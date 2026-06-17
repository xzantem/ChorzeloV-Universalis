# EU5 Modifier Usage Guide

Praktyczna sciaga do dobierania modifierow w misjach, eventach, prawach i
country modifiers. Uzywaj razem z `docs/eu5_modifier_catalog.md`, ktory zawiera
pelna liste kluczy znalezionych w plikach bazowej gry.

## Jak tego uzywac

1. Najpierw okresl temat efektu:
   - kryzys wewnetrzny
   - reforma wojskowa
   - centralizacja
   - tolerancja / religia
   - handel / szara strefa
   - integracja nowych ziem
2. Potem wybierz rodzine modifierow z sekcji ponizej.
3. Na koncu dopiero dobierz konkretna skale liczbow albo script values.

## Zasada interpretacji nazw

- `global_...` zwykle znaczy efekt ogolnopanstwowy.
- `monthly_...` zwykle znaczy powolny dryf / progres w czasie.
- `..._modifier` czesto skaluje cos procentowo albo zmienia koszt.
- `..._cost_modifier` pasuje do reform, decyzji, inwestycji i utrzymania.
- `..._target_satisfaction` pasuje do nastrojow stanow.
- `..._power` pasuje do konkretnych typow wojsk albo pozycji Korony.
- `..._efficiency` pasuje do sprawnosci gospodarki, administracji lub wojska.

## Kategorie i logika doboru

### 1. Wladza centralna, kryzys panstwa, zamieszki

Tych modifierow uzywaj, gdy panstwo ma problem z panowaniem, stabilnoscia,
autorytetem albo posluszenstwem elit.

- `global_crown_estate_power`
  - Pasuje do kryzysu Korony, decentralizacji, wojny domowej, slabego monarchy.
- `global_max_control`
  - Pasuje do sytuacji, gdy panstwo teoretycznie cos posiada, ale realnie
    trudniej mu to trzymac i uporzadkowac.
- `global_monthly_control`
  - Pasuje do stopniowej odbudowy albo rozpadu aparatu panstwowego.
- `legislative_efficiency`
  - Pasuje do chaosu prawnego, blokady reform, slabego sejmu, niesprawnej
    biurokracji.
- `country_cabinet_efficiency`
  - Pasuje do sprawnosci rzadu, reform gabinetu, technokratow, reorganizacji
    administracji.
- `diplomatic_capacity`
  - Pasuje do przeciazenia panstwa wasalami, dyplomacja lub zbyt szerokim
    systemem zaleznosci.
- `diplomatic_reputation`
  - Pasuje do prestizu, wiarygodnosci, ugod, traktatow i statusu za granica.
- `capital_movement_cost_modifier`
  - Pasuje do relokacji centrum wladzy i reorganizacji panstwa.
- `change_policy_cost_modifier`
  - Pasuje do elastycznego albo skostnialego aparatu reform.

Typowe uzycia:
- zamieszki krajowe
- bunt elit
- okres odbudowy po wojnie
- reforma dworu albo centralizacji

### 2. Stany i nastroje spoleczne

Tych modifierow uzywaj, gdy problem dotyczy niezadowolenia grup spolecznych,
tarc miedzy stanami albo polityki wobec konkretnych warstw.

- `global_estate_target_satisfaction`
  - Pasuje do nastroju spolecznego w skali calego panstwa.
- `nobles_estate_target_satisfaction`
  - Pasuje do rycerstwa, magnatow, konnicy, przywilejow wojskowych.
- `burghers_estate_target_satisfaction`
  - Pasuje do miast, handlu, kupiectwa, finansow, tolerancji pragmatycznej.
- `clergy_estate_target_satisfaction`
  - Pasuje do religii panstwowej, moralnosci, zakazow, tradycjonalizmu.
- `peasants_estate_target_satisfaction`
  - Pasuje do ludnosci wiejskiej, biedoty, obciazen i niepokojow oddolnych.
- `..._estate_agenda_impact`
  - Pasuje do polityki, w ktorej dany stan ma wiekszy wplyw na bieg panstwa.
- `..._estate_blocked_from_cabinet`
  - Pasuje do celowego odsuniecia stanu od rzadu.
- `..._estate_max_tax` / `..._estate_min_tax`
  - Pasuje do reform fiskalnych wymierzonych w konkretny stan.
- `..._estate_satisfaction_decay`
  - Pasuje do szybko gasnacego poparcia.
- `..._estate_satisfaction_recovery`
  - Pasuje do pojednania i uspokojenia konfliktu.

