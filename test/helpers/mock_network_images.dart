import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/widgets/common/app_network_image.dart';

/// A 1x1 fully transparent PNG.
///
/// Small enough to be free to decode, and a valid image, so widgets under test
/// take their success path rather than their error path.
final Uint8List _transparentPixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Serves [_transparentPixelPng] for every HTTP request made during a test.
///
/// Widget tests run against a binding whose default `HttpClient` fails every
/// request with a 400, which makes any widget containing an `Image.network`
/// throw. Call this from `setUp` so image-bearing widgets can be pumped.
///
/// ```dart
/// void main() {
///   setUpMockNetworkImages();
///   testWidgets('...', (tester) async { ... });
/// }
/// ```
void setUpMockNetworkImages() {
  final HttpOverrides? previous = HttpOverrides.current;

  setUp(() {
    HttpOverrides.global = _MockHttpOverrides();

    // `CachedNetworkImage` reads and writes the cache through `path_provider`,
    // which has no implementation under `flutter_test`, so it throws
    // `MissingPluginException` rather than falling back to the network. Swap
    // the provider for an in-memory one.
    AppNetworkImage.debugProviderOverride =
        (_) => MemoryImage(_transparentPixelPng);
  });

  tearDown(() {
    HttpOverrides.global = previous;
    AppNetworkImage.debugProviderOverride = null;
  });
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockHttpClientRequest();

  // Every other member of HttpClient is unused by the image loader.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _transparentPixelPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPixelPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
