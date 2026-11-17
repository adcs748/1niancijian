package com.example.niancijian;

import android.content.Context;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import java.util.Locale;

public class TTSBridge {

    private final TextToSpeech tts;
    private final WebView webView;
    private volatile boolean ready = false;

    public TTSBridge(Context context, WebView webView) {
        this.webView = webView;
        this.tts = new TextToSpeech(context.getApplicationContext(), this::onInit);
    }

    private void onInit(int status) {
        if (status != TextToSpeech.SUCCESS || tts == null) {
            return;
        }
        int result = tts.setLanguage(Locale.US);
        ready = result != TextToSpeech.LANG_MISSING_DATA
                && result != TextToSpeech.LANG_NOT_SUPPORTED;
        tts.setOnUtteranceProgressListener(new UtteranceProgressListener() {
            @Override
            public void onStart(String utteranceId) {
            }

            @Override
            public void onDone(String utteranceId) {
                notifyDone();
            }

            @Override
            public void onError(String utteranceId) {
                notifyDone();
            }
        });
    }

    private void notifyDone() {
        if (webView == null) return;
        webView.post(() -> {
            if (webView != null) {
                webView.evaluateJavascript("window.__nativeTTSDone && window.__nativeTTSDone();", null);
            }
        });
    }

    @JavascriptInterface
    public boolean isReady() {
        return ready;
    }

    @JavascriptInterface
    public void speak(String text) {
        speak(text, "en-US");
    }

    @JavascriptInterface
    public void speak(String text, String lang) {
        if (!ready || text == null) return;
        String content = text.trim();
        if (content.isEmpty()) return;
        if (content.length() > 1200) {
            content = content.substring(0, 1200);
        }
        Locale locale = "zh-CN".equals(lang) ? Locale.SIMPLIFIED_CHINESE : Locale.US;
        tts.setLanguage(locale);
        tts.speak(content, TextToSpeech.QUEUE_FLUSH, null, "ec-" + System.currentTimeMillis());
    }

    @JavascriptInterface
    public void stop() {
        if (tts != null) {
            tts.stop();
        }
    }

    public void shutdown() {
        if (tts != null) {
            tts.shutdown();
        }
    }
}