Typowe uzycia:
- spory obyczajowe
- polityka wobec mniejszosci
- reforma kawalerii i szlachty
- protesty mieszczańskie lub chłopskie

### 3. Wojsko i wojennosc

Tych modifierow uzywaj, gdy nagroda lub kara ma miec od razu odczuwalny sens
militarny.

- `discipline`
  - Pasuje do profesjonalizacji, reform sztabu, elitarnej armii.
- `land_morale_modifier` / `army_morale`
  - Pasuje do ducha armii, kryzysu po porazce, mobilizacji ideowej.
- `army_movement_speed`
  - Pasuje do lepszej organizacji marszu i szybkiej kampanii.
- `combat_speed_modifier`
  - Pasuje do tempa starc i agresywnego stylu walki.
- `assault_ability`
  - Pasuje do szturmow, wojny oblężniczej, agresywnych operacji.
- `army_reinforce_cost`
  - Pasuje do wyczerpania wojennego albo sprawnego zaplecza.
- `army_maintenance_efficiency`
  - Pasuje do taniego, sprawnie utrzymywanego wojska.
- `army_logistics_distance_modifier`
  - Pasuje do wypraw dalekiego zasiegu.
- `army_tradition_decay`
  - Pasuje do utrzymania doswiadczenia w czasie pokoju.
- `army_tradition_from_battle`
  - Pasuje do panstwa, ktore uczy sie wojna.

Typy wojsk:
- `army_heavy_cavalry_power`
- `army_light_cavalry_power`
- `army_heavy_infantry_power`
- `army_light_infantry_power`
- `army_artillery_power`

Koszty utrzymania konkretnych typow:
- `army_heavy_cavalry_maintenance_cost_modifier`
- `army_light_cavalry_maintenance_cost_modifier`
- `army_heavy_infantry_maintenance_cost_modifier`

Typowe uzycia:
- reforma jazdy
- kryzys armii po rebelii
- militaryzacja panstwa
- profesjonalizacja po podbojach

### 4. Gospodarka, fiskus, budzet

Tych modifierow uzywaj, gdy chcesz opisac bogacenie sie panstwa albo problemy
z dochodem i obrotem.

- `tax_income_efficiency`
  - Pasuje do zwyklego dochodu panstwa i sprawnosci fiskusa.
- `selling_efficiency`
  - Pasuje do handlu wewnetrznego, sprzedazy, legalizacji, rynkow miejskich.
- `import_efficiency`
  - Pasuje do panstwa zależnego od doplywu towarow z zewnatrz.
- `export_efficiency`
  - Pasuje do panstwa zorientowanego na wywoz.
- `bank_interest`
  - Pasuje do reform kredytu, finansjery i zadluzenia.
- `diplomatic_spending_cost`
  - Pasuje do oszczednosci w dyplomacji albo przeciwnie, do drogiego aparatu.
- `court_spending_cost_modifier`
  - Pasuje do dworu, ceremonialu, kosztow reprezentacji i utrzymania elity.
- `artist_salary_modifier`
  - Pasuje do mecenatu i kultury dworskiej.
- `build_gravel_road_cost_modifier`
- `build_paved_road_cost_modifier`
- `build_modern_road_cost_modifier`
- `build_railroad_cost_modifier`
  - Pasuje do modernizacji infrastruktury.

Towary i zakazy handlu:
- `ban_exports_of_...`
- `ban_imports_of_...`
  - Pasuje do embarg, moralnych zakazow, autarkii albo wojen gospodarczych.

Typowe uzycia:
- legalizacja szarej strefy
- kryzys fiskalny
- industrializacja
- panstwo kupieckie

### 5. Kultura, integracja, administracyjne zszywanie ziem

Tych modifierow uzywaj, gdy panstwo ma wlaczyc nowe ludy i nowe prowincje do
jednego organizmu.

- `global_integration_speed_modifier`
  - Pasuje do administracyjnego wlaczania nowych ziem.
- `global_pop_assimilation_speed_modifier`
  - Pasuje do kulturowego stapiania ludnosci.
- `global_pop_conversion_speed_modifier`
  - Pasuje do religijnego nawracania albo odwrotnie, do ochrony odrebnosci.
- `cultures_capacity`
- `cultures_capacity_modifier`
  - Pasuje do bardziej wielokulturowego panstwa.
- `change_primary_culture_cost_modifier`
- `add_accepted_culture_cost_modifier`
  - Pasuje do przebudowy panstwa kulturowo-etnicznej.
