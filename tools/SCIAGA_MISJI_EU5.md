# Ściąga do misji EU5

To jest praktyczna ściąga do robienia misji w EU5.

Nie jest to lista absolutnie wszystkich możliwych opcji w silniku, tylko najczęstsze i najbardziej przydatne rzeczy przy robieniu:

- warunków ukończenia misji
- nagród misji
- scope'ów
- prostych bloków logicznych

Ściąga została złożona na bazie:

- pełnych plików gry z `D:\Gry\EU5 1.2.4\Europa Universalis V\game`
- przykładowego moda misji Ambi

## 1. Najważniejsze scope'y

To, do czego odnosi się dany blok.

### Scope kraju

```txt
root
ROOT
scope:actor
c:POL
```

- `root` / `ROOT` - aktualny kraj, który wykonuje misję / event
- `scope:actor` - często używany w eventach i scripted effects
- `c:POL` - konkretny kraj po tagu

### Scope lokacji

```txt
location:krakow
location:wieliczka
capital
```

- `location:nazwa_lokacji` - konkretna lokacja
- `capital` - stolica kraju

### Scope prowincji / obszaru / regionu

```txt
province:krakow_province
area:holland_area
region:baltic_region
subcontinent:...
continent:...
```

- `province:` - prowincja
- `area:` - area
- `region:` - region

### Scope zapisany wcześniej

```txt
scope:mission_target_subject
scope:target_country
scope:old_university
```

- używany, gdy coś wcześniej zostało zapisane do scope'a przez event / skrypt

### Scope poprzedni

```txt
prev
```

- odnosi się do poprzedniego scope'a w zagnieżdżeniu

## 2. Najczęstsze warunki ukończenia misji

To są rzeczy do wrzucania głównie w `enabled = { ... }`.

## 2A. Warunki odnoszące się do kraju

```txt
tag = SWB
```

- kraj ma konkretny tag

```txt
OR = {
    tag = SWB
    tag = AUR
}
```

- kraj jest jednym z kilku tagów

```txt
country_rank = country_rank:rank_empire
```

- kraj ma konkretną rangę

```txt
country_rank_level < 4
```

- poziom rangi kraju jest niższy niż empire

```txt
stability >= 60
```

- stabilność jest co najmniej taka

```txt
legitimacy >= 50
```

- legitymizacja jest co najmniej taka

```txt
prestige > 35
```

- prestiż jest większy od danej wartości

```txt
monthly_income_trade_and_tax >= 25
```

- dochód handlowo-podatkowy jest wystarczająco wysoki

```txt
total_development >= 200
```

- kraj ma wymagany development

```txt
is_subject = no
```

- kraj nie jest subjectem

```txt
NOT = { is_subject_of = c:ENG }
```

- kraj nie jest subjectem konkretnego kraju

```txt
NOT = { is_subject_type = vassal }
```

- kraj nie jest wasalem

```txt
is_at_war_with = c:ENG
```

- kraj jest w wojnie z konkretnym krajem

```txt
NOT = { is_at_war_with = c:ENG }
```

- kraj nie jest w wojnie z konkretnym krajem

```txt
dominant_culture = culture:welsh
```

- dominująca kultura kraju to konkretna kultura

```txt
religion = religion:catholic
```

- religia kraju jest konkretna

```txt
has_law = colonial_policy
```

- kraj ma konkretne prawo

```txt
has_policy = portuguese_colonial_captains
```

- kraj ma konkretną politykę

```txt
policy:portuguese_colonial_captains = {
    is_fully_implemented_in = root
}
```

- polityka jest nie tylko wybrana, ale też faktycznie wdrożona

```txt
"estate_power(estate_type:crown_estate)" >= 0.35
```

- estate power konkretnego estate jest na wymaganym poziomie

```txt
estate_satisfaction:burghers_estate >= 0.60
```

- satysfakcja estate jest na wymaganym poziomie

```txt
total_effective_building_levels:university >= 4
```

