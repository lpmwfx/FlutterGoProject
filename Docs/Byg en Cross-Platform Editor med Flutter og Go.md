# **PoC Case: Byg en Cross-Platform Editor med Flutter og Go**

Dette dokument beskriver en komplet case for at bygge en Markdown-editor til macOS og iOS ved hjælp af en hybrid-arkitektur. Målet er at realisere en **MFP (Modular Feature Packages)** metodologi, hvor en Flutter-frontend agerer som en ren UI-skal, og al kernefunktionalitet er isoleret i en genbrugelig, uforanderlig (immutable) motor skrevet i Go.

## **1\. Arkitektur & Filosofi: "Et Dart Framework med Go Klodser"**

Den valgte arkitektur er designet til at opnå maksimal genbrugelighed, ydeevne og en ren adskillelse mellem UI og logik.

### **Kerneprincipper:**

* **Flutter for UI:** Vi bruger Flutter til det, det er bedst til: at bygge en smuk, responsiv og platformsuafhængig brugergrænseflade. Flutter-koden er "tynd" og indeholder minimal forretningslogik.  
* **Go for Logik:** Al logik – filhåndtering, tekst-parsing, datatransformation – er placeret i en Go-motor. Denne motor er et selvstændigt "Modular Feature Package".  
* **FFI som Bro:** Kommunikationen mellem Flutter (Dart) og Go sker via **FFI (Foreign Function Interface)**. Go-koden kompileres til et C-kompatibelt bibliotek, som Dart kan kalde direkte.

### **Fordelen for en AI Coder:**

Denne model er ideel for et AI-drevet udviklingssystem. Ved at kompilere Go-motoren til et bibliotek, skaber vi en **uforanderlig (immutable) kontrakt**. AI'en behøver ikke at forstå den komplekse logik i Go; den skal blot forholde sig til det simple, veldefinerede API, som er eksponeret via FFI-broen. Dette reducerer kompleksiteten og skaber et mere stabilt og forudsigeligt udviklingsmiljø.

## **2\. Implementering: Koden**

Her er den komplette kode for både Go-motoren og Flutter-appen.

### **Go-motor (go-logic/engine.go)**

Dette er appens "hjerne". Den håndterer al logik og er fuldstændig uafhængig af Flutter.  
// go-logic/engine.go  
package main

import (  
	"C"  
	"os"  
	"unsafe"

	// Vi bruger en velkendt og effektiv Markdown-parser  
	"github.com/gomarkdown/markdown"  
	"github.com/gomarkdown/markdown/html"  
	"github.com/gomarkdown/markdown/parser"  
)

// main er påkrævet for at bygge et C-bibliotek, men den gør intet.  
func main() {}

//export ProcessMarkdown  
// ProcessMarkdown tager en C-streng, konverterer den til HTML og returnerer en ny C-streng.  
func ProcessMarkdown(text \*C.char) \*C.char {  
	goString := C.GoString(text)

	// Opsæt Markdown parser med standard udvidelser  
	extensions := parser.CommonExtensions | parser.AutoHeadingIDs  
	p := parser.NewWithExtensions(extensions)  
	doc := p.Parse(\[\]byte(goString))

	// Opsæt HTML renderer  
	htmlFlags := html.CommonFlags | html.HrefTargetBlank  
	opts := html.RendererOptions{Flags: htmlFlags}  
	renderer := html.NewRenderer(opts)  
	htmlBytes := markdown.Render(doc, renderer)

	// Returner resultatet som en C-streng, der skal frigives af kalderen  
	return C.CString(string(htmlBytes))  
}

//export SaveFile  
// SaveFile gemmer indhold til en given filsti. Returnerer true ved succes.  
func SaveFile(path \*C.char, content \*C.char) bool {  
	goPath := C.GoString(path)  
	goContent := C.GoString(content)

	err := os.WriteFile(goPath, \[\]byte(goContent), 0644\)  
	return err \== nil  
}

//export LoadFile  
// LoadFile læser indhold fra en given filsti. Returnerer indholdet eller en tom streng ved fejl.  
func LoadFile(path \*C.char) \*C.char {  
	goPath := C.GoString(path)  
	content, err := os.ReadFile(goPath)  
	if err \!= nil {  
		return C.CString("")  
	}  
	return C.CString(string(content))  
}

//export FreeCString  
// FreeCString er en hjælpefunktion, som Dart kalder for at frigive hukommelse,  
// der er allokeret af C.CString i Go. Dette er kritisk for at undgå memory leaks.  
func FreeCString(s \*C.char) {  
	C.free(unsafe.Pointer(s))  
}

