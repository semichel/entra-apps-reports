Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Optional evidence never masquerades as an empty successful query
function Get-OptionalEvidence {
    param([string]$Uri)
    $path = ([uri]$Uri).AbsolutePath
    $tenantQuery = $path -notmatch '/(applications|servicePrincipals)/'
    $timer = [Diagnostics.Stopwatch]::StartNew()
    if ($tenantQuery) { Write-ReportLog ('Loading tenant evidence: {0}' -f $path) }
    try {
        $items = @(Invoke-MgGetAll $Uri)
        if ($tenantQuery) { Write-ReportLog ('Loaded {0}: {1} records in {2:N1}s.' -f $path, $items.Count, $timer.Elapsed.TotalSeconds) Green }
        return [ordered]@{ status = 'AVAILABLE'; items = $items; reason = $null }
    }
    catch {
        $status = Get-Val (Get-Val $_.Exception 'Response') 'StatusCode'
        if ($tenantQuery) { Write-ReportLog ('Tenant evidence unavailable at {0} (HTTP {1}) after {2:N1}s.' -f $path, $status, $timer.Elapsed.TotalSeconds) Yellow }
        return [ordered]@{ status = 'UNAVAILABLE'; items = @(); reason = ("Graph query failed (HTTP {0}); access, licensing or endpoint support must be checked." -f $status) }
    }
}

#= Index tenant evidence once instead of scanning every record for every application
function Group-EvidenceByKey {
    param($Items, [string]$Key)
    $index = @{}
    foreach ($item in $Items) {
        $value = Get-Str $item $Key; if ([string]::IsNullOrWhiteSpace($value)) { continue }
        if (-not $index.ContainsKey($value)) { $index[$value] = [System.Collections.Generic.List[object]]::new() }; $index[$value].Add($item)
    }
    return $index
}

#= Supplement the core inventory using read-only Graph evidence
function Add-ExtendedEvidence {
    param(
        [System.Collections.IDictionary]$Report,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Registrations
    )
    Write-ReportLog 'Collecting app registration and consent evidence.'
    Write-ReportLog ('Reusing {0} registrations from the initial inventory; no second registration download.' -f $Registrations.Count)
    $principals = @(Invoke-MgGetAll 'https://graph.microsoft.com/v1.0/servicePrincipals?$select=id,appId,displayName,appOwnerOrganizationId,publisherName,servicePrincipalType,appRoles,oauth2PermissionScopes,description,homepage,tags,info')
    $principalIndex = @{}
    foreach ($principal in $principals) {
        $principalIndex[(Get-Str $principal 'id')] = $principal
    }
    $registrationIndex = @{}
    $index = 0
    foreach ($registration in $registrations) {
        $index++; Write-CollectionProgress 'Registration owners and federation' $index $registrations.Count (Get-Str $registration 'displayName')
        $registrationIndex[(Get-Str $registration 'appId')] = Get-RegistrationEvidence $registration
    }
    Write-Progress -Id 1 -Activity 'Registration owners and federation' -Completed
    $Report['registrations'] = @($registrationIndex.Values)
    Write-ReportLog 'Loading delegated consent. Sign-in and audit logs are not collected.'
    $Report['tenantEvidence'] = [ordered]@{
        delegatedConsentGrants = Get-OptionalEvidence 'https://graph.microsoft.com/v1.0/oauth2PermissionGrants'
    }
    $index = 0
    Write-ReportLog ('Tenant evidence collected: {0} consent grants. Building lookup once.' -f $Report['tenantEvidence']['delegatedConsentGrants']['items'].Count)
    $consentByPrincipal = Group-EvidenceByKey (Get-Val (Get-Val $Report['tenantEvidence'] 'delegatedConsentGrants') 'items') 'clientId'
    foreach ($app in @(Get-Val $Report 'applications')) {
        $index++; Write-CollectionProgress 'Application permissions and evidence' $index @(Get-Val $Report 'applications').Count (Get-Str $app 'displayName')
        Add-AppEvidence $app $principalIndex $registrationIndex (Get-Val $Report 'tenantEvidence') $consentByPrincipal
    }
    Write-Progress -Id 1 -Activity 'Application permissions and evidence' -Completed
    $Report['schemaVersion'] = '2.0'
    $Report['evidenceCollectedAtUtc'] = [DateTimeOffset]::UtcNow.ToString('o')
}

