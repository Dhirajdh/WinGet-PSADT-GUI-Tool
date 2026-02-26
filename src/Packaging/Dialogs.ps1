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

