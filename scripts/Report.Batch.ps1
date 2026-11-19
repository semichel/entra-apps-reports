Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#= Read complete relationship collections in batches, correlating and retrying each response
function Invoke-ReportBatchGetAll {
    param([System.Collections.IDictionary]$Requests)
    $results = @{}; $queue = [Collections.Generic.Queue[object]]::new()
    foreach ($uri in $Requests.Keys) {
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        [void]$seen.Add($uri)
        $queue.Enqueue(@{ uri = $uri; next = $uri; required = [bool]$Requests[$uri]; attempt = 0; items = [Collections.Generic.List[object]]::new(); seen = $seen })
    }
    $calls = 0; $pages = 0
    while ($queue.Count) {
        $pending = @{}; $batch = [Collections.Generic.List[object]]::new()
        while ($queue.Count -and $batch.Count -lt 20) {
            $state = $queue.Dequeue(); $parsed = [uri]$state.next
            if ($parsed.Scheme -ne 'https' -or $parsed.Host -ne 'graph.microsoft.com' -or $parsed.Port -ne 443 -or $parsed.UserInfo -or -not $parsed.AbsolutePath.StartsWith('/v1.0/', [StringComparison]::Ordinal)) { throw 'Batch relationship URL must use https://graph.microsoft.com/v1.0/.' }
            $id = [string]($batch.Count + 1); $pending[$id] = $state
            $batch.Add(@{ id = $id; method = 'GET'; url = $parsed.PathAndQuery.Substring('/v1.0'.Length) })
        }
        $calls++
        try { $response = Invoke-ReportGet 'https://graph.microsoft.com/v1.0/$batch' -BatchRequests $batch.ToArray() }
        catch {
            if (@($pending.Values | Where-Object { $_.required }).Count) { throw }
            foreach ($state in $pending.Values) {
                $results[$state.uri] = @{ status = 'UNAVAILABLE'; items = @(); reason = 'Graph batch transport failed; optional relationship evidence is unavailable.' }
            }
            continue
        }
        $responses = @((Get-Val $response 'responses') | Where-Object { $null -ne $_ })
        if ($responses.Count -ne $pending.Count) { throw 'Incomplete Graph batch response.' }
        $delay = 0
        foreach ($item in $responses) {
            $id = Get-Str $item 'id'
            if (-not $id -or -not $pending.ContainsKey($id)) { throw 'Unexpected or duplicate Graph batch response ID.' }
            $state = $pending[$id]; $pending.Remove($id)
            $status = Get-Val $item 'status'; $body = Get-Val $item 'body'
            if ($status -isnot [int] -and $status -isnot [long]) { throw 'Missing Graph batch response status.' }
            if ($status -eq 200) {
                if ($body -isnot [System.Collections.IDictionary] -or -not $body.Contains('value')) { throw 'Graph batch collection response has no value collection.' }
                foreach ($record in @((Get-Val $body 'value')) | Where-Object { $null -ne $_ }) {
                    if ($record -isnot [System.Collections.IDictionary]) { throw 'Graph batch collection contains an invalid record.' }
                    $state.items.Add($record)
                }
                $pages++; $state.next = Get-Str $body '@odata.nextLink'; $state.attempt = 0
                if ($state.next) {
                    if (-not $state.seen.Add($state.next)) { throw 'Repeated Graph batch nextLink detected.' }
                    $queue.Enqueue($state)
                } else { $results[$state.uri] = @{ status = 'AVAILABLE'; items = $state.items.ToArray(); reason = $null } }
                continue
            }
            $state.attempt++; $wait = [int][Math]::Pow(2, $state.attempt)
            $retryAfter = Get-Str (Get-Val $item 'headers') 'Retry-After'
            if ($retryAfter) {
                $seconds = 0; $date = [DateTimeOffset]::MinValue
                if ([int]::TryParse($retryAfter, [ref]$seconds) -and $seconds -ge 0) { $wait = [Math]::Max($wait, $seconds) }
                elseif ([DateTimeOffset]::TryParse($retryAfter, [ref]$date)) { $wait = [int][Math]::Max($wait, [Math]::Ceiling(($date - [DateTimeOffset]::UtcNow).TotalSeconds)) }
                else { throw 'Invalid Retry-After in Graph batch response.' }
            }
            if ($status -in @(429, 503, 504) -and $state.attempt -lt 5 -and $wait -le 120) {
                $delay = [Math]::Max($delay, $wait); $queue.Enqueue($state)
                continue
            }
            $reason = 'Graph relationship query failed (HTTP {0}); access, licensing or retry limits must be checked.' -f $status
            if ($state.required) { throw $reason }
            $results[$state.uri] = @{ status = 'UNAVAILABLE'; items = @(); reason = $reason }
        }
        Write-ReportLog ('Relationship batch {0}: {1} successful pages; {2} collections pending.' -f $calls, $pages, $queue.Count)
        if ($delay) { Start-Sleep -Seconds $delay }
    }
    Write-ReportLog ('Relationship reads completed: {0} collections, {1} successful pages, {2} batch calls.' -f $Requests.Count, $pages, $calls) Green
    return $results
}

#= Prefetch core and optional relationships without assuming parent changes cover them
function Get-ReportRelationshipEvidence {
    param([object[]]$Principals, [object[]]$Registrations)
    $requests = [ordered]@{}
    foreach ($principal in $Principals) {
        $id = Get-Str $principal 'id'
        if ($null -eq (Get-ExpandedOwnerEvidence $principal)) { $requests[("https://graph.microsoft.com/v1.0/servicePrincipals/{0}/owners?`$select=id,displayName,userPrincipalName" -f $id)] = $true }
        $requests[("https://graph.microsoft.com/v1.0/servicePrincipals/{0}/appRoleAssignedTo?`$select=id,principalId,principalDisplayName,principalType,appRoleId,resourceId" -f $id)] = $true
        $requests[("https://graph.microsoft.com/v1.0/servicePrincipals/{0}/appRoleAssignments?`$select=id,appRoleId,resourceId,resourceDisplayName,principalId" -f $id)] = $false
    }
    foreach ($registration in $Registrations) {
        $id = Get-Str $registration 'id'
        if ($null -eq (Get-ExpandedOwnerEvidence $registration)) { $requests[("https://graph.microsoft.com/v1.0/applications/{0}/owners?`$select=id,displayName,userPrincipalName" -f $id)] = $false }
        $requests[("https://graph.microsoft.com/v1.0/applications/{0}/federatedIdentityCredentials" -f $id)] = $false
    }
    return Invoke-ReportBatchGetAll $requests
}