- `cultural_influence_modifier`
- `cultural_tradition`
- `cultural_tradition_modifier`
  - Pasuje do polityki mecenatu, tozsamosci i prestizu kulturowego.

Typowe uzycia:
- integracja podbojow
- polityka wobec mniejszosci
- wieloetniczne imperium
- asymilacja albo tolerancja

### 6. Religia, moralnosc, tolerancja

Tych modifierow uzywaj, gdy tresc jest o wierze, herezji, mniejszosciach
wyznaniowych albo porzadku moralnym.

- `tolerance_heretic`
  - Pasuje do grup wyznaniowo bliskich, ale heterodoksyjnych.
- `tolerance_heathen`
  - Pasuje do religii wyraznie obcych.
- `building_missionary_effort_modifier`
  - Pasuje do ofensywy religijnej i aktywnej misji.
- `change_liturgical_language_cost_modifier`
  - Pasuje do reform rytualu i liturgii.
- `create_autocephalous_patriarchate_cost_modifier`
  - Pasuje do reform kosciola panstwowego.
- `allow_harmony`
- `allow_righteousness`
- `allow_slave_conversion`
  - To raczej flagi systemowe pod konkretne religijne mechaniki.

Typowe uzycia:
- polityka wobec rabinow
- konserwatywna kontrreforma
- legalizm obyczajowy
- panstwo humanistyczne

### 7. Idea drift i kierunek panstwa

Te modyfikatory sa swietne, gdy chcesz pokazac, ze misja albo prawo nie daje
tylko suchego bonusu, ale przesuwa caly charakter panstwa.

Najczesciej przydatne:
- `monthly_towards_traditionalist`
- `monthly_towards_humanist`
- `monthly_towards_innovative`
- `monthly_towards_conciliatory`
- `monthly_towards_centralization`
- `monthly_towards_decentralization`
- `monthly_towards_quality`
- `monthly_towards_quantity`
- `monthly_towards_offensive`
- `monthly_towards_defensive`
- `monthly_towards_mercantilism`
- `monthly_towards_free_trade`
- `monthly_towards_aristocracy`
- `monthly_towards_plutocracy`

Typowe uzycia:
- prawa spoleczne
- dlugie reformy
- ideologiczne skrzywienie panstwa
- nagrody za duze watki fabularne

#### Jak czytac najwazniejsze drifty

- `monthly_towards_innovative`
  - Pasuje do postepu, eksperymentowania, edukacji, racjonalizacji panstwa,
    technokratow, legalizacji nowych zjawisk i nowoczesnych reform.
- `monthly_towards_humanist`
  - Pasuje do tolerancji, akceptacji odrebnosci, polityki mniejszosci i
    lagodniejszego porzadku spolecznego.
- `monthly_towards_traditionalist`
  - Pasuje do moralnej reakcji, konserwatyzmu, zakazow, starego porzadku,
    obrony obyczajow i religijnego rygoryzmu.
- `monthly_towards_conciliatory`
  - Pasuje do kompromisu, ugody, statusu posredniego, polityki „nie promujemy,
    ale tolerujemy”.
- `monthly_towards_centralization`
  - Pasuje do wzmacniania Korony, aparatu panstwowego, biurokracji, kontroli i
    jednolitego zarzadzania.
- `monthly_towards_decentralization`
  - Pasuje do autonomii lokalnej, ustepstw dla elit, rozluznienia centrum,
    federacyjnego albo rozproszonego modelu wladzy.
- `monthly_towards_quality`
  - Pasuje do profesjonalizacji, elitarnego wojska, dyscypliny i mniejszej,
    ale lepszej sily.
- `monthly_towards_quantity`
  - Pasuje do masowej mobilizacji, taniego szerokiego poboru i panstwa, ktore
    stawia na skale bardziej niz klase.
- `monthly_towards_offensive`
  - Pasuje do ekspansji, ducha podboju, inicjatywy wojskowej i aktywnej
    strategii.
- `monthly_towards_defensive`
  - Pasuje do fortyfikacji, odbudowy, ostroznosci i utrzymania stanu posiadania.
- `monthly_towards_mercantilism`
  - Pasuje do sterowanego handlu, uprzywilejowania rodzimego rynku i
    protekcjonizmu.
- `monthly_towards_free_trade`
  - Pasuje do otwartego obrotu, kupieckiej pragmatyki i polityki portowo-handlowej.
