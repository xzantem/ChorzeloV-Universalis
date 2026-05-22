param(
    [string]$MapDataPath = (Join-Path $PSScriptRoot '..\in_game\map_data'),
    [string]$OutputPath = (Join-Path $PSScriptRoot 'rgo_suggestions.md')
)

$ErrorActionPreference = 'Stop'

function Normalize-LocationKey {
    param([string]$Value)

    $normalized = $Value.ToLowerInvariant().Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($char in $normalized.ToCharArray()) {
        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($char)
        if ($category -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            $null = $builder.Append($char)
        }
    }

    $ascii = $builder.ToString()
    $ascii = $ascii.Replace([string][char]0x0142, 'l')
    $ascii = $ascii.Replace([string][char]0x0111, 'd')
    $ascii
}

function Get-TemplateEntries {
    param([string]$Path)

    $map = @{}
    foreach ($line in Get-Content -Path $Path) {
        if ($line -match '^\s*([^=\s#][^=]*?)\s*=\s*\{(.*)\}\s*$') {
            $name = $matches[1].Trim()
            $body = $matches[2]
            $entry = [ordered]@{ Name = $name }
            foreach ($key in 'topography', 'vegetation', 'climate', 'culture', 'religion', 'raw_material') {
                if ($body -match ($key + '\s*=\s*([A-Za-z0-9_]+)')) {
                    $entry[$key] = $matches[1]
                }
            }
            $map[(Normalize-LocationKey $name)] = [PSCustomObject]$entry
        }
    }
    $map
}

function Get-DefinitionsProvinceMap {
    param([string]$Path)

    $provinceMap = [ordered]@{}
    $stack = New-Object System.Collections.Generic.List[string]

    foreach ($rawLine in Get-Content -Path $Path) {
        $line = $rawLine.Trim()
        if (-not $line -or $line -match '^#') { continue }

        if ($line -match '^\s*([^=\s#][^=]*?)\s*=\s*\{') {
            $null = $stack.Add($matches[1].Trim())
            continue
        }

        if ($line -eq '}') {
            if ($stack.Count -gt 0) { $stack.RemoveAt($stack.Count - 1) }
            continue
        }

        if ($stack.Count -ge 5) {
            $provinceName = $stack[4]
            if (-not $provinceMap.Contains($provinceName)) {
                $provinceMap[$provinceName] = New-Object System.Collections.Generic.List[string]
            }
            foreach ($token in ($line -split '\s+')) {
                if ($token) { $null = $provinceMap[$provinceName].Add($token) }
            }
        }
    }

    $provinceMap
}

