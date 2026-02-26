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

