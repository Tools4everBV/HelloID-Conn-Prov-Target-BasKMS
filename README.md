# HelloID-Conn-Prov-Target-BasKMS

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://www.basbedrijfskleding.nl/wp-content/themes/atention/assets/img/logo.png">
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
      - [UTF-8 encoding](#utf-8-encoding)
  - [Setup the connector](#setup-the-connector)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-BasKMS_ is a _target_ connector. _BasKMS_ provides a set of REST API's that allow you to programmatically interact with its data. The HelloID connector uses the API endpoints listed in the table below.

| Endpoint | Description |
| -------- | ----------- |
| /kms/employee/show        | Retrieve a single employee by `referenceId`.             |
| /kms/employee/create        | Create a new employee.             |
| /kms/employee/update        | Update an employee.           |

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
    | Account correlation field | `-`                               |

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
| TokenUrl     | The URL to retrieve a token            | Yes       |
| BaseUrl      | The base URL to the API                | Yes       |

### Prerequisites

### Remarks

#### `referenceId`

The `referenceId` contains the `externalId` of the person. This field is used within the _create_ lifecycle action to determine if an account exists and is part of the JSON payload to the target application.

#### Error handling

At this stage, the error handling functionality is still using the default function. This is because the error-handling logic could not be fully tested in all scenarios during the initial development phase.

We recommend that error handling be revisited and thoroughly tested in various edge cases (e.g., invalid data formats, missing required fields, system failures, etc.) once more comprehensive tests can be conducted.

For now, the default behavior will capture basic issues, but it may not provide customized or detailed feedback.

#### Social security number (BSN)

The data returned by _KMS_ also contains the _social security number_ or _BSN_. Therefore, within the connector, both the output from `$correlatedAccount` and `$createdAccount` are filtered to only contain the fields specified in the field mapping or `$actionContext.Data` with the addition of the `id`.

#### UTF-8 encoding

Before final deployment, comprehensive testing is required to validate that all data inputs and outputs are correctly encoded in UTF-8. This will include verifying that special characters and non-Latin scripts are accurately processed and displayed.

## Setup the connector

> _How to setup the connector in HelloID._ Are special settings required. Like the _primary manager_ settings for a source connector.

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/target-systems/powershell-v2-target-systems.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/

