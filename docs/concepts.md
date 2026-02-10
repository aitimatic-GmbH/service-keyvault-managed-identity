# Konzepte: Key Vault + Managed Identity

Dieses Dokument erklärt die zentralen Konzepte hinter diesem Projekt -- unabhängig von der konkreten Implementierung.

---

## Azure Key Vault

Azure Key Vault ist ein Cloud-Dienst zum sicheren Speichern und Verwalten von:

- **Secrets** -- Connection Strings, API-Keys, Passwörter
- **Keys** -- Kryptographische Schlüssel (Verschlüsselung, Signierung)
- **Certificates** -- TLS/SSL-Zertifikate

Secrets werden verschlüsselt gespeichert (AES-256) und nie im Klartext übertragen. Jeder Zugriff wird protokolliert (AuditEvent-Logs).

### Soft-Delete und Purge Protection

| Feature | Bedeutung |
|---------|----------|
| **Soft-Delete** | Gelöschte Secrets bleiben 90 Tage wiederherstellbar. Schützt vor versehentlichem Löschen. |
| **Purge Protection** | Verhindert das endgültige Löschen während der Retention-Periode. **Einmalschalter** -- kann nicht deaktiviert werden. |

Was passiert beim Löschen eines Key Vaults:

```
Key Vault löschen
  → Soft-Deleted (90 Tage)
    → Name blockiert (kann nicht wiederverwendet werden)
    → Purge-Befehl nötig um den Namen freizugeben
    → Purge Protection verhindert Purge bis Retention abläuft
```

### SKUs

| SKU | Preis | Wann nutzen |
|-----|-------|-------------|
| **Standard** | ~0,03 EUR / 10K Operationen | Default -- reicht für die meisten Szenarien |
| **Premium** | ~0,12 EUR / 10K Operationen | Wenn HSM-geschützte Keys benötigt werden |

Wir nutzen **Standard** -- kein HSM nötig.

---

## Managed Identity

Eine Managed Identity ist eine automatisch verwaltete Identität in Azure AD (Entra ID). Sie ersetzt manuelle Credentials durch einen von Azure verwalteten Service Principal.

### Das Problem ohne Managed Identity

```
Entwickler erstellt Service Principal
  → Client ID + Client Secret generiert
    → Secret muss irgendwo gespeichert werden (Config, Env-Var, Key Vault?)
      → Secret läuft ab (1-2 Jahre)
        → Manuelle Rotation nötig
          → App fällt aus wenn vergessen
```

### Die Lösung mit Managed Identity

```
Azure erstellt Identity automatisch
  → Keine Credentials sichtbar
    → Kein Secret das abläuft
      → Kein Rotations-Aufwand
        → Azure kümmert sich um alles
```

Die App nutzt `DefaultAzureCredential()` -- ein SDK-Aufruf der automatisch erkennt wo die App läuft:

| Umgebung | Authentifizierung |
|----------|------------------|
| Azure (App Service, Functions, VM) | Managed Identity (über `AZURE_CLIENT_ID`) |
| Lokal (Entwickler-Rechner) | Azure CLI (`az login`) |
| CI/CD Pipeline | Workload Identity Federation oder Service Principal |

### User-Assigned vs. System-Assigned

| | User-Assigned | System-Assigned |
|-|--------------|----------------|
| **Lebenszyklus** | Unabhängig von der Ressource | An die Ressource gebunden (wird mit ihr gelöscht) |
| **Wiederverwendbar** | Ja -- eine Identity für Web App, Functions, etc. | Nein -- jede Ressource hat ihre eigene |
| **Vorab erstellbar** | Ja -- RBAC kann vor der App eingerichtet werden | Nein -- RBAC erst nach Erstellung möglich |
| **Wann nutzen** | Mehrere Services teilen sich Zugriff | Eine einzelne Ressource (z.B. VM) |

**Unsere Wahl**: User-Assigned als primärer Typ. Eine Identity für alle Compute-Ressourcen (Identity-Sharing). System-Assigned kommt in Phase 6 für VMs zum Einsatz -- als bewusster Vergleich.

