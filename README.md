# Entra Apps Reports

Inventerar organisationens Entra-appregistreringar och enterprise-appar/SPN: ägare, beskrivningar, certifikat/hemligheters datum, tilldelningar, API-behörigheter, federation och policyer. Inbyggda Microsoft-appar undantas. Körningen läser konfiguration och skapar HTML, JSON och CSV; inga sign-in- eller auditloggar hämtas.

## GitHub Actions

HTML-rapporten och Actions-sammanfattningen visar statistik per kontroll: PASS, FAIL, WARN, UNKNOWN, undantagna/inaktiverade och ej tillämpliga. Varje app räknas en gång per kontroll.

Filtertaggarna visar kontrollens namn och resultat, exempelvis `EnterpriseAdminOwner: FAIL` eller `RegistrationDescription: WARN`.
Tagglistan anpassas efter status, kategori, severity och sökning. Failed visar FAIL-taggar, Passed visar PASS-taggar och Investigate visar WARN/UNKNOWN. Taggval som inte längre passar urvalet rensas automatiskt.

Normal körning: **Actions → Entra application report → Run workflow**, från `main`. Rapporten visas i Actions-sammanfattningen och hela HTML/JSON/CSV-resultatet finns i körningens artifact. Tenant och körande app anges av repository-secrets `AZURE_TENANT_ID` och `AZURE_CLIENT_ID`.

## Config och kontroller

[config/production.json](config/production.json) styr bedömningen. `tenantDisplayName` är rapportens visningsnamn, inte valet av tenant. Ändra fälten under `rules` för era krav:

| Fält | Funktion och standardkrav |
|---|---|
| `ownerUpnPrefix`, `minimumAdminOwners` | Minst **1** användarägare med UPN-prefix **azadmu**, separat på SPN och appregistrering. Kontroller: `EnterpriseAdminOwner`, `RegistrationAdminOwner`. |
| `requireDescriptions` | Beskrivning krävs på båda objekten; tomt eller blanksteg ger varning. Ingen standardtext krävs. Kontroller: `EnterpriseDescription`, `RegistrationDescription`. |
| `requireAssignment` | Tilldelning måste krävas. Kontroll: `AssignmentRequired`. |
| `requireGroupAssignment` | Minst en tilldelad grupp; direkta användare får också finnas. Kontroll: `GroupAssignmentsPreferred`. |
| `requireRedirectUris`, `allowLocalhostHttp` | Minst en HTTPS-redirect. HTTP till localhost tillåts som standard. Kontroll: `RedirectUriSecurity`. |
| `maxSecretLifetimeDays`, `maxCertificateLifetimeDays` | Högst **90** respektive **365** dagars livslängd för befintliga credentials. Utgångna eller ogiltiga datumperioder ger fel. Kontroll: `CredentialDates`. |
| `credentialWarningDays` | Varning vid **30** eller färre hela dagar kvar. Framtida startdatum ger också varning. |

Kravfält kan sättas till `false` för att stänga av kontrollen. Numeriska värden är heltal mellan 1 och 10000. Saknade credentials eller registrering i en annan tenant visas som `NOT_APPLICABLE`; saknade uppgifter som behövs för bedömning ger `UNKNOWN`. API-behörigheter, federation och policyer visas som information.

**Passed** betyder att aktiva, tillämpliga kontroller passerar. Fel ger **Failed**; varningar eller okända resultat ger **Investigate**. Rapporten har inga manuella kontrollpunkter.

`disabledChecks` stänger av namngivna kontroller för alla appar, exempelvis `["GroupAssignmentsPreferred"]`. `exclusions` ger undantag för en app via dess **Application (client) ID**:

```json
"exclusions": [
  {
    "appId": "11111111-2222-3333-4444-555555555555",
    "checks": ["EnterpriseDescription", "RegistrationDescription"],
    "reason": "Godkänt undantag enligt beställning 12345"
  }
]
```

Använd `"checks": ["*"]` för hela appen. Undantag visas som **Skipped** med motivering; appen finns kvar i inventeringen. Inga undantag är aktiverade från början. Regler och undantag sparas med rapporten och visas under tenantposten.

## Testa lokalt/on-prem

Kör från repots rot i PowerShell 7 med ditt eget Global Reader-konto:

```powershell
.\Start-TestRun.ps1 -TenantId 'DIN-TENANT-ID'
```

Lägg till `-UseDeviceCode` för device-inloggning. Resultatet finns i `reports/latest/report.html` med JSON och CSV i samma mapp.

För att bara rendera sparad data med aktuell config, utan inloggning eller Graph-hämtning:

```powershell
.\Render-Report.ps1 -ConfigPath .\config\production.json
```

Utan `-ConfigPath` använder renderingen reglerna som sparats i rapporten. Ändringar i Entra kräver en ny insamling.
