package com.kts.saycap;

import android.Manifest;
import android.app.Activity;
import android.app.DownloadManager;
import android.content.ContentUris;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.provider.OpenableColumns;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.util.Base64;
import android.util.LruCache;
import android.view.KeyEvent;
import android.webkit.JavascriptInterface;
import android.webkit.JsResult;
import android.webkit.PermissionRequest;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

/**
 * KTS 세이캡 — 고정 URL 연결형 + 로컬 사본 폴백 + 기기 잠금.
 *
 * v1.3 (2026-11-16) — 대표님 실기기 피드백 3건
 *  1) [버그] 갤러리에서 사진을 골라도 앱으로 안 불러와지던 문제
 *     → content:// URI를 WebView 파일 선택창에 넘기지 않고, 앱이 직접 바이트를 읽어
 *       __npBegin/__npChunk/__npEnd 로 넘긴다(모든 안드로이드 버전·모든 갤러리 앱 호환).
 *  2) 앱을 열면 폰의 최신 사진 1장이 바로 뜨고 오른쪽 마이크(받아쓰기)가 자동으로 켜진다.
 *     → MediaStore 최신 이미지 + 네이티브 음성인식(SpeechRecognizer, WebView는 음성인식 미지원).
 *     사진은 MediaStore id로 같은 기록을 다시 열기 때문에 일기가 중복되지 않는다.
 *  3) 공유(카메라 → 공유 → 세이캡) 동선은 그대로 병행 유지.
 *
 * v1.5 (2026-11-17) — 어디서든 '내 폰 사진'
 *  · SayCapApp.listPhotos(offset, limit) : MediaStore.Images 최신순 목록(JSON, content:// URI·날짜·크기)
 *  · 가상 경로 __saycap_thumb?id=…&s=… (썸네일 JPEG) / __saycap_media?id=… (원본 바이트)
 *    → shouldInterceptRequest 가 직접 응답하므로 웹뷰가 content:// 를 몰라도 <img>·fetch 로 바로 쓴다.
 *  · 사진 권한: API 33+ READ_MEDIA_IMAGES(34+ 부분 허용 READ_MEDIA_VISUAL_USER_SELECTED 포함), 그 아래 READ_EXTERNAL_STORAGE
 *  · 음성인식 소리 크기(onRmsChanged) → window.__saycapRms (자막 아래 이퀄라이저)
 */
public class MainActivity extends Activity {

    private static final String REMOTE = "https://kim779944-max.github.io/K0612766940K-/saycap/";
    private static final String LOCAL = "file:///android_asset/app.html";
    private static final String LOCK = "file:///android_asset/lock.html";
    private static final int REQ_FILE = 1001;
    private static final int REQ_PERM = 1002;
    private static final int REQ_PICK = 1003;
    private static final int REQ_MEDIA = 1004;

    /* v1.5 폰 사진 목록용 가상 경로 */
    private static final String THUMB_PATH = "__saycap_thumb";
    private static final String MEDIA_PATH = "__saycap_media";
    private static final String PERM_USER_SELECTED = "android.permission.READ_MEDIA_VISUAL_USER_SELECTED";
    private final LruCache<String, byte[]> thumbCache = new LruCache<String, byte[]>(12 * 1024 * 1024) {
        @Override protected int sizeOf(String k, byte[] v) { return v.length; }
    };
    private volatile long lastRmsAt = 0;

    /* 공유로 들어온 사진이 건네지는 가상 경로 (실제 네트워크에는 나가지 않음) */
    private static final String SHARE_PATH = "__saycap_share";
    private static final int SHARE_MAX = 40 * 1024 * 1024;   // 40MB
    private static final int PHOTO_MAX = 40 * 1024 * 1024;
    private static final int CHUNK = 192 * 1024;             // base64 조각 크기(원본 바이트)

    private WebView web;
    private ValueCallback<Uri[]> filePathCallback;
    private boolean fallbackDone = false;
    private volatile byte[] sharedBytes = null;
    private volatile String sharedMime = "image/jpeg";

    private volatile boolean wantLatestPending = false;

    private SpeechRecognizer recog;
    private boolean recogOn = false;
    private int noSpeechCount = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        web = new WebView(this);
        setContentView(web);

