# Kontroller och regler

Rapporten kontrollerar Entra-appkonfiguration. Den innehåller inga manuella kontrollpunkter och hämtar inga sign-in- eller auditloggar. API-behörigheter, federation och policyer visas som information, utan egna godkännanderegler.

## Vad krävs för Passed?

Alla tillämpliga och aktiva kontroller ska ha `PASS`. `FAIL` ger appstatus **Failed**. `WARN` eller `UNKNOWN` ger **Investigate**. `NOT_APPLICABLE` och `SKIPPED` blockerar inte övriga kontroller. Om alla kontroller undantas visas appen som **Skipped**, inte Passed.

| Kontroll | Standardkrav | Config |
|---|---|---|
| `EnterpriseAdminOwner` | Minst en användarägare på SPN med UPN som börjar med `azadmu` | `ownerUpnPrefix`, `minimumAdminOwners` |
| `RegistrationAdminOwner` | Samma ägarkrav på appregistreringen, separat från SPN | Samma fält |
| `EnterpriseDescription` | Beskrivningen på SPN får inte vara tom eller blanksteg | `requireDescriptions` |
| `RegistrationDescription` | Samma beskrivningskrav på appregistreringen | Samma fält |
| `AssignmentRequired` | Tilldelning krävs för appen | `requireAssignment` |
| `GroupAssignmentsPreferred` | Minst en grupp är tilldelad; direkta användare får också finnas | `requireGroupAssignment` |
| `RedirectUriSecurity` | Minst en redirect-URL, HTTPS; HTTP till localhost tillåts | `requireRedirectUris`, `allowLocalhostHttp` |
| `CredentialDates` | Befintliga credentials har giltiga datum, är aktiva och har mer än 30 hela dagar kvar. Hemligheter högst 90 dagars livslängd, certifikat högst 365 dagar | `maxSecretLifetimeDays`, `maxCertificateLifetimeDays`, `credentialWarningDays` |

Inga certifikat eller hemligheter ger `NOT_APPLICABLE`: inga finns att bedöma. Ogiltig eller utgången datumperiod och för lång livslängd ger FAIL. Saknade datum ger UNKNOWN. Ett framtida startdatum eller få återstående dagar ger WARN.

Ingen lokal appregistrering ger `NOT_APPLICABLE` för registreringskontrollerna. Registreringar i andra tenant granskas inte. Saknade ägaruppgifter/UPN ger UNKNOWN. Ägarkontrollen använder UPN-prefixet, inte användarens visningsnamn eller aktiva katalogroll. Tom beskrivning ger WARN. Ingen bestämd standardtext eller beställningsnummer krävs ännu.

## Ändra regler

Redigera `config/production.json`. Alla regelvärden ligger under `rules`; nuvarande standardvärden finns redan i filen. Exempel: ändra `minimumAdminOwners` till `2`, `ownerUpnPrefix` till ett annat prefix eller `maxSecretLifetimeDays` till `180`.

`requireDescriptions`, `requireAssignment`, `requireGroupAssignment` och `requireRedirectUris` kan sättas till `false` för att stänga av respektive krav. `allowLocalhostHttp: false` kräver HTTPS även för localhost. Avstängda krav visas som SKIPPED. Numeriska värden ska vara heltal mellan 1 och 10000. Ägarprefix ska vara en bokstavlig sträng, utan jokertecken.

En specifik kontroll kan stängas av för alla appar genom `disabledChecks`, exempelvis:

```json
"disabledChecks": ["GroupAssignmentsPreferred"]
```

## Undantag per app

Använd **Application (client) ID**, inte SPN:s objekt-ID. Varje undantag ska ange vilka kontroller och varför. Appen och dess uppgifter finns kvar i rapporten.

```json
"exclusions": [
  {
    "appId": "11111111-2222-3333-4444-555555555555",
    "checks": ["EnterpriseDescription", "RegistrationDescription"],
    "reason": "Godkänt tillfälligt undantag enligt beställning 12345"
  }
]
```

För att undanta alla kontroller för en app: använd `"checks": ["*"]`. Inga undantag finns aktiverade från början. Undantag ändrar bara bedömningen, inga inställningar i Entra.

## Körning och spårbarhet

Nästa lokala körning eller GitHub-körning använder configen. Regler och undantag sparas i `report.json` och visas under tenantposten i HTML och Actions-sammanfattningen.

Ändra bedömningen av en befintlig rapport utan att hämta Graph-data:

```powershell
.\Render-Report.ps1 -ConfigPath .\config\production.json
```

Utan `-ConfigPath` används reglerna som sparats i rapporten. Äldre rapporter utan regelsnapshot använder standardregler. Ändrad Entra-konfiguration kräver däremot en ny insamling.