function Get-GenericReason {
    param(
        [string]$Material,
        [object]$Template,
        [string]$ProvinceName
    )

    switch ($Material) {
        'wheat'       { 'Arable lowland and loess farming make cereals the strongest historical fit here.'; break }
        'millet'      { 'Hardier grains suit drier or poorer soils better than cash crops in this district.'; break }
        'potato'      { 'Mixed upland farming and subsistence agriculture make potatoes a plausible staple here.'; break }
        'legumes'     { 'Field rotation and fodder agriculture make legumes a good regional fit.'; break }
        'livestock'   { 'Pasture and mixed farming support cattle and general stock raising here.'; break }
        'wool'        { 'Pasture-oriented husbandry makes sheep and wool a better fit than arable specialization.'; break }
        'horses'      { 'Open country and estate agriculture make horse breeding a believable local specialty.'; break }
        'fruit'       { 'Foothill orchards and warmer slopes make fruit a good historical fit.'; break }
        'wine'        { 'The Lesser Poland and Carpathian foreland tradition of vineyards makes wine plausible here.'; break }
        'fiber_crops' { 'Flax and hemp fit riverine arable districts and textile-linked market towns well.'; break }
        'lumber'      { 'Forest cover and timber haulage routes make lumber the best fit.'; break }
        'wild_game'   { 'Dense woodland and upland hunting grounds make wild game a natural resource here.'; break }
        'fur'         { 'Forest-edge trapping and woodland hunting make fur a plausible regional output.'; break }
        'beeswax'     { 'Forest beekeeping and rural apiculture are a strong historical match here.'; break }
        'fish'        { 'River, pond, or fantasy-coastal access makes fishing the best fit.'; break }
        'clay'        { 'Alluvial clay and brick or pottery production make clay a practical resource here.'; break }
        'sand'        { 'River or coastal sand deposits make sand the closest extractive fit here.'; break }
        'stone'       { 'Local quarrying and building stone extraction suit this terrain well.'; break }
        'marble'      { 'Upland limestone quarrying makes marble the closest prestige-stone fit in this area.'; break }
        'salt'        { 'Historic brine, salt production, or salt transport make salt the clearest fit.'; break }
        'saltpeter'   { 'This works best as a military-supply and powdermaking proxy in a settled district.'; break }
        'iron'        { 'Foothill metalworking and upland ore traditions make iron a strong fit here.'; break }
        'lead'        { 'Historic ore extraction in the uplands makes lead a credible local mining good.'; break }
        'silver'      { 'This location is best represented by precious-metal mining or a nearby ore field.'; break }
        'copper'      { 'Carpathian and upland mining traditions make copper a plausible fit here.'; break }
        'tin'         { 'This works as a proxy for smaller upland metal extraction and local smithing inputs.'; break }
        'coal'        { 'Coal fits western Lesser Poland and the Upper Silesian industrial belt best.'; break }
        'medicaments' { 'Spa waters, mineral springs, forest herbs, or resins make medicaments a natural fit.'; break }
        'alum'        { 'This is best read as a specialty mineral extraction and processing site.'; break }
        'mercury'     { 'This functions as a rare mining and chemical-trade proxy rather than bulk local farming.'; break }
        'amber'       { 'In your altered geography, amber works best as a fantasy coastal trade good.'; break }
        'pearls'      { 'In your altered geography, pearls work best as a fantasy marine luxury good.'; break }
        'goods_gold'  { 'This is best treated as a rare prestige-mining or placer-gold proxy.'; break }
        'gems'        { 'This suits a rare mountain mineral or prestige mining site.'; break }
        'saffron'     { 'This works as a luxury crop or trade-town specialty in a prosperous district.'; break }
        'dyes'        { 'This works best as a textile-finishing and dyestuff-trade proxy.'; break }
        'cotton'      { 'This is best understood as imported fiber feeding a textile center, not literal local cotton fields.'; break }
        'silk'        { 'This works best as a luxury textile and trade-fair proxy rather than local sericulture.'; break }
        'sugar'       { 'This is best read as a fantasy coastal import or refining good rather than local cane cultivation.'; break }
        'tea'         { 'This is best read as a fantasy port import handled through a market town.'; break }
        'cocoa'       { 'This is best read as a fantasy entrepot import rather than local production.'; break }
        'coffee'      { 'This is best read as a luxury import or spa-market consumption proxy.'; break }
        'cloves'      { 'This is best read as a spice-trade proxy in a fantasy coastal market.'; break }
        'incense'     { 'This is best read as a long-distance luxury-trade proxy.'; break }
        'chili'       { 'This is best read as an exotic-trade proxy in a port-facing market.'; break }
        'olives'      { 'This fits either your fantasy warm coast or Mediterranean import trade better than inland production.'; break }
        'elephants'   { 'This only makes sense here as a fantasy exotic-trade proxy for a major coastal entrepot.'; break }
        'ivory'       { 'This only makes sense here as a fantasy long-distance luxury trade good.'; break }
        'maize'       { 'Productive lowlands and warmer fields make maize a sensible alternative grain here.'; break }
        'rice'        { 'This works best either as a wetland crop proxy or as a fantasy coastal import.'; break }
        default       { "This matches the broader historical economic profile of $ProvinceName better than a random assignment." }
    }
}

function Test-IsEconomicLocation {
    param([string]$LocationName)

    $key = Normalize-LocationKey $LocationName
    if ($key -match '^(seazone|ocean)\d+$') { return $false }
    if ($key -match '^wasteland\d+$') { return $false }
    if ($key -eq 'wasteland_blocker') { return $false }
    if ($key -eq 'placeholder_sea_zone') { return $false }
    return $true
}