---

## RBAC (Role-Based Access Control)

RBAC steuert, **wer** auf **was** zugreifen darf. Es besteht aus drei Teilen:

```
Wer (Principal)  +  Was darf er (Role)  +  Wo (Scope)  =  Zugriff
```

### Beispiel

```
id-kvmi-dev          Secrets User         kv-kvmi-dev      Secrets lesen
(Managed Identity) + (nur lesen)        + (dieser Vault) = (erlaubt)
```

### Principal-Typen

| Typ | Beschreibung | Beispiel |
|-----|-------------|---------|
| ServicePrincipal | Managed Identity oder App Registration | `id-kvmi-dev` |
| User | Azure AD Benutzer | `max@firma.de` |
| Group | Azure AD Gruppe | `Developers` |

### Key Vault Rollen

| Rolle | GUID | Erlaubt |
|-------|------|---------|
| Key Vault Secrets User | `4633458b-...` | Nur Secret-**Werte** lesen |
| Key Vault Secrets Officer | `b86a8fe4-...` | Secrets erstellen, ändern, löschen |
| Key Vault Administrator | `00482a5a-...` | Volle Verwaltung (Secrets, Keys, Certificates) |
| Key Vault Reader | `21090545-...` | Nur Metadaten lesen (keine Werte!) |

**Principle of Least Privilege**: Wir vergeben nur **Secrets User** an Compute-Ressourcen. Die App kann Secrets lesen, aber nicht erstellen oder löschen.

### RBAC vs. Access Policies

Azure Key Vault kennt zwei Autorisierungsmodelle:

| | Access Policies (Legacy) | RBAC (unsere Wahl) |
|-|-------------------------|-------------------|
| **Scope** | Nur auf Vault-Ebene | Vault, einzelnes Secret, Key, Certificate |
| **Konsistenz** | Nur Key Vault | Azure-weit (gleich wie Storage, Compute, etc.) |
| **Vererbung** | Nein | Ja -- von Resource Group auf Vault auf Secret |
| **Empfehlung** | Backward Compatibility | **Microsoft Best Practice** |

### Idempotente Role Assignments

RBAC Role Assignments brauchen eine eindeutige GUID als Namen. Wir nutzen:

```bicep
name: guid(keyVault.id, principalId, roleDefinitionId)
```

Gleiche Inputs → gleiche GUID → kein Duplikat bei erneutem Deployment. Ohne das würde Azure beim zweiten Deployment mit einem Fehler abbrechen.

---

## Private Endpoints

Ein Private Endpoint gibt einer Azure-Ressource eine **private IP-Adresse** innerhalb eines VNets.

### Ohne Private Endpoint

```
App → Internet (Microsoft Backbone) → Key Vault (öffentliche IP)
```

Der Key Vault hat eine öffentliche IP. Zugriff wird durch RBAC geschützt, aber der Traffic verlässt das VNet.

### Mit Private Endpoint

```
App → VNet → Private Endpoint (10.0.1.4) → Key Vault
```

Der Key Vault hat eine private IP. Kein öffentlicher Zugriff möglich. Der Traffic bleibt vollständig im VNet.

### Drei Bausteine

| Baustein | Aufgabe |
|----------|---------|
| **Private Endpoint** | Netzwerk-Interface mit privater IP im Subnet |
| **Private DNS Zone** | Löst `kv-kvmi-dev.vault.azure.net` auf die private IP auf |
| **DNS Zone Group** | Verknüpft Endpoint mit DNS Zone -- erstellt A-Records automatisch |

### DNS-Auflösung im Detail

```
1. App fragt: "Wo ist kv-kvmi-dev.vault.azure.net?"
2. VNet leitet an Private DNS Zone weiter
3. Private DNS Zone antwortet: "10.0.1.4"
4. App verbindet sich mit 10.0.1.4 (Private Endpoint)
5. Private Endpoint leitet an Key Vault weiter
→ Kein Traffic verlässt das VNet
```

Ohne Private DNS Zone würde die App die öffentliche IP bekommen und der Zugriff wäre blockiert (`publicNetworkAccess: Disabled`).

