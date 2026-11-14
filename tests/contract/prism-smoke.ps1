param(
    [string]$BaseUrl = 'http://127.0.0.1:4010',
    [string]$SpecPath = (Join-Path $PSScriptRoot '..\..\api\openapi.yaml')
)

# Contract smoke tests for api/openapi.yaml (CRUD of domain entities, ADD-002).
# Step 1: the expected status code must be declared in the matching operation of
#   openapi.yaml, otherwise the case fails before any request. Step 2: the request
#   goes to the Prism mock and the actual code is compared with the expected one.
# Prism limitations, Prefer headers and uncovered operations: docs/contract-testing.md.
# ASCII-only file: Windows PowerShell 5.1 reads BOM-less scripts as ANSI, so Cyrillic
#   JSON values use \uXXXX escapes and query values are percent-encoded.

$ErrorActionPreference = 'Stop'

$R = 'reason=entered-by-mistake'
$cases = @(
    # --- Access and sessions (REQ-F-005, REQ-F-013, REQ-F-075) ---
    @{ Type='N'; Name='Client login: invalid body'; Method='POST'; Path='/auth/client-sessions'; Body='{}'; Expected=400 },
    @{ Type='P'; Name='Client login: valid body'; Method='POST'; Path='/auth/client-sessions'; Body='{"phone":"+380671234567","password":"long password with spaces"}'; Expected=200 },
    @{ Type='N'; Name='Staff login: invalid body'; Method='POST'; Path='/auth/staff-sessions'; Body='{}'; Expected=400 },
    @{ Type='N'; Name='Current session: missing bearer'; Method='GET'; Path='/auth/sessions/current'; Expected=401 },
    @{ Type='P'; Name='Current session: read'; Method='GET'; Path='/auth/sessions/current'; Token=$true; Expected=200 },
    @{ Type='P'; Name='Logout: delete current session'; Method='DELETE'; Path='/auth/sessions/current'; Token=$true; Expected=204 },
    @{ Type='N'; Name='Logout: missing bearer'; Method='DELETE'; Path='/auth/sessions/current'; Expected=401 },

    # --- Clients (REQ-F-001, REQ-F-011, REQ-F-034, REQ-F-076) ---
    @{ Type='P'; Name='Clients: create'; Method='POST'; Path='/clients'; Token=$true; Body='{"firstName":"Olena","lastName":"Koval","phone":"+380671234567"}'; Expected=201 },
    @{ Type='N'; Name='Clients: create without phone'; Method='POST'; Path='/clients'; Token=$true; Body='{"firstName":"Olena","lastName":"Koval"}'; Expected=400 },
    @{ Type='P'; Name='Clients: read by id'; Method='GET'; Path='/clients/client-1'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Clients: read unknown id'; Method='GET'; Path='/clients/unknown'; Token=$true; PreferCode=404; Expected=404 },
    @{ Type='P'; Name='Clients: search by phone'; Method='GET'; Path='/clients/search?phone=%2B380671234567'; Token=$true; Expected=200 },
    @{ Type='P'; Name='Clients: update name'; Method='PATCH'; Path='/clients/client-1'; Token=$true; Body='{"firstName":"Olena"}'; Expected=200 },
    @{ Type='N'; Name='Clients: update with empty body'; Method='PATCH'; Path='/clients/client-1'; Token=$true; Body='{}'; Expected=400 },
    @{ Type='P'; Name='Clients: delete mistaken profile'; Method='DELETE'; Path="/clients/client-1?$R"; Token=$true; Expected=204 },
    @{ Type='N'; Name='Clients: delete without reason'; Method='DELETE'; Path='/clients/client-1'; Token=$true; Expected=400 },
    @{ Type='N'; Name='Clients: delete without bearer'; Method='DELETE'; Path="/clients/client-1?$R"; Expected=401 },
    @{ Type='N'; Name='Clients: delete by non-admin'; Method='DELETE'; Path="/clients/client-1?$R"; Token=$true; PreferCode=403; Expected=403 },
    @{ Type='N'; Name='Clients: delete profile with history'; Method='DELETE'; Path="/clients/client-1?$R"; Token=$true; PreferCode=409; Expected=409 },

    # --- Staff accounts (REQ-F-012, REQ-F-015, REQ-F-077, REQ-F-078) ---
    @{ Type='P'; Name='Staff: list'; Method='GET'; Path='/staff-accounts'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Staff: list with invalid role filter'; Method='GET'; Path='/staff-accounts?role=boss'; Token=$true; Expected=400 },
    @{ Type='P'; Name='Staff: create'; Method='POST'; Path='/staff-accounts'; Token=$true; Body='{"login":"vet.ivan","role":"veterinarian"}'; Expected=201 },
    @{ Type='N'; Name='Staff: create with short login'; Method='POST'; Path='/staff-accounts'; Token=$true; Body='{"login":"ab","role":"veterinarian"}'; Expected=400 },
    @{ Type='P'; Name='Staff: read by id'; Method='GET'; Path='/staff-accounts/staff-1'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Staff: read foreign record'; Method='GET'; Path='/staff-accounts/staff-2'; Token=$true; PreferCode=403; Expected=403 },
    @{ Type='P'; Name='Staff: block'; Method='PATCH'; Path='/staff-accounts/staff-1'; Token=$true; Body='{"blocked":true}'; Expected=200 },
    @{ Type='P'; Name='Staff: delete mistaken account'; Method='DELETE'; Path="/staff-accounts/staff-1?$R"; Token=$true; Expected=204 },
    @{ Type='N'; Name='Staff: delete activated account'; Method='DELETE'; Path="/staff-accounts/staff-1?$R"; Token=$true; PreferCode=409; Expected=409 },

    # --- Pets (REQ-F-019..REQ-F-035, REQ-F-079) ---
    @{ Type='N'; Name='Pets: missing bearer'; Method='GET'; Path='/pets'; Expected=401 },
    @{ Type='P'; Name='Pets: search by name part'; Method='GET'; Path='/pets?namePart=%D0%BC%D1%83%D1%80'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Pets: search with invalid microchip'; Method='GET'; Path='/pets?microchip=123'; Token=$true; Expected=400 },
    @{ Type='N'; Name='Pets: invalid create body'; Method='POST'; Path='/pets'; Token=$true; Body='{}'; Expected=400 },
    @{ Type='P'; Name='Pets: valid create body'; Method='POST'; Path='/pets'; Token=$true; Body='{"clientId":"client-smoke-1","name":"Smoke pet","species":"cat","sex":"\u0421\u0430\u043c\u043a\u0430","breed":"mixed","birthDate":"2020-01-01"}'; Expected=201 },
    @{ Type='P'; Name='Pets: read by id'; Method='GET'; Path='/pets/pet-1'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Pets: read unknown id'; Method='GET'; Path='/pets/unknown'; Token=$true; PreferCode=404; Expected=404 },
    @{ Type='P'; Name='Pets: update name'; Method='PATCH'; Path='/pets/pet-1'; Token=$true; Body='{"name":"Murka"}'; Expected=200 },
    @{ Type='N'; Name='Pets: update with empty body'; Method='PATCH'; Path='/pets/pet-1'; Token=$true; Body='{}'; Expected=400 },
    @{ Type='P'; Name='Pets: delete mistaken card'; Method='DELETE'; Path="/pets/pet-1?$R"; Token=$true; Expected=204 },
    @{ Type='N'; Name='Pets: delete without reason'; Method='DELETE'; Path='/pets/pet-1'; Token=$true; Expected=400 },
    @{ Type='N'; Name='Pets: delete card with history'; Method='DELETE'; Path="/pets/pet-1?$R"; Token=$true; PreferCode=409; Expected=409 },

    # --- Pet change proposals (REQ-F-026, REQ-F-029, REQ-F-080) ---
    @{ Type='P'; Name='Proposals: list'; Method='GET'; Path='/pets/pet-1/change-proposals'; Token=$true; Expected=200 },
    @{ Type='P'; Name='Proposals: create'; Method='POST'; Path='/pets/pet-1/change-proposals'; Token=$true; Body='{"proposedData":{"name":"Murka"}}'; Expected=201 },
    @{ Type='P'; Name='Proposals: read by id'; Method='GET'; Path='/pets/pet-1/change-proposals/prop-1'; Token=$true; Expected=200 },
    @{ Type='P'; Name='Proposals: update pending'; Method='PATCH'; Path='/pets/pet-1/change-proposals/prop-1'; Token=$true; Body='{"proposedData":{"name":"Murchyk"}}'; Expected=200 },
    @{ Type='N'; Name='Proposals: update without data'; Method='PATCH'; Path='/pets/pet-1/change-proposals/prop-1'; Token=$true; Body='{}'; Expected=400 },
    @{ Type='N'; Name='Proposals: update after decision'; Method='PATCH'; Path='/pets/pet-1/change-proposals/prop-1'; Token=$true; PreferCode=409; Body='{"proposedData":{"name":"Murchyk"}}'; Expected=409 },
    @{ Type='P'; Name='Proposals: withdraw pending'; Method='DELETE'; Path='/pets/pet-1/change-proposals/prop-1'; Token=$true; Expected=204 },
    @{ Type='N'; Name='Proposals: withdraw after decision'; Method='DELETE'; Path='/pets/pet-1/change-proposals/prop-1'; Token=$true; PreferCode=409; Expected=409 },

    # --- Staff schedules and slots (REQ-F-036..REQ-F-039, REQ-F-081) ---
    @{ Type='P'; Name='Schedule: read for date'; Method='GET'; Path='/staff-schedules/vet-1/2030-01-15'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Schedule: invalid date'; Method='GET'; Path='/staff-schedules/vet-1/not-a-date'; Token=$true; Expected=400 },
    @{ Type='P'; Name='Schedule: set for date'; Method='PUT'; Path='/staff-schedules/vet-1/2030-01-15'; Token=$true; Body='{"intervals":[{"start":"09:00","end":"13:00"},{"start":"14:00","end":"18:00"}]}'; Expected=200 },
    @{ Type='N'; Name='Schedule: set with invalid time'; Method='PUT'; Path='/staff-schedules/vet-1/2030-01-15'; Token=$true; Body='{"intervals":[{"start":"9am","end":"13:00"}]}'; Expected=400 },
    @{ Type='P'; Name='Schedule: delete for date'; Method='DELETE'; Path='/staff-schedules/vet-1/2030-01-15'; Token=$true; Expected=204 },
    @{ Type='N'; Name='Schedule: delete with booked appointment'; Method='DELETE'; Path='/staff-schedules/vet-1/2030-01-15'; Token=$true; PreferCode=409; Expected=409 },
    @{ Type='N'; Name='Slots: missing bearer'; Method='GET'; Path='/appointment-slots?date=2026-11-10'; Expected=401 },
    @{ Type='P'; Name='Slots: valid request'; Method='GET'; Path='/appointment-slots?date=2026-11-10'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Slots: invalid date'; Method='GET'; Path='/appointment-slots?date=not-a-date'; Token=$true; Expected=400 },
    @{ Type='N'; Name='Slots: missing date'; Method='GET'; Path='/appointment-slots'; Token=$true; Expected=400 },

    # --- Appointments (REQ-F-039..REQ-F-048, REQ-F-082) ---
    @{ Type='P'; Name='Appointments: list'; Method='GET'; Path='/appointments?petId=pet-1'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Appointments: invalid create body'; Method='POST'; Path='/appointments'; Token=$true; Body='{}'; Expected=400 },
    @{ Type='P'; Name='Appointments: valid create body'; Method='POST'; Path='/appointments'; Token=$true; PreferCode=201; Body='{"clientId":"client-smoke-1","petId":"pet-smoke-1","veterinarianId":"vet-smoke-1","startsAt":"2030-01-15T10:00:00+02:00","idempotencyKey":"smoke-appointment-001"}'; Expected=201 },
    @{ Type='P'; Name='Appointments: read by id'; Method='GET'; Path='/appointments/apt-1'; Token=$true; Expected=200 },
    @{ Type='P'; Name='Appointments: reschedule'; Method='PATCH'; Path='/appointments/apt-1'; Token=$true; Body='{"veterinarianId":"vet-1","startsAt":"2030-01-15T10:20:00+02:00"}'; Expected=200 },
    @{ Type='P'; Name='Appointments: delete mistaken entry'; Method='DELETE'; Path="/appointments/apt-1?$R"; Token=$true; Expected=204 },
    @{ Type='N'; Name='Appointments: delete conducted appointment'; Method='DELETE'; Path="/appointments/apt-1?$R"; Token=$true; PreferCode=409; Expected=409 },

    # --- Medical records (REQ-F-054..REQ-F-062, REQ-F-083) ---
    @{ Type='N'; Name='Medical history: missing bearer'; Method='GET'; Path='/pets/pet-1/medical-records'; Expected=401 },
    @{ Type='P'; Name='Medical history: list with bearer'; Method='GET'; Path='/pets/pet-smoke-1/medical-records'; Token=$true; Expected=200 },
    @{ Type='P'; Name='Medical records: create lab result'; Method='POST'; Path='/pets/pet-1/medical-records'; Token=$true; Body='{"recordType":"\u0430\u043d\u0430\u043b\u0456\u0437","name":"Blood test","performedDate":"2026-11-10"}'; Expected=201 },
    @{ Type='N'; Name='Medical records: create without type'; Method='POST'; Path='/pets/pet-1/medical-records'; Token=$true; Body='{}'; Expected=400 },
    @{ Type='P'; Name='Medical records: read by id'; Method='GET'; Path='/medical-records/rec-1'; Token=$true; Expected=200 },    @{ Type='N'; Name='Medical records: delete is refused'; Method='DELETE'; Path='/medical-records/rec-1'; Token=$true; PreferCode=409; Expected=409 },

    # --- Referrals (REQ-F-065, REQ-F-084) ---
    @{ Type='P'; Name='Referrals: create'; Method='POST'; Path='/pets/pet-1/referrals'; Token=$true; Body='{"issuedDate":"2026-11-10","prescribed":"Ultrasound","direction":"\u043e\u0431\u0441\u0442\u0435\u0436\u0435\u043d\u043d\u044f"}'; Expected=201 },
    @{ Type='N'; Name='Referrals: create without prescribed item'; Method='POST'; Path='/pets/pet-1/referrals'; Token=$true; Body='{"issuedDate":"2026-11-10"}'; Expected=400 },
    @{ Type='P'; Name='Referrals: list for pet'; Method='GET'; Path='/pets/pet-1/referrals'; Token=$true; Expected=200 },
    @{ Type='P'; Name='Referrals: read by id'; Method='GET'; Path='/referrals/ref-1'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Referrals: read by administrator'; Method='GET'; Path='/referrals/ref-1'; Token=$true; PreferCode=403; Expected=403 },
    @{ Type='P'; Name='Referrals: revise with reason'; Method='PATCH'; Path='/referrals/ref-1'; Token=$true; Body='{"reason":"Typo","prescribed":"Abdominal ultrasound"}'; Expected=200 },
    @{ Type='N'; Name='Referrals: revise without reason'; Method='PATCH'; Path='/referrals/ref-1'; Token=$true; Body='{"prescribed":"Abdominal ultrasound"}'; Expected=400 },
    @{ Type='P'; Name='Referrals: annul'; Method='DELETE'; Path="/referrals/ref-1?$R"; Token=$true; Expected=204 },
    @{ Type='N'; Name='Referrals: annul twice'; Method='DELETE'; Path="/referrals/ref-1?$R"; Token=$true; PreferCode=409; Expected=409 },

    # --- Recommendations (REQ-F-064..REQ-F-072, REQ-F-085) ---
    @{ Type='P'; Name='Recommendations: waiting list'; Method='GET'; Path='/recommendations'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Recommendations: invalid create body'; Method='POST'; Path='/recommendations'; Token=$true; Body='{}'; Expected=400 },
    @{ Type='P'; Name='Recommendations: create home recommendation'; Method='POST'; Path='/recommendations'; Token=$true; Body='{"petId":"pet-1","format":"\u0412\u0434\u043e\u043c\u0430","recommendationText":"Watch appetite","recommendedDate":"2026-11-20","homeInstruction":"Keep water available"}'; Expected=201 },
    @{ Type='P'; Name='Recommendations: list for pet'; Method='GET'; Path='/pets/pet-1/recommendations'; Token=$true; Expected=200 },
    @{ Type='P'; Name='Recommendations: read by id'; Method='GET'; Path='/recommendations/rcm-1'; Token=$true; Expected=200 },
    @{ Type='N'; Name='Recommendations: read by administrator'; Method='GET'; Path='/recommendations/rcm-1'; Token=$true; PreferCode=403; Expected=403 },
    @{ Type='P'; Name='Recommendations: revise with reason'; Method='PATCH'; Path='/recommendations/rcm-1'; Token=$true; Body='{"reason":"Clarification","recommendationText":"Watch appetite daily"}'; Expected=200 },
    @{ Type='P'; Name='Recommendations: delete mistaken one'; Method='DELETE'; Path="/recommendations/rcm-1?$R"; Token=$true; Expected=204 },
    @{ Type='N'; Name='Recommendations: delete without reason'; Method='DELETE'; Path='/recommendations/rcm-1'; Token=$true; Expected=400 },
    @{ Type='N'; Name='Recommendations: delete booked one'; Method='DELETE'; Path="/recommendations/rcm-1?$R"; Token=$true; PreferCode=409; Expected=409 }
)

# ---------- Step 1: declared status codes from openapi.yaml ----------
function Get-DeclaredResponses([string]$path) {
    $map = @{}
    $currentPath = $null; $currentMethod = $null; $inResponses = $false
    foreach ($line in (Get-Content -LiteralPath $path -Encoding UTF8)) {
        if ($line -match '^components:') { break }
        if ($line -match '^  (/\S*):\s*$') { $currentPath = $Matches[1]; $currentMethod = $null; $inResponses = $false; continue }
        if ($line -match '^    (get|post|put|patch|delete):\s*$') {
            $currentMethod = $Matches[1].ToUpper(); $inResponses = $false
            $map["$currentMethod $currentPath"] = New-Object System.Collections.Generic.List[string]
            continue
        }
        if ($null -eq $currentMethod) { continue }
        if ($line -match '^      responses:\s*$') { $inResponses = $true; continue }
        if ($line -match '^      \S') { $inResponses = $false; continue }
        if ($inResponses -and $line -match "^        '?(\d{3}|default)'?:") { $map["$currentMethod $currentPath"].Add($Matches[1]) }
    }
    return $map
}

function Find-Operation($declared, [string]$method, [string]$requestPath) {
    $pathOnly = $requestPath.Split('?')[0]
    $best = $null; $bestParams = [int]::MaxValue
    foreach ($key in $declared.Keys) {
        $parts = $key.Split(' ', 2)
        if ($parts[0] -ne $method) { continue }
        $regex = '^' + ([regex]::Escape($parts[1]) -replace '\\\{[^}]+\}', '[^/]+') + '$'
        if ($pathOnly -match $regex) {
            $params = ([regex]::Matches($parts[1], '\{')).Count
            if ($params -lt $bestParams) { $best = $key; $bestParams = $params }
        }
    }
    return $best
}

$declared = Get-DeclaredResponses (Resolve-Path $SpecPath)
Write-Host "Contract: api/openapi.yaml ($($declared.Count) operations)"

# ---------- Step 2: run cases ----------
$passed = 0
$failed = 0
foreach ($case in $cases) {
    $operation = Find-Operation $declared $case.Method $case.Path
    $status = $null
    $actual = ''
    if ($null -eq $operation) {
        $status = 'FAIL'; $actual = 'operation not in contract'
    } elseif (-not $declared[$operation].Contains([string]$case.Expected)) {
        $status = 'FAIL'; $actual = "HTTP $($case.Expected) not declared for $operation"
    } else {
        $url = $BaseUrl.TrimEnd('/') + $case.Path
        $headers = @{}
        if ($case.Token) { $headers['Authorization'] = 'Bearer test-token' }
        if ($case.PreferCode) { $headers['Prefer'] = "code=$($case.PreferCode)" }
        $request = @{ Uri=$url; Method=$case.Method; Headers=$headers; UseBasicParsing=$true; ErrorAction='Stop' }
        if ($null -ne $case.Body) {
            $request['Body'] = $case.Body
            $request['ContentType'] = 'application/json'
        }
        $code = 0
        try {
            $response = Invoke-WebRequest @request
            $code = [int]$response.StatusCode
        } catch {
            if ($null -ne $_.Exception.Response) {
                $code = [int]$_.Exception.Response.StatusCode
            } else {
                $actual = $_.Exception.Message
            }
        }
        if ($code -ne 0) { $actual = "HTTP $code" }
        if ($code -eq $case.Expected) { $status = 'PASS' } else { $status = 'FAIL' }
    }
    $type = if ($case.Type -eq 'P') { 'positive' } else { 'negative' }
    if ($status -eq 'PASS') {
        Write-Host ("PASS  [{0}] {1} [{2}]" -f $type, $case.Name, $actual) -ForegroundColor Green
        $passed++
    } else {
        Write-Host ("FAIL  [{0}] {1} [expected {2}, got {3}]" -f $type, $case.Name, $case.Expected, $actual) -ForegroundColor Red
        $failed++
    }
}

$positive = @($cases | Where-Object { $_.Type -eq 'P' }).Count
$negative = @($cases | Where-Object { $_.Type -eq 'N' }).Count
Write-Host "`nResult: $passed PASS; $failed FAIL; $($cases.Count) total ($positive positive, $negative negative)"
if ($failed -gt 0) { exit 1 }
