param(
    [string]$AndroidDeviceId,
    [string]$GradleUserHome
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$savedGradleUserHome = $env:GRADLE_USER_HOME

function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command 失败：$LASTEXITCODE" }
}

if ($GradleUserHome) { $env:GRADLE_USER_HOME = (Resolve-Path -LiteralPath $GradleUserHome).Path }
Push-Location (Join-Path $projectRoot 'app')
try {
    if ($IsWindows) {
        Invoke-Checked 'flutter' @('test', 'integration_test/bridge_test.dart', '-d', 'windows')
        Invoke-Checked 'flutter' @('test', 'integration_test/desktop_window_test.dart', '-d', 'windows')
    }
    if ($AndroidDeviceId) {
        Invoke-Checked 'flutter' @('test', 'integration_test/bridge_test.dart', '-d', $AndroidDeviceId)
    }
    if (-not $IsWindows -and -not $AndroidDeviceId) { throw '请指定 AndroidDeviceId，Apple 平台使用 check_apple.sh' }
} finally {
    Pop-Location
    $env:GRADLE_USER_HOME = $savedGradleUserHome
}
