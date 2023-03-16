import Flutter
import UIKit

public class SwiftAgoraRtcRawdataPlugin: NSObject, FlutterPlugin, AgoraAudioFrameDelegate, AgoraVideoFrameDelegate, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events;
        return nil;
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil;
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "agora_rtc_rawdata", binaryMessenger: registrar.messenger())
        let instance = SwiftAgoraRtcRawdataPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let event_channel = FlutterEventChannel(name: "agora_rtc_rawdata_events", binaryMessenger: registrar.messenger())
        event_channel.setStreamHandler(instance)
    }

    private var audioObserver: AgoraAudioFrameObserver?
    private var videoObserver: AgoraVideoFrameObserver?

    private var enableSetPushDirectAudio: Bool = false

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPushDirectAudioEnable":
            result(enableSetPushDirectAudio)
        case "setPushDirectAudioEnable":
            enableSetPushDirectAudio = call.arguments as! Bool
            result(nil)
        case "registerAudioFrameObserver":
            if audioObserver == nil {
                audioObserver = AgoraAudioFrameObserver(engineHandle: call.arguments as! UInt)
            }
            audioObserver?.delegate = self
            audioObserver?.register()
            result(nil)
        case "unregisterAudioFrameObserver":
            if audioObserver != nil {
                audioObserver?.delegate = nil
                audioObserver?.unregisterAudioFrameObserver()
                audioObserver = nil
            }
            result(nil)
        case "registerVideoFrameObserver":
            if videoObserver == nil {
                videoObserver = AgoraVideoFrameObserver(engineHandle: call.arguments as! UInt)
            }
            videoObserver?.delegate = self
            videoObserver?.register()
            result(nil)
        case "unregisterVideoFrameObserver":
            if videoObserver != nil {
                videoObserver?.delegate = nil
                videoObserver?.unregisterVideoFrameObserver()
                videoObserver = nil
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func onRecord(_ frame: AgoraAudioFrame) -> Bool {
        NSLog("Peter onRecordAudioFrame 33333 " + String(enableSetPushDirectAudio))

        if(enableSetPushDirectAudio) {
            //TODO:FUCKME
            NSLog("Peter onRecordAudioFrame 44444")

            return true
        }
        
        guard let eventSink = eventSink else {return true};
        let buffer_data = Data(bytesNoCopy: frame.buffer, count: Int(frame.samples * frame.bytesPerSample * frame.channels), deallocator: .none)
        let map: [String : Any] = [
            "buffer":FlutterStandardTypedData(bytes: buffer_data),
            "samples": frame.samples
        ]
        eventSink(map)
        return true
    }

    public func onPlaybackAudioFrame(_: AgoraAudioFrame) -> Bool {
        return true
    }

    public func onMixedAudioFrame(_: AgoraAudioFrame) -> Bool {
        return true
    }

    public func onPlaybackAudioFrame(beforeMixing _: AgoraAudioFrame, uid _: UInt) -> Bool {
        return true
    }

    public func onCapture(_ videoFrame: AgoraVideoFrame) -> Bool {
        memset(videoFrame.uBuffer, 0, Int(videoFrame.uStride * videoFrame.height) / 2)
        memset(videoFrame.vBuffer, 0, Int(videoFrame.vStride * videoFrame.height) / 2)
        return true
    }

    public func onRenderVideoFrame(_ videoFrame: AgoraVideoFrame, uid _: UInt) -> Bool {
        memset(videoFrame.uBuffer, 255, Int(videoFrame.uStride * videoFrame.height) / 2)
        memset(videoFrame.vBuffer, 255, Int(videoFrame.vStride * videoFrame.height) / 2)
        return true
    }
}
