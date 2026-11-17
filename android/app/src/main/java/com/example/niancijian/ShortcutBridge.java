package com.example.niancijian;

import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;
import android.webkit.JavascriptInterface;

import androidx.core.content.pm.ShortcutInfoCompat;
import androidx.core.content.pm.ShortcutManagerCompat;
import androidx.core.graphics.drawable.IconCompat;

public class ShortcutBridge {

    private final Context context;

    public ShortcutBridge(Context context) {
        this.context = context;
    }

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

            Intent intent = new Intent(context, MainActivity.class);
            intent.setAction(Intent.ACTION_VIEW);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);

            ShortcutInfoCompat shortcut = new ShortcutInfoCompat.Builder(
                    context,
                    "niancijian-desktop-" + System.currentTimeMillis()
            )
                    .setShortLabel(label == null || label.trim().isEmpty() ? "一念词间" : label.trim())
                    .setIcon(IconCompat.createWithBitmap(bitmap))
                    .setIntent(intent)
                    .build();

            return ShortcutManagerCompat.requestPinShortcut(context, shortcut, null);
        } catch (Exception exception) {
            return false;
        }
    }
}