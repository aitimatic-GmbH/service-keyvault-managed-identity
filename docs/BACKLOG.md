# Backlog: Secure Secrets Management & Identity Integration

## Status-Legende

- **done** -- Abgeschlossen und gemerged
- **in-progress** -- Aktuell in Bearbeitung (eigener Branch)
- **planned** -- Geplant, noch nicht begonnen
- **future** -- Spaetere Erweiterung, kein fester Termin

---

## Phase 1: Projekt-Foundation

**Status**: done
**Branch**: `feat/projekt-foundation`

| Aufgabe | Status |
|---------|--------|
| `infra/bicepconfig.json` -- Bicep Linter + Formatting | done |
| `.github/CODEOWNERS` -- Repository Ownership | done |
| `.gitignore` -- Bicep/Azure Eintraege | done |
| `README.md` -- Service-Uebersicht, Architektur-Diagramm | done |

---

## Phase 2: Core Key Vault Modul

**Status**: done
**Branch**: `feat/core-keyvault-module`

| Aufgabe | Status |
|---------|--------|
| `infra/modules/keyvault/main.bicep` -- Key Vault (RBAC, Soft-Delete, Purge Protection, Network ACLs) | done |
| `infra/modules/rbac/keyvault-role.bicep` -- RBAC Role Assignment (idempotent) | done |
| `infra/main.bicep` -- Root-Orchestrierung mit Naming-Konvention | done |
| `infra/environments/dev.bicepparam` -- Dev-Parameter (germanywestcentral) | done |
| `scripts/deploy.sh` -- Deployment-Skript | done |
| `scripts/validate.sh` -- What-if Preview | done |
| `scripts/teardown.sh` -- Cleanup (RG + Vault Purge) | done |

---

## Phase 3: Managed Identity + Web App

**Status**: in-progress
**Branch**: `feat/managed-identity-webapp`

| Aufgabe | Status |
|---------|--------|
| `infra/modules/identity/user-assigned.bicep` -- User-Assigned Managed Identity | done |
| `infra/modules/webapp/main.bicep` -- App Service Plan (F1) + Web App + Identity Binding | done |
| `infra/main.bicep` -- Feature-Flag `deployWebApp`, Identity + RBAC + Web App Module | done |
| `examples/webapp-python/` -- Flask Beispiel-App | done |
| `docs/` -- Technische Dokumentation | in-progress |
| Azure-Test: Deploy + Secret erstellen + abrufen | planned |

---

## Phase 4: Network Security (Private Endpoints)

**Status**: planned

| Aufgabe | Status |
|---------|--------|
| `infra/modules/networking/vnet.bicep` -- VNet + Subnets | planned |
| `infra/modules/networking/private-endpoint.bicep` -- Private Endpoint + DNS Zone Group | planned |
| `infra/modules/networking/private-dns-zone.bicep` -- Private DNS Zone + VNet-Link | planned |
| `infra/main.bicep` -- Feature-Flag `deployNetworking` | planned |
| `infra/environments/staging.bicepparam` -- Staging-Parameter | planned |
| `infra/environments/prod.bicepparam` -- Prod-Parameter | planned |
| Key Vault `publicNetworkAccess: Disabled` | planned |

---

## Phase 5: Azure Functions

**Status**: in-progress
**Branch**: `feat/azure-functions`

| Aufgabe | Status |
|---------|--------|
| `infra/modules/functions/main.bicep` -- Storage + Function App (Y1 Consumption) | done |
| `infra/main.bicep` -- Feature-Flag `deployFunctions`, Identity-Sharing | done |
| `examples/function-python/` -- HTTP-Trigger Beispiel | done |
| Key Vault References in App Settings (AZURE_CLIENT_ID, KEY_VAULT_URI) | done |
| Identity-Bedingung erweitert: `deployWebApp \|\| deployFunctions` | done |
| Azure-Test: Validate + Function testen | planned |

---

## Phase 6: VM Integration

**Status**: planned

| Aufgabe | Status |
|---------|--------|
| `infra/modules/vm/main.bicep` -- NIC + VM (B1s) mit System-Assigned Identity | planned |
| `infra/main.bicep` -- Feature-Flag `deployVm` | planned |
| SSH-Key Auth (kein Passwort) | planned |
| RBAC fuer VM System-Assigned Identity | planned |

---

## Phase 7: Container Apps + AKS

**Status**: future

| Aufgabe | Status |
|---------|--------|
| `infra/modules/container-apps/main.bicep` -- Container Apps (Consumption) | future |
| `infra/modules/aks/main.bicep` -- AKS + Workload Identity + OIDC | future |
| Federated Identity Credential | future |

---

## Phase 8: Monitoring + Automation

**Status**: future

| Aufgabe | Status |
|---------|--------|
| `infra/modules/monitoring/log-analytics.bicep` -- Log Analytics (PerGB2018) | future |
| `infra/modules/monitoring/diagnostic-settings.bicep` -- Diagnostic Settings | future |
| `infra/modules/automation/secret-rotation.bicep` -- Automation + Event Grid | future |
| AuditEvent-Logs fuer AZ-500 Compliance | future |

---

## Phase 9: CI/CD (Submodule-faehig)

**Status**: future

| Aufgabe | Status |
|---------|--------|
| `.github/actions/bicep-lint/action.yml` -- Composite Action: Lint | future |
| `.github/actions/bicep-validate/action.yml` -- Composite Action: Validate | future |
| `.github/actions/bicep-deploy/action.yml` -- Composite Action: Deploy | future |
| `scripts/lint.sh` -- Direktskript-Methode | future |
| `scripts/bicep-deploy.sh` -- Direktskript-Methode | future |
| `.github/workflows/` -- Interne Workflows | future |

---

## Phase 10: Dokumentation (Detail)

**Status**: future

| Aufgabe | Status |
|---------|--------|
| `docs/architecture.md` -- Mermaid-Diagramme | future |
| `docs/deployment-guide.md` -- Schritt-fuer-Schritt | future |
| `docs/troubleshooting.md` -- Fehlerbehebung | future |
| `docs/cost-estimation.md` -- Kostenaufschluesselung | future |
| `docs/glossary.md` -- Begriffe | future |
