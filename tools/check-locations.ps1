param(
    [string]$MapDataPath = (Join-Path $PSScriptRoot '..\in_game\map_data'),
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

function Set-ProgressStep {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Percent,
        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    Write-Progress -Id 1 -Activity 'Checking locations' -Status $Status -PercentComplete $Percent
}

function Get-NamedLocationEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Get-Content -Path $Path | ForEach-Object {
        if ($_ -match '^\s*([^=]+?)\s*=\s*([0-9A-Fa-f]{6,8})\s*$') {
            [PSCustomObject]@{
                Name = $matches[1].Trim()
                Hex  = $matches[2].Substring(0, 6).ToUpper()
            }
        }
    } | Where-Object { $_ }
}

function Get-DefinitionsNames {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Get-Content -Path $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -and $line -notmatch '^#' -and $line -notmatch '=\s*\{' -and $line -notmatch '^\}$') {
            $line -split '\s+' | Where-Object { $_ }
        }
    } | Where-Object { $_ }
}

function Get-DefinitionsStructureNames {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $result = [ordered]@{
        Continent    = New-Object System.Collections.Generic.List[string]
        Subcontinent = New-Object System.Collections.Generic.List[string]
        Region       = New-Object System.Collections.Generic.List[string]
        Area         = New-Object System.Collections.Generic.List[string]
        Province     = New-Object System.Collections.Generic.List[string]
    }

    $depth = 0
    foreach ($line in Get-Content -Path $Path) {
        if ($line -match '^\s*([^=\s#][^=]*?)\s*=\s*\{') {
            $name = $matches[1].Trim()
            switch ($depth) {
                0 { $null = $result.Continent.Add($name) }
                1 { $null = $result.Subcontinent.Add($name) }
                2 { $null = $result.Region.Add($name) }
                3 { $null = $result.Area.Add($name) }
                4 { $null = $result.Province.Add($name) }
            }
        }

        $opens = ([regex]::Matches($line, '\{')).Count
        $closes = ([regex]::Matches($line, '\}')).Count
        $depth += $opens - $closes
    }

    $result
}

function Get-TemplateNames {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Get-Content -Path $Path | ForEach-Object {
        if ($_ -match '^\s*([^=\s#][^=]*?)\s*=') {
            $matches[1].Trim()
        }
    } | Where-Object { $_ }
}

