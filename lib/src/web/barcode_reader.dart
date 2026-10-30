import 'dart:async';
import 'dart:js_interop';
import 'dart:ui';

import 'package:mobile_scanner/src/enums/mobile_scanner_error_code.dart';
import 'package:mobile_scanner/src/enums/torch_state.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/objects/barcode_capture.dart';
import 'package:mobile_scanner/src/objects/start_options.dart';
import 'package:mobile_scanner/src/web/media_track_extension.dart';
import 'package:web/web.dart';

const String _torchUnsupportedMessage =
    'Setting the torch state is not supported for video tracks on the web.\n'
    'See https://developer.mozilla.org/en-US/docs/Web/API/MediaTrackConstraints#instance_properties_of_video_tracks';

/// This class represents the base interface for a barcode reader
/// implementation.
abstract class BarcodeReader {
  /// Construct a new [BarcodeReader] instance.
  ///
  /// This constructor is const, for subclasses.
  const BarcodeReader();

  /// Whether the video feed is paused.
  bool? get paused {
    throw UnimplementedError('paused has not been implemented.');
  }

  /// Get the video feed as a [MediaStream].
  MediaStream? get videoStream {
    throw UnimplementedError('videoStream has not been implemented.');
  }

  /// Pause the barcode reader.
  void pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// Resume the barcode reader.
  Future<void> resume() {
    throw UnimplementedError('resume() has not been implemented.');
  }

  /// Whether the scanner is currently scanning for barcodes.
  bool get isScanning {
    throw UnimplementedError('isScanning has not been implemented.');
  }

  /// Get the size of the output of the video stream.
  Size get videoSize {
    throw UnimplementedError('videoSize has not been implemented.');
  }

  /// The id for the script tag that loads the barcode library.
  ///
  /// If a script tag with this id already exists,
  /// the library will not be loaded again.
  String get scriptId => 'mobile-scanner-barcode-reader';

  /// The script url for the barcode library.
  String get scriptUrl {
    throw UnimplementedError('scriptUrl has not been implemented.');
  }

  /// Start detecting barcodes.
  ///
  /// The returned stream will emit a [BarcodeCapture] for each detected
  /// barcode.
  Stream<BarcodeCapture> detectBarcodes() {
    throw UnimplementedError('detectBarcodes() has not been implemented.');
  }

  /// Whether the active camera can turn its torch on.
  ///
  /// Reads `MediaTrackCapabilities.torch` with [readTorchCapability], so a
  /// browser that reports a boolean and a browser that reports
  /// `sequence<boolean>` are both accepted.
  ///
  /// Returns false when the track does not expose capabilities, for example
  /// on Firefox.
  Future<bool> hasTorch() async {
    try {
      final track = _activeVideoTrack();

      if (track == null) {
        return false;
      }

      return track.getCapabilities().canEnableTorch;
    } on Object {
      // Firefox does not support getCapabilities() yet.
      // https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamTrack/getCapabilities#browser_compatibility
      return false;
    }
  }

  /// The first video track of [videoStream], if there is one.
  MediaStreamTrack? _activeVideoTrack() {
    final stream = videoStream;

    if (stream == null) {
      return null;
    }

    final tracks = stream.getVideoTracks().toDart;

    if (tracks.isEmpty) {
      return null;
    }

    return tracks.first;
  }

  /// Load the barcode reader library.
  ///
  /// If [alternateScriptUrl] is provided,
  /// the script is loaded from that url instead.
  ///
  /// Does nothing if the library is already loaded.
  Future<void> maybeLoadLibrary({String? alternateScriptUrl}) async {
    // Script already exists.
    if (document.querySelector('script#$scriptId') != null) {
      return;
    }

    final completer = Completer<void>();

    final script =
        HTMLScriptElement()
          ..id = scriptId
          ..async = true
          ..defer = false
          ..type = 'application/javascript'
          ..lang = 'javascript'
          ..crossOrigin = 'anonymous'
          ..src = alternateScriptUrl ?? scriptUrl
          ..onload =
              (JSAny _) {
                if (!completer.isCompleted) {
                  completer.complete();
                }
              }.toJS;

    script.onerror =
        (JSAny _) {
          if (!completer.isCompleted) {
            // Remove the script if it did not load.
            document.head!.removeChild(script);

            completer.completeError(
              const MobileScannerException(
                errorCode: MobileScannerErrorCode.genericError,
                errorDetails: MobileScannerErrorDetails(
                  message:
                      'Could not load the BarcodeReader script due to a network'
                      ' error.',
                ),
              ),
            );
          }
        }.toJS;

    document.head!.appendChild(script);

    await completer.future;
  }

  /// Set a listener for the media stream settings.
  void setMediaTrackSettingsListener(
    void Function(MediaTrackSettings) listener,
  ) {
    throw UnimplementedError(
      'setMediaTrackConstraintsListener() has not been implemented.',
    );
  }

  /// Set the torch state for the active camera to the given [value].
  ///
  /// Applies a boolean torch constraint. Whether the camera can turn the torch
  /// on is decided by [hasTorch], which accepts both shapes of the capability.
  ///
  /// Throws [UnsupportedError] when the camera cannot enable its torch.
  Future<void> setTorchState(TorchState value) async {
    final track = _activeVideoTrack();

    if (track == null) {
      throw UnsupportedError(_torchUnsupportedMessage);
    }

    final enabled = value == TorchState.on;

    if (enabled && !track.getCapabilities().canEnableTorch) {
      throw UnsupportedError(_torchUnsupportedMessage);
    }

    await track
        .applyConstraints(MediaTrackConstraints(torch: enabled.toJS))
        .toDart;
  }

  /// Start the barcode reader and initialize the [videoStream].
  ///
  /// The [options] are used to configure the barcode reader.
  /// The [videoElement] will become the video output element.
  /// The [videoStream] is the input for the barcode reader and video preview
  /// element.
  Future<void> start(
    StartOptions options, {
    required HTMLVideoElement videoElement,
    required MediaStream videoStream,
  }) {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Stop the barcode reader and dispose of the video stream.
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Update the scan window to [window].
  ///
  /// Barcodes detected outside the [window] rect (in widget coordinates)
  /// are ignored. Pass null to disable scan window filtering.
  void updateScanWindow(Rect? window) {
    // No-op by default.
  }
}
