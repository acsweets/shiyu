param([switch]$InstallTools)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$toolRoot = Join-Path $projectRoot '.tooling/frb'
$generator = Join-Path $toolRoot ('bin/flutter_rust_bridge_codegen' + $(if ($IsWindows) { '.exe' } else { '' }))
$savedPath = $env:PATH

# 生成工具安装在本仓库忽略目录，不修改其他项目的全局工具版本。
function Invoke-Checked {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command 失败：$LASTEXITCODE" }
}

# 固定生成文本的行尾格式，清理上游模板空白；不修改接口或生成内容的语义。
function Format-GeneratedText {
    param([string]$FilePath)
    $generatedText = [IO.File]::ReadAllText($FilePath)
    $generatedText = [regex]::Replace($generatedText, '[ \t]+(?=\r?$)', '', [Text.RegularExpressions.RegexOptions]::Multiline)
    $generatedText = $generatedText.TrimEnd([char[]]"`r`n") + "`n"
    [IO.File]::WriteAllText($FilePath, $generatedText, [Text.UTF8Encoding]::new($false))
}

if ($InstallTools) {
    Invoke-Checked 'cargo' @('install', 'flutter_rust_bridge_codegen', '--version', '2.12.0', '--locked', '--root', $toolRoot)
    Invoke-Checked 'cargo' @('install', 'cargo-expand', '--version', '1.0.127', '--locked', '--root', $toolRoot)
}
if (-not (Test-Path -LiteralPath $generator)) { throw '请先运行 generate_bindings.ps1 -InstallTools' }

$env:PATH = (Join-Path $toolRoot 'bin') + [IO.Path]::PathSeparator + $savedPath
Push-Location (Join-Path $projectRoot 'app')
try {
    Invoke-Checked 'flutter' @('pub', 'get', '--enforce-lockfile')
    Invoke-Checked $generator @('generate')
} finally {
    Pop-Location
    $env:PATH = $savedPath
}

Push-Location (Join-Path $projectRoot 'core')
try {
    Invoke-Checked 'cargo' @('build', '-p', 'shiyu_ffi', '--locked')
    $metadata = (& cargo metadata --format-version 1 --no-deps | ConvertFrom-Json)
    if ($LASTEXITCODE -ne 0) { throw '读取 Cargo 路径失败' }
    $libraryName = if ($IsWindows) { 'shiyu_ffi.dll' } elseif ($IsMacOS) { 'libshiyu_ffi.dylib' } else { 'libshiyu_ffi.so' }
    $library = Join-Path $metadata.target_directory "debug/$libraryName"
    Invoke-Checked 'cargo' @('run', '-p', 'shiyu_bindgen', '--locked', '--', 'generate', '--library', $library, '--language', 'kotlin', '--no-format', '--out-dir', '../app/android/app/src/main/kotlin')
    Invoke-Checked 'cargo' @('run', '-p', 'shiyu_bindgen', '--locked', '--', 'generate', '--library', $library, '--language', 'swift', '--no-format', '--out-dir', '../native/ios/Generated')
    Invoke-Checked 'cargo' @('fmt', '--all')
    foreach ($generatedFile in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'native/ios/Generated') -File) {
        Format-GeneratedText $generatedFile.FullName
    }
    Format-GeneratedText (Join-Path $projectRoot 'app/android/app/src/main/kotlin/com/growthrecord/shiyu/core/shiyu_ffi.kt')
} finally {
    Pop-Location
}
