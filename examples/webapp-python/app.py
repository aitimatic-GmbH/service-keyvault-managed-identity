"""
Example: Reading Azure Key Vault Secrets with Managed Identity

Uses DefaultAzureCredential which automatically picks up:
- Managed Identity (on App Service via AZURE_CLIENT_ID env var)
- Azure CLI credentials (local development via az login)
"""

import os

from flask import Flask, jsonify
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

app = Flask(__name__)

KEY_VAULT_URI = os.environ.get("KEY_VAULT_URI")


@app.route("/")
def index():
    return jsonify({
        "service": "keyvault-managed-identity-demo",
        "status": "running",
        "key_vault_uri": KEY_VAULT_URI,
    })


@app.route("/secret/<secret_name>")
def get_secret(secret_name):
    """Read a secret from Key Vault. Value is redacted in the response."""
    try:
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=KEY_VAULT_URI, credential=credential)
        secret = client.get_secret(secret_name)
        return jsonify({
            "secret_name": secret.name,
            "created_on": str(secret.properties.created_on),
            "enabled": secret.properties.enabled,
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
