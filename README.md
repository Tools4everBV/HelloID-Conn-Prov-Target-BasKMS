# HelloID-Conn-Prov-Target-BasKMS

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-BasKMS/blob/main/Logo.png?raw=true">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-BasKMS](#helloid-conn-prov-target-baskms)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Provisioning PowerShell V2 connector](#provisioning-powershell-v2-connector)
      - [Correlation configuration](#correlation-configuration)
      - [Field mapping](#field-mapping)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
      - [`referenceId`](#referenceid)
      - [Error handling](#error-handling)
      - [Social security number (BSN)](#social-security-number-bsn)
      - [DepartmentName](#departmentname)
  - [Setup the connector](#setup-the-connector)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-BasKMS_ is a _target_ connector. _BasKMS_ provides a set of REST API's that allow you to programmatically interact with its data. The HelloID connector uses the API endpoints listed in the table below.

| Endpoint             | Description                                  |
| -------------------- | -------------------------------------------- |
| /kms/employee/show   | Retrieve a single employee by `referenceId`. |
| /kms/employee/create | Create a new employee.                       |
| /kms/employee/update | Update an employee.                          |

The following lifecycle actions are available:

| Action             | Description                           |
| ------------------ | ------------------------------------- |
| create.ps1         | PowerShell _create_ lifecycle action  |
| delete.ps1         | PowerShell _delete_ lifecycle action  |
| disable.ps1        | PowerShell _disable_ lifecycle action |
| enable.ps1         | PowerShell _enable_ lifecycle action  |
| update.ps1         | PowerShell _update_ lifecycle action  |
| configuration.json | Default _configuration.json_          |
| fieldMapping.json  | Default _fieldMapping.json_           |

## Getting started

### Provisioning PowerShell V2 connector

#### Correlation configuration

The correlation configuration is used to specify which properties will be used to match an existing account within _BasKMS_ to a person in _HelloID_.

To properly setup the correlation:

1. Open the `Correlation` tab.

2. Specify the following configuration:

    | Setting                   | Value                             |
    | ------------------------- | --------------------------------- |
    | Enable correlation        | `True`                            |
    | Person correlation field  | `PersonContext.Person.ExternalId` |
    | Account correlation field | `referenceId`                     |

> [!TIP]
> _For more information on correlation, please refer to our correlation [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems/correlation.html) pages_.

#### Field mapping

The field mapping can be imported by using the _fieldMapping.json_ file.

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                            | Mandatory |
| ------------ | -------------------------------------- | --------- |
| ClientID     | The ClientID to connect to the API     | Yes       |
| ClientSecret | The ClientSecret to connect to the API | Yes       |
| UserName     | The UserName to connect to the API     | Yes       |
| Password     | The Password to connect to the API     | Yes       |
| BaseUrl      | The base URL to the API                | Yes       |

### Prerequisites

### Remarks

#### `referenceId`

The `referenceId` contains the `externalId` of the person. This field is used within the _create_ lifecycle action to determine if an account exists and is part of the JSON payload to the target application.

> [!IMPORTANT]
> The referenceId can only be filled with the API or with an import (not in the GUI).

#### Error handling

Most of the errors in BasKMS are returned in the response. For this reason, the code will check the response if it contains an error.

#### Social security number (BSN)

The data returned by _KMS_ also could also contain the _social security number_ or _BSN_. Therefore, within the connector, both the output from `$correlatedAccount` and `$createdAccount` are filtered to only contain the fields specified in the field mapping or `$actionContext.Data` with the addition of the `id`.

#### DepartmentName
The field mapping contains a field `departmentName`, which is returned by BasKMS as `department.name`. In the update script, this is hardcoded to `departmentName`.

> [!IMPORTANT]
> If `departmentName` is not present, BasKMS will set the `department` field to empty without returning an error.

## Setup the connector

> _How to setup the connector in HelloID._ Are special settings required. Like the _primary manager_ settings for a source connector.

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/

