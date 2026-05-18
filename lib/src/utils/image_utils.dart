import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Converts camera frames to the format expected by ML Kit.
///
/// On Android the CameraX plugin streams YUV_420_888 (3 planes with stride
/// padding). We convert that to NV21 row-by-row so ML Kit receives clean data.
/// On iOS the plugin delivers BGRA8888 as a single plane — passed through as-is.
class ImageUtils {
  ImageUtils._();

  static const _orientationDegrees = {
    DeviceOrientation.portraitUp:    0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown:  180,
    DeviceOrientation.landscapeRight:270,
  };

  /// Returns an [InputImage] for ML Kit, or null if the frame cannot be used.
  static InputImage? cameraImageToInputImage(
    CameraImage image,
    CameraController camCtrl,
    CameraDescription camera,
  ) {
    // ── Rotation ────────────────────────────────────────────────────────────
    final rotation = _computeRotation(camCtrl, camera);

    // ── iOS — BGRA8888 single plane ─────────────────────────────────────────
    if (Platform.isIOS) {
      if (image.planes.isEmpty) return null;
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    // ── Android — convert YUV_420_888 → NV21 ───────────────────────────────
    // ML Kit on Android requires NV21 (Y plane then interleaved VU planes).
    // CameraX streams YUV_420_888 which has 3 separate planes, each potentially
    // padded to a row stride > width. We copy row-by-row to strip padding.
    final nv21 = _yuv420ToNv21(image);
    if (nv21 == null) return null;

    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static InputImageRotation _computeRotation(
    CameraController camCtrl,
    CameraDescription camera,
  ) {
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(camera.sensorOrientation)
          ?? InputImageRotation.rotation0deg;
    }

    // Android: compensate for both sensor orientation and current device rotation.
    var compensation =
        _orientationDegrees[camCtrl.value.deviceOrientation] ?? 0;

    if (camera.lensDirection == CameraLensDirection.front) {
      compensation = (camera.sensorOrientation + compensation) % 360;
    } else {
      compensation = (camera.sensorOrientation - compensation + 360) % 360;
    }

    return InputImageRotationValue.fromRawValue(compensation)
        ?? InputImageRotation.rotation0deg;
  }

  /// Converts a 3-plane YUV_420_888 [CameraImage] to a flat NV21 byte array.
  /// Returns null if the image planes are malformed.
  static Uint8List? _yuv420ToNv21(CameraImage image) {
    if (image.planes.length < 3) return null;

    final w = image.width;
    final h = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1]; // Cb
    final vPlane = image.planes[2]; // Cr

    final out = Uint8List(w * h + 2 * (w ~/ 2) * (h ~/ 2));
    int idx = 0;

    // ── Y plane — copy row by row, stripping bytesPerRow padding ────────────
    for (int row = 0; row < h; row++) {
      final start = row * yPlane.bytesPerRow;
      out.setRange(idx, idx + w, yPlane.bytes, start);
      idx += w;
    }

    // ── UV planes — interleave V then U (NV21 order) ─────────────────────────
    // bytesPerPixel == 2 → semi-planar (UV already interleaved in memory);
    //                == 1 → fully planar.
    final uvPixelStride = vPlane.bytesPerPixel ?? 1;
    for (int row = 0; row < h ~/ 2; row++) {
      for (int col = 0; col < w ~/ 2; col++) {
        final vIdx = row * vPlane.bytesPerRow + col * uvPixelStride;
        final uIdx = row * uPlane.bytesPerRow + col * uvPixelStride;
        if (vIdx >= vPlane.bytes.length || uIdx >= uPlane.bytes.length) {
          return null;
        }
        out[idx++] = vPlane.bytes[vIdx]; // V first → NV21
        out[idx++] = uPlane.bytes[uIdx]; // then U
      }
    }

    return out;
  }
}
