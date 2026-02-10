# Example: Python Web App with Key Vault Integration

Flask-App die Secrets aus Azure Key Vault über Managed Identity liest.

## Lokal testen

```bash
az login
export KEY_VAULT_URI="https://kv-kvmi-dev.vault.azure.net/"

pip install -r requirements.txt
python app.py
```

## Endpunkte

- `GET /` -- Health Check
- `GET /secret/<name>` -- Secret-Metadaten lesen (Wert wird nicht angezeigt)

## Auf App Service

Die App wird automatisch konfiguriert über die Bicep-Module:
- `AZURE_CLIENT_ID` -- Client ID der Managed Identity
- `KEY_VAULT_URI` -- Vault URI
