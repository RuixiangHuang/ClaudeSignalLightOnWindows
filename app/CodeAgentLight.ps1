param(
    [string]$StatePath = (Join-Path (Split-Path -Parent $PSScriptRoot) "runtime\status.json"),
    [string[]]$ProcessNames = @("codex", "codeagent"),
    [int]$PollMilliseconds = 750
)

$ErrorActionPreference = "Stop"
$runtimePath = Join-Path (Split-Path -Parent $PSScriptRoot) "runtime"
New-Item -ItemType Directory -Path $runtimePath -Force | Out-Null
$logPath = Join-Path $runtimePath "widget.log"

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

$notifyIcon = [System.Windows.Forms.NotifyIcon]::new()
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$notifyIcon.Text = "Code Agent Light"
$notifyIcon.Visible = $true

$trayMenu = [System.Windows.Forms.ContextMenuStrip]::new()
$showMenuItem = $trayMenu.Items.Add("Show Widget")
$hideMenuItem = $trayMenu.Items.Add("Hide Widget")
[void]$trayMenu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new())
$exitMenuItem = $trayMenu.Items.Add("Exit")
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
$script:allowExit = $false

function Show-Widget {
    $window.Show()
    $window.Activate()
    $window.Topmost = $true
}

function Hide-Widget {
    $window.Hide()
}

function Set-LightState([string]$status, [string]$message) {
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
            $statusText.Text = "RUNNING"
        }
        "waiting" {
            $yellowLight.Fill = New-Brush $onColors.yellow
            $statusText.Text = "ACTION"
            if ($statusChanged) {
                Start-YellowPulse
                if ($null -ne $script:currentStatus) {
                    [System.Media.SystemSounds]::Asterisk.Play()
                }
            }
        }
        default {
            $redLight.Fill = New-Brush $onColors.red
            $statusText.Text = "DONE"
        }
    }

    $script:currentStatus = $status
    $window.ToolTip = if ($message) { $message } else { $statusText.Text }
    $trayMessage = if ($message) { $message } else { $statusText.Text }
    $notifyIcon.Text = "Code Agent Light - $($statusText.Text)"
    $notifyIcon.BalloonTipTitle = "Code Agent Light"
    $notifyIcon.BalloonTipText = $trayMessage
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
}
