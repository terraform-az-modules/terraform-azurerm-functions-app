# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.0.0] - 2026-04-22
### :bug: Bug Fixes
- [`81a7ffe`](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/commit/81a7ffe66b0bd5763fded8ecbfe1da18972cf66c) - consolidate versions.tf, remove provider_meta, upgrade to azurerm >= 4.0 *(commit by [@anmolnagpal](https://github.com/anmolnagpal))*
- [`9c72c01`](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/commit/9c72c01247fbdbf57ddfac07f493e8fc01939da8) - replace version placeholder in example versions.tf with >= 4.0 *(commit by [@anmolnagpal](https://github.com/anmolnagpal))*

### :wrench: Chores
- [`ed370de`](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/commit/ed370de88f159f6a279261afca85ec1a8f441f8b) - **deps**: Bump hashicorp/setup-terraform from 3 to 4 *(commit by [@dependabot[bot]](https://github.com/apps/dependabot))*
- [`f6e8640`](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/commit/f6e8640fb27cd04b5031b0d0ce26cf39ea85d0fa) - **deps**: Bump terraform-linters/setup-tflint from 4 to 6 *(commit by [@dependabot[bot]](https://github.com/apps/dependabot))*
- [`93094e2`](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/commit/93094e26ab49b48c39f7c905e21b684d45a276e9) - **deps**: Bump actions/checkout from 4 to 6 *(commit by [@dependabot[bot]](https://github.com/apps/dependabot))*
- [`3fd1ff2`](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/commit/3fd1ff22a70d5498971c34148d26d4b372c88a0a) - add provider_meta for API usage tracking *(PR [#8](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/pull/8) by [@clouddrove-ci](https://github.com/clouddrove-ci))*
- [`a90cd01`](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/commit/a90cd01e5a9ec5fb93a6c73066c540f1d12e990e) - polish module with basic example, changelog, and version fixes *(PR [#9](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/pull/9) by [@clouddrove-ci](https://github.com/clouddrove-ci))*
- [`63ea820`](https://github.com/terraform-az-modules/terraform-azurerm-functions-app/commit/63ea8208a5dc82cd2840ab29e209f0241e1e8b28) - **deps**: Bump actions/checkout from 3 to 6 *(commit by [@dependabot[bot]](https://github.com/apps/dependabot))*


## [1.0.0] - 2026-03-20

### Changes
- Add provider_meta for API usage tracking
- Add terraform tests and pre-commit CI workflow
- Add SECURITY.md, CONTRIBUTING.md, .releaserc.json
- Standardize pre-commit to antonbabenko v1.105.0
- Set provider: none in tf-checks for validate-only CI
- Bump required_version to >= 1.10.0
[v2.0.0]: https://github.com/terraform-az-modules/terraform-azurerm-functions-app/compare/v1.0.0...v2.0.0