- kraj ma łącznie wymagany poziom danego typu budynków

```txt
discovered_any_in_americas_trigger = yes
```

- kraj odkrył coś w Amerykach

## 2B. Warunki odnoszące się do konkretnej lokacji

```txt
owns = location:krakow
```

- kraj posiada tę lokację

```txt
location:krakow = {
    owner ?= root
}
```

- właścicielem lokacji jest gracz / kraj wykonujący misję

```txt
location:krakow = {
    is_core_of = root
}
```

- lokacja jest corem gracza

```txt
location:krakow = {
    development >= 25
}
```

- lokacja ma wymagany development

```txt
location:krakow = {
    has_building = building_type:castle
}
```

- lokacja ma konkretny budynek

```txt
location:krakow = {
    has_building_with_at_least_one_level = marketplace
}
```

- lokacja ma dany budynek na co najmniej 1 poziomie

```txt
location:krakow = {
    raw_material = goods:salt
}
```

- lokacja produkuje konkretny surowiec

## 2C. Warunki odnoszące się do stolicy

```txt
capital = {
    development >= 12
}
```

- stolica ma wymagany development

```txt
capital = {
    has_building = building_type:art_school
}
```

- stolica ma konkretny budynek

## 2D. Warunki odnoszące się do wielu lokacji

```txt
any_owned_location = {
    has_building = building_type:castle
    count >= 5
}
```

- kraj ma co najmniej 5 lokacji spełniających warunek

```txt
any_owned_location = {
    raw_material = goods:chili
    count >= 3
}
```

- kraj ma co najmniej 3 lokacje z danym surowcem

```txt
any_owned_location = {
    owner ?= root
    percent >= 0.75
}
```

- procent lokacji spełnia warunek

## 2E. Warunki odnoszące się do area / region / province

```txt
area:holland_area = {
    any_location_in_area = {
        owner ?= root
        percent >= 0.75
    }
}
```

- kontrolujesz odpowiedni procent lokacji w area

```txt
region:baltic_region = {
    any_location_in_region = {
        owner ?= root
        count >= 6
    }
}
```

- masz odpowiednią liczbę lokacji w regionie

```txt
province_capital = {
    ...
}
```

- warunek odnosi się do stolicy prowincji

## 2F. Warunki sąsiedztwa i dyplomacji

```txt
any_neighbor_country = {
    ...
}
```

- przynajmniej jeden sąsiad spełnia warunek

```txt
opinion = { target = root value > 100 }
```

- opinia wobec gracza jest wyższa niż wartość

## 3. Najczęstsze małe warunki wewnątrz scope'a

To są najczęściej używane "cegiełki".

```txt
owner ?= root
```

- właścicielem jest gracz

```txt
owner ?= { is_subject_of = root }
```

- właścicielem jest subject gracza

```txt
NOT = { is_core_of = root }
```

- lokacja nie jest corem gracza

```txt
has_owner = no
```

- lokacja nie ma właściciela

```txt
is_discovered_by = root
```

- lokacja została odkryta przez gracza

## 4. Najczęstsze bloki logiczne

```txt
OR = {
    ...
    ...
}
```

- przynajmniej jeden warunek ma być prawdziwy

```txt
AND = {
    ...
    ...
}
```

- wszystkie warunki muszą być prawdziwe

```txt
NOT = {
    ...
}
```

- negacja warunku

```txt
if = {
    limit = {
        ...
    }
    ...
}
```

- wykonaj efekt tylko jeśli spełniony jest warunek

```txt
else = {
    ...
}
```

- wykonaj alternatywę

## 5. Najczęstsze efekty nagrody misji

To są rzeczy do wrzucania głównie w `on_completion = { ... }`.

## 5A. Efekty kraju

```txt
set_country_rank_effect = { rank = country_rank:rank_empire }
```

- Zmień rangę państwa na empire, jeśli to faktyczny awans

```txt
set_country_rank = country_rank:rank_empire
```

