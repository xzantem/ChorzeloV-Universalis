param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 1000)]
    [int]$Count,

    [string]$MapDataPath,

    [ValidateRange(0, 100)]
    [int]$PreviewValue = 100,

    [ValidateRange(0, 100)]
    [int]$MinSaturation = 25,

    [ValidateRange(0, 4)]
    [int]$Precision = 0,

    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

if (-not ([System.Management.Automation.PSTypeName]'LocationColorRowSearch').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Globalization;

public class HsCandidateResult {
    public double H { get; set; }
    public double S { get; set; }
    public double Score { get; set; }
}

public static class LocationColorRowSearch {
    private static string MakeKey(double hue, double saturation, int precision) {
        double roundedHue = Math.Round(((hue % 360.0) + 360.0) % 360.0, precision);
        if (roundedHue >= 360.0) {
            roundedHue = 0.0;
        }

        double roundedSaturation = Math.Round(Math.Max(0.0, Math.Min(100.0, saturation)), precision);
        string format = "F" + precision.ToString(CultureInfo.InvariantCulture);
        return roundedHue.ToString(format, CultureInfo.InvariantCulture) + ":" +
               roundedSaturation.ToString(format, CultureInfo.InvariantCulture);
    }

    private static double Distance(double h1, double s1, double h2, double s2) {
        double hueDelta = Math.Abs(h1 - h2);
        if (hueDelta > 180.0) {
            hueDelta = 360.0 - hueDelta;
        }

        double scaledHueDelta = hueDelta / 3.6;
        double saturationDelta = Math.Abs(s1 - s2);
        return Math.Sqrt((scaledHueDelta * scaledHueDelta) + (saturationDelta * saturationDelta));
    }

    public static HsCandidateResult FindBestInHueRow(
        int hue,
        double[] currentHues,
        double[] currentSaturations,
        HashSet<string> blockedKeys,
        int precision,
        int minSaturation
    ) {
        HsCandidateResult best = null;

        for (int saturation = minSaturation; saturation <= 100; saturation++) {
            string key = MakeKey(hue, saturation, precision);
            if (blockedKeys.Contains(key)) {
                continue;
            }

            double score = double.PositiveInfinity;
            for (int i = 0; i < currentHues.Length; i++) {
                double distance = Distance(hue, saturation, currentHues[i], currentSaturations[i]);
                if (distance < score) {
                    score = distance;
                }
            }

            if (best == null ||
                score > best.Score ||
                (score == best.Score && (hue < best.H || (hue == best.H && saturation < best.S)))) {
                best = new HsCandidateResult {
                    H = hue,
                    S = saturation,
                    Score = score
                };
            }
        }

        return best;
    }
}
"@
}

if (-not $MapDataPath) {
    $MapDataPath = Join-Path $PSScriptRoot '..\in_game\map_data'
}

function Set-ProgressStep {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Percent,
        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    Write-Progress -Id 1 -Activity 'Suggesting location colors' -Status $Status -PercentComplete $Percent
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

function Get-NamedLocationHexColors {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Get-Content -Path $Path | ForEach-Object {
        if ($_ -match '^\s*[^=]+=\s*([0-9A-Fa-f]{6,8})\s*$') {
            $matches[1].Substring(0, 6).ToUpper()
        }
    } | Where-Object { $_ }
}

function Convert-HexToRgb {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Hex
    )

    [PSCustomObject]@{
        R = [Convert]::ToInt32($Hex.Substring(0, 2), 16)
        G = [Convert]::ToInt32($Hex.Substring(2, 2), 16)
        B = [Convert]::ToInt32($Hex.Substring(4, 2), 16)
    }
}

function Convert-RgbToHsv {
    param(
        [Parameter(Mandatory = $true)]
        [int]$R,
        [Parameter(Mandatory = $true)]
        [int]$G,
        [Parameter(Mandatory = $true)]
        [int]$B
    )

    # PowerShell variable names are case-insensitive, so keep the normalized
    # channels distinct from the typed R/G/B parameters.
    $redUnit = $R / 255.0
    $greenUnit = $G / 255.0
    $blueUnit = $B / 255.0

    $maxChannel = $redUnit
    if ($greenUnit -gt $maxChannel) { $maxChannel = $greenUnit }
    if ($blueUnit -gt $maxChannel) { $maxChannel = $blueUnit }

    $minChannel = $redUnit
    if ($greenUnit -lt $minChannel) { $minChannel = $greenUnit }
    if ($blueUnit -lt $minChannel) { $minChannel = $blueUnit }
    $delta = $maxChannel - $minChannel

    $h = 0.0
    if ($delta -ne 0) {
        if ($maxChannel -eq $redUnit) {
            $h = 60.0 * ((($greenUnit - $blueUnit) / $delta) % 6.0)
        }
        elseif ($maxChannel -eq $greenUnit) {
            $h = 60.0 * ((($blueUnit - $redUnit) / $delta) + 2.0)
        }
        else {
            $h = 60.0 * ((($redUnit - $greenUnit) / $delta) + 4.0)
        }
    }

    if ($h -lt 0) {
        $h += 360.0
    }

    $s = if ($maxChannel -eq 0) { 0.0 } else { ($delta / $maxChannel) * 100.0 }
    $v = $maxChannel * 100.0

    [PSCustomObject]@{
        H = $h
        S = $s
        V = $v
    }
}

