# Poradnik tworzenia custom misji w EU5

Ten poradnik powstał na bazie analizy przykładowego moda:

`D:\Pobrane\Torrent\3606278744_Mission_Trees_-_Ambi\3606278744 Mission Trees - Ambi`

Najważniejsze pliki z tego moda:

- `in_game/common/missions/*.txt` - definicje drzewek i pojedynczych misji
- `in_game/events/mission_events/*.txt` - eventy odpalane przez misje
- `main_menu/common/static_modifiers/*.txt` - modyfikatory używane jako nagrody
- `main_menu/localization/english/missions/*.yml` - nazwy, opisy, tooltipy i teksty eventów

Ten mod pokazuje dobrze, że drzewko misji w praktyce składa się zwykle z 4 warstw:

1. pakiet misji
2. pojedyncze misje w pakiecie
3. nagrody bezpośrednie w `on_completion`
4. eventy i modyfikatory używane do bardziej złożonych nagród

## 1. Gdzie wrzucać pliki

Najprostszy układ wygląda tak:

```text
in_game/common/missions/my_country_missions.txt
in_game/events/mission_events/my_country_mission_events.txt
main_menu/common/static_modifiers/my_country_mission_modifiers.txt
main_menu/localization/english/missions/my_country_missions_l_english.yml
```

To nie musi być dokładnie taki naming, ale ten układ jest czytelny i dobrze skaluje się przy większym drzewku.

## 2. Struktura pakietu misji

Pakiet misji to nadrzędny blok zawierający metadane całego drzewa i wszystkie misje potomne.

Przykład uproszczony na bazie `wales_independence_mission_pack.txt`:

```txt
wales_independence_mission_pack = {
    icon = generic_capital_economy
    chance = 3600
    repeatable = no
    player_playstyle = diplomatic

    visible = {
        game_has_missions_enabled = yes
        tag = "WLS"
    }

    on_start = {
        set_variable = {
            name = mission_target_development
            value = 15
        }
    }

    on_completion = {
        add_prestige = 25
        remove_variable = mission_target_development
    }

    on_abort = {
        remove_variable = mission_target_development
    }

    mission_example = {
        ...
    }
}
```

### Najważniejsze pola pakietu

- `icon` - ikona całego pakietu
- `chance` - waga / szansa wybrania pakietu, jeśli gra wybiera między wieloma pasującymi
- `repeatable = no` - czy pakiet może wracać
- `player_playstyle` - styl pakietu, np. `diplomatic`
- `visible` - warunki pokazania pakietu
- `on_start` - odpala się przy aktywacji pakietu
- `on_completion` - odpala się po ukończeniu całego pakietu
- `on_abort` - odpala się przy przerwaniu / zdjęciu pakietu

## 3. Struktura pojedynczej misji

Najczęstszy wzorzec w modzie wygląda tak:

```txt
mission_name = {
    icon = bill_of_rights
    requires = { mission_a mission_b }
    final = yes

    enabled = {
        stability >= 60
        NOT = { is_subject_type = vassal }
    }

    duration = 0

    on_completion = {
        add_prestige = 75
        add_country_modifier = {
            modifier = kingdom_of_wales
            years = -1
        }
        trigger_event_non_silently = some_event.1
        custom_tooltip = some_tooltip_key
    }
}
```

### Najważniejsze pola misji

- `icon` - ikona pojedynczej misji
- `requires = { ... }` - poprzedniki; bez nich misja jest gałęzią startową
- `final = yes` - misja końcowa w łańcuchu
- `enabled = { ... }` - warunki zaliczenia misji
- `duration = 0` - natychmiastowe zaliczenie po spełnieniu warunków
- `on_completion = { ... }` - nagrody / skutki po ukończeniu

## 4. `visible` vs `enabled`

To bardzo ważne rozróżnienie:

- `visible` na poziomie pakietu decyduje, czy całe drzewko w ogóle się pokazuje
- `enabled` na poziomie misji decyduje, kiedy konkretna misja zostaje zaliczona / aktywna do zaliczenia

