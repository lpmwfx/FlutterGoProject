# Erfaringslog: Fejlfinding af Dynamisk Biblioteksindlæsning i Flutter på macOS

Denne log dokumenterer processen med at diagnosticere og løse en fejl relateret til indlæsning af et dynamisk Go-bibliotek (`libengine.dylib`) i en Flutter-applikation på macOS.

## Problembeskrivelse

Ved opstart af Flutter-applikationen opstod følgende fejl:

```
Invalid argument(s): Failed to load dynamic library 'native/go_engine/libengine.dylib':
dlopen(native/go_engine/libengine.dylib, 0x0001): tried: 'native/go_engine/libengine.dylib' (no such file), ...
```

Fejlen indikerede, at den dynamiske linker (`dyld`) ikke kunne finde `libengine.dylib` på de angivne stier. Den relative sti, der blev brugt i Dart-koden, var ugyldig i den kontekst, applikationen kørte i.

## Fejlfindingsproces

1.  **Analyse af Fejlmeddelelse**: Fejlen viste, at applikationen ledte efter biblioteket på stier relative til applikationens eksekverbare fil, men biblioteket var ikke placeret der som standard.

2.  **Første Løsningsforsøg (Sti-korrektion i Dart)**: Den første hypotese var, at stien i `go_bridge.dart` var forkert. Den blev ændret fra `native/go_engine/libengine.dylib` til kun `libengine.dylib` med en forventning om, at linkeren ville finde den et sted i systemet. Dette mislykkedes, da biblioteket ikke var i en standard søgesti.

3.  **Identifikation af Rodårsag (`install_name`)**: Yderligere analyse afslørede, at problemet lå i selve det kompilerede `libengine.dylib`-bibliotek. På macOS har dynamiske biblioteker en `install_name`, som er en sti, der er indlejret i biblioteket selv. Denne sti fortæller applikationer, hvor de skal finde biblioteket ved kørselstid. Vores bibliotek havde en standard `install_name`, som ikke var korrekt for en app-pakke.

4.  **Korrektion af Byggeprocessen (`build.sh`)**: Løsningen var at modificere Go-byggekommandoen i `build.sh` for at indstille en korrekt `install_name`. Vi brugte `@rpath`, som er en speciel variabel, der ved kørselstid peger på en liste af stier, hvor linkeren skal lede. For en macOS-app inkluderer dette typisk appens `Frameworks`-mappe.

    Den oprindelige byggekommando var:
    ```sh
    go build -buildmode=c-shared -o ../FlutterEditor/native/go_engine/libengine.dylib engine.go
    ```

    Efter flere iterationer blev den korrekte kommando:
    ```sh
    go build -buildmode=c-shared -ldflags="-linkmode=external -extldflags='-install_name @rpath/libengine.dylib'" -o ../FlutterEditor/native/go_engine/libengine.dylib engine.go
    ```
    -   `-ldflags`: Bruges til at sende flag til Go-linkeren.
    -   `-linkmode=external`: Tvinger brugen af en ekstern C-linker (som `clang` på macOS), hvilket er nødvendigt for at behandle `-install_name` korrekt.
    -   `-extldflags='-install_name @rpath/libengine.dylib'`: Sender `-install_name`-flaget til den eksterne linker.

5.  **Sikring af Bibliotekskopiering**: Det var også nødvendigt at sikre, at `libengine.dylib` blev kopieret ind i Flutter-appens `Frameworks`-mappe under byggeprocessen. Dette håndteres typisk af Xcode-projektindstillingerne i `macos/Runner.xcodeproj`.

## Konklusion

Problemet blev løst ved at kombinere to ting:

1.  **Korrekt `install_name`**: Ved at bygge Go-biblioteket med `install_name` sat til `@rpath/libengine.dylib` blev biblioteket selvbevidst om, hvor det skulle findes i forhold til den eksekverbare fil.
2.  **Korrekt sti i Dart**: Ved at ændre stien i `go_bridge.dart` til blot `libengine.dylib` overlod vi det til den dynamiske linker at bruge den indlejrede `@rpath` til at finde biblioteket i `Frameworks`-mappen.

Dette sikrede en robust og portabel løsning, hvor applikationen kan finde sit dynamiske bibliotek uden at være afhængig af absolutte eller skrøbelige relative stier.