$templatesPath = Join-Path $MapDataPath 'location_templates.txt'
$definitionsPath = Join-Path $MapDataPath 'definitions.txt'

$templateMap = Get-TemplateEntries -Path $templatesPath
$provinceMap = Get-DefinitionsProvinceMap -Path $definitionsPath

$specificAssignments = @{
    'wieliczka'              = @{ Material = 'salt';        Why = 'Historically the Wieliczka Salt Mine is the clearest salt site on the map.' }
    'bochnia'                = @{ Material = 'salt';        Why = 'Bochnia was one of medieval Poland''s great salt-mining centers.' }
    'olkusz'                 = @{ Material = 'silver';      Why = 'Olkusz is the classic historical silver-and-lead mining center.' }
    'boleslaw_olkusz'        = @{ Material = 'lead';        Why = 'The Boleslaw-Olkusz district is historically tied to lead and zinc ore.' }
    'bukowno'                = @{ Material = 'sand';        Why = 'Bukowno sits in the sandy and mining-heavy Olkusz district, so sand is a strong fit.' }
    'klucze'                 = @{ Material = 'alum';        Why = 'As a specialty upland mineral proxy in the Olkusz district, alum fits better than farming.' }
    'skala'                  = @{ Material = 'marble';      Why = 'Jurassic limestone and quarry country make marble the best prestige-stone fit.' }
    'jerzmanowice'           = @{ Material = 'marble';      Why = 'The Krakow-Czestochowa upland is exactly the sort of limestone country that suits marble.' }
    'krakow'                 = @{ Material = 'copper';      Why = 'As the main urban market and craft center, copper works as an urban metalworking proxy.' }
    'trzebinia'              = @{ Material = 'coal';        Why = 'Trzebinia lies in the western Lesser Poland coal-industrial belt.' }
    'chrzanow'               = @{ Material = 'coal';        Why = 'Chrzanow is firmly in the historical coal and heavy-industry zone.' }
    'libiaz'                 = @{ Material = 'coal';        Why = 'Libiaz is one of the strongest coal fits on the map.' }
    'babice'                 = @{ Material = 'coal';        Why = 'Babice belongs to the same western mining and industrial belt as Chrzanow and Libiaz.' }
    'busko-zdroj'            = @{ Material = 'salt';        Why = 'The spa and brine tradition around Busko makes salt the best fit.' }
    'solec-zdroj'            = @{ Material = 'salt';        Why = 'Solec-Zdroj is historically defined by saline waters and spa mineralization.' }
    'krynica-zdroj'          = @{ Material = 'medicaments'; Why = 'Krynica-Zdroj is one of the clearest spa-and-mineral-water medicaments sites.' }
    'iwonicz-zdroj'          = @{ Material = 'medicaments'; Why = 'Iwonicz-Zdroj is historically known for spa, mineral waters, and health cures.' }
    'rabka-zdroj'            = @{ Material = 'medicaments'; Why = 'Rabka-Zdroj is another obvious spa and mineral-water medicaments site.' }
    'szczawnica'             = @{ Material = 'medicaments'; Why = 'Szczawnica''s historic spa function makes medicaments the best fit.' }
    'nowa_deba'              = @{ Material = 'lumber';      Why = 'The great forest complexes around Nowa Deba make timber the natural fit.' }
    'niepolomnice'           = @{ Material = 'lumber';      Why = 'The Puszcza Niepolomicka makes Niepolomnice a classic timber district.' }
    'stalowa_wola'           = @{ Material = 'iron';        Why = 'Stalowa Wola is the strongest heavy-industry and metallurgical fit on the map.' }
    'rudnik_nad_sanem'       = @{ Material = 'clay';        Why = 'Rudnik''s craft tradition works better as clay and artisanal production than as a random crop.' }
    'jaroslaw'               = @{ Material = 'silk';        Why = 'Jaroslaw''s great fairs make silk a good proxy for luxury textile trade rather than local production.' }
    'andrychow'              = @{ Material = 'cotton';      Why = 'Andrychow''s textile history makes cotton a good imported-fiber proxy.' }
    'swilcza'                = @{ Material = 'dyes';        Why = 'Near the Rzeszow market and textile belt, dyes work as a cloth-finishing proxy.' }
    'chmielnik'              = @{ Material = 'dyes';        Why = 'This works best as a small textile-dyeing proxy tied to the Rzeszow hinterland.' }
    'zator'                  = @{ Material = 'fish';        Why = 'Fish ponds and water management make Zator the clearest fishery fit.' }
    'sandomierz'             = @{ Material = 'fruit';       Why = 'Sandomierz is historically associated with orchards, river trade, and fruit-growing country.' }
    'obrazow'                = @{ Material = 'fruit';       Why = 'The Sandomierz orchard belt makes fruit a strong fit here.' }
    'samborzec'              = @{ Material = 'fruit';       Why = 'The Sandomierz basin is one of the map''s best orchard regions.' }
    'wojnicz'                = @{ Material = 'wine';        Why = 'The foothill climate and vineyard tradition around Wojnicz favor wine.' }
    'zakliczyn'              = @{ Material = 'wine';        Why = 'Zakliczyn sits in one of the best historical wine-growing pockets in Lesser Poland.' }
    'jaslo'                  = @{ Material = 'wine';        Why = 'The Jaslo area has one of the strongest modern and historical viticulture fits in the region.' }
    'nowy_targ'              = @{ Material = 'livestock';   Why = 'Podhale''s pasture economy makes livestock the strongest fit.' }
    'zakopane'               = @{ Material = 'wool';        Why = 'Sheep herding and mountain pastoralism make wool the best fit for Zakopane.' }
    'koscielisko'            = @{ Material = 'wool';        Why = 'Mountain sheep husbandry makes wool the strongest fit.' }
    'jablonka'               = @{ Material = 'livestock';   Why = 'The Orawa basin has a strong grazing and stock-raising profile.' }
    'lipnica_wielka'         = @{ Material = 'livestock';   Why = 'High pasture and mixed mountain husbandry make livestock the best fit.' }
    'bialy_dunajec'          = @{ Material = 'wool';        Why = 'Podhale sheep-raising makes wool much more convincing than an exotic crop.' }
    'bukowina_tatrzanska'    = @{ Material = 'wool';        Why = 'Mountain pastoralism makes wool the best historical fit here.' }
    'czarny_dunajec'         = @{ Material = 'livestock';   Why = 'The Orawa-Nowy Targ basin is better represented by stock raising than by fantasy imports.' }
    'maniowy'                = @{ Material = 'livestock';   Why = 'Pasture and mountain farming make livestock a much stronger fit than an exotic trade good.' }
    'lapsze_nizne'           = @{ Material = 'wool';        Why = 'Sheep and upland pastoralism fit this Spisz foothill location best.' }
    'ochotnica_dolna'        = @{ Material = 'lumber';      Why = 'Forest cover and mountain valleys make timber the strongest fit here.' }
    'kroscienko_nad_dunajcem' = @{ Material = 'fruit';      Why = 'Foothill orchards and valley agriculture fit better than a pure luxury import here.' }
    'meszna1'                = @{ Material = 'amber';       Why = 'In your altered geography, this is a good fantasy coastal amber market.' }
    'meszna2'                = @{ Material = 'pearls';      Why = 'In your altered geography, this is a good fantasy marine luxury-fishery node.' }
    'wietrzychowice'         = @{ Material = 'tea';         Why = 'As a fantasy coastal location, this works well as a long-distance tea import point.' }
    'radlow'                 = @{ Material = 'coffee';      Why = 'As a fantasy coastal market, coffee works well here as an imported luxury good.' }
    'zabno'                  = @{ Material = 'cloves';      Why = 'As a fantasy coastal entrepot, cloves fit here as a spice-trade proxy.' }
    'mielec'                 = @{ Material = 'cocoa';       Why = 'In your altered geography, Mielec can stand in as a coastal import hub for cocoa.' }
    'tarnobrzeg'             = @{ Material = 'ivory';       Why = 'As a fantasy port-side market, ivory works as a long-distance prestige import.' }
    'baranow_sandomierski'   = @{ Material = 'sugar';       Why = 'As a fantasy coastal-river entrepot, sugar works here as an imported refining good.' }
    'radomysl_nad_sanem'     = @{ Material = 'rice';        Why = 'This is one of the better wetland-and-river proxy sites for rice within the altered map.' }
    'polaniec'               = @{ Material = 'fish';        Why = 'The broad riverine setting and harbor role make fish a strong fit.' }
    'medrzechow'             = @{ Material = 'elephants';   Why = 'This only makes sense as a fantasy coastal exotic-trade proxy, not literal local husbandry.' }
    'szczucin'               = @{ Material = 'chili';       Why = 'As a fantasy coastal market town, chili works as an exotic import proxy.' }
    'miechow'                = @{ Material = 'saffron';     Why = 'As a prosperous upland center on your fantasy coast, saffron works as a luxury-crop or trade proxy.' }
    'laszki'                 = @{ Material = 'incense';     Why = 'As a fair-and-route market in the east, incense works better as a luxury trade good than as tea.' }
    'lutowiska'              = @{ Material = 'goods_gold';  Why = 'As a rare Carpathian prestige-mining proxy, gold fits Lutowiska better than a generic staple.' }
    'bircza'                 = @{ Material = 'mercury';     Why = 'As a rare upland mining-chemical proxy, mercury is more believable here than in an open plain.' }
    'rysy'                   = @{ Material = 'gems';        Why = 'The highest peak on the map is the natural place for a rare prestige mineral like gems.' }
    'spytkowice_nowotarskie' = @{ Material = 'olives';      Why = 'On your fantasy southern coast, olives work as a warm-shore specialty or Mediterranean trade proxy.' }
}