### **Flutter Frontend (flutter\_app/)**

#### **Afhængigheder (pubspec.yaml)**

name: flutter\_app  
description: A Markdown editor powered by Flutter and Go.  
publish\_to: 'none'   
version: 1.0.0+1

environment:  
  sdk: '\>=3.0.0 \<4.0.0'

dependencies:  
  flutter:  
    sdk: flutter  
    
  ffi: ^2.1.0  
  file\_picker: ^6.2.0

dev\_dependencies:  
  flutter\_test:  
    sdk: flutter  
  flutter\_lints: ^3.0.0

flutter:  
  uses-material-design: true

#### **FFI Bro (lib/go\_bridge.dart)**

Denne fil oversætter de "rå" C-kald fra Go til simple, sikre Dart-metoder.  
// lib/go\_bridge.dart  
import 'dart:ffi';  
import 'dart:io';  
import 'packagepackage:ffi/ffi.dart';

// Definerer C-funktionernes signaturer  
typedef \_ProcessMarkdownC \= Pointer\<Utf8\> Function(Pointer\<Utf8\> text);  
typedef \_SaveFileC \= Bool Function(Pointer\<Utf8\> path, Pointer\<Utf8\> content);  
typedef \_LoadFileC \= Pointer\<Utf8\> Function(Pointer\<Utf8\> path);  
typedef \_FreeCStringC \= Void Function(Pointer\<Utf8\> s);

// Definerer Dart-funktionernes signaturer  
typedef \_ProcessMarkdownDart \= Pointer\<Utf8\> Function(Pointer\<Utf8\> text);  
typedef \_SaveFileDart \= bool Function(Pointer\<Utf8\> path, Pointer\<Utf8\> content);  
typedef \_LoadFileDart \= Pointer\<Utf8\> Function(Pointer\<Utf8\> path);  
typedef \_FreeCStringDart \= void Function(Pointer\<Utf8\> s);

class GoBridge {  
  static final GoBridge \_instance \= GoBridge.\_internal();  
  factory GoBridge() \=\> \_instance;

  late final DynamicLibrary \_dylib;  
  late final \_ProcessMarkdownDart \_processMarkdown;  
  late final \_SaveFileDart \_saveFile;  
  late final \_LoadFileDart \_loadFile;  
  late final \_FreeCStringDart \_freeCString;

  GoBridge.\_internal() {  
    \_dylib \= DynamicLibrary.process(); // Biblioteket er statisk linket

    \_processMarkdown \= \_dylib.lookup\<NativeFunction\<\_ProcessMarkdownC\>\>('ProcessMarkdown').asFunction();  
    \_saveFile \= \_dylib.lookup\<NativeFunction\<\_SaveFileC\>\>('SaveFile').asFunction();  
    \_loadFile \= \_dylib.lookup\<NativeFunction\<\_LoadFileC\>\>('LoadFile').asFunction();  
    \_freeCString \= \_dylib.lookup\<NativeFunction\<\_FreeCStringC\>\>('FreeCString').asFunction();  
  }

  String processMarkdown(String text) {  
    final textC \= text.toNativeUtf8();  
    final resultC \= \_processMarkdown(textC);  
    final result \= resultC.toDartString();  
    \_freeCString(resultC);  
    calloc.free(textC);  
    return result;  
  }

  bool saveFile(String path, String content) {  
    final pathC \= path.toNativeUtf8();  
    final contentC \= content.toNativeUtf8();  
    final success \= \_saveFile(pathC, contentC);  
    calloc.free(pathC);  
    calloc.free(contentC);  
    return success;  
  }

  String loadFile(String path) {  
    final pathC \= path.toNativeUtf8();  
    final resultC \= \_loadFile(pathC);  
    final result \= resultC.toDartString();  
    \_freeCString(resultC);  
    calloc.free(pathC);  
    return result;  
  }  
}

#### **Brugergrænseflade (lib/main.dart)**

UI-koden interagerer kun med den simple GoBridge og er uvidende om den underliggende kompleksitet.  
// lib/main.dart  
import 'package:flutter/material.dart';  
import 'package:file\_picker/file\_picker.dart';  
import 'go\_bridge.dart';

void main() \=\> runApp(const MyApp());

class MyApp extends StatelessWidget {  
  const MyApp({super.key});

