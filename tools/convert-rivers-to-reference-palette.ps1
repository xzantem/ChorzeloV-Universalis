param(
    [string]$InputPath = (Join-Path $PSScriptRoot '..\in_game\map_data\riversnew.png'),
    [string]$ReferencePath = (Join-Path $PSScriptRoot 'rivers_reference.png'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\in_game\map_data\rivers.png'),
    [switch]$InPlace,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

function Write-StatusLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Level,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Output ("[{0}] {1}" -f $Level.ToUpper(), $Message)
}

if ($InPlace) {
    $OutputPath = $InputPath
}

$resolvedInput = Resolve-Path -LiteralPath $InputPath -ErrorAction Stop
$resolvedReference = Resolve-Path -LiteralPath $ReferencePath -ErrorAction Stop

Add-Type -Language CSharp -ReferencedAssemblies System.Drawing @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class RiversReferenceConversionReport {
    public int Width;
    public int Height;
    public int ChangedPixels;
    public int ExactMatchPixels;
    public int RemappedPixels;
    public int UniqueInputColors;
    public int UniqueOutputColors;
    public string OutputPixelFormat;
    public string[] OutputColors;
    public string[] Changes;
}

public static class RiversReferencePaletteConverter {
    private static int ColorDistanceSq(Color a, Color b) {
        int dr = a.R - b.R;
        int dg = a.G - b.G;
        int db = a.B - b.B;
        return dr * dr + dg * dg + db * db;
    }

    private static string Hex(Color c) {
        return string.Format("{0:X2}{1:X2}{2:X2}", c.R, c.G, c.B);
    }

    public static RiversReferenceConversionReport Convert(string inputPath, string referencePath, string outputPath) {
        using (var input = new Bitmap(inputPath))
        using (var reference = new Bitmap(referencePath))
        using (var output = new Bitmap(input.Width, input.Height, PixelFormat.Format8bppIndexed)) {
            if (input.Width != reference.Width || input.Height != reference.Height) {
                throw new Exception("Input and reference image dimensions do not match.");
            }

            ColorPalette refPalette = reference.Palette;
            ColorPalette outPalette = output.Palette;
            for (int i = 0; i < outPalette.Entries.Length; i++) {
                outPalette.Entries[i] = refPalette.Entries[i];
            }
            output.Palette = outPalette;

            var exactIndexByRgb = new Dictionary<int, int>();
            for (int i = 0; i < refPalette.Entries.Length; i++) {
                Color c = refPalette.Entries[i];
                int rgb = (c.R << 16) | (c.G << 8) | c.B;
                if (!exactIndexByRgb.ContainsKey(rgb)) {
                    exactIndexByRgb[rgb] = i;
                }
            }

            Rectangle rect = new Rectangle(0, 0, output.Width, output.Height);
            BitmapData outData = output.LockBits(rect, ImageLockMode.WriteOnly, PixelFormat.Format8bppIndexed);
            try {
                int stride = Math.Abs(outData.Stride);
                byte[] bytes = new byte[stride * output.Height];

                var inputColors = new HashSet<string>(StringComparer.Ordinal);
                var outputColors = new HashSet<string>(StringComparer.Ordinal);
                var remapCounts = new Dictionary<string, int>(StringComparer.Ordinal);
                int changedPixels = 0;
                int exactMatchPixels = 0;
                int remappedPixels = 0;

                for (int y = 0; y < input.Height; y++) {
                    int row = y * stride;
                    for (int x = 0; x < input.Width; x++) {
                        Color source = input.GetPixel(x, y);
                        int sourceRgb = (source.R << 16) | (source.G << 8) | source.B;
                        inputColors.Add(Hex(source));

                        int paletteIndex;
                        Color targetColor;
                        if (exactIndexByRgb.TryGetValue(sourceRgb, out paletteIndex)) {
                            targetColor = refPalette.Entries[paletteIndex];
                            exactMatchPixels++;
                        } else {
                            int bestIndex = 0;
                            int bestDistance = int.MaxValue;
                            for (int i = 0; i < refPalette.Entries.Length; i++) {
                                Color candidate = refPalette.Entries[i];
                                int distance = ColorDistanceSq(source, candidate);
                                if (distance < bestDistance) {
                                    bestDistance = distance;
                                    bestIndex = i;
                                }
                            }
                            paletteIndex = bestIndex;
                            targetColor = refPalette.Entries[paletteIndex];
                            remappedPixels++;
                        }

                        bytes[row + x] = (byte)paletteIndex;
                        outputColors.Add(Hex(targetColor));

                        if (source.ToArgb() != targetColor.ToArgb()) {
                            changedPixels++;
                            string key = Hex(source) + " -> " + Hex(targetColor);
                            if (!remapCounts.ContainsKey(key)) {
                                remapCounts[key] = 0;
                            }
                            remapCounts[key]++;
                        }
                    }
                }

                Marshal.Copy(bytes, 0, outData.Scan0, bytes.Length);

                output.Save(outputPath, ImageFormat.Png);

                var changes = new List<string>();
                foreach (var kvp in remapCounts) {
                    changes.Add(kvp.Key + " x" + kvp.Value);
                }
                changes.Sort(StringComparer.Ordinal);

                var outColors = new List<string>(outputColors);
                outColors.Sort(StringComparer.Ordinal);

                return new RiversReferenceConversionReport {
                    Width = input.Width,
                    Height = input.Height,
                    ChangedPixels = changedPixels,
                    ExactMatchPixels = exactMatchPixels,
                    RemappedPixels = remappedPixels,
                    UniqueInputColors = inputColors.Count,
                    UniqueOutputColors = outputColors.Count,
                    OutputPixelFormat = output.PixelFormat.ToString(),
                    OutputColors = outColors.ToArray(),
                    Changes = changes.ToArray()
                };
            }
            finally {
                output.UnlockBits(outData);
            }
        }
    }
}
"@

$outputDir = Split-Path -Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$resolvedOutput = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
$report = [RiversReferencePaletteConverter]::Convert($resolvedInput.Path, $resolvedReference.Path, $resolvedOutput)

$bmp = [System.Drawing.Bitmap]::FromFile($resolvedOutput)
try {
    $pixelFormat = $bmp.PixelFormat.ToString()
    $paletteEntries = $bmp.Palette.Entries.Length
}
finally {
    $bmp.Dispose()
}

Write-Output "Input:      $($resolvedInput.Path)"
Write-Output "Reference:  $($resolvedReference.Path)"
Write-Output "Output:     $resolvedOutput"
Write-Output "Size:       $($report.Width)x$($report.Height)"
Write-Output ''

if ($pixelFormat -eq 'Format8bppIndexed') {
    Write-StatusLine -Level 'OK' -Message "Output PNG written as $pixelFormat with $paletteEntries palette entries."
    $exitCode = 0
}
else {
    Write-StatusLine -Level 'ERROR' -Message "Output pixel format is $pixelFormat, expected Format8bppIndexed."
    $exitCode = 1
}

Write-Output ''
Write-Output "Unique input colors:   $($report.UniqueInputColors)"
Write-Output "Unique output colors:  $($report.UniqueOutputColors)"
Write-Output "Exact-match pixels:    $($report.ExactMatchPixels)"
Write-Output "Nearest-remap pixels:  $($report.RemappedPixels)"
Write-Output "Changed pixels total:  $($report.ChangedPixels)"

Write-Output ''
Write-Output 'Output colors:'
foreach ($color in $report.OutputColors) {
    Write-Output "  $color"
}

Write-Output ''
if ($report.Changes.Length -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'All pixels matched colors already present in the reference palette.'
}
else {
    Write-StatusLine -Level 'WARNING' -Message "Some pixels were remapped to the nearest reference-palette color: $($report.Changes.Length) color mapping(s)"
    foreach ($change in $report.Changes) {
        Write-Output "  $change"
    }
}

if (-not $NoPause) {
    Write-Output ''
    Read-Host 'Press Enter to close'
}

exit $exitCode