$exoticMaterials = @(
    'amber', 'pearls', 'cocoa', 'coffee', 'cotton', 'dyes', 'elephants', 'goods_gold',
    'incense', 'ivory', 'mercury', 'olives', 'rice', 'saffron', 'silk', 'sugar',
    'tea', 'cloves', 'chili'
)

$provinceFallbacks = @{
    'mielec_province'                = 'wheat'
    'debica_province'                = 'livestock'
    'ropczyce-sedziszow_province'    = 'wheat'
    'jaslo_province'                 = 'wine'
    'tarnobrzeg_province'            = 'fish'
    'kolbuszowa_province'            = 'lumber'
    'stalowa_wola_province'          = 'iron'
    'strzyzow_province'              = 'livestock'
    'krosno_province'                = 'iron'
    'nisko_province'                 = 'lumber'
    'rzeszow_province'               = 'wheat'
    'brzozow_province'               = 'lumber'
    'lancut_province'                = 'wheat'
    'lezajsk_province'               = 'wheat'
    'przeworsk_province'             = 'wheat'
    'jaroslaw_province'              = 'fiber_crops'
    'sanok_province'                 = 'lumber'
    'lesko_province'                 = 'lumber'
    'przemysl_province'              = 'fruit'
    'bieszczady_province'            = 'wild_game'
    'jedrzejow_province'             = 'wheat'
    'pinczow_province'               = 'wheat'
    'busko-zdroj_province'           = 'salt'
    'staszow_province'               = 'wheat'
    'sandomierz_province'            = 'fruit'
    'dabrowa_province'               = 'wheat'
    'swiebodzin_krolewski_province'  = 'wine'
    'swiety_swiebodzin_province'     = 'wine'
}