        /* targetSdk 35(안드로이드 15)부터 화면이 시스템 막대 아래까지 그려집니다.
           앱 화면이 상태바·내비바에 가리지 않도록 여백을 직접 잡아 줍니다. */
        if (Build.VERSION.SDK_INT >= 30) {
            getWindow().setDecorFitsSystemWindows(false);
        }
        web.setOnApplyWindowInsetsListener((v, insets) -> {
            int top, bottom;
            if (Build.VERSION.SDK_INT >= 30) {
                android.graphics.Insets sb = insets.getInsets(android.view.WindowInsets.Type.systemBars());
                top = sb.top; bottom = sb.bottom;
            } else {
                top = insets.getSystemWindowInsetTop();
                bottom = insets.getSystemWindowInsetBottom();
            }
            v.setPadding(0, top, 0, bottom);
            return insets;
        });

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setAllowFileAccess(true);
        s.setAllowContentAccess(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setLoadWithOverviewMode(true);
        s.setUseWideViewPort(true);
        s.setSupportZoom(true);
        s.setBuiltInZoomControls(false);
        s.setCacheMode(WebSettings.LOAD_DEFAULT);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE);

        web.setWebViewClient(new WebViewClient() {
            /* 공유로 받은 사진을 메모리에서 바로 넘긴다 (원본 화질·외부 전송 0) */
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView v, WebResourceRequest req) {
                try {
                    String path = req.getUrl().getPath();
                    if (path != null && path.endsWith(SHARE_PATH)) {
                        Map<String, String> h = new HashMap<>();
                        h.put("Access-Control-Allow-Origin", "*");
                        h.put("Cache-Control", "no-store");
                        byte[] data = sharedBytes;
                        if (data != null && data.length > 0) {
                            return new WebResourceResponse(sharedMime, null, 200, "OK", h,
                                    new ByteArrayInputStream(data));
                        }
                        return new WebResourceResponse("text/plain", "utf-8", 404, "Not Found", h,
                                new ByteArrayInputStream(new byte[0]));
                    }
                    /* v1.5 폰 사진 썸네일 · 원본 (MediaStore id) */
                    if (path != null && (path.endsWith(THUMB_PATH) || path.endsWith(MEDIA_PATH))) {
                        return serveMedia(req.getUrl(), path.endsWith(THUMB_PATH));
                    }
                } catch (Exception ignored) { }
                return null;
            }
            @Override
            public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest req) {
                Uri u = req.getUrl();
                String us = u.toString();
                if (us.startsWith("tel:") || us.startsWith("sms:") || us.startsWith("mailto:")) {
                    try { startActivity(new Intent(Intent.ACTION_VIEW, u)); return true; } catch (Exception ignored) { }
                }
                return false;
            }
            @Override
            public void onReceivedError(WebView v, WebResourceRequest req, WebResourceError err) {
                if (req.isForMainFrame() && !fallbackDone && !isLocked()) {
                    fallbackDone = true;
                    Toast.makeText(MainActivity.this, "오프라인 사본으로 엽니다", Toast.LENGTH_SHORT).show();
                    v.loadUrl(LOCAL);
                }
            }
        });

        web.setWebChromeClient(new WebChromeClient() {
            /* 웹이 마이크·카메라를 요청하면 앱 권한을 확인하고 허용 */
            @Override
            public void onPermissionRequest(final PermissionRequest request) {
                runOnUiThread(() -> request.grant(request.getResources()));
            }
            /* <input type=file> — 웹뷰에 content:// 를 넘기지 않고 앱이 직접 고른다.
               (기기·갤러리 앱에 따라 WebView가 content URI를 못 읽어 "선택은 되는데 안 열리는" 원인) */
            @Override
            public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb, FileChooserParams params) {
                if (filePathCallback != null) filePathCallback.onReceiveValue(null);
                filePathCallback = null;
                cb.onReceiveValue(null);        // 웹뷰 쪽 선택은 비우고, 앱이 직접 받아 넘긴다
                openPicker();
                return true;
            }
            @Override
            public boolean onJsAlert(WebView v, String url, String msg, JsResult r) { return super.onJsAlert(v, url, msg, r); }
        });

        /* 저장 — 시스템 다운로드로 넘긴다 */
        web.setDownloadListener((url, userAgent, contentDisposition, mimeType, contentLength) -> {
            try {
                if (url.startsWith("blob:")) {
                    Toast.makeText(this, "이 브라우저에서는 공유로 저장해 주세요", Toast.LENGTH_LONG).show();
                    return;
                }
                DownloadManager.Request req = new DownloadManager.Request(Uri.parse(url));
                req.setMimeType(mimeType);
                req.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                req.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS,
                        android.webkit.URLUtil.guessFileName(url, contentDisposition, mimeType));
                DownloadManager dm = (DownloadManager) getSystemService(Context.DOWNLOAD_SERVICE);
                if (dm != null) dm.enqueue(req);
            } catch (Exception e) {
                Toast.makeText(this, "저장하지 못했습니다", Toast.LENGTH_SHORT).show();
            }
        });

        /* v1.3: 웹과 앱을 잇는 다리 — 최신 사진 · 사진 고르기 · 받아쓰기 */
        web.addJavascriptInterface(new Bridge(), "SayCapApp");

        if (isLocked()) { web.loadUrl(LOCK); return; }
        askPermissions();
        boolean shared = handleShareIntent(getIntent());
        web.loadUrl(shared ? REMOTE + "?share=1&native=1" : REMOTE + "?native=1");
    }

    /* =========================================================
       v1.3 JS 브리지
       ========================================================= */
    public class Bridge {
        @JavascriptInterface
        public String version() { return "1.5"; }

        /* v1.5 폰 전체 사진 목록 (최신순, offset/limit 페이지) — 권한이 없으면 {"perm":false} 후 권한 요청,
           결과는 window.__devPhotosReady(true|false) 로 알려 준다. */
        @JavascriptInterface
        public String listPhotos(int offset, int limit) { return listPhotosJson(offset, limit); }

        /* v1.5 목록에서 고른 사진 1장을 기존 조각 전달 경로(__npBegin… → __npAllDone)로 넘긴다 (가상 경로를 못 쓸 때 대비) */
        @JavascriptInterface
        public void openPhoto(String id) { openPhotoById(id); }

        /* 앱을 열면 최신 사진 1장을 넘겨 달라 */
        @JavascriptInterface
        public void wantLatest() { runOnUiThread(MainActivity.this::requestLatest); }

        /* 다른 사진 고르기 — 시스템 사진 선택기 */
        @JavascriptInterface
        public void pick() { runOnUiThread(MainActivity.this::openPicker); }

        /* 받아쓰기 (WebView는 Web Speech API가 없어 네이티브 인식기로 처리) */
        @JavascriptInterface
        public void startSTT() { runOnUiThread(MainActivity.this::startRecognition); }

        @JavascriptInterface
        public void stopSTT() { runOnUiThread(MainActivity.this::stopRecognition); }
    }

    /* =========================================================
       사진 바이트 전달 — __npBegin / __npChunk / __npEnd
       (content:// 나 파일 경로를 웹에 노출하지 않는다 · 오프라인 사본에서도 동작)
       ========================================================= */
    private void post(final String jsCode) {
        runOnUiThread(() -> {
            try { if (web != null) web.evaluateJavascript(jsCode, null); } catch (Exception ignored) { }
        });
    }

    private static String q(String s) {
        if (s == null) s = "";
        StringBuilder b = new StringBuilder("'");
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '\'' || c == '\\') b.append('\\').append(c);
            else if (c < 0x20) b.append(' ');
            else b.append(c);
        }
        return b.append("'").toString();
    }

    private void deliverBytes(String key, String name, String mime, byte[] data) {
        if (data == null || data.length == 0) return;
        post("window.__npBegin&&window.__npBegin(" + q(key) + "," + q(name) + "," + q(mime) + "," + data.length + ")");
        int idx = 0;
        for (int off = 0; off < data.length; off += CHUNK) {
            int len = Math.min(CHUNK, data.length - off);
            String b64 = Base64.encodeToString(data, off, len, Base64.NO_WRAP);
            post("window.__npChunk&&window.__npChunk(" + idx + ",'" + b64 + "')");
            idx++;
        }
        post("window.__npEnd&&window.__npEnd(" + q(key) + ")");
    }

    /* =========================================================
       최신 사진 (MediaStore)
       ========================================================= */
    private boolean hasMediaPermission() {
        if (Build.VERSION.SDK_INT >= 33) {
            if (checkSelfPermission(Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED) return true;
            /* 안드로이드 14+: '사진 일부만 허용'도 그 사진들은 목록에 보이도록 */
            return Build.VERSION.SDK_INT >= 34
                    && checkSelfPermission(PERM_USER_SELECTED) == PackageManager.PERMISSION_GRANTED;
        }
        return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
    }

    private boolean mediaAskPending = false;

    private void askMediaPermission() {
        if (mediaAskPending) return;
        mediaAskPending = true;
        String[] need;
        if (Build.VERSION.SDK_INT >= 34) {
            need = new String[]{Manifest.permission.READ_MEDIA_IMAGES, PERM_USER_SELECTED};
        } else if (Build.VERSION.SDK_INT >= 33) {
            need = new String[]{Manifest.permission.READ_MEDIA_IMAGES};
        } else {
            need = new String[]{Manifest.permission.READ_EXTERNAL_STORAGE};
        }
        try {
            requestPermissions(need, REQ_MEDIA);
        } catch (Exception e) {
            mediaAskPending = false;
            post("window.__devPhotosReady&&window.__devPhotosReady(false)");
        }
    }

    /* =========================================================
       v1.5 폰 사진 목록 (MediaStore.Images) — JS 브리지 스레드에서 바로 조회
       ========================================================= */
    private String listPhotosJson(int offset, int limit) {
        if (!hasMediaPermission()) {
            runOnUiThread(MainActivity.this::askMediaPermission);
            return "{\"perm\":false}";
        }
        if (offset < 0) offset = 0;
        if (limit <= 0 || limit > 200) limit = 60;
        Cursor c = null;
        try {
            String[] proj = {
                    MediaStore.Images.Media._ID,
                    MediaStore.Images.Media.DISPLAY_NAME,
                    MediaStore.Images.Media.DATE_TAKEN,
                    MediaStore.Images.Media.DATE_ADDED,
                    MediaStore.Images.Media.WIDTH,
                    MediaStore.Images.Media.HEIGHT,
                    MediaStore.Images.Media.MIME_TYPE
            };
            /* 최신순 — 페이지는 커서 위치로 자른다 (안드로이드 11+는 정렬문에 LIMIT를 못 쓴다) */
            String order = MediaStore.Images.Media.DATE_ADDED + " DESC, " + MediaStore.Images.Media._ID + " DESC";
            c = getContentResolver().query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, proj, null, null, order);
            JSONObject out = new JSONObject();
            JSONArray arr = new JSONArray();
            int total = c == null ? 0 : c.getCount();
            if (c != null && offset < total && c.moveToPosition(offset)) {
                int n = 0;
                do {
                    long id = c.getLong(0);
                    long taken = c.isNull(2) ? 0L : c.getLong(2);
                    long added = c.isNull(3) ? 0L : c.getLong(3) * 1000L;
                    JSONObject o = new JSONObject();
                    o.put("id", String.valueOf(id));
                    o.put("uri", ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id).toString());
                    o.put("name", c.isNull(1) ? "" : c.getString(1));
                    o.put("date", taken > 0 ? taken : added);
                    o.put("w", c.isNull(4) ? 0 : c.getInt(4));
                    o.put("h", c.isNull(5) ? 0 : c.getInt(5));
                    o.put("mime", c.isNull(6) ? "image/jpeg" : c.getString(6));
                    arr.put(o);
                    n++;
                } while (n < limit && c.moveToNext());
            }
            out.put("perm", true);
            out.put("total", total);
            out.put("offset", offset);
            out.put("items", arr);
            return out.toString();
        } catch (Exception e) {
            return "{\"perm\":true,\"total\":0,\"items\":[],\"error\":true}";
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignored) { }
        }
    }

    private static long parseId(String s) {
        try { return Long.parseLong(s == null ? "" : s.trim()); } catch (Exception e) { return -1L; }
    }

    private static WebResourceResponse notFound(Map<String, String> h) {
        return new WebResourceResponse("text/plain", "utf-8", 404, "Not Found", h,
                new ByteArrayInputStream(new byte[0]));
    }

    /* __saycap_thumb?id=…&s=… → 썸네일 JPEG / __saycap_media?id=… → 원본 그대로 */
    private WebResourceResponse serveMedia(Uri url, boolean thumb) {
        Map<String, String> h = new HashMap<>();
        h.put("Access-Control-Allow-Origin", "*");
        h.put("Cache-Control", thumb ? "max-age=86400" : "no-store");
        long id = parseId(url.getQueryParameter("id"));
        if (id < 0 || !hasMediaPermission()) return notFound(h);
        Uri uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id);
        if (thumb) {
            int size = 320;
            try { size = Integer.parseInt(url.getQueryParameter("s")); } catch (Exception ignored) { }
            size = Math.max(96, Math.min(640, size));
            byte[] b = thumbBytes(id, uri, size);
            if (b == null) return notFound(h);
            return new WebResourceResponse("image/jpeg", null, 200, "OK", h, new ByteArrayInputStream(b));
        }
        String mime = null;
        try { mime = getContentResolver().getType(uri); } catch (Exception ignored) { }
        if (mime == null || !mime.startsWith("image/")) mime = "image/jpeg";
        try {
            InputStream in = getContentResolver().openInputStream(uri);
            if (in == null) return notFound(h);
            return new WebResourceResponse(mime, null, 200, "OK", h, in);
        } catch (Exception e) {
            return notFound(h);
        }
    }

    private byte[] thumbBytes(long id, Uri uri, int size) {
        String key = id + ":" + size;
        byte[] hit = thumbCache.get(key);
        if (hit != null) return hit;
        Bitmap bm = null;
        boolean rotated = false;
        try {
            if (Build.VERSION.SDK_INT >= 29) {
                bm = getContentResolver().loadThumbnail(uri, new android.util.Size(size, size), null);
                rotated = true;              // loadThumbnail 은 사진 방향까지 맞춰 준다
            } else {
                bm = MediaStore.Images.Thumbnails.getThumbnail(getContentResolver(), id,
                        MediaStore.Images.Thumbnails.MINI_KIND, null);
            }
        } catch (Throwable ignored) { bm = null; }
        if (bm == null) { bm = decodeSampled(uri, size); rotated = false; }
        if (bm == null) return null;
        if (!rotated) {
            int deg = orientationOf(id);
            if (deg != 0) {
                try {
                    android.graphics.Matrix m = new android.graphics.Matrix();
                    m.postRotate(deg);
                    Bitmap r = Bitmap.createBitmap(bm, 0, 0, bm.getWidth(), bm.getHeight(), m, true);
                    if (r != bm) { bm.recycle(); bm = r; }
                } catch (Throwable ignored) { }
            }
        }
        ByteArrayOutputStream bo = new ByteArrayOutputStream();
        try { bm.compress(Bitmap.CompressFormat.JPEG, 82, bo); } catch (Throwable e) { return null; }
        finally { try { bm.recycle(); } catch (Throwable ignored) { } }
        byte[] out = bo.toByteArray();
        if (out.length > 0) thumbCache.put(key, out);
        return out.length > 0 ? out : null;
    }

    private int orientationOf(long id) {
        Cursor c = null;
        try {
            c = getContentResolver().query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    new String[]{MediaStore.Images.Media.ORIENTATION},
                    MediaStore.Images.Media._ID + "=?", new String[]{String.valueOf(id)}, null);
            if (c != null && c.moveToFirst() && !c.isNull(0)) return c.getInt(0);
        } catch (Exception ignored) {
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignored) { }
        }
        return 0;
    }

    private Bitmap decodeSampled(Uri uri, int size) {
        InputStream in = null;
        try {
            BitmapFactory.Options o = new BitmapFactory.Options();
            o.inJustDecodeBounds = true;
            in = getContentResolver().openInputStream(uri);
            if (in == null) return null;
            BitmapFactory.decodeStream(in, null, o);
            in.close();
            in = null;
            int s = 1;
            while (o.outWidth / (s * 2) >= size && o.outHeight / (s * 2) >= size) s *= 2;
            BitmapFactory.Options o2 = new BitmapFactory.Options();
            o2.inSampleSize = s;
            in = getContentResolver().openInputStream(uri);
            if (in == null) return null;
            return BitmapFactory.decodeStream(in, null, o2);
        } catch (Throwable e) {
            return null;
        } finally {
            try { if (in != null) in.close(); } catch (Exception ignored) { }
        }
    }

    /* 목록에서 고른 사진 → 조각 전달(가상 경로를 못 쓰는 환경 대비) */
    private void openPhotoById(final String sid) {
        new Thread(() -> {
            long id = parseId(sid);
            if (id < 0 || !hasMediaPermission()) {
                post("window.__npFail&&window.__npFail('none')");
                return;
            }
            Uri uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id);
            byte[] data = readAll(uri, PHOTO_MAX);
            if (data == null || data.length == 0) {
                post("window.__npFail&&window.__npFail('none')");
                return;
            }
            String mime = null;
            try { mime = getContentResolver().getType(uri); } catch (Exception ignored) { }
            String name = displayName(uri);
            if (mime == null || !mime.startsWith("image/")) mime = guessMime(name);
            if (name == null || name.trim().length() == 0) name = "SayCap_" + id + ".jpg";
            deliverBytes("pick:0", name, mime, data);
            post("window.__npAllDone&&window.__npAllDone(1)");
        }).start();
    }

    private void requestLatest() {
        if (!hasMediaPermission()) {
            wantLatestPending = true;
            askPermissions();
            return;
        }
        loadLatestAsync();
    }

    private void loadLatestAsync() {
        new Thread(() -> {
            long id = -1;
            String name = null, mime = null;
            Cursor c = null;
            try {
                String[] proj = {
                        MediaStore.Images.Media._ID,
                        MediaStore.Images.Media.DISPLAY_NAME,
                        MediaStore.Images.Media.MIME_TYPE
                };
                String order = MediaStore.Images.Media.DATE_TAKEN + " DESC, "
                        + MediaStore.Images.Media.DATE_ADDED + " DESC";
                c = getContentResolver().query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, proj,
                        null, null, order);
                if (c != null && c.moveToFirst()) {
                    id = c.getLong(0);
                    name = c.getString(1);
                    mime = c.getString(2);
                }
            } catch (Exception ignored) {
            } finally {
                try { if (c != null) c.close(); } catch (Exception ignored) { }
            }

            if (id < 0) {
                post("window.__npFail&&window.__npFail('none')");
                return;
            }
            Uri uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id);
            byte[] data = readAll(uri, PHOTO_MAX);
            if (data == null || data.length == 0) {
                post("window.__npFail&&window.__npFail('none')");
                return;
            }
            if (mime == null || !mime.startsWith("image/")) mime = guessMime(name);
            if (name == null || name.trim().length() == 0) name = "SayCap_" + id + ".jpg";
            deliverBytes("latest:" + id, name, mime, data);
        }).start();
    }

    /* =========================================================
       사진 고르기
       ========================================================= */
    private void openPicker() {
        try {
            Intent it;
            if (Build.VERSION.SDK_INT >= 33) {
                it = new Intent(MediaStore.ACTION_PICK_IMAGES);
                it.setType("image/*");
                it.putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, 10);
            } else {
                it = new Intent(Intent.ACTION_GET_CONTENT);
                it.setType("image/*");
                it.addCategory(Intent.CATEGORY_OPENABLE);
                it.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
            }
            startActivityForResult(it, REQ_PICK);
        } catch (Exception e) {
            try {
                Intent it2 = new Intent(Intent.ACTION_GET_CONTENT);
                it2.setType("image/*");
                it2.addCategory(Intent.CATEGORY_OPENABLE);
                startActivityForResult(it2, REQ_PICK);
            } catch (Exception e2) {
                post("window.__npFail&&window.__npFail('picker')");
            }
        }
    }

    private String displayName(Uri u) {
        Cursor c = null;
        try {
            c = getContentResolver().query(u, new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null);
            if (c != null && c.moveToFirst() && !c.isNull(0)) return c.getString(0);
        } catch (Exception ignored) {
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignored) { }
        }
        return null;
    }

    private String guessMime(String name) {
        if (name == null) return "image/jpeg";
        String n = name.toLowerCase();
        if (n.endsWith(".png")) return "image/png";
        if (n.endsWith(".webp")) return "image/webp";
        if (n.endsWith(".heic") || n.endsWith(".heif")) return "image/heic";
        if (n.endsWith(".gif")) return "image/gif";
        if (n.endsWith(".bmp")) return "image/bmp";
        return "image/jpeg";
    }

    private byte[] readAll(Uri u, int max) {
        InputStream in = null;
        try {
            in = getContentResolver().openInputStream(u);
            if (in == null) return null;
            ByteArrayOutputStream bo = new ByteArrayOutputStream();
            byte[] buf = new byte[64 * 1024];
            int n, total = 0;
            while ((n = in.read(buf)) > 0) {
                total += n;
                if (total > max) break;
                bo.write(buf, 0, n);
            }
            return bo.size() > 0 ? bo.toByteArray() : null;
        } catch (Exception e) {
            return null;
        } finally {
            try { if (in != null) in.close(); } catch (Exception ignored) { }
        }
    }

    /* =========================================================
       받아쓰기 — 네이티브 음성인식
       ========================================================= */
    private void startRecognition() {
        if (Build.VERSION.SDK_INT >= 23
                && checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, REQ_PERM);
            post("window.__saycapSTTError&&window.__saycapSTTError('perm')");
            return;
        }
        boolean avail;
        try { avail = SpeechRecognizer.isRecognitionAvailable(this); } catch (Exception e) { avail = false; }
        if (!avail) {
            post("window.__saycapSTTError&&window.__saycapSTTError('unavailable')");
            return;
        }
        if (recog == null) {
            try {
                recog = SpeechRecognizer.createSpeechRecognizer(this);
                recog.setRecognitionListener(listener);
            } catch (Exception e) {
                recog = null;
                post("window.__saycapSTTError&&window.__saycapSTTError('unavailable')");
                return;
            }
        }
        recogOn = true;
        noSpeechCount = 0;
        listenOnce();
    }

    private void listenOnce() {
        if (!recogOn || recog == null) return;
        Intent it = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        it.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        it.putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ko-KR");
        it.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true);
        it.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1);
        it.putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, getPackageName());
        try {
            recog.startListening(it);
        } catch (Exception e) {
            post("window.__saycapSTTError&&window.__saycapSTTError('start')");
        }
    }

    private void restartSoon(final long delay) {
        if (!recogOn) return;
        web.postDelayed(() -> { if (recogOn) listenOnce(); }, delay);
    }

    private void stopRecognition() {
        recogOn = false;
        noSpeechCount = 0;
        try { if (recog != null) recog.stopListening(); } catch (Exception ignored) { }
    }

    private String firstResult(Bundle b) {
        if (b == null) return "";
        ArrayList<String> list = b.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
        if (list == null || list.isEmpty()) return "";
        String t = list.get(0);
        return t == null ? "" : t.trim();
    }

    private final RecognitionListener listener = new RecognitionListener() {
        @Override public void onReadyForSpeech(Bundle params) { }
        @Override public void onBeginningOfSpeech() { noSpeechCount = 0; }
        /* v1.5 실제 목소리 크기 → 자막 아래 이퀄라이저 (약 14fps로 솎아서) */
        @Override public void onRmsChanged(float rmsdB) {
            long now = System.currentTimeMillis();
            if (now - lastRmsAt < 70) return;
            lastRmsAt = now;
            post("window.__saycapRms&&window.__saycapRms(" + String.format(java.util.Locale.US, "%.1f", rmsdB) + ")");
        }
        @Override public void onBufferReceived(byte[] buffer) { }
        @Override public void onEndOfSpeech() { }

        @Override
        public void onPartialResults(Bundle partialResults) {
            String t = firstResult(partialResults);
            if (t.length() > 0) post("window.__saycapSTT&&window.__saycapSTT(" + q(t) + ",false)");
        }

        @Override
        public void onResults(Bundle results) {
            String t = firstResult(results);
            if (t.length() > 0) {
                post("window.__saycapSTT&&window.__saycapSTT(" + q(t) + ",true)");
            }
            restartSoon(280);          // 한 문장 끝 → 이어서 계속 듣기
        }

        @Override
        public void onError(int error) {
            if (!recogOn) return;
            if (error == SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
                recogOn = false;
                post("window.__saycapSTTError&&window.__saycapSTTError('perm')");
                return;
            }
            if (error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT) {
                noSpeechCount++;
                if (noSpeechCount >= 4) {
                    recogOn = false;
                    post("window.__saycapSTTError&&window.__saycapSTTError('nospeech')");
                    return;
                }
                restartSoon(420);
                return;
            }
            if (error == SpeechRecognizer.ERROR_RECOGNIZER_BUSY
                    || error == SpeechRecognizer.ERROR_CLIENT
                    || error == SpeechRecognizer.ERROR_NETWORK
                    || error == SpeechRecognizer.ERROR_NETWORK_TIMEOUT) {
                restartSoon(900);
                return;
            }
            recogOn = false;
            post("window.__saycapSTTError&&window.__saycapSTTError('error')");
        }

        @Override
        public void onEvent(int eventType, Bundle params) { }
    };

    /* =========================================================
       공유(카메라 → 공유 → 세이캡)
       ========================================================= */
    private boolean handleShareIntent(Intent it) {
        if (it == null) return false;
        String act = it.getAction();
        if (!Intent.ACTION_SEND.equals(act) && !Intent.ACTION_SEND_MULTIPLE.equals(act)) return false;
        Uri u = null;
        try {
            if (Intent.ACTION_SEND.equals(act)) {
                Object o = it.getParcelableExtra(Intent.EXTRA_STREAM);
                if (o instanceof Uri) u = (Uri) o;
            } else {
                ArrayList<Uri> list = it.getParcelableArrayListExtra(Intent.EXTRA_STREAM);
                if (list != null && !list.isEmpty()) u = list.get(0);   // 여러 장이면 첫 장부터
            }
        } catch (Exception ignored) { return false; }
        if (u == null) return false;
        String mime = null;
        try { mime = getContentResolver().getType(u); } catch (Exception ignored) { }
        if (mime == null || !mime.startsWith("image/")) return false;
        byte[] data = readAll(u, SHARE_MAX);
        if (data == null || data.length == 0) {
            Toast.makeText(this, "공유받은 사진을 열지 못했습니다", Toast.LENGTH_LONG).show();
            return false;
        }
        sharedMime = mime;
        sharedBytes = data;
        return true;
    }

    /* 앱이 이미 켜져 있을 때 다른 앱에서 '공유'를 누른 경우 */
    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        if (isLocked()) return;
        if (handleShareIntent(intent)) {
            fallbackDone = false;
            web.loadUrl(REMOTE + "?share=1&native=1&t=" + System.currentTimeMillis());
        }
    }

    /* =========================================================
       권한
       ========================================================= */
    private void askPermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return;
        String[] need;
        if (Build.VERSION.SDK_INT >= 33) {
            need = new String[]{Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO,
                    Manifest.permission.READ_MEDIA_IMAGES};
        } else {
            need = new String[]{Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO,
                    Manifest.permission.READ_EXTERNAL_STORAGE};
        }
        boolean ask = false;
        for (String p : need) {
            if (checkSelfPermission(p) != PackageManager.PERMISSION_GRANTED) ask = true;
        }
        if (ask) requestPermissions(need, REQ_PERM);
    }

    @Override
    public void onRequestPermissionsResult(int code, String[] perms, int[] result) {
        super.onRequestPermissionsResult(code, perms, result);
        if (code == REQ_MEDIA) {           // v1.5 폰 사진 목록 권한
            mediaAskPending = false;
            post("window.__devPhotosReady&&window.__devPhotosReady(" + hasMediaPermission() + ")");
            return;
        }
        if (code != REQ_PERM) return;
        if (hasMediaPermission()) post("window.__devPhotosReady&&window.__devPhotosReady(true)");
        boolean media = false, mic = true, askedMic = false;
        for (int i = 0; i < result.length && i < perms.length; i++) {
            boolean ok = result[i] == PackageManager.PERMISSION_GRANTED;
            if (Manifest.permission.CAMERA.equals(perms[i]) && !ok) {
                Toast.makeText(this, "카메라 권한을 허용해야 촬영이 됩니다", Toast.LENGTH_LONG).show();
            }
            if (Manifest.permission.READ_MEDIA_IMAGES.equals(perms[i])
                    || Manifest.permission.READ_EXTERNAL_STORAGE.equals(perms[i])) media = ok;
            if (Manifest.permission.RECORD_AUDIO.equals(perms[i])) { askedMic = true; mic = ok; }
        }
        if (wantLatestPending) {
            wantLatestPending = false;
            if (media) loadLatestAsync();
            else post("window.__npFail&&window.__npFail('perm')");
        }
        if (askedMic && !mic) post("window.__saycapSTTError&&window.__saycapSTTError('perm')");
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        if (req == REQ_PICK) {
            if (res != RESULT_OK || data == null) {
                post("window.__npFail&&window.__npFail('cancel')");
                return;
            }
            final ArrayList<Uri> uris = new ArrayList<>();
            try {
                if (data.getClipData() != null) {
                    int n = data.getClipData().getItemCount();
                    for (int i = 0; i < n; i++) uris.add(data.getClipData().getItemAt(i).getUri());
                } else if (data.getData() != null) {
                    uris.add(data.getData());
                }
            } catch (Exception ignored) { }
            if (uris.isEmpty()) {
                post("window.__npFail&&window.__npFail('cancel')");
                return;
            }
            new Thread(() -> {
                int count = 0;
                for (int i = 0; i < uris.size() && i < 10; i++) {
                    Uri u = uris.get(i);
                    byte[] b = readAll(u, PHOTO_MAX);
                    if (b == null || b.length == 0) continue;
                    String mime = null;
                    try { mime = getContentResolver().getType(u); } catch (Exception ignored) { }
                    if (mime == null || !mime.startsWith("image/")) mime = guessMime(displayName(u));
                    String name = displayName(u);
                    if (name == null) name = "SayCap_" + System.currentTimeMillis() + ".jpg";
                    deliverBytes("pick:" + count, name, mime, b);
                    count++;
                }
                final int c = count;
                post("window.__npAllDone&&window.__npAllDone(" + c + ")");
            }).start();
            return;
        }
        if (req == REQ_FILE) {
            Uri[] out = null;
            if (res == RESULT_OK && data != null && data.getData() != null) out = new Uri[]{data.getData()};
            if (filePathCallback != null) filePathCallback.onReceiveValue(out);
            filePathCallback = null;
            return;
        }
        super.onActivityResult(req, res, data);
    }

    /* 뒤로가기 — 웹 히스토리 우선 */
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_BACK && web != null && web.canGoBack()) {
            web.goBack();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    protected void onDestroy() {
        recogOn = false;
        try { if (recog != null) { recog.cancel(); recog.destroy(); } } catch (Exception ignored) { }
        recog = null;
        super.onDestroy();
    }

    /* 기기 잠금 */
    private boolean isLocked() {
        SharedPreferences p = getSharedPreferences("kts_lock", MODE_PRIVATE);
        String saved = p.getString("dev", null);
        String now = deviceId();
        if (saved == null) { p.edit().putString("dev", now).apply(); return false; }
        return !saved.equals(now);
    }

    private String deviceId() {
        String raw = android.provider.Settings.Secure.getString(getContentResolver(),
                android.provider.Settings.Secure.ANDROID_ID);
        if (raw == null) raw = "unknown";
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] h = md.digest((raw + "|com.kts.saycap").getBytes("UTF-8"));
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < 8; i++) sb.append(String.format("%02x", h[i]));
            return sb.toString().toUpperCase();
        } catch (Exception e) { return Integer.toHexString(raw.hashCode()).toUpperCase(); }
    }
}
