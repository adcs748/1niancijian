package com.example.niancijian;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ShortcutInfo;
import android.content.pm.ShortcutManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.Icon;
import android.net.Uri;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.util.Base64;
import android.view.KeyEvent;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.webkit.WebViewAssetLoader;

import java.util.Locale;

public class MainActivity extends AppCompatActivity {

    private static final int FILE_CHOOSER_REQUEST = 1001;
    private static final long EXIT_CONFIRM_INTERVAL = 2000L;

    private WebView webView;
    private TtsBridge ttsBridge;
    private ShortcutHelper shortcutHelper;
    private ValueCallback<Uri[]> filePathCallback;
    private long lastBackPressedAt = 0L;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        webView = new WebView(this);
        setContentView(webView);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setLoadWithOverviewMode(true);
        settings.setUseWideViewPort(true);
        settings.setCacheMode(WebSettings.LOAD_DEFAULT);

        ttsBridge = new TtsBridge();
        webView.addJavascriptInterface(ttsBridge, "AndroidTTS");

        shortcutHelper = new ShortcutHelper();
        webView.addJavascriptInterface(shortcutHelper, "AndroidShell");

        final WebViewAssetLoader assetLoader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                return assetLoader.shouldInterceptRequest(request.getUrl());
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback, FileChooserParams params) {
                if (filePathCallback != null) {
                    filePathCallback.onReceiveValue(null);
                }
                filePathCallback = callback;
                try {
                    Intent intent = params.createIntent();
                    startActivityForResult(intent, FILE_CHOOSER_REQUEST);
                    return true;
                } catch (Exception exception) {
                    filePathCallback = null;
                    return false;
                }
            }
        });

        webView.setDownloadListener((url, userAgent, contentDisposition, mimetype, contentLength) -> {
            try {
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                startActivity(intent);
            } catch (Exception ignored) {
            }
        });

        webView.loadUrl("https://appassets.androidplatform.net/assets/web-preview/index.html");
    }

    @Override
    public boolean onKeyDown(int keyCode, @NonNull KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            handleBack();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public void onBackPressed() {
        handleBack();
    }

    private void handleBack() {
        if (webView == null) {
            confirmExit();
            return;
        }
        webView.evaluateJavascript(
                "window.__androidHandleBack ? window.__androidHandleBack() : 'exit'",
                value -> {
                    String result = value == null ? "exit" : value.replace("\"", "");
                    if ("handled".equals(result)) {
                        lastBackPressedAt = 0L;
                        return;
                    }
                    confirmExit();
                }
        );
    }

    private void confirmExit() {
        long now = System.currentTimeMillis();
        if (now - lastBackPressedAt <= EXIT_CONFIRM_INTERVAL) {
            finish();
            return;
        }
        lastBackPressedAt = now;
        Toast.makeText(this, "再按一次返回键退出", Toast.LENGTH_SHORT).show();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode == FILE_CHOOSER_REQUEST) {
            if (filePathCallback != null) {
                filePathCallback.onReceiveValue(WebChromeClient.FileChooserParams.parseResult(resultCode, data));
                filePathCallback = null;
            }
            return;
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onDestroy() {
        if (ttsBridge != null) {
            ttsBridge.shutdown();
            ttsBridge = null;
        }
        shortcutHelper = null;
        if (webView != null) {
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }

    private class TtsBridge {

        private final TextToSpeech tts;
        private volatile boolean ready = false;

        TtsBridge() {
            tts = new TextToSpeech(MainActivity.this.getApplicationContext(), this::onInit);
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

        void shutdown() {
            if (tts != null) {
                tts.shutdown();
            }
        }
    }

    private class ShortcutHelper {

        @JavascriptInterface
        public boolean addShortcut(String label, String iconBase64) {
            try {
                String data = iconBase64 == null ? "" : iconBase64;
                int comma = data.indexOf(',');
                if (comma >= 0) {
                    data = data.substring(comma + 1);
                }
                byte[] bytes = Base64.decode(data, Base64.DEFAULT);
                Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                if (bitmap == null) {
                    return false;
                }

                ShortcutManager manager = (ShortcutManager) getSystemService(Context.SHORTCUT_SERVICE);
                if (manager == null || !manager.isRequestPinShortcutSupported()) {
                    return false;
                }

                Intent intent = new Intent(MainActivity.this, MainActivity.class);
                intent.setAction(Intent.ACTION_VIEW);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);

                ShortcutInfo info = new ShortcutInfo.Builder(
                        MainActivity.this,
                        "niancijian-desktop-" + System.currentTimeMillis()
                )
                        .setShortLabel(label == null || label.trim().isEmpty() ? "一念词间" : label.trim())
                        .setIcon(Icon.createWithBitmap(bitmap))
                        .setIntent(intent)
                        .build();

                return manager.requestPinShortcut(info, null);
            } catch (Exception exception) {
                return false;
            }
        }

    }
}