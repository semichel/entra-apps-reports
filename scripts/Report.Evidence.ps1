Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Optional evidence never masquerades as an empty successful query
function Get-OptionalEvidence {
    param([string]$Uri)
    try {
        $items = @(Invoke-MgGetAll $Uri)
        return [ordered]@{ status = 'AVAILABLE'; items = $items; reason = $null }
    }
    catch {
        $status = Get-Val (Get-Val $_.Exception 'Response') 'StatusCode'
        return [ordered]@{ status = 'UNAVAILABLE'; items = @(); reason = ("Graph query failed (HTTP {0}); access, licensing or endpoint support must be checked." -f $status) }
    }
}

#= Resolve a single owner and preserve missing or ambiguous contact evidence
function Set-OwnerContactEvidence {
    param([System.Collections.IDictionary]$Owner, $ById, $ByEmployee)
    $Owner['userEmail'] = $null; $Owner['contactUserId'] = $null; $Owner['contactUserPrincipalName'] = $null
    $Owner['employeeId'] = $null; $Owner['contactMatchStatus'] = 'NOT_APPLICABLE'
    $user = Get-Val $ById (Get-Str $Owner 'id')
    if ($null -eq $user) {
        if ((Get-Str $Owner '@odata.type') -eq '#microsoft.graph.user') { $Owner['contactMatchStatus'] = 'OWNER_USER_NOT_FOUND' }
        return
    }
    foreach ($key in @('displayName','userPrincipalName','employeeId')) {
        $Owner[$key] = Get-Val $user $key
    }
    $Owner['@odata.type'] = '#microsoft.graph.user'
    $employeeId = Get-Str $user 'employeeId'
    if ([string]::IsNullOrWhiteSpace($employeeId)) { $Owner['contactMatchStatus'] = 'MISSING_EMPLOYEE_ID'; return }
    $matches = @((Get-Val $ByEmployee $employeeId) | Where-Object { $null -ne $_ })
    if ($matches.Count -eq 0) { $Owner['contactMatchStatus'] = 'NO_REGULAR_ACCOUNT'; return }
    if ($matches.Count -gt 1) { $Owner['contactMatchStatus'] = 'AMBIGUOUS'; return }
    $Owner['contactUserId'] = Get-Str $matches[0] 'id'
    $Owner['contactUserPrincipalName'] = Get-Str $matches[0] 'userPrincipalName'
    $mail = Get-Str $matches[0] 'mail'
    if ([string]::IsNullOrWhiteSpace($mail)) { $Owner['contactMatchStatus'] = 'MISSING_USER_EMAIL'; return }
    $Owner['userEmail'] = $mail; $Owner['contactMatchStatus'] = 'MATCHED'
}

#= Supplement the core inventory using read-only Graph evidence
function Add-ExtendedEvidence {
    param(
        [System.Collections.IDictionary]$Report,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Registrations
    )
    Write-ReportLog 'Collecting app registration and permission evidence.'
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
    $index = 0
    foreach ($app in @(Get-Val $Report 'applications')) {
        $index++; Write-CollectionProgress 'Application permissions and evidence' $index @(Get-Val $Report 'applications').Count (Get-Str $app 'displayName')
        Add-AppEvidence $app $principalIndex $registrationIndex
    }
    Write-Progress -Id 1 -Activity 'Application permissions and evidence' -Completed
    Add-OwnerContactEvidence $Report
    $Report['schemaVersion'] = '2.0'
    $Report['evidenceCollectedAtUtc'] = [DateTimeOffset]::UtcNow.ToString('o')
}

#= Match owner accounts to regular accounts using employee IDs without guessing recipients
function Add-OwnerContactEvidence {
    param([System.Collections.IDictionary]$Report)
    Write-ReportLog 'Loading user names, employee IDs and mail addresses once for owner contact matching.'
    $users = @(Invoke-MgGetAll 'https://graph.microsoft.com/v1.0/users?$top=999&$select=id,displayName,userPrincipalName,employeeId,mail')
    $byId = @{}; $byEmployee = @{}
    $prefix = Get-Str (Get-Val (Get-Val $Report 'ruleConfiguration') 'rules') 'ownerUpnPrefix'
    foreach ($user in $users) {
        $byId[(Get-Str $user 'id')] = $user
        $employeeId = Get-Str $user 'employeeId'; $upn = Get-Str $user 'userPrincipalName'
        if ([string]::IsNullOrWhiteSpace($employeeId) -or [string]::IsNullOrWhiteSpace($upn)) { continue }
        if ($prefix -and $upn.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { continue }
        if (-not $byEmployee.ContainsKey($employeeId)) { $byEmployee[$employeeId] = [Collections.Generic.List[object]]::new() }
        $byEmployee[$employeeId].Add($user)
    }
    $owners = @(@((Get-Val $Report 'applications')) | ForEach-Object { Get-Val $_ 'owners' })
    $owners += @(@((Get-Val $Report 'registrations')) | ForEach-Object { Get-Val (Get-Val $_ 'owners') 'items' })
    foreach ($owner in $owners) {
        if ($null -ne $owner) { Set-OwnerContactEvidence $owner $byId $byEmployee }
    }
    Write-ReportLog ('Owner contact matching completed using {0} user records; the user catalog is not saved in the report.' -f $users.Count) Green
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

#= Enrich an application with permissions evidence
function Add-AppEvidence {
    param([System.Collections.IDictionary]$App, $PrincipalIndex, $RegistrationIndex)
    $id = Get-Str $App 'servicePrincipalId'
    $appId = Get-Str $App 'appId'
    $principal = Get-Val $PrincipalIndex $id
    foreach ($key in @('appOwnerOrganizationId','publisherName','servicePrincipalType','appRoles','oauth2PermissionScopes','description','homepage','tags','info')) {
        $App[$key] = Get-Val $principal $key
    }
    $App['registration'] = Get-Val $RegistrationIndex $appId
    $App['applicationPermissionGrants'] = Get-ApplicationPermissionEvidence $id $PrincipalIndex
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
