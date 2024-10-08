##################################################
# HelloID-Conn-Prov-Target-BasKMS-Delete
# PowerShell V2
##################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-BasKMSError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            # Make sure to inspect the error result object and add only the error message as a FriendlyMessage.
            # $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails # Temporarily assignment
        } catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw 'The account reference could not be found'
    }

    # Retrieve access token
    $splatParams = @{
        Uri         = $actionContext.Configuration.TokenUrl
        ContentType = 'application/x-www-form-urlencoded'
        Method      = 'POST'
        Body = @{
            client_id     = $actionContext.Configuration.ClientId
            client_secret = $actionContext.Configuration.ClientSecret
            username      = $actionContext.Configuration.UserName
            password      = $actionContext.Configuration.Password
            grant_type    = 'password'
        }
    }
    $responseToken = Invoke-RestMethod @splatParams

    Write-Information 'Verifying if a BasKMS account exists'
    $splatGetUserParams = @{
        Uri     = "$($actionContext.Configuration.BaseUrl)/kms/employee/show"
        Method  = 'POST'
        Headers = @{
            Authorization = "Bearer $($responseToken.access_token)"
            Accept = 'application/json'
            ContentType = 'application/x-www-form-urlencoded'
        }
        Body = @{
            id = $correlationValue
        }
    }
    $correlatedAccount = Invoke-RestMethod @splatGetUserParams
    if (-not ($correlatedAccount.error)){
        $propertyNames = $actionContext.Data.PSObject.Properties.Name + 'id'
        $filteredCorrelatedAccount = $correlatedAccount | Select-Object -Property $propertyNames
        $correlatedAccount = $null
    }

    if ($null -ne $filteredCorrelatedAccount) {
        $action = 'DeleteAccount'
    } else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'DeleteAccount' {
            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information "Deleting BasKMS account with accountReference: [$($actionContext.References.Account)]"
                $splatDeleteUserParams = @{
                    Uri     = "$($actionContext.Configuration.BaseUrl)/kms/employee/update"
                    Method  = 'POST'
                    Headers = @{
                        Authorization = "Bearer $($responseToken.access_token)"
                        Accept = 'application/json'
                        ContentType = 'application/x-www-form-urlencoded'
                    }
                    Body = @{
                        id = $actionContext.References.Account
                        deleted = $true
                    }
                }
                $null = Invoke-RestMethod @splatDeleteUserParams
            } else {
                Write-Information "[DryRun] Delete BasKMS account with accountReference: [$($actionContext.References.Account)], will be executed during enforcement"
            }

            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = 'Delete account was successful'
                    IsError = $false
                })
            break
        }

        'NotFound' {
            Write-Information "BasKMS account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "BasKMS account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
                    IsError = $false
                })
            break
        }
    }
} catch {
    $outputContext.success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-BasKMSError -ErrorObject $ex
        $auditMessage = "Could not delete BasKMS account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not delete BasKMS account. Error: $($_.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}
