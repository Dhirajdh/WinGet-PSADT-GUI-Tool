function Show-ConfigureWindow {
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
        Show-AppDetailsWindow
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
}

