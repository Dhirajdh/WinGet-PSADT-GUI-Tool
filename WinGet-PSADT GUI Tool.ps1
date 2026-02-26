#Requires -Version 5.1
<#
.SYNOPSIS  WinGet-PSADT GUI Tool
.NOTES     Requires: winget, PSAppDeployToolkit.Tools module, IntuneWinAppUtil.exe in .\Tools\
#>
function Show-StartupMsg(
    [string]$Text,
    [string]$Title = "WinGet-PSADT GUI Tool",
    [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::Information
) {
    [System.Reflection.Assembly]::LoadWithPartialName("PresentationFramework") | Out-Null
    $w = New-Object System.Windows.Window
    $w.Title = $Title
    $w.Width = 540
    $w.SizeToContent = [System.Windows.SizeToContent]::Height
    $w.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
    $w.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $w.WindowStyle = [System.Windows.WindowStyle]::None
    $w.AllowsTransparency = $true
    $w.Background = [System.Windows.Media.Brushes]::Transparent
    $root = New-Object System.Windows.Controls.Border
    $root.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0F1923")
    $root.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
    $root.BorderThickness = [System.Windows.Thickness]::new(1)
    $root.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $g = New-Object System.Windows.Controls.Grid
    $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = [System.Windows.GridLength]::new(42)
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
    $r2 = New-Object System.Windows.Controls.RowDefinition; $r2.Height = [System.Windows.GridLength]::new(58)
    $g.RowDefinitions.Add($r0); $g.RowDefinitions.Add($r1); $g.RowDefinitions.Add($r2)
    $titleBar = New-Object System.Windows.Controls.Border
    $titleBar.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0A1118")
    $titleBar.CornerRadius = [System.Windows.CornerRadius]::new(10,10,0,0)
    [System.Windows.Controls.Grid]::SetRow($titleBar,0)
    $tt = New-Object System.Windows.Controls.TextBlock
    $tt.Text = $Title
    $tt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F9FAFB")
    $tt.FontSize = 13; $tt.FontWeight = [System.Windows.FontWeights]::SemiBold; $tt.VerticalAlignment = "Center"
    $tt.Margin = [System.Windows.Thickness]::new(12,0,0,0)
    $titleBar.Child = $tt
    $cg = New-Object System.Windows.Controls.Grid
    $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = [System.Windows.GridLength]::new(46)
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
    $cg.ColumnDefinitions.Add($c0); $cg.ColumnDefinitions.Add($c1)
    $cg.Margin = [System.Windows.Thickness]::new(14,14,14,10)
    [System.Windows.Controls.Grid]::SetRow($cg,1)
    $glyph = [char]0xE946; $color = "#38BDF8"
    if ($Icon -eq [System.Windows.MessageBoxImage]::Error) { $glyph=[char]0xEA39; $color="#EF4444" }
    if ($Icon -eq [System.Windows.MessageBoxImage]::Warning) { $glyph=[char]0xE7BA; $color="#F59E0B" }
    $iconTb = New-Object System.Windows.Controls.TextBlock
    $iconTb.Text = $glyph
    $iconTb.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
    $iconTb.FontSize = 22
    $iconTb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
    [System.Windows.Controls.Grid]::SetColumn($iconTb,0)
    $msgTb = New-Object System.Windows.Controls.TextBlock
    $msgTb.Text = $Text
    $msgTb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
    $msgTb.FontSize = 13
    $msgTb.TextWrapping = "Wrap"
    [System.Windows.Controls.Grid]::SetColumn($msgTb,1)
    $cg.Children.Add($iconTb) | Out-Null
    $cg.Children.Add($msgTb) | Out-Null
    $ok = New-Object System.Windows.Controls.Button
    $ok.Content = "OK"; $ok.Width = 90; $ok.Height = 32; $ok.HorizontalAlignment = "Right"
    $ok.Margin = [System.Windows.Thickness]::new(0,0,12,10)
    $ok.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563EB")
    $ok.Foreground = [System.Windows.Media.Brushes]::White
    $ok.BorderThickness = [System.Windows.Thickness]::new(0)
    [System.Windows.Controls.Grid]::SetRow($ok,2)
    $ok.Add_Click({ $w.Close() })
    $g.Children.Add($titleBar) | Out-Null
    $g.Children.Add($cg) | Out-Null
    $g.Children.Add($ok) | Out-Null
    $root.Child = $g
    $w.Content = $root
    $null = $w.ShowDialog()
}

# WPF + PSADT workflow is most reliable in Windows PowerShell (Desktop).
if ($PSVersionTable.PSEdition -ne "Desktop") {
    Show-StartupMsg -Text (
        "This script is designed for Windows PowerShell 5.1 (Desktop).`n`nCurrent host: PowerShell $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition)).`n`nIt will now relaunch in Windows PowerShell.",
        "Host Compatibility",
        [System.Windows.MessageBoxImage]::Information
    )
    $scriptPath = $PSCommandPath
    if ([string]::IsNullOrWhiteSpace($scriptPath)) { $scriptPath = $MyInvocation.MyCommand.Path }
    if ([string]::IsNullOrWhiteSpace($scriptPath) -or !(Test-Path $scriptPath)) {
        $fallback = Join-Path (Get-Location).Path "WinGet-PSADT GUI Tool.ps1"
        if (Test-Path $fallback) { $scriptPath = $fallback }
    }

    $ps51 = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
    if (!(Test-Path $ps51)) { $ps51 = "powershell.exe" }

    if ($scriptPath -and (Test-Path $scriptPath)) {
        try {
            $wd = Split-Path -Path $scriptPath -Parent
            if ([string]::IsNullOrWhiteSpace($wd) -or !(Test-Path $wd)) { $wd = (Get-Location).Path }
            $psArgs = "-NoProfile -ExecutionPolicy Bypass -Sta -File `"$scriptPath`""
            Start-Process -FilePath $ps51 -ArgumentList $psArgs -WorkingDirectory $wd -WindowStyle Hidden | Out-Null
        } catch {
            Show-StartupMsg -Text (
                "Failed to relaunch in Windows PowerShell.`n`n$($_.Exception.Message)`n`nRun manually:`n$ps51 -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"",
                "Relaunch Failed",
                [System.Windows.MessageBoxImage]::Error
            )
        }
    } else {
        Show-StartupMsg -Text (
            "Could not determine the script path to relaunch.`n`nPlease run this file manually in Windows PowerShell 5.1.",
            "Relaunch Failed",
            [System.Windows.MessageBoxImage]::Error
        )
    }
    return
}

Clear-Host
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
try { Add-Type -AssemblyName System.Windows.Forms } catch {}

if     ($PSScriptRoot -and $PSScriptRoot -ne '') { $Global:ScriptBase = $PSScriptRoot }
elseif ($MyInvocation.MyCommand.Path)             { $Global:ScriptBase = Split-Path $MyInvocation.MyCommand.Path -Parent }
else                                              { $Global:ScriptBase = (Get-Location).Path }

$Global:PackageRoot     = Join-Path $Global:ScriptBase "Packages"
$Global:OutputRoot      = Join-Path $Global:ScriptBase "Output"
$Global:ToolsFolder     = Join-Path $Global:ScriptBase "Tools"
$Global:IntuneUtil      = Join-Path $Global:ToolsFolder "IntuneWinAppUtil.exe"
$Global:SelectedPackage = $null
$Global:SelectedAppName = $null
$Global:SelectedVersion = $null
$Global:CurrentProcess  = $null
$Global:LogFolder       = Join-Path $Global:ScriptBase "Logs"
$Global:LogFile         = Join-Path $Global:LogFolder "App.log"

if (!(Test-Path $Global:PackageRoot)) { New-Item -ItemType Directory -Path $Global:PackageRoot | Out-Null }
if (!(Test-Path $Global:OutputRoot)) { New-Item -ItemType Directory -Path $Global:OutputRoot -Force | Out-Null }
if (!(Test-Path $Global:LogFolder)) { New-Item -ItemType Directory -Path $Global:LogFolder -Force | Out-Null }
try {
    Add-Content -LiteralPath $Global:LogFile -Value ("[{0}] [INFO] SessionStart | Host={1} | Version={2} | PSEdition={3} | PID={4}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"),$Host.Name,$PSVersionTable.PSVersion,$PSVersionTable.PSEdition,$PID) -Encoding UTF8
} catch {}

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinGet-PSADT GUI Tool"
        Height="680" Width="1000"
        MinHeight="580" MinWidth="800"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent">
  <Window.Resources>
    <Style x:Key="CC" TargetType="TextBlock">
      <Setter Property="TextAlignment" Value="Center"/>
      <Setter Property="VerticalAlignment" Value="Center"/>
    </Style>
    <Style TargetType="DataGridColumnHeader">
      <Setter Property="Background" Value="#111827"/>
      <Setter Property="Foreground" Value="#9CA3AF"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="HorizontalContentAlignment" Value="Center"/>
      <Setter Property="Padding" Value="10,8"/>
      <Setter Property="BorderBrush" Value="#374151"/>
      <Setter Property="BorderThickness" Value="0,0,0,1"/>
    </Style>
    <Style TargetType="DataGrid">
      <Setter Property="Background" Value="#1A2332"/>
      <Setter Property="Foreground" Value="#E5E7EB"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="RowBackground" Value="#1A2332"/>
      <Setter Property="AlternatingRowBackground" Value="#1F2D3D"/>
      <Setter Property="RowHeight" Value="36"/>
      <Setter Property="SelectionMode" Value="Single"/>
    </Style>
    <Style TargetType="DataGridCell">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#E5E7EB"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
    </Style>
    <Style TargetType="DataGridRow">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#E5E7EB"/>
      <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#1E3A8A"/>
          <Setter Property="Foreground" Value="White"/>
        </Trigger>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#2D3F55"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <Style TargetType="ScrollBar">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Width" Value="6"/>
    </Style>
    <Style TargetType="ComboBoxItem">
      <Setter Property="Background" Value="#1A2332"/>
      <Setter Property="Foreground" Value="#D1D5DB"/>
      <Setter Property="Padding" Value="10,7"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#2D3F55"/>
          <Setter Property="Foreground" Value="White"/>
        </Trigger>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#1E3A8A"/>
          <Setter Property="Foreground" Value="White"/>
        </Trigger>
      </Style.Triggers>
    </Style>
  </Window.Resources>
  <Border Background="#0F1923" CornerRadius="12" BorderBrush="#2D3F55" BorderThickness="1">
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="42"/>
        <RowDefinition Height="62"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="6"/>
        <RowDefinition Height="78"/>
      </Grid.RowDefinitions>

      <!-- TITLE BAR -->
      <Grid Grid.Row="0" Name="TitleBar" Background="#0A1118">
        <Grid.ColumnDefinitions>
          <ColumnDefinition/>
          <ColumnDefinition Width="46"/>
          <ColumnDefinition Width="46"/>
          <ColumnDefinition Width="46"/>
        </Grid.ColumnDefinitions>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="14,0">
          <TextBlock Text="&#xE8F4;" FontFamily="Segoe MDL2 Assets" FontSize="14"
                     Foreground="#3B82F6" VerticalAlignment="Center" Margin="0,0,8,0"/>
          <TextBlock Text="WinGet-PSADT GUI Tool" Foreground="#F9FAFB"
                     FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/>
        </StackPanel>
        <Button Name="MinBtn" Grid.Column="1" Background="Transparent" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="Transparent">
              <TextBlock Text="&#xE921;" FontFamily="Segoe MDL2 Assets" FontSize="10"
                         Foreground="#6B7280" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#1F2937"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="MaxBtn" Grid.Column="2" Background="Transparent" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="Transparent">
              <TextBlock Text="&#xE922;" FontFamily="Segoe MDL2 Assets" FontSize="10"
                         Foreground="#6B7280" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#1F2937"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="CloseBtn" Grid.Column="3" Background="Transparent" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="Transparent" CornerRadius="0,12,0,0">
              <TextBlock Text="&#xE8BB;" FontFamily="Segoe MDL2 Assets" FontSize="10"
                         Foreground="#6B7280" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bg" Property="Background" Value="#EF4444"/>
                <Setter Property="Foreground" Value="White"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
      </Grid>

      <!-- SEARCH BAR -->
      <Grid Grid.Row="1" Margin="14,10,14,8">
        <Grid.ColumnDefinitions>
          <ColumnDefinition/>
          <ColumnDefinition Width="130"/>
        </Grid.ColumnDefinitions>
        <Border Background="#1A2332" CornerRadius="8" BorderBrush="#2D3F55" BorderThickness="1">
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="40"/>
              <ColumnDefinition/>
            </Grid.ColumnDefinitions>
            <TextBlock Text="&#xE721;" FontFamily="Segoe MDL2 Assets" FontSize="14"
                       Foreground="#6B7280" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            <TextBox Name="SearchBox" Grid.Column="1" Background="Transparent" BorderThickness="0"
                     Foreground="White" CaretBrush="White" FontSize="14"
                     VerticalContentAlignment="Center" Margin="0,0,8,0"/>
          </Grid>
        </Border>
        <Button Name="SearchBtn" Grid.Column="1" Margin="10,0,0,0" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#3B82F6" CornerRadius="8">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE721;" FontFamily="Segoe MDL2 Assets" FontSize="13"
                           Foreground="White" VerticalAlignment="Center" Margin="0,0,6,0"/>
                <TextBlock Text="Search" Foreground="White" FontSize="14" FontWeight="SemiBold" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#2563EB"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Background" Value="#1D4ED8"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
      </Grid>

      <!-- RESULTS GRID -->
      <DataGrid Name="ResultsGrid" Grid.Row="2" Margin="14,0,14,0"
                AutoGenerateColumns="False" IsReadOnly="True"
                GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#1F2D3D"
                VerticalGridLinesBrush="Transparent" HeadersVisibility="Column"
                CanUserResizeRows="False" CanUserReorderColumns="False"
                ScrollViewer.VerticalScrollBarVisibility="Auto"
                ScrollViewer.HorizontalScrollBarVisibility="Disabled">
        <DataGrid.Columns>
          <DataGridTextColumn Header="Application Name" Binding="{Binding Name}"   Width="3*"   ElementStyle="{StaticResource CC}"/>
          <DataGridTextColumn Header="Package ID"       Binding="{Binding ID}"     Width="3*"   ElementStyle="{StaticResource CC}"/>
          <DataGridTextColumn Header="Version"          Binding="{Binding Version}" Width="1.8*" ElementStyle="{StaticResource CC}"/>
          <DataGridTextColumn Header="Source"           Binding="{Binding Source}"  Width="1.2*" ElementStyle="{StaticResource CC}"/>
        </DataGrid.Columns>
      </DataGrid>

      <!-- STATUS BAR + LIVE OUTPUT -->
      <Border Grid.Row="3" Background="#0A1118" Margin="14,6,14,0" CornerRadius="6" Padding="10,6">
        <StackPanel>
          <StackPanel Orientation="Horizontal">
            <TextBlock Name="StatusDot" Text="&#x25CF;" FontSize="9" Foreground="#6B7280"
                       VerticalAlignment="Center" Margin="0,0,6,0"/>
            <TextBlock Name="StatusLabel" Foreground="#6B7280" FontSize="12"
                       Text="Ready  |  Search for an application to begin"
                       VerticalAlignment="Center"/>
          </StackPanel>
          <Border Name="LiveOutputBorder" Visibility="Collapsed" Margin="0,5,0,0"
                  Background="#060D14" CornerRadius="4" BorderBrush="#1E3A5F" BorderThickness="1" Padding="8,5">
            <TextBox Name="LiveOutputBox" Background="Transparent" BorderThickness="0"
                     Foreground="#38BDF8" FontFamily="Consolas" FontSize="11"
                     IsReadOnly="True" TextWrapping="Wrap"
                     VerticalScrollBarVisibility="Auto" MaxHeight="120" Text=""/>
          </Border>
        </StackPanel>
      </Border>

      <!-- PROGRESS BAR -->
      <Border Grid.Row="4" Margin="14,4,14,0" CornerRadius="3" ClipToBounds="True">
        <ProgressBar Name="MainProgressBar" Height="5" Visibility="Collapsed"
                     IsIndeterminate="True" Background="#1A2332" BorderThickness="0">
          <ProgressBar.Foreground>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
              <GradientStop Color="#3B82F6" Offset="0"/>
              <GradientStop Color="#10B981" Offset="0.5"/>
              <GradientStop Color="#3B82F6" Offset="1"/>
            </LinearGradientBrush>
          </ProgressBar.Foreground>
        </ProgressBar>
      </Border>

      <!-- ACTION BUTTONS -->
      <Grid Grid.Row="5" Margin="14,8,14,14">
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>
        <Button Name="InfoBtn" Grid.Column="0" Height="50" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#92400E" CornerRadius="10">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE946;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock Text="Package Info" Foreground="White" FontSize="13" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#F59E0B"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Background" Value="#D97706"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="DownloadBtn" Grid.Column="2" Height="50" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#1D4ED8" CornerRadius="10">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE896;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock Text="Download" Foreground="White" FontSize="13" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#2563EB"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Background" Value="#1E40AF"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="ConfigureBtn" Grid.Column="4" Height="50" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#5B21B6" CornerRadius="10">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE713;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock Text="Configure" Foreground="White" FontSize="13" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#7C3AED"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Background" Value="#4C1D95"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="LogsBtn" Grid.Column="6" Height="50" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#0F766E" CornerRadius="10">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE8A5;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock Text="Open Logs" Foreground="White" FontSize="13" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#0D9488"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Background" Value="#115E59"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="GenerateBtn" Grid.Column="8" Height="50" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#065F46" CornerRadius="10">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE8F4;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock Text="Generate .intunewin" Foreground="White" FontSize="13" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#10B981"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Background" Value="#047857"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="UploadBtn" Grid.Column="10" Height="50" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#0B5CAD" CornerRadius="10">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE898;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock Text="Upload to Intune" Foreground="White" FontSize="13" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#2563EB"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Background" Value="#1D4ED8"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
      </Grid>
    </Grid>
  </Border>
</Window>
"@

try {
    $reader = New-Object System.Xml.XmlNodeReader $XAML
    $Window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    try { Add-Content -LiteralPath $Global:LogFile -Value ("[{0}] [ERROR] XamlLoadFailed | {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"), $_.Exception.Message) -Encoding UTF8 } catch {}
    Write-Host "XAML error: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"; return
}

# Bind controls
$TitleBar        = $Window.FindName("TitleBar")
$MinBtn          = $Window.FindName("MinBtn")
$MaxBtn          = $Window.FindName("MaxBtn")
$CloseBtn        = $Window.FindName("CloseBtn")
$SearchBox       = $Window.FindName("SearchBox")
$SearchBtn       = $Window.FindName("SearchBtn")
$ResultsGrid     = $Window.FindName("ResultsGrid")
$StatusDot       = $Window.FindName("StatusDot")
$StatusLabel     = $Window.FindName("StatusLabel")
$LiveOutputBorder= $Window.FindName("LiveOutputBorder")
$LiveOutputBox   = $Window.FindName("LiveOutputBox")
$MainProgressBar = $Window.FindName("MainProgressBar")
$InfoBtn         = $Window.FindName("InfoBtn")
$DownloadBtn     = $Window.FindName("DownloadBtn")
$ConfigureBtn    = $Window.FindName("ConfigureBtn")
$LogsBtn         = $Window.FindName("LogsBtn")
$GenerateBtn     = $Window.FindName("GenerateBtn")
$UploadBtn       = $Window.FindName("UploadBtn")

function Write-DebugLog([string]$Level, [string]$Message) {
    try {
        $lvl = if ([string]::IsNullOrWhiteSpace($Level)) { "INFO" } else { $Level.ToUpperInvariant() }
        $msg = if ($null -eq $Message) { "" } else { ($Message -replace "(`r|`n)+"," | ").Trim() }
        Add-Content -LiteralPath $Global:LogFile -Value ("[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"), $lvl, $msg) -Encoding UTF8
    } catch {}
}
function Get-CleanErrorText([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $t = $Text
    $t = $t -replace '#<\s*CLIXML',''
    $t = $t -replace '<[^>]+>',' '
    $t = $t -replace '_x000D__x000A_',"`r`n"
    $t = $t -replace '\s{2,}',' '
    $t = $t.Trim()
    return $t
}
function Show-Msg(
    [object]$Text,
    [object]$Title = "WinGet-PSADT GUI Tool",
    [object]$Buttons = [System.Windows.MessageBoxButton]::OK,
    [object]$Icon = [System.Windows.MessageBoxImage]::Information
) {
    # Support both PowerShell function-call style and method-style calls like:
    # Show-Msg("text","title",...).
    if (($Text -is [System.Array]) -and ($PSBoundParameters.Count -le 1)) {
        $arr = @($Text)
        if ($arr.Count -ge 1) { $Text = $arr[0] }
        if ($arr.Count -ge 2) { $Title = $arr[1] }
        if ($arr.Count -ge 3) { $Buttons = $arr[2] }
        if ($arr.Count -ge 4) { $Icon = $arr[3] }
    }
    $btn = [System.Windows.MessageBoxButton]::OK
    $ico = [System.Windows.MessageBoxImage]::Information
    try { $btn = [System.Windows.MessageBoxButton]$Buttons } catch {}
    try { $ico = [System.Windows.MessageBoxImage]$Icon } catch {}
    $result = [System.Windows.MessageBoxResult]::None
    $msgState = @{ Result = [System.Windows.MessageBoxResult]::None }

    $w = New-Object System.Windows.Window
    $w.Title = [string]$Title
    $w.Width = 540
    $w.MinWidth = 460
    $w.SizeToContent = [System.Windows.SizeToContent]::Height
    $w.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterOwner
    $w.ResizeMode = [System.Windows.ResizeMode]::NoResize
    $w.WindowStyle = [System.Windows.WindowStyle]::None
    $w.AllowsTransparency = $true
    $w.Background = [System.Windows.Media.Brushes]::Transparent
    try {
        if ($script:Window -and $script:Window.IsVisible) {
            $w.Owner = $script:Window
        }
    } catch {}

    $root = New-Object System.Windows.Controls.Border
    $root.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0F1923")
    $root.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
    $root.BorderThickness = [System.Windows.Thickness]::new(1)
    $root.CornerRadius = [System.Windows.CornerRadius]::new(10)

    $g = New-Object System.Windows.Controls.Grid
    $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = [System.Windows.GridLength]::new(42)
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
    $r2 = New-Object System.Windows.Controls.RowDefinition; $r2.Height = [System.Windows.GridLength]::new(64)
    $g.RowDefinitions.Add($r0); $g.RowDefinitions.Add($r1); $g.RowDefinitions.Add($r2)

    $titleBar = New-Object System.Windows.Controls.Border
    $titleBar.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0A1118")
    $titleBar.CornerRadius = [System.Windows.CornerRadius]::new(10,10,0,0)
    [System.Windows.Controls.Grid]::SetRow($titleBar,0)
    $tg = New-Object System.Windows.Controls.Grid
    $tc0 = New-Object System.Windows.Controls.ColumnDefinition
    $tc1 = New-Object System.Windows.Controls.ColumnDefinition; $tc1.Width = [System.Windows.GridLength]::new(42)
    $tg.ColumnDefinitions.Add($tc0); $tg.ColumnDefinitions.Add($tc1)
    $tt = New-Object System.Windows.Controls.TextBlock
    $tt.Text = [string]$Title
    $tt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F9FAFB")
    $tt.FontSize = 13
    $tt.FontWeight = [System.Windows.FontWeights]::SemiBold
    $tt.VerticalAlignment = "Center"
    $tt.Margin = [System.Windows.Thickness]::new(12,0,0,0)
    [System.Windows.Controls.Grid]::SetColumn($tt,0)
    $closeBtn = New-Object System.Windows.Controls.Button
    $closeBtn.Content = [char]0xE8BB
    $closeBtn.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
    $closeBtn.FontSize = 10
    $closeBtn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9CA3AF")
    $closeBtn.Background = [System.Windows.Media.Brushes]::Transparent
    $closeBtn.BorderThickness = [System.Windows.Thickness]::new(0)
    $closeBtn.Cursor = [System.Windows.Input.Cursors]::Hand
    [System.Windows.Controls.Grid]::SetColumn($closeBtn,1)
    $stateForClose = $msgState
    $winForClose = $w
    $closeBtn.Add_Click({
        try { $stateForClose.Result = [System.Windows.MessageBoxResult]::Cancel } catch {}
        try { $winForClose.Close() } catch {}
    }.GetNewClosure())
    $titleBar.Add_MouseLeftButtonDown({ $w.DragMove() })
    $tg.Children.Add($tt) | Out-Null
    $tg.Children.Add($closeBtn) | Out-Null
    $titleBar.Child = $tg

    $contentGrid = New-Object System.Windows.Controls.Grid
    $cc0 = New-Object System.Windows.Controls.ColumnDefinition; $cc0.Width = [System.Windows.GridLength]::new(50)
    $cc1 = New-Object System.Windows.Controls.ColumnDefinition; $cc1.Width = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
    $contentGrid.ColumnDefinitions.Add($cc0); $contentGrid.ColumnDefinitions.Add($cc1)
    $contentGrid.Margin = [System.Windows.Thickness]::new(14,14,14,12)
    [System.Windows.Controls.Grid]::SetRow($contentGrid,1)

    $iconColor = "#38BDF8"
    $iconGlyph = [char]0xE946
    switch ($ico) {
        ([System.Windows.MessageBoxImage]::Warning) { $iconColor = "#F59E0B"; $iconGlyph = [char]0xE7BA }
        ([System.Windows.MessageBoxImage]::Error) { $iconColor = "#EF4444"; $iconGlyph = [char]0xEA39 }
        ([System.Windows.MessageBoxImage]::Question) { $iconColor = "#60A5FA"; $iconGlyph = [char]0xE897 }
        default { $iconColor = "#38BDF8"; $iconGlyph = [char]0xE946 }
    }
    $itb = New-Object System.Windows.Controls.TextBlock
    $itb.Text = $iconGlyph
    $itb.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
    $itb.FontSize = 24
    $itb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($iconColor)
    $itb.VerticalAlignment = "Top"
    [System.Windows.Controls.Grid]::SetColumn($itb,0)
    $mtb = New-Object System.Windows.Controls.TextBlock
    $mtb.Text = [string]$Text
    $mtb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
    $mtb.FontSize = 13
    $mtb.TextWrapping = "Wrap"
    $mtb.Margin = [System.Windows.Thickness]::new(6,2,0,0)
    [System.Windows.Controls.Grid]::SetColumn($mtb,1)
    $contentGrid.Children.Add($itb) | Out-Null
    $contentGrid.Children.Add($mtb) | Out-Null

    $btnRow = New-Object System.Windows.Controls.StackPanel
    $btnRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $btnRow.HorizontalAlignment = "Right"
    $btnRow.Margin = [System.Windows.Thickness]::new(0,0,12,12)
    [System.Windows.Controls.Grid]::SetRow($btnRow,2)

    $mkBtn = {
        param([string]$Label,[System.Windows.MessageBoxResult]$Val,[string]$Bg,[string]$Fg)
        $b = New-Object System.Windows.Controls.Button
        $b.Content = $Label
        $b.MinWidth = 84
        $b.Height = 32
        $b.Margin = [System.Windows.Thickness]::new(8,0,0,0)
        $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Bg)
        $b.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Fg)
        $b.BorderThickness = [System.Windows.Thickness]::new(0)
        $b.Cursor = [System.Windows.Input.Cursors]::Hand
        $tpl = @"
<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" TargetType="Button">
  <Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="7">
    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
  </Border>
  <ControlTemplate.Triggers>
    <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Opacity" Value="0.92"/></Trigger>
    <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Opacity" Value="0.82"/></Trigger>
  </ControlTemplate.Triggers>
</ControlTemplate>
"@
        $b.Template = [Windows.Markup.XamlReader]::Parse($tpl)
        $retVal = $Val
        $dlgWin = $w
        $stateForBtn = $msgState
        $b.Add_Click({
            try { $stateForBtn.Result = $retVal } catch {}
            try { $dlgWin.Close() } catch {}
        }.GetNewClosure())
        return $b
    }
    $msgState.Result = [System.Windows.MessageBoxResult]::None
    switch ($btn) {
        ([System.Windows.MessageBoxButton]::OK) {
            $btnRow.Children.Add((& $mkBtn "OK" ([System.Windows.MessageBoxResult]::OK) "#2563EB" "#FFFFFF")) | Out-Null
        }
        ([System.Windows.MessageBoxButton]::OKCancel) {
            $btnRow.Children.Add((& $mkBtn "OK" ([System.Windows.MessageBoxResult]::OK) "#2563EB" "#FFFFFF")) | Out-Null
            $btnRow.Children.Add((& $mkBtn "Cancel" ([System.Windows.MessageBoxResult]::Cancel) "#374151" "#D1D5DB")) | Out-Null
        }
        ([System.Windows.MessageBoxButton]::YesNo) {
            $btnRow.Children.Add((& $mkBtn "Yes" ([System.Windows.MessageBoxResult]::Yes) "#059669" "#FFFFFF")) | Out-Null
            $btnRow.Children.Add((& $mkBtn "No" ([System.Windows.MessageBoxResult]::No) "#374151" "#D1D5DB")) | Out-Null
        }
        ([System.Windows.MessageBoxButton]::YesNoCancel) {
            $btnRow.Children.Add((& $mkBtn "Yes" ([System.Windows.MessageBoxResult]::Yes) "#059669" "#FFFFFF")) | Out-Null
            $btnRow.Children.Add((& $mkBtn "No" ([System.Windows.MessageBoxResult]::No) "#374151" "#D1D5DB")) | Out-Null
            $btnRow.Children.Add((& $mkBtn "Cancel" ([System.Windows.MessageBoxResult]::Cancel) "#374151" "#D1D5DB")) | Out-Null
        }
        default {
            $btnRow.Children.Add((& $mkBtn "OK" ([System.Windows.MessageBoxResult]::OK) "#2563EB" "#FFFFFF")) | Out-Null
        }
    }

    $g.Children.Add($titleBar) | Out-Null
    $g.Children.Add($contentGrid) | Out-Null
    $g.Children.Add($btnRow) | Out-Null
    $root.Child = $g
    $w.Content = $root
    $null = $w.ShowDialog()
    $result = $msgState.Result
    return $result
}
function Test-MsgResult([object]$Result,[string]$Target) {
    $t = if ([string]::IsNullOrWhiteSpace($Target)) { "" } else { $Target.Trim().ToLowerInvariant() }
    $s = if ($null -eq $Result) { "" } else { [string]$Result }
    $n = -1
    try { $n = [int]$Result } catch {}
    switch ($t) {
        "yes"    { return ($Result -eq [System.Windows.MessageBoxResult]::Yes -or $s -eq "Yes" -or $n -eq 6) }
        "no"     { return ($Result -eq [System.Windows.MessageBoxResult]::No -or $s -eq "No" -or $n -eq 7) }
        "cancel" { return ($Result -eq [System.Windows.MessageBoxResult]::Cancel -or $s -eq "Cancel" -or $n -eq 2) }
        "none"   { return ($Result -eq [System.Windows.MessageBoxResult]::None -or $s -eq "None" -or $n -eq 0 -or [string]::IsNullOrWhiteSpace($s)) }
        default  { return $false }
    }
}

function Set-Status([string]$Message, [string]$Color = "#6B7280") {
    $Window.Dispatcher.Invoke([action]{
        $StatusLabel.Foreground = $Color
        $StatusDot.Foreground   = $Color
        $StatusLabel.Text       = $Message
    })
}
function Show-Progress {
    $Window.Dispatcher.Invoke([action]{
        try {
            $MainProgressBar.IsIndeterminate = $true
            $MainProgressBar.Visibility      = "Visible"
            # Ensure visual container is visible as well.
            $parent = [System.Windows.Media.VisualTreeHelper]::GetParent($MainProgressBar)
            if ($parent -is [System.Windows.UIElement]) { $parent.Visibility = "Visible" }
            if ($parent -is [System.Windows.Controls.Border] -and $parent.Height -lt 6) { $parent.Height = 6 }
            if ($MainProgressBar.Height -lt 5) { $MainProgressBar.Height = 5 }
            [System.Windows.Controls.Panel]::SetZIndex($MainProgressBar, 999)
            $MainProgressBar.UpdateLayout()
        } catch {}
    })
}
function Hide-Progress {
    $Window.Dispatcher.Invoke([action]{
        $MainProgressBar.IsIndeterminate = $false
        $MainProgressBar.Visibility      = "Collapsed"
    })
}

