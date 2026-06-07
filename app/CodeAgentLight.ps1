param(
    [string]$StatePath = (Join-Path (Split-Path -Parent $PSScriptRoot) "runtime\status.json"),
    [string[]]$ProcessNames = @("codex", "codeagent"),
    [int]$PollMilliseconds = 750
)

$ErrorActionPreference = "Stop"
$runtimePath = Join-Path (Split-Path -Parent $PSScriptRoot) "runtime"
New-Item -ItemType Directory -Path $runtimePath -Force | Out-Null
$logPath = Join-Path $runtimePath "widget.log"
$settingsPath = Join-Path $runtimePath "settings.json"

trap {
    $entry = "[{0}] {1}`r`n{2}`r`n" -f (
        [DateTimeOffset]::Now.ToString("o"),
        $_.Exception.Message,
        $_.ScriptStackTrace
    )
    Add-Content -LiteralPath $logPath -Value $entry -Encoding UTF8
    [System.Windows.MessageBox]::Show(
        "Code Agent Light failed to start.`n`n$($_.Exception.Message)`n`nLog: $logPath",
        "Code Agent Light",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    break
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class NativeIcon {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool DestroyIcon(IntPtr handle);
}
"@

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        Topmost="True"
        ShowInTaskbar="False"
        Width="92"
        Height="238"
        ResizeMode="NoResize">
    <Border CornerRadius="24"
            Background="#E6121720"
            BorderBrush="#55394350"
            BorderThickness="1"
            Padding="13">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="24"/>
            </Grid.RowDefinitions>

            <Ellipse x:Name="RedLight" Grid.Row="0" Width="52" Height="52"
                     Fill="#3A171A" Stroke="#663A404B" StrokeThickness="2"/>
            <Ellipse x:Name="YellowLight" Grid.Row="1" Width="52" Height="52"
                     Fill="#3A3216" Stroke="#663A404B" StrokeThickness="2">
                <Ellipse.Effect>
                    <DropShadowEffect x:Name="YellowGlow"
                                      Color="#FFC83D"
                                      BlurRadius="0"
                                      ShadowDepth="0"
                                      Opacity="0"/>
                </Ellipse.Effect>
            </Ellipse>
            <Ellipse x:Name="GreenLight" Grid.Row="2" Width="52" Height="52"
                     Fill="#163A27" Stroke="#663A404B" StrokeThickness="2"/>
            <TextBlock x:Name="StatusText" Grid.Row="3"
                       HorizontalAlignment="Center"
                       VerticalAlignment="Center"
                       Foreground="#D9E0EA"
                       FontFamily="Segoe UI"
                       FontSize="10"
                       Text="DONE"/>
        </Grid>
    </Border>
</Window>
"@

$reader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
$redLight = $window.FindName("RedLight")
$yellowLight = $window.FindName("YellowLight")
$greenLight = $window.FindName("GreenLight")
$statusText = $window.FindName("StatusText")
$yellowGlow = $window.FindName("YellowGlow")

$script:language = "en"
$script:notificationSound = "asterisk"
if (Test-Path -LiteralPath $settingsPath) {
    try {
        $savedSettings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
        if ($savedSettings.language -in @("en", "zh-CN")) {
            $script:language = [string]$savedSettings.language
        }
        if ($savedSettings.notificationSound -in @(
            "asterisk",
            "exclamation",
            "question",
            "beep",
            "none"
        )) {
            $script:notificationSound = [string]$savedSettings.notificationSound
        }
    }
    catch {
        # Ignore malformed optional settings and use English.
    }
}

$translationsPath = Join-Path $PSScriptRoot "translations.json"
$translations = Get-Content -LiteralPath $translationsPath -Raw -Encoding UTF8 |
    ConvertFrom-Json

function New-TrafficLightIcon([string]$activeStatus) {
    $bitmap = [System.Drawing.Bitmap]::new(
        32,
        32,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $housingPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $housingPath.AddArc(7, 1, 8, 8, 180, 90)
    $housingPath.AddArc(17, 1, 8, 8, 270, 90)
    $housingPath.AddArc(17, 23, 8, 8, 0, 90)
    $housingPath.AddArc(7, 23, 8, 8, 90, 90)
    $housingPath.CloseFigure()

    $housingBrush = [System.Drawing.SolidBrush]::new(
        [System.Drawing.Color]::FromArgb(255, 24, 28, 34)
    )
    $housingPen = [System.Drawing.Pen]::new(
        [System.Drawing.Color]::FromArgb(255, 92, 100, 112),
        1.2
    )
    $graphics.FillPath($housingBrush, $housingPath)
    $graphics.DrawPath($housingPen, $housingPath)

    $lights = @(
        @{ status = "done"; y = 4; on = "#FF3948"; off = "#54232A" },
        @{ status = "waiting"; y = 12; on = "#FFC83D"; off = "#59491F" },
        @{ status = "running"; y = 20; on = "#31D17C"; off = "#214C35" }
    )

    foreach ($light in $lights) {
        $color = if ($activeStatus -eq $light.status) {
            [System.Drawing.ColorTranslator]::FromHtml($light.on)
        }
        else {
            [System.Drawing.ColorTranslator]::FromHtml($light.off)
        }
        $lightBrush = [System.Drawing.SolidBrush]::new($color)
        $graphics.FillEllipse($lightBrush, 12, $light.y, 8, 8)
        $lightBrush.Dispose()
    }

    $handle = $bitmap.GetHicon()
    try {
        return [System.Drawing.Icon]::FromHandle($handle).Clone()
    }
    finally {
        [void][NativeIcon]::DestroyIcon($handle)
        $housingPen.Dispose()
        $housingBrush.Dispose()
        $housingPath.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$trayIcons = @{
    running = New-TrafficLightIcon "running"
    waiting = New-TrafficLightIcon "waiting"
    done = New-TrafficLightIcon "done"
}

$notifyIcon = [System.Windows.Forms.NotifyIcon]::new()
$notifyIcon.Icon = $trayIcons.done
$notifyIcon.Text = "Code Agent Light"
$notifyIcon.Visible = $true

$trayMenu = [System.Windows.Forms.ContextMenuStrip]::new()
$showMenuItem = $trayMenu.Items.Add("")
$hideMenuItem = $trayMenu.Items.Add("")
$languageMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
[void]$trayMenu.Items.Add($languageMenuItem)
$englishMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
$chineseMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
[void]$languageMenuItem.DropDownItems.Add($englishMenuItem)
[void]$languageMenuItem.DropDownItems.Add($chineseMenuItem)
$soundMenuItem = [System.Windows.Forms.ToolStripMenuItem]::new()
[void]$trayMenu.Items.Add($soundMenuItem)
$soundMenuItems = @{}
foreach ($soundName in @("asterisk", "exclamation", "question", "beep", "none")) {
    $item = [System.Windows.Forms.ToolStripMenuItem]::new()
    $item.Tag = $soundName
    [void]$soundMenuItem.DropDownItems.Add($item)
    $soundMenuItems[$soundName] = $item
}
[void]$trayMenu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new())
$exitMenuItem = $trayMenu.Items.Add("")
$notifyIcon.ContextMenuStrip = $trayMenu

$workArea = [Windows.SystemParameters]::WorkArea
$window.Left = $workArea.Right - $window.Width - 24
$window.Top = $workArea.Bottom - $window.Height - 24

$offColors = @{
    red = "#3A171A"
    yellow = "#3A3216"
    green = "#163A27"
}

$onColors = @{
    red = "#FF3948"
    yellow = "#FFC83D"
    green = "#31D17C"
}

function New-Brush([string]$color) {
    return [Windows.Media.BrushConverter]::new().ConvertFromString($color)
}

$yellowOpacityAnimation = [Windows.Media.Animation.DoubleAnimation]::new()
$yellowOpacityAnimation.From = 0.45
$yellowOpacityAnimation.To = 1.0
$yellowOpacityAnimation.Duration = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(900))
$yellowOpacityAnimation.AutoReverse = $true
$yellowOpacityAnimation.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever

$yellowGlowAnimation = [Windows.Media.Animation.DoubleAnimation]::new()
$yellowGlowAnimation.From = 0.2
$yellowGlowAnimation.To = 0.95
$yellowGlowAnimation.Duration = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(900))
$yellowGlowAnimation.AutoReverse = $true
$yellowGlowAnimation.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever

$yellowBlurAnimation = [Windows.Media.Animation.DoubleAnimation]::new()
$yellowBlurAnimation.From = 4
$yellowBlurAnimation.To = 18
$yellowBlurAnimation.Duration = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(900))
$yellowBlurAnimation.AutoReverse = $true
$yellowBlurAnimation.RepeatBehavior = [Windows.Media.Animation.RepeatBehavior]::Forever

function Start-YellowPulse {
    $yellowLight.BeginAnimation(
        [Windows.UIElement]::OpacityProperty,
        $yellowOpacityAnimation
    )
    $yellowGlow.BeginAnimation(
        [Windows.Media.Effects.DropShadowEffect]::OpacityProperty,
        $yellowGlowAnimation
    )
    $yellowGlow.BeginAnimation(
        [Windows.Media.Effects.DropShadowEffect]::BlurRadiusProperty,
        $yellowBlurAnimation
    )
}

function Stop-YellowPulse {
    $yellowLight.BeginAnimation([Windows.UIElement]::OpacityProperty, $null)
    $yellowGlow.BeginAnimation(
        [Windows.Media.Effects.DropShadowEffect]::OpacityProperty,
        $null
    )
    $yellowGlow.BeginAnimation(
        [Windows.Media.Effects.DropShadowEffect]::BlurRadiusProperty,
        $null
    )
    $yellowLight.Opacity = 1
    $yellowGlow.Opacity = 0
    $yellowGlow.BlurRadius = 0
}

$script:currentStatus = $null
$script:currentMessage = $null
$script:allowExit = $false

function Get-Text([string]$key) {
    $languagePack = $translations.PSObject.Properties[$script:language].Value
    return [string]$languagePack.PSObject.Properties[$key].Value
}

function Save-Settings {
    [ordered]@{
        language = $script:language
        notificationSound = $script:notificationSound
    } | ConvertTo-Json | Set-Content -LiteralPath $settingsPath -Encoding UTF8
}

function Update-MenuLanguage {
    $showMenuItem.Text = Get-Text "show"
    $hideMenuItem.Text = Get-Text "hide"
    $languageMenuItem.Text = Get-Text "language"
    $englishMenuItem.Text = Get-Text "english"
    $chineseMenuItem.Text = Get-Text "chinese"
    $soundMenuItem.Text = Get-Text "notificationSound"
    foreach ($soundName in $soundMenuItems.Keys) {
        $soundMenuItems[$soundName].Text = Get-Text "sound_$soundName"
        $soundMenuItems[$soundName].Checked =
            $script:notificationSound -eq $soundName
    }
    $exitMenuItem.Text = Get-Text "exit"
    $englishMenuItem.Checked = $script:language -eq "en"
    $chineseMenuItem.Checked = $script:language -eq "zh-CN"
}

$soundFiles = @{
    asterisk = Join-Path $env:WINDIR "Media\ding.wav"
    exclamation = Join-Path $env:WINDIR "Media\chord.wav"
    question = Join-Path $env:WINDIR "Media\chimes.wav"
    beep = Join-Path $env:WINDIR "Media\notify.wav"
}

$soundPlayers = @{}
foreach ($soundName in $soundFiles.Keys) {
    $soundPath = $soundFiles[$soundName]
    if (Test-Path -LiteralPath $soundPath) {
        $soundPlayers[$soundName] = [System.Media.SoundPlayer]::new($soundPath)
        $soundPlayers[$soundName].LoadAsync()
    }
}

function Play-NotificationSound(
    [string]$soundName = $script:notificationSound
) {
    if ($soundPlayers.ContainsKey($soundName)) {
        $soundPlayers[$soundName].Play()
    }
}

function Show-Widget {
    $window.Show()
    $window.Activate()
    $window.Topmost = $true
}

function Hide-Widget {
    $window.Hide()
}

function Set-LightState(
    [string]$status,
    [string]$message,
    [bool]$playTransitionSound = $true
) {
    $statusChanged = $script:currentStatus -ne $status

    $redLight.Fill = New-Brush $offColors.red
    $yellowLight.Fill = New-Brush $offColors.yellow
    $greenLight.Fill = New-Brush $offColors.green

    if ($status -ne "waiting" -and $script:currentStatus -eq "waiting") {
        Stop-YellowPulse
    }

    switch ($status) {
        "running" {
            $greenLight.Fill = New-Brush $onColors.green
            $statusText.Text = Get-Text "running"
        }
        "waiting" {
            $yellowLight.Fill = New-Brush $onColors.yellow
            $statusText.Text = Get-Text "waiting"
            if ($statusChanged) {
                Start-YellowPulse
                if ($playTransitionSound -and $null -ne $script:currentStatus) {
                    Play-NotificationSound
                }
            }
        }
        default {
            $redLight.Fill = New-Brush $onColors.red
            $statusText.Text = Get-Text "done"
        }
    }

    $script:currentStatus = $status
    $script:currentMessage = $message
    $notifyIcon.Icon = if ($trayIcons.ContainsKey($status)) {
        $trayIcons[$status]
    }
    else {
        $trayIcons.done
    }
    $window.ToolTip = if ($message) { $message } else { $statusText.Text }
    $trayMessage = if ($message) { $message } else { $statusText.Text }
    $notifyText = "Code Agent Light - $($statusText.Text)"
    $notifyIcon.Text = $notifyText.Substring(0, [Math]::Min(63, $notifyText.Length))
    $notifyIcon.BalloonTipTitle = "Code Agent Light"
    $notifyIcon.BalloonTipText = $trayMessage
}

function Set-Language([string]$language) {
    if ($language -notin @("en", "zh-CN")) {
        return
    }

    $script:language = $language
    Save-Settings
    Update-MenuLanguage

    if ($script:currentStatus) {
        Set-LightState $script:currentStatus $script:currentMessage $false
    }
}

function Set-NotificationSound([string]$soundName) {
    if ($soundName -notin @(
        "asterisk",
        "exclamation",
        "question",
        "beep",
        "none"
    )) {
        return
    }

    $script:notificationSound = $soundName
    Save-Settings
    Update-MenuLanguage

    if ($soundName -ne "none") {
        Play-NotificationSound $soundName
    }
}

function Get-AgentState {
    if (Test-Path -LiteralPath $StatePath) {
        try {
            $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
            if ($state.status -in @("running", "waiting", "done")) {
                return @{
                    status = [string]$state.status
                    message = [string]$state.message
                }
            }
        }
        catch {
            # A writer may be replacing the state file; retry on the next tick.
        }
    }

    foreach ($processName in $ProcessNames) {
        if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
            return @{
                status = "running"
                message = "$processName process detected"
            }
        }
    }

    return @{
        status = "done"
        message = "No active agent"
    }
}

