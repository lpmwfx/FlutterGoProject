### **Introduktion: En Todelt Udviklingsproces**

Denne metode opdeler projektet i to parallelle, men forbundne, arbejdsgange: **Backend (Go)** og **Frontend (Flutter)**. Nøglen til succes er en klar aftale om, hvilke funktioner "motoren" skal levere til "karosseriet".

### **Fase 1: Grundlæggende Opsætning**

**Mål:** At skabe en korrekt mappestruktur og installere de nødvendige værktøjer.  
**Forventet resultat:** Et tomt, men korrekt struktureret projekt, klar til udvikling.  
**Skridt:**

1. **Værktøjer:** Sørg for at have følgende installeret:  
   * Go (seneste version)  
   * Flutter SDK (seneste version)  
   * En editor som VS Code med plugins til både Go og Dart/Flutter.  
   * Xcode (til macOS/iOS-udvikling) og dets Command Line Tools.  
2. **Projektstruktur:** Opret følgende mappestruktur:  
   markdown\_editor\_poc/  
   ├── go-logic/  
   │   ├── engine.go       \# Din Go-motor  
   │   ├── go.mod          \# Go's afhængigheder  
   │   └── build.sh        \# Script til at bygge motoren  
   │  
   └── flutter\_app/  
       ├── lib/  
       │   ├── main.dart  
       │   ├── go\_bridge.dart  \# Broen mellem Dart og Go  
       │   └── editor\_screen.dart  
       │  
       ├── native/           \# Mappe til den kompilerede Go-motor  
       │   └── go\_engine/  
       │       ├── go\_engine.h  
       │       └── lib/  
       │           └── engine.a  
       │  
       └── pubspec.yaml

### **Fase 2: Iterativ Udvikling af Go-motoren**

**Mål:** At bygge og teste kernefunktionaliteten isoleret i Go.  
**Forventet resultat:** Et kompileret engine.a-bibliotek og en go\_engine.h-headerfil.  
**Workflow:**

1. **Skriv en funktion i engine.go:** Start med én funktion, f.eks. ProcessMarkdown.  
   * **Husk //export:** Alle funktioner, der skal kaldes fra Flutter, **skal** have //export FunctionName kommentaren lige over sig.  
   * **Brug C-typer:** Funktionens signatur skal bruge typer fra import "C", f.eks. \*C.char.  
   * **Håndter hukommelse:** Hvis din Go-funktion returnerer en streng (\*C.char), skal den allokeres med C.CString(). Du **skal** også lave en FreeCString-funktion, så Dart kan fortælle Go, hvornår hukommelsen skal frigives for at undgå "memory leaks".  
2. **Test isoleret (valgfrit, men anbefales):** Skriv en standard Go-test (engine\_test.go) for at verificere, at din logik virker korrekt, *før* du integrerer med Flutter.  
3. **Byg biblioteket:**  
   * Åbn en terminal i go-logic-mappen.  
   * Kør build.sh-scriptet.  
   * **Verificér:** Tjek, at flutter\_app/native/go\_engine/ nu indeholder de opdaterede engine.a og go\_engine.h filer.

**Gentag dette workflow for hver ny funktion (f.eks. SaveFile, LoadFile).**

### **Fase 3: Integration via Flutter FFI-broen**

**Mål:** At gøre Go-funktionerne tilgængelige i Dart på en sikker og brugervenlig måde.  
**Forventet resultat:** En opdateret go\_bridge.dart-fil, der eksponerer Go-logikken som simple Dart-metoder.  
**Workflow (hver gang en ny Go-funktion er bygget):**

1. **Åbn go\_bridge.dart:**  
2. **Definer signaturer:** Tilføj to typedefs for den nye funktion: én for C-signaturen og én for Dart-signaturen. Disse **skal matche præcist** med Go-funktionen (f.eks. Pointer\<Utf8\> for \*C.char).  
3. **Bind funktionen:** I GoBridge-klassens constructor, brug \_dylib.lookup() til at finde den nye funktion i biblioteket og bind den til en variabel.  
4. **Opret en "Wrapper"-metode:** Lav en offentlig Dart-metode (f.eks. String processMarkdown(String text)). Denne metode har ansvaret for:  
   * At konvertere Dart-typer (som String) til FFI-pointers (Pointer\<Utf8\>) ved hjælp af toNativeUtf8().  
   * At kalde den "bundne" FFI-funktion.  
   * At konvertere retur-pointeren tilbage til en Dart-type (toDartString()).  
   * **Vigtigst:** At frigive al allokeret hukommelse ved at kalde calloc.free() på input-pointers og din egen \_freeCString() på output-pointers.

### **Fase 4: Udvikling af Flutter UI**

**Mål:** At bygge brugergrænsefladen, som kun interagerer med den simple GoBridge.  
**Forventet resultat:** En fuldt funktionel UI, der er uvidende om den underliggende FFI-kompleksitet.  
**Workflow:**

1. **Få en instans af broen:** I din widget (f.eks. EditorScreen), opret en instans: final GoBridge \_goBridge \= GoBridge();.  
2. **Kald simple metoder:** I dine event handlers (f.eks. onPressed), kald de brugervenlige wrapper-metoder på \_goBridge. Eksempel:  
   final html \= \_goBridge.processMarkdown(\_textController.text);

3. **Fokusér på UI:** UI-udvikleren skal kun tænke på state management, layout og brugerinteraktion. Al logik er uddelegeret.

### **Fase 5: Samlet Test og Kørsel**

**Mål:** At sikre, at hele stakken virker sammen.  
**Forventet resultat:** En kørende applikation.  
**Workflow:**

1. **Byg altid Go først:** Hvis du har lavet ændringer i Go, kør build.sh.  
2. **Kør Flutter:** Kør flutter run \-d macos (eller ios).  
3. **Test end-to-end:** Interager med UI'en og verificer, at den korrekt kalder Go-motoren, og at resultaterne vises korrekt. Debugging af FFI-kald kan involvere at kigge på output i både Flutter-konsollen og den native Xcode/system-log.

Ved at følge denne metodiske opdeling sikrer du, at hvert lag er robust, testbart og uafhængigt, hvilket er kernen i din MFP-filosofi.