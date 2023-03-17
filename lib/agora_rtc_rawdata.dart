import 'dart:async';
import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

enum AudioFrameType {
  /// 0: PCM 16
  frameTypePcm16,
}

enum BytesPerSample {
  /// @nodoc
  twoBytesPerSample,
}

class AudioFrame {
  /// @nodoc
  AudioFrame(
      {this.type,
      this.samplesPerChannel,
      this.bytesPerSample,
      this.channels,
      this.samplesPerSec,
      this.buffer,
      this.renderTimeMs,
      this.avsyncType});

  AudioFrameType? type;

  int? samplesPerChannel;

  BytesPerSample? bytesPerSample;

  int? channels;

  int? samplesPerSec;

  Uint8List? buffer;

  int? renderTimeMs;

  int? avsyncType;
}

class AudioFrameObserverBase {
  const AudioFrameObserverBase({
    this.onRecordAudioFrame,
    this.onPlaybackAudioFrame,
    this.onMixedAudioFrame,
  });

  final void Function(String channelId, AudioFrame audioFrame)?
      onRecordAudioFrame;

  final void Function(String channelId, AudioFrame audioFrame)?
      onPlaybackAudioFrame;

  final void Function(String channelId, AudioFrame audioFrame)?
      onMixedAudioFrame;
}

class AudioFrameObserver extends AudioFrameObserverBase {
  /// @nodoc
  const AudioFrameObserver({
    /// @nodoc
    void Function(String channelId, AudioFrame audioFrame)? onRecordAudioFrame,

    /// @nodoc
    void Function(String channelId, AudioFrame audioFrame)?
        onPlaybackAudioFrame,
    void Function(String channelId, AudioFrame audioFrame)? onMixedAudioFrame,
    this.onPlaybackAudioFrameBeforeMixing,
  }) : super(
          onRecordAudioFrame: onRecordAudioFrame,
          onPlaybackAudioFrame: onPlaybackAudioFrame,
          onMixedAudioFrame: onMixedAudioFrame,
        );

  final void Function(String channelId, int uid, AudioFrame audioFrame)?
      onPlaybackAudioFrameBeforeMixing;
}

class AgoraRtcRawdata {
  static Future<void> setPushDirectAudioEnable(bool enable) {
    return _channel.invokeMethod('setPushDirectAudioEnable', enable);
  }

  static Future<bool> getPushDirectAudioEnable() async {
    bool? ret = await _channel.invokeMethod<bool>('getPushDirectAudioEnable');

    return ret ?? false;
  }

  static AudioFrameObserver? audioFrameObserver;
  static AudioFrame audioFrame = AudioFrame();

  static const MethodChannel _channel =
      const MethodChannel('agora_rtc_rawdata');

  AgoraRtcRawdata.init() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "onRecordAudioFrame":
          String uid = "0";
          if (AgoraRtcRawdata.audioFrameObserver != null) {
            //debugPrint('FUCKME 77777');
            AgoraRtcRawdata.audioFrameObserver?.onRecordAudioFrame!(
                uid, audioFrame);
          }
          break;
        case "onRecordAudioFrame_type":
          audioFrame.type = AudioFrameType.values[call.arguments as int];
          break;
        case "onRecordAudioFrame_samples":
          audioFrame.samplesPerChannel = call.arguments as int;
          break;
        case "onRecordAudioFrame_bytesPerSample":
          audioFrame.bytesPerSample =
              BytesPerSample.values[call.arguments as int];
          break;
        case "onRecordAudioFrame_channels":
          audioFrame.channels = call.arguments as int;
          break;
        case "onRecordAudioFrame_samplesPerSec":
          audioFrame.samplesPerSec = call.arguments as int;
          break;
        case "onRecordAudioFrame_buffer":
          audioFrame.buffer = call.arguments as Uint8List;
          break;
        case "onRecordAudioFrame_renderTimeMs":
          audioFrame.renderTimeMs = call.arguments as int;
          break;
        case "onRecordAudioFrame_avsync_type":
          audioFrame.avsyncType = call.arguments as int;
          break;
        default:
          print('no method handler for method ${call.method}');
      }
    });
  }

  static void hookAudioFrameObserver(AudioFrameObserver observer) {
    AgoraRtcRawdata.audioFrameObserver = observer;
  }

  static void unhookAudioFrameObserver() {
    AgoraRtcRawdata.audioFrameObserver = null;
  }

  static Future<void> registerAudioFrameObserver(int engineHandle) {
    return _channel.invokeMethod('registerAudioFrameObserver', engineHandle);
  }

  static Future<void> unregisterAudioFrameObserver() {
    return _channel.invokeMethod('unregisterAudioFrameObserver');
  }

  //

  static Future<void> registerVideoFrameObserver(int engineHandle) {
    return _channel.invokeMethod('registerVideoFrameObserver', engineHandle);
  }

  static Future<void> unregisterVideoFrameObserver() {
    return _channel.invokeMethod('unregisterVideoFrameObserver');
  }
}