function Repair-Mojibake {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($Value)
    [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Write-StatusLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Level,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Output ("[{0}] {1}" -f $Level.ToUpper(), $Message)
}

function Get-ImageHexColors {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$ProgressId = 1,
        [string]$ProgressActivity = 'Checking locations'
    )

    if (-not ('MapColorReader' -as [type])) {
        Add-Type -Language CSharp -ReferencedAssemblies System.Drawing @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class MapColorReader {
    public static int GetHeight(string path) {
        using (var bmp = new Bitmap(path)) {
            return bmp.Height;
        }
    }

    public static string[] ReadUniqueHexColorsChunk(string path, int startY, int rowCount) {
        using (var bmp = new Bitmap(path)) {
            int safeRowCount = Math.Min(rowCount, bmp.Height - startY);
            var rect = new Rectangle(0, startY, bmp.Width, safeRowCount);
            var data = bmp.LockBits(rect, ImageLockMode.ReadOnly, bmp.PixelFormat);
            try {
                int stride = Math.Abs(data.Stride);
                int len = stride * safeRowCount;
                byte[] bytes = new byte[len];
                Marshal.Copy(data.Scan0, bytes, 0, len);

                var set = new HashSet<int>();
                var palette = bmp.Palette;
                for (int y = 0; y < safeRowCount; y++) {
                    int row = y * stride;
                    if (bmp.PixelFormat == PixelFormat.Format24bppRgb) {
                        for (int x = 0; x < bmp.Width; x++) {
                            int i = row + x * 3;
                            int rgb = (bytes[i + 2] << 16) | (bytes[i + 1] << 8) | bytes[i];
                            set.Add(rgb);
                        }
                    }
                    else if (
                        bmp.PixelFormat == PixelFormat.Format32bppArgb ||
                        bmp.PixelFormat == PixelFormat.Format32bppRgb ||
                        bmp.PixelFormat == PixelFormat.Format32bppPArgb) {
                        for (int x = 0; x < bmp.Width; x++) {
                            int i = row + x * 4;
                            int rgb = (bytes[i + 2] << 16) | (bytes[i + 1] << 8) | bytes[i];
                            set.Add(rgb);
                        }
                    }
                    else if (bmp.PixelFormat == PixelFormat.Format8bppIndexed) {
                        for (int x = 0; x < bmp.Width; x++) {
                            Color c = palette.Entries[bytes[row + x]];
                            int rgb = (c.R << 16) | (c.G << 8) | c.B;
                            set.Add(rgb);
                        }
                    }
                    else if (bmp.PixelFormat == PixelFormat.Format4bppIndexed) {
                        for (int x = 0; x < bmp.Width; x++) {
                            int b = bytes[row + (x / 2)];
                            int index = ((x & 1) == 0) ? ((b >> 4) & 0x0F) : (b & 0x0F);
                            Color c = palette.Entries[index];
                            int rgb = (c.R << 16) | (c.G << 8) | c.B;
                            set.Add(rgb);
                        }
                    }
                    else {
                        for (int x = 0; x < bmp.Width; x++) {
                            Color c = bmp.GetPixel(x, startY + y);
                            int rgb = (c.R << 16) | (c.G << 8) | c.B;
                            set.Add(rgb);
                        }
                    }
                }

                var result = new string[set.Count];
                int idx = 0;
                foreach (int rgb in set) {
                    result[idx++] = rgb.ToString("X6");
                }
                Array.Sort(result, StringComparer.Ordinal);
                return result;
            }
            finally {
                bmp.UnlockBits(data);
            }
        }
    }
}
"@
    }

    $resolvedPath = (Resolve-Path $Path).Path
    $height = [MapColorReader]::GetHeight($resolvedPath)
    $rowChunk = 256
    $set = New-Object 'System.Collections.Generic.HashSet[string]'

    for ($startY = 0; $startY -lt $height; $startY += $rowChunk) {
        $rows = [Math]::Min($rowChunk, $height - $startY)
        $chunk = [MapColorReader]::ReadUniqueHexColorsChunk($resolvedPath, $startY, $rows)
        foreach ($hex in $chunk) {
            $null = $set.Add($hex)
        }

        $percent = 35 + [int](20 * (($startY + $rows) / $height))
        Write-Progress -Id $ProgressId -Activity $ProgressActivity -Status ("Reading locations.png colors ({0}/{1} rows)" -f ($startY + $rows), $height) -PercentComplete $percent
    }

    @($set) | Sort-Object
}

$namedLocationsPath = Join-Path $MapDataPath 'named_locations\00_default.txt'
$locationsImagePath = Join-Path $MapDataPath 'locations.png'
$definitionsPath = Join-Path $MapDataPath 'definitions.txt'
$templatesPath = Join-Path $MapDataPath 'location_templates.txt'

if (-not (Test-Path -LiteralPath $namedLocationsPath)) {
    throw "Missing named locations file: $namedLocationsPath"
}

if (-not (Test-Path -LiteralPath $locationsImagePath)) {
    throw "Missing locations image: $locationsImagePath"
}

$hasDefinitions = Test-Path -LiteralPath $definitionsPath
$hasTemplates = Test-Path -LiteralPath $templatesPath

Set-ProgressStep -Percent 10 -Status 'Reading named locations'
$entries = @(Get-NamedLocationEntries -Path $namedLocationsPath)
$duplicateHexGroups = @($entries | Group-Object Hex | Where-Object Count -gt 1 | Sort-Object Name)

