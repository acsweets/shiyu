param(
    [Parameter(Mandatory = $true)]
    [string]$Executable
)

$ErrorActionPreference = 'Stop'
$binary = Get-Item -LiteralPath $Executable
if ($binary.PSIsContainer -or $binary.Name -ine 'shiyu.exe') {
    throw '请指定时余发布目录中的 shiyu.exe。'
}

$program = 'Shiyu.TimerPack'
$classes = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Software\Classes')
try {
    $type = $classes.CreateSubKey($program)
    try {
        $type.SetValue('', 'Shiyu Timer Pack')
        $open = $type.CreateSubKey('shell\open\command')
        try {
            $open.SetValue('', ('"{0}" "%1"' -f $binary.FullName))
        } finally {
            $open.Dispose()
        }
    } finally {
        $type.Dispose()
    }

    $registered = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey('.timerpack')
    $current = $null
    if ($null -ne $registered) {
        try {
            $current = $registered.GetValue('')
        } finally {
            $registered.Dispose()
        }
    }
    $extension = $classes.CreateSubKey('.timerpack')
    try {
        if (-not $current) {
            $extension.SetValue('', $program)
        }
        $choices = $extension.CreateSubKey('OpenWithProgids')
        try {
            $choices.SetValue($program, [byte[]]@(), [Microsoft.Win32.RegistryValueKind]::None)
        } finally {
            $choices.Dispose()
        }
    } finally {
        $extension.Dispose()
    }
} finally {
    $classes.Dispose()
}

Write-Output '已注册时余皮肤包文件类型。如果 Windows 已绑定其他应用，请在“打开方式”中选择时余。'