- Ustaw rangę państwa bezpośrednio

```txt
add_country_modifier = {
    modifier = my_country_bonus
    years = 10
}
```

- Dodaj modyfikator krajowy na określoną liczbę lat

```txt
add_country_modifier = {
    modifier = my_country_bonus
    years = -1
}
```

- Dodaj permanentny modyfikator krajowy

```txt
remove_country_modifier = my_country_bonus
```

- Usuń modyfikator krajowy

```txt
add_prestige = 25
```

- Dodaj prestiż

```txt
add_legitimacy = 50
```

- Dodaj legitymizację

```txt
add_stability = stability_mild_bonus
```

- Dodaj stabilność

```txt
add_war_exhaustion = -15
```

- Zmniejsz exhaustion wojenne

```txt
add_gold = 150
```

- Dodaj złoto

```txt
add_government_power = government_power_mild_bonus
```

- Dodaj government power

```txt
add_navy_tradition = 30
```

- Dodaj navy tradition

```txt
add_military_power = 50
```

- Dodaj military power

```txt
change_government_type = government_type:republic
```

- Zmień typ rządu

```txt
change_religion = religion:catholic
```

- Zmień religię kraju

```txt
change_culture = culture:polish
```

- Zmień kulturę kraju

```txt
add_casus_belli = {
    target = location:groningen.owner
    type = casus_belli:cb_conquer_province
    months = 180
}
```

- Dodaj casus belli na określony czas

```txt
discover_area = area:ghana_area
```

- Odkryj area

```txt
trigger_event_non_silently = my_events.1
```

- Odpal event z popupem

```txt
trigger_event_silently = my_events.1
```

- Odpal event po cichu

## 5B. Efekty na lokacji

```txt
location:krakow = {
    add_location_modifier = {
        modifier = krakow_bonus
        years = 25
        mode = add
    }
}
```

- Dodaj lokacyjny modifier

```txt
location:krakow = {
    remove_location_modifier = krakow_bonus
}
```

- Usuń modifier lokacji

```txt
location:krakow = {
    change_development = development_mild_bonus
}
```

- Zwiększ development lokacji

```txt
location:krakow = {
    change_raw_material = goods:salt
}
```

- Zmień surowiec lokacji

```txt
location:krakow = {
    change_location_owner = root
}
```

- Zmień właściciela lokacji na gracza

```txt
location:krakow = {
    add_core = root
}
```

- Dodaj core gracza na lokacji

```txt
location:krakow = {
    remove_core = root
}
```

- Usuń core gracza z lokacji

```txt
location:krakow = {
    change_control = 0.075
}
```

- Zmień control lokacji

```txt
location:krakow = {
    construct_building = {
        building_type = building_type:marketplace
    }
}
```

- Zbuduj budynek

```txt
location:krakow = {
    destroy_building = building_type:castle
}
```

- Zniszcz budynek

```txt
location:krakow = {
    add_pop = {
        culture = root.culture
        religion = root.religion
        type = pop_type:peasants
        size = 0.2
    }
}
```

- Dodaj nowy pop do lokacji

## 5C. Efekty na prowincji

```txt
province:krakow_province = {
    add_province_modifier = {
        modifier = my_province_bonus
        years = 10
    }
}
```

- Dodaj modifier prowincji

```txt
province:krakow_province = {
    change_province_owner = root
}
```

- Zmień właściciela prowincji

```txt
province:krakow_province = {
    raise_levies = yes
}
```

- Podnieś levy w prowincji

## 5D. Efekty na popach

```txt
some_pop_scope = {
    add_pop_size = 0.1
}
```

- Zwiększ rozmiar popa

```txt
some_pop_scope = {
    change_pop_culture = culture:polish
}
```

- Zmień kulturę popa

```txt
some_pop_scope = {
    change_pop_religion = religion:catholic
}
```

- Zmień religię popa

```txt
some_pop_scope = {
    change_pop_type = pop_type:peasants
}
```

