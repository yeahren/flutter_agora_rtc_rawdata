//
//  AgoraAudioFrameObserver.mm
//  react-native-agora-rawdata
//
//  Created by LXH on 2020/11/10.
// 

#import "AgoraAudioFrameObserver.h"

#import <AgoraRtcKit/IAgoraMediaEngine.h>
#import <AgoraRtcKit/IAgoraRtcEngine.h>

namespace agora { 
class AudioFrameObserver : public media::IAudioFrameObserver {
public:
    AudioFrameObserver(long long engineHandle, void *observer, bool enableSetPushDirectAudio)
    : engineHandle(engineHandle), observer(observer), enableSetPushDirectAudio(enableSetPushDirectAudio) {
        auto rtcEngine = reinterpret_cast<rtc::IRtcEngine *>(engineHandle);
        if (rtcEngine) {
            _mediaEngine.queryInterface(rtcEngine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
        }
    }
    
    void registerAudioFrameObserver() {
        if (_mediaEngine) {
            _mediaEngine->setDirectExternalAudioSource(true);
            _mediaEngine->registerAudioFrameObserver(this);
        }
    }
    
    void unregisterAudioFrameOserver() {
        if (_mediaEngine) {
            _mediaEngine->setDirectExternalAudioSource(false);
            _mediaEngine->registerAudioFrameObserver(nullptr);
        }
    }
    
    virtual ~AudioFrameObserver() {
        unregisterAudioFrameOserver();
    }
    
public:
    bool onPublishAudioFrame(const char* channelId,
                             agora::media::IAudioFrameObserver::AudioFrame& audioFrame) override{
        return true;
    }
    
    bool onRecordAudioFrame(const char* channelId, AudioFrame& audioFrame) override {
        @autoreleasepool {
            AgoraAudioFrame *audioFrameApple = NativeToAppleAudioFrame(audioFrame);
            
            AgoraAudioFrameObserver *observerApple =
            (__bridge AgoraAudioFrameObserver *)observer;
            
            NSLog(@"%s: %s: %d", "Peter", "onRecordAudioFrame - enableSetPushDirectAudio", bool(enableSetPushDirectAudio));
            
            //--For Fucking Chorus Support--
            if(enableSetPushDirectAudio) {
                if (_mediaEngine) {
                    auto ret = _mediaEngine->pushDirectAudioFrame(&audioFrame);
                    NSLog(@"%s: %s: %d", "Peter", "mediaEngine->pushDirectAudioFram", ret);
                }
            }
            //--
            
            if (observerApple.delegate != nil &&
                [observerApple.delegate
                 respondsToSelector:@selector(onRecordAudioFrame:)]) {
                return [observerApple.delegate onRecordAudioFrame:audioFrameApple];
            }
        }
        return true;
    }
    
    bool onPlaybackAudioFrame(const char* channelId, AudioFrame& audioFrame) override {
        @autoreleasepool {
            AgoraAudioFrame *audioFrameApple = NativeToAppleAudioFrame(audioFrame);
            
            AgoraAudioFrameObserver *observerApple =
            (__bridge AgoraAudioFrameObserver *)observer;
            if (observerApple.delegate != nil &&
                [observerApple.delegate
                 respondsToSelector:@selector(onPlaybackAudioFrame:)]) {
                return [observerApple.delegate onPlaybackAudioFrame:audioFrameApple];
            }
        }
        return true;
    }
    
    bool onMixedAudioFrame(const char* channelId, AudioFrame& audioFrame) override {
        @autoreleasepool {
            AgoraAudioFrame *audioFrameApple = NativeToAppleAudioFrame(audioFrame);
            
            AgoraAudioFrameObserver *observerApple =
            (__bridge AgoraAudioFrameObserver *)observer;
            if (observerApple.delegate != nil &&
                [observerApple.delegate
                 respondsToSelector:@selector(onMixedAudioFrame:)]) {
                return [observerApple.delegate onMixedAudioFrame:audioFrameApple];
            }
        }
        return true;
    }
    
    bool onPlaybackAudioFrameBeforeMixing(
                                          const char* channelId, rtc::uid_t uid, AudioFrame& audioFrame) override {
                                              @autoreleasepool {
                                                  AgoraAudioFrame *audioFrameApple = NativeToAppleAudioFrame(audioFrame);
                                                  
                                                  AgoraAudioFrameObserver *observerApple =
                                                  (__bridge AgoraAudioFrameObserver *)observer;
                                                  if (observerApple.delegate != nil &&
                                                      [observerApple.delegate respondsToSelector:@selector
                                                       (onPlaybackAudioFrameBeforeMixing:uid:)]) {
                                                      return [observerApple.delegate
                                                              onPlaybackAudioFrameBeforeMixing:audioFrameApple
                                                              uid:uid];
                                                  }
                                              }
                                              return true;
                                          }
    
    bool onEarMonitoringAudioFrame(
                                   media::IAudioFrameObserverBase::AudioFrame &audioFrame) {
        return false;
    }
    
    int getObservedAudioFramePosition() override {
        return 0;
    }
    
    AudioParams getPublishAudioParams() override {
        return media::IAudioFrameObserverBase::AudioParams();
    }
    
    media::IAudioFrameObserverBase::AudioParams getPlaybackAudioParams() override {
        return media::IAudioFrameObserverBase::AudioParams();
    }
    
    media::IAudioFrameObserverBase::AudioParams getRecordAudioParams() override {
        return media::IAudioFrameObserverBase::AudioParams();
    }
    
    media::IAudioFrameObserverBase::AudioParams getMixedAudioParams() override {
        return media::IAudioFrameObserverBase::AudioParams();
    }
    
    media::IAudioFrameObserverBase::AudioParams getEarMonitoringAudioParams() {
        return media::IAudioFrameObserverBase::AudioParams();
    }
    
private:
    AgoraAudioFrame *NativeToAppleAudioFrame(AudioFrame &audioFrame) {
        AgoraAudioFrame *audioFrameApple = [[AgoraAudioFrame alloc] init];
        audioFrameApple.type = (AgoraAudioFrameType)audioFrame.type;
        audioFrameApple.samples = audioFrame.samplesPerChannel;
        audioFrameApple.bytesPerSample = audioFrame.bytesPerSample;
        audioFrameApple.channels = audioFrame.channels;
        audioFrameApple.samplesPerSec = audioFrame.samplesPerSec;
        audioFrameApple.buffer = audioFrame.buffer;
        audioFrameApple.renderTimeMs = audioFrame.renderTimeMs;
        audioFrameApple.avsync_type = audioFrame.avsync_type;
        return audioFrameApple;
    }
    
private:
    void *observer;
    long long engineHandle;
    util::AutoPtr<media::IMediaEngine> _mediaEngine;
public:
    std::atomic<bool> enableSetPushDirectAudio {false};
};
}

@interface AgoraAudioFrameObserver ()
@property(nonatomic) agora::AudioFrameObserver *observer;
@end

@implementation AgoraAudioFrameObserver

- (instancetype)initWithEngineHandle:(NSUInteger)engineHandle :(bool)enableSetPushDirectAudio {
    if (self = [super init]) {
        self.engineHandle = engineHandle;
        self.enableSetPushDirectAudio = enableSetPushDirectAudio;
    }
    return self;
}

- (instancetype)initWithEngineHandle:(NSUInteger)engineHandle {
    return [self initWithEngineHandle:engineHandle :false];
}

- (void)setEnableSetPushDirectAudio:(bool)enable {
    if(_observer) {
        _observer->enableSetPushDirectAudio = enable;
    }
    
    _enableSetPushDirectAudio = enable;
}

- (void)registerAudioFrameObserver {
    if (!_observer) {
        _observer =
        new agora::AudioFrameObserver(_engineHandle, (__bridge void *)self, self.enableSetPushDirectAudio);
    }
    
    _observer->registerAudioFrameObserver();
}

- (void)unregisterAudioFrameObserver {
    if (_observer) {
        _observer->unregisterAudioFrameOserver();
    }
}

@end