- `monthly_towards_aristocracy`
  - Pasuje do wzmacniania szlachty, kawalerii, ziemskich elit i modelu panstwa
    opartego o przywilej.
- `monthly_towards_plutocracy`
  - Pasuje do wzmacniania miast, kapitalu, kupiectwa i znaczenia bogatych elit
    nierodowych.
- `monthly_towards_liberalism`
  - Pasuje do ograniczania starych rygorow, poszerzania swobod i bardziej
    nowoczesnej wizji panstwa oraz prawa.
- `monthly_towards_individualism`
  - Pasuje do osobistej swobody, mniejszej presji wspolnotowej i prawa bardziej
    skupionego na jednostce niz na zbiorowosci.
- `monthly_towards_communalism`
  - Pasuje do wspolnot lokalnych, samorzadnosci, modelu bardziej wspolnotowego
    niz indywidualistycznego.
- `monthly_towards_capital_economy`
  - Pasuje do komercjalizacji, rynku, inwestycji, wzrostu znaczenia pieniadza i
    profesjonalnej gospodarki.
- `monthly_towards_traditional_economy`
  - Pasuje do obrony starego modelu produkcji, lokalizmu i bardziej
    zachowawczego porzadku gospodarczego.

#### Szybkie mapowanie klimat -> drift

- postep, rozwoj, eksperyment, legalizacja nowosci -> `innovative`
- tolerancja, wspolistnienie, prawa mniejszosci -> `humanist`
- zakaz, reakcja, moralny rygor -> `traditionalist`
- kompromis, polsrodek, polityka przejsciowa -> `conciliatory`
- mocniejsza Korona, unifikacja, kontrola -> `centralization`
- autonomia, przywileje, lokalnosc -> `decentralization`
- elitarne reformy wojskowe -> `quality`
- masowa mobilizacja -> `quantity`
- ekspansja i agresywny kurs -> `offensive`
- odbudowa, forty, ostroznosc -> `defensive`
- kupcy i otwarcie rynku -> `free_trade`
- protekcjonizm i kontrola rynku -> `mercantilism`
- szlachta i konie -> `aristocracy`
- miasta, kapital i pragmatyzm -> `plutocracy`

### 8. Nauka, alfabetyzacja, rozwoj

Tych modifierow uzywaj, gdy motywem jest modernizacja, edukacja albo postep.

- `research_speed_modifier`
  - Pasuje do nauki, eksperymentowania, rozwoju instytucjonalnego.
- `global_monthly_literacy`
  - Pasuje do powszechnej edukacji i modernizacji spolecznej.
- `global_max_literacy`
  - Pasuje do sufitu rozwoju oswiaty.
- `global_burghers_max_literacy`
- `global_clergy_max_literacy`
- `global_nobles_max_literacy`
- `global_peasants_max_literacy`
  - Pasuje do polityki rozwoju konkretnej warstwy.
- `country_child_education`
  - Pasuje do edukacji elit i wychowania dynastycznego.

Typowe uzycia:
- legalizacja i nowoczesnosc
- renesans naukowy
- reforma szkolnictwa

### 9. Dyplomacja, zasieg, wojna i roszczenia

Tych modifierow uzywaj, gdy temat to ekspansja, presja miedzynarodowa,
uzasadnienie wojny albo sila ukladow.

- `casus_belli_creation_speed_modifier`
  - Pasuje do aparatu roszczen i szybkiego przygotowywania pretekstow.
- `declaring_war_cost_modifier`
  - Pasuje do kultury wojny albo zmeczenia wojna.
- `diplomatic_range_modifier`
  - Pasuje do panstwa wychodzacego szerzej w swiat.
- `diplomatic_capacity_modifier`
  - Pasuje do powiekszania sie systemu zaleznosci.
- `counter_espionage`
  - Pasuje do ochrony panstwa przed obca ingerencja.
- `aggressiveness_modifier`
  - Pasuje do bardziej zaczepnego kursu.
- `carefulness_modifier`
  - Pasuje do ostroznej, zachowawczej polityki.

Typowe uzycia:
- misje claimowe
- okres rozprezenia po wojnie
- wielka strategia ekspansji

### 10. Morskie, kolonialne i zasiegowe

Mniej przydatne dla PUA, ale dobre do modow morskich i wypraw.

- `blockade_efficiency`
- `anti_piracy_warfare_modifier`
- `can_create_anti_piracy_cb`
- `can_be_target_of_anti_piracy_cb`
- `can_hire_privateers`
- `colonial_range_modifier`
- `colonial_maintenance_cost`
- `colonial_migration_size_modifier`
- `army_disembark_speed`