$window.Add_MouseLeftButtonDown({
    param($sender, $eventArgs)
    if ($eventArgs.ButtonState -eq [Windows.Input.MouseButtonState]::Pressed) {
        $window.DragMove()
    }
})

$window.Add_MouseRightButtonUp({
    Hide-Widget
})

$window.Add_Closing({
    param($sender, $eventArgs)
    if (-not $script:allowExit) {
        $eventArgs.Cancel = $true
        Hide-Widget
    }
})

$showMenuItem.Add_Click({
    $window.Dispatcher.Invoke([action]{ Show-Widget })
})

$hideMenuItem.Add_Click({
    $window.Dispatcher.Invoke([action]{ Hide-Widget })
})

$englishMenuItem.Add_Click({
    $window.Dispatcher.Invoke([action]{ Set-Language "en" })
})

$chineseMenuItem.Add_Click({
    $window.Dispatcher.Invoke([action]{ Set-Language "zh-CN" })
})

foreach ($soundName in $soundMenuItems.Keys) {
    $menuItem = $soundMenuItems[$soundName]
    $menuItem.Add_Click({
        param($sender, $eventArgs)
        Set-NotificationSound ([string]$sender.Tag)
    })
}

$notifyIcon.Add_DoubleClick({
    $window.Dispatcher.Invoke([action]{ Show-Widget })
})

$exitMenuItem.Add_Click({
    $window.Dispatcher.Invoke([action]{
        $script:allowExit = $true
        $timer.Stop()
        $notifyIcon.Visible = $false
        $notifyIcon.Dispose()
        $trayMenu.Dispose()
        $window.Close()
    })
})

$timer = [Windows.Threading.DispatcherTimer]::new()
$timer.Interval = [TimeSpan]::FromMilliseconds([Math]::Max(250, $PollMilliseconds))
$timer.Add_Tick({
    $state = Get-AgentState
    Set-LightState $state.status $state.message
})

$initialState = Get-AgentState
Update-MenuLanguage
Set-LightState $initialState.status $initialState.message
$timer.Start()
try {
    $window.ShowDialog() | Out-Null
}
finally {
    if ($notifyIcon) {
        $notifyIcon.Visible = $false
        $notifyIcon.Dispose()
    }
    if ($trayMenu) {
        $trayMenu.Dispose()
    }
    foreach ($icon in $trayIcons.Values) {
        $icon.Dispose()
    }
    foreach ($player in $soundPlayers.Values) {
        $player.Dispose()
    }
}
