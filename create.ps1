#################################################
# HelloID-Conn-Prov-Target-BasKMS-Create
# PowerShell V2
#################################################

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
    # Initial Assignments
    $outputContext.AccountReference = 'Currently not available'

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

    # Validate correlation configuration
    if ($actionContext.CorrelationConfiguration.Enabled) {
        $correlationField = $actionContext.CorrelationConfiguration.PersonField
        $correlationValue = $actionContext.CorrelationConfiguration.PersonFieldValue

        if ([string]::IsNullOrEmpty($($correlationField))) {
            throw 'Correlation is enabled but not configured correctly'
        }
        if ([string]::IsNullOrEmpty($($correlationValue))) {
            throw 'Correlation is enabled but [accountFieldValue] is empty. Please make sure it is correctly mapped'
        }

        # Determine if a user needs to be [created] or [correlated]
        $splatGetUserParams = @{
            Uri     = "$($actionContext.Configuration.BaseUrl)/kms/employee/show"
            Method  = 'POST'
            Headers = @{
                Authorization = "Bearer $($responseToken.access_token)"
                Accept = 'application/json'
                ContentType = 'application/x-www-form-urlencoded'
            }
            Body = @{
                referenceId = $correlationValue
            }
        }
        $correlatedAccount = Invoke-RestMethod @splatGetUserParams
        if (-not ($correlatedAccount.error)){
            $propertyNames = $actionContext.Data.PSObject.Properties.Name + 'id'
            $filteredCorrelatedAccount = $correlatedAccount | Select-Object -Property $propertyNames
            $correlatedAccount = $null
        }
    }

    if ($null -ne $filteredCorrelatedAccount) {
        $action = 'CorrelateAccount'
    } else {
        $action = 'CreateAccount'
    }

    # Process
    switch ($action) {
        'CreateAccount' {
            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information 'Creating and correlating BasKMS account'
                $actionContext.Data | Add-Member -MemberType NoteProperty -Name 'active' -Value $false
                $splatCreateParams = @{
                    Uri    = "$($actionContext.Configuration.BaseUrl)/kms/employee/create"
                    Method = 'POST'
                    Headers = @{
                        Authorization = "Bearer $($responseToken.access_token)"
                    }
                    Body        = $actionContext.Data | ConvertTo-Json
                    ContentType = 'application/json'
                }
                $createdAccount = Invoke-RestMethod @splatCreateParams
                $propertyNames = $actionContext.Data.PSObject.Properties.Name + 'id'
                $filteredCreatedAccount = $createdAccount | Select-Object -Property $propertyNames
                $outputContext.Data = $filteredCreatedAccount
                $outputContext.AccountReference = $filteredCreatedAccount.id
            } else {
                Write-Information '[DryRun] Create and correlate BasKMS account, will be executed during enforcement'
            }
            $auditLogMessage = "Create account was successful. AccountReference is: [$($outputContext.AccountReference)]"
            break
        }

        'CorrelateAccount' {
            Write-Information 'Correlating BasKMS account'
            $outputContext.Data = $filteredCorrelatedAccount
            $outputContext.AccountReference = $filteredCorrelatedAccount.id
            $outputContext.AccountCorrelated = $true
            $auditLogMessage = "Correlated account: [$($outputContext.AccountReference)] on field: [$($correlationField)] with value: [$($correlationValue)]"
            break
        }
    }

    $outputContext.success = $true
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Action  = $action
            Message = $auditLogMessage
            IsError = $false
        })
} catch {
    $outputContext.success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-BasKMSError -ErrorObject $ex
        $auditMessage = "Could not create or correlate BasKMS account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not create or correlate BasKMS account. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}
