param([switch]$BuildWindows)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

# 统一检查外部命令退出码，防止前一步失败后继续报告成功。
function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Command 执行失败，退出码：$LASTEXITCODE"
    }
}

Push-Location (Join-Path $projectRoot 'app')
try {
    Invoke-Checked 'flutter' @('pub', 'get', '--enforce-lockfile')
    Invoke-Checked 'flutter' @('gen-l10n')
    Invoke-Checked 'dart' @('format', '--output=none', '--set-exit-if-changed', 'lib/app', 'lib/features', 'lib/main.dart', 'lib/main_probe.dart', 'test', 'integration_test')
    Invoke-Checked 'flutter' @('analyze', '--fatal-infos')
    Invoke-Checked 'flutter' @('test')
    if ($BuildWindows) {
        Invoke-Checked 'flutter' @('build', 'windows', '--release')
    }
} finally {
    Pop-Location
}

Push-Location (Join-Path $projectRoot 'core')
try {
    Invoke-Checked 'cargo' @('fmt', '--all', '--', '--check')
    Invoke-Checked 'cargo' @('clippy', '--workspace', '--all-targets', '--locked', '--', '-D', 'warnings')
    Invoke-Checked 'cargo' @('test', '--workspace', '--locked')
} finally {
    Pop-Location
}