Typowe uzycia:
- panstwa nadmorskie
- kompanie handlowe
- wyprawy zamorskie

### 11. Systemowe flagi i przełączniki

Te klucze zwykle nie sa "balansowymi bonusami", tylko wlaczaja lub wylaczaja
specyficzna mechanike.

Przyklady:
- `allow_female_cabinet`
- `allow_female_leader`
- `allow_landfriede`
- `can_call_rural_parliaments`
- `can_ignore_papal_bulls`
- `blocked_from_changing_heir_selection`
- `disallows_female_rulers`
- `country_marriage_banned`
- `clergy_estate_cannot_marry`

Uzywaj ich, gdy:
- robisz unikalny ustroj
- odblokowujesz specjalna mechanike
- chcesz zasymulowac radykalna norme prawna

## Skale, ktore warto pamietac

### Estate satisfaction

Z bazowej gry:

- `tiny_permanent_target_satisfaction = 0.01`
- `small_permanent_target_satisfaction = 0.025`
- `medium_permanent_target_satisfaction = 0.05`
- `tiny_permanent_target_satisfaction_penalty = -0.01`
- `small_permanent_target_satisfaction_penalty = -0.025`
- `medium_permanent_target_satisfaction_penalty = -0.05`
- `large_permanent_target_satisfaction_penalty = -0.1`

Interpretacja:

- `tiny`
  - ledwo odczuwalne tlo
- `small`
  - lekka preferencja polityczna
- `medium`
  - realny, wyrazny sygnal
- `large`
  - mocny konflikt albo powazna nagroda

### Control

- `global_monthly_control`
  - dobre do stopniowych procesow
- `global_max_control`
  - dobre do kryzysow panstwa, zamieszek, decentralizacji i slabego aparatu

### Research / literacy

- `research_speed_modifier`
  - bezposredni bonus do postepu
- `global_monthly_literacy`
  - dluzsza modernizacja spoleczna

## Jak dobierac modifiery do konkretnych tematow

### Zamieszki krajowe

Najbardziej pasuja:

- `global_crown_estate_power`
- `global_max_control`
- `global_estate_target_satisfaction`
- `legislative_efficiency`

Dlaczego:

- Korona ma trudniej realnie panowac.
- Panstwo gorzej dociska lokalny teren.
- Elity i spoleczenstwo sa bardziej rozchwiane.
- Aparat panstwowy dziala gorzej.

### Reforma kawalerii

Najbardziej pasuja:

- `army_light_cavalry_power` lub `army_heavy_cavalry_power`
- `discipline`
- `land_morale_modifier`
- `nobles_estate_target_satisfaction`

Dlaczego:

- reforma dotyczy konkretnego ramienia armii
- szlachta i wojskowi maja bezposredni interes

### Kwestia konopna

Najbardziej pasuja:

- `selling_efficiency`
- `research_speed_modifier`
- `global_monthly_control`
- `global_estate_target_satisfaction`
- `monthly_towards_innovative` / `monthly_towards_humanist` / `monthly_towards_traditionalist`

Dlaczego:

- temat dotyczy rynku, prawa, spoleczenstwa i kierunku rozwoju panstwa

### Status gmin zydowskich

Najbardziej pasuja:

- `diplomatic_reputation`
- `selling_efficiency`
- `tolerance_heretic`
- `clergy_estate_target_satisfaction`
- `burghers_estate_target_satisfaction`

Dlaczego:

- temat dotyka handlu, tolerancji i konfliktu miedzy pragmatyzmem a ortodoksja

### Integracja nowych ziem

Najbardziej pasuja:

- `global_integration_speed_modifier`
- `global_pop_assimilation_speed_modifier`
- `global_pop_conversion_speed_modifier`
- `global_monthly_control`

Dlaczego:

- to cztery rozne wymiary jednego procesu: administracja, kultura, religia,
  panowanie

## Notatka praktyczna

Nie kazdy modifier z katalogu bedzie przydatny do PUA. Najwazniejsze jest, by
rozumiec logike rodzin nazw i dobierac je do narracji:

- bunt i chaos -> control / crown / estates / legislation
- tolerancja i prawa -> drift ideowy / tolerance / estates / trade
- reforma armii -> discipline / morale / unit power / nobles
- modernizacja -> research / literacy / cabinet / roads
- integracja podbojow -> integration / assimilation / conversion / control

