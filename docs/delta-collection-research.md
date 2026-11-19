# Graph collection optimization

Verified against Microsoft documentation on 2026-11-19. Relationship GET batching and single-catalog reuse are implemented. Persistent delta remains research.

## What delta can cover

| Inventory | Verified support | Implication for this report |
|---|---|---|
| App registrations | v1.0 `/applications/delta`; `Application.Read.All` is accepted; `$select` is supported. Non-ID filters are not supported. | A persisted object cache can replace repeated full registration inventory. [Application delta](https://learn.microsoft.com/en-us/graph/api/application-delta?view=graph-rest-1.0) |
| Enterprise applications | v1.0 `/servicePrincipals/delta`; `Application.Read.All` is accepted; `$select` is supported. Filtering is limited to IDs. | Cache all service-principal records needed by inventory and permission-name resolution, then apply `servicePrincipalType` filtering locally. The current list filter cannot simply be copied to delta. [Service-principal delta](https://learn.microsoft.com/en-us/graph/api/serviceprincipal-delta?view=graph-rest-1.0) |
| Owner contact profiles | v1.0 `/users/delta` accepts `User.Read.All` and `$select`. Selected values can become null; minimal responses omit unchanged fields. | Select `id,displayName,userPrincipalName,employeeId,mail`; merge updates by ID and rebuild contact indexes from the complete cache. [User delta](https://learn.microsoft.com/en-us/graph/api/user-delta?view=graph-rest-1.0) `employeeId` explicitly requires `$select`. [User properties](https://learn.microsoft.com/en-us/graph/api/resources/user?view=graph-rest-1.0) |

`passwordCredentials` and `keyCredentials` are properties of the application and service-principal resources, whereas owners and federation are relationships. Select credential metadata needed by the checks, sanitize it as today, and validate the initial delta response against normal inventory before switching collectors. [Application resource](https://learn.microsoft.com/en-us/graph/api/resources/application?view=graph-rest-1.0), [service-principal resource](https://learn.microsoft.com/en-us/graph/api/resources/serviceprincipal?view=graph-rest-1.0).

## What must remain fresh

The application/service-principal delta references do **not document a completeness guarantee** for owner changes, federation changes, or either app-role-assignment relationship. Relationship expansion support in the ordinary resource APIs is not proof that a relationship-only change will invalidate a parent delta record. This is an unresolved guarantee, rather than a claim that these changes are impossible to observe. Keep explicit relationship reads until separately established and tested. [Application relationships](https://learn.microsoft.com/en-us/graph/api/resources/application?view=graph-rest-1.0), [service-principal relationships](https://learn.microsoft.com/en-us/graph/api/resources/serviceprincipal?view=graph-rest-1.0).

`directoryObjects/delta` documents a separate appRoleAssignment feed, including a combined user/appRoleAssignment example, but does not allow individual-ID tracking for that type. That is a potential later investigation, not sufficient evidence to remove this report's user/group assignments and application permission-grant reads now. [Directory-object delta](https://learn.microsoft.com/en-us/graph/api/directoryobject-delta?view=graph-rest-1.0).

Always rerun local governance and expiry calculations on the full merged inventory. A stored expiry date can cross a policy threshold merely because time passes; local rule/exclusion changes also do not need a directory edit. This is an implementation inference from the distinction between changed directory data and locally calculated results.

## Bookmark requirements

- Bootstrap with a complete delta enumeration. A bookmark alone cannot reconstruct existing inventory.
- Follow every `@odata.nextLink`, including after an empty page; save the final complete `@odata.deltaLink` unchanged.
- Merge by object ID, process `@removed`, and tolerate duplicate/replayed records and delayed changes.
- Directory-object tokens expire after seven days. `410 Gone` or an expired state such as `syncStateNotFound` requires a complete resynchronization. [Delta lifecycle and limitations](https://learn.microsoft.com/en-us/graph/delta-query-overview).

For this pipeline, persist the corresponding object cache and completed bookmarks together only after success. Bind state to tenant, reader identity, query/selected fields and schema; reject incompatible state. Store the user catalog and bookmarks in separate private state storage, outside Pages, report exports and public artifacts. These are proposed implementation safeguards; the current report deliberately retains only owner/contact evidence, not the full user catalog.

## Smallest useful first change

1. Batch the existing independent relationship GET requests in groups of at most 20. Preserve pagination, per-response failures, retries and UNAVAILABLE evidence. This reduces network round trips while keeping full collection coverage; it does not reduce Graph's underlying per-request throttling accounting. [JSON batching](https://learn.microsoft.com/en-us/graph/json-batching).
2. Combine the two service-principal catalog passes where their filtering/selected fields permit it, keeping credential sanitization and complete permission definitions.
3. Add private persistent delta state for users/applications/service principals only if measured collection time still warrants it. Keep relationship reads and local reevaluation; compare incremental runs with full runs before enabling it by default.

Implemented verification: `scripts/Test-CollectionBatch.ps1` compares complete collected evidence and governance results between sequential and batched paths, including owner matching, assignment pagination, permission-name resolution and credential sanitization. Its fixture uses 10 sequential HTTP reads versus 2 batches plus 2 ordinary catalog reads. Separate transport cases cover reversed/missing/duplicate responses, retries, failed optional pages and unsafe/repeated next links. This is a synthetic request-count comparison, not a live speed benchmark.

## Live batching trial

The [trial workflow](https://github.com/semichel/entra-apps-reports/actions/runs/44550342695) completed collection and Pages deployment successfully on 2026-11-19 using commit `b41ee15`. Compared with the [previous successful workflow](https://github.com/semichel/entra-apps-reports/actions/runs/44527823376):

- The Generate report step decreased from 2 minutes 38 seconds to 1 minute 35 seconds, approximately 40% faster. The collector's own timer decreased from 2:35 to 1:32.
- The collector completed 689 relationship collections in 35 batch envelopes and reused the initial principal catalog.
- Both artifacts contain 338 enterprise applications, 13 registrations, 3 enterprise-owner records, 23 assignments and 20 permission grants. Tenant, rule configuration, application/registration evidence and governance results matched after normalizing record ordering and excluding calculated remaining-day fields and diagnostic reason text.
- Module installation took 4 minutes 26 seconds in the trial, making total workflow time longer despite faster generation. Setup timing is separate from collector performance; no module-installation changes were made.

Persistent delta and delta relationship-change experiments remain unimplemented. The largest delta correctness risk is treating an unchanged parent object as proof that its relationships are unchanged.