function Flush-UI {
    try {
        $Window.UpdateLayout()
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Render,
            [System.Windows.Threading.DispatcherOperationCallback]{ param($f) $f.Continue = $false; return $null },
            $frame
        ) | Out-Null
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    } catch {}
}
function Show-LiveOutput {
    $Window.Dispatcher.Invoke([action]{
        $LiveOutputBox.Text          = ""
        $LiveOutputBorder.Visibility = "Visible"
    })
}
function Hide-LiveOutput {
    $Window.Dispatcher.Invoke([action]{
        $LiveOutputBorder.Visibility = "Collapsed"
        $LiveOutputBox.Text          = ""
    })
}
function Append-LiveOutput([string]$Line) {
    $clean = $Line -replace "\x1b\[[0-9;]*[A-Za-z]",""  -replace "[^\x20-\x7E]",""
    $clean = $clean.Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) { return }
    $Window.Dispatcher.Invoke([action]{
        $lines = @($LiveOutputBox.Text -split "`n" | Where-Object { $_ -ne "" })
        if ($lines.Count -ge 80) {
            $LiveOutputBox.Text = ($lines[-79..-1] -join "`n") + "`n" + $clean
        } else {
            $LiveOutputBox.Text = ($LiveOutputBox.Text + "`n" + $clean).TrimStart("`n")
        }
        $LiveOutputBox.ScrollToEnd()
    })
}
function Get-ComboTextPixelWidth([System.Windows.Controls.ComboBox]$Combo,[string]$Text) {
    if (!$Combo) { return 0.0 }
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.FontFamily = $Combo.FontFamily
    $tb.FontSize = $Combo.FontSize
    $tb.FontWeight = $Combo.FontWeight
    $tb.Text = [string]$Text
    $tb.Measure([System.Windows.Size]::new([double]::PositiveInfinity,[double]::PositiveInfinity))
    return [double]$tb.DesiredSize.Width
}
function Set-ComboDynamicSize([System.Windows.Controls.ComboBox]$Combo,[int]$MinChars = 8) {
    if (!$Combo) { return }
    $maxWidth = [Math]::Max(0.0, [double]($MinChars * 7))
    foreach ($it in @($Combo.Items)) {
        $s = [string]$it
        $w = Get-ComboTextPixelWidth -Combo $Combo -Text $s
        if ($w -gt $maxWidth) { $maxWidth = $w }
    }
    if ($Combo.SelectedItem) {
        $sw = Get-ComboTextPixelWidth -Combo $Combo -Text ([string]$Combo.SelectedItem)
        if ($sw -gt $maxWidth) { $maxWidth = $sw }
    }
    # Add room for padding + arrow glyph area.
    $targetWidth = [Math]::Ceiling([Math]::Max(110.0, $maxWidth + 44.0))
    $Combo.Width = $targetWidth
    $Combo.HorizontalAlignment = "Left"
    $Combo.MaxDropDownHeight = [Math]::Min(360, ([Math]::Max(1,$Combo.Items.Count) * 28) + 8)
}
function Apply-ComboAutoSize([System.Windows.DependencyObject]$Root,[int]$MinChars = 8) {
    if (!$Root) { return }
    if ($Root -is [System.Windows.Controls.ComboBox]) {
        $cb = [System.Windows.Controls.ComboBox]$Root
        Set-ComboDynamicSize -Combo $cb -MinChars $MinChars
        $localMin = $MinChars
        $cb.Add_DropDownOpened({
            try { Set-ComboDynamicSize -Combo $this -MinChars $localMin } catch {}
        })
    }
    $count = 0
    try { $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Root) } catch { $count = 0 }
    for ($i = 0; $i -lt $count; $i++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Root,$i)
        if ($child) { Apply-ComboAutoSize -Root $child -MinChars $MinChars }
    }
}
function Get-WingetPath {
    $p = Get-Command winget -ErrorAction SilentlyContinue
    if ($p) { return $p.Source }
    $loc = "$env:LocalAppData\Microsoft\WindowsApps\winget.exe"
    if (Test-Path $loc) { return $loc }
    return $null
}
function Get-SafeName([string]$Name) {
    return ($Name -replace '[\\/:*?"<>|]','_').Trim()
}
function Get-CloseProcessesExample {
    return "@('excel', @{ Name = 'winword'; Description = 'Microsoft Word' })"
}
function Get-SectionMarker([string]$Section) {
    $name = if ($null -eq $Section) { "" } else { $Section }
    switch ($name.Trim()) {
        "Pre-Install"   { return "## <Perform Pre-Installation tasks here>" }
        "Install"       { return "## <Perform Installation tasks here>" }
        "Post-Install"  { return "## <Perform Post-Installation tasks here>" }
        "Pre-Uninstall" { return "## <Perform Pre-Uninstallation tasks here>" }
        "Uninstall"     { return "## <Perform Uninstallation tasks here>" }
        "Post-Uninstall"{ return "## <Perform Post-Uninstallation tasks here>" }
        "Pre-Repair"    { return "## <Perform Pre-Repair tasks here>" }
        "Repair"        { return "## <Perform Repair tasks here>" }
        "Post-Repair"   { return "## <Perform Post-Repair tasks here>" }
        default         { return "## <Perform Pre-Installation tasks here>" }
    }
}
function Get-IntuneWinOutputName([string]$AppName,[string]$Version) {
    $n = if ([string]::IsNullOrWhiteSpace($AppName)) { "Package" } else { Get-SafeName $AppName }
    $v = if ([string]::IsNullOrWhiteSpace($Version) -or $Version -eq "N/A") { "UnknownVersion" } else { Get-SafeName $Version }
    $n = ($n -replace '\s+','_')
    $v = ($v -replace '\s+','_')
    return "{0}_{1}.intunewin" -f $n,$v
}
function Resolve-WingetPackageVersion([string]$PackageId,[string]$GridVersion) {
    $candidate = ""
    if (![string]::IsNullOrWhiteSpace($GridVersion) -and $GridVersion -match '\d+(\.\d+)+([-\w\.]*)?') {
        $candidate = $Matches[0]
    }
    $winget = Get-WingetPath
    if (!$winget -or [string]::IsNullOrWhiteSpace($PackageId)) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { return "UnknownVersion" }
        return $candidate
    }
    try {
        $show = & $winget show --id "$PackageId" --exact --source winget --accept-source-agreements --disable-interactivity 2>&1
        foreach ($line in $show) {
            $clean = ($line -replace "\x1b\[[0-9;]*[A-Za-z]","" -replace "[^\x20-\x7E]","").Trim()
            if ($clean -match '^Version\s*:\s*(.+)$') {
                $ver = $Matches[1].Trim()
                if ($ver -match '\d') { return $ver }
            }
        }
    } catch {}
    if ([string]::IsNullOrWhiteSpace($candidate)) { return "UnknownVersion" }
    return $candidate
}
function Get-WingetPackageInfo([string]$PackageId) {
    $out = [PSCustomObject]@{
        Version        = ""
        Publisher      = ""
        InformationUrl = ""
        PrivacyUrl     = ""
        Developer      = ""
        Owner          = ""
        Notes          = ""
    }
    if ([string]::IsNullOrWhiteSpace($PackageId)) { return $out }
    $winget = Get-WingetPath
    if (!$winget) { return $out }
    try {
        $lines = & $winget show --id "$PackageId" --exact --source winget --accept-source-agreements --disable-interactivity 2>&1 |
            ForEach-Object { ($_ -replace "\x1b\[[0-9;]*[A-Za-z]","" -replace "[^\x20-\x7E]","").Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        foreach ($ln in $lines) {
            if ($ln -notmatch "^\s*([^:]+)\s*:\s*(.*)$") { continue }
            $k = ($Matches[1]).Trim().ToLowerInvariant()
            $v = ($Matches[2]).Trim()
            if ([string]::IsNullOrWhiteSpace($v)) { continue }
            if ($k -eq "version" -and [string]::IsNullOrWhiteSpace($out.Version)) { $out.Version = $v; continue }
            if ($k -eq "publisher" -and [string]::IsNullOrWhiteSpace($out.Publisher)) { $out.Publisher = $v; continue }
            if (($k -match "homepage|url|package url|information url") -and [string]::IsNullOrWhiteSpace($out.InformationUrl)) { $out.InformationUrl = $v; continue }
            if (($k -match "privacy") -and [string]::IsNullOrWhiteSpace($out.PrivacyUrl)) { $out.PrivacyUrl = $v; continue }
            if (($k -match "author|developer") -and [string]::IsNullOrWhiteSpace($out.Developer)) { $out.Developer = $v; continue }
            if (($k -match "description|short description") -and [string]::IsNullOrWhiteSpace($out.Notes)) { $out.Notes = $v; continue }
        }
        if ([string]::IsNullOrWhiteSpace($out.Developer) -and $out.Publisher) { $out.Developer = $out.Publisher }
        if ([string]::IsNullOrWhiteSpace($out.Owner) -and $out.Publisher) { $out.Owner = $out.Publisher }
    } catch {}
    return $out
}
function Resolve-BestAppVersion([object]$SelectedItem,[object]$Context) {
    $isValidVersion = {
        param($v)
        if ([string]::IsNullOrWhiteSpace([string]$v)) { return $false }
        $s = [string]$v
        if ($s -eq "N/A" -or $s -eq "UnknownVersion" -or $s -eq "1.0.0") { return $false }
        return ($s -match '\d')
    }
    if (& $isValidVersion $Global:SelectedVersion) { return [string]$Global:SelectedVersion }

    try {
        if ($Context -and $Context.ScriptPath -and (Test-Path $Context.ScriptPath)) {
            $d = Get-AppDetailsFromScript -ScriptPath $Context.ScriptPath -AppName $Context.AppName -Version ""
            if ($d -and (& $isValidVersion $d.AppVersion)) { return [string]$d.AppVersion }
        }
    } catch {}

    if ($SelectedItem) {
        $id = if ($SelectedItem.ID) { [string]$SelectedItem.ID } else { "" }
        $gridVer = if ($SelectedItem.Version) { [string]$SelectedItem.Version } else { "" }
        $wv = Resolve-WingetPackageVersion -PackageId $id -GridVersion $gridVer
        if (& $isValidVersion $wv) { return [string]$wv }
    }

    try {
        if ($Context -and $Context.Installer -and (Test-Path $Context.Installer.FullName)) {
            $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Context.Installer.FullName)
            foreach ($pv in @($vi.ProductVersion,$vi.FileVersion)) {
                if (& $isValidVersion $pv) { return [string]$pv }
            }
        }
    } catch {}

    if (& $isValidVersion $Global:SelectedVersion) { return [string]$Global:SelectedVersion }
    return "UnknownVersion"
}
function Get-WindowsPowerShellPath {
    $ps51 = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
    if (Test-Path $ps51) { return $ps51 }
    return "powershell.exe"
}
function Set-IntuneWinInternalFileName([string]$IntuneWinPath,[string]$InnerFileName) {
    if ([string]::IsNullOrWhiteSpace($IntuneWinPath) -or !(Test-Path $IntuneWinPath)) { return $false }
    if ([string]::IsNullOrWhiteSpace($InnerFileName)) { return $false }
    if ([System.IO.Path]::GetExtension($InnerFileName) -ne ".intunewin") { return $false }
    $tmpRoot = Join-Path $env:TEMP ("psadt_iw_fix_{0}" -f [Guid]::NewGuid().ToString("N"))
    $extractDir = Join-Path $tmpRoot "x"
    $newZip = Join-Path $tmpRoot "new.intunewin"
    try {
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($IntuneWinPath,$extractDir)

        $xmlFiles = Get-ChildItem -Path $extractDir -Recurse -File -Include *.xml -ErrorAction SilentlyContinue
        if (!$xmlFiles -or $xmlFiles.Count -eq 0) { return $false }

        $metaFile = $null
        $oldInnerName = $null
        foreach ($xf in $xmlFiles) {
            $txt = [System.IO.File]::ReadAllText($xf.FullName,[System.Text.Encoding]::UTF8)
            $m = [regex]::Match($txt,'<FileName>\s*([^<]*\.intunewin)\s*</FileName>',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($m.Success) {
                $metaFile = $xf
                $oldInnerName = $m.Groups[1].Value.Trim()
                break
            }
        }
        if (!$metaFile -or [string]::IsNullOrWhiteSpace($oldInnerName)) { return $false }

        $oldEntry = Get-ChildItem -Path $extractDir -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ieq $oldInnerName } | Select-Object -First 1
        if ($oldEntry -and ($oldEntry.Name -ine $InnerFileName)) {
            $dest = Join-Path $oldEntry.DirectoryName $InnerFileName
            if (Test-Path $dest) { Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue }
            Rename-Item -LiteralPath $oldEntry.FullName -NewName $InnerFileName -Force
        }

        $metaText = [System.IO.File]::ReadAllText($metaFile.FullName,[System.Text.Encoding]::UTF8)
        $metaText = [regex]::Replace($metaText,'(<FileName>\s*)([^<]*\.intunewin)(\s*</FileName>)',("`$1{0}`$3" -f $InnerFileName),[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        [System.IO.File]::WriteAllText($metaFile.FullName,$metaText,[System.Text.Encoding]::UTF8)

        if (Test-Path $newZip) { Remove-Item -LiteralPath $newZip -Force -ErrorAction SilentlyContinue }
        [System.IO.Compression.ZipFile]::CreateFromDirectory($extractDir,$newZip,[System.IO.Compression.CompressionLevel]::Optimal,$false)
        Copy-Item -LiteralPath $newZip -Destination $IntuneWinPath -Force
        return $true
    } catch {
        return $false
    } finally {
        try { if (Test-Path $tmpRoot) { Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue } } catch {}
    }
}
function Invoke-WindowsPowerShellCommand([string]$CommandText) {
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    $ps51 = if ($pwsh -and (Test-Path $pwsh.Source)) { $pwsh.Source } else { Get-WindowsPowerShellPath }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($CommandText))
    $tmpOut = Join-Path $env:TEMP "psadt_subproc_$([Guid]::NewGuid().ToString('N')).out.log"
    $tmpErr = Join-Path $env:TEMP "psadt_subproc_$([Guid]::NewGuid().ToString('N')).err.log"
    $args = @("-NoProfile","-ExecutionPolicy","Bypass","-EncodedCommand",$encoded)
    $p = Start-Process -FilePath $ps51 -ArgumentList $args -PassThru -Wait -WindowStyle Hidden -RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr
    $output = ""
    try {
        $outTxt = if (Test-Path $tmpOut) { Get-Content -LiteralPath $tmpOut -Raw -ErrorAction SilentlyContinue } else { "" }
        $errTxt = if (Test-Path $tmpErr) { Get-Content -LiteralPath $tmpErr -Raw -ErrorAction SilentlyContinue } else { "" }
        $output = (($outTxt, $errTxt) -join "`n").Trim()
    } catch {}
    try { if (Test-Path $tmpOut) { Remove-Item -LiteralPath $tmpOut -Force -ErrorAction SilentlyContinue } } catch {}
    try { if (Test-Path $tmpErr) { Remove-Item -LiteralPath $tmpErr -Force -ErrorAction SilentlyContinue } } catch {}
    return [PSCustomObject]@{
        ExitCode = $p.ExitCode
        StdOut   = $outTxt
        StdErr   = $errTxt
        Output   = $output
    }
}
function New-PSADTTemplateSafe([string]$Destination,[string]$Name,[bool]$Force = $true) {
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    $hostPath = if ($pwsh -and (Test-Path $pwsh.Source)) { $pwsh.Source } else { Get-WindowsPowerShellPath }
    Write-DebugLog "INFO" ("TemplateCreateStart | Name={0} | Destination={1} | Force={2} | Host={3}" -f $Name,$Destination,$Force,$hostPath)

    # First try in current session (works for users with a healthy module load path).
    try {
        if ($Force) {
            New-ADTTemplate -Destination $Destination -Name $Name -Force -ErrorAction Stop | Out-Null
        } else {
            New-ADTTemplate -Destination $Destination -Name $Name -ErrorAction Stop | Out-Null
        }
        Write-DebugLog "INFO" ("TemplateCreateCurrentSessionSuccess | Name={0}" -f $Name)
        return [PSCustomObject]@{ ExitCode = 0; Output = "Created in current session." }
    } catch {
        Write-DebugLog "WARN" ("TemplateCreateCurrentSessionFailed | Name={0} | {1}" -f $Name,$_.Exception.Message)
    }

    $destEsc = $Destination.Replace("'","''")
    $nameEsc = $Name.Replace("'","''")
    $cmd = @"
`$ErrorActionPreference = 'Stop'
try {
    New-ADTTemplate -Destination '$destEsc' -Name '$nameEsc' $(if($Force){'-Force'}) -ErrorAction Stop | Out-Null
    exit 0
} catch {
    Write-Error `$_.Exception.Message
    exit 1
}
"@
    $result = Invoke-WindowsPowerShellCommand $cmd
    Write-DebugLog "INFO" ("TemplateCreateEnd | Name={0} | ExitCode={1} | Output={2}" -f $Name,$result.ExitCode,$result.Output)
    if ($result.ExitCode -eq 0) { return $result }

    # Final fallback: scaffold minimal package layout when module/template cmd cannot be loaded.
    try {
        $pkgRoot = Join-Path $Destination $Name
        if (!(Test-Path $pkgRoot)) { New-Item -ItemType Directory -Path $pkgRoot -Force | Out-Null }
        foreach ($d in @("Assets","Config","Files","Output","PSAppDeployToolkit","PSAppDeployToolkit.Extensions","Strings","SupportFiles")) {
            $p = Join-Path $pkgRoot $d
            if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
        }

        $mod = Get-Module -ListAvailable -Name PSAppDeployToolkit,PSAppDeployToolkit.Tools -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending | Select-Object -First 1
        if ($mod -and $mod.ModuleBase -and (Test-Path $mod.ModuleBase)) {
            Copy-Item -Path (Join-Path $mod.ModuleBase "*") -Destination (Join-Path $pkgRoot "PSAppDeployToolkit") -Recurse -Force -ErrorAction SilentlyContinue
            Write-DebugLog "INFO" ("TemplateFallbackCopiedModule | Source={0}" -f $mod.ModuleBase)
        } else {
            Write-DebugLog "WARN" "TemplateFallbackNoModuleFilesFound"
        }

        $scriptPath = Join-Path $pkgRoot "Invoke-AppDeployToolkit.ps1"
        if (!(Test-Path $scriptPath)) {
            $templateScript = @'
#requires -version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Repair')]
    [string]$DeploymentType = 'Install'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$dirFiles = Join-Path $scriptRoot 'Files'

function Invoke-Install {
    ## <Perform Installation tasks here>
}
function Invoke-Uninstall {
    ## <Perform Uninstallation tasks here>
}
function Invoke-Repair {
    ## <Perform Repair tasks here>
}

switch ($DeploymentType) {
    'Install'   { Invoke-Install }
    'Uninstall' { Invoke-Uninstall }
    'Repair'    { Invoke-Repair }
}
'@
            [System.IO.File]::WriteAllText($scriptPath,$templateScript,[System.Text.Encoding]::UTF8)
        }

        Write-DebugLog "WARN" ("TemplateFallbackUsed | PackageRoot={0}" -f $pkgRoot)
        return [PSCustomObject]@{ ExitCode = 0; Output = "Fallback template scaffolded (New-ADTTemplate unavailable)." }
    } catch {
        Write-DebugLog "ERROR" ("TemplateFallbackFailed | {0}" -f $_.Exception.Message)
        return $result
    }
}
function Ensure-PSADTModule {
    # Only ensure module presence; avoid importing in this runspace to prevent TypeData collisions.
    Write-DebugLog "INFO" "EnsurePSADTModuleStart"
    if (-not (Get-Module -ListAvailable -Name PSAppDeployToolkit.Tools -ErrorAction SilentlyContinue)) {
        Write-DebugLog "WARN" "PSAppDeployToolkit.Tools not found in ListAvailable; prompting install."
        $r = Show-Msg(
            "PSAppDeployToolkit.Tools module not found.`n`nInstall it now from PSGallery?",
            "Module Missing",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($r -ne "Yes") {
            Write-DebugLog "WARN" "PSADT module install declined by user."
            return $false
        }
        Set-Status "Installing PSAppDeployToolkit.Tools..." "#3B82F6"
        try {
            Install-Module PSAppDeployToolkit.Tools -Scope CurrentUser -Force -ErrorAction Stop
            Write-DebugLog "INFO" "PSADT module installed successfully."
        } catch {
            Write-DebugLog "ERROR" ("PSADT module install failed: {0}" -f $_.Exception.Message)
            Show-Msg("Install failed:`n`n$($_.Exception.Message)","Error",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
            return $false
        }
    }
    Write-DebugLog "INFO" "EnsurePSADTModuleEnd | Result=True"
    return $true
}
function Start-IntuneUploadAssistant(
    [string]$PackageRoot,
    [string]$IntuneWinPath,
    [string]$DefaultDisplayName,
    [string]$DefaultPublisher,
    [string]$DefaultDescription,
    [string]$IconPath,
    [string]$DefaultAppVersion = "",
    [string]$DefaultInformationUrl = "",
    [string]$DefaultPrivacyUrl = "",
    [string]$DefaultDeveloper = "",
    [string]$DefaultOwner = "",
    [string]$DefaultNotes = "",
    [string]$DetectionNameRegex = "",
    [string]$DetectionUseVersion = "",
    [string]$DetectionVersion = "",
    [string]$DetectionRegistryRoots = ""
) {
    $pwsh = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    $psPath = if ($pwsh -and (Test-Path $pwsh.Source)) { $pwsh.Source } else { Get-WindowsPowerShellPath }
    $tmpScript = Join-Path $env:TEMP ("psadt_intune_upload_{0}.ps1" -f [Guid]::NewGuid().ToString("N"))
    $paramNames = @(
        'PackageRoot','IntuneWinPath','DefaultDisplayName','DefaultPublisher','DefaultDescription','IconPath',
        'DefaultAppVersion','DefaultInformationUrl','DefaultPrivacyUrl','DefaultDeveloper','DefaultOwner','DefaultNotes',
        'DetectionNameRegex','DetectionUseVersion','DetectionVersion','DetectionRegistryRoots'
    )
    foreach ($n in $paramNames) {
        if ($null -eq (Get-Variable -Name $n -ValueOnly)) { Set-Variable -Name $n -Value "" }
    }
    $pkgEsc = $PackageRoot.Replace("'","''")
    $fileEsc = $IntuneWinPath.Replace("'","''")
    $nameEsc = $DefaultDisplayName.Replace("'","''")
    $pubEsc = $DefaultPublisher.Replace("'","''")
    $descEsc = $DefaultDescription.Replace("'","''")
    $iconEsc = $IconPath.Replace("'","''")
    $appVerEsc = $DefaultAppVersion.Replace("'","''")
    $infoUrlEsc = $DefaultInformationUrl.Replace("'","''")
    $privacyUrlEsc = $DefaultPrivacyUrl.Replace("'","''")
    $developerEsc = $DefaultDeveloper.Replace("'","''")
    $ownerEsc = $DefaultOwner.Replace("'","''")
    $notesEsc = $DefaultNotes.Replace("'","''")
    $detRegexEsc = $DetectionNameRegex.Replace("'","''")
    $detUseVerEsc = $DetectionUseVersion.Replace("'","''")
    $detVerEsc = $DetectionVersion.Replace("'","''")
    $detRootsEsc = $DetectionRegistryRoots.Replace("'","''")
    $runLog = Join-Path $Global:LogFolder ("intune-upload-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $runLogEsc = $runLog.Replace("'","''")
    $scriptText = @"
param()
`$ErrorActionPreference = 'Stop'
`$packageRoot = '$pkgEsc'
`$intuneWinPath = '$fileEsc'
`$defaultName = '$nameEsc'
`$defaultPublisher = '$pubEsc'
`$defaultDescription = '$descEsc'
`$iconPath = '$iconEsc'
`$defaultAppVersion = '$appVerEsc'
`$defaultInformationUrl = '$infoUrlEsc'
`$defaultPrivacyUrl = '$privacyUrlEsc'
`$defaultDeveloper = '$developerEsc'
`$defaultOwner = '$ownerEsc'
`$defaultNotes = '$notesEsc'
`$detectionNameRegex = '$detRegexEsc'
`$detectionUseVersion = '$detUseVerEsc'
`$detectionVersion = '$detVerEsc'
`$detectionRegistryRoots = '$detRootsEsc'
`$runLog = '$runLogEsc'

Start-Transcript -Path `$runLog -Force | Out-Null
Write-Host "PSADT Intune Upload Assistant" -ForegroundColor Cyan
Write-Host "Package: `$intuneWinPath" -ForegroundColor DarkGray

if (!(Test-Path `$intuneWinPath)) {
    throw "IntuneWin file not found: `$intuneWinPath"
}

if (-not (Get-Module -ListAvailable -Name IntuneWin32App -ErrorAction SilentlyContinue)) {
    Write-Host "IntuneWin32App module not found." -ForegroundColor Yellow
    Install-Module IntuneWin32App -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
}

Import-Module IntuneWin32App -Force -ErrorAction Stop
if (!(Get-Command Add-IntuneWin32App -ErrorAction SilentlyContinue)) {
    throw "Add-IntuneWin32App command not found in IntuneWin32App module."
}
if (!(Get-Command Connect-MSIntuneGraph -ErrorAction SilentlyContinue)) {
    throw "Connect-MSIntuneGraph command not found in IntuneWin32App module."
}
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication -ErrorAction SilentlyContinue)) {
    Write-Host "Microsoft.Graph.Authentication module not found." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
}
Import-Module Microsoft.Graph.Authentication -Force -ErrorAction Stop

Write-Host "`nSigning in to Microsoft Graph..." -ForegroundColor Cyan
`$tenantForIntune = `$null
`$graphClientId = `$null
if (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue) {
    Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","DeviceManagementConfiguration.ReadWrite.All","DeviceManagementManagedDevices.Read.All","Group.Read.All","offline_access" -NoWelcome | Out-Null
    if (Get-Command Select-MgProfile -ErrorAction SilentlyContinue) { Select-MgProfile -Name beta }
    `$mgCtx = Get-MgContext
    if (`$mgCtx) {
        `$tenantForIntune = `$mgCtx.TenantId
        `$graphClientId = `$mgCtx.ClientId
        if (`$mgCtx.Account) { Write-Host ("Signed in as: {0}" -f `$mgCtx.Account) -ForegroundColor DarkGray }
    }
}

Write-Host "Connecting Intune module context..." -ForegroundColor Cyan
`$msiConn = Get-Command Connect-MSIntuneGraph -ErrorAction Stop
`$connectArgs = @{}
if (`$tenantForIntune -and `$msiConn.Parameters.ContainsKey('TenantID')) { `$connectArgs['TenantID'] = `$tenantForIntune }
if (`$msiConn.Parameters.ContainsKey('ClientID') -and `$graphClientId) { `$connectArgs['ClientID'] = `$graphClientId }
if (`$msiConn.Parameters.ContainsKey('Interactive')) { `$connectArgs['Interactive'] = `$true }
if (`$msiConn.Parameters.ContainsKey('ClientID') -and -not `$connectArgs.ContainsKey('ClientID')) {
    throw "Connect-MSIntuneGraph requires ClientID in this environment, but no ClientID was available from Graph sign-in context."
}
Connect-MSIntuneGraph @connectArgs | Out-Null

`$displayName = if ([string]::IsNullOrWhiteSpace(`$defaultName)) { "PSADT Package" } else { `$defaultName }
`$publisher = if ([string]::IsNullOrWhiteSpace(`$defaultPublisher)) { "Unknown Publisher" } else { `$defaultPublisher }
`$description = if ([string]::IsNullOrWhiteSpace(`$defaultDescription)) { "`$displayName via PSADT" } else { `$defaultDescription }
`$appVersion = if ([string]::IsNullOrWhiteSpace(`$defaultAppVersion)) { "" } else { `$defaultAppVersion }
`$informationUrl = if ([string]::IsNullOrWhiteSpace(`$defaultInformationUrl)) { "" } else { `$defaultInformationUrl }
`$privacyUrl = if ([string]::IsNullOrWhiteSpace(`$defaultPrivacyUrl)) { "" } else { `$defaultPrivacyUrl }
`$developer = if ([string]::IsNullOrWhiteSpace(`$defaultDeveloper)) { `$publisher } else { `$defaultDeveloper }
`$owner = if ([string]::IsNullOrWhiteSpace(`$defaultOwner)) { `$publisher } else { `$defaultOwner }
`$notes = if ([string]::IsNullOrWhiteSpace(`$defaultNotes)) { "" } else { `$defaultNotes }

`$installCmd = "powershell.exe -ExecutionPolicy Bypass -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Install -DeployMode Silent"
`$uninstallCmd = "powershell.exe -ExecutionPolicy Bypass -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall -DeployMode Silent"

`$addCmd = Get-Command Add-IntuneWin32App -ErrorAction Stop
function Get-AddParamName([System.Management.Automation.CommandInfo]`$Cmd,[string[]]`$Candidates) {
    foreach (`$n in `$Candidates) {
        foreach (`$k in `$Cmd.Parameters.Keys) {
            if (`$k -ieq `$n) { return `$k }
        }
    }
    return `$null
}
`$args = @{
    FilePath             = `$intuneWinPath
    DisplayName          = `$displayName
    Publisher            = `$publisher
    Description          = `$description
    InstallCommandLine   = `$installCmd
    UninstallCommandLine = `$uninstallCmd
}
`$optionalMetaParamNames = @()
if (`$addCmd.Parameters.ContainsKey('InstallExperience')) { `$args['InstallExperience'] = 'system' }
if (`$addCmd.Parameters.ContainsKey('RestartBehavior')) { `$args['RestartBehavior'] = 'suppress' }
foreach (`$m in @(
    @{ Value = [System.IO.Path]::GetFileName(`$intuneWinPath); Names = @('FileName','Filename','PackageFileName','ContentFileName') },
    @{ Value = `$appVersion;     Names = @('AppVersion','DisplayVersion') },
    @{ Value = `$informationUrl; Names = @('InformationUrl','InformationURL') },
    @{ Value = `$privacyUrl;     Names = @('PrivacyUrl','PrivacyURL') },
    @{ Value = `$developer;      Names = @('Developer') },
    @{ Value = `$owner;          Names = @('Owner') },
    @{ Value = `$notes;          Names = @('Notes') }
)) {
    if ([string]::IsNullOrWhiteSpace([string]`$m.Value)) { continue }
    `$pn = Get-AddParamName -Cmd `$addCmd -Candidates `$m.Names
    if (`$pn) {
        `$args[`$pn] = [string]`$m.Value
        if (`$optionalMetaParamNames -notcontains `$pn) { `$optionalMetaParamNames += `$pn }
    }
}
if (![string]::IsNullOrWhiteSpace(`$iconPath) -and (Test-Path `$iconPath) -and `$addCmd.Parameters.ContainsKey('Icon') -and (Get-Command New-IntuneWin32AppIcon -ErrorAction SilentlyContinue)) {
    try {
        `$icoObj = New-IntuneWin32AppIcon -FilePath `$iconPath
        if (`$icoObj) { `$args['Icon'] = `$icoObj }
    } catch {
        Write-Host "Icon load failed; continuing without icon." -ForegroundColor Yellow
    }
}

if (`$addCmd.Parameters.ContainsKey('DetectionRule') -and (Get-Command New-IntuneWin32AppDetectionRuleScript -ErrorAction SilentlyContinue)) {
    `$detectPath = Join-Path `$env:TEMP ("psadt_detect_{0}.ps1" -f [Guid]::NewGuid().ToString("N"))
    `$nameRegex = if ([string]::IsNullOrWhiteSpace(`$detectionNameRegex)) { ('^' + [regex]::Escape(`$displayName) + '(?:\s|$)') } else { `$detectionNameRegex }
    `$useVersion = if ([string]::IsNullOrWhiteSpace(`$detectionUseVersion)) { ![string]::IsNullOrWhiteSpace(`$appVersion) } else { [System.Convert]::ToBoolean(`$detectionUseVersion) }
    `$ver = if ([string]::IsNullOrWhiteSpace(`$detectionVersion)) { [string]`$appVersion } else { [string]`$detectionVersion }
    `$roots = @()
    if (![string]::IsNullOrWhiteSpace(`$detectionRegistryRoots)) {
        `$roots = @(`$detectionRegistryRoots -split ';' | ForEach-Object { `$_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace(`$_) })
    }
    if (`$roots.Count -eq 0) {
        `$roots = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
    }
    `$nameRegexEsc = `$nameRegex.Replace("'", "''")
    `$verEsc = `$ver.Replace("'", "''")
    `$rootsLit = (`$roots | ForEach-Object { "'" + (`$_.Replace("'", "''")) + "'" }) -join ','
    `$useVersionLit = if (`$useVersion) { '`$true' } else { '`$false' }
    `$detectTemplate = @'
`$roots = @(__ROOTS__)
`$apps = foreach (`$r in `$roots) { Get-ItemProperty -Path `$r -ErrorAction SilentlyContinue }
`$hits = `$apps | Where-Object { `$_.DisplayName -and (`$_.DisplayName -match '__NAME_REGEX__') }
if (__USE_VERSION__ -and ![string]::IsNullOrWhiteSpace('__VERSION__')) { `$hits = `$hits | Where-Object { [string]`$_.DisplayVersion -eq '__VERSION__' } }
if (`$hits -and (`$hits | Select-Object -First 1)) { Write-Output 'Installed'; exit 0 } else { exit 1 }
'@
    `$detectScript = `$detectTemplate.
        Replace('__ROOTS__', `$rootsLit).
        Replace('__NAME_REGEX__', `$nameRegexEsc).
        Replace('__USE_VERSION__', `$useVersionLit).
        Replace('__VERSION__', `$verEsc)
    Set-Content -LiteralPath `$detectPath -Value `$detectScript -Encoding UTF8
    try {
        `$det = New-IntuneWin32AppDetectionRuleScript -ScriptFile `$detectPath -RunAs32Bit `$false -EnforceSignatureCheck `$false
        `$args['DetectionRule'] = `$det
    } catch {
        Write-Host "Detection rule generation failed, upload may require manual rule setup." -ForegroundColor Yellow
    }
}

if (`$addCmd.Parameters.ContainsKey('RequirementRule') -and (Get-Command New-IntuneWin32AppRequirementRule -ErrorAction SilentlyContinue)) {
    try {
        `$reqCmd = Get-Command New-IntuneWin32AppRequirementRule -ErrorAction Stop
        `$archVal = "AllWithARM64"
        if (`$reqCmd.Parameters.ContainsKey('Architecture')) {
            `$validArch = @()
            try { `$validArch = @(`$reqCmd.Parameters['Architecture'].Attributes | Where-Object { `$_ -is [System.Management.Automation.ValidateSetAttribute] } | ForEach-Object { `$_.ValidValues } | Select-Object -First 1) } catch {}
            if (`$validArch -and (`$validArch -contains 'AllWithARM64')) { `$archVal = 'AllWithARM64' }
            elseif (`$validArch -and (`$validArch -contains 'All')) { `$archVal = 'All' }
            elseif (`$validArch -and (`$validArch -contains 'x64x86')) { `$archVal = 'x64x86' }
            elseif (`$validArch -and (`$validArch -contains 'x64')) { `$archVal = 'x64' }
        }
        `$req = New-IntuneWin32AppRequirementRule -Architecture `$archVal -MinimumSupportedWindowsRelease "W10_1607"
        `$args['RequirementRule'] = `$req
    } catch {}
}

Write-Host "`nStarting upload to Intune..." -ForegroundColor Cyan
Write-Host ("Display name : {0}" -f `$displayName) -ForegroundColor DarkGray
Write-Host ("Publisher    : {0}" -f `$publisher) -ForegroundColor DarkGray
Write-Host ("Package file : {0}" -f `$intuneWinPath) -ForegroundColor DarkGray
`$result = `$null
try {
    `$result = Add-IntuneWin32App @args -Verbose
} catch {
    Write-Host ("Warning: upload with optional metadata failed; retrying base upload. {0}" -f `$_.Exception.Message) -ForegroundColor Yellow
    `$retryArgs = @{}
    foreach (`$k in `$args.Keys) { `$retryArgs[`$k] = `$args[`$k] }
    foreach (`$k in `$optionalMetaParamNames) {
        if (`$retryArgs.ContainsKey(`$k)) { `$retryArgs.Remove(`$k) | Out-Null }
    }
    `$result = Add-IntuneWin32App @retryArgs -Verbose
}

`$appId = `$null
if (`$result) {
    foreach (`$prop in @('id','Id','appId','AppId','mobileAppId','MobileAppId')) {
        if (`$result.PSObject.Properties.Name -contains `$prop) {
            `$candidate = [string]`$result.`$prop
            if (![string]::IsNullOrWhiteSpace(`$candidate)) { `$appId = `$candidate; break }
        }
    }
}
`$uploadedFileName = [System.IO.Path]::GetFileName(`$intuneWinPath)
`$fileRenameApplied = `$false
`$mobileFileNamePatched = `$false
if (![string]::IsNullOrWhiteSpace(`$appId) -and (Get-Command Invoke-MgGraphRequest -ErrorAction SilentlyContinue)) {
    try {
        # Patch mobile app-level filename (this is what the portal often displays in "Select file to update").
        `$mbody = @{ fileName = `$uploadedFileName } | ConvertTo-Json -Depth 3
        Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}" -f `$appId) -Body `$mbody -ContentType "application/json" | Out-Null
        # Also patch the win32LobApp typed endpoint.
        Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}/microsoft.graph.win32LobApp" -f `$appId) -Body `$mbody -ContentType "application/json" | Out-Null
        `$mobileFileNamePatched = `$true
    } catch {
        Write-Host ("Warning: could not patch mobile app fileName to '{0}'. {1}" -f `$uploadedFileName, `$_.Exception.Message) -ForegroundColor Yellow
    }
    try {
        # Try to align Intune content file display name with the generated package filename.
        `$cvResp = Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}/microsoft.graph.win32LobApp/contentVersions" -f `$appId)
        `$cvs = @()
        if (`$cvResp -and `$cvResp.value) { `$cvs = @(`$cvResp.value) }
        if (`$cvs.Count -gt 0) {
            `$latestCv = `$cvs | Sort-Object { [int]`$_.id } -Descending | Select-Object -First 1
            if (`$latestCv -and `$latestCv.id) {
                `$filesResp = Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}/microsoft.graph.win32LobApp/contentVersions/{1}/files" -f `$appId, `$latestCv.id)
                `$files = @()
                if (`$filesResp -and `$filesResp.value) { `$files = @(`$filesResp.value) }
                if (`$files.Count -gt 0) {
                    foreach (`$targetFile in `$files) {
                        if (-not `$targetFile -or -not `$targetFile.id) { continue }
                        `$body = @{ name = `$uploadedFileName; fileName = `$uploadedFileName } | ConvertTo-Json -Depth 3
                        Invoke-MgGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/{0}/microsoft.graph.win32LobApp/contentVersions/{1}/files/{2}" -f `$appId, `$latestCv.id, `$targetFile.id) -Body `$body -ContentType "application/json" | Out-Null
                        `$fileRenameApplied = `$true
                    }
                }
            }
        }
    } catch {
        Write-Host ("Warning: could not set uploaded file display name to '{0}'. {1}" -f `$uploadedFileName, `$_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host "`nUpload completed successfully." -ForegroundColor Green
if (![string]::IsNullOrWhiteSpace(`$appId)) {
    `$intuneUrl = "https://intune.microsoft.com/#view/Microsoft_Intune_Apps/SettingsMenu/0/appId/`$appId"
    `$graphUrl  = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/`$appId"
    Write-Host ("App ID       : {0}" -f `$appId) -ForegroundColor Green
    Write-Host ("Intune URL   : {0}" -f `$intuneUrl) -ForegroundColor Cyan
    Write-Host ("Graph URL    : {0}" -f `$graphUrl) -ForegroundColor Cyan
    if (`$mobileFileNamePatched) {
        Write-Host ("App fileName : {0}" -f `$uploadedFileName) -ForegroundColor Green
    }
    if (`$fileRenameApplied) {
        Write-Host ("Package name : {0}" -f `$uploadedFileName) -ForegroundColor Green
    }
} else {
    Write-Host "Upload succeeded but app ID could not be read from response." -ForegroundColor Yellow
}
Write-Host "`nResult details:" -ForegroundColor DarkGray
`$result | Format-List * | Out-Host
Stop-Transcript | Out-Null
"@
    try {
        [System.IO.File]::WriteAllText($tmpScript,$scriptText,[System.Text.Encoding]::UTF8)
        $p = Start-Process -FilePath $psPath -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$tmpScript) -WindowStyle Hidden -PassThru
        Write-DebugLog "INFO" ("IntuneUploadAssistantStarted | Script={0} | File={1} | Log={2} | Pid={3}" -f $tmpScript,$IntuneWinPath,$runLog,$p.Id)
        return [PSCustomObject]@{
            Started    = $true
            Process    = $p
            LogPath    = $runLog
            ScriptPath = $tmpScript
        }
    } catch {
        Write-DebugLog "ERROR" ("IntuneUploadAssistantStartFailed | {0}" -f $_.Exception.Message)
        return [PSCustomObject]@{
            Started = $false
            Error   = $_.Exception.Message
        }
    }
}

function Find-DownloadedInstaller([string]$FilesFolder) {
    if ([string]::IsNullOrWhiteSpace($FilesFolder) -or !(Test-Path $FilesFolder)) { return $null }

    $all = Get-ChildItem -Path $FilesFolder -Recurse -File -ErrorAction SilentlyContinue
    if (!$all) { return $null }

    $preferredExt = @(".exe",".msi",".msp",".msix",".appx",".msixbundle",".appxbundle")
    $preferred = $all | Where-Object { $preferredExt -contains $_.Extension.ToLowerInvariant() } |
        Sort-Object LastWriteTime -Descending
    if ($preferred) { return $preferred | Select-Object -First 1 }

    # Fallback: choose newest, non-manifest, non-log file with non-trivial size.
    $skipExt = @(".txt",".log",".json",".yaml",".yml",".xml",".sha256",".md")
    $candidate = $all |
        Where-Object { ($skipExt -notcontains $_.Extension.ToLowerInvariant()) -and $_.Length -gt 102400 } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $candidate
}
function Get-PackageContext([object]$SelectedItem) {
    $packageRoot = $null
    $appName = $null
    if ($SelectedItem -and $SelectedItem.Name) {
        $appName = [string]$SelectedItem.Name
        $safe = Get-SafeName $appName
        $packageRoot = Join-Path $Global:PackageRoot $safe
    } elseif ($Global:SelectedPackage -and (Test-Path $Global:SelectedPackage)) {
        $packageRoot = $Global:SelectedPackage
        $appName = Split-Path $packageRoot -Leaf
    }
    if ([string]::IsNullOrWhiteSpace($packageRoot)) { return $null }

    $filesFolder = Join-Path $packageRoot "Files"
    $scriptPath  = Join-Path $packageRoot "Invoke-AppDeployToolkit.ps1"
    $installer   = Find-DownloadedInstaller $filesFolder
    return [PSCustomObject]@{
        PackageRoot  = $packageRoot
        FilesFolder  = $filesFolder
        ScriptPath   = $scriptPath
        AppName      = if ($appName) { $appName } else { Split-Path $packageRoot -Leaf }
        HasPackage   = (Test-Path $packageRoot)
        HasFiles     = (Test-Path $filesFolder)
        HasScript    = (Test-Path $scriptPath)
        Installer    = $installer
        HasInstaller = ($null -ne $installer)
    }
}
function Get-AppDetailsDefaults([string]$AppName,[string]$Version) {
    $spec = Get-AppDetailFieldSpec
    $d = [ordered]@{}
    foreach ($f in $spec) {
        $d[$f.Key] = [string]$f.Default
    }
    $d["AppName"] = if ([string]::IsNullOrWhiteSpace($AppName)) { "Application" } else { $AppName }
    $d["AppVersion"] = if ([string]::IsNullOrWhiteSpace($Version)) { "1.0.0" } else { $Version }
    return $d
}
function Get-AppDetailFieldSpec {
    return @(
        @{Key="AppVendor";Label="App Vendor";Kind="string";Default="Unknown Publisher"},
        @{Key="AppName";Label="App Name";Kind="string";Default="Application"},
        @{Key="AppVersion";Label="App Version";Kind="string";Default="1.0.0"},
        @{Key="AppArch";Label="App Arch";Kind="string";Default="x64"},
        @{Key="AppLang";Label="App Language";Kind="string";Default="EN"},
        @{Key="AppRevision";Label="App Revision";Kind="string";Default="01"},
        @{Key="AppSuccessExitCodes";Label="App Success Exit Codes";Kind="raw";Default="@(0)"},
        @{Key="AppRebootExitCodes";Label="App Reboot Exit Codes";Kind="raw";Default="@(1641, 3010)"},
        @{Key="AppProcessesToClose";Label="App Processes To Close";Kind="raw";Default="@()";Example=(Get-CloseProcessesExample)},
        @{Key="AppIconPath";Label="App Icon Path";Kind="string";Default=""},
        @{Key="AppScriptVersion";Label="Script Version";Kind="string";Default="1.0.0"},
        @{Key="AppScriptDate";Label="Script Date";Kind="string";Default=(Get-Date -Format "yyyy-MM-dd")},
        @{Key="AppScriptAuthor";Label="Script Author";Kind="string";Default=$env:USERNAME},
        @{Key="RequireAdmin";Label="Require Admin";Kind="raw";Default='$true'},
        @{Key="InstallName";Label="Install Name";Kind="string";Default=""},
        @{Key="InstallTitle";Label="Install Title";Kind="string";Default=""}
    )
}
function Get-VendorFromPackageId([string]$PackageId) {
    if ([string]::IsNullOrWhiteSpace($PackageId)) { return "" }
    $parts = $PackageId.Split(".")
    if ($parts.Count -gt 0) { return $parts[0] }
    return ""
}
function Find-PackageIcon([string]$PackageRoot,[string]$FilesFolder) {
    $ext = @(".ico",".png",".jpg",".jpeg",".bmp")
    $candidates = @()
    foreach ($root in @($FilesFolder, (Join-Path $PackageRoot "SupportFiles"), (Join-Path $PackageRoot "Assets"), $PackageRoot)) {
        if ([string]::IsNullOrWhiteSpace($root) -or !(Test-Path $root)) { continue }
        $hits = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $ext -contains $_.Extension.ToLowerInvariant() } |
            Sort-Object LastWriteTime -Descending
        if ($hits) { $candidates += $hits }
    }
    if ($candidates.Count -gt 0) { return $candidates[0].FullName }
    return ""
}
function Get-DetectionConfigPath([string]$ScriptPath) {
    if ([string]::IsNullOrWhiteSpace($ScriptPath)) { return "" }
    $dir = Split-Path -Path $ScriptPath -Parent
    if ([string]::IsNullOrWhiteSpace($dir)) { return "" }
    return (Join-Path $dir "WinGet-PSADT GUI Tool.Detection.json")
}
function Get-DetectionDefaults([string]$AppName,[string]$AppVersion) {
    $name = if ([string]::IsNullOrWhiteSpace($AppName)) { "Application" } else { $AppName }
    $ver = if ([string]::IsNullOrWhiteSpace($AppVersion)) { "" } else { [string]$AppVersion }
    return [ordered]@{
        DetectionNameRegex    = '^' + [regex]::Escape($name) + '(?:\s|$)'
        DetectionUseVersion   = if ([string]::IsNullOrWhiteSpace($ver)) { "false" } else { "true" }
        DetectionVersion      = $ver
        DetectionRegistryRoots= 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*;HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
}
function Get-DetectionConfigForScript([string]$ScriptPath,[string]$AppName,[string]$AppVersion) {
    $d = Get-DetectionDefaults -AppName $AppName -AppVersion $AppVersion
    $cfgPath = Get-DetectionConfigPath -ScriptPath $ScriptPath
    if ([string]::IsNullOrWhiteSpace($cfgPath) -or !(Test-Path $cfgPath)) { return $d }
    try {
        $obj = Get-Content -LiteralPath $cfgPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        foreach ($k in @("DetectionNameRegex","DetectionUseVersion","DetectionVersion","DetectionRegistryRoots")) {
            if ($obj.PSObject.Properties.Name -contains $k) {
                $v = [string]$obj.$k
                if ($null -ne $v) { $d[$k] = $v }
            }
        }
    } catch {}
    return $d
}
function Save-DetectionConfigForScript([string]$ScriptPath,[hashtable]$Config) {
    $cfgPath = Get-DetectionConfigPath -ScriptPath $ScriptPath
    if ([string]::IsNullOrWhiteSpace($cfgPath)) { throw "Invalid detection config path." }
    $obj = [ordered]@{
        DetectionNameRegex     = [string]$Config["DetectionNameRegex"]
        DetectionUseVersion    = [string]$Config["DetectionUseVersion"]
        DetectionVersion       = [string]$Config["DetectionVersion"]
        DetectionRegistryRoots = [string]$Config["DetectionRegistryRoots"]
    }
    $json = $obj | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($cfgPath,$json,[System.Text.Encoding]::UTF8)
}
function Ensure-AppDetailsDefaultsInScript([string]$ScriptPath,[string]$AppName,[string]$Version,[string]$Vendor,[string]$PackageRoot,[string]$FilesFolder) {
    $cur = Get-AppDetailsFromScript -ScriptPath $ScriptPath -AppName $AppName -Version $Version
    $changed = $false
    if ([string]::IsNullOrWhiteSpace($cur.AppName)) { $cur.AppName = $AppName; $changed = $true }
    if ([string]::IsNullOrWhiteSpace($cur.AppVersion) -or $cur.AppVersion -eq "1.0.0") { $cur.AppVersion = $Version; $changed = $true }
    if ([string]::IsNullOrWhiteSpace($cur.AppVendor) -or $cur.AppVendor -eq "Unknown Publisher") {
        if (![string]::IsNullOrWhiteSpace($Vendor)) { $cur.AppVendor = $Vendor; $changed = $true }
    }
    if ([string]::IsNullOrWhiteSpace($cur.AppIconPath)) {
        $icon = Find-PackageIcon -PackageRoot $PackageRoot -FilesFolder $FilesFolder
        if (![string]::IsNullOrWhiteSpace($icon)) { $cur.AppIconPath = $icon; $changed = $true }
    }
    if ($changed) {
        Save-AppDetailsToScript -ScriptPath $ScriptPath -Details $cur
    }
}
function Get-AppDetailsFromScript([string]$ScriptPath,[string]$AppName,[string]$Version) {
    $defaults = Get-AppDetailsDefaults -AppName $AppName -Version $Version
    $spec = Get-AppDetailFieldSpec
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { return $defaults }
    try {
        $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
        $mSession = [regex]::Match($text,'(?ms)^\s*\$adtSession\s*=\s*@\{(?<body>.*?)(?m)^\s*\}')
        if ($mSession.Success) {
            $body = $mSession.Groups['body'].Value
            foreach ($f in $spec) {
                $k = $f.Key
                $m = [regex]::Match($body, "(?m)^\s*" + [regex]::Escape($k) + "\s*=\s*(.+?)(?:\s*#.*)?$")
                if ($m.Success) {
                    $raw = $m.Groups[1].Value.Trim()
                    if ($f.Kind -eq "string") {
                        if ($raw -match "^'(.*)'$") {
                            $defaults[$k] = ($Matches[1] -replace "''","'")
                        } else {
                            $defaults[$k] = $raw
                        }
                    } else {
                        $defaults[$k] = $raw
                    }
                }
            }
        }
    } catch {}
    return $defaults
}
function Save-AppDetailsToScript([string]$ScriptPath,[hashtable]$Details) {
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { throw "Script file not found: $ScriptPath" }
    $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
    # Remove legacy generator block if present.
    $text = [regex]::Replace($text,'(?s)\r?\n?\s*# WinGet-PSADT GUI Tool:BEGIN-APPDETAILS.*?# WinGet-PSADT GUI Tool:END-APPDETAILS\s*\r?\n?','')

    $mSession = [regex]::Match($text,'(?ms)^\s*\$adtSession\s*=\s*@\{(?<body>.*?)(?m)^\s*\}')
    if (!$mSession.Success) {
        throw "Could not find `$adtSession hashtable in Invoke-AppDeployToolkit.ps1"
    }
    $body = $mSession.Groups['body'].Value
    $spec = Get-AppDetailFieldSpec
    foreach ($f in $spec) {
        $k = $f.Key
        $v = if ($Details.ContainsKey($k)) { [string]$Details[$k] } else { [string]$f.Default }
        if ([string]::IsNullOrWhiteSpace($v)) { $v = [string]$f.Default }
        $expr = if ($f.Kind -eq "string") { "'" + ($v -replace "'","''") + "'" } else { $v.Trim() }
        $p = "(?m)^(\s*" + [regex]::Escape($k) + "\s*=\s*)(.+?)(\s*(?:#.*)?$)"
        if ([regex]::IsMatch($body,$p)) {
            $body = [regex]::Replace($body,$p,('$1' + $expr + '$3'),1)
        } else {
            $insert = "    $k = $expr"
            if ($body -match "(?m)^\s*DeployAppScriptFriendlyName\s*=") {
                $body = [regex]::Replace($body,"(?m)^(\s*DeployAppScriptFriendlyName\s*=.*)$","$insert`r`n`$1",1)
            } else {
                $body = $body + "`r`n" + $insert
            }
        }
    }

    $newSession = '$adtSession = @{' + $body + "`r`n}"
    $text = $text.Substring(0,$mSession.Index) + $newSession + $text.Substring($mSession.Index + $mSession.Length)
    [System.IO.File]::WriteAllText($ScriptPath,$text,[System.Text.Encoding]::UTF8)
}
function Get-SAIWDefaults {
    $d = [ordered]@{}
    foreach ($f in (Get-SAIWFieldSpec)) {
        $d[$f.Key] = [string]$f.Default
    }
    return $d
}
function Get-SAIWFieldSpec {
    $spec = [System.Collections.Generic.List[hashtable]]::new()
    $meta = $null
    if ($Global:PSADTFunctions -and $Global:PSADTFunctions.Contains("User Interface")) {
        $ui = $Global:PSADTFunctions["User Interface"]
        if ($ui -and $ui.Contains("Show-ADTInstallationWelcome")) {
            $meta = $ui["Show-ADTInstallationWelcome"]
        }
    }
    if ($meta -and $meta.Params) {
        foreach ($pName in $meta.Params.Keys) {
            $key = ([string]$pName).Trim()
            if ($key.StartsWith("-")) { $key = $key.Substring(1) }
            $pDef = $meta.Params[$pName]
            $defVal = ""
            if (($pDef -is [System.Collections.IDictionary]) -and $pDef.Contains("Default")) {
                $defVal = [string]$pDef.Default
            } elseif (($pDef.Type -eq "switch") -or ($pDef.ParamType -eq "SwitchParameter")) {
                $defVal = '$false'
            }
            $label = $key
            $isBool = (($pDef.Type -eq "switch") -or ($pDef.ParamType -eq "SwitchParameter") -or ($defVal -in @('$true','$false','true','false')))
            $isEnum = (($pDef.Type -eq "combo") -or (($pDef -is [System.Collections.IDictionary]) -and $pDef.Contains("Options") -and @($pDef.Options).Count -gt 0))
            $opts = @()
            if ($isEnum -and ($pDef -is [System.Collections.IDictionary]) -and $pDef.Contains("Options")) { $opts = @($pDef.Options) }
            $spec.Add(@{
                Key     = $key
                Label   = $label
                Default = $defVal
                IsBool  = $isBool
                IsEnum  = $isEnum
                Options = $opts
            }) | Out-Null
        }
    }
    if ($spec.Count -eq 0) {
        # Safe fallback when metadata cannot be discovered.
        $spec.Add(@{Key="AllowDefer";Label="AllowDefer";Default='$true';IsBool=$true;IsEnum=$false;Options=@()}) | Out-Null
        $spec.Add(@{Key="DeferTimes";Label="DeferTimes";Default='3';IsBool=$false;IsEnum=$false;Options=@()}) | Out-Null
        $spec.Add(@{Key="CheckDiskSpace";Label="CheckDiskSpace";Default='$true';IsBool=$true;IsEnum=$false;Options=@()}) | Out-Null
        $spec.Add(@{Key="PersistPrompt";Label="PersistPrompt";Default='$true';IsBool=$true;IsEnum=$false;Options=@()}) | Out-Null
    }
    return @($spec)
}
function Get-SAIWParamsFromScript([string]$ScriptPath) {
    $d = @{}
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { return $d }
    try {
        $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
        $m = [regex]::Match($text,'(?ms)^\s*\$saiwParams\s*=\s*@\{(?<body>.*?)(?m)^\s*\}')
        if ($m.Success) {
            $body = $m.Groups['body'].Value
            foreach ($k in (Get-SAIWFieldSpec | ForEach-Object { $_.Key })) {
                $mx = [regex]::Match($body,"(?m)^\s*" + [regex]::Escape($k) + "\s*=\s*(.+?)(?:\s*#.*)?$")
                if ($mx.Success) { $d[$k] = $mx.Groups[1].Value.Trim() }
            }
        }
    } catch {}
    return $d
}
function Save-SAIWParamsToScript([string]$ScriptPath,[hashtable]$Params) {
    function Format-SAIWValue([hashtable]$Field,[string]$RawValue) {
        $v = if ($null -eq $RawValue) { "" } else { [string]$RawValue }
        if ([string]::IsNullOrWhiteSpace($v)) { return "" }
        $t = $v.Trim()
        if ($Field.IsBool) { return $t }
        if ($t -match '^-?\d+(\.\d+)?$') { return $t }
        if ($t -match "^\$|^\(|^\{|^\[|^@\(") { return $t }
        if ($t -match "^'.*'$|^"".*""$") { return $t }
        $esc = $t.Replace("'","''")
        return "'" + $esc + "'"
    }
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { throw "Script file not found: $ScriptPath" }
    $spec = Get-SAIWFieldSpec
    $defaults = Get-SAIWDefaults
    $p = @{}
    foreach ($k in ($spec | ForEach-Object { $_.Key })) {
        if ($Params.ContainsKey($k)) { $p[$k] = ([string]$Params[$k]).Trim() }
    }
    $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
    $mInstall = [regex]::Match($text,'(?ms)function\s+Install-ADTDeployment\b.*?(?=^\s*function\s+Uninstall-ADTDeployment\b)')
    if (!$mInstall.Success) { throw "Could not find Install-ADTDeployment function block." }
    $installBlock = $mInstall.Value

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('    $saiwParams = @{') | Out-Null
    $falseTokens = @('$false','false')
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($f in $spec) {
        $k = $f.Key
        $v = if ($p.Contains($k)) { [string]$p[$k] } else { "" }
        if ([string]::IsNullOrWhiteSpace($v)) { continue }
        $vt = $v.Trim()
        if ($f.IsBool -and ($falseTokens -contains $vt.ToLowerInvariant())) { continue }
        if ((-not $f.IsBool) -and $defaults.Contains($k) -and ([string]$defaults[$k]).Trim() -eq $vt) { continue }
        $fmt = Format-SAIWValue -Field $f -RawValue $vt
        if (![string]::IsNullOrWhiteSpace($fmt)) {
            $entries.Add([PSCustomObject]@{ Key = $k; Value = $fmt }) | Out-Null
        }
    }
    $maxKeyLen = 0
    foreach ($e in $entries) {
        if ($e.Key.Length -gt $maxKeyLen) { $maxKeyLen = $e.Key.Length }
    }
    foreach ($e in $entries) {
        $padKey = $e.Key.PadRight($maxKeyLen)
        $lines.Add(("        {0} = {1}" -f $padKey, $e.Value)) | Out-Null
    }
    $lines.Add('    }') | Out-Null
    $lines.Add('    if ($adtSession.AppProcessesToClose.Count -gt 0)') | Out-Null
    $lines.Add('    {') | Out-Null
    $lines.Add('        $saiwParams.Add(''CloseProcesses'', $adtSession.AppProcessesToClose)') | Out-Null
    $lines.Add('    }') | Out-Null
    $lines.Add('    ## Show Welcome Message, close processes if specified, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt.') | Out-Null
    $lines.Add('    Show-ADTInstallationWelcome @saiwParams') | Out-Null
    $block = ($lines -join "`r`n")

    # Work only inside Pre-Install phase section.
    $mPre = [regex]::Match($installBlock,'(?ms)^\s*##\s*MARK:\s*Pre-Install\b.*?(?=^\s*##\s*MARK:\s*Install\b)')
    if (!$mPre.Success) { throw "Could not find Pre-Install phase section in Install-ADTDeployment." }
    $preSection = $mPre.Value

    # Remove existing SAIW block + welcome line in Pre-Install only.
    $preSection = [regex]::Replace($preSection,'(?ms)^\s*\$saiwParams\s*=\s*@\{.*?^\s*\}\s*','')
    $preSection = [regex]::Replace($preSection,'(?m)^\s*if\s*\(\$adtSession\.AppProcessesToClose\.Count\s*-gt\s*0(?:\s*-and\s*-not\s+\$saiwParams\.ContainsKey\(''CloseProcesses''\))?\)\s*$','')
    $preSection = [regex]::Replace($preSection,'(?m)^\s*\$saiwParams\.Add\(''CloseProcesses''\s*,\s*\$adtSession\.AppProcessesToClose\)\s*$','')
    $preSection = [regex]::Replace($preSection,'(?m)^\s*Show-ADTInstallationWelcome\s+@saiwParams\s*$','')
    $preSection = [regex]::Replace($preSection,'(?m)^\s*##\s*Show Welcome Message.*$','')
    $preSection = [regex]::Replace($preSection,'(?ms)^\s*\{\s*\r?\n\s*\}\s*(?:\r?\n)?','')

    # Insert before progress comment, else before Pre-Install tasks marker.
    $insertAt = -1
    $mProg = [regex]::Match($preSection,'(?m)^\s*##\s*Show Progress Message.*$')
    if ($mProg.Success) { $insertAt = $mProg.Index }
    else {
        $mMarker = [regex]::Match($preSection,'(?m)^\s*##\s*<Perform Pre-Installation tasks here>\s*$')
        if ($mMarker.Success) { $insertAt = $mMarker.Index }
    }
    if ($insertAt -lt 0) { $insertAt = $preSection.Length }
    $preSection = $preSection.Substring(0,$insertAt).TrimEnd() + "`r`n`r`n" + $block + "`r`n`r`n" + $preSection.Substring($insertAt).TrimStart()

    $installBlock = $installBlock.Substring(0,$mPre.Index) + $preSection + $installBlock.Substring($mPre.Index + $mPre.Length)

    $text = $text.Substring(0,$mInstall.Index) + $installBlock + $text.Substring($mInstall.Index + $mInstall.Length)
    [System.IO.File]::WriteAllText($ScriptPath,$text,[System.Text.Encoding]::UTF8)
}
function Normalize-PSADTTemplateSections([string]$ScriptPath) {
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { return }
    $text = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
    $fixes = @(
        @{
            Fn = "Install-ADTDeployment"
            Next = "Uninstall-ADTDeployment"
            Map = @{
                "## MARK: Uninstall" = "## MARK: Install"
                "## MARK: Post-Uninstallation" = "## MARK: Post-Install"
                "## <Perform Pre-Uninstallation tasks here>" = "## <Perform Pre-Installation tasks here>"
                "## <Perform Uninstallation tasks here>" = "## <Perform Installation tasks here>"
                "## <Perform Post-Uninstallation tasks here>" = "## <Perform Post-Installation tasks here>"
            }
        },
        @{
            Fn = "Uninstall-ADTDeployment"
            Next = "Repair-ADTDeployment"
            Map = @{
                "## MARK: Install" = "## MARK: Uninstall"
                "## MARK: Post-Install" = "## MARK: Post-Uninstallation"
                "## <Perform Pre-Installation tasks here>" = "## <Perform Pre-Uninstallation tasks here>"
                "## <Perform Installation tasks here>" = "## <Perform Uninstallation tasks here>"
                "## <Perform Post-Installation tasks here>" = "## <Perform Post-Uninstallation tasks here>"
            }
        },
        @{
            Fn = "Repair-ADTDeployment"
            Next = ""
            Map = @{
                "## MARK: Install" = "## MARK: Repair"
                "## MARK: Post-Install" = "## MARK: Post-Repair"
                "## <Perform Pre-Installation tasks here>" = "## <Perform Pre-Repair tasks here>"
                "## <Perform Installation tasks here>" = "## <Perform Repair tasks here>"
                "## <Perform Post-Installation tasks here>" = "## <Perform Post-Repair tasks here>"
                "## MARK: Uninstall" = "## MARK: Repair"
                "## MARK: Post-Uninstallation" = "## MARK: Post-Repair"
                "## <Perform Pre-Uninstallation tasks here>" = "## <Perform Pre-Repair tasks here>"
                "## <Perform Uninstallation tasks here>" = "## <Perform Repair tasks here>"
                "## <Perform Post-Uninstallation tasks here>" = "## <Perform Post-Repair tasks here>"
            }
        }
    )
    foreach ($f in $fixes) {
        $pattern = if ([string]::IsNullOrWhiteSpace($f.Next)) {
            "(?ms)function\s+$([regex]::Escape($f.Fn))\b.*$"
        } else {
            "(?ms)function\s+$([regex]::Escape($f.Fn))\b.*?(?=^\s*function\s+$([regex]::Escape($f.Next))\b)"
        }
        $m = [regex]::Match($text,$pattern)
        if (!$m.Success) { continue }
        $blk = $m.Value
        foreach ($k in $f.Map.Keys) {
            $blk = $blk -replace [regex]::Escape($k), [string]$f.Map[$k]
        }
        $text = $text.Substring(0,$m.Index) + $blk + $text.Substring($m.Index + $m.Length)
    }
    # Hard line-based removal of the default Post-Install completion prompt block
    # inside Install-ADTDeployment:
    #   ## Display a message at the end of the install.
    #   if (!$adtSession.UseDefaultMsi) { ... }
    $mInstallFn = [regex]::Match($text,"(?ms)function\s+Install-ADTDeployment\b.*?(?=^\s*function\s+Uninstall-ADTDeployment\b)")
    if ($mInstallFn.Success) {
        $installFn = $mInstallFn.Value
        $src = @($installFn -split "`r?`n")
        $dst = [System.Collections.Generic.List[string]]::new()
        $skipComment = $false
        $skipIfBlock = $false
        $braceDepth = 0
        foreach ($ln in $src) {
            $t = $ln.Trim()
            if (!$skipComment -and !$skipIfBlock -and $t -eq '## Display a message at the end of the install.') {
                $skipComment = $true
                continue
            }
            if ($skipComment -and !$skipIfBlock) {
                if ($t -match '^if\s*\(!\$adtSession\.UseDefaultMsi\)\s*$') {
                    $skipIfBlock = $true
                    $braceDepth = 0
                    continue
                }
                if ([string]::IsNullOrWhiteSpace($t)) { continue }
                $skipComment = $false
            }
            if ($skipIfBlock) {
                $openCount = ([regex]::Matches($ln,'\{')).Count
                $closeCount = ([regex]::Matches($ln,'\}')).Count
                $braceDepth += ($openCount - $closeCount)
                if ($braceDepth -le 0 -and $closeCount -gt 0) {
                    $skipIfBlock = $false
                    $skipComment = $false
                }
                continue
            }
            $dst.Add($ln) | Out-Null
        }
        $installFn = ($dst -join "`r`n")
        $text = $text.Substring(0,$mInstallFn.Index) + $installFn + $text.Substring($mInstallFn.Index + $mInstallFn.Length)
    }
    [System.IO.File]::WriteAllText($ScriptPath,$text,[System.Text.Encoding]::UTF8)
}
function Repair-PSADTGeneratedScript([string]$ScriptPath,[string]$TemplatePath = "") {
    if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { throw "Script file not found: $ScriptPath" }
    $resolvedTemplate = $TemplatePath
    if ([string]::IsNullOrWhiteSpace($resolvedTemplate)) {
        $candidates = @(
            "d:\Organization\Intune_Scripts\Application\Win32AppPackaging\Packaging Tool\PSADT Template\PSADT-DD-Template\Invoke-AppDeployToolkit_Template.ps1",
            (Join-Path $Global:ScriptBase "Invoke-AppDeployToolkit_Template.ps1"),
            (Join-Path $Global:ScriptBase "Template\Invoke-AppDeployToolkit_Template.ps1"),
            (Join-Path $Global:ScriptBase "PSADT Template\Invoke-AppDeployToolkit_Template.ps1")
        )
        foreach ($c in $candidates) {
            if (Test-Path $c) { $resolvedTemplate = $c; break }
        }
    }
    if ([string]::IsNullOrWhiteSpace($resolvedTemplate) -or !(Test-Path $resolvedTemplate)) {
        throw "Default template file not found. Provide Invoke-AppDeployToolkit_Template.ps1."
    }
    $templateText = [System.IO.File]::ReadAllText($resolvedTemplate,[System.Text.Encoding]::UTF8)
    [System.IO.File]::WriteAllText($ScriptPath,$templateText,[System.Text.Encoding]::UTF8)
}

$TitleBar.Add_MouseLeftButtonDown({ $Window.DragMove() })
$MinBtn.Add_Click({ $Window.WindowState = "Minimized" })
$MaxBtn.Add_Click({
    if ($Window.WindowState -eq "Maximized") { $Window.WindowState = "Normal" }
    else { $Window.WindowState = "Maximized" }
})
$CloseBtn.Add_Click({
    Write-DebugLog "INFO" "MainWindowCloseClicked"
    $Window.Close()
})
$LogsBtn.Add_Click({
    Show-Progress
    try {
        if (Test-Path $Global:LogFile) {
            Start-Process -FilePath "notepad.exe" -ArgumentList "`"$($Global:LogFile)`""
            Write-DebugLog "INFO" ("OpenLogsClick | OpenedFile={0}" -f $Global:LogFile)
        } elseif (Test-Path $Global:LogFolder) {
            Start-Process -FilePath "explorer.exe" -ArgumentList "`"$($Global:LogFolder)`""
            Write-DebugLog "WARN" ("OpenLogsClick | Log file missing, opened folder={0}" -f $Global:LogFolder)
        } else {
            Show-Msg("Logs folder not found yet.","Logs",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
            Write-DebugLog "WARN" "OpenLogsClick | Logs folder missing"
        }
    } catch {
        Show-Msg("Failed to open logs:`n$($_.Exception.Message)","Logs",
            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
        Write-DebugLog "ERROR" ("OpenLogsClickFailed | {0}" -f $_.Exception.Message)
    } finally {
        Hide-Progress
    }
})

# Enter key triggers search
$SearchBox.Add_KeyDown({
    if ($_.Key -eq "Return") { $SearchBtn.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent)) }
})

$SearchBtn.Add_Click({
    $q = $SearchBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($q)) { return }
    $script:SearchQueryText = $q
    Write-DebugLog "INFO" ("SearchClick | Query={0}" -f $q)
    Set-Status "Searching winget for '$q'..." "#3B82F6"
    Show-Progress
    $ResultsGrid.ItemsSource = $null

    # Cleanup prior search cycle
    try {
        if ($script:SearchTimer) { $script:SearchTimer.Stop() }
        if ($script:SearchJob -and $script:SearchJob.State -in @("Running","NotStarted")) {
            Stop-Job $script:SearchJob -ErrorAction SilentlyContinue | Out-Null
        }
        if ($script:SearchJob) {
            Remove-Job $script:SearchJob -Force -ErrorAction SilentlyContinue
            $script:SearchJob = $null
        }
    } catch {}

    $script:SearchJob = Start-Job -ScriptBlock {
        param($query)
        $wc = Get-Command winget -ErrorAction SilentlyContinue
        $winget = if ($wc) { $wc.Source } else { $null }
        if (!$winget) {
            $wPath = "$env:LocalAppData\Microsoft\WindowsApps\winget.exe"
            if (Test-Path $wPath) { $winget = $wPath }
        }
        if (!$winget) { return @() }

        $results = [System.Collections.Generic.List[hashtable]]::new()
        $seenIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        try {
            $jraw = & $winget search $query --source winget --accept-source-agreements --disable-interactivity --output json 2>$null
            if ($jraw) {
                $jtxt = ($jraw -join "`n").Trim()
                if ($jtxt) {
                    $parsed = ConvertFrom-Json $jtxt -ErrorAction Stop
                    $rows = @()
                    if ($parsed -is [System.Array]) { $rows = $parsed }
                    elseif ($parsed -and $parsed.Data) { $rows = @($parsed.Data) }
                    else { $rows = @($parsed) }
                    foreach ($r in $rows) {
                        if (!$r) { continue }
                        $nameVal = [string]($r.Name)
                        if ([string]::IsNullOrWhiteSpace($nameVal)) { $nameVal = [string]($r.PackageName) }
                        if ([string]::IsNullOrWhiteSpace($nameVal)) { $nameVal = [string]($r.PackageIdentifier) }
                        $idVal   = [string]($r.Id)
                        if ([string]::IsNullOrWhiteSpace($idVal)) { $idVal = [string]($r.PackageIdentifier) }
                        $verVal  = [string]($r.Version)
                        if ([string]::IsNullOrWhiteSpace($verVal)) { $verVal = [string]($r.AvailableVersion) }
                        $srcVal  = [string]($r.Source)
                        if ([string]::IsNullOrWhiteSpace($srcVal)) { $srcVal = [string]($r.SourceIdentifier) }
                        if ([string]::IsNullOrWhiteSpace($srcVal)) { $srcVal = "winget" }
                        if ($idVal -match '\.' -and $seenIds.Add($idVal)) {
                            $results.Add(@{Name=$nameVal;ID=$idVal;Version=$verVal;Source=$srcVal})
                        }
                    }
                }
            }
        } catch {}
        if ($results.Count -gt 0) { return $results }

        $raw = & $winget search $query --source winget --accept-source-agreements --disable-interactivity 2>&1
        $headerIdx=-1; $sepIdx=-1; $colStarts=@(); $hline=""
        for ($i=0; $i -lt $raw.Count; $i++) {
            $line = ($raw[$i] -replace "\x1b\[[0-9;]*[A-Za-z]","" -replace "[^\x20-\x7E]","")
            if ($headerIdx -lt 0 -and $line -match '\bName\b' -and $line -match '\bId\b' -and $line -match '\bVersion\b') {
                $headerIdx=$i; $hline=$line; continue
            }
            if ($headerIdx -ge 0 -and $sepIdx -lt 0 -and $line -match '^[-\s]{10,}$') {
                $sepIdx=$i
                foreach ($col in @('Name','Id','Version','Source')) {
                    $idx=$hline.IndexOf($col)
                    if ($idx -ge 0) { $colStarts+=$idx }
                }
                continue
            }
            if ($sepIdx -ge 0 -and ![string]::IsNullOrWhiteSpace($line)) {
                $cols=@("","","","")
                for ($c=0; $c -lt $colStarts.Count; $c++) {
                    $s=$colStarts[$c]
                    $e=if($c+1 -lt $colStarts.Count){$colStarts[$c+1]}else{$line.Length}
                    if($s -lt $line.Length){$cols[$c]=$line.Substring($s,[Math]::Min($e,$line.Length)-$s).Trim()}
                }
                $nameVal = $cols[0]; $idVal = $cols[1]; $verVal = $cols[2]; $srcVal = $cols[3]
                if ($idVal -match '\.' -and $nameVal -ne '' -and $seenIds.Add($idVal)) {
                    $results.Add(@{Name=$nameVal;ID=$idVal;Version=$verVal;Source=$srcVal})
                }
            } elseif (![string]::IsNullOrWhiteSpace($line) -and $line -notmatch '^\s*(Name|[-]+)\b') {
                $parts = $line.Trim() -split '\s{2,}'
                if ($parts.Count -ge 2) {
                    $nameVal  = $parts[0].Trim()
                    $idVal    = $parts[1].Trim()
                    $verVal   = if ($parts.Count -ge 3) { $parts[2].Trim() } else { "" }
                    $matchVal = if ($parts.Count -ge 4) { $parts[3].Trim() } else { "" }
                    $srcVal   = if ($parts.Count -ge 5) { $parts[4].Trim() } else { "winget" }
                    if ([string]::IsNullOrWhiteSpace($srcVal) -or $srcVal -match '^(Moniker|Tag|Command)\s*:') { $srcVal = "winget" }
                    if ($verVal -match '^(Moniker|Tag|Command)\s*:') { $verVal = "" }
                    if ($idVal -match '\.' -and $nameVal -ne '' -and $seenIds.Add($idVal)) {
                        $results.Add(@{Name=$nameVal;ID=$idVal;Version=$verVal;Source=$srcVal})
                    }
                }
            }
        }
        return $results
    } -ArgumentList $q

    $script:SearchTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:SearchTimer.Interval = [TimeSpan]::FromMilliseconds(350)
    $script:SearchTimer.Add_Tick({
        if ($script:SearchJob -and $script:SearchJob.State -in @("Completed","Failed","Stopped")) {
            $script:SearchTimer.Stop()
            Hide-Progress
            try {
                $rows = Receive-Job $script:SearchJob -ErrorAction SilentlyContinue
                Remove-Job $script:SearchJob -Force -ErrorAction SilentlyContinue
                $script:SearchJob = $null

                if ($rows -and $rows.Count -gt 0) {
                    $items = $rows | ForEach-Object {
                        $src = [string]$_.Source
                        if ([string]::IsNullOrWhiteSpace($src)) { $src = "winget" }
                        [PSCustomObject]@{
                            Name    = $_.Name
                            ID      = $_.ID
                            Version = $_.Version
                            Source  = $src
                        }
                    }
                    $ResultsGrid.ItemsSource = $items
                    Write-DebugLog "INFO" ("SearchComplete | Query={0} | Count={1}" -f $script:SearchQueryText,$items.Count)
                    Set-Status "Found $($items.Count) result(s) for '$($script:SearchQueryText)'" "#10B981"
                } else {
                    Write-DebugLog "WARN" ("SearchCompleteNoResults | Query={0}" -f $script:SearchQueryText)
                    Set-Status "No results for '$($script:SearchQueryText)' - try a shorter term or check winget is working" "#F59E0B"
                }
            } catch {
                Write-DebugLog "ERROR" ("SearchTimerError | Query={0} | {1}" -f $script:SearchQueryText,$_.Exception.Message)
                Set-Status "Search error: $($_.Exception.Message)" "#EF4444"
            }
        }
    })
    $script:SearchTimer.Start()
})

$InfoBtn.Add_Click({
    Show-Progress
    $selected = $ResultsGrid.SelectedItem
    if (!$selected) {
        Hide-Progress
        Show-Msg("Select an application from the list first.",
            "No Selection",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null; return
    }
    Set-Status "Fetching package info for $($selected.ID)..." "#3B82F6"
    $winget = Get-WingetPath
    if (!$winget) { Set-Status "winget not found" "#EF4444"; Hide-Progress; return }

    $info = & $winget show --id "$($selected.ID)" --exact --source winget --accept-source-agreements 2>&1 |
        ForEach-Object { ($_ -replace "\x1b\[[0-9;]*[A-Za-z]","" -replace "[^\x20-\x7E]","") }
    $infoText = ($info -join "`n").Trim()
    if ([string]::IsNullOrWhiteSpace($infoText)) { $infoText = "No information returned from winget." }
    Hide-Progress

    Set-Status "Package info loaded: $($selected.Name)" "#6B7280"

    # -- Info popup window --
    $iw = New-Object System.Windows.Window
    $iw.Title                  = "Package Info"
    $iw.Width                  = 680
    $iw.Height                 = 520
    $iw.WindowStartupLocation  = "CenterOwner"
    $iw.Owner                  = $Window
    $iw.WindowStyle            = "None"
    $iw.AllowsTransparency     = $true
    $iw.Background             = "Transparent"
    $iw.ResizeMode             = "CanResizeWithGrip"

    $script:InfoWindow = $iw

    $outerBorder             = New-Object System.Windows.Controls.Border
    $outerBorder.Background  = "#0F1923"
    $outerBorder.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $outerBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
    $outerBorder.BorderThickness = [System.Windows.Thickness]::new(1)

    $rootGrid = New-Object System.Windows.Controls.Grid
    $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = "42"
    $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = "*"
    $rootGrid.RowDefinitions.Add($r0); $rootGrid.RowDefinitions.Add($r1)

    # Title bar
    $tb = New-Object System.Windows.Controls.Border
    $tb.Background  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0A1118"); $tb.CornerRadius = [System.Windows.CornerRadius]::new(10,10,0,0)
    $tbGrid = New-Object System.Windows.Controls.Grid
    $tc0 = New-Object System.Windows.Controls.ColumnDefinition
    $tc1 = New-Object System.Windows.Controls.ColumnDefinition; $tc1.Width = [System.Windows.GridLength]::new(40)
    $tbGrid.ColumnDefinitions.Add($tc0); $tbGrid.ColumnDefinitions.Add($tc1)
    $tbTitle = New-Object System.Windows.Controls.TextBlock
    $tbTitle.Text = "  Package Info  -  $($selected.Name)"
    $tbTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9CA3AF"); $tbTitle.FontSize = 12; $tbTitle.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetColumn($tbTitle,0)
    $tbGrid.Children.Add($tbTitle) | Out-Null

    $closeInfoBtn = New-Object System.Windows.Controls.Button
    $closeInfoBtn.Background   = "Transparent"
    $closeInfoBtn.BorderThickness = "0"
    $closeInfoBtn.Cursor       = "Hand"
    $closeInfoBtn.Width        = 40
    $closeX = New-Object System.Windows.Controls.TextBlock
    $closeX.Text = [char]0xE8BB; $closeX.FontFamily = "Segoe MDL2 Assets"
    $closeX.FontSize = 10; $closeX.Foreground = "#6B7280"
    $closeX.HorizontalAlignment = "Center"; $closeX.VerticalAlignment = "Center"
    $closeInfoBtn.Content = $closeX
    [System.Windows.Controls.Grid]::SetColumn($closeInfoBtn,1)
    $tbGrid.Children.Add($closeInfoBtn) | Out-Null
    $tb.Child = $tbGrid
    [System.Windows.Controls.Grid]::SetRow($tb,0)
    $rootGrid.Children.Add($tb) | Out-Null

    $script:InfoCloseX   = $closeX
    $script:InfoCloseBtn = $closeInfoBtn

    $script:InfoRedBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
    $closeInfoBtn.Add_MouseEnter({ $script:InfoCloseX.Foreground=[System.Windows.Media.Brushes]::White; $script:InfoCloseBtn.Background=$script:InfoRedBrush })
    $closeInfoBtn.Add_MouseLeave({ $script:InfoCloseX.Foreground="#6B7280"; $script:InfoCloseBtn.Background=[System.Windows.Media.Brushes]::Transparent })
    $closeInfoBtn.Add_Click({ $script:InfoWindow.Close() })
    $tb.Add_MouseLeftButtonDown({ $script:InfoWindow.DragMove() })

    # Content
    $sv = New-Object System.Windows.Controls.ScrollViewer
    $sv.Margin = [System.Windows.Thickness]::new(0); $sv.VerticalScrollBarVisibility = "Auto"
    $sv.HorizontalScrollBarVisibility = "Auto"
    $txtBox = New-Object System.Windows.Controls.TextBox
    $txtBox.Text = $infoText; $txtBox.IsReadOnly = $true
    $txtBox.Background = "Transparent"; $txtBox.BorderThickness = "0"
    $txtBox.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D1D5DB"); $txtBox.FontFamily = "Consolas"; $txtBox.FontSize = 12
    $txtBox.TextWrapping = "Wrap"; $txtBox.Margin = "14,10"
    $sv.Content = $txtBox
    [System.Windows.Controls.Grid]::SetRow($sv,1)
    $rootGrid.Children.Add($sv) | Out-Null

    $outerBorder.Child = $rootGrid
    $iw.Content = $outerBorder
    $iw.ShowDialog() | Out-Null
})

$DownloadBtn.Add_Click({
    Show-Progress
    try {
        $selected = $ResultsGrid.SelectedItem
        if (!$selected) {
            Hide-Progress
            Show-Msg("Select an application from the list first.",
                "No Selection",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null; return
        }
        if ([string]::IsNullOrWhiteSpace($selected.ID) -or $selected.ID -eq "N/A") {
            Hide-Progress
            Show-Msg("Invalid package ID. Select a different result.",
                "Invalid Package",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
        }
        $ctx = Get-PackageContext $selected
        $safeName    = Get-SafeName $selected.Name
        $packageRoot = $ctx.PackageRoot
        $filesFolder = $ctx.FilesFolder
        Show-LiveOutput
        Append-LiveOutput "Download requested: $($selected.Name) [$($selected.ID)]"
        Append-LiveOutput "Checking PSADT module..."
        Append-LiveOutput "Resolving package version..."
        Write-DebugLog "INFO" ("DownloadClick | App={0} | Id={1} | SafeName={2}" -f $selected.Name,$selected.ID,$safeName)
        $resolvedVersion = Resolve-WingetPackageVersion -PackageId $selected.ID -GridVersion $selected.Version
        $Global:SelectedAppName = $selected.Name
        $Global:SelectedVersion = $resolvedVersion
        Append-LiveOutput "Resolved version: $resolvedVersion"
        if ($ctx -and $ctx.HasInstaller) {
            $Global:SelectedPackage = $ctx.PackageRoot
            Append-LiveOutput "Existing package detected: $($ctx.PackageRoot)"
            Append-LiveOutput "Existing installer: $($ctx.Installer.Name)"
            Set-Status "Using existing package for $($selected.Name) (download skipped)" "#10B981"
            Show-Msg(
                "Package already exists.`n`nUsing existing installer:`n$($ctx.Installer.FullName)`n`nDownload skipped.",
                "Existing Package",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
            Hide-Progress
            return
        }
        $winget = Get-WingetPath
        if (!$winget) {
            Hide-Progress
            Show-Msg("winget.exe not found.","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null; return
        }
        if (!(Ensure-PSADTModule)) { Hide-Progress; return }

        Set-Status "Creating PSADT v4 template for '$safeName'... (this can take a while)" "#3B82F6"
        Show-Progress
        Append-LiveOutput "Step 1/3: Preparing PSADT package workspace..."
        Append-LiveOutput "Package root: $packageRoot"
        $expectedDirs = @(
            $packageRoot,
            (Join-Path $packageRoot "Assets"),
            (Join-Path $packageRoot "Config"),
            (Join-Path $packageRoot "Files"),
            (Join-Path $packageRoot "Output"),
            (Join-Path $packageRoot "PSAppDeployToolkit"),
            (Join-Path $packageRoot "PSAppDeployToolkit.Extensions"),
            (Join-Path $packageRoot "Strings"),
            (Join-Path $packageRoot "SupportFiles")
        )
        Append-LiveOutput "Checking PSADT folder structure..."
        foreach ($d in $expectedDirs) {
            if (Test-Path $d) { Append-LiveOutput ("[exists]  {0}" -f $d) }
            else { Append-LiveOutput ("[pending] {0}" -f $d) }
        }
        Append-LiveOutput "Creating PSADT template: $safeName"
        Append-LiveOutput "Running New-ADTTemplate in background host (please wait)..."

        try {
            $tpl = New-PSADTTemplateSafe -Destination $Global:PackageRoot -Name $safeName -Force $true
            if ($tpl) {
                Append-LiveOutput ("Template command exit code: {0}" -f $tpl.ExitCode)
                if ($tpl.Output) { Append-LiveOutput ("Template output: {0}" -f (Get-CleanErrorText $tpl.Output)) }
            }
            if ($tpl.ExitCode -ne 0) {
                $detail = if ([string]::IsNullOrWhiteSpace($tpl.Output)) { "Unknown template creation error. ExitCode=$($tpl.ExitCode)" } else { Get-CleanErrorText $tpl.Output }
                throw $detail
            }
            Append-LiveOutput "Verifying created PSADT folders..."
            foreach ($d in $expectedDirs) {
                if (Test-Path $d) { Append-LiveOutput ("[ready]   {0}" -f $d) }
                else { Append-LiveOutput ("[missing] {0}" -f $d) }
            }
            Write-DebugLog "INFO" ("TemplateReady | PackageRoot={0}" -f $packageRoot)
            Set-Status "Template created. Starting download..." "#3B82F6"
            Append-LiveOutput "Step 2/3: Template ready."
            Append-LiveOutput "Template ready: $packageRoot"
        } catch {
            Write-DebugLog "ERROR" ("TemplateCreateFailed | App={0} | {1}" -f $selected.Name,$_.Exception.Message)
            Append-LiveOutput "Template creation failed: $($_.Exception.Message)"
            Hide-Progress
            Set-Status "Template creation failed: $($_.Exception.Message)" "#EF4444"
            Show-Msg("Failed to create PSADT template:`n`n$($_.Exception.Message)",
                "Template Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
            return
        }

        if (!(Test-Path $filesFolder)) { New-Item -ItemType Directory -Path $filesFolder -Force | Out-Null }

        # Capture into script scope for timer closure
        $script:DL_AppName     = $selected.Name
        $script:DL_SafeName    = $safeName
        $script:DL_PackageRoot = $packageRoot
        $script:DL_FilesFolder = $filesFolder
        $script:DL_OutFile     = Join-Path $env:TEMP "psadt_dl_$([System.IO.Path]::GetRandomFileName()).txt"
        $script:DL_ErrFile     = Join-Path $env:TEMP "psadt_dl_$([System.IO.Path]::GetRandomFileName()).err.txt"
        $script:DL_LastLine    = 0
        $script:DL_LastErrLine = 0
        $script:DL_HasOutput   = $false
        $pkgId                 = $selected.ID.Trim()
        $script:DL_PkgId       = $pkgId

        # Stop any prior download timer/process to avoid overlap.
        try {
            if ($script:DownloadTimer) { $script:DownloadTimer.Stop() }
            if ($script:CurrentDownloadProcess -and !$script:CurrentDownloadProcess.HasExited) {
                $script:CurrentDownloadProcess.Kill()
            }
        } catch {}

        # Launch winget directly; avoid cmd.exe indirection which can break app aliases/quoting.
        $dlArgs = "download --id `"$pkgId`" --exact --source winget --download-directory `"$filesFolder`" --accept-package-agreements --accept-source-agreements --disable-interactivity"
        $script:CurrentDownloadProcess = Start-Process -FilePath $winget -ArgumentList $dlArgs -PassThru -WindowStyle Hidden -RedirectStandardOutput $script:DL_OutFile -RedirectStandardError $script:DL_ErrFile
        $Global:CurrentProcess = $script:CurrentDownloadProcess
        Write-DebugLog "INFO" ("WingetDownloadStart | Id={0} | Pid={1} | FilesFolder={2}" -f $pkgId,$script:CurrentDownloadProcess.Id,$filesFolder)
        Append-LiveOutput "Starting winget download..."
        Append-LiveOutput ">> $winget $dlArgs"
        Append-LiveOutput "PID: $($script:CurrentDownloadProcess.Id)"
        Set-Status "Downloading $($selected.Name)..." "#3B82F6"

        $script:DownloadTimer          = New-Object System.Windows.Threading.DispatcherTimer
        $script:DownloadTimer.Interval = [TimeSpan]::FromMilliseconds(500)
        $script:DownloadTimer.Add_Tick({
            if (Test-Path $script:DL_OutFile) {
                try {
                    $all = [System.IO.File]::ReadAllLines($script:DL_OutFile,[System.Text.Encoding]::UTF8)
                    if ($all.Count -gt $script:DL_LastLine) {
                        $new = $all[$script:DL_LastLine..($all.Count-1)]
                        $script:DL_LastLine = $all.Count
                        foreach ($nl in $new) { Append-LiveOutput $nl; $script:DL_HasOutput = $true }
                    }
                } catch {}
            }
            if (Test-Path $script:DL_ErrFile) {
                try {
                    $errAll = [System.IO.File]::ReadAllLines($script:DL_ErrFile,[System.Text.Encoding]::UTF8)
                    if ($errAll.Count -gt $script:DL_LastErrLine) {
                        $errNew = $errAll[$script:DL_LastErrLine..($errAll.Count-1)]
                        $script:DL_LastErrLine = $errAll.Count
                        foreach ($el in $errNew) { Append-LiveOutput $el; $script:DL_HasOutput = $true }
                    }
                } catch {}
            }
            if ($script:CurrentDownloadProcess -and $script:CurrentDownloadProcess.HasExited) {
                $script:DownloadTimer.Stop()
                Hide-Progress
                try {
                    if (Test-Path $script:DL_OutFile) { Remove-Item $script:DL_OutFile -Force -ErrorAction SilentlyContinue }
                    if (Test-Path $script:DL_ErrFile) { Remove-Item $script:DL_ErrFile -Force -ErrorAction SilentlyContinue }
                } catch {}

                # Some packages write files a moment after process exits; retry briefly.
                $installer = $null
                for ($attempt = 0; $attempt -lt 6 -and !$installer; $attempt++) {
                    if ($attempt -gt 0) { Start-Sleep -Milliseconds 400 }
                    $installer = Find-DownloadedInstaller $script:DL_FilesFolder
                }

                Hide-LiveOutput
                if (!$installer) {
                    $found = Get-ChildItem -Path $script:DL_FilesFolder -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 20
                    if ($found) {
                        $names = ($found | ForEach-Object { $_.FullName }) -join " ; "
                        Write-DebugLog "WARN" ("WingetDownloadNoInstallerFilesPresent | Id={0} | Files={1}" -f $script:DL_PkgId,$names)
                    }
                    if (Test-Path $script:DL_OutFile) {
                        try {
                            $tail = Get-Content -LiteralPath $script:DL_OutFile -Tail 20 -ErrorAction SilentlyContinue
                            if ($tail) { Write-DebugLog "WARN" ("WingetDownloadOutputTail | Id={0} | Tail={1}" -f $script:DL_PkgId,($tail -join " | ")) }
                        } catch {}
                    }
                    if (Test-Path $script:DL_ErrFile) {
                        try {
                            $errTail = Get-Content -LiteralPath $script:DL_ErrFile -Tail 20 -ErrorAction SilentlyContinue
                            if ($errTail) { Write-DebugLog "WARN" ("WingetDownloadErrorTail | Id={0} | Tail={1}" -f $script:DL_PkgId,($errTail -join " | ")) }
                        } catch {}
                    }
                    Write-DebugLog "WARN" ("WingetDownloadNoInstaller | Id={0} | FilesFolder={1}" -f $script:DL_PkgId,$script:DL_FilesFolder)
                    Set-Status "Download finished - no installer found in Files folder" "#EF4444"
                    Show-Msg(
                        "winget exited but no installer was found in:`n$($script:DL_FilesFolder)`n`nThis package may not support direct download.`nPlace the installer manually in the Files folder.",
                        "Download Issue",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
                    return
                }
                $Global:SelectedPackage = $script:DL_PackageRoot
                $Global:SelectedAppName = $script:DL_AppName
                Write-DebugLog "INFO" ("WingetDownloadComplete | Installer={0} | PackageRoot={1}" -f $installer.Name,$script:DL_PackageRoot)
                Set-Status "Downloaded: $($installer.Name)  |  Ready to Configure" "#10B981"
                Show-Msg(
                    "Download complete!`n`nApp       : $($script:DL_AppName)`nInstaller : $($installer.Name)`nSaved to  : $($script:DL_FilesFolder)`n`nClick Configure to set up the PSADT script.",
                    "Download Complete",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
            }
        })
        $script:DownloadTimer.Start()
    } catch {
        Write-DebugLog "ERROR" ("DownloadUnhandledException | {0}" -f $_.Exception.Message)
        Hide-Progress
        Hide-LiveOutput
        Set-Status "Download failed: $($_.Exception.Message)" "#EF4444"
        Show-Msg(
            "Download failed with an unexpected error:`n`n$($_.Exception.Message)",
            "Download Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
})

$Global:PSADTFunctions = [ordered]@{
    "Process Execution" = [ordered]@{
        "Execute-ADTProcess" = @{ Desc = "Run an EXE or any executable"; Params = [ordered]@{} }
        "Start-ADTProcess"   = @{ Desc = "Start a process"; Params = [ordered]@{} }
    }
    "User Interface" = [ordered]@{
        "Show-ADTInstallationWelcome"   = @{ Desc = "Show welcome dialog"; Params = [ordered]@{} }
        "Show-ADTInstallationProgress"  = @{ Desc = "Show progress dialog"; Params = [ordered]@{} }
        "Close-ADTInstallationProgress" = @{ Desc = "Close progress dialog"; Params = [ordered]@{} }
    }
    "Registry" = [ordered]@{
        "Set-ADTRegistryKey" = @{ Desc = "Set registry"; Params = [ordered]@{} }
        "Get-ADTRegistryKey" = @{ Desc = "Get registry"; Params = [ordered]@{} }
    }
    "File System" = [ordered]@{
        "Copy-ADTFile" = @{ Desc = "Copy file"; Params = [ordered]@{} }
        "New-ADTFolder" = @{ Desc = "Create folder"; Params = [ordered]@{} }
    }
    "Logging" = [ordered]@{
        "Write-ADTLogEntry" = @{ Desc = "Write log entry"; Params = [ordered]@{} }
    }
}

function Get-ADTCategoryFromCommandName([string]$Name) {
    switch -Regex ($Name) {
        # MSI / MSP / MST
        "^Start-ADTMsiProcess|^Start-ADTMspProcess|Msi|Msp|Mst|Transform" { return "MSI / MSP / MST" }

        # Process Execution
        "^Start-ADTProcess|^Invoke-ADT|RegSvr32|SCCMTask" { return "Process Execution" }

        # User Interface
        "^Show-ADT|Close-ADTInstallationProgress|Block-ADTAppExecution|Unblock-ADTAppExecution|Send-ADTKeys" { return "User Interface" }

        # Registry
        "Registry" { return "Registry" }

        # File System
        "File|Folder|Zip|Content|Wim" { return "File System" }

        # Shortcuts
        "Shortcut" { return "Shortcuts" }

        # Services
        "Service" { return "Services" }

        # User Context
        "User|ActiveSetup|Profile|Session" { return "User Context / Profiles" }

        # Environment / System
        "Environment|OperatingSystem|PendingReboot|Battery|Network|Desktop|GroupPolicy|PowerShellProcessPath|Oobe" { return "Environment / System" }

        # Configuration
        "Ini|Config|Defer|StringTable" { return "Configuration / INI" }

        # Logging
        "Log|ErrorRecord|ValidateScriptErrorRecord" { return "Logging" }

        # Security / Permissions
        "Permission|SID|NTAccount" { return "Security / Permissions" }

        # Application Management
        "Application|MSUpdates|SCCM" { return "Application Detection / Management" }

        # Browser Extensions
        "Edge" { return "Browser Extensions" }

        # Core Toolkit Engine
        "^Initialize-|^Complete-|ModuleCallback|CommandTable|BoundParameters|FunctionErrorHandler|PowerShellEncodedCommand|TerminalServerInstallMode" { return "Core Toolkit Engine" }
    }
    return "Core Toolkit Engine"
}

function Get-PSADTDiscoveredLibrary {
    $discoveryCmd = @"
`$ErrorActionPreference = 'SilentlyContinue'
try { Import-Module PSAppDeployToolkit -ErrorAction SilentlyContinue } catch {}
`$commands = Get-Command -Module PSAppDeployToolkit -ErrorAction SilentlyContinue |
    Where-Object { `$_.CommandType -in @('Function','Cmdlet') } |
    Where-Object { `$_.Name -match '^[A-Za-z]+-ADT' } |
    Sort-Object Name -Unique

`$rows = foreach (`$c in `$commands) {
    `$plist = foreach (`$p in (`$c.Parameters.Values | Sort-Object Position, Name)) {
        if (`$p.Name -in @('Verbose','Debug','ErrorAction','WarningAction','InformationAction','ErrorVariable','WarningVariable','InformationVariable','OutVariable','OutBuffer','PipelineVariable','WhatIf','Confirm')) { continue }
        `$mandatory = `$false
        `$positions = @()
        foreach (`$a in `$p.Attributes) {
            if (`$a -is [System.Management.Automation.ParameterAttribute]) {
                if (`$a.Mandatory) { `$mandatory = `$true }
                if (`$a.Position -ge 0) { `$positions += [int]`$a.Position }
            }
        }
        `$typeName = if (`$p.ParameterType) { `$p.ParameterType.Name } else { 'Object' }
        `$isSwitch = (`$p.ParameterType -and `$p.ParameterType.FullName -eq 'System.Management.Automation.SwitchParameter')
        `$isEnum = `$false
        `$opts = @()
        if (`$p.ParameterType) {
            try { `$isEnum = `$p.ParameterType.IsEnum } catch {}
            if (`$isEnum) {
                try { `$opts = [Enum]::GetNames(`$p.ParameterType) } catch {}
            }
        }
        [PSCustomObject]@{
            Name      = `$p.Name
            TypeName  = `$typeName
            Required  = `$mandatory
            Position  = if (`$positions.Count -gt 0) { (`$positions | Measure-Object -Minimum).Minimum } else { 'Named' }
            IsSwitch  = `$isSwitch
            IsEnum    = `$isEnum
            Options   = @(`$opts)
        }
    }
    [PSCustomObject]@{ Name = `$c.Name; Parameters = @(`$plist) }
}
`$rows | ConvertTo-Json -Depth 8 -Compress
"@

    $res = Invoke-WindowsPowerShellCommand $discoveryCmd
    $json = if ($res.StdOut) { $res.StdOut.Trim() } else { "" }
    if ([string]::IsNullOrWhiteSpace($json)) {
        Write-DebugLog "WARN" ("PSADTDiscoveryEmptyStdOut | ExitCode={0} | Err={1}" -f $res.ExitCode,$res.StdErr)
        return $null
    }

    try {
        $rows = @((ConvertFrom-Json $json))
    } catch {
        Write-DebugLog "WARN" ("PSADTDiscoveryJsonParseFailed | {0}" -f $_.Exception.Message)
        return $null
    }

    if (!$rows -or $rows.Count -eq 0) { return $null }

    $library = [ordered]@{}
    $seenFunctions = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($cmd in $rows) {
        $cmdName = [string]$cmd.Name
        if ([string]::IsNullOrWhiteSpace($cmdName)) { continue }
        if (!$seenFunctions.Add($cmdName)) { continue }
        $cat = Get-ADTCategoryFromCommandName $cmdName
        if (!$library.Contains($cat)) { $library[$cat] = [ordered]@{} }

        $params = [ordered]@{}
        foreach ($p in @($cmd.Parameters)) {
            if (!$p) { continue }
            $pName = "-$($p.Name)"
            if ($params.Contains($pName)) { continue }
            $req = [bool]$p.Required
            $typeName = if ($p.TypeName) { [string]$p.TypeName } else { "Object" }
            $posText = if ($p.Position -ne $null -and $p.Position -ne "") { [string]$p.Position } else { "Named" }
            $isSwitch = [bool]$p.IsSwitch
            $isEnum = [bool]$p.IsEnum
            $opts = @($p.Options)

            $def = [ordered]@{
                Label      = "$($p.Name) [$typeName | $(if($req){'Required'}else{'Optional'}) | Pos:$posText]"
                Type       = if ($isSwitch) { "switch" } elseif ($isEnum -and $opts.Count -gt 0) { "combo" } else { "text" }
                Default    = if ($isSwitch) { $false } else { "" }
                Required   = $req
                ParamType  = $typeName
                Position   = $posText
            }
            if ($isEnum -and $opts.Count -gt 0) {
                $def["Options"] = $opts
                $def["Default"] = $opts[0]
            }
            $params[$pName] = $def
        }

        $library[$cat][$cmdName] = @{
            Desc   = "Discovered from module metadata"
            Params = $params
        }
    }

    # Stable category ordering.
    $catOrder = @(
        "Process Execution","MSI / MSP / MST",
        "User Interface","Registry","File System","Shortcuts","Services","User Context / Profiles",
        "Environment / System","Configuration / INI","Logging","Security / Permissions",
        "Application Detection / Management","Browser Extensions","Core Toolkit Engine"
    )
    $orderedLibrary = [ordered]@{}
    foreach ($c in $catOrder) {
        if ($library.Contains($c)) { $orderedLibrary[$c] = $library[$c] }
    }
    foreach ($c in ($library.Keys | Sort-Object)) {
        if (!$orderedLibrary.Contains($c)) { $orderedLibrary[$c] = $library[$c] }
    }
    return $orderedLibrary
}

function Refresh-PSADTFunctionLibrary {
    # Cache discovery results for faster Configure startup.
    if ($script:PSADTLibraryLastRefresh -and $Global:PSADTFunctions -and $Global:PSADTFunctions.Keys.Count -gt 0) {
        $age = (New-TimeSpan -Start $script:PSADTLibraryLastRefresh -End (Get-Date)).TotalSeconds
        if ($age -lt 600) {
            Write-DebugLog "INFO" ("PSADTFunctionLibraryCacheHit | AgeSec={0:N0}" -f $age)
            return $true
        }
    }
    try {
        $discovered = Get-PSADTDiscoveredLibrary
        if ($discovered -and $discovered.Keys.Count -gt 0) {
            $Global:PSADTFunctions = $discovered
            $script:PSADTLibraryLastRefresh = Get-Date
            $fnCount = ($discovered.Values | ForEach-Object { $_.Keys.Count } | Measure-Object -Sum).Sum
            Write-DebugLog "INFO" ("PSADTFunctionLibraryRefreshed | Categories={0} | Functions={1}" -f $discovered.Keys.Count,$fnCount)
            return $true
        }
    } catch {
        Write-DebugLog "WARN" ("PSADTFunctionLibraryRefreshFailed | {0}" -f $_.Exception.Message)
    }
    return $false
}

$ConfigureBtn.Add_Click({
    # Stop any active operation timers that might hide the global progress bar.
    try { if ($script:DownloadTimer) { $script:DownloadTimer.Stop() } } catch {}
    try { if ($script:GenerateTimer) { $script:GenerateTimer.Stop() } } catch {}
    try { if ($script:GenTimer) { $script:GenTimer.Stop() } } catch {}
    try { if ($script:UploadTimer) { $script:UploadTimer.Stop() } } catch {}
    $cfgSw = [System.Diagnostics.Stopwatch]::StartNew()
    # Configure uses the main app progress bar only.
    Hide-LiveOutput
    Show-Progress
    # Temporarily move the same global progress bar just under status during Configure load.
    try {
        $script:CFG_ProgressHost = [System.Windows.Media.VisualTreeHelper]::GetParent($MainProgressBar)
        if ($script:CFG_ProgressHost -is [System.Windows.Controls.Border]) {
            $script:CFG_ProgressHostOldRow = [System.Windows.Controls.Grid]::GetRow($script:CFG_ProgressHost)
            $script:CFG_ProgressHostOldMargin = $script:CFG_ProgressHost.Margin
            $script:CFG_ProgressHostOldVA = $script:CFG_ProgressHost.VerticalAlignment
            [System.Windows.Controls.Grid]::SetRow($script:CFG_ProgressHost, 3)
            $script:CFG_ProgressHost.Margin = [System.Windows.Thickness]::new(14,2,14,0)
            $script:CFG_ProgressHost.VerticalAlignment = [System.Windows.VerticalAlignment]::Bottom
        }
    } catch {}
    # Hard-enforce same global progress bar visibility/style used across app.
    try {
        $MainProgressBar.Height = 5
        $MainProgressBar.Opacity = 1
        $MainProgressBar.IsIndeterminate = $true
        $MainProgressBar.Visibility = "Visible"
        $MainProgressBar.UpdateLayout()
    } catch {}
    $script:CFG_ProgressPulse = New-Object System.Windows.Threading.DispatcherTimer
    $script:CFG_ProgressPulse.Interval = [TimeSpan]::FromMilliseconds(120)
    $script:CFG_ProgressPulse.Add_Tick({
        try { $MainProgressBar.IsIndeterminate = $true; $MainProgressBar.Visibility = "Visible" } catch {}
    })
    $script:CFG_ProgressPulse.Start()
    Flush-UI
    Set-Status "Preparing Configure panel..." "#3B82F6"
    # Let WPF render at least a few frames so indeterminate animation is visible
    # before first-run metadata discovery blocks the UI thread.
    try {
        $renderWait = [System.Diagnostics.Stopwatch]::StartNew()
        while ($renderWait.ElapsedMilliseconds -lt 900) {
            $null = $Window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
            Start-Sleep -Milliseconds 30
        }
    } catch {}
    try {
        $currentFnCount = 0
        try { if ($Global:PSADTFunctions) { $currentFnCount = ($Global:PSADTFunctions.Values | ForEach-Object { $_.Keys.Count } | Measure-Object -Sum).Sum } } catch {}
        $fnLibReady = ($currentFnCount -ge 100)
        if (-not $fnLibReady) {
            Set-Status "Loading PSADT function metadata (first run)..." "#3B82F6"
            $null = Refresh-PSADTFunctionLibrary
        }

        $selected = $ResultsGrid.SelectedItem
        $ctx = Get-PackageContext $selected
        if (!$ctx) {
            Show-Msg("Download a package first, then click Configure.",
                "No Package",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
        }

        # Derive package paths
        $packageRoot = $ctx.PackageRoot
        $appName     = $ctx.AppName
        $filesFolder = $ctx.FilesFolder
        $scriptPath  = $ctx.ScriptPath
        Write-DebugLog "INFO" ("ConfigureClick | PackageRoot={0}" -f $packageRoot)

        if (!$ctx.HasFiles) {
            Show-Msg("Files folder not found. Download first.","Not Downloaded",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
        }

        $installer = $ctx.Installer

        if (!$installer) {
            Show-Msg("No installer found in Files folder. Download first.",
                "No Installer",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
        }

        # Auto-inject into template if script exists but markers not yet populated
        if (!(Test-Path $scriptPath)) {
            try {
                $tpl2 = New-PSADTTemplateSafe -Destination $Global:PackageRoot -Name (Split-Path $packageRoot -Leaf) -Force $true
                if ($tpl2.ExitCode -ne 0) {
                    $detail2 = if ([string]::IsNullOrWhiteSpace($tpl2.Output)) { "Unknown template creation error. ExitCode=$($tpl2.ExitCode)" } else { Get-CleanErrorText $tpl2.Output }
                    throw $detail2
                }
                Write-DebugLog "INFO" ("ConfigureTemplateCreated | ScriptPath={0}" -f $scriptPath)
            } catch {
                Write-DebugLog "ERROR" ("ConfigureTemplateCreateFailed | {0}" -f $_.Exception.Message)
                Show-Msg("Could not create PSADT template:`n$($_.Exception.Message)","Error",
                    [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null; return
            }
        }

    # Inject boilerplate into existing template placeholders if not done yet
        if (Test-Path $scriptPath) {
        $content = [System.IO.File]::ReadAllText($scriptPath,[System.Text.Encoding]::UTF8)
        $alreadySeeded = $content -match 'WinGet-PSADT GUI Tool:BEGIN-AUTO'
        $silentArgs = switch ($installer.Extension.ToLower()) {
            ".msi" { "/qn /norestart" }; default { "/S" }
        }
        $installerName = $installer.Name

        $installLines = @(
            "    # WinGet-PSADT GUI Tool:BEGIN-AUTO Install",
            "    Show-ADTInstallationProgress",
            "    `$Exe = `"`$(`$adtSession.DirFiles)\$installerName`"",
            "    Start-ADTProcess ``",
            "        -FilePath `$Exe ``",
            "        -ArgumentList `"$silentArgs`" ``",
            "        -WaitForChildProcess",
            "    Write-ADTLogEntry -Message `"Installation of $appName completed.`" -Severity 1",
            "    # WinGet-PSADT GUI Tool:END-AUTO Install"
        )
        $uninstallLines = @(
            "    # WinGet-PSADT GUI Tool:BEGIN-AUTO Uninstall",
            "    ## MSI: Uninstall-ADTApplication ``",
            "    ##     -Name '$appName' ``",
            "    ##     -ApplicationType 'MSI' ``",
            "    ##     -FilterScript {`$_.DisplayName -match ('^' + [regex]::Escape(`$adtSession.AppName) + '(?:\s|$)')} ``",
            "    Show-ADTInstallationProgress",
            "    Uninstall-ADTApplication ``",
            "        -FilterScript {`$_.DisplayName -match ('^' + [regex]::Escape(`$adtSession.AppName) + '(?:\s|$)')} ``",
            "        -Verbose ``",
            "        -ApplicationType 'EXE' ``",
            "        -ArgumentList '/uninstall $silentArgs'",
            "    Write-ADTLogEntry -Message `"Uninstall of $appName completed.`" -Severity 1",
            "    # WinGet-PSADT GUI Tool:END-AUTO Uninstall"
        )
        $repairLines = @(
            "    # WinGet-PSADT GUI Tool:BEGIN-AUTO Repair",
            "    Show-ADTInstallationProgress",
            "    `$Exe = `"`$(`$adtSession.DirFiles)\$installerName`"",
            "    Start-ADTProcess ``",
            "        -FilePath `$Exe ``",
            "        -ArgumentList `"$silentArgs`" ``",
            "        -WaitForChildProcess",
            "    Write-ADTLogEntry -Message `"Repair of $appName completed.`" -Severity 1",
            "    # WinGet-PSADT GUI Tool:END-AUTO Repair"
        )

        $markers = @{
            "## <Perform Installation tasks here>"   = $installLines
            "## <Perform Uninstallation tasks here>" = $uninstallLines
            "## <Perform Repair tasks here>"         = $repairLines
        }

        if (!$alreadySeeded) {
            $lines   = [System.IO.File]::ReadAllLines($scriptPath,[System.Text.Encoding]::UTF8)
            $out     = [System.Collections.Generic.List[string]]::new()
            $injected= @{}

            foreach ($line in $lines) {
                $out.Add($line)
                foreach ($m in $markers.Keys) {
                    if (!$injected[$m] -and $line.Trim() -eq $m) {
                        foreach ($il in $markers[$m]) { $out.Add($il) }
                        $injected[$m] = $true
                    }
                }
            }
            [System.IO.File]::WriteAllLines($scriptPath,$out,[System.Text.Encoding]::UTF8)
            Write-DebugLog "INFO" ("ConfigureInjectedDefaultBlocks | ScriptPath={0}" -f $scriptPath)
        }
        Normalize-PSADTTemplateSections -ScriptPath $scriptPath
        $Global:SelectedPackage = $packageRoot
        $vendorGuess = if ($selected -and $selected.ID) { Get-VendorFromPackageId $selected.ID } else { "" }
        Ensure-AppDetailsDefaultsInScript -ScriptPath $scriptPath -AppName $appName -Version $Global:SelectedVersion -Vendor $vendorGuess -PackageRoot $packageRoot -FilesFolder $filesFolder
        Save-SAIWParamsToScript -ScriptPath $scriptPath -Params (Get-SAIWParamsFromScript -ScriptPath $scriptPath)
        Set-Status "Template configured for $appName  |  Use the Configure window to add more functions" "#10B981"
    }

    # -- Build Configure window --
    $cw = New-Object System.Windows.Window
    $cw.Title               = "Configure Package"
    $cw.Width               = 960
    $cw.Height              = 680
    $cw.MinWidth            = 780
    $cw.MinHeight           = 500
    $cw.WindowStartupLocation = "CenterOwner"
    $cw.Owner               = $Window
    $cw.WindowStyle         = "None"
    $cw.AllowsTransparency  = $true
    $cw.Background          = "Transparent"
    $cw.ResizeMode          = "CanResizeWithGrip"
    $script:ConfigWindow    = $cw

    [xml]$cwXAML = @"
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Background="#0F1923" CornerRadius="12" BorderBrush="#2D3F55" BorderThickness="1">
  <Border.Resources>
    <SolidColorBrush x:Key="{x:Static SystemColors.WindowBrushKey}" Color="#1A2332"/>
    <SolidColorBrush x:Key="{x:Static SystemColors.ControlBrushKey}" Color="#1A2332"/>
    <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#1E3A8A"/>
    <SolidColorBrush x:Key="{x:Static SystemColors.ControlTextBrushKey}" Color="#D1D5DB"/>
    <Style TargetType="DataGridColumnHeader">
      <Setter Property="Background" Value="#111827"/>
      <Setter Property="Foreground" Value="#9CA3AF"/>
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Padding" Value="8,6"/>
      <Setter Property="BorderBrush" Value="#374151"/>
      <Setter Property="BorderThickness" Value="0,0,0,1"/>
      <Setter Property="HorizontalContentAlignment" Value="Center"/>
    </Style>
    <Style TargetType="DataGridCell">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#D1D5DB"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="FocusVisualStyle" Value="{x:Null}"/>
    </Style>
    <Style TargetType="DataGridRow">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#D1D5DB"/>
      <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#1E3A8A"/>
          <Setter Property="Foreground" Value="White"/>
        </Trigger>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#1F2D3D"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <Style x:Key="DarkScrollThumb" TargetType="Thumb">
      <Setter Property="Background" Value="#334155"/>
      <Setter Property="BorderBrush" Value="#475569"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Thumb">
            <Border Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="3"/>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="DarkScrollBarButton" TargetType="RepeatButton">
      <Setter Property="Background" Value="#0B1624"/>
      <Setter Property="BorderBrush" Value="#1F2D3D"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RepeatButton">
            <Border Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="2"/>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ScrollBar">
      <Setter Property="Background" Value="#0B1624"/>
      <Setter Property="Width" Value="10"/>
      <Setter Property="Height" Value="10"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Grid Background="{TemplateBinding Background}">
              <Track Name="PART_Track" IsDirectionReversed="True">
                <Track.DecreaseRepeatButton>
                  <RepeatButton Style="{StaticResource DarkScrollBarButton}" Command="ScrollBar.PageUpCommand"/>
                </Track.DecreaseRepeatButton>
                <Track.Thumb>
                  <Thumb Style="{StaticResource DarkScrollThumb}"/>
                </Track.Thumb>
                <Track.IncreaseRepeatButton>
                  <RepeatButton Style="{StaticResource DarkScrollBarButton}" Command="ScrollBar.PageDownCommand"/>
                </Track.IncreaseRepeatButton>
              </Track>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="Orientation" Value="Horizontal">
                <Setter TargetName="PART_Track" Property="IsDirectionReversed" Value="False"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ComboBox">
      <Setter Property="Background" Value="#1A2332"/>
      <Setter Property="Foreground" Value="#F9FAFB"/>
      <Setter Property="BorderBrush" Value="#2D3F55"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="6,2,6,2"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBox">
            <Grid>
              <Border x:Name="Bd"
                      Background="{TemplateBinding Background}"
                      BorderBrush="{TemplateBinding BorderBrush}"
                      BorderThickness="{TemplateBinding BorderThickness}"
                      CornerRadius="2"/>
              <Grid Margin="2">
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="*"/>
                  <ColumnDefinition Width="26"/>
                </Grid.ColumnDefinitions>
                <ContentPresenter x:Name="ContentSite"
                                  Grid.Column="0"
                                  Margin="4,0,24,0"
                                  VerticalAlignment="Center"
                                  HorizontalAlignment="Left"
                                  RecognizesAccessKey="True"
                                  Content="{TemplateBinding SelectionBoxItem}"
                                  ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"/>
                <ToggleButton x:Name="ToggleButton"
                              Grid.ColumnSpan="2"
                              Focusable="False"
                              IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                              Background="Transparent"
                              BorderBrush="Transparent"
                              BorderThickness="0">
                  <Path HorizontalAlignment="Right"
                        VerticalAlignment="Center"
                        Margin="0,0,10,0"
                        Stretch="None"
                        SnapsToDevicePixels="True"
                        Fill="#9CA3AF"
                        Data="M 0 0 L 4 4 L 8 0 Z"/>
                </ToggleButton>
              </Grid>
              <Popup Name="PART_Popup"
                     Placement="Bottom"
                     IsOpen="{TemplateBinding IsDropDownOpen}"
                     AllowsTransparency="True"
                     Focusable="False"
                     PopupAnimation="Fade">
                <Border Background="#1A2332"
                        MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}"
                        BorderBrush="#2D3F55"
                        BorderThickness="1"
                        CornerRadius="2"
                        SnapsToDevicePixels="True">
                  <ScrollViewer Margin="0" SnapsToDevicePixels="True" CanContentScroll="True" HorizontalScrollBarVisibility="Auto">
                    <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                  </ScrollViewer>
                </Border>
              </Popup>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="BorderBrush" Value="#3B82F6"/>
              </Trigger>
              <Trigger Property="IsKeyboardFocusWithin" Value="True">
                <Setter TargetName="Bd" Property="BorderBrush" Value="#38BDF8"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Foreground" Value="#6B7280"/>
                <Setter TargetName="Bd" Property="Opacity" Value="0.8"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ComboBoxItem">
      <Setter Property="Background" Value="#1A2332"/>
      <Setter Property="Foreground" Value="#D1D5DB"/>
      <Setter Property="Padding" Value="8,6"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#2D3F55"/>
          <Setter Property="Foreground" Value="White"/>
        </Trigger>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#1E3A8A"/>
          <Setter Property="Foreground" Value="White"/>
        </Trigger>
      </Style.Triggers>
    </Style>
  </Border.Resources>
  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="42"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="52"/>
    </Grid.RowDefinitions>

    <!-- Title bar -->
    <Border Grid.Row="0" Background="#0A1118" CornerRadius="12,12,0,0" Name="CW_TitleBar">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition/>
          <ColumnDefinition Width="46"/>
        </Grid.ColumnDefinitions>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="14,0">
          <TextBlock Text="&#xE713;" FontFamily="Segoe MDL2 Assets" FontSize="13"
                     Foreground="#7C3AED" VerticalAlignment="Center" Margin="0,0,8,0"/>
          <TextBlock Text="Configure Package" Foreground="#F9FAFB" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center"/>
          <TextBlock Name="CW_AppLabel" Text="" Foreground="#6B7280" FontSize="11" VerticalAlignment="Center" Margin="8,1,0,0"/>
        </StackPanel>
        <Button Name="CW_CloseBtn" Grid.Column="1" Background="Transparent" BorderThickness="0" Cursor="Hand">
          <Button.Template>
            <ControlTemplate TargetType="Button">
              <Border x:Name="bg" Background="Transparent" CornerRadius="0,12,0,0">
                <TextBlock Text="&#xE8BB;" FontFamily="Segoe MDL2 Assets" FontSize="10"
                           Foreground="#6B7280" HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
              <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                  <Setter TargetName="bg" Property="Background" Value="#EF4444"/>
                  <Setter Property="Foreground" Value="White"/>
                </Trigger>
              </ControlTemplate.Triggers>
            </ControlTemplate>
          </Button.Template>
        </Button>
      </Grid>
    </Border>

    <!-- Body: 3-column -->
    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="175"/>
        <ColumnDefinition Width="1"/>
        <ColumnDefinition Width="195"/>
        <ColumnDefinition Width="1"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <!-- Dividers -->
      <Border Grid.Column="1" Background="#2D3F55"/>
      <Border Grid.Column="3" Background="#2D3F55"/>

      <!-- Col 0: Category -->
      <Grid Grid.Column="0">
        <Grid.RowDefinitions>
          <RowDefinition Height="32"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Border Background="#060D14" BorderBrush="#2D3F55" BorderThickness="0,0,0,1" Padding="10,0">
          <TextBlock Text="CATEGORY" Foreground="#4B5563" FontSize="10" FontWeight="Bold" VerticalAlignment="Center"/>
        </Border>
        <ListBox Name="CW_CategoryList" Grid.Row="1" Background="Transparent" BorderThickness="0"
                 ScrollViewer.HorizontalScrollBarVisibility="Disabled">
          <ListBox.ItemContainerStyle>
            <Style TargetType="ListBoxItem">
              <Setter Property="Padding" Value="12,8"/>
              <Setter Property="Foreground" Value="#9CA3AF"/>
              <Setter Property="Background" Value="Transparent"/>
              <Setter Property="Cursor" Value="Hand"/>
              <Setter Property="FontSize" Value="12"/>
              <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                  <Setter Property="Background" Value="#1E3A8A"/>
                  <Setter Property="Foreground" Value="White"/>
                </Trigger>
                <Trigger Property="IsMouseOver" Value="True">
                  <Setter Property="Background" Value="#1F2D3D"/>
                </Trigger>
              </Style.Triggers>
            </Style>
          </ListBox.ItemContainerStyle>
        </ListBox>
      </Grid>

      <!-- Col 2: Function -->
      <Grid Grid.Column="2">
        <Grid.RowDefinitions>
          <RowDefinition Height="32"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Border Background="#060D14" BorderBrush="#2D3F55" BorderThickness="0,0,0,1" Padding="10,0">
          <TextBlock Text="FUNCTION" Foreground="#4B5563" FontSize="10" FontWeight="Bold" VerticalAlignment="Center"/>
        </Border>
        <ListBox Name="CW_FunctionList" Grid.Row="1" Background="Transparent" BorderThickness="0"
                 ScrollViewer.HorizontalScrollBarVisibility="Disabled">
          <ListBox.ItemContainerStyle>
            <Style TargetType="ListBoxItem">
              <Setter Property="Padding" Value="10,7"/>
              <Setter Property="Foreground" Value="#9CA3AF"/>
              <Setter Property="Background" Value="Transparent"/>
              <Setter Property="Cursor" Value="Hand"/>
              <Setter Property="FontFamily" Value="Consolas"/>
              <Setter Property="FontSize" Value="11"/>
              <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                  <Setter Property="Background" Value="#1E3A8A"/>
                  <Setter Property="Foreground" Value="#38BDF8"/>
                </Trigger>
                <Trigger Property="IsMouseOver" Value="True">
                  <Setter Property="Background" Value="#1F2D3D"/>
                </Trigger>
              </Style.Triggers>
            </Style>
          </ListBox.ItemContainerStyle>
        </ListBox>
      </Grid>

      <!-- Col 4: Params + Preview -->
      <Grid Grid.Column="4">
        <Grid.RowDefinitions>
          <RowDefinition Height="32"/>
          <RowDefinition Height="135"/>
          <RowDefinition Height="1"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="1"/>
          <RowDefinition Height="110"/>
        </Grid.RowDefinitions>
        <Border Grid.Row="0" Background="#060D14" BorderBrush="#2D3F55" BorderThickness="0,0,0,1" Padding="12,0">
          <TextBlock Name="CW_FuncTitle" Text="Select a category, then a function"
                     Foreground="#4B5563" FontSize="11" FontWeight="SemiBold" VerticalAlignment="Center"/>
        </Border>
        <!-- Parameter metadata -->
        <Border Grid.Row="1" Background="#0B1624" BorderBrush="#2D3F55" BorderThickness="0,0,0,1" Padding="8,6,8,6">
          <DataGrid Name="CW_ParamGrid"
                    AutoGenerateColumns="False"
                    IsReadOnly="True"
                    HeadersVisibility="Column"
                    CanUserResizeRows="False"
                    CanUserReorderColumns="False"
                    RowHeight="24"
                    FontSize="11"
                    Background="#0B1624"
                    Foreground="#D1D5DB"
                    GridLinesVisibility="Horizontal"
                    HorizontalGridLinesBrush="#1F2D3D"
                    VerticalGridLinesBrush="Transparent"
                    ScrollViewer.VerticalScrollBarVisibility="Auto"
                    ScrollViewer.HorizontalScrollBarVisibility="Disabled">
            <DataGrid.Columns>
              <DataGridTextColumn Header="ParameterName" Binding="{Binding ParameterName}" Width="2*"/>
              <DataGridTextColumn Header="Type"          Binding="{Binding ParameterType}" Width="1.3*"/>
              <DataGridTextColumn Header="Required"      Binding="{Binding Required}"      Width="1*"/>
              <DataGridTextColumn Header="Position"      Binding="{Binding Position}"      Width="1*"/>
            </DataGrid.Columns>
          </DataGrid>
        </Border>
        <Border Grid.Row="2" Background="#2D3F55"/>
        <!-- Param form -->
        <ScrollViewer Grid.Row="3" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Background="#0D1B2A">
          <StackPanel Name="CW_ParamsPanel" Margin="14,10"/>
        </ScrollViewer>
        <!-- Divider -->
        <Border Grid.Row="4" Background="#2D3F55"/>
        <!-- Preview -->
        <Grid Grid.Row="5" Background="#060D14">
          <Grid.RowDefinitions>
            <RowDefinition Height="22"/>
            <RowDefinition Height="*"/>
          </Grid.RowDefinitions>
          <Border Background="#0A1118" Padding="12,3">
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="Command preview" Foreground="#4B5563" FontSize="10" VerticalAlignment="Center"/>
              <TextBlock Text="   (hover param label for flag name)" Foreground="#374151" FontSize="10" VerticalAlignment="Center"/>
            </StackPanel>
          </Border>
          <TextBox Name="CW_PreviewBox" Grid.Row="1"
                   Background="Transparent" BorderThickness="0"
                   Foreground="#38BDF8" FontFamily="Consolas" FontSize="11"
                   IsReadOnly="True" TextWrapping="Wrap" Padding="12,5"
                   VerticalScrollBarVisibility="Auto"
                   Text="# Select a function to preview the command"/>
        </Grid>
      </Grid>
    </Grid>

    <!-- Footer -->
    <Border Grid.Row="2" Background="#0A1118" CornerRadius="0,0,12,12"
            BorderBrush="#2D3F55" BorderThickness="0,1,0,0" Padding="14,0">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="110"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="120"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="120"/>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="110"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="120"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="36"/>
          <ColumnDefinition Width="10"/>
          <ColumnDefinition Width="100"/>
        </Grid.ColumnDefinitions>
        <TextBlock Grid.Column="0" Text="Add to:" Foreground="#6B7280" FontSize="12" VerticalAlignment="Center"/>
        <ComboBox Name="CW_SectionCombo" Grid.Column="2" Height="32" FontSize="12"
                  Background="#1A2332" Foreground="White" BorderBrush="#2D3F55" BorderThickness="1">
          <ComboBoxItem Content="Pre-Install" IsSelected="True"/>
          <ComboBoxItem Content="Install"/>
          <ComboBoxItem Content="Post-Install"/>
          <ComboBoxItem Content="Pre-Uninstall"/>
          <ComboBoxItem Content="Uninstall"/>
          <ComboBoxItem Content="Post-Uninstall"/>
          <ComboBoxItem Content="Pre-Repair"/>
          <ComboBoxItem Content="Repair"/>
          <ComboBoxItem Content="Post-Repair"/>
        </ComboBox>
        <Button Name="CW_AddBtn" Grid.Column="4" Height="32" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#0EA5E9" CornerRadius="6">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE74E;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="White" Margin="0,0,5,0" VerticalAlignment="Center"/>
                <TextBlock Text="Save to Script" Foreground="White" FontSize="12" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#0284C7"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Background" Value="#0369A1"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="CW_DetailsBtn" Grid.Column="6" Height="32" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#7C3AED" CornerRadius="6">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE946;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="White" Margin="0,0,5,0" VerticalAlignment="Center"/>
                <TextBlock Text="App Details" Foreground="White" FontSize="12" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#8B5CF6"/></Trigger>
              <Trigger Property="IsPressed" Value="True"><Setter TargetName="bg" Property="Background" Value="#6D28D9"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="CW_OpenBtn" Grid.Column="8" Height="32" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#374151" CornerRadius="6">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE8A5;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="#D1D5DB" Margin="0,0,5,0" VerticalAlignment="Center"/>
                <TextBlock Text="Open Script" Foreground="#D1D5DB" FontSize="12" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#4B5563"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="CW_RepairBtn" Grid.Column="10" Height="32" BorderThickness="0" Cursor="Hand" ToolTip="Repair script structure">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#0F766E" CornerRadius="6">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE895;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="White" Margin="0,0,5,0" VerticalAlignment="Center"/>
                <TextBlock Text="Repair Script" Foreground="White" FontSize="12" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#0D9488"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="CW_ClearBtn" Grid.Column="12" Height="32" BorderThickness="0" Cursor="Hand" ToolTip="Clear selected section">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#374151" CornerRadius="6">
              <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" FontSize="11"
                         Foreground="#EF4444" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#4B5563"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
        <Button Name="CW_DoneBtn" Grid.Column="14" Height="32" BorderThickness="0" Cursor="Hand">
          <Button.Template><ControlTemplate TargetType="Button">
            <Border x:Name="bg" Background="#065F46" CornerRadius="6">
              <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="&#xE8FB;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="White" Margin="0,0,5,0" VerticalAlignment="Center"/>
                <TextBlock Text="Done" Foreground="White" FontSize="12" FontWeight="SemiBold"/>
              </StackPanel>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#10B981"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate></Button.Template>
        </Button>
      </Grid>
    </Border>
  </Grid>
</Border>
"@

    try {
        $cwReader  = New-Object System.Xml.XmlNodeReader $cwXAML
        $cwContent = [Windows.Markup.XamlReader]::Load($cwReader)
    } catch {
        Show-Msg("Configure window error:`n$($_.Exception.Message)","XAML Error",
            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null; return
    }

    $cw.Content = $cwContent

    # Bind Configure window controls
    $CW_TitleBar     = $cwContent.FindName("CW_TitleBar")
    $CW_CloseBtn     = $cwContent.FindName("CW_CloseBtn")
    $CW_AppLabel     = $cwContent.FindName("CW_AppLabel")
    $CW_CategoryList = $cwContent.FindName("CW_CategoryList")
    $CW_FunctionList = $cwContent.FindName("CW_FunctionList")
    $CW_ParamGrid    = $cwContent.FindName("CW_ParamGrid")
    $CW_ParamsPanel  = $cwContent.FindName("CW_ParamsPanel")
    $CW_FuncTitle    = $cwContent.FindName("CW_FuncTitle")
    $CW_PreviewBox   = $cwContent.FindName("CW_PreviewBox")
    $CW_SectionCombo = $cwContent.FindName("CW_SectionCombo")
    $CW_AddBtn       = $cwContent.FindName("CW_AddBtn")
    $CW_DetailsBtn   = $cwContent.FindName("CW_DetailsBtn")
    $CW_OpenBtn      = $cwContent.FindName("CW_OpenBtn")
    $CW_RepairBtn    = $cwContent.FindName("CW_RepairBtn")
    $CW_ClearBtn     = $cwContent.FindName("CW_ClearBtn")
    $CW_DoneBtn      = $cwContent.FindName("CW_DoneBtn")

    $CW_AppLabel.Text = "  -  $appName  ($($installer.Name))"
    $CW_TitleBar.Add_MouseLeftButtonDown({ $script:ConfigWindow.DragMove() })
    $CW_CloseBtn.Add_Click({ $script:ConfigWindow.Close() })
    $CW_DoneBtn.Add_Click({ $script:ConfigWindow.Close() })

    # Param tracking
    $script:CW_ParamControls = @{}
    $script:CW_CurrentFunc   = $null
    $script:CW_CurrentCat    = $null
    $script:CW_ScriptPath    = $scriptPath
    if (-not $script:CW_ParamStateCache) { $script:CW_ParamStateCache = @{} }
    if (-not $script:CW_FormBaseline) { $script:CW_FormBaseline = @{} }

    # Capture combobox into scope
    $script:CW_SectionCombo = $CW_SectionCombo
    $script:CW_PreviewBox   = $CW_PreviewBox
    $script:CW_ParamGrid    = $CW_ParamGrid
    $script:CW_ParamsPanel  = $CW_ParamsPanel
    $script:CW_FuncTitle    = $CW_FuncTitle
    $script:CW_SectionSwitchGuard = $false
    $script:CW_LastSection = if ($CW_SectionCombo.SelectedItem -is [System.Windows.Controls.ComboBoxItem]) { [string]$CW_SectionCombo.SelectedItem.Content } else { [string]$CW_SectionCombo.SelectedItem }
    Apply-ComboAutoSize -Root $cwContent -MinChars 8

    function CW-GetActiveSection {
        $si = $script:CW_SectionCombo.SelectedItem
        if ($si -is [System.Windows.Controls.ComboBoxItem]) { return [string]$si.Content }
        return [string]$si
    }
    function CW-GetStateKey([string]$Cat,[string]$Fn,[string]$ParamName,[string]$Section = "") {
        $sec = if ([string]::IsNullOrWhiteSpace($Section)) { CW-GetActiveSection } else { $Section }
        if ([string]::IsNullOrWhiteSpace($sec)) { $sec = "Pre-Install" }
        return "$sec|$Cat|$Fn|$ParamName"
    }
    function CW-SaveCurrentState {
        if (!$script:CW_CurrentFunc -or !$script:CW_CurrentCat) { return }
        foreach ($pName in $script:CW_ParamControls.Keys) {
            $ctrl = $script:CW_ParamControls[$pName]
            if (!$ctrl) { continue }
            $k = CW-GetStateKey $script:CW_CurrentCat $script:CW_CurrentFunc $pName
            if ($ctrl -is [System.Windows.Controls.CheckBox]) {
                $script:CW_ParamStateCache[$k] = [bool]($ctrl.IsChecked -eq $true)
            } elseif ($ctrl -is [System.Windows.Controls.ComboBox]) {
                $script:CW_ParamStateCache[$k] = if ($ctrl.SelectedItem) { $ctrl.SelectedItem.ToString() } else { "" }
            } else {
                $script:CW_ParamStateCache[$k] = $ctrl.Text
            }
        }
    }
    function CW-GetParamKeyFromTag($TagValue) {
        if ($TagValue -is [System.Collections.IDictionary]) { return [string]$TagValue["Param"] }
        return [string]$TagValue
    }
    function CW-IsHintActive([System.Windows.Controls.TextBox]$Ctrl) {
        if (!$Ctrl) { return $false }
        if (!($Ctrl.Tag -is [System.Collections.IDictionary])) { return $false }
        $hint = [string]$Ctrl.Tag["Hint"]
        if ([string]::IsNullOrWhiteSpace($hint)) { return $false }
        return ($Ctrl.Text -eq $hint -and $Ctrl.Foreground -eq "#6B7280")
    }
    function CW-GetParamHint([string]$ParamName,$ParamDef) {
        $pt = if ($ParamDef -and $ParamDef.ParamType) { [string]$ParamDef.ParamType } else { "String" }
        switch -Regex ($pt) {
            '^DateTime$'      { return "Ex: (Get-Date).AddDays(3)" }
            '^TimeSpan$'      { return "Ex: '00:30:00'" }
            '^ScriptBlock$'   { return "Ex: { `$_.DisplayName -match 'Contoso' }" }
            '^Guid$'          { return "Ex: '00000000-0000-0000-0000-000000000000'" }
            '^Int(16|32|64)$' { return "Ex: 3" }
            '^Double$'        { return "Ex: 1.5" }
            '^String\[\]$'    { return "Ex: 'value1','value2'" }
            '^Object\[\]$'    { return "Ex: @('value1','value2')" }
            '^String$'        { return "Ex: 'value'" }
            default {
                if ($ParamName -match 'Path') { return "Ex: 'C:\Temp\file.txt'" }
                if ($ParamName -match 'Name') { return "Ex: 'Contoso App'" }
                if ($ParamName -match 'Version') { return "Ex: '1.2.3'" }
                return "Ex: value"
            }
        }
    }

    function CW-BuildPreview {
        function CW-FormatParamValue($pDef, [string]$RawValue) {
            $val = if ($null -eq $RawValue) { "" } else { [string]$RawValue }
            if ([string]::IsNullOrWhiteSpace($val)) { return "" }
            $trim = $val.Trim()
            $paramName = if ($pDef -and $pDef.Name) { [string]$pDef.Name } else { "" }
            $forceQuoteNames = @('StatusMessage','StatusMessageDetail','Title','Subtitle','Message')
            if ($forceQuoteNames -contains $paramName) {
                if ($trim -match '^''.*''$|^".*"$') { return $trim }
                $escaped = $trim.Replace('"','`"')
                return '"' + $escaped + '"'
            }
            return $trim
        }
        if (!$script:CW_CurrentFunc) { return }
        $cat  = $script:CW_CurrentCat
        $fn   = $script:CW_CurrentFunc
        $meta = $Global:PSADTFunctions[$cat][$fn]
        $parts = @($fn)
        foreach ($p in $meta.Params.Keys) {
            $ctrl = $script:CW_ParamControls[$p]
            if (!$ctrl) { continue }
            $pDef = $meta.Params[$p]
            if ($pDef -is [System.Collections.IDictionary]) { $pDef["Name"] = $p.TrimStart('-') }
            if ($pDef.Type -eq "switch") {
                if ($ctrl.IsChecked -eq $true) { $parts += $p }
            } else {
                $val = if ($ctrl -is [System.Windows.Controls.ComboBox]) {
                    if ($ctrl.SelectedItem) { $ctrl.SelectedItem.ToString() } else { "" }
                } else {
                    if ($ctrl -is [System.Windows.Controls.TextBox] -and (CW-IsHintActive $ctrl)) { "" } else { $ctrl.Text }
                }
                if (![string]::IsNullOrWhiteSpace($val)) {
                    $fmt = CW-FormatParamValue -pDef $pDef -RawValue $val
                    if (![string]::IsNullOrWhiteSpace($fmt)) { $parts += "$p $fmt" }
                }
            }
        }
        if ($parts.Count -le 1) {
            $script:CW_PreviewBox.Text = $parts[0]
            return
        }
        $plines = New-Object System.Collections.Generic.List[string]
        for ($i = 0; $i -lt $parts.Count; $i++) {
            if ($i -lt ($parts.Count - 1)) { $plines.Add(($parts[$i] + " ``")) | Out-Null }
            else { $plines.Add($parts[$i]) | Out-Null }
        }
        $script:CW_PreviewBox.Text = ($plines -join "`r`n            ")
    }
    function CW-HasConfiguredInput {
        if (!$script:CW_CurrentFunc -or !$script:CW_CurrentCat) { return $false }
        $meta = $Global:PSADTFunctions[$script:CW_CurrentCat][$script:CW_CurrentFunc]
        if (!$meta -or !$meta.Params -or $meta.Params.Count -eq 0) { return $false }
        foreach ($p in $meta.Params.Keys) {
            $ctrl = $script:CW_ParamControls[$p]
            if (!$ctrl) { continue }
            $pDef = $meta.Params[$p]
            if ($pDef.Type -eq "switch") {
                if ($ctrl.IsChecked -eq $true) { return $true }
                continue
            }
            if ($ctrl -is [System.Windows.Controls.ComboBox]) {
                $v = if ($ctrl.SelectedItem) { [string]$ctrl.SelectedItem.ToString() } else { "" }
                if (![string]::IsNullOrWhiteSpace($v)) { return $true }
                continue
            }
            $tv = [string]$ctrl.Text
            if (![string]::IsNullOrWhiteSpace($tv)) { return $true }
        }
        return $false
    }
    function CW-GetFormStateKey([string]$Section,[string]$Cat,[string]$Fn) {
        $sec = if ([string]::IsNullOrWhiteSpace($Section)) { CW-GetActiveSection } else { $Section }
        if ([string]::IsNullOrWhiteSpace($sec)) { $sec = "Pre-Install" }
        return "$sec|$Cat|$Fn"
    }
    function CW-GetCurrentSignature {
        if (!$script:CW_CurrentFunc -or !$script:CW_CurrentCat) { return "" }
        $meta = $Global:PSADTFunctions[$script:CW_CurrentCat][$script:CW_CurrentFunc]
        if (!$meta -or !$meta.Params) { return "" }
        $parts = New-Object System.Collections.Generic.List[string]
        foreach ($p in ($meta.Params.Keys | Sort-Object)) {
            $ctrl = $script:CW_ParamControls[$p]
            if (!$ctrl) { continue }
            $val = ""
            if ($ctrl -is [System.Windows.Controls.CheckBox]) {
                $val = if ($ctrl.IsChecked -eq $true) { "1" } else { "0" }
            } elseif ($ctrl -is [System.Windows.Controls.ComboBox]) {
                $val = if ($ctrl.SelectedItem) { [string]$ctrl.SelectedItem.ToString() } else { "" }
            } else {
                $val = [string]$ctrl.Text
            }
            $parts.Add(("{0}={1}" -f $p, $val.Trim())) | Out-Null
        }
        return ($parts -join "|")
    }
    function CW-IsCurrentDirty([string]$Section = "") {
        if (!$script:CW_CurrentFunc -or !$script:CW_CurrentCat) { return $false }
        $sec = if ([string]::IsNullOrWhiteSpace($Section)) { CW-GetActiveSection } else { $Section }
        $k = CW-GetFormStateKey -Section $sec -Cat $script:CW_CurrentCat -Fn $script:CW_CurrentFunc
        $cur = CW-GetCurrentSignature
        $base = if ($script:CW_FormBaseline.ContainsKey($k)) { [string]$script:CW_FormBaseline[$k] } else { "" }
        return ($cur -ne $base)
    }
    function CW-SetCurrentBaseline([string]$Section = "") {
        if (!$script:CW_CurrentFunc -or !$script:CW_CurrentCat) { return }
        $sec = if ([string]::IsNullOrWhiteSpace($Section)) { CW-GetActiveSection } else { $Section }
        $k = CW-GetFormStateKey -Section $sec -Cat $script:CW_CurrentCat -Fn $script:CW_CurrentFunc
        $script:CW_FormBaseline[$k] = CW-GetCurrentSignature
    }

    function CW-ApplyBaselineToState([string]$Section,[string]$Cat,[string]$Fn) {
        if ([string]::IsNullOrWhiteSpace($Section) -or [string]::IsNullOrWhiteSpace($Cat) -or [string]::IsNullOrWhiteSpace($Fn)) { return }
        if (-not $Global:PSADTFunctions.Contains($Cat)) { return }
        if (-not $Global:PSADTFunctions[$Cat].Contains($Fn)) { return }
        $formKey = CW-GetFormStateKey -Section $Section -Cat $Cat -Fn $Fn
        $sig = if ($script:CW_FormBaseline.ContainsKey($formKey)) { [string]$script:CW_FormBaseline[$formKey] } else { "" }
        $vals = @{}
        if (-not [string]::IsNullOrWhiteSpace($sig)) {
            foreach ($tok in @($sig -split "\|")) {
                if ([string]::IsNullOrWhiteSpace($tok)) { continue }
                $eq = $tok.IndexOf("=")
                if ($eq -lt 0) { continue }
                $pn = $tok.Substring(0,$eq)
                $pv = $tok.Substring($eq+1)
                $vals[$pn] = $pv
            }
        }
        $meta = $Global:PSADTFunctions[$Cat][$Fn]
        foreach ($p in $meta.Params.Keys) {
            $stateKey = CW-GetStateKey -Cat $Cat -Fn $Fn -ParamName $p -Section $Section
            $def = $meta.Params[$p]
            $raw = if ($vals.ContainsKey($p)) { [string]$vals[$p] } else { "" }
            if ($def.Type -eq "switch") {
                $script:CW_ParamStateCache[$stateKey] = ($raw -eq "1" -or $raw -ieq "true" -or $raw -ieq "`$true")
            } else {
                $script:CW_ParamStateCache[$stateKey] = $raw
            }
        }
    }

    function CW-ResolveCategoryForFunction([string]$FnName) {
        if ([string]::IsNullOrWhiteSpace($FnName)) { return $null }
        foreach ($catKey in @($Global:PSADTFunctions.Keys)) {
            if ($Global:PSADTFunctions[$catKey].Contains($FnName)) { return [string]$catKey }
        }
        return $null
    }
    function CW-NormalizeSavedValue([string]$Raw) {
        if ($null -eq $Raw) { return "" }
        $v = [string]$Raw
        if ($v -match '^"(.*)"$') { return $Matches[1] }
        if ($v -match "^'(.*)'$") { return $Matches[1].Replace("''","'") }
        return $v
    }
    function CW-LoadSavedBlocksToState([string]$ScriptPath) {
        if ([string]::IsNullOrWhiteSpace($ScriptPath) -or !(Test-Path $ScriptPath)) { return }
        try {
            $raw = [System.IO.File]::ReadAllText($ScriptPath,[System.Text.Encoding]::UTF8)
            $pat = "(?ms)^\s*#\s*WinGet-PSADT GUI Tool:BEGIN-CMD \[(?<id>[^\]]+)\]\s*$\r?\n(?<cmd>.*?)^\s*#\s*WinGet-PSADT GUI Tool:END-CMD \[\k<id>\]\s*$"
            $ms = [regex]::Matches($raw,$pat)
            foreach ($m in $ms) {
                $id = [string]$m.Groups["id"].Value
                $cmdBody = [string]$m.Groups["cmd"].Value
                if ([string]::IsNullOrWhiteSpace($id)) { continue }
                $idParts = $id.Split("|",2)
                if ($idParts.Count -lt 2) { continue }
                $section = [string]$idParts[0]
                $fn = [string]$idParts[1]
                $cat = CW-ResolveCategoryForFunction -FnName $fn
                if ([string]::IsNullOrWhiteSpace($cat)) { continue }
                $keyForm = CW-GetFormStateKey -Section $section -Cat $cat -Fn $fn
                $cleanLines = @($cmdBody -split "`r?`n" | ForEach-Object {
                    $t = [string]$_
                    $t = $t.Trim()
                    if ($t.EndsWith("``")) { $t = $t.Substring(0,$t.Length-1).TrimEnd() }
                    $t
                } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                if ($cleanLines.Count -eq 0) { continue }
                $sigParts = New-Object System.Collections.Generic.List[string]
                $meta = $Global:PSADTFunctions[$cat][$fn]
                foreach ($p in ($meta.Params.Keys | Sort-Object)) {
                    $stateKey = CW-GetStateKey -Cat $cat -Fn $fn -ParamName $p -Section $section
                    $script:CW_ParamStateCache[$stateKey] = ""
                    $sigParts.Add(("{0}=" -f $p)) | Out-Null
                }
                foreach ($ln in $cleanLines) {
                    if ($ln -notmatch "^-(?<pn>\S+)(?<rest>\s+.*)?$") { continue }
                    $paramName = "-" + [string]$Matches["pn"]
                    if (-not $meta.Params.Contains($paramName)) { continue }
                    $rest = if ($Matches["rest"]) { [string]$Matches["rest"].Trim() } else { "" }
                    $def = $meta.Params[$paramName]
                    $stateKey = CW-GetStateKey -Cat $cat -Fn $fn -ParamName $paramName -Section $section
                    if ($def.Type -eq "switch") {
                        $script:CW_ParamStateCache[$stateKey] = $true
                    } else {
                        $script:CW_ParamStateCache[$stateKey] = CW-NormalizeSavedValue -Raw $rest
                    }
                }
                # Rebuild baseline signature from loaded values for this section/function.
                $sigParts.Clear()
                foreach ($p in ($meta.Params.Keys | Sort-Object)) {
                    $stateKey = CW-GetStateKey -Cat $cat -Fn $fn -ParamName $p -Section $section
                    $sv = if ($script:CW_ParamStateCache.ContainsKey($stateKey)) { [string]$script:CW_ParamStateCache[$stateKey] } else { "" }
                    $sigParts.Add(("{0}={1}" -f $p,$sv.Trim())) | Out-Null
                }
                $script:CW_FormBaseline[$keyForm] = ($sigParts -join "|")
            }
        } catch {
            Write-DebugLog "WARN" ("CW-LoadSavedBlocksToState failed | {0}" -f $_.Exception.Message)
        }
    }
    function CW-BuildParamForm([string]$Cat,[string]$Fn) {
        $script:CW_ParamsPanel.Children.Clear()
        $script:CW_ParamControls = @{}
        $script:CW_CurrentFunc   = $Fn
        $script:CW_CurrentCat    = $Cat
        $meta = $Global:PSADTFunctions[$Cat][$Fn]

        # Build and bind metadata table rows.
        $metaRows = [System.Collections.Generic.List[object]]::new()
        foreach ($pName in $meta.Params.Keys) {
            $pDef = $meta.Params[$pName]
            $metaRows.Add([PSCustomObject]@{
                ParameterName = $pName
                ParameterType = if ($pDef.ParamType) { $pDef.ParamType } else { $pDef.Type }
                Required      = if ($pDef.Required) { "Yes" } else { "No" }
                Position      = if ($pDef.Position) { $pDef.Position } else { "Named" }
            }) | Out-Null
        }
        $script:CW_ParamGrid.ItemsSource = $metaRows

        # Description banner
        $db = New-Object System.Windows.Controls.Border
        $db.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0D1B2A"); $db.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $db.Margin = [System.Windows.Thickness]::new(0,0,0,10); $db.Padding = [System.Windows.Thickness]::new(10,6,10,6)
        $dtb = New-Object System.Windows.Controls.TextBlock
        $dtb.Text = $meta.Desc; $dtb.Foreground = "#6B7280"
        $dtb.FontSize = 11; $dtb.TextWrapping = "Wrap"
        $db.Child = $dtb; $script:CW_ParamsPanel.Children.Add($db) | Out-Null

        if ($meta.Params.Count -eq 0) {
            $np = New-Object System.Windows.Controls.TextBlock
            $np.Text = "No parameters required."; $np.Foreground = "#4B5563"; $np.FontSize = 11
            $script:CW_ParamsPanel.Children.Add($np) | Out-Null
            $script:CW_PreviewBox.Text = $Fn; return
        }

        foreach ($pName in $meta.Params.Keys) {
            $pDef = $meta.Params[$pName]
            $row  = New-Object System.Windows.Controls.Grid
            $row.Margin = [System.Windows.Thickness]::new(0,4,0,4)
            $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = [System.Windows.GridLength]::new(155)
            $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $row.ColumnDefinitions.Add($c0); $row.ColumnDefinitions.Add($c1)

            $lbl = New-Object System.Windows.Controls.TextBlock
            $lbl.Text = $pDef.Label
            $lbl.Foreground = if ($pDef.Required) { "#E5E7EB" } else { "#9CA3AF" }
            $lbl.FontSize = 11; $lbl.VerticalAlignment = "Center"
            $lbl.Margin = [System.Windows.Thickness]::new(0,0,10,0); $lbl.ToolTip = $pName
            [System.Windows.Controls.Grid]::SetColumn($lbl,0)
            $row.Children.Add($lbl) | Out-Null

            $ctrl = $null
            if ($pDef.Type -eq "switch") {
                $ctrl = New-Object System.Windows.Controls.CheckBox
                $ctrl.Tag = $pName
                $k = CW-GetStateKey $Cat $Fn $pName
                if ($script:CW_ParamStateCache.ContainsKey($k)) { $ctrl.IsChecked = [bool]$script:CW_ParamStateCache[$k] }
                else { $ctrl.IsChecked = $pDef.Default }
                $ctrl.Foreground = "#9CA3AF"; $ctrl.VerticalAlignment = "Center"
                $ctrl.Add_Click({
                    $kk = CW-GetStateKey $script:CW_CurrentCat $script:CW_CurrentFunc ([string]$this.Tag)
                    $script:CW_ParamStateCache[$kk] = [bool]($this.IsChecked -eq $true)
                    CW-BuildPreview
                })
            } elseif ($pDef.Type -eq "combo") {
                $ctrl = New-Object System.Windows.Controls.ComboBox
                $ctrl.Tag = $pName
                $ctrl.Height = 28; $ctrl.FontSize = 11
                $ctrl.HorizontalAlignment = "Left"
                $ctrl.VerticalContentAlignment = "Center"
                $ctrl.Background = "#1A2332"; $ctrl.Foreground = "White"
                $ctrl.BorderBrush = "#2D3F55"; $ctrl.BorderThickness = "1"
                $ctrl.Padding = [System.Windows.Thickness]::new(6,2,6,2)
                $ctrl.Items.Add("") | Out-Null
                foreach ($opt in $pDef.Options) { $ctrl.Items.Add($opt) | Out-Null }
                $k = CW-GetStateKey $Cat $Fn $pName
                $savedVal = if ($script:CW_ParamStateCache.ContainsKey($k)) { [string]$script:CW_ParamStateCache[$k] } else { $null }
                $isBoolCombo = ($ctrl.Items.Count -eq 2 -and
                    [string]$ctrl.Items[0] -match '^(?i:true|false)$' -and
                    [string]$ctrl.Items[1] -match '^(?i:true|false)$')
                if (![string]::IsNullOrWhiteSpace($savedVal) -and ($ctrl.Items -contains $savedVal)) {
                    $ctrl.SelectedItem = $savedVal
                } else {
                    # All dropdowns should start unselected unless user already set a value.
                    $ctrl.SelectedIndex = 0
                }
                Set-ComboDynamicSize -Combo $ctrl -MinChars 2
                $ctrl.Add_SelectionChanged({
                    $kk = CW-GetStateKey $script:CW_CurrentCat $script:CW_CurrentFunc ([string]$this.Tag)
                    $script:CW_ParamStateCache[$kk] = if ($this.SelectedItem) { $this.SelectedItem.ToString() } else { "" }
                    CW-BuildPreview
                })
            } else {
                $ctrl = New-Object System.Windows.Controls.TextBox
                $hintText = CW-GetParamHint -ParamName $pName -ParamDef $pDef
                $ctrl.Tag = @{ Param = $pName; Hint = $hintText }
                $k = CW-GetStateKey $Cat $Fn $pName
                $seedText = if ($script:CW_ParamStateCache.ContainsKey($k)) { [string]$script:CW_ParamStateCache[$k] } else { [string]$pDef.Default }
                if ([string]::IsNullOrWhiteSpace($seedText)) {
                    $ctrl.Text = ""
                    $ctrl.Foreground = "#D1D5DB"
                } else {
                    $ctrl.Text = $seedText
                    $ctrl.Foreground = "#D1D5DB"
                }
                $ctrl.Height = 28; $ctrl.FontSize = 11
                $ctrl.FontFamily = "Consolas"
                $ctrl.VerticalContentAlignment = "Center"
                $ctrl.Background = "#1A2332"
                $ctrl.CaretBrush = "White"
                $ctrl.ToolTip = $hintText
                $ctrl.BorderBrush = "#2D3F55"; $ctrl.BorderThickness = "1"; $ctrl.Padding = "6,0,6,0"
                $ctrl.Add_TextChanged({
                    $paramKey = CW-GetParamKeyFromTag $this.Tag
                    if ([string]::IsNullOrWhiteSpace($paramKey)) { return }
                    $kk = CW-GetStateKey $script:CW_CurrentCat $script:CW_CurrentFunc $paramKey
                    $script:CW_ParamStateCache[$kk] = $this.Text
                    CW-BuildPreview
                })
            }
            [System.Windows.Controls.Grid]::SetColumn($ctrl,1)
            $row.Children.Add($ctrl) | Out-Null
            $script:CW_ParamControls[$pName] = $ctrl
            $script:CW_ParamsPanel.Children.Add($row) | Out-Null
        }
        CW-BuildPreview
        CW-SetCurrentBaseline
    }
    function CW-SelectSection([string]$SectionName) {
        foreach ($it in $script:CW_SectionCombo.Items) {
            $name = if ($it -is [System.Windows.Controls.ComboBoxItem]) { [string]$it.Content } else { [string]$it }
            if ($name -eq $SectionName) {
                $script:CW_SectionSwitchGuard = $true
                $script:CW_SectionCombo.SelectedItem = $it
                $script:CW_SectionSwitchGuard = $false
                return
            }
        }
    }
    function CW-SaveCurrentPreviewToSection([string]$Section,[bool]$ShowSuccess = $true) {
        if (!$script:CW_CurrentFunc) {
            Show-Msg("Select a function first.","No Function",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
            return $false
        }
        if (!(Test-Path $script:CW_ScriptPath)) {
            Show-Msg("Script file not found. Run Download first.",
                "Not Found",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
            return $false
        }
        $hasInput = CW-HasConfiguredInput
        $marker = Get-SectionMarker -Section $Section
        $previewLines = @($script:CW_PreviewBox.Text -split "`r?`n")
        $cmd = (($previewLines | ForEach-Object {
            if ([string]::IsNullOrWhiteSpace($_)) { $_ } else { "    " + $_.TrimEnd() }
        }) -join "`r`n").TrimEnd()
        $blockId = "{0}|{1}" -f $Section,$script:CW_CurrentFunc
        $beginLine = "    # WinGet-PSADT GUI Tool:BEGIN-CMD [$blockId]"
        $endLine   = "    # WinGet-PSADT GUI Tool:END-CMD [$blockId]"
        $blockText = @($beginLine,$cmd,$endLine) -join "`r`n"

        $rawText = [System.IO.File]::ReadAllText($script:CW_ScriptPath,[System.Text.Encoding]::UTF8)
        $existingPattern = "(?ms)^\s*#\s*WinGet-PSADT GUI Tool:BEGIN-CMD \[$([regex]::Escape($blockId))\]\s*$.*?^\s*#\s*WinGet-PSADT GUI Tool:END-CMD \[$([regex]::Escape($blockId))\]\s*$\r?\n?"
        $hadExisting = [regex]::IsMatch($rawText,$existingPattern)
        $rawText = [regex]::Replace($rawText,$existingPattern,"")
        if (-not $hasInput) {
            if ($hadExisting) {
                [System.IO.File]::WriteAllText($script:CW_ScriptPath,$rawText,[System.Text.Encoding]::UTF8)
                CW-SetCurrentBaseline -Section $Section
                Set-Status "Removed $($script:CW_CurrentFunc) from $Section section" "#F59E0B"
                if ($ShowSuccess) {
                    Show-Msg("Removed from $Section section in Invoke-AppDeployToolkit.ps1.",
                        "Removed",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
                }
                return $true
            } else {
                CW-SetCurrentBaseline -Section $Section
                if ($ShowSuccess) {
                    Show-Msg("No parameter values provided for $($script:CW_CurrentFunc). Nothing was saved.",
                        "Nothing To Save",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
                }
                return $false
            }
        }
        $fileLines = $rawText -split "`r?`n"
        $out2 = [System.Collections.Generic.List[string]]::new()
        $found2 = $false
        foreach ($fl in $fileLines) {
            $out2.Add($fl)
            if (!$found2 -and $fl.Trim() -eq $marker) {
                foreach ($bl in ($blockText -split "`r?`n")) { $out2.Add($bl) }
                $found2 = $true
            }
        }
        if (!$found2) {
            Show-Msg("Marker not found: $marker`n`nRun Download then Configure first.",
                "Marker Missing",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
            return $false
        }
        [System.IO.File]::WriteAllLines($script:CW_ScriptPath,$out2,[System.Text.Encoding]::UTF8)
        CW-SetCurrentBaseline -Section $Section
        Set-Status "Saved $($script:CW_CurrentFunc) to $Section section" "#10B981"
        if ($ShowSuccess) {
            Show-Msg("Saved to $Section section in Invoke-AppDeployToolkit.ps1:`n`n$($script:CW_PreviewBox.Text)",
                "Saved",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
        }
        return $true
    }

    # Hydrate per-section function parameter state from previously saved script blocks.
    CW-LoadSavedBlocksToState -ScriptPath $script:CW_ScriptPath

    # Populate categories
    @($Global:PSADTFunctions.Keys | Sort-Object -Unique) | ForEach-Object { $CW_CategoryList.Items.Add($_) | Out-Null }

    $CW_CategoryList.Add_SelectionChanged({
        $cat = $CW_CategoryList.SelectedItem
        if (!$cat) { return }
        $CW_FunctionList.Items.Clear()
        $script:CW_ParamGrid.ItemsSource = $null
        $script:CW_ParamsPanel.Children.Clear()
        $script:CW_CurrentFunc = $null
        $script:CW_PreviewBox.Text = "# Select a function to preview"
        $script:CW_FuncTitle.Text  = $cat
        @($Global:PSADTFunctions[$cat].Keys | Sort-Object -Unique) | ForEach-Object { $CW_FunctionList.Items.Add($_) | Out-Null }
    })

    $CW_FunctionList.Add_SelectionChanged({
        $cat = $CW_CategoryList.SelectedItem
        $fn  = $CW_FunctionList.SelectedItem
        if (!$cat -or !$fn) { return }
        $script:CW_FuncTitle.Text = $fn
        CW-BuildParamForm $cat $fn
    })
    $CW_SectionCombo.Add_SelectionChanged({
        if ($script:CW_SectionSwitchGuard) { return }
        $newSec = if ($script:CW_SectionCombo.SelectedItem -is [System.Windows.Controls.ComboBoxItem]) { [string]$script:CW_SectionCombo.SelectedItem.Content } else { [string]$script:CW_SectionCombo.SelectedItem }
        if ([string]::IsNullOrWhiteSpace($newSec)) { return }
        $oldSec = [string]$script:CW_LastSection
        if ([string]::IsNullOrWhiteSpace($oldSec)) { $script:CW_LastSection = $newSec; return }
        if ($newSec -eq $oldSec) { return }

        $hasDraft = ($script:CW_CurrentFunc -and (CW-IsCurrentDirty -Section $oldSec))
        if ($hasDraft) {
            $choice = Show-Msg("Save current command to '$oldSec' before switching to '$newSec'?",
                "Switch Section",[System.Windows.MessageBoxButton]::YesNoCancel,[System.Windows.MessageBoxImage]::Question)
            if (Test-MsgResult -Result $choice -Target "Cancel") {
                CW-SelectSection $oldSec
                return
            }
            if (Test-MsgResult -Result $choice -Target "Yes") {
                $saved = CW-SaveCurrentPreviewToSection -Section $oldSec -ShowSuccess $false
                if (-not $saved) {
                    CW-SelectSection $oldSec
                    return
                }
                Set-Status "Saved current command to $oldSec and switched to $newSec" "#10B981"
            } elseif (Test-MsgResult -Result $choice -Target "No") {
                CW-ApplyBaselineToState -Section $oldSec -Cat $script:CW_CurrentCat -Fn $script:CW_CurrentFunc
            }
        }
        $script:CW_LastSection = $newSec
        if ($script:CW_CurrentCat -and $script:CW_CurrentFunc) {
            # Reload current function controls from the newly selected section state.
            CW-BuildParamForm $script:CW_CurrentCat $script:CW_CurrentFunc
        }
    })

    $CW_AddBtn.Add_Click({
        $si = $script:CW_SectionCombo.SelectedItem
        $section = if ($si -is [System.Windows.Controls.ComboBoxItem]) { $si.Content } else { $si.ToString() }
        [void](CW-SaveCurrentPreviewToSection -Section $section -ShowSuccess $true)
    })

    $CW_DetailsBtn.Add_Click({
        if (!(Test-Path $script:CW_ScriptPath)) {
            Show-Msg("Script file not found. Run Download first.",
                "Not Found",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
        }
        $cur = Get-AppDetailsFromScript -ScriptPath $script:CW_ScriptPath -AppName $appName -Version $Global:SelectedVersion
        $saiwCur = Get-SAIWParamsFromScript -ScriptPath $script:CW_ScriptPath
        $detCur = Get-DetectionConfigForScript -ScriptPath $script:CW_ScriptPath -AppName $cur.AppName -AppVersion $cur.AppVersion

        $dw = New-Object System.Windows.Window
        $dw.Title = "Application Details"
        $dw.Width = 1120; $dw.Height = 760
        $dw.WindowStartupLocation = "CenterOwner"; $dw.Owner = $script:ConfigWindow
        $dw.WindowStyle = "None"; $dw.ResizeMode = "NoResize"; $dw.AllowsTransparency = $true
        $dw.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("Transparent")
        $comboStylesXaml = @"
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
  <Style x:Key="DarkScrollThumb" TargetType="Thumb">
    <Setter Property="Background" Value="#334155"/>
    <Setter Property="BorderThickness" Value="0"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="Thumb">
          <Border Background="{TemplateBinding Background}" CornerRadius="3"/>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style TargetType="ScrollBar">
    <Setter Property="Background" Value="#0F1923"/>
    <Setter Property="Width" Value="8"/>
    <Setter Property="Height" Value="8"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ScrollBar">
          <Grid Background="{TemplateBinding Background}">
            <Track Name="PART_Track" IsDirectionReversed="True">
              <Track.DecreaseRepeatButton><RepeatButton Opacity="0" IsHitTestVisible="False"/></Track.DecreaseRepeatButton>
              <Track.Thumb>
                <Thumb Style="{StaticResource DarkScrollThumb}"/>
              </Track.Thumb>
              <Track.IncreaseRepeatButton><RepeatButton Opacity="0" IsHitTestVisible="False"/></Track.IncreaseRepeatButton>
            </Track>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="Orientation" Value="Horizontal">
              <Setter TargetName="PART_Track" Property="IsDirectionReversed" Value="False"/>
            </Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
  <Style x:Key="DarkDetailsComboItem" TargetType="ComboBoxItem">
    <Setter Property="Background" Value="#1A2332"/>
    <Setter Property="Foreground" Value="#D1D5DB"/>
    <Setter Property="Padding" Value="8,6"/>
    <Style.Triggers>
      <Trigger Property="IsMouseOver" Value="True">
        <Setter Property="Background" Value="#2D3F55"/>
        <Setter Property="Foreground" Value="White"/>
      </Trigger>
      <Trigger Property="IsSelected" Value="True">
        <Setter Property="Background" Value="#1E3A8A"/>
        <Setter Property="Foreground" Value="White"/>
      </Trigger>
    </Style.Triggers>
  </Style>
  <Style x:Key="DarkDetailsCombo" TargetType="ComboBox">
    <Setter Property="Background" Value="#1A2332"/>
    <Setter Property="Foreground" Value="#E5E7EB"/>
    <Setter Property="BorderBrush" Value="#2D3F55"/>
    <Setter Property="BorderThickness" Value="1"/>
    <Setter Property="Template">
      <Setter.Value>
        <ControlTemplate TargetType="ComboBox">
          <Grid>
            <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="2"/>
            <Grid Margin="2">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="26"/>
              </Grid.ColumnDefinitions>
              <ContentPresenter Grid.Column="0" Margin="4,0,24,0" VerticalAlignment="Center" HorizontalAlignment="Left" Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"/>
              <ToggleButton Grid.ColumnSpan="2" Focusable="False" IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}" Background="Transparent" BorderBrush="Transparent" BorderThickness="0">
                <Path HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,10,0" Stretch="None" SnapsToDevicePixels="True" Fill="#9CA3AF" Data="M 0 0 L 4 4 L 8 0 Z"/>
              </ToggleButton>
            </Grid>
            <Popup Name="PART_Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Fade">
              <Border Background="#1A2332" MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}" BorderBrush="#2D3F55" BorderThickness="1" CornerRadius="2" SnapsToDevicePixels="True">
                <ScrollViewer Margin="0" SnapsToDevicePixels="True" CanContentScroll="True" HorizontalScrollBarVisibility="Auto">
                  <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                </ScrollViewer>
              </Border>
            </Popup>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True">
              <Setter TargetName="Bd" Property="BorderBrush" Value="#3B82F6"/>
            </Trigger>
            <Trigger Property="IsKeyboardFocusWithin" Value="True">
              <Setter TargetName="Bd" Property="BorderBrush" Value="#38BDF8"/>
            </Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value>
    </Setter>
  </Style>
</ResourceDictionary>
"@
        $dw.Resources = [Windows.Markup.XamlReader]::Parse($comboStylesXaml)
        $g = New-Object System.Windows.Controls.Grid
        $g.Margin = [System.Windows.Thickness]::new(14)
        $fieldSpec = Get-AppDetailFieldSpec
        $saiwSpec = Get-SAIWFieldSpec
        $detSpec = @(
            @{ Key="DetectionNameRegex"; Label="Name Regex"; Kind="text" },
            @{ Key="DetectionUseVersion"; Label="Use Version Match"; Kind="bool" },
            @{ Key="DetectionVersion"; Label="Version"; Kind="text" },
            @{ Key="DetectionRegistryRoots"; Label="Registry Roots (; separated)"; Kind="text" }
        )
        $r0 = New-Object System.Windows.Controls.RowDefinition; $r0.Height = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
        $r1 = New-Object System.Windows.Controls.RowDefinition; $r1.Height = [System.Windows.GridLength]::new(46)
        $g.RowDefinitions.Add($r0); $g.RowDefinitions.Add($r1)

        $contentGrid = New-Object System.Windows.Controls.Grid
        $cg0 = New-Object System.Windows.Controls.ColumnDefinition; $cg0.Width = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
        $cg1 = New-Object System.Windows.Controls.ColumnDefinition; $cg1.Width = [System.Windows.GridLength]::new(1)
        $cg2 = New-Object System.Windows.Controls.ColumnDefinition; $cg2.Width = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
        $contentGrid.ColumnDefinitions.Add($cg0); $contentGrid.ColumnDefinitions.Add($cg1); $contentGrid.ColumnDefinitions.Add($cg2)
        [System.Windows.Controls.Grid]::SetRow($contentGrid,0)
        $g.Children.Add($contentGrid) | Out-Null

        $divider = New-Object System.Windows.Controls.Border
        $divider.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
        [System.Windows.Controls.Grid]::SetColumn($divider,1)
        $contentGrid.Children.Add($divider) | Out-Null

        $leftWrap = New-Object System.Windows.Controls.ScrollViewer
        $leftWrap.VerticalScrollBarVisibility = "Auto"
        $leftWrap.HorizontalScrollBarVisibility = "Disabled"
        $leftWrap.Margin = [System.Windows.Thickness]::new(0,0,10,0)
        [System.Windows.Controls.Grid]::SetColumn($leftWrap,0)
        $contentGrid.Children.Add($leftWrap) | Out-Null

        $rightWrap = New-Object System.Windows.Controls.ScrollViewer
        $rightWrap.VerticalScrollBarVisibility = "Auto"
        $rightWrap.HorizontalScrollBarVisibility = "Disabled"
        $rightWrap.Margin = [System.Windows.Thickness]::new(10,0,0,0)
        [System.Windows.Controls.Grid]::SetColumn($rightWrap,2)
        $contentGrid.Children.Add($rightWrap) | Out-Null

        $leftPanel = New-Object System.Windows.Controls.StackPanel
        $leftPanel.Orientation = "Vertical"
        $leftWrap.Content = $leftPanel
        $rightPanel = New-Object System.Windows.Controls.StackPanel
        $rightPanel.Orientation = "Vertical"
        $rightWrap.Content = $rightPanel

        $leftHdr = New-Object System.Windows.Controls.TextBlock
        $leftHdr.Text = "App Details"
        $leftHdr.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
        $leftHdr.FontSize = 12
        $leftHdr.Margin = [System.Windows.Thickness]::new(0,0,0,8)
        $leftPanel.Children.Add($leftHdr) | Out-Null

        $rightHdr = New-Object System.Windows.Controls.TextBlock
        $rightHdr.Text = "saiwParams (Show-ADTInstallationWelcome Parameters) Details"
        $rightHdr.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
        $rightHdr.FontSize = 12
        $rightHdr.Margin = [System.Windows.Thickness]::new(0,0,0,8)
        $rightPanel.Children.Add($rightHdr) | Out-Null

        $leftGrid = New-Object System.Windows.Controls.Grid
        $lc0 = New-Object System.Windows.Controls.ColumnDefinition; $lc0.Width = [System.Windows.GridLength]::new(170)
        $lc1 = New-Object System.Windows.Controls.ColumnDefinition; $lc1.Width = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
        $leftGrid.ColumnDefinitions.Add($lc0); $leftGrid.ColumnDefinitions.Add($lc1)
        0..$fieldSpec.Count | ForEach-Object {
            $rr = New-Object System.Windows.Controls.RowDefinition
            $rr.Height = if ($_ -eq $fieldSpec.Count) { [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star) } else { [System.Windows.GridLength]::new(34) }
            $leftGrid.RowDefinitions.Add($rr)
        }
        $leftPanel.Children.Add($leftGrid) | Out-Null

        $rightGrid = New-Object System.Windows.Controls.Grid
        $rc0 = New-Object System.Windows.Controls.ColumnDefinition; $rc0.Width = [System.Windows.GridLength]::new(230)
        $rc1 = New-Object System.Windows.Controls.ColumnDefinition; $rc1.Width = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
        $rightGrid.ColumnDefinitions.Add($rc0); $rightGrid.ColumnDefinitions.Add($rc1)
        0..($saiwSpec.Count-1) | ForEach-Object {
            $rr = New-Object System.Windows.Controls.RowDefinition
            $rr.Height = [System.Windows.GridLength]::new(34)
            $rightGrid.RowDefinitions.Add($rr)
        }
        $rightPanel.Children.Add($rightGrid) | Out-Null

        $getSaiwHint = {
            param($s)
            $pt = [string]$s.ParamType
            switch -Regex ($pt) {
                '^DateTime$'      { return "Ex: (Get-Date).AddDays(3).Date.AddHours(23).AddMinutes(59)" }
                '^TimeSpan$'      { return "Ex: '00:30:00'" }
                '^ScriptBlock$'   { return "Ex: { `$_.DisplayName -match 'Contoso' }" }
                '^Guid$'          { return "Ex: '00000000-0000-0000-0000-000000000000'" }
                '^Int(16|32|64)$' { return "Ex: 3" }
                '^Double$'        { return "Ex: 1.5" }
                '^String\[\]$'    { return "Ex: 'value1','value2'" }
                '^Object\[\]$'    { return "Ex: @('value1','value2')" }
                default { return "Ex: value" }
            }
        }

        $ctrls = @{}
        for ($i=0; $i -lt $fieldSpec.Count; $i++) {
            $lbl = New-Object System.Windows.Controls.TextBlock
            $lbl.Text = $fieldSpec[$i].Label
            $lbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9CA3AF")
            $lbl.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetRow($lbl,$i); [System.Windows.Controls.Grid]::SetColumn($lbl,0)
            $leftGrid.Children.Add($lbl) | Out-Null

            if ($fieldSpec[$i].Key -eq "RequireAdmin") {
                $cbReq = New-Object System.Windows.Controls.ComboBox
                $cbReq.Height = 26
                $cbReq.HorizontalAlignment = "Left"
                $cbReq.VerticalContentAlignment = "Center"
                $cbReq.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2332")
                $cbReq.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
                $cbReq.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
                $cbReq.BorderThickness = [System.Windows.Thickness]::new(1)
                $cbReq.Style = $dw.Resources["DarkDetailsCombo"]
                $cbReq.ItemContainerStyle = $dw.Resources["DarkDetailsComboItem"]
                $cbReq.Items.Add("") | Out-Null
                $cbReq.Items.Add("true") | Out-Null
                $cbReq.Items.Add("false") | Out-Null
                $curReq = [string]$cur["RequireAdmin"]
                if ($curReq -match '^\$?true$') { $cbReq.SelectedItem = "true" }
                elseif ($curReq -match '^\$?false$') { $cbReq.SelectedItem = "false" }
                else { $cbReq.SelectedIndex = 0 }
                Set-ComboDynamicSize -Combo $cbReq -MinChars 2
                [System.Windows.Controls.Grid]::SetRow($cbReq,$i); [System.Windows.Controls.Grid]::SetColumn($cbReq,1)
                $leftGrid.Children.Add($cbReq) | Out-Null
                $ctrls[$fieldSpec[$i].Key] = $cbReq
            } else {
                $tb = New-Object System.Windows.Controls.TextBox
                $tb.Text = [string]$cur[$fieldSpec[$i].Key]
                $tb.Height = 26
                $tb.VerticalContentAlignment = "Center"
                $tb.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2332")
                $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
                $tb.CaretBrush = [System.Windows.Media.Brushes]::White
                $tb.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
                $tb.BorderThickness = [System.Windows.Thickness]::new(1)
                $tb.Padding = [System.Windows.Thickness]::new(6,0,6,0)
                if ($fieldSpec[$i].Key -eq "AppProcessesToClose") {
                    $example = Get-CloseProcessesExample
                    $tb.ToolTip = $example
                    if ([string]::IsNullOrWhiteSpace($tb.Text) -or $tb.Text.Trim() -eq "@()") {
                        $tb.Text = $example
                        $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#6B7280")
                        $tb.Tag = "hint"
                    }
                    $tb.Add_GotFocus({
                        if ($this.Tag -eq "hint") {
                            $this.Text = ""
                            $this.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
                            $this.Tag = $null
                        }
                    })
                    $tb.Add_LostFocus({
                        if ([string]::IsNullOrWhiteSpace($this.Text)) {
                            $this.Text = Get-CloseProcessesExample
                            $this.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#6B7280")
                            $this.Tag = "hint"
                        }
                    })
                }
                [System.Windows.Controls.Grid]::SetRow($tb,$i); [System.Windows.Controls.Grid]::SetColumn($tb,1)
                $leftGrid.Children.Add($tb) | Out-Null
                $ctrls[$fieldSpec[$i].Key] = $tb
            }
        }
        for ($j=0; $j -lt $saiwSpec.Count; $j++) {
            $rowIdx = $j
            $lbl = New-Object System.Windows.Controls.TextBlock
            $lbl.Text = $saiwSpec[$j].Label
            $lbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9CA3AF")
            $lbl.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetRow($lbl,$rowIdx); [System.Windows.Controls.Grid]::SetColumn($lbl,0)
            $rightGrid.Children.Add($lbl) | Out-Null

            if ($saiwSpec[$j].IsBool) {
                $cb = New-Object System.Windows.Controls.ComboBox
                $cb.Height = 26
                $cb.HorizontalAlignment = "Left"
                $cb.VerticalContentAlignment = "Center"
                $cb.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2332")
                $cb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
                $cb.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
                $cb.BorderThickness = [System.Windows.Thickness]::new(1)
                $cb.Style = $dw.Resources["DarkDetailsCombo"]
                $cb.ItemContainerStyle = $dw.Resources["DarkDetailsComboItem"]
                $cb.Items.Add("") | Out-Null
                $cb.Items.Add("true") | Out-Null
                $cb.Items.Add("false") | Out-Null
                $curVal = [string]$saiwCur[$saiwSpec[$j].Key]
                if ($curVal -match '^\$?true$') { $cb.SelectedItem = "true" }
                elseif ($curVal -match '^\$?false$') { $cb.SelectedItem = "false" }
                else { $cb.SelectedIndex = 0 }
                Set-ComboDynamicSize -Combo $cb -MinChars 2
                [System.Windows.Controls.Grid]::SetRow($cb,$rowIdx); [System.Windows.Controls.Grid]::SetColumn($cb,1)
                $rightGrid.Children.Add($cb) | Out-Null
                $ctrls["SAIW_" + $saiwSpec[$j].Key] = $cb
            } elseif ($saiwSpec[$j].IsEnum -and @($saiwSpec[$j].Options).Count -gt 0) {
                $cb = New-Object System.Windows.Controls.ComboBox
                $cb.Height = 26
                $cb.HorizontalAlignment = "Left"
                $cb.VerticalContentAlignment = "Center"
                $cb.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2332")
                $cb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
                $cb.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
                $cb.BorderThickness = [System.Windows.Thickness]::new(1)
                $cb.Style = $dw.Resources["DarkDetailsCombo"]
                $cb.ItemContainerStyle = $dw.Resources["DarkDetailsComboItem"]
                $cb.Items.Add("") | Out-Null
                foreach ($opt in @($saiwSpec[$j].Options)) { $cb.Items.Add([string]$opt) | Out-Null }
                $curVal = [string]$saiwCur[$saiwSpec[$j].Key]
                if ($cb.Items -contains $curVal) { $cb.SelectedItem = $curVal }
                else { $cb.SelectedIndex = 0 }
                Set-ComboDynamicSize -Combo $cb -MinChars 2
                [System.Windows.Controls.Grid]::SetRow($cb,$rowIdx); [System.Windows.Controls.Grid]::SetColumn($cb,1)
                $rightGrid.Children.Add($cb) | Out-Null
                $ctrls["SAIW_" + $saiwSpec[$j].Key] = $cb
            } else {
                $tb = New-Object System.Windows.Controls.TextBox
                $hint = (& $getSaiwHint $saiwSpec[$j])
                $seed = [string]$saiwCur[$saiwSpec[$j].Key]
                if ([string]::IsNullOrWhiteSpace($seed)) {
                    $tb.Text = ""
                    $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
                    $tb.Tag = @{ Hint = $hint; IsHint = $false }
                } else {
                    $tb.Text = $seed
                    $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
                    $tb.Tag = @{ Hint = $hint; IsHint = $false }
                }
                $tb.Height = 26
                $tb.VerticalContentAlignment = "Center"
                $tb.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2332")
                $tb.CaretBrush = [System.Windows.Media.Brushes]::White
                $tb.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
                $tb.BorderThickness = [System.Windows.Thickness]::new(1)
                $tb.Padding = [System.Windows.Thickness]::new(6,0,6,0)
                $tb.ToolTip = $hint
                [System.Windows.Controls.Grid]::SetRow($tb,$rowIdx); [System.Windows.Controls.Grid]::SetColumn($tb,1)
                $rightGrid.Children.Add($tb) | Out-Null
                $ctrls["SAIW_" + $saiwSpec[$j].Key] = $tb
            }
        }
        $detHdr = New-Object System.Windows.Controls.TextBlock
        $detHdr.Text = "Intune Detection Rule"
        $detHdr.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
        $detHdr.FontSize = 12
        $detHdr.Margin = [System.Windows.Thickness]::new(0,12,0,8)
        $rightPanel.Children.Add($detHdr) | Out-Null

        $detGrid = New-Object System.Windows.Controls.Grid
        $dc0 = New-Object System.Windows.Controls.ColumnDefinition; $dc0.Width = [System.Windows.GridLength]::new(230)
        $dc1 = New-Object System.Windows.Controls.ColumnDefinition; $dc1.Width = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
        $detGrid.ColumnDefinitions.Add($dc0); $detGrid.ColumnDefinitions.Add($dc1)
        0..($detSpec.Count-1) | ForEach-Object {
            $rr = New-Object System.Windows.Controls.RowDefinition
            $rr.Height = [System.Windows.GridLength]::new(34)
            $detGrid.RowDefinitions.Add($rr)
        }
        $rightPanel.Children.Add($detGrid) | Out-Null
        for ($k=0; $k -lt $detSpec.Count; $k++) {
            $lbl = New-Object System.Windows.Controls.TextBlock
            $lbl.Text = $detSpec[$k].Label
            $lbl.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#9CA3AF")
            $lbl.VerticalAlignment = "Center"
            [System.Windows.Controls.Grid]::SetRow($lbl,$k); [System.Windows.Controls.Grid]::SetColumn($lbl,0)
            $detGrid.Children.Add($lbl) | Out-Null

            if ($detSpec[$k].Kind -eq "bool") {
                $cb = New-Object System.Windows.Controls.ComboBox
                $cb.Height = 26
                $cb.HorizontalAlignment = "Left"
                $cb.VerticalContentAlignment = "Center"
                $cb.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2332")
                $cb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
                $cb.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
                $cb.BorderThickness = [System.Windows.Thickness]::new(1)
                $cb.Style = $dw.Resources["DarkDetailsCombo"]
                $cb.ItemContainerStyle = $dw.Resources["DarkDetailsComboItem"]
                $cb.Items.Add("") | Out-Null
                $cb.Items.Add("true") | Out-Null
                $cb.Items.Add("false") | Out-Null
                $v = [string]$detCur[$detSpec[$k].Key]
                if ($v -match '^(?i:true)$') { $cb.SelectedItem = "true" }
                elseif ($v -match '^(?i:false)$') { $cb.SelectedItem = "false" }
                else { $cb.SelectedIndex = 0 }
                Set-ComboDynamicSize -Combo $cb -MinChars 2
                [System.Windows.Controls.Grid]::SetRow($cb,$k); [System.Windows.Controls.Grid]::SetColumn($cb,1)
                $detGrid.Children.Add($cb) | Out-Null
                $ctrls["DET_" + $detSpec[$k].Key] = $cb
            } else {
                $tb = New-Object System.Windows.Controls.TextBox
                $tb.Text = [string]$detCur[$detSpec[$k].Key]
                $tb.Height = 26
                $tb.VerticalContentAlignment = "Center"
                $tb.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2332")
                $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
                $tb.CaretBrush = [System.Windows.Media.Brushes]::White
                $tb.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
                $tb.BorderThickness = [System.Windows.Thickness]::new(1)
                $tb.Padding = [System.Windows.Thickness]::new(6,0,6,0)
                [System.Windows.Controls.Grid]::SetRow($tb,$k); [System.Windows.Controls.Grid]::SetColumn($tb,1)
                $detGrid.Children.Add($tb) | Out-Null
                $ctrls["DET_" + $detSpec[$k].Key] = $tb
            }
        }
        # Replace AppIconPath row editor with textbox + browse button.
        $iconKeys = @($fieldSpec | ForEach-Object { $_.Key })
        $iconIdx = [array]::IndexOf($iconKeys, "AppIconPath")
        $leftGrid.Children.Remove($ctrls["AppIconPath"]) | Out-Null
        $iconGrid = New-Object System.Windows.Controls.Grid
        $ig0 = New-Object System.Windows.Controls.ColumnDefinition; $ig0.Width = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
        $ig1 = New-Object System.Windows.Controls.ColumnDefinition; $ig1.Width = [System.Windows.GridLength]::new(70)
        $iconGrid.ColumnDefinitions.Add($ig0); $iconGrid.ColumnDefinitions.Add($ig1)
        $iconTb = New-Object System.Windows.Controls.TextBox
        $iconTb.Text = [string]$cur["AppIconPath"]
        if ([string]::IsNullOrWhiteSpace($iconTb.Text)) {
            $autoIco = Find-PackageIcon -PackageRoot $packageRoot -FilesFolder $filesFolder
            if ($autoIco) { $iconTb.Text = $autoIco }
        }
        $iconTb.Height = 26
        $iconTb.VerticalContentAlignment = "Center"
        $iconTb.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2332")
        $iconTb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E5E7EB")
        $iconTb.CaretBrush = [System.Windows.Media.Brushes]::White
        $iconTb.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
        $iconTb.BorderThickness = [System.Windows.Thickness]::new(1)
        $iconTb.Padding = [System.Windows.Thickness]::new(6,0,6,0)
        [System.Windows.Controls.Grid]::SetColumn($iconTb,0)
        $iconGrid.Children.Add($iconTb) | Out-Null
        $iconBtn = New-Object System.Windows.Controls.Button
        $iconBtn.Content = "Browse"
        $iconBtn.Height = 26
        $iconBtn.Margin = [System.Windows.Thickness]::new(6,0,0,0)
        $iconBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#374151")
        $iconBtn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D1D5DB")
        $iconBtn.BorderThickness = [System.Windows.Thickness]::new(0)
        [System.Windows.Controls.Grid]::SetColumn($iconBtn,1)
        $iconGrid.Children.Add($iconBtn) | Out-Null
        [System.Windows.Controls.Grid]::SetRow($iconGrid,$iconIdx); [System.Windows.Controls.Grid]::SetColumn($iconGrid,1)
        $leftGrid.Children.Add($iconGrid) | Out-Null
        $ctrls["AppIconPath"] = $iconTb

        $previewBorder = New-Object System.Windows.Controls.Border
        $previewBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0B1624")
        $previewBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
        $previewBorder.BorderThickness = [System.Windows.Thickness]::new(1)
        $previewBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $previewBorder.MinHeight = 170
        $previewBorder.Margin = [System.Windows.Thickness]::new(0,10,0,0)
        $previewGrid = New-Object System.Windows.Controls.Grid
        $iconImage = New-Object System.Windows.Controls.Image
        $iconImage.Stretch = "Uniform"
        $iconImage.Margin = [System.Windows.Thickness]::new(8,8,8,8)
        $previewGrid.Children.Add($iconImage) | Out-Null
        $previewBorder.Child = $previewGrid
        [System.Windows.Controls.Grid]::SetRow($previewBorder,$fieldSpec.Count); [System.Windows.Controls.Grid]::SetColumn($previewBorder,0); [System.Windows.Controls.Grid]::SetColumnSpan($previewBorder,2)
        $leftGrid.Children.Add($previewBorder) | Out-Null

        $updatePreview = {
            param([string]$Path)
            try {
                if (![string]::IsNullOrWhiteSpace($Path) -and (Test-Path $Path)) {
                    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $bmp.BeginInit()
                    $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $bmp.UriSource = New-Object System.Uri($Path,[System.UriKind]::Absolute)
                    $bmp.EndInit()
                    $iconImage.Source = $bmp
                } else {
                    $iconImage.Source = $null
                }
            } catch {
                $iconImage.Source = $null
            }
        }
        & $updatePreview $iconTb.Text
        $iconTb.Add_TextChanged({ & $updatePreview $iconTb.Text })
        $iconBtn.Add_Click({
            $ofd = New-Object Microsoft.Win32.OpenFileDialog
            $ofd.Filter = "Image Files|*.ico;*.png;*.jpg;*.jpeg;*.bmp|All Files|*.*"
            if ($ofd.ShowDialog() -eq $true) { $iconTb.Text = $ofd.FileName; & $updatePreview $iconTb.Text }
        })

        $btnRow = New-Object System.Windows.Controls.StackPanel
        $btnRow.Orientation = "Horizontal"; $btnRow.HorizontalAlignment = "Right"; $btnRow.VerticalAlignment = "Center"; $btnRow.Margin = [System.Windows.Thickness]::new(0,8,0,0)
        [System.Windows.Controls.Grid]::SetRow($btnRow,1)
        $saveBtn = New-Object System.Windows.Controls.Button
        $saveBtn.Content = "Save App Details"; $saveBtn.Width = 130; $saveBtn.Height = 30; $saveBtn.Margin = [System.Windows.Thickness]::new(0,0,8,0)
        $saveBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0EA5E9")
        $saveBtn.Foreground = [System.Windows.Media.Brushes]::White; $saveBtn.BorderThickness = [System.Windows.Thickness]::new(0)
        $cancelBtn = New-Object System.Windows.Controls.Button
        $cancelBtn.Content = "Cancel"; $cancelBtn.Width = 90; $cancelBtn.Height = 30
        $cancelBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#374151")
        $cancelBtn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D1D5DB"); $cancelBtn.BorderThickness = [System.Windows.Thickness]::new(0)
        $btnTpl = @"
<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" TargetType="Button">
  <Border x:Name="bg" Background="{TemplateBinding Background}" CornerRadius="7">
    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
  </Border>
  <ControlTemplate.Triggers>
    <Trigger Property="IsMouseOver" Value="True">
      <Setter TargetName="bg" Property="Opacity" Value="0.9"/>
    </Trigger>
    <Trigger Property="IsPressed" Value="True">
      <Setter TargetName="bg" Property="Opacity" Value="0.8"/>
    </Trigger>
  </ControlTemplate.Triggers>
</ControlTemplate>
"@
        $btnTemplate = [Windows.Markup.XamlReader]::Parse($btnTpl)
        $saveBtn.Template = $btnTemplate
        $cancelBtn.Template = $btnTemplate
        $btnRow.Children.Add($saveBtn) | Out-Null
        $btnRow.Children.Add($cancelBtn) | Out-Null
        $g.Children.Add($btnRow) | Out-Null

        $cancelBtn.Add_Click({ $dw.Close() })
        $saveBtn.Add_Click({
            try {
                $d = @{
                }
                foreach ($f in $fieldSpec) {
                    $c = $ctrls[$f.Key]
                    if ($c -is [System.Windows.Controls.ComboBox]) {
                        $sv = if ($c.SelectedItem) { $c.SelectedItem.ToString() } else { "" }
                        if ($f.Key -eq "RequireAdmin") {
                            if ($sv -eq "true") { $d[$f.Key] = '$true' }
                            elseif ($sv -eq "false") { $d[$f.Key] = '$false' }
                            else { $d[$f.Key] = [string]$cur["RequireAdmin"] }
                        } else {
                            $d[$f.Key] = $sv
                        }
                    } else {
                        $tv = $c.Text.Trim()
                        if ($f.Key -eq "AppProcessesToClose" -and ($c.Tag -eq "hint" -or $tv -eq (Get-CloseProcessesExample))) {
                            $tv = "@()"
                        }
                        $d[$f.Key] = $tv
                    }
                }
                Save-AppDetailsToScript -ScriptPath $script:CW_ScriptPath -Details $d
                $sp = @{}
                foreach ($s in $saiwSpec) {
                    $c = $ctrls["SAIW_" + $s.Key]
                    if ($c -is [System.Windows.Controls.ComboBox]) {
                        $sv = if ($c.SelectedItem) { $c.SelectedItem.ToString() } else { "" }
                        if ($s.IsBool) {
                            if ($sv -eq "true") { $sp[$s.Key] = '$true' }
                            elseif ($sv -eq "false") { $sp[$s.Key] = '$false' }
                            else { $sp[$s.Key] = "" }
                        } else {
                            $sp[$s.Key] = $sv
                        }
                    } else {
                        if (($c.Tag -is [System.Collections.IDictionary]) -and $c.Tag["IsHint"]) { $sp[$s.Key] = "" }
                        else { $sp[$s.Key] = $c.Text.Trim() }
                    }
                }
                Save-SAIWParamsToScript -ScriptPath $script:CW_ScriptPath -Params $sp
                $dp = @{}
                foreach ($ds in $detSpec) {
                    $c = $ctrls["DET_" + $ds.Key]
                    if ($c -is [System.Windows.Controls.ComboBox]) {
                        $dp[$ds.Key] = if ($c.SelectedItem) { [string]$c.SelectedItem.ToString() } else { "" }
                    } else {
                        $dp[$ds.Key] = [string]$c.Text.Trim()
                    }
                }
                Save-DetectionConfigForScript -ScriptPath $script:CW_ScriptPath -Config $dp
                Normalize-PSADTTemplateSections -ScriptPath $script:CW_ScriptPath
                if ($d.AppName) { $Global:SelectedAppName = $d.AppName }
                if ($d.AppVersion) { $Global:SelectedVersion = $d.AppVersion }
                Set-Status "Application details and @saiwParams saved to script" "#10B981"
                Show-Msg("Application details and Show-ADTInstallationWelcome @saiwParams values saved in Invoke-AppDeployToolkit.ps1.",
                    "Saved",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
                $dw.Close()
            } catch {
                Show-Msg("Failed to save app details:`n`n$($_.Exception.Message)",
                    "Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
            }
        })
        $rootBorder = New-Object System.Windows.Controls.Border
        $rootBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0F1923")
        $rootBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D3F55")
        $rootBorder.BorderThickness = [System.Windows.Thickness]::new(1)
        $rootBorder.CornerRadius = [System.Windows.CornerRadius]::new(10)

        $rootGrid = New-Object System.Windows.Controls.Grid
        $rTitle = New-Object System.Windows.Controls.RowDefinition; $rTitle.Height = [System.Windows.GridLength]::new(38)
        $rBody  = New-Object System.Windows.Controls.RowDefinition; $rBody.Height  = [System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
        $rootGrid.RowDefinitions.Add($rTitle); $rootGrid.RowDefinitions.Add($rBody)

        $titleBar = New-Object System.Windows.Controls.Border
        $titleBar.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0A1118")
        $titleBar.CornerRadius = [System.Windows.CornerRadius]::new(10,10,0,0)
        [System.Windows.Controls.Grid]::SetRow($titleBar,0)
        $titleGrid = New-Object System.Windows.Controls.Grid
        $tc0 = New-Object System.Windows.Controls.ColumnDefinition
        $tc1 = New-Object System.Windows.Controls.ColumnDefinition; $tc1.Width = [System.Windows.GridLength]::new(36)
        $titleGrid.ColumnDefinitions.Add($tc0); $titleGrid.ColumnDefinitions.Add($tc1)
        $titleText = New-Object System.Windows.Controls.TextBlock
        $titleText.Text = "Application Details"
        $titleText.Foreground = [System.Windows.Media.Brushes]::White
        $titleText.FontSize = 12
        $titleText.Margin = [System.Windows.Thickness]::new(12,0,0,0)
        $titleText.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($titleText,0)
        $titleGrid.Children.Add($titleText) | Out-Null
        $closeBtn = New-Object System.Windows.Controls.Button
        $closeIcon = New-Object System.Windows.Controls.TextBlock
        $closeIcon.Text = [char]0xE8BB
        $closeIcon.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
        $closeIcon.FontSize = 10
        $closeIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D1D5DB")
        $closeBtn.Content = $closeIcon
        $closeBtn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D1D5DB")
        $closeBtn.Background = [System.Windows.Media.Brushes]::Transparent
        $closeBtn.BorderThickness = [System.Windows.Thickness]::new(0)
        $closeBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        [System.Windows.Controls.Grid]::SetColumn($closeBtn,1)
        $titleGrid.Children.Add($closeBtn) | Out-Null
        $titleBar.Child = $titleGrid
        $titleBar.Add_MouseLeftButtonDown({ $dw.DragMove() })
        $closeBtn.Add_Click({ $dw.Close() })

        [System.Windows.Controls.Grid]::SetRow($g,1)
        $rootGrid.Children.Add($titleBar) | Out-Null
        $rootGrid.Children.Add($g) | Out-Null
        $rootBorder.Child = $rootGrid
        $dw.Content = $rootBorder
        Apply-ComboAutoSize -Root $rootBorder -MinChars 2
        $dw.Add_ContentRendered({
            try { Apply-ComboAutoSize -Root $rootBorder -MinChars 2 } catch {}
        })
        $dw.ShowDialog() | Out-Null
    })

    $CW_OpenBtn.Add_Click({
        if (Test-Path $script:CW_ScriptPath) { Start-Process $script:CW_ScriptPath }
        else { Show-Msg("Script not found.","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null }
    })

    $CW_RepairBtn.Add_Click({
        if (!(Test-Path $script:CW_ScriptPath)) {
            Show-Msg("Script not found. Run Download first.","Not Found",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
        }
        $ans = Show-Msg("Reset script to the default PSADT template now?`n`nThis will fully replace current Invoke-AppDeployToolkit.ps1 content.",
            "Repair Script",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($ans -ne "Yes") { return }
        try {
            Show-LiveOutput
            Show-Progress
            Repair-PSADTGeneratedScript -ScriptPath $script:CW_ScriptPath
            Set-Status "Script reset to default template successfully" "#10B981"
            Show-Msg("Reset completed.`n`nInvoke-AppDeployToolkit.ps1 has been replaced with the default template.","Repair Complete",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
        } catch {
            Show-Msg("Repair failed:`n`n$($_.Exception.Message)","Repair Failed",
                [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
        } finally {
            Hide-Progress
        }
    })

    $CW_ClearBtn.Add_Click({
        $si = $script:CW_SectionCombo.SelectedItem
        $section = if ($si -is [System.Windows.Controls.ComboBoxItem]) { $si.Content } else { $si.ToString() }
        $res = Show-Msg("Clear all injected commands from $section section?",
            "Clear Section",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($res -ne "Yes") { return }
        $marker = Get-SectionMarker -Section $section
        $allM = @("## <Perform Pre-Installation tasks here>","## <Perform Installation tasks here>",
                  "## <Perform Post-Installation tasks here>","## <Perform Pre-Uninstallation tasks here>",
                  "## <Perform Uninstallation tasks here>","## <Perform Post-Uninstallation tasks here>",
                  "## <Perform Pre-Repair tasks here>","## <Perform Repair tasks here>","## <Perform Post-Repair tasks here>")
        $fl2 = [System.IO.File]::ReadAllLines($script:CW_ScriptPath,[System.Text.Encoding]::UTF8)
        $out3=[System.Collections.Generic.List[string]]::new(); $inBlk=$false
        try {
            if ($script:CFG_ProgressHost -is [System.Windows.Controls.Border]) {
                [System.Windows.Controls.Grid]::SetRow($script:CFG_ProgressHost, $script:CFG_ProgressHostOldRow)
                $script:CFG_ProgressHost.Margin = $script:CFG_ProgressHostOldMargin
                $script:CFG_ProgressHost.VerticalAlignment = $script:CFG_ProgressHostOldVA
            }
        } catch {}
        foreach ($fl in $fl2) {
            $t=$fl.Trim()
            if ($t -eq $marker) { $inBlk=$true }
            elseif ($inBlk -and $allM -contains $t) { $inBlk=$false }
            if (!$inBlk -or $t -eq $marker) { $out3.Add($fl) }
        }
        [System.IO.File]::WriteAllLines($script:CW_ScriptPath,$out3,[System.Text.Encoding]::UTF8)
        Set-Status "Cleared $section section" "#F59E0B"
    })

        Set-Status ("Configure ready  |  Loaded in {0} ms" -f $cfgSw.ElapsedMilliseconds) "#10B981"
        # Keep same global progress bar visible briefly so load feedback is clearly seen.
        try {
            $minMs = 1200
            $remain = $minMs - [int]$cfgSw.ElapsedMilliseconds
            if ($remain -gt 0) {
                $swv = [System.Diagnostics.Stopwatch]::StartNew()
                while ($swv.ElapsedMilliseconds -lt $remain) {
                    $null = $Window.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
                    Start-Sleep -Milliseconds 30
                }
            }
        } catch {}
        try { if ($script:CFG_ProgressPulse) { $script:CFG_ProgressPulse.Stop() } } catch {}
        Hide-Progress
        Hide-LiveOutput
        $cw.ShowDialog() | Out-Null
    } finally {
        try {
            if ($script:CFG_ProgressHost -is [System.Windows.Controls.Border]) {
                [System.Windows.Controls.Grid]::SetRow($script:CFG_ProgressHost, $script:CFG_ProgressHostOldRow)
                $script:CFG_ProgressHost.Margin = $script:CFG_ProgressHostOldMargin
                $script:CFG_ProgressHost.VerticalAlignment = $script:CFG_ProgressHostOldVA
            }
        } catch {}
        try { if ($script:CFG_ProgressPulse) { $script:CFG_ProgressPulse.Stop() } } catch {}
        Hide-Progress
        Hide-LiveOutput
    }
})

$GenerateBtn.Add_Click({
    Show-Progress
    $selected = $ResultsGrid.SelectedItem
    $ctx = Get-PackageContext $selected
    if (!$ctx -or !$ctx.HasPackage) {
        Hide-Progress
        Show-Msg("Download and Configure a package first.",
            "No Package",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
    }
    $Global:SelectedPackage = $ctx.PackageRoot
    if (!$Global:SelectedAppName) { $Global:SelectedAppName = $ctx.AppName }
    $Global:SelectedVersion = Resolve-BestAppVersion -SelectedItem $selected -Context $ctx
    $scriptPath   = $ctx.ScriptPath
    $outputFolder = $Global:OutputRoot

    if (!(Test-Path $scriptPath)) {
        Hide-Progress
        Show-Msg("Invoke-AppDeployToolkit.ps1 not found. Click Configure first.",
            "Not Configured",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null; return
    }
    if (!(Test-Path $Global:IntuneUtil)) {
        Hide-Progress
        $r = Show-Msg(
            "IntuneWinAppUtil.exe not found at:`n$($Global:IntuneUtil)`n`nPlace the tool in the Tools\ folder.`n`nOpen download page?",
            "Tool Not Found",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Question)
        if ($r -eq "Yes") { Start-Process "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases" }
        return
    }

    if (!(Test-Path $outputFolder)) { New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null }
    $script:GEN_OutputFolder  = $outputFolder
    $script:GEN_SelectedPkg   = $Global:SelectedPackage
    $script:GEN_TargetName    = Get-IntuneWinOutputName $Global:SelectedAppName $Global:SelectedVersion
    Write-DebugLog "INFO" ("GenerateClick | PackageRoot={0} | Script={1}" -f $Global:SelectedPackage,$scriptPath)

    Set-Status "Packaging .intunewin - please wait..." "#3B82F6"
    Show-Progress
    Show-LiveOutput
    Append-LiveOutput "Generate requested for package: $($Global:SelectedPackage)"
    Append-LiveOutput "Using output folder: $outputFolder"
    Append-LiveOutput "Target output name: $($script:GEN_TargetName)"

    try {
        $args2 = "-c `"$($script:GEN_SelectedPkg)`" -s `"$scriptPath`" -o `"$outputFolder`" -q"
        $script:GEN_Process = Start-Process -FilePath $Global:IntuneUtil -ArgumentList $args2 -PassThru -WindowStyle Hidden
        $Global:CurrentProcess = $script:GEN_Process
        Write-DebugLog "INFO" ("GenerateStart | Pid={0} | Args={1}" -f $script:GEN_Process.Id,$args2)
        Append-LiveOutput ">> $($Global:IntuneUtil) $args2"
        Append-LiveOutput "PID: $($script:GEN_Process.Id)"

        $script:GenTimer          = New-Object System.Windows.Threading.DispatcherTimer
        $script:GenTimer.Interval = [TimeSpan]::FromMilliseconds(800)
        $script:GenTimer.Add_Tick({
            if ($script:GEN_Process -and $script:GEN_Process.HasExited) {
                $script:GenTimer.Stop(); Hide-Progress
                Append-LiveOutput "IntuneWinAppUtil exited."
                $pkg = Get-ChildItem $script:GEN_OutputFolder -Filter "*.intunewin" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($pkg) {
                    $finalPkg = $pkg
                    $targetPath = Join-Path $script:GEN_OutputFolder $script:GEN_TargetName
                    if ($pkg.Name -ne $script:GEN_TargetName) {
                        try {
                            if (Test-Path $targetPath) { Remove-Item -LiteralPath $targetPath -Force -ErrorAction SilentlyContinue }
                            Rename-Item -LiteralPath $pkg.FullName -NewName $script:GEN_TargetName -Force
                            $finalPkg = Get-Item -LiteralPath $targetPath -ErrorAction SilentlyContinue
                            if (!$finalPkg) { $finalPkg = Get-Item -LiteralPath (Join-Path $script:GEN_OutputFolder $script:GEN_TargetName) -ErrorAction SilentlyContinue }
                            if ($finalPkg) {
                                Append-LiveOutput "Renamed output: $($finalPkg.Name)"
                            }
                        } catch {
                            Write-DebugLog "WARN" ("GenerateRenameFailed | From={0} | To={1} | {2}" -f $pkg.Name,$script:GEN_TargetName,$_.Exception.Message)
                            Append-LiveOutput "Rename failed, keeping: $($pkg.Name)"
                            $finalPkg = $pkg
                        }
                    }
                    Append-LiveOutput "Keeping package as generated by IntuneWinAppUtil (no internal metadata rewrite)."
                    Write-DebugLog "INFO" ("GenerateComplete | File={0}" -f $pkg.FullName)
                    Set-Status "Package ready: $($finalPkg.Name)" "#10B981"
                    Hide-LiveOutput
                    $op = Show-Msg(
                        ".intunewin created!`n`nFile     : $($finalPkg.Name)`nSaved to : $($script:GEN_OutputFolder)`n`nOpen output folder?",
                        "Package Complete",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Information)
                    if (Test-MsgResult -Result $op -Target "Yes") {
                        try {
                            $folderPath = if ($finalPkg -and $finalPkg.DirectoryName) { [string]$finalPkg.DirectoryName } else { [string]$script:GEN_OutputFolder }
                            $filePath   = if ($finalPkg -and $finalPkg.FullName) { [string]$finalPkg.FullName } else { "" }

                            if (![string]::IsNullOrWhiteSpace($filePath) -and (Test-Path -LiteralPath $filePath)) {
                                Start-Process -FilePath "explorer.exe" -ArgumentList "/select,`"$filePath`"" | Out-Null
                            } elseif (![string]::IsNullOrWhiteSpace($folderPath) -and (Test-Path -LiteralPath $folderPath)) {
                                Start-Process -FilePath "explorer.exe" -ArgumentList "`"$folderPath`"" | Out-Null
                            }
                        } catch {
                            try {
                                if ($script:GEN_OutputFolder -and (Test-Path -LiteralPath $script:GEN_OutputFolder)) {
                                    Start-Process -FilePath "explorer.exe" -ArgumentList "`"$($script:GEN_OutputFolder)`"" | Out-Null
                                }
                            } catch {}
                        }
                    }
                } else {
                    Write-DebugLog "WARN" ("GenerateCompleteNoOutput | OutputFolder={0}" -f $script:GEN_OutputFolder)
                    Append-LiveOutput "No .intunewin file found in output."
                    Set-Status ".intunewin not found after packaging - check IntuneWinAppUtil output" "#EF4444"
                    Show-Msg("Tool finished but no .intunewin found in:`n$($script:GEN_OutputFolder)",
                        "Package Issue",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
                }
            }
        })
        $script:GenTimer.Start()
    } catch {
        Write-DebugLog "ERROR" ("GenerateFailed | {0}" -f $_.Exception.Message)
        Append-LiveOutput "Generate failed: $($_.Exception.Message)"
        Hide-Progress; Set-Status "Packaging failed: $($_.Exception.Message)" "#EF4444"
        Show-Msg("Failed to run IntuneWinAppUtil:`n$($_.Exception.Message)",
            "Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$UploadBtn.Add_Click({
    Show-Progress
    $selected = $ResultsGrid.SelectedItem
    $ctx = Get-PackageContext $selected
    if (!$ctx -or !$ctx.HasPackage) {
        Hide-Progress
        Show-Msg("Download and configure a package first.",
            "No Package",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    $Global:SelectedPackage = $ctx.PackageRoot
    if (!$Global:SelectedAppName) { $Global:SelectedAppName = $ctx.AppName }
    $Global:SelectedVersion = Resolve-BestAppVersion -SelectedItem $selected -Context $ctx

    $outputFolder = $Global:OutputRoot
    if (!(Test-Path $outputFolder)) {
        Hide-Progress
        Show-Msg("Output folder not found. Generate .intunewin first.",
            "No Output",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    $targetName = Get-IntuneWinOutputName $Global:SelectedAppName $Global:SelectedVersion
    $targetPath = Join-Path $outputFolder $targetName
    $pkg = $null
    $chooseMode = Show-Msg(
        "Choose upload file mode:`n`nYes = Use expected generated file`nNo = Browse and select .intunewin from Output folder`n`nExpected:`n$targetPath",
        "Upload File Selection",
        [System.Windows.MessageBoxButton]::YesNoCancel,
        [System.Windows.MessageBoxImage]::Question
    )
    if ((Test-MsgResult -Result $chooseMode -Target "Cancel") -or
        (Test-MsgResult -Result $chooseMode -Target "None")) {
        Hide-Progress
        return
    }
    if (Test-MsgResult -Result $chooseMode -Target "No") {
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Title = "Select .intunewin package"
        $ofd.Filter = "Intune Package (*.intunewin)|*.intunewin|All Files (*.*)|*.*"
        $ofd.Multiselect = $false
        if (Test-Path $outputFolder) { $ofd.InitialDirectory = $outputFolder }
        $ofd.FileName = $targetName
        $pick = $ofd.ShowDialog($Window)
        if ($pick -ne $true -or [string]::IsNullOrWhiteSpace($ofd.FileName) -or !(Test-Path $ofd.FileName)) {
            Hide-Progress
            return
        }
        $pkg = Get-Item -LiteralPath $ofd.FileName -ErrorAction SilentlyContinue
    } else {
        $pkg = if (Test-Path $targetPath) { Get-Item -LiteralPath $targetPath -ErrorAction SilentlyContinue } else { $null }
        if (!$pkg) {
            Hide-Progress
            Show-Msg("Expected package file not found:`n$targetPath`n`nClick Generate .intunewin first, or choose No to browse and select another file.",
                "No Package File",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
    }

    $defaultName = if ($ResultsGrid.SelectedItem -and $ResultsGrid.SelectedItem.Name) {
        [string]$ResultsGrid.SelectedItem.Name
    } else {
        [string]$ctx.AppName
    }

    Write-DebugLog "INFO" ("UploadClick | File={0}" -f $pkg.FullName)
    Set-Status "Launching Intune upload assistant..." "#3B82F6"
    Show-LiveOutput
    Append-LiveOutput "Upload requested: $($pkg.FullName)"
    Append-LiveOutput "Starting Intune upload assistant window..."

    $publisherDefault = "Unknown Publisher"
    $descDefault = if ($Global:SelectedVersion) { "$defaultName $($Global:SelectedVersion) uploaded by WinGet-PSADT GUI Tool" } else { "$defaultName uploaded by WinGet-PSADT GUI Tool" }
    $appVersionDefault = if ($Global:SelectedVersion) { [string]$Global:SelectedVersion } else { "" }
    $infoUrlDefault = ""
    $privacyUrlDefault = ""
    $developerDefault = ""
    $ownerDefault = ""
    $notesDefault = ""
    $det = Get-AppDetailsFromScript -ScriptPath (Join-Path $Global:SelectedPackage "Invoke-AppDeployToolkit.ps1") -AppName $defaultName -Version $Global:SelectedVersion
    if ($det.AppVendor) { $publisherDefault = $det.AppVendor }
    if ($det.AppVersion) { $descDefault = "$defaultName $($det.AppVersion) uploaded by WinGet-PSADT GUI Tool" }
    if ($det.AppVersion) { $appVersionDefault = [string]$det.AppVersion }
    if ($det.AppVendor) { $developerDefault = [string]$det.AppVendor; $ownerDefault = [string]$det.AppVendor }
    $pkgInfo = if ($selected -and $selected.ID) { Get-WingetPackageInfo -PackageId ([string]$selected.ID) } else { $null }
    if ($pkgInfo) {
        if ($pkgInfo.Publisher -and ($publisherDefault -eq "Unknown Publisher")) { $publisherDefault = [string]$pkgInfo.Publisher }
        if ($pkgInfo.Version -and [string]::IsNullOrWhiteSpace($appVersionDefault)) { $appVersionDefault = [string]$pkgInfo.Version }
        if ($pkgInfo.InformationUrl) { $infoUrlDefault = [string]$pkgInfo.InformationUrl }
        if ($pkgInfo.PrivacyUrl) { $privacyUrlDefault = [string]$pkgInfo.PrivacyUrl }
        if ($pkgInfo.Developer -and [string]::IsNullOrWhiteSpace($developerDefault)) { $developerDefault = [string]$pkgInfo.Developer }
        if ($pkgInfo.Owner -and [string]::IsNullOrWhiteSpace($ownerDefault)) { $ownerDefault = [string]$pkgInfo.Owner }
        if ($pkgInfo.Notes) { $notesDefault = [string]$pkgInfo.Notes }
    }
    if ([string]::IsNullOrWhiteSpace($developerDefault) -and $publisherDefault -and $publisherDefault -ne "Unknown Publisher") { $developerDefault = $publisherDefault }
    if ([string]::IsNullOrWhiteSpace($ownerDefault) -and $publisherDefault -and $publisherDefault -ne "Unknown Publisher") { $ownerDefault = $publisherDefault }
    $iconToUse = if ($det.AppIconPath -and (Test-Path $det.AppIconPath)) { $det.AppIconPath } else { Find-PackageIcon -PackageRoot $Global:SelectedPackage -FilesFolder (Join-Path $Global:SelectedPackage "Files") }
    $detCfg = Get-DetectionConfigForScript -ScriptPath (Join-Path $Global:SelectedPackage "Invoke-AppDeployToolkit.ps1") -AppName $defaultName -AppVersion $appVersionDefault
    $detNameRegexPreview = if ([string]::IsNullOrWhiteSpace([string]$detCfg.DetectionNameRegex)) { '^' + [regex]::Escape([string]$defaultName) + '(?:\s|$)' } else { [string]$detCfg.DetectionNameRegex }
    $detUseVersionPreview = if ([string]::IsNullOrWhiteSpace([string]$detCfg.DetectionUseVersion)) {
        -not [string]::IsNullOrWhiteSpace([string]$appVersionDefault)
    } else {
        [System.Convert]::ToBoolean([string]$detCfg.DetectionUseVersion)
    }
    $detVersionPreview = if ([string]::IsNullOrWhiteSpace([string]$detCfg.DetectionVersion)) { [string]$appVersionDefault } else { [string]$detCfg.DetectionVersion }
    $detRootsPreview = @()
    if (![string]::IsNullOrWhiteSpace([string]$detCfg.DetectionRegistryRoots)) {
        $detRootsPreview = @(([string]$detCfg.DetectionRegistryRoots) -split ';' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    if ($detRootsPreview.Count -eq 0) {
        $detRootsPreview = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    Append-LiveOutput "Detection rule preview:"
    Append-LiveOutput ("  NameRegex      : {0}" -f $detNameRegexPreview)
    Append-LiveOutput ("  UseVersion     : {0}" -f $detUseVersionPreview)
    Append-LiveOutput ("  Version        : {0}" -f $detVersionPreview)
    Append-LiveOutput ("  RegistryRoots  : {0}" -f ($detRootsPreview -join ';'))
    Append-LiveOutput "  Script logic   :"
    Append-LiveOutput "    `$roots = @(...)"
    Append-LiveOutput "    `$apps  = foreach (`$r in `$roots) { Get-ItemProperty -Path `$r -ErrorAction SilentlyContinue }"
    Append-LiveOutput ("    `$hits  = `$apps | Where-Object {{ `$_.DisplayName -and (`$_.DisplayName -match '{0}') }}" -f $detNameRegexPreview)
    if ($detUseVersionPreview -and ![string]::IsNullOrWhiteSpace($detVersionPreview)) {
        Append-LiveOutput ("    `$hits  = `$hits | Where-Object {{ [string]`$_.DisplayVersion -eq '{0}' }}" -f $detVersionPreview)
    }
    Append-LiveOutput "    if (`$hits) { exit 0 } else { exit 1 }"
    $ua = Start-IntuneUploadAssistant `
        -PackageRoot $Global:SelectedPackage `
        -IntuneWinPath $pkg.FullName `
        -DefaultDisplayName $defaultName `
        -DefaultPublisher $publisherDefault `
        -DefaultDescription $descDefault `
        -IconPath $iconToUse `
        -DefaultAppVersion $appVersionDefault `
        -DefaultInformationUrl $infoUrlDefault `
        -DefaultPrivacyUrl $privacyUrlDefault `
        -DefaultDeveloper $developerDefault `
        -DefaultOwner $ownerDefault `
        -DefaultNotes $notesDefault `
        -DetectionNameRegex ([string]$detCfg.DetectionNameRegex) `
        -DetectionUseVersion ([string]$detCfg.DetectionUseVersion) `
        -DetectionVersion ([string]$detCfg.DetectionVersion) `
        -DetectionRegistryRoots ([string]$detCfg.DetectionRegistryRoots)
    if ($ua -and $ua.Started -and $ua.Process) {
        $script:UP_Process = $ua.Process
        $script:UP_LogPath = $ua.LogPath
        $script:UP_LastLine = 0
        $Global:CurrentProcess = $script:UP_Process
        Show-Progress
        Set-Status "Uploading to Intune... complete auth in browser if prompted." "#3B82F6"
        Append-LiveOutput ("Upload process started (PID: {0})" -f $script:UP_Process.Id)
        Append-LiveOutput "Waiting for authentication and upload progress..."
        if ($script:UploadTimer) { try { $script:UploadTimer.Stop() } catch {} }
        $script:UploadTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:UploadTimer.Interval = [TimeSpan]::FromMilliseconds(900)
        $script:UploadTimer.Add_Tick({
            try {
                if ($script:UP_LogPath -and (Test-Path $script:UP_LogPath)) {
                    $all = [System.IO.File]::ReadAllLines($script:UP_LogPath,[System.Text.Encoding]::UTF8)
                    if ($all.Count -gt $script:UP_LastLine) {
                        $new = $all[$script:UP_LastLine..($all.Count-1)]
                        $script:UP_LastLine = $all.Count
                        foreach ($ln in $new) {
                            if (![string]::IsNullOrWhiteSpace($ln)) { Append-LiveOutput $ln }
                        }
                    }
                }
                if ($script:UP_Process -and $script:UP_Process.HasExited) {
                    $script:UploadTimer.Stop()
                    Hide-Progress
                    $code = $script:UP_Process.ExitCode
                    if ($code -eq 0) {
                        Set-Status "Intune upload completed successfully." "#10B981"
                        $intuneUrl = ""
                        $graphUrl = ""
                        if ($script:UP_LogPath -and (Test-Path $script:UP_LogPath)) {
                            try {
                                $tail = Get-Content -LiteralPath $script:UP_LogPath -Tail 200 -ErrorAction SilentlyContinue
                                $iu = $tail | Where-Object { $_ -match "Intune URL\s*:\s*" } | Select-Object -Last 1
                                $gu = $tail | Where-Object { $_ -match "Graph URL\s*:\s*" } | Select-Object -Last 1
                                if ($iu) { $intuneUrl = ($iu -replace '.*Intune URL\s*:\s*','').Trim() }
                                if ($gu) { $graphUrl = ($gu -replace '.*Graph URL\s*:\s*','').Trim() }
                            } catch {}
                        }
                        $msg = "Upload completed successfully."
                        if ($intuneUrl) { $msg += "`n`nIntune URL:`n$intuneUrl" }
                        if ($graphUrl) { $msg += "`n`nGraph URL:`n$graphUrl" }
                        Show-Msg($msg,"Upload Complete",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information) | Out-Null
                    } else {
                        Set-Status ("Intune upload failed (exit code {0}). Check logs." -f $code) "#EF4444"
                        Show-Msg("Upload failed (exit code $code).`n`nCheck Logs for details.","Upload Failed",
                            [System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
                    }
                }
            } catch {}
        })
        $script:UploadTimer.Start()
        Set-Status "Intune upload started. Follow browser sign-in if prompted." "#3B82F6"
    } else {
        Hide-Progress
        Append-LiveOutput "Failed to start upload assistant."
        Set-Status "Failed to start Intune upload assistant" "#EF4444"
        Show-Msg(
            "Could not start the Intune upload assistant.`n`n$($ua.Error)`n`nCheck Logs for details.",
            "Upload Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
})

Write-DebugLog "INFO" "MainWindowShowDialogStart"
Apply-ComboAutoSize -Root $Window -MinChars 8
 $Window.Add_ContentRendered({
     try {
         $null = $Window.Dispatcher.BeginInvoke([action]{
             try {
                 $SearchBox.Focus() | Out-Null
                 [System.Windows.Input.Keyboard]::Focus($SearchBox) | Out-Null
             } catch {}
         }, [System.Windows.Threading.DispatcherPriority]::Input)
     } catch {}
 })
$Window.ShowDialog() | Out-Null
Write-DebugLog "INFO" "MainWindowShowDialogEnd"
return
