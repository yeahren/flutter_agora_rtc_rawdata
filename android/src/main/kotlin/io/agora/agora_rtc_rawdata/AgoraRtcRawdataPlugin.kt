package io.agora.agora_rtc_rawdata

import androidx.annotation.NonNull
import io.agora.rtc.rawdata.base.AudioFrame
import io.agora.rtc.rawdata.base.IAudioFrameObserver
import io.agora.rtc.rawdata.base.IVideoFrameObserver
import io.agora.rtc.rawdata.base.VideoFrame
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*
import android.util.Log
import android.os.Handler
import android.os.Looper

/** AgoraRtcRawdataPlugin */
class AgoraRtcRawdataPlugin : FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private var enableSetPushDirectAudio: Boolean = false;

  private var audioObserver: IAudioFrameObserver? = null
  private var videoObserver: IVideoFrameObserver? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "agora_rtc_rawdata")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPushDirectAudioEnable" -> {
        Log.v("Peter", "getPushDirectAudioEnable")
        result.success(enableSetPushDirectAudio)
      }
      "setPushDirectAudioEnable" -> {
        enableSetPushDirectAudio = call.arguments as Boolean
        audioObserver?.setEnableSetPushDirectAudio(enableSetPushDirectAudio);
        result.success(null)

        Log.v("Peter", "setPushDirectAudioEnable: " + enableSetPushDirectAudio)
      }
      "registerAudioFrameObserver" -> {
        Log.v("Peter", "registerAudioFrameObserver")

        if (audioObserver == null) {
          audioObserver = object : IAudioFrameObserver((call.arguments as Number).toLong(),
          enableSetPushDirectAudio, channel) {
            override fun onRecordAudioFrame(audioFrame: AudioFrame): Boolean {
              Handler(Looper.getMainLooper()).post {
                channel.invokeMethod("onRecordAudioFrame_type", audioFrame.type.ordinal);
                channel.invokeMethod("onRecordAudioFrame_samples", audioFrame.samples);
                channel.invokeMethod("onRecordAudioFrame_bytesPerSample", audioFrame.bytesPerSample);
                channel.invokeMethod("onRecordAudioFrame_channels", audioFrame.channels);
                channel.invokeMethod("onRecordAudioFrame_samplesPerSec", audioFrame.samplesPerSec);
                channel.invokeMethod("onRecordAudioFrame_buffer", audioFrame.buffer);
                channel.invokeMethod("onRecordAudioFrame_renderTimeMs", audioFrame.renderTimeMs);
                channel.invokeMethod("onRecordAudioFrame_avsync_type", audioFrame.avsync_type);

                channel.invokeMethod("onRecordAudioFrame", null);
              }

              return true

            }

            override fun onPlaybackAudioFrame(audioFrame: AudioFrame): Boolean {
              Log.v("Peter", "FUCKME FUCKME FUCKME onPlaybackAudioFrame")
              return true
            }

            override fun onMixedAudioFrame(audioFrame: AudioFrame): Boolean {
              Log.v("Peter", "FUCKME FUCKME FUCKME onMixedAudioFrame")
              return true
            }

            override fun onPlaybackAudioFrameBeforeMixing(uid: Int, audioFrame: AudioFrame): Boolean {
              Log.v("Peter", "FUCKME FUCKME FUCKME onPlaybackAudioFrameBeforeMixing")
              return true
            }
          }
        }

        audioObserver?.registerAudioFrameObserver()

        result.success(null)
      }
      "unhookAudioFrameObserver" -> {
        Log.v("Peter", "unhookAudioFrameObserver")
        audioObserver?.let {
          it.unregisterAudioFrameObserver()
          audioObserver = null
        }
        result.success(null)
      }
      ///////// VIDEO ///////
      "registerVideoFrameObserver" -> {
        Log.v("Peter", "registerVideoFrameObserver")
        if (videoObserver == null) {
          videoObserver = object : IVideoFrameObserver((call.arguments as Number).toLong()) {
            override fun onCaptureVideoFrame(videoFrame: VideoFrame): Boolean {
              //Log.v("Peter", "FUCKME FUCKME FUCKME onCaptureVideoFrame")
              Arrays.fill(videoFrame.getuBuffer(), 0)
              Arrays.fill(videoFrame.getvBuffer(), 0)
              return true
            }

            override fun onRenderVideoFrame(uid: Int, videoFrame: VideoFrame): Boolean {
              //Log.v("Peter", "FUCKME FUCKME FUCKME onRenderVideoFrame")
              // unsigned char value 255
              Arrays.fill(videoFrame.getuBuffer(), -1)
              Arrays.fill(videoFrame.getvBuffer(), -1)
              return true
            }
          }
        }
        videoObserver?.registerVideoFrameObserver()
        result.success(null)
      }
      "unregisterVideoFrameObserver" -> {
        //Log.v("Peter", "unregisterVideoFrameObserver")
        videoObserver?.let {
          it.unregisterVideoFrameObserver()
          videoObserver = null
        }
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  companion object {
    // Used to load the 'native-lib' library on application startup.
    init {
      System.loadLibrary("cpp")
    }
  }
}