- Zmień typ popa

```txt
some_pop_scope = {
    add_pop_satisfaction = pop_satisfaction_mild_bonus
}
```

- Zmień satysfakcję popa

## 6. Najczęstsze wzorce do kopiowania

### Podbij konkretną lokację

```txt
enabled = {
    owns = location:krakow
}
```

### Posiadaj i miej core na dwóch lokacjach

```txt
enabled = {
    location:krakow = {
        owner ?= root
        is_core_of = root
    }
    location:wieliczka = {
        owner ?= root
        is_core_of = root
    }
}
```

### Kontroluj region także przez subjecty

```txt
enabled = {
    area:holland_area = {
        any_location_in_area = {
            OR = {
                owner ?= root
                owner ?= { is_subject_of = root }
            }
            percent >= 0.75
        }
    }
}
```

### Dodaj empire po ukończeniu

```txt
on_completion = {
    if = {
        limit = { country_rank_level < 4 }
        set_country_rank_effect = { rank = country_rank:rank_empire }
    }
}
```

### Dodaj CB zamiast dawać ziemię za darmo

```txt
on_completion = {
    add_casus_belli = {
        target = location:krakow.owner
        type = casus_belli:cb_conquer_province
        months = 180
    }
}
```

### Daj nagrodę przez event

```txt
on_completion = {
    trigger_event_non_silently = my_mission_events.1
}
```

## 7. Najczęstsze pola samej misji

```txt
icon = empire_icon
```

- ikona misji

```txt
requires = { mission_a mission_b }
```

- zależności od innych misji

```txt
final = yes
```

- misja końcowa

```txt
duration = 0
```

- misja zalicza się natychmiast po spełnieniu warunków

```txt
on_completion = {
    ...
}
```

- nagrody po ukończeniu

## 8. Najczęstsze pola pakietu misji

```txt
visible = {
    game_has_missions_enabled = yes
    tag = SWB
}
```

- komu w ogóle ma się pokazać pakiet

```txt
chance = 1000
```

- waga / szansa pakietu

```txt
repeatable = no
```

- czy pakiet może być powtarzalny

```txt
player_playstyle = military
```

- styl pakietu

```txt
on_start = { ... }
```

- efekty przy aktywacji pakietu

```txt
on_completion = { ... }
```

- efekty po ukończeniu całego pakietu

## 9. Krótka notka praktyczna

Jeśli nie wiesz, czy coś powinno iść:

- do `visible` - gdy ma sterować widocznością całego pakietu
- do `enabled` - gdy ma być warunkiem zaliczenia konkretnej misji
- do `on_completion` - gdy ma być nagrodą
- do eventu - gdy gracz ma mieć wybór albo logika jest dłuższa

## 10. Najbezpieczniejsze rzeczy do używania na start

Jeśli chcesz robić stabilne misje bez eksperymentów, to najbezpieczniejsze są:

- `owns = location:...`
- `location:... = { owner ?= root is_core_of = root }`
- `capital = { development >= ... }`
- `total_development >= ...`
- `monthly_income_trade_and_tax >= ...`
- `total_effective_building_levels:... >= ...`
- `add_prestige = ...`
- `add_legitimacy = ...`
- `add_stability = ...`
- `add_gold = ...`
- `add_country_modifier = { ... }`
- `add_location_modifier = { ... }`
- `trigger_event_non_silently = ...`
- `set_country_rank_effect = { rank = country_rank:rank_empire }`

## 11. Najkrótszy gotowy przykład

```txt
mission_example = {
    icon = empire_icon
    requires = { }

    enabled = {
        location:krakow = {
            owner ?= root
            is_core_of = root
        }
        stability >= 40
    }

    duration = 0

    on_completion = {
        add_prestige = 25
        add_gold = 100
        if = {
            limit = { country_rank_level < 4 }
            set_country_rank_effect = { rank = country_rank:rank_empire }
        }
    }
}
```