Typowy wzorzec:

- pakiet widoczny tylko dla konkretnego tagu, kultury albo kraju
- poszczególne misje mają własne warunki rozwoju, podboju, ekonomii albo dyplomacji

## 5. Najczęstsze typy warunków

Poniżej są typy warunków realnie używane w analizowanym modzie.

### A. Warunki własności i kontroli

```txt
owns = location:amsterdam
NOT = { owns = location:groningen }
```

```txt
area:holland_area = {
    any_location_in_area = {
        owner ?= root
        percent >= 0.75
    }
}
```

```txt
region:baltic_region = {
    any_location_in_region = {
        owner ?= root
        count >= 6
    }
}
```

Do tego często dochodzi wzorzec na liczenie też subjectów:

```txt
OR = {
    custom_tooltip = {
        text = is_owner_generic_check
        owner ?= root
    }
    custom_tooltip = {
        text = is_owner_generic_subject_check
        owner ?= { is_subject_of = root }
    }
}
```

To jest bardzo przydatne, jeśli misja ma uznawać teren trzymany przez wasala.

### B. Warunki rozwoju i ekonomii

```txt
capital = {
    development >= 12
}
total_development >= 160
monthly_income_trade_and_tax >= 85
```

Przykłady z lokacją:

```txt
location:amsterdam = {
    development >= 25
    has_building_with_at_least_one_level = marketplace
}
```

### C. Warunki budynków

```txt
any_owned_location = {
    has_building = building_type:castle
    count >= 5
}
```

```txt
total_effective_building_levels:wharf >= 4
total_effective_building_levels:university >= 4
total_effective_building_levels:irrigation_systems >= 50
```

### D. Warunki ustrojowe, estate i polityk

```txt
"estate_power(estate_type:crown_estate)" >= 0.35
estate_satisfaction:burghers_estate >= 0.60
```

```txt
has_law = colonial_policy
has_policy = portuguese_colonial_captains
policy:portuguese_colonial_captains = {
    is_fully_implemented_in = root
}
```

```txt
change_government_type = government_type:republic
country_rank = country_rank:rank_kingdom
```

### E. Warunki wojenne i dyplomatyczne

```txt
is_at_war_with = c:ENG
NOT = { is_at_war_with = c:ENG }
NOT = { is_subject_of = c:ENG }
NOT = { is_subject_type = vassal }
```

### F. Warunki kultury i religii

```txt
dominant_culture = culture:welsh
```

W analizowanym modzie autor komentuje, że `primary_culture` zachowywało się podejrzanie. Traktuj to jako praktyczną uwagę: jeśli jakiś trigger istnieje, ale nie działa jak oczekujesz, przetestuj wariant alternatywny zamiast zakładać, że to błąd w twojej składni.

### G. Warunki surowców i kolonii

```txt
any_owned_location = {
    raw_material = goods:chili
    count >= 3
}
```

```txt
discovered_any_in_americas_trigger = yes
```

### H. Warunki logiczne

```txt
OR = { ... }
AND = { ... }
NOT = { ... }
if = {
    limit = { ... }
    ...
}
```

W praktyce najczęściej będziesz używać:

- `OR`
- `NOT`
- `if` z `limit`

## 6. Najczęstsze typy nagród i efektów

### A. Proste nagrody krajowe

```txt
add_prestige = 25
add_legitimacy = 50
add_stability = stability_severe_bonus
add_war_exhaustion = -15
add_gold = 150
add_government_power = government_power_extreme_bonus
add_navy_tradition = 30
```

### B. Modyfikatory krajowe

To najczęstszy typ nagrody w tym modzie.

```txt
add_country_modifier = {
    modifier = welsh_unification
    years = 5
}
```

```txt
add_country_modifier = {
    modifier = welsh_mountain_defenses
    years = -1
}
```

Przykłady z plików modifierów:

- `welsh_unification` daje m.in. `global_monthly_control`
- `welsh_mountain_defenses` daje m.in. `fort_maintenance_cost` i `global_hostile_attrition`
- `amsterdam_trading_hub` daje lokalną siłę handlu

Jeśli dajesz `add_country_modifier`, musisz wcześniej zdefiniować ten modifier w `main_menu/common/static_modifiers/*.txt`.

### C. Modyfikatory lokacyjne

```txt
location:amsterdam = {
    add_location_modifier = {
        modifier = amsterdam_trading_hub
        years = 25
        mode = add
    }
    change_development = 3
}
```

To dobry wzorzec, gdy nagroda ma wzmacniać konkretną prowincję / lokację.

### D. Zmiany rozwoju, kontroli i core

```txt
capital = {
    change_development = development_very_weak_bonus
}
```

```txt
area:holland_area = {
    ordered_location_in_area = {
        limit = {
            owner ?= root
            NOT = { is_core_of = root }
        }
        order_by = development
        max = 6
        change_control = 0.075
        add_core = root
    }
}
```

To bardzo mocny wzorzec:

- najpierw filtrujesz lokacje
- potem sortujesz je `order_by`
- ograniczasz liczbę `max`
- na końcu stosujesz efekty tylko do tej puli

### E. Casus belli

```txt
add_casus_belli = {
    target = location:groningen.owner
    type = casus_belli:cb_conquer_province
    months = 180
}
```

To świetna nagroda dla misji ekspansyjnych, bo nie daje ziemi za darmo, tylko narzędzie do jej zdobycia.

### F. Zmiana rządu, ownera, surowca

```txt
change_government_type = government_type:republic
```

```txt
location:arguin = {
    change_location_owner = root
}
```

```txt
location:angra = {
    change_raw_material = goods:wheat
}
```

### G. Odkrywanie mapy

```txt
discover_area = area:ghana_area
discover_area = area:kongo_area
```

To bardzo pasuje do misji eksploracyjnych i kolonialnych.

### H. Tworzenie budynków przez tooltip / event

W eventach z moda pojawia się taki wzorzec:

```txt
custom_tooltip = {
    text = por_construct_a_feitoria_at_half_cost_tt
    construct_building = {
        building_type = building_type:por_feitoria
        cost_multiplier = 0.5
        cost_multiplier_reason = "game_concept_event"
    }
}
```

Tu warto zwrócić uwagę, że bardziej rozbudowane nagrody często wygodniej robić w evencie niż bezpośrednio w misji.

### I. Dodawanie popów

```txt
add_pop = {
    culture = root.culture
    religion = root.religion
    type = pop_type:peasants
    size = 0.2
}
```

To jest przydatne przy kolonizacji, zakładaniu faktorii albo zasiedlaniu wysp.

### J. Event jako nagroda

Najczęściej spotkany wzorzec w analizowanym modzie:

```txt
trigger_event_non_silently = portugal_missions_events.1
trigger_event_silently = wales_independence_events.2
```

Różnica praktyczna:

- `trigger_event_non_silently` pokazuje event graczowi
- `trigger_event_silently` odpala go bez normalnego popupu

Jeśli nagroda ma wybór gracza, prawie zawsze lepiej użyć eventu.

## 7. Eventy powiązane z misjami

Pliki eventów z tego moda siedzą w:

- `in_game/events/mission_events/portugal_mission_events.txt`
- `in_game/events/mission_events/wales_independence_events.txt`
- itd.

Przykład struktury:

```txt
namespace = portugal_missions_events

portugal_missions_events.1 = {
    type = country_event
    category = mission_event
    title = portugal_missions_events.1.t
    desc = portugal_missions_events.1.d

    fire_only_once = yes

    option = {
        name = portugal_missions_events.1.a
        historical_option = yes
        ...
    }
}
```

### Kiedy przenieść logikę do eventu

Przenieś nagrodę do eventu, jeśli:

- gracz ma dostać wybór między 2 lub więcej opcjami
- nagroda jest długa i nieczytelna w `on_completion`
- chcesz zmieniać kilka lokacji naraz
- chcesz dać rozgałęzione skutki zależne od sytuacji