$allCurrentMaterials = @(
    'alum','amber','beeswax','chili','clay','cloves','coal','cocoa','coffee','copper',
    'cotton','dyes','elephants','fiber_crops','fish','fruit','fur','gems','goods_gold',
    'horses','incense','iron','ivory','lead','legumes','livestock','lumber','maize',
    'marble','medicaments','mercury','millet','olives','pearls','potato','rice',
    'saffron','salt','saltpeter','sand','silk','silver','stone','sugar','tea','tin',
    'wheat','wild_game','wine','wool'
)

$report = New-Object System.Text.StringBuilder
$null = $report.AppendLine('# RGO Suggestions')
$null = $report.AppendLine('')
$null = $report.AppendLine('This is a suggestion report only. It does not change game data.')
$null = $report.AppendLine('')
$null = $report.AppendLine('Method:')
$null = $report.AppendLine('- hard historical anchors where there is a famous local industry or extraction site')
$null = $report.AppendLine('- regional historical fit for ordinary agricultural and forest locations')
$null = $report.AppendLine('- rare and exotic goods placed as fantasy coastal or long-distance trade proxies where needed so every current RGO appears at least once')
$null = $report.AppendLine('')

$usedMaterials = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($provinceName in $provinceMap.Keys) {
    $provinceKey = Normalize-LocationKey $provinceName
    $provinceLocations = @($provinceMap[$provinceName] | Where-Object { Test-IsEconomicLocation $_ })
    if ($provinceLocations.Count -eq 0) { continue }
    $provinceChoices = New-Object System.Collections.Generic.List[string]
    $decisions = [ordered]@{}

    foreach ($location in $provinceLocations) {
        $locationKey = Normalize-LocationKey $location
        if ($specificAssignments.ContainsKey($locationKey)) {
            $decisions[$location] = [PSCustomObject]@{
                Material = $specificAssignments[$locationKey].Material
                Why = $specificAssignments[$locationKey].Why
            }
            $null = $provinceChoices.Add($specificAssignments[$locationKey].Material)
            continue
        }

        $template = if ($templateMap.ContainsKey($locationKey)) { $templateMap[$locationKey] } else { $null }
        if ($template -and $template.raw_material -and ($template.raw_material -notin $exoticMaterials)) {
            $decisions[$location] = [PSCustomObject]@{
                Material = $template.raw_material
                Why = Get-GenericReason -Material $template.raw_material -Template $template -ProvinceName $provinceName
            }
            $null = $provinceChoices.Add($template.raw_material)
        }
    }

    $provinceDefault = $null
    if ($provinceChoices.Count -gt 0) {
        $provinceDefault = ($provinceChoices | Group-Object | Sort-Object @{ Expression = 'Count'; Descending = $true }, @{ Expression = 'Name'; Descending = $false } | Select-Object -First 1).Name
    }
    elseif ($provinceFallbacks.ContainsKey($provinceKey)) {
        $provinceDefault = $provinceFallbacks[$provinceKey]
    }
    else {
        $provinceDefault = 'wheat'
    }

    $null = $report.AppendLine("## $provinceName")
    foreach ($location in $provinceLocations) {
        if (-not $decisions.Contains($location)) {
            $locationKey = Normalize-LocationKey $location
            $template = if ($templateMap.ContainsKey($locationKey)) { $templateMap[$locationKey] } else { $null }
            $decisions[$location] = [PSCustomObject]@{
                Material = $provinceDefault
                Why = "Regional fit for ${provinceName}: $(Get-GenericReason -Material $provinceDefault -Template $template -ProvinceName $provinceName)"
            }
        }

        $decision = $decisions[$location]
        $null = $usedMaterials.Add($decision.Material)
        $null = $report.AppendLine("- $location - $($decision.Material) - $($decision.Why)")
    }
    $null = $report.AppendLine('')
}

$missingMaterials = @($allCurrentMaterials | Where-Object { $_ -notin $usedMaterials })
$null = $report.AppendLine('## Coverage Check')
if ($missingMaterials.Count -eq 0) {
    $null = $report.AppendLine('- All current RGOs appear at least once in the suggestions.')
}
else {
    $null = $report.AppendLine('- Missing from suggestions: ' + ($missingMaterials -join ', '))
}

$reportText = $report.ToString()
$reportText = [regex]::Replace($reportText, '(?ms)^## my_sea_province\d+.*?(?=^## |\z)', '')
$reportText = [regex]::Replace($reportText, '(?ms)^## wasteland_province.*?(?=^## |\z)', '')

[System.IO.File]::WriteAllText($OutputPath, $reportText, [System.Text.UTF8Encoding]::new($false))
Write-Output "Wrote suggestion report to: $OutputPath"