function Convert-HsvToHex {
    param(
        [Parameter(Mandatory = $true)]
        [double]$H,
        [Parameter(Mandatory = $true)]
        [double]$S,
        [Parameter(Mandatory = $true)]
        [double]$V
    )

    $h = (($H % 360) + 360) % 360
    $s = [Math]::Max(0.0, [Math]::Min(100.0, $S)) / 100.0
    $v = [Math]::Max(0.0, [Math]::Min(100.0, $V)) / 100.0

    $c = $v * $s
    $x = $c * (1 - [Math]::Abs((($h / 60.0) % 2) - 1))
    $m = $v - $c

    $r1 = 0.0
    $g1 = 0.0
    $b1 = 0.0

    if ($h -lt 60) {
        $r1, $g1, $b1 = $c, $x, 0
    }
    elseif ($h -lt 120) {
        $r1, $g1, $b1 = $x, $c, 0
    }
    elseif ($h -lt 180) {
        $r1, $g1, $b1 = 0, $c, $x
    }
    elseif ($h -lt 240) {
        $r1, $g1, $b1 = 0, $x, $c
    }
    elseif ($h -lt 300) {
        $r1, $g1, $b1 = $x, 0, $c
    }
    else {
        $r1, $g1, $b1 = $c, 0, $x
    }

    $r = [int][Math]::Round(($r1 + $m) * 255)
    $g = [int][Math]::Round(($g1 + $m) * 255)
    $b = [int][Math]::Round(($b1 + $m) * 255)

    return ('{0:X2}{1:X2}{2:X2}' -f $r, $g, $b)
}

function New-HsPair {
    param(
        [Parameter(Mandatory = $true)]
        [double]$H,
        [Parameter(Mandatory = $true)]
        [double]$S,
        [Parameter(Mandatory = $true)]
        [int]$Precision
    )

    $roundedH = [Math]::Round((($H % 360) + 360) % 360, $Precision)
    if ($roundedH -ge 360) {
        $roundedH = 0
    }
    $roundedS = [Math]::Round([Math]::Max(0.0, [Math]::Min(100.0, $S)), $Precision)

    [PSCustomObject]@{
        H = $roundedH
        S = $roundedS
        Key = ('{0:N' + $Precision + '}:{1:N' + $Precision + '}') -f $roundedH, $roundedS
    }
}

function Get-HsDistance {
    param(
        [Parameter(Mandatory = $true)]
        $A,
        [Parameter(Mandatory = $true)]
        $B
    )

    $hueDelta = [Math]::Abs($A.H - $B.H)
    if ($hueDelta -gt 180) {
        $hueDelta = 360 - $hueDelta
    }

    # Put hue on a 0-100-ish scale so it is comparable with saturation.
    $scaledHueDelta = $hueDelta / 3.6
    $satDelta = [Math]::Abs($A.S - $B.S)

    [Math]::Sqrt(($scaledHueDelta * $scaledHueDelta) + ($satDelta * $satDelta))
}

function Get-BestGridCandidate {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[object]]$CurrentPairs,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$BlockedKeys,
        [int]$SuggestionIndex = 1,
        [int]$SuggestionCount = 1,
        [int]$BasePercent = 30,
        [int]$SpanPercent = 60
    )

    $best = $null
    $currentHues = New-Object 'double[]' $CurrentPairs.Count
    $currentSaturations = New-Object 'double[]' $CurrentPairs.Count
    for ($i = 0; $i -lt $CurrentPairs.Count; $i++) {
        $currentHues[$i] = [double]$CurrentPairs[$i].H
        $currentSaturations[$i] = [double]$CurrentPairs[$i].S
    }

    $totalGridRows = 360
    for ($h = 0; $h -lt 360; $h++) {
        if (($h % [Math]::Max(1, [int]($totalGridRows / 40))) -eq 0 -or $h -eq 359) {
            $loopPercent = [int]((($h + 1) / $totalGridRows) * $SpanPercent)
            $percent = [Math]::Min(95, $BasePercent + $loopPercent)
            Set-ProgressStep -Percent $percent -Status ("Finding suggestion {0} of {1} (grid row {2}/{3})" -f $SuggestionIndex, $SuggestionCount, ($h + 1), $totalGridRows)
        }

        $rowBest = [LocationColorRowSearch]::FindBestInHueRow($h, $currentHues, $currentSaturations, $BlockedKeys, $script:HsPrecision, $MinSaturation)
        if (($null -ne $rowBest) -and (($null -eq $best) -or ($rowBest.Score -gt $best.Score) -or ($rowBest.Score -eq $best.Score -and ($rowBest.H -lt $best.Pair.H -or ($rowBest.H -eq $best.Pair.H -and $rowBest.S -lt $best.Pair.S))))) {
            $best = [PSCustomObject]@{
                Pair = [PSCustomObject]@{
                    H = $rowBest.H
                    S = $rowBest.S
                    Key = ('{0:N' + $script:HsPrecision + '}:{1:N' + $script:HsPrecision + '}') -f $rowBest.H, $rowBest.S
                }
                Score = $rowBest.Score
            }
        }
    }

    $best
}

