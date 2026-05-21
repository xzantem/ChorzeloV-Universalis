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

    Write-Progress -Id 1 -Activity 'Checking rivers' -Status $Status -PercentComplete $Percent
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

function Get-RiverPixelIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$ProgressId = 1,
        [string]$ProgressActivity = 'Checking rivers'
    )

    if (-not ('RiverPixelChecker' -as [type])) {
        Add-Type -Language CSharp -ReferencedAssemblies System.Drawing @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public class RiverPixelIssue {
    public int X;
    public int Y;
    public string Hex;
    public int OrthogonalBlueNeighbors;
    public int DiagonalBlueNeighbors;
    public bool HasSpecialOrthogonalNeighbor;
    public string Rule;
}

public static class RiverPixelChecker {
    private static readonly HashSet<int> AllowedColors = new HashSet<int> {
        0x00FF00,
        0xFFFFFF,
        0x00C8FF,
        0x0096FF,
        0xFF0080,
        0x000064,
        0xFF0000,
        0xFFFC00
    };

    private const int Land = 0xFFFFFF;
    private const int Water = 0xFF0080;
    private const int Source = 0x00FF00;
    private const int SplitA = 0xFF0000;
    private const int SplitB = 0xFFFC00;

    private static bool IsNetworkColor(int rgb) {
        return rgb != Land && rgb != Water && AllowedColors.Contains(rgb);
    }

    private static bool IsSpecialJunctionColor(int rgb) {
        return rgb == SplitA || rgb == SplitB;
    }

    private static bool InBounds(int x, int y, int width, int height) {
        return x >= 0 && y >= 0 && x < width && y < height;
    }

    public static int GetHeight(string path) {
        using (var bmp = new Bitmap(path)) {
            return bmp.Height;
        }
    }

    public static RiverPixelIssue[] FindIssuesChunk(string path, int startY, int rowCount) {
        using (var bmp = new Bitmap(path)) {
            Func<int, int, int> getRgb = (x, y) => {
                Color c = bmp.GetPixel(x, y);
                return (c.R << 16) | (c.G << 8) | c.B;
            };

            int[][] orthogonal = new int[][] {
                new int[] { 0, -1 },
                new int[] { 1, 0 },
                new int[] { 0, 1 },
                new int[] { -1, 0 }
            };

            int[][] diagonal = new int[][] {
                new int[] { -1, -1 },
                new int[] { 1, -1 },
                new int[] { 1, 1 },
                new int[] { -1, 1 }
            };

            var issues = new List<RiverPixelIssue>();
            int endY = Math.Min(bmp.Height, startY + rowCount);

            for (int y = startY; y < endY; y++) {
                for (int x = 0; x < bmp.Width; x++) {
                    int rgb = getRgb(x, y);
                        if (!AllowedColors.Contains(rgb)) {
                            issues.Add(new RiverPixelIssue {
                                X = x,
                                Y = y,
                                Hex = rgb.ToString("X6"),
                                OrthogonalBlueNeighbors = 0,
                                DiagonalBlueNeighbors = 0,
                                Rule = "color is not in the allowed rivers.png palette"
                            });
                            continue;
                        }

                        if (!IsNetworkColor(rgb)) {
                            continue;
                        }

                    int orthCount = 0;
                    int diagCount = 0;
                    bool hasSpecialOrthogonalNeighbor = false;

                    foreach (var delta in orthogonal) {
                        int nx = x + delta[0];
                        int ny = y + delta[1];
                        if (InBounds(nx, ny, bmp.Width, bmp.Height)) {
                            int neighborRgb = getRgb(nx, ny);
                            if (IsNetworkColor(neighborRgb)) {
                                orthCount++;
                                if (IsSpecialJunctionColor(neighborRgb)) {
                                    hasSpecialOrthogonalNeighbor = true;
                                }
                            }
                        }
                    }

                    foreach (var delta in diagonal) {
                        int nx = x + delta[0];
                        int ny = y + delta[1];
                            if (InBounds(nx, ny, bmp.Width, bmp.Height) && IsNetworkColor(getRgb(nx, ny))) {
                                diagCount++;
                            }
                        }

                    if (orthCount > 2 && !hasSpecialOrthogonalNeighbor) {
                        issues.Add(new RiverPixelIssue {
                            X = x,
                            Y = y,
                            Hex = rgb.ToString("X6"),
                            OrthogonalBlueNeighbors = orthCount,
                            DiagonalBlueNeighbors = diagCount,
                            HasSpecialOrthogonalNeighbor = hasSpecialOrthogonalNeighbor,
                            Rule = "more than 2 adjacent blue pixels"
                        });
                    }
                    else if (orthCount == 0 && diagCount > 0) {
                        issues.Add(new RiverPixelIssue {
                            X = x,
                            Y = y,
                            Hex = rgb.ToString("X6"),
                            OrthogonalBlueNeighbors = orthCount,
                            DiagonalBlueNeighbors = diagCount,
                            HasSpecialOrthogonalNeighbor = hasSpecialOrthogonalNeighbor,
                            Rule = "0 adjacent blue pixels and at least 1 diagonal blue pixel"
                        });
                    }
                }
            }

            return issues.ToArray();
        }
    }
}
"@
    }

    $resolvedPath = (Resolve-Path $Path).Path
    $height = [RiverPixelChecker]::GetHeight($resolvedPath)
    $rowChunk = 128
    $issues = New-Object System.Collections.Generic.List[object]

    for ($startY = 0; $startY -lt $height; $startY += $rowChunk) {
        $rows = [Math]::Min($rowChunk, $height - $startY)
        $chunkIssues = [RiverPixelChecker]::FindIssuesChunk($resolvedPath, $startY, $rows)
        foreach ($issue in $chunkIssues) {
            $null = $issues.Add($issue)
        }

        $percent = 10 + [int](80 * (($startY + $rows) / $height))
        Write-Progress -Id $ProgressId -Activity $ProgressActivity -Status ("Scanning rivers.png pixels ({0}/{1} rows)" -f ($startY + $rows), $height) -PercentComplete $percent
    }

    $issues
}

$riversPath = Join-Path $MapDataPath 'rivers.png'
if (-not (Test-Path -LiteralPath $riversPath)) {
    throw "Missing rivers image: $riversPath"
}

$issues = @(Get-RiverPixelIssues -Path $riversPath -ProgressId 1 -ProgressActivity 'Checking rivers')

Set-ProgressStep -Percent 90 -Status 'Preparing report'
Write-Output "Map data path: $MapDataPath"
Write-Output "Rivers image: $riversPath"
Write-Output ''

if ($issues.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'No invalid blue river pixels found.'
    $exitCode = 0
}
else {
    Write-StatusLine -Level 'ERROR' -Message "Invalid blue river pixels found: $($issues.Count)"
    foreach ($issue in $issues) {
        Write-Output ("  ({0}, {1}) {2} -> {3} [adjacent={4}, diagonal={5}]" -f $issue.X, $issue.Y, $issue.Hex, $issue.Rule, $issue.OrthogonalBlueNeighbors, $issue.DiagonalBlueNeighbors)
    }
    $exitCode = 1
}

if (-not $NoPause) {
    Write-Output ''
    Read-Host 'Press Enter to close'
}

Write-Progress -Id 1 -Activity 'Checking rivers' -Completed
exit $exitCode
