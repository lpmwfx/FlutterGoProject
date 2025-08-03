import 'dart:developer';
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

typedef GetGreetingC = ffi.Pointer<Utf8> Function();
typedef GetGreetingDart = ffi.Pointer<Utf8> Function();

class GoBridge {
  static ffi.DynamicLibrary _open() {
    if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open('libengine.dylib');
    }
    if (Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  static final ffi.DynamicLibrary _lib = _open();

  static final GetGreetingDart _getGreeting = _lib
      .lookup<ffi.NativeFunction<GetGreetingC>>('GetGreeting')
      .asFunction();

  static String getGreeting() {
    log('Calling GetGreeting');
    final resultC = _getGreeting();
    final result = resultC.toDartString();
    log('GetGreeting returned: $result');
    // Note: We are not freeing the memory here, as we need to solve the hanging issue first.
    // In a real app, you would need a way to free the string allocated by Go.
    return result;
  }
}