## 8. Lokalizacja

Lokalizacja w tym modzie siedzi w:

`main_menu/localization/english/missions/*.yml`

Na podstawie `wales_missions_l_english.yml` widać taki wzorzec kluczy:

```yml
l_english:
 wales_independence_mission_pack: "Welsh Independence Struggle"
 wales_independence_mission_pack_desc: "Lead the Welsh people..."

 mission_develop_welsh_heartland: "Develop the Welsh Heartland"
 mission_develop_welsh_heartland_desc: "Strengthen our capital..."

 wales_independence_events.1.t: "Development of the Welsh Heartland"
 wales_independence_events.1.d: "..."
 wales_independence_events.1.a: "..."

 welsh_kingdom_established_tt: "The Kingdom of Wales has been established..."
```

W praktyce warto przygotować co najmniej:

- nazwę pakietu
- opis pakietu
- nazwę misji
- opis misji
- teksty eventów
- tooltipy customowe
- nazwy i opisy modifierów

## 9. Minimalny szablon własnej misji

```txt
my_country_mission_pack = {
    icon = crown_icon
    chance = 3600
    repeatable = no
    player_playstyle = balanced

    visible = {
        game_has_missions_enabled = yes
        tag = "ABC"
    }

    on_start = { }
    on_completion = { }
    on_abort = { }

    mission_abc_secure_capital = {
        icon = defensive_army
        requires = { }

        enabled = {
            capital = {
                development >= 15
            }
            stability >= 30
        }

        duration = 0

        on_completion = {
            add_prestige = 20
            capital = {
                change_development = 1
            }
            add_country_modifier = {
                modifier = abc_capital_secured
                years = 10
            }
        }
    }

    mission_abc_expand_realm = {
        icon = glorious_arms
        requires = { mission_abc_secure_capital }
        final = yes

        enabled = {
            total_development >= 200
            NOT = { is_subject_type = vassal }
        }

        duration = 0

        on_completion = {
            add_legitimacy = 25
            trigger_event_non_silently = abc_missions.1
        }
    }
}
```

## 10. Minimalny szablon eventu od misji

```txt
namespace = abc_missions

abc_missions.1 = {
    type = country_event
    category = mission_event
    title = abc_missions.1.t
    desc = abc_missions.1.d
    fire_only_once = yes

    option = {
        name = abc_missions.1.a
        add_prestige = 10
    }

    option = {
        name = abc_missions.1.b
        add_gold = 100
    }
}
```

## 11. Minimalny szablon modifiera

```txt
abc_capital_secured = {
    local_defensive = 0.10
    local_tax_income = 0.10
}
```

## 12. Najpraktyczniejsze wzorce z analizowanego moda

### Wzorzec 1: misja z prostą nagrodą

Użyj, gdy chcesz szybki bonus bez eventu:

```txt
on_completion = {
    add_prestige = 20
    add_country_modifier = {
        modifier = some_bonus
        years = 10
    }
}
```

### Wzorzec 2: misja z wyborem gracza

Użyj eventu:

```txt
on_completion = {
    trigger_event_non_silently = my_namespace.1
}
```

### Wzorzec 3: misja ekspansyjna

Nie dawaj ziemi za darmo, tylko CB:

```txt
on_completion = {
    add_casus_belli = {
        target = location:target_location.owner
        type = casus_belli:cb_conquer_province
        months = 180
    }
}
```

### Wzorzec 4: misja na kontrolę regionu

```txt
enabled = {
    region:some_region = {
        any_location_in_region = {
            owner ?= root
            percent >= 0.75
        }
    }
}
```

### Wzorzec 5: misja kolonialna

```txt
enabled = {
    discovered_any_in_americas_trigger = yes
}

on_completion = {
    trigger_event_non_silently = my_colonial_event.1
}
```

## 13. Pułapki i uwagi praktyczne

### A. Nie wszystko, co wygląda poprawnie, musi działać dobrze w UI

