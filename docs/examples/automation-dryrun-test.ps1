param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("radarr", "sonarr")]
    [string]$Source,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Path,

    [Parameter(Position = 2)]
    [string]$Profile = ""
)

$ErrorActionPreference = "Stop"

$automationUrl = $env:MEDIASTAT_AUTOMATION_URL
$automationToken = $env:MEDIASTAT_AUTOMATION_TOKEN

if ([string]::IsNullOrWhiteSpace($automationUrl)) {
    throw "Set MEDIASTAT_AUTOMATION_URL to the MediaStat automation endpoint, for example http://localhost:8080/automation/queue"
}

if ([string]::IsNullOrWhiteSpace($automationToken)) {
    throw "Set MEDIASTAT_AUTOMATION_TOKEN before running this test"
}

$automationUrl = $automationUrl.TrimEnd("/")
if (-not $automationUrl.EndsWith("/automation/queue")) {
    $automationUrl = "$automationUrl/automation/queue"
}

$payload = @{
    source = $Source
    event = "import"
    path = $Path
    post_action = "keep"
    category = ""
}

if (-not [string]::IsNullOrWhiteSpace($Profile)) {
    $payload.profile = $Profile
}

$json = $payload | ConvertTo-Json -Depth 5

try {
    $response = Invoke-WebRequest `
        -Uri $automationUrl `
        -Method Post `
        -Headers @{ "X-Automation-Token" = $automationToken } `
        -ContentType "application/json" `
        -Body $json `
        -UseBasicParsing

    Write-Host "HTTP status: $($response.StatusCode)"
    Write-Host "Response body:"
    Write-Output $response.Content
} catch {
    $status = "n/a"
    if ($_.Exception.Response) {
        $status = [int]$_.Exception.Response.StatusCode
    }
    Write-Host "HTTP status: $status"
    Write-Host "Response body:"
    if ($_.ErrorDetails.Message) {
        Write-Output $_.ErrorDetails.Message
    } elseif ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Output $reader.ReadToEnd()
    } else {
        Write-Output $_.Exception.Message
    }
    exit 1
}
