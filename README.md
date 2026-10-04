# Azure Terraform environments

[![Source validation](https://github.com/Pmen225/azure-multi-environment-terraform/actions/workflows/terraform.yml/badge.svg?branch=main)](https://github.com/Pmen225/azure-multi-environment-terraform/actions/workflows/terraform.yml)

Reusable Terraform modules for Azure networking and Linux App Service, composed into separate `dev` and `prod` roots. Both environments use the same resource definitions with different compute sizes and address ranges. Each root has its own provider lock file and local state.

## Architecture

The network module defines a VNet and delegated integration subnet. The application module receives that subnet ID and connects a Linux web app through outbound VNet integration. Random suffixes distinguish globally scoped application names.

| Configuration | `dev` | `prod` |
| --- | --- | --- |
| App Service plan | B1 | P0v3 |
| VNet address space | `10.20.0.0/16` | `10.30.0.0/16` |
| Integration subnet | `10.20.1.0/24` | `10.30.1.0/24` |
| Default region | UK South | UK South |
| Application runtime | Node.js 24 LTS | Node.js 24 LTS |

Each web app requires HTTPS and TLS 1.2. FTP and basic publishing authentication are disabled. The network module validates its address range inputs and delegates the application subnet to App Service.

## Environment separation

Separate roots isolate configuration and state changes. Both use the selected Azure subscription, so directory separation does not establish subscription or identity isolation. The `prod` root provides the P0v3 configuration variant.

Shared modules keep networking and application controls consistent between environments. Compute sizing is an explicit input to each root, while each web app receives the subnet produced by its corresponding network module.

## Validation

GitHub Actions checks Terraform formatting, locked provider initialisation and schema validation for both roots through an environment matrix. The checks require no Azure credentials, and the badge reports the latest workflow status on `main`.

The repository defines infrastructure only and contains no application package or runtime tests.

## Design and operations

Both web apps have public HTTPS endpoints. VNet integration provides outbound connectivity; private inbound access is not configured. The platform includes no private endpoints, data stores, monitoring stack, deployment slots or availability zone configuration.

State is local to each root. A shared deployment process would require a secured remote backend with separate state keys and locking, an Azure deployment identity and explicit approval controls. The existing workflow performs source validation only. Azure permissions, resource provider registration and regional availability remain deployment dependencies.

Both App Service plans are billable, including when their applications are stopped. P0v3 carries a higher compute cost than B1. Each environment has a separate resource lifecycle and state, so removing one leaves the other unchanged. State and saved plans can contain sensitive data and are excluded from version control.

## Source layout

- [`modules/network/`](modules/network/): VNet, input validation and delegated subnet
- [`modules/app/`](modules/app/): Linux App Service plan and web app
- [`envs/dev/`](envs/dev/) and [`envs/prod/`](envs/prod/): independent environment roots
- [Validation workflow](.github/workflows/terraform.yml): matrix checks for both environments