$textHex = @($entries.Hex | Sort-Object -Unique)
$defaultNames = @($entries.Name | Sort-Object -Unique)

$imageHex = @(Get-ImageHexColors -Path $locationsImagePath -ProgressId 1 -ProgressActivity 'Checking locations')

$imageOnly = @($imageHex | Where-Object { $_ -notin $textHex })
$textOnly = @($textHex | Where-Object { $_ -notin $imageHex })

$definitionsNames = @()
$definitionsOnly = @()
$defaultOnly = @()
$structureDuplicateGroups = @()
$definitionsLocationDuplicateGroups = @()
if ($hasDefinitions) {
    Set-ProgressStep -Percent 55 -Status 'Reading definitions.txt'
    $definitionsNamesRaw = @(Get-DefinitionsNames -Path $definitionsPath)
    $definitionsLocationDuplicateGroups = @($definitionsNamesRaw | Group-Object | Where-Object Count -gt 1 | Sort-Object Name)
    $definitionsNames = @($definitionsNamesRaw | Sort-Object -Unique)
    $definitionsOnly = @($definitionsNames | Where-Object { $_ -notin $defaultNames })
    $defaultOnly = @($defaultNames | Where-Object { $_ -notin $definitionsNames })

    $structureNames = Get-DefinitionsStructureNames -Path $definitionsPath
    foreach ($category in @('Continent', 'Subcontinent', 'Region', 'Area', 'Province')) {
        $groups = @($structureNames[$category] | Group-Object | Where-Object Count -gt 1 | Sort-Object Name)
        foreach ($group in $groups) {
            $structureDuplicateGroups += [PSCustomObject]@{
                Category = $category
                Name     = $group.Name
                Count    = $group.Count
            }
        }
    }
}

$templateNames = @()
$templateMissing = @()
$templateExtra = @()
if ($hasTemplates) {
    Set-ProgressStep -Percent 75 -Status 'Reading location_templates.txt'
    $templateNames = @(Get-TemplateNames -Path $templatesPath | ForEach-Object { Repair-Mojibake $_ } | Sort-Object -Unique)
    $templateMissing = @($defaultNames | Where-Object { $_ -notin $templateNames })
    $templateExtra = @($templateNames | Where-Object { $_ -notin $defaultNames })
}

Set-ProgressStep -Percent 90 -Status 'Preparing report'
Write-Output "Map data path: $MapDataPath"
Write-Output "Named entries: $($entries.Count)"
Write-Output "Unique named locations: $($defaultNames.Count)"
Write-Output "Unique text HEX values: $($textHex.Count)"
Write-Output "Unique image colors: $($imageHex.Count)"
if ($hasDefinitions) {
    Write-Output "Unique definitions locations: $($definitionsNames.Count)"
    Write-Output "Duplicate definitions location names: $($definitionsLocationDuplicateGroups.Count)"
    Write-Output "Duplicate definitions structure names: $($structureDuplicateGroups.Count)"
}
if ($hasTemplates) {
    Write-Output "Unique template locations: $($templateNames.Count)"
}
Write-Output ''

if ($duplicateHexGroups.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'Duplicate HEX values: none'
}
else {
    Write-StatusLine -Level 'ERROR' -Message "Duplicate HEX values: $($duplicateHexGroups.Count)"
    foreach ($group in $duplicateHexGroups) {
        $names = ($group.Group | ForEach-Object Name) -join ', '
        Write-Output "  $($group.Name) -> $names"
    }
}

Write-Output ''

if ($imageOnly.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'Colors in locations.png but missing from 00_default.txt: none'
}
else {
    Write-StatusLine -Level 'ERROR' -Message "Colors in locations.png but missing from 00_default.txt: $($imageOnly.Count)"
    $imageOnly | ForEach-Object { Write-Output "  $_" }
}

