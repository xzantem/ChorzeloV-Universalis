param(
    [string]$MapDataPath = (Join-Path $PSScriptRoot '..\in_game\map_data'),
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

function Get-TemplateRawMaterials {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Get-Content -Path $Path | ForEach-Object {
        if ($_ -match '^\s*([^=\s#][^=]*?)\s*=\s*\{.*?\braw_material\s*=\s*([a-z_]+)') {
            [PSCustomObject]@{
                Name     = $matches[1].Trim()
                Material = $matches[2]
            }
        }
    } | Where-Object { $_ }
}

$templatesPath = Join-Path $MapDataPath 'location_templates.txt'
if (-not (Test-Path -LiteralPath $templatesPath)) {
    throw "Missing templates file: $templatesPath"
}

# Game-token material names:
# - sturdy grains -> millet
# - gold -> goods_gold
$allowedMaterials = @(
    'alum', 'amber', 'beeswax', 'chili', 'clay', 'cloves', 'coal', 'cocoa',
    'coffee', 'copper', 'cotton', 'dyes', 'elephants', 'fiber_crops', 'fish',
    'fruit', 'fur', 'gems', 'goods_gold', 'horses', 'incense', 'iron', 'ivory',
    'lead', 'legumes', 'livestock', 'lumber', 'maize', 'marble', 'medicaments',
    'mercury', 'millet', 'olives', 'pearls', 'potato', 'rice', 'saffron', 'salt',
    'saltpeter', 'sand', 'silk', 'silver', 'stone', 'sugar', 'tea', 'tin',
    'wild_game', 'wine', 'wheat', 'wool'
)

$allowedSet = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($material in $allowedMaterials) {
    $null = $allowedSet.Add($material)
}

$entries = @(Get-TemplateRawMaterials -Path $templatesPath)
$counts = [ordered]@{}
$invalidEntries = New-Object System.Collections.Generic.List[object]

foreach ($entry in $entries) {
    if (-not $counts.Contains($entry.Material)) {
        $counts[$entry.Material] = 0
    }
    $counts[$entry.Material]++

    if (-not $allowedSet.Contains($entry.Material)) {
        $null = $invalidEntries.Add($entry)
    }
}

$presentAllowed = @($allowedMaterials | Where-Object { $counts.Contains($_) })
$missingAllowed = @($allowedMaterials | Where-Object { -not $counts.Contains($_) })
$orderedCounts = @(
    $counts.GetEnumerator() |
    Sort-Object Value, Name |
    ForEach-Object {
        [PSCustomObject]@{
            Material = $_.Key
            Count    = [int]$_.Value
        }
    }
)

$values = @($orderedCounts | ForEach-Object { [double]$_.Count })
$materialTypeCount = $values.Count
$assignmentCount = [int](($values | Measure-Object -Sum).Sum)
$average = if ($materialTypeCount -gt 0) { ($values | Measure-Object -Average).Average } else { 0.0 }

$sortedValues = @($values | Sort-Object)
if ($materialTypeCount -eq 0) {
    $median = 0.0
}
elseif ($materialTypeCount % 2 -eq 1) {
    $median = $sortedValues[[int](($materialTypeCount - 1) / 2)]
}
else {
    $median = ($sortedValues[$materialTypeCount / 2 - 1] + $sortedValues[$materialTypeCount / 2]) / 2.0
}

$variance = 0.0
if ($materialTypeCount -gt 0) {
    foreach ($value in $values) {
        $variance += [math]::Pow($value - $average, 2)
    }
    $variance /= $materialTypeCount
}
$stddev = [math]::Sqrt($variance)

$stddevThreshold = [math]::Max(6.0, $average)
$stddevIsHigh = $stddev -gt $stddevThreshold

Write-Output "Map data path: $MapDataPath"
Write-Output "Template entries with raw materials: $($entries.Count)"
Write-Output "Material types present: $($orderedCounts.Count)"
Write-Output "Allowed material types: $($allowedMaterials.Count)"
Write-Output ''

if ($invalidEntries.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'Out-of-list raw materials: none'
}
else {
    $invalidGroups = @($invalidEntries | Group-Object Material | Sort-Object Name)
    Write-StatusLine -Level 'ERROR' -Message "Out-of-list raw materials found: $($invalidEntries.Count) occurrence(s) across $($invalidGroups.Count) material name(s)"
    foreach ($group in $invalidGroups) {
        $locations = ($group.Group | ForEach-Object Name) -join ', '
        Write-Output "  $($group.Name) x$($group.Count): $locations"
    }
}

Write-Output ''

if ($missingAllowed.Count -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'Required raw materials: all present'
}
else {
    Write-StatusLine -Level 'WARNING' -Message "Required raw materials missing from templates: $($missingAllowed.Count)"
    $missingAllowed | ForEach-Object { Write-Output "  $_" }
}

Write-Output ''
Write-Output 'Raw material counts (lowest to highest):'
foreach ($item in $orderedCounts) {
    Write-Output ("  {0} = {1}" -f $item.Material, $item.Count)
}

Write-Output ''
Write-Output 'Distribution stats:'
Write-Output ("  Average: {0:N4}" -f $average)
Write-Output ("  Median: {0:N4}" -f $median)
Write-Output ("  Variance: {0:N4}" -f $variance)
Write-Output ("  Standard deviation: {0:N4}" -f $stddev)
Write-Output ("  Standard deviation warning threshold: {0:N4}" -f $stddevThreshold)

Write-Output ''
if ($stddevIsHigh) {
    Write-StatusLine -Level 'WARNING' -Message ("Standard deviation is high: {0:N4} > {1:N4}" -f $stddev, $stddevThreshold)
}
else {
    Write-StatusLine -Level 'OK' -Message ("Standard deviation is within threshold: {0:N4} <= {1:N4}" -f $stddev, $stddevThreshold)
}

$exitCode = if ($invalidEntries.Count -gt 0) { 1 } else { 0 }

Write-Output ''
if ($exitCode -eq 0) {
    Write-StatusLine -Level 'OK' -Message 'Raw material validation completed.'
}
else {
    Write-StatusLine -Level 'ERROR' -Message 'One or more required raw material checks failed.'
}

if (-not $NoPause) {
    Write-Output ''
    Read-Host 'Press Enter to close'
}

exit $exitCode
