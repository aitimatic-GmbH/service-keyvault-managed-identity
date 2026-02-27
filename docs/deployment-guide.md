# Deployment Guide

## Voraussetzungen

1. **Azure CLI** mit Bicep installiert
   ```bash
   az --version        # Version 2.83.0
   az bicep version    # Version 0.40.2
   ```

2. **Azure Subscription** mit Berechtigungen:
   - `Microsoft.KeyVault/*` -- Key Vault erstellen/verwalten
   - `Microsoft.ManagedIdentity/*` -- Managed Identities erstellen
   - `Microsoft.Authorization/roleAssignments/*` -- RBAC Rollen zuweisen
   - `Microsoft.Web/*` -- App Service erstellen (Phase 3)

3. **Anmeldung**:
   ```bash
   az login
   az account set --subscription "<SUBSCRIPTION_ID>"
   ```

## Deployment-Ablauf

### Schritt 1: Validieren (what-if)

```bash
./scripts/validate.sh dev
```

Was passiert:
- Resource Group `rg-kvmi-dev` wird erstellt (falls nicht vorhanden)
- `az deployment group what-if` zeigt an was erstellt/geaendert/geloescht wird
- **Kein tatsaechliches Deployment** -- nur eine Vorschau

### Schritt 2: Deployen

```bash
./scripts/deploy.sh dev
```

Was passiert:
- Resource Group `rg-kvmi-dev` wird erstellt (falls nicht vorhanden)
- Bicep wird kompiliert und als ARM-Deployment ausgefuehrt
- Modus: **Incremental** (nur hinzufuegen/aendern, nie loeschen)
- Key Vault `kv-kvmi-dev` wird erstellt

### Schritt 3: Verifizieren

```bash
# Key Vault pruefen
az keyvault show --name kv-kvmi-dev --query '{
  name: name,
  rbac: properties.enableRbacAuthorization,
  softDelete: properties.enableSoftDelete,
  purgeProtection: properties.enablePurgeProtection,
  sku: properties.sku.name
}'

# Test-Secret erstellen (erfordert Key Vault Administrator Rolle fuer deinen User)
az keyvault secret set \
  --vault-name kv-kvmi-dev \
  --name test-secret \
  --value "Hello from Key Vault!"

# Secret lesen
az keyvault secret show \
  --vault-name kv-kvmi-dev \
  --name test-secret \
  --query value
```

### Schritt 4: Web App aktivieren (Phase 3)

In `infra/environments/dev.bicepparam` hinzufuegen:
```bicep
param deployWebApp = true
```

Dann erneut deployen:
```bash
./scripts/deploy.sh dev
```

Neue Ressourcen:
- `id-kvmi-dev` -- User-Assigned Managed Identity
- `asp-kvmi-dev` -- App Service Plan (F1 Free)
- `app-kvmi-dev` -- Web App (Python 3.12)
- RBAC: Identity bekommt "Key Vault Secrets User" auf dem Vault

Testen:
```bash
# Web App URL
az webapp show --name app-kvmi-dev --resource-group rg-kvmi-dev --query defaultHostName -o tsv

# Health Check
curl https://app-kvmi-dev.azurewebsites.net/

# Secret abrufen (Wert wird nicht angezeigt)
curl https://app-kvmi-dev.azurewebsites.net/secret/test-secret
```

## Aufraeumen

```bash
./scripts/teardown.sh dev
```

Was passiert:
- Fragt nach Bestaetigung (`yes` eingeben)
- Loescht Resource Group `rg-kvmi-dev` und alle Ressourcen darin
- Purgt den soft-deleted Key Vault (damit der Name wiederverwendbar ist)

**Achtung**: Key Vault Purge Protection verzoegert das endgueltige Loeschen. Wenn du den gleichen Vault-Namen sofort wieder brauchst, muss der Purge-Befehl erfolgreich durchlaufen.

## Skript-Referenz

| Skript | Zweck | Braucht Azure Login |
|--------|-------|-------------------|
| `scripts/validate.sh [env]` | What-if Preview | Ja |
| `scripts/deploy.sh [env]` | Deployment | Ja |
| `scripts/teardown.sh [env]` | Aufraeumen | Ja |

Alle Skripte akzeptieren `dev`, `staging` oder `prod` als Argument. Default: `dev`.

## Bicep Lint lokal ausfuehren

```bash
az bicep lint --file infra/main.bicep
az bicep build --file infra/main.bicep --stdout > /dev/null
```

Erwartete Warnings bei aktiviertem `deployWebApp`:
- 4x BCP318 -- Konditionale Module referenzieren sich gegenseitig. Zur Laufzeit sicher.
