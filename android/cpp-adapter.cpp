#include "AudioFrameObserver.h"
#include "VideoFrameObserver.h"
#include <jni.h>
#include <mutex>

static agora::AudioFrameObserver* g_observer{nullptr};
static std::mutex mtx;

extern "C" JNIEXPORT void JNICALL
Java_io_agora_rtc_rawdata_base_IAudioFrameObserver_nativeSetEnableSetPushDirectAudio(
        JNIEnv *env, jobject, jlong nativeHandle, jboolean enableSetPushDirectAudio) {
    mtx.lock();

    if(g_observer) {
        g_observer->setEnableSetPushDirectAudio(enableSetPushDirectAudio);
    }

    mtx.unlock();
}

extern "C" JNIEXPORT jlong JNICALL
Java_io_agora_rtc_rawdata_base_IAudioFrameObserver_nativeRegisterAudioFrameObserver(
    JNIEnv *env, jobject jCaller, jlong engineHandle, jboolean enableSetPushDirectAudio) {

    mtx.lock();

    if(g_observer == nullptr) {
        g_observer = new agora::AudioFrameObserver(env, jCaller, engineHandle, enableSetPushDirectAudio);
    }

    g_observer->setEnableSetPushDirectAudio(false);
    g_observer->setNativeHandler(engineHandle);
    g_observer->registerAudioFrameObserver();

    jlong ret = reinterpret_cast<intptr_t>(g_observer);

    mtx.unlock();

    return ret;
}

extern "C" JNIEXPORT void JNICALL
Java_io_agora_rtc_rawdata_base_IAudioFrameObserver_nativeUnregisterAudioFrameObserver(
    JNIEnv *, jobject, jlong nativeHandle) {
    mtx.lock();

    if(g_observer) {
        g_observer->setEnableSetPushDirectAudio(false);
        g_observer->unregisterAudioFrameObserver();
        g_observer->setNativeHandler(0);
    }

    mtx.unlock();
}

extern "C" JNIEXPORT jlong JNICALL
Java_io_agora_rtc_rawdata_base_IVideoFrameObserver_nativeRegisterVideoFrameObserver(
    JNIEnv *env, jobject jCaller, jlong engineHandle) {
  auto observer = new agora::VideoFrameObserver(env, jCaller, engineHandle);
  jlong ret = reinterpret_cast<intptr_t>(observer);
  return ret;
}

extern "C" JNIEXPORT void JNICALL
Java_io_agora_rtc_rawdata_base_IVideoFrameObserver_nativeUnregisterVideoFrameObserver(
    JNIEnv *, jobject, jlong nativeHandle) {
  auto observer = reinterpret_cast<agora::VideoFrameObserver *>(nativeHandle);
  delete observer;
}