#= Registration evidence excludes credential values
function Get-RegistrationEvidence {
    param($Registration)
    $id = Get-Str $Registration 'id'
    $result = [ordered]@{}
    foreach ($key in @('id','appId','displayName','description','signInAudience','publisherDomain','createdDateTime','web','spa','publicClient','identifierUris','optionalClaims','groupMembershipClaims','api','appRoles','requiredResourceAccess','info','tags')) {
        $result[$key] = Get-Val $Registration $key
    }
    $result['owners'] = Get-ExpandedOwnerEvidence $Registration
    if ($null -eq $result['owners']) { $result['owners'] = Get-OptionalEvidence ("https://graph.microsoft.com/v1.0/applications/{0}/owners?`$select=id,displayName,userPrincipalName" -f $id) }
    $result['credentials'] = @(Get-CredentialSummary $Registration 'AppRegistration')
    $result['federatedIdentityCredentials'] = Get-OptionalEvidence ("https://graph.microsoft.com/v1.0/applications/{0}/federatedIdentityCredentials" -f $id)
    return $result
}

#= Enrich an application with permissions and consent evidence
function Add-AppEvidence {
    param([System.Collections.IDictionary]$App, $PrincipalIndex, $RegistrationIndex, $TenantEvidence, $ConsentByPrincipal)
    $id = Get-Str $App 'servicePrincipalId'
    $appId = Get-Str $App 'appId'
    $principal = Get-Val $PrincipalIndex $id
    foreach ($key in @('appOwnerOrganizationId','publisherName','servicePrincipalType','appRoles','oauth2PermissionScopes','description','homepage','tags','info')) {
        $App[$key] = Get-Val $principal $key
    }
    $App['registration'] = Get-Val $RegistrationIndex $appId
    $App['applicationPermissionGrants'] = Get-ApplicationPermissionEvidence $id $PrincipalIndex
    $App['delegatedConsentGrants'] = [ordered]@{ status = Get-Str (Get-Val $TenantEvidence 'delegatedConsentGrants') 'status'; items = @((Get-Val $ConsentByPrincipal $id) | Where-Object { $null -ne $_ }) }
    $App['scopeNote'] = 'Catalog observation; apply the supplied SSO requirements only after confirming this is an in-scope production SSO application. Platform/resource apps may legitimately differ.'
}

#= Resolve granted application permission names against resource roles
function Get-ApplicationPermissionEvidence {
    param([string]$PrincipalId, $PrincipalIndex)
    $evidence = Get-OptionalEvidence ("https://graph.microsoft.com/v1.0/servicePrincipals/{0}/appRoleAssignments?`$select=id,appRoleId,resourceId,resourceDisplayName,principalId" -f $PrincipalId)
    foreach ($grant in @(Get-Val $evidence 'items')) {
        Set-PermissionName $grant $PrincipalIndex
    }
    return $evidence
}

#= Permission role name enrichment without additional Graph reads
function Set-PermissionName {
    param([System.Collections.IDictionary]$Grant, $PrincipalIndex)
    $resource = Get-Val $PrincipalIndex (Get-Str $Grant 'resourceId')
    $roleId = Get-Str $Grant 'appRoleId'
    $role = @((Get-Val $resource 'appRoles') | Where-Object { (Get-Str $_ 'id') -eq $roleId }) | Select-Object -First 1
    $Grant['permission'] = Get-Str $role 'value'
    $Grant['permissionDisplayName'] = Get-Str $role 'displayName'
}
