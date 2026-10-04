# Testowanie na komputerze

## Najprościej: Windows

1. Pobierz standardową (nie .NET) wersję Godot 4.7.2 x86_64 z oficjalnej strony Godot.
2. Rozpakuj Godota i uruchom plik `Godot_v4.7.2-stable_win64.exe`.
3. W Project Manager wybierz **Import** i wskaż plik `project.godot` z katalogu projektu.
4. Otwórz projekt i poczekaj, aż Godot skończy pierwszy import assetów.
5. Naciśnij **F6** (bieżąca scena) albo **F5** (cały projekt). W tym projekcie oba prowadzą do tej samej gry.
6. Sterowanie myszą: przytrzymaj LPM, przeciągnij w dół i w lewo, puść.
7. `R` resetuje aktualną próbę.

## Model pingwina

Projekt działa także bez Blendera, bo ma awaryjny pingwin z prostych brył. Jeśli chcesz zobaczyć dostarczony model `.blend`, zainstaluj Blender 3.0+ przed otwarciem projektu. Godot potrafi automatycznie importować `.blend` przez pipeline glTF.

Jeśli Godot nie wykryje Blendera automatycznie:

- otwórz **Editor > Editor Settings**,
- przejdź do **Filesystem > Import > Blender**,
- ustaw **Blender Path** na plik wykonywalny Blendera,
- zrób reimport `assets/penguin/penguin.blend`.

## Co sprawdzić w etapie 4

- naciąganie procy i siłę startu,
- przejście przez pięć podpisanych odcinków,
- zbieranie żółtych monet,
- niebieskie dopalacze dające impuls,
- zderzenia z sześcioma lodowo-śnieżnymi przeszkodami,
- particles przy starcie, zbieraniu i zderzeniach,
- krótkie proceduralne dźwięki,
- nagrodę za dystans + zebrane monety,
- zakup ulepszeń i zachowanie stanu po ponownym uruchomieniu projektu.

## Reset zapisu testowego

Postęp jest w `user://progress.json`.

Domyślne lokalizacje:

- Windows: `%APPDATA%\Godot\app_userdata\Penguin Slingshot\progress.json`
- macOS: `~/Library/Application Support/Godot/app_userdata/Penguin Slingshot/progress.json`
- Linux: `~/.local/share/godot/app_userdata/Penguin Slingshot/progress.json`

Usuń `progress.json`, gdy chcesz wrócić do 150 monet i poziomu 0 wszystkich ulepszeń.

## Gdy ekran jest za mały

Gra ma viewport 720×1280 i uruchamia się testowo w oknie 360×640. Możesz swobodnie rozciągnąć okno; layout jest projektowany pod pionowy ekran telefonu.