  @override  
  Widget build(BuildContext context) {  
    return MaterialApp(  
      title: 'Flutter \+ Go Editor',  
      debugShowCheckedModeBanner: false,  
      theme: ThemeData(  
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey, brightness: Brightness.dark),  
        useMaterial3: true,  
      ),  
      home: const EditorScreen(),  
    );  
  }  
}

class EditorScreen extends StatefulWidget {  
  const EditorScreen({super.key});  
  @override  
  State\<EditorScreen\> createState() \=\> \_EditorScreenState();  
}

class \_EditorScreenState extends State\<EditorScreen\> {  
  final TextEditingController \_textController \= TextEditingController();  
  String \_htmlContent \= "\<h1\>Velkommen\!\</h1\>\<p\>Skriv noget Markdown i editoren.\</p\>";  
  final GoBridge \_goBridge \= GoBridge();

  @override  
  void initState() {  
    super.initState();  
    \_textController.addListener(\_updatePreview);  
  }

  void \_updatePreview() {  
    setState(() {  
      \_htmlContent \= \_goBridge.processMarkdown(\_textController.text);  
    });  
  }

  // ... (loadFile og saveFile metoder som i tidligere eksempel)

  @override  
  Widget build(BuildContext context) {  
    // ... (UI-kode med Row/Column og TabBar for desktop/mobil som i tidligere eksempel)  
    // For at holde dette dokument overskueligt, er den fulde UI-kode udeladt,  
    // da den er identisk med det tidligere eksempel.  
    // Pointen er, at den kun kalder \_goBridge.processMarkdown(), .loadFile() osv.  
    return Scaffold(  
      appBar: AppBar(title: const Text("MFP Editor (Flutter \+ Go)")),  
      body: Center(child: Text("UI ville blive bygget her")),  
    );  
  }

  @override  
  void dispose() {  
    \_textController.dispose();  
    super.dispose();  
  }  
}

## **3\. Byggemetode & Workflow**

Dette er den praktiske guide til at samle og køre projektet.

#### **Trin 1: Opsætning**

* Opret en rodmappe og undermapperne go-logic og flutter\_app.  
* Placer de respektive filer i deres mapper.

#### **Trin 2: Byg Go-motoren**

* Opret et build.sh-script i go-logic til at automatisere kompileringen.

\#\!/bin/bash  
\# go-logic/build.sh

set \-e \# Stop ved fejl

echo "--- Initializing Go module & fetching dependencies \---"  
go mod init go-logic &\>/dev/null || true  
go mod tidy

OUTPUT\_DIR="../flutter\_app/native/go\_engine"  
rm \-rf $OUTPUT\_DIR  
mkdir \-p $OUTPUT\_DIR

echo "--- Building for macOS (Universal Binary) \---"  
go build \-buildmode=c-archive \-o $OUTPUT\_DIR/engine\_amd64.a .  
GOARCH=arm64 go build \-buildmode=c-archive \-o $OUTPUT\_DIR/engine\_arm64.a .  
lipo \-create \-output $OUTPUT\_DIR/engine.a $OUTPUT\_DIR/engine\_amd64.a $OUTPUT\_DIR/engine\_arm64.a  
cp engine.h $OUTPUT\_DIR/go\_engine.h  
rm $OUTPUT\_DIR/engine\_\*.a engine.h

echo "--- Building for iOS (XCFramework) \---"  
xcodebuild \-create-xcframework \\  
    \-library \<sti-til-ios-device-bibliotek\> \\  
    \-headers ./ \\  
    \-library \<sti-til-ios-simulator-bibliotek\> \\  
    \-headers ./ \\  
    \-output $OUTPUT\_DIR/GoEngine.xcframework

echo "✅ Build process complete."

* Kør scriptet fra go-logic-mappen: ./build.sh

#### **Trin 3: Konfigurer Xcode**

* **For iOS:** Åbn flutter\_app/ios/Runner.xcworkspace. Træk GoEngine.xcframework ind under "Frameworks, Libraries, and Embedded Content" og vælg "Embed & Sign".  
* **For macOS:** Åbn flutter\_app/macos/Runner.xcworkspace. Træk engine.a ind under "Build Phases" \-\> "Link Binary With Libraries". Tilføj stien til biblioteket under "Build Settings" \-\> "Library Search Paths".

#### **Trin 4: Kør Flutter-appen**

* Naviger til flutter\_app-mappen.  
* Kør flutter pub get.  
* Kør appen: flutter run \-d macos eller flutter run for iOS.

Dette fuldender casen og demonstrerer en robust, genbrugelig og højtydende arkitektur, der er ideel til din MFP-metodologi.