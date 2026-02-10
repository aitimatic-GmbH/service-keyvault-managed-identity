# Secure Secrets Management & Identity Integration in Azure

[![Bicep Lint](https://img.shields.io/badge/Bicep-Linted-blue)](#) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **"Sicherheit, die funktioniert: Ihre Geheimnisse sind sicher und nur für Ihre Anwendungen zugänglich."**

## Was ist das?

Dieses Repository stellt eine produktionsreife Azure Key Vault Infrastruktur mit Managed Identity Integration bereit -- vollständig als Infrastructure as Code (Bicep). Es demonstriert, wie Azure-Services sich ohne Passwörter am Key Vault authentifizieren können.

## Warum Key Vault + Managed Identity?

**Das Problem**: Passwörter, Connection Strings und API-Keys landen in Konfigurationsdateien, Umgebungsvariablen oder sogar im Quellcode. Auditoren finden sie, Rotationen sind manuell und fehleranfällig.

**Die Lösung**: Azure Key Vault speichert alle Secrets zentral und verschlüsselt. Managed Identities ermöglichen Anwendungen den Zugriff ohne jegliche Credentials im Code. Azure übernimmt das Credential-Management vollständig.

## Architektur

```mermaid
graph TB
    subgraph "Azure Resource Group"
        KV["Key Vault\n(RBAC-Auth, Soft-Delete, Purge Protection)"]

        subgraph "Identities"
            UAI["User-Assigned\nManaged Identity"]
            SAI["System-Assigned\n(VM-gebunden)"]
        end

        subgraph "Compute"
            WEB["App Service\n(Web App)"]
            FUNC["Azure Functions"]
            VM["Virtual Machine"]
            CA["Container Apps"]
            AKS["AKS Cluster"]
        end

        subgraph "Network"
            VNET["VNet + Subnets"]
            PE["Private Endpoint"]
            DNS["Private DNS Zone"]
        end

        subgraph "Monitoring"
            LAW["Log Analytics"]
            DIAG["Diagnostic Settings"]
        end
    end

    WEB -->|"nutzt"| UAI
    FUNC -->|"nutzt"| UAI
    CA -->|"nutzt"| UAI
    AKS -->|"Workload Identity"| UAI
    VM -->|"nutzt"| SAI

    UAI -->|"RBAC: Secrets User"| KV
    SAI -->|"RBAC: Secrets User"| KV

    KV --- PE
    PE --- DNS
    PE --- VNET

    KV --> DIAG
    DIAG --> LAW
```

## Voraussetzungen

- Azure Subscription mit Berechtigungen für Key Vault und Identity-Erstellung
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) mit Bicep (`az bicep install`)
- Oder: Dieses Repository im Dev Container öffnen (alle Tools vorinstalliert)

## Quick Start

```bash
# 1. Anmelden
az login

# 2. Validieren (what-if)
./scripts/validate.sh dev

# 3. Deployen
./scripts/deploy.sh dev

# 4. Test-Secret erstellen
az keyvault secret set --vault-name kv-kvmi-dev --name test-secret --value "Hello from Key Vault!"

# 5. Aufräumen
./scripts/teardown.sh dev
```

## Repository-Struktur

```
infra/                      Bicep Infrastructure as Code
  bicepconfig.json          Linter- und Formatting-Konfiguration
  main.bicep                Root-Orchestrierung (Einstiegspunkt)
  modules/                  Wiederverwendbare Bicep-Module
    keyvault/               Key Vault mit Security Best Practices
    rbac/                   RBAC Role Assignments
    identity/               User-Assigned Managed Identity
    webapp/                 App Service + Plan
    networking/             VNet, Private Endpoint, DNS Zone
    functions/              Azure Functions
    vm/                     Virtual Machine
    container-apps/         Container Apps
    aks/                    Azure Kubernetes Service
    monitoring/             Log Analytics, Diagnostic Settings
    automation/             Secret Rotation
  environments/             Parameter-Dateien pro Umgebung
    dev.bicepparam
    staging.bicepparam
    prod.bicepparam
examples/                   Beispiel-Anwendungen
  webapp-python/            Flask-App mit Key Vault Integration
  function-python/          Azure Function mit Key Vault Integration
scripts/                    Deployment- und Hilfs-Skripte
docs/                       Detaillierte Dokumentation
```

## Implementierungs-Phasen

| Phase | Inhalt | Status |
|-------|--------|--------|
| 1 | Projekt-Foundation (Struktur, Linter, README) | done |
| 2 | Core Key Vault Modul + RBAC + Deploy-Skripte | done |
| 3 | Managed Identity + Web App | done |
| 4 | Network Security (Private Endpoint, DNS) | done |
| 5 | Azure Functions | done |
| 6 | VM Integration | geplant |
| 7 | Container Apps + AKS | geplant |
| 8 | Monitoring + Secret Rotation | geplant |
| 9 | CI/CD (GitHub Actions, Submodule-faehig) | geplant |
| 10 | Dokumentation | geplant |

## Design-Entscheidungen

| Entscheidung | Wahl | Begründung |
|-------------|------|-------------|
| Autorisierung | RBAC (nicht Access Policies) | Granulares Scoping, Azure-weit konsistent, Microsoft-Empfehlung |
| Identity-Typ | User-Assigned (primär) | Wiederverwendbar, unabhängiger Lifecycle, vorab provisionierbar |
| Parameter-Format | `.bicepparam` | Native Bicep-Format, Compile-Time-Validierung |
| Region | `germanywestcentral` | DSGVO-konform (Frankfurt), geringe Latenz für DE |
| Key Vault SKU | Standard | Kein HSM nötig, Premium wäre 4x teurer |

## Dokumentation

| Dokument | Inhalt |
|----------|--------|
| [Konzepte](docs/konzept.md) | Key Vault, Managed Identity, RBAC, Private Endpoints, Identity-Sharing |
| [Architektur](docs/architecture.md) | Diagramme, Security Design, Naming Convention, Feature Flags |
| [Deployment Guide](docs/deployment-guide.md) | Validieren, Deployen, Verifizieren, Aufräumen |
| [Backlog](docs/BACKLOG.md) | Status aller Phasen und offene Aufgaben |

## Sicherheit

Sicherheitsprobleme bitte über [SECURITY.md](SECURITY.md) melden.

## Lizenz

[MIT](LICENSE) -- aitimatic GmbH
