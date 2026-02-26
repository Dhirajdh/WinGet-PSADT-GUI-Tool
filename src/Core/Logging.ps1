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

