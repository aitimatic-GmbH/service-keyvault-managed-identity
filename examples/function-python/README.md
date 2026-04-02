# Example: Python Azure Function with Key Vault Integration

HTTP-Trigger Function die Secrets aus Azure Key Vault über Managed Identity liest.

## Lokal testen

```bash
az login
export KEY_VAULT_URI="https://kv-kvmi-dev.vault.azure.net/"

pip install -r requirements.txt
func start
```

## Endpunkte

- `GET /api/health` -- Health Check
- `GET /api/secret/{name}` -- Secret-Metadaten lesen (Wert wird nicht angezeigt)

## Auf Azure Functions

Die Function App wird automatisch konfiguriert über die Bicep-Module:
- `AZURE_CLIENT_ID` -- Client ID der Managed Identity
- `KEY_VAULT_URI` -- Vault URI
- `AzureWebJobsStorage` -- Storage Account Connection String

## Deploy

```bash
func azure functionapp publish func-kvmi-dev
```