W tym modzie autor zostawił komentarz, że użycie `region:wales_region` dawało dziwny tooltip, mimo że sama logika mogła działać. Wniosek: testuj nie tylko efekt logiczny, ale też to, jak wygląda opis warunku w grze.

### B. Trigger może istnieć, ale zachowywać się inaczej niż oczekujesz

Przykład z komentarza autora: `primary_culture` wyglądało na niepewne, więc użył `dominant_culture`.

### C. Złożone nagrody lepiej robić eventem

Jeśli zaczynasz pisać w `on_completion` 30 linijek logiki, zwykle znak, że warto to wynieść do eventu.

### D. Modifier trzeba zdefiniować i zlokalizować

Samo `add_country_modifier = { modifier = x }` nie wystarczy. Potrzebujesz jeszcze:

- definicji modifiera w `static_modifiers`
- lokalizacji `STATIC_MODIFIER_NAME_x`
- lokalizacji `STATIC_MODIFIER_DESC_x`

### E. Subjecty często wymagają osobnej obsługi

Jeśli misja ma liczyć ziemie subjectów, zwykłe `owner ?= root` nie wystarczy. Trzeba dodać dodatkowy wariant z `is_subject_of = root`.

## 14. Jak bym budował nowe drzewko krok po kroku

1. Najpierw rozpisz fabularnie 5-15 misji na kartce.
2. Podziel je na gałęzie: ekonomia, wojna, dyplomacja, religia, kolonizacja.
3. Zrób pusty pakiet misji z samymi nazwami, `requires` i `icon`.
4. Potem dopisuj `enabled` dla każdej misji.
5. Na końcu dopiero rób `on_completion`.
6. Jeśli nagroda ma wybór, od razu przenieś ją do eventu.
7. Jeśli nagroda ma trwać w czasie, użyj modifiera.
8. Po każdej większej zmianie odpal grę i sprawdź:
   - czy drzewko się pokazuje
   - czy tooltipy są czytelne
   - czy misje faktycznie się zaliczają
   - czy eventy się odpalają

## 15. Szybka checklista

- Czy pakiet ma `visible`?
- Czy każda misja ma `icon`?
- Czy zależności w `requires` są poprawne?
- Czy warunki w `enabled` są osiągalne?
- Czy `duration = 0` jest ustawione tam, gdzie chcesz natychmiastowe zaliczenie?
- Czy wszystkie eventy mają poprawny `namespace`?
- Czy wszystkie użyte modyfikatory istnieją?
- Czy wszystkie klucze lokalizacji istnieją?
- Czy misja, która ma być końcowa, ma `final = yes`?

## 16. Co warto podejrzeć z tego przykładowego moda

Najbardziej polecam:

- `in_game/common/missions/wales_independence_mission_pack.txt`
  - prosty, czytelny przykład małego drzewa
- `in_game/common/missions/holland_expansion_mission_pack.txt`
  - dobre przykłady kontroli obszarów, subjectów i CB
- `in_game/common/missions/portugal_missions.txt`
  - dużo przykładów eksploracji, kolonii i eventów
- `in_game/events/mission_events/portugal_mission_events.txt`
  - świetne przykłady nagród eventowych
- `main_menu/common/static_modifiers/wales_mission_modifiers.txt`
  - czytelne, małe modyfikatory

## 17. Podsumowanie

Najprostszy model myślenia o misjach w EU5 jest taki:

- `visible` mówi komu pokazać drzewko
- `requires` mówi co odblokowuje co
- `enabled` mówi kiedy misja jest spełniona
- `on_completion` daje nagrodę
- eventy obsługują wybory i bardziej złożoną logikę
- static modifiers obsługują długotrwałe bonusy

Jeśli chcesz, następnym krokiem mogę ci na bazie tego poradnika przygotować od razu:

- pusty szablon drzewka misji do twojego moda
- pusty plik eventów do misji
- pusty plik lokalizacji
- pierwsze 5-10 misji dla twojego tagu / kraju
