function Show-AppDetailsWindow {
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
    
}