---

## Identity-Sharing

Mehrere Compute-Ressourcen teilen sich eine User-Assigned Managed Identity:

```
                    ┌──────────────────┐
                    │  Managed Identity │
                    │  id-kvmi-dev      │
                    └────┬─────────┬───┘
                         │         │
                    nutzt│         │nutzt
                         │         │
                  ┌──────┴──┐ ┌────┴─────┐
                  │ Web App │ │ Function │
                  └─────────┘ └──────────┘
```

**Vorteil**: Ein RBAC Role Assignment genügt für alle Services. Wenn ein neuer Service dazukommt (z.B. Container App), wird nur die Identity angehängt -- kein neues RBAC nötig.

In `main.bicep` wird die Identity erstellt sobald **irgendein** Compute-Service aktiv ist:

```bicep
module identity '...' = if (deployWebApp || deployFunctions) { ... }
module kvRbac  '...' = if (deployWebApp || deployFunctions) { ... }
```

---

## Feature Flags und Incremental Deployment

### Feature Flags

Jede Phase wird über einen Boolean-Parameter gesteuert:

```bicep
param deployWebApp bool = false      // Phase 3
param deployNetworking bool = false  // Phase 4
param deployFunctions bool = false   // Phase 5
```

Das ermöglicht:
- **Schrittweises Aktivieren** -- erst Key Vault, dann Web App, dann Networking
- **Umgebungsspezifisch** -- Dev ohne Networking, Prod mit allem
- **Sicheres Testen** -- neue Features einzeln aktivieren

### Incremental Mode

Alle Deployments laufen im Modus **Incremental**:

| Aktion | Was passiert |
|--------|-------------|
| Neue Ressource im Template | Wird **erstellt** |
| Bestehende Ressource geändert | Wird **aktualisiert** |
| Ressource nicht im Template | Wird **nicht gelöscht** |

Das bedeutet: Wenn `deployWebApp = false`, wird die Web App nicht gelöscht -- sie wird einfach nicht im Template verwaltet.

### Parameter-Dateien (.bicepparam)

Jede Umgebung hat eine eigene Parameter-Datei:

```bicep
// infra/environments/dev.bicepparam
using '../main.bicep'

param location = 'germanywestcentral'
param environmentName = 'dev'
param projectName = 'kvmi'
param tags = {
  environment: 'dev'
  project: 'keyvault-managed-identity'
  managedBy: 'bicep'
}
// Feature Flags nach Bedarf aktivieren:
// param deployWebApp = true
// param deployFunctions = true
```

`.bicepparam` ist das native Bicep-Format -- mit Compile-Time-Validierung. Tippfehler in Parameternamen werden sofort erkannt.

---

## Authentifizierungs-Flow

So läuft die Authentifizierung wenn eine App ein Secret lesen will:

```
1. App startet, ruft DefaultAzureCredential() auf
2. SDK erkennt: "Ich bin auf Azure, AZURE_CLIENT_ID ist gesetzt"
3. SDK fragt Azure AD (Entra ID): "Gib mir ein Token für diese Identity"
4. Azure AD prüft: "Existiert diese Identity? Ja."
5. Azure AD gibt JWT Token zurück (gültig ~24h)
6. App schickt Request an Key Vault:
   GET /secrets/my-secret
   Authorization: Bearer {token}
7. Key Vault prüft RBAC:
   "Hat principalId die Rolle 'Key Vault Secrets User'? Ja."
8. Key Vault gibt Secret-Wert zurück
```

**Kein Passwort fließt.** Das Token wird automatisch erneuert bevor es abläuft. Die App sieht nie Credentials.

---

## Weiterführende Links

- [Azure Key Vault Dokumentation](https://learn.microsoft.com/azure/key-vault/general/overview)
- [Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview)
- [Key Vault RBAC](https://learn.microsoft.com/azure/key-vault/general/rbac-guide)
- [Private Endpoints](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)
- [Bicep Dokumentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview)
- [DefaultAzureCredential](https://learn.microsoft.com/python/api/azure-identity/azure.identity.defaultazurecredential)