Write-Output ''

if ($textOnly.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'Colors in 00_default.txt but missing from locations.png: none'
}
else {
    Write-StatusLine -Level 'ERROR' -Message "Colors in 00_default.txt but missing from locations.png: $($textOnly.Count)"
    $textOnly | ForEach-Object { Write-Output "  $_" }
}

Write-Output ''

if (-not $hasDefinitions) {
    Write-StatusLine -Level 'WARNING' -Message 'definitions.txt check: skipped (file missing)'
}
elseif ($definitionsOnly.Count -eq 0 -and $defaultOnly.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message '00_default.txt and definitions.txt location names: match'
}
else {
    Write-StatusLine -Level 'ERROR' -Message '00_default.txt and definitions.txt location names: mismatch'
    Write-Output "  Missing from 00_default.txt: $($definitionsOnly.Count)"
    $definitionsOnly | ForEach-Object { Write-Output "    $_" }
    Write-Output "  Missing from definitions.txt: $($defaultOnly.Count)"
    $defaultOnly | ForEach-Object { Write-Output "    $_" }
}

Write-Output ''

if (-not $hasDefinitions) {
    Write-StatusLine -Level 'WARNING' -Message 'definitions.txt duplicate location names: skipped (file missing)'
}
elseif ($definitionsLocationDuplicateGroups.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'definitions.txt duplicate location names: none'
}
else {
    Write-StatusLine -Level 'ERROR' -Message 'definitions.txt duplicate location names: found'
    foreach ($group in $definitionsLocationDuplicateGroups) {
        Write-Output "  $($group.Name) x$($group.Count)"
    }
}

Write-Output ''

if (-not $hasDefinitions) {
    Write-StatusLine -Level 'WARNING' -Message 'definitions.txt structure duplicates: skipped (file missing)'
}
elseif ($structureDuplicateGroups.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'definitions.txt structure duplicates: none'
}
else {
    Write-StatusLine -Level 'ERROR' -Message 'definitions.txt structure duplicates: found'
    foreach ($group in $structureDuplicateGroups) {
        Write-Output "  $($group.Category): $($group.Name) x$($group.Count)"
    }
}

Write-Output ''

if (-not $hasTemplates) {
    Write-StatusLine -Level 'WARNING' -Message 'location_templates.txt coverage: file missing'
}
elseif ($templateMissing.Count -eq 0 -and $templateExtra.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'location_templates.txt coverage: none'
}
else {
    Write-StatusLine -Level 'WARNING' -Message 'location_templates.txt coverage: names do not fully match 00_default.txt'
    Write-Output "  Missing from location_templates.txt: $($templateMissing.Count)"
    $templateMissing | ForEach-Object { Write-Output "    $_" }
    Write-Output "  Extra in location_templates.txt: $($templateExtra.Count)"
    $templateExtra | ForEach-Object { Write-Output "    $_" }
}

if ($duplicateHexGroups.Count -gt 0 -or $imageOnly.Count -gt 0 -or $textOnly.Count -gt 0) {
    $exitCode = 1
}
elseif ($hasDefinitions -and ($definitionsOnly.Count -gt 0 -or $defaultOnly.Count -gt 0 -or $definitionsLocationDuplicateGroups.Count -gt 0 -or $structureDuplicateGroups.Count -gt 0)) {
    $exitCode = 1
}
else {
    $exitCode = 0
}

if ($exitCode -eq 0) {
    Write-Output ''
    Write-StatusLine -Level 'OK' -Message 'locations.png, 00_default.txt, and definitions.txt are consistent.'
}
else {
    Write-Output ''
    Write-StatusLine -Level 'ERROR' -Message 'One or more required checks failed.'
}

if (-not $NoPause) {
    Write-Output ''
    Read-Host 'Press Enter to close'
}

Write-Progress -Id 1 -Activity 'Checking locations' -Completed
exit $exitCode
