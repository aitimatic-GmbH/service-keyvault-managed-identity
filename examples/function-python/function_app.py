"""Azure Function: Key Vault Secret Reader via Managed Identity."""

import json
import logging
import os

import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

app = func.FunctionApp()

KEY_VAULT_URI = os.environ.get("KEY_VAULT_URI", "")
credential = DefaultAzureCredential()
secret_client = SecretClient(vault_url=KEY_VAULT_URI, credential=credential)


@app.route(route="health", methods=["GET"])
def health(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint."""
    return func.HttpResponse(
        json.dumps({"status": "healthy", "keyVaultUri": KEY_VAULT_URI}),
        mimetype="application/json",
    )


@app.route(route="secret/{name}", methods=["GET"])
def get_secret(req: func.HttpRequest) -> func.HttpResponse:
    """Read secret metadata from Key Vault (value is redacted)."""
    secret_name = req.route_params.get("name", "")

    try:
        secret = secret_client.get_secret(secret_name)
        return func.HttpResponse(
            json.dumps({
                "name": secret.name,
                "enabled": secret.properties.enabled,
                "created": str(secret.properties.created_on),
                "updated": str(secret.properties.updated_on),
                "value": "*** REDACTED ***",
            }),
            mimetype="application/json",
        )
    except Exception as e:
        logging.error("Failed to read secret '%s': %s", secret_name, e)
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            status_code=500,
            mimetype="application/json",
        )