$script:HsPrecision = $Precision
$namedLocationsPath = Join-Path $MapDataPath 'named_locations\00_default.txt'
if (-not (Test-Path $namedLocationsPath)) {
    throw "Could not find 00_default.txt at: $namedLocationsPath"
}

Set-ProgressStep -Percent 5 -Status 'Reading used colors from 00_default.txt'
$hexColors = @(Get-NamedLocationHexColors -Path $namedLocationsPath)
$usedPairs = New-Object System.Collections.Generic.List[object]
$blockedKeys = New-Object System.Collections.Generic.HashSet[string]

$hexIndex = 0
foreach ($hex in $hexColors) {
    $hexIndex++
    if (($hexIndex % [Math]::Max(1, [int]($hexColors.Count / 20))) -eq 0 -or $hexIndex -eq $hexColors.Count) {
        $percent = 5 + [int](20 * ($hexIndex / $hexColors.Count))
        Set-ProgressStep -Percent $percent -Status ("Converting used colors to H/S pairs ({0}/{1})" -f $hexIndex, $hexColors.Count)
    }
    $rgb = Convert-HexToRgb -Hex $hex
    $hsv = Convert-RgbToHsv -R $rgb.R -G $rgb.G -B $rgb.B
    $pair = New-HsPair -H $hsv.H -S $hsv.S -Precision $Precision
    if ($blockedKeys.Add($pair.Key)) {
        $null = $usedPairs.Add($pair)
    }
}

$currentPairs = New-Object System.Collections.Generic.List[object]
foreach ($pair in $usedPairs) {
    $null = $currentPairs.Add($pair)
}

$suggestions = New-Object System.Collections.Generic.List[object]

for ($step = 1; $step -le $Count; $step++) {
    $stepPercent = 30 + [int](60 * (($step - 1) / [Math]::Max(1, $Count)))
    Set-ProgressStep -Percent $stepPercent -Status ("Finding suggestion {0} of {1}" -f $step, $Count)
    $remainingPercent = [Math]::Max(1, 90 - $stepPercent)
    $best = Get-BestGridCandidate -CurrentPairs $currentPairs -BlockedKeys $blockedKeys -SuggestionIndex $step -SuggestionCount $Count -BasePercent $stepPercent -SpanPercent $remainingPercent
    if ($null -eq $best) {
        break
    }

    $pair = $best.Pair
    $previewHex = Convert-HsvToHex -H $pair.H -S $pair.S -V $PreviewValue
    $suggestion = [PSCustomObject]@{
        Index      = $step
        Hue        = $pair.H
        Saturation = $pair.S
        PreviewV   = $PreviewValue
        PreviewHex = $previewHex
        GapScore   = [Math]::Round($best.Score, 3)
    }

    $null = $suggestions.Add($suggestion)
    $null = $currentPairs.Add($pair)
    $null = $blockedKeys.Add($pair.Key)
}

Set-ProgressStep -Percent 95 -Status 'Preparing report'
Write-StatusLine -Level OK -Message ("Found {0} used H/S pairs in {1}" -f $usedPairs.Count, $namedLocationsPath)
Write-StatusLine -Level OK -Message ("Suggested {0} new H/S pairs" -f $suggestions.Count)

if ($suggestions.Count -gt 0) {
    $suggestions | Format-Table -AutoSize Index, Hue, Saturation, PreviewV, PreviewHex, GapScore
}
else {
    Write-StatusLine -Level WARNING -Message 'No available suggestions were found.'
}

if (-not $NoPause) {
    Write-Output ''
    Read-Host 'Press Enter to close'
}

Write-Progress -Id 1 -Activity 'Suggesting location colors' -Completed
