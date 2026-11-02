param([string]$BaseUrl = 'http://127.0.0.1:4010')

$ErrorActionPreference = 'Stop'
$cases = @(
    @{ Name='Slots: missing bearer'; Method='GET'; Path='/appointment-slots?date=2026-11-10'; Expected=401 },
    @{ Name='Slots: valid request'; Method='GET'; Path='/appointment-slots?date=2026-11-10'; Token=$true; Expected=200 },
    @{ Name='Slots: invalid date'; Method='GET'; Path='/appointment-slots?date=not-a-date'; Token=$true; Expected=400 },
    @{ Name='Slots: missing date'; Method='GET'; Path='/appointment-slots'; Token=$true; Expected=400 },
    @{ Name='Pets: missing bearer'; Method='GET'; Path='/pets'; Expected=401 },
    @{ Name='Pets: invalid create body'; Method='POST'; Path='/pets'; Token=$true; Body='{}'; Expected=400 },
    @{ Name='Appointments: invalid create body'; Method='POST'; Path='/appointments'; Token=$true; Body='{}'; Expected=400 },
    @{ Name='Medical history: missing bearer'; Method='GET'; Path='/pets/pet-1/medical-records'; Expected=401 },
    @{ Name='Recommendations: list'; Method='GET'; Path='/recommendations'; Token=$true; Expected=200 },
    @{ Name='Recommendations: invalid create body'; Method='POST'; Path='/recommendations'; Token=$true; Body='{}'; Expected=400 },
    @{ Name='Client login: invalid body'; Method='POST'; Path='/auth/client-sessions'; Body='{}'; Expected=422 }
)

$passed = 0
$failed = 0
foreach ($case in $cases) {
    $url = $BaseUrl.TrimEnd('/') + $case.Path
    $headers = @{}
    if ($case.Token) { $headers['Authorization'] = 'Bearer test-token' }
    $request = @{ Uri=$url; Method=$case.Method; Headers=$headers; UseBasicParsing=$true; ErrorAction='Stop' }
    if ($null -ne $case.Body) {
        $request['Body'] = $case.Body
        $request['ContentType'] = 'application/json'
    }
    $actual = 0
    try {
        $response = Invoke-WebRequest @request
        $actual = [int]$response.StatusCode
    } catch {
        if ($null -ne $_.Exception.Response) {
            $actual = [int]$_.Exception.Response.StatusCode
        } else {
            Write-Host "ERROR $($case.Name): $($_.Exception.Message)" -ForegroundColor Red
            $failed++
            continue
        }
    }
    if ($actual -eq $case.Expected) {
        Write-Host "PASS  $($case.Name) [HTTP $actual]" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "FAIL  $($case.Name) [expected $($case.Expected), got $actual]" -ForegroundColor Red
        $failed++
    }
}
Write-Host "`nResult: $passed PASS; $failed FAIL; $($cases.Count) total"
if ($failed -gt 0) { exit 1 }
