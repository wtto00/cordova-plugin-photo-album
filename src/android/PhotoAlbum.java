package wang.tato.photoAlbum;

import android.annotation.SuppressLint;
import android.content.ContentResolver;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;
import android.util.Size;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URLConnection;

public class PhotoAlbum extends CordovaPlugin {

    public static final String TAG = "Cordova.Plugin.PhotoAlbum";

    @Override
    protected void pluginInitialize() {
        super.pluginInitialize();

        Log.d(TAG, "plugin initialized.");
    }

    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        Log.d(TAG, String.format("%s is called. Callback ID: %s.", action, callbackContext.getCallbackId()));

        if (action.equals("getAlbums")) {
            return getAlbums(args, callbackContext);
        } else if (action.equals("getPhotoThumbnail")) {
            return getPhotoThumbnail(args, callbackContext);
        } else if (action.equals("getPhotoData")) {
            return getPhotoData(args, callbackContext);
        }

        return false;
    }

    private JSONObject buildBucketItem(long id, String name) throws JSONException {
        JSONObject bucket = new JSONObject();
        bucket.put("id", id);
        bucket.put("name", name);
        bucket.put("images", new JSONArray());
        return bucket;
    }

    private JSONObject buildImageItem(long id, String path) throws JSONException {
        JSONObject imageItem = new JSONObject();
        imageItem.put("id", id);
        imageItem.put("path", path);
        return imageItem;
    }

    private void bucketPushImage(JSONObject bucket, JSONObject image) throws JSONException {
        JSONArray images = bucket.getJSONArray("images");
        images.put(image);
    }

    private boolean getAlbums(CordovaArgs args, final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    ContentResolver cr = cordova.getContext().getContentResolver();
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        @SuppressLint("Recycle") Cursor cursor = cr.query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, new String[]{
                                MediaStore.Images.ImageColumns._ID,
                                MediaStore.Images.ImageColumns.DATA,
                                MediaStore.Images.ImageColumns.BUCKET_ID,
                                MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME
                        }, null, null, MediaStore.Images.ImageColumns.DATE_MODIFIED + " DESC");
                        if (cursor == null) {
                            callbackContext.error("出错了");
                            return;
                        }
                        JSONArray albums = new JSONArray();
                        if (cursor.moveToFirst()) {
                            JSONObject recent = buildBucketItem(-1, "最近的照片");
                            albums.put(recent);
                            JSONObject bucketMap = new JSONObject();
                            do {
                                long id = cursor.getLong(0);
                                String path = cursor.getString(1);
                                long bucketId = cursor.getLong(2);
                                String bucketName = cursor.getString(3);
                                JSONObject image = buildImageItem(id, path);

                                bucketPushImage(recent, image);

                                String albumId = String.valueOf(bucketId);
                                if (bucketMap.has(albumId)) {
                                    int index = bucketMap.getInt(albumId);
                                    JSONObject bucket = albums.getJSONObject(index);
                                    bucketPushImage(bucket, image);
                                    albums.put(index, bucket);
                                } else {
                                    JSONObject bucket = buildBucketItem(bucketId, bucketName);
                                    bucketPushImage(bucket, image);
                                    bucketMap.put(albumId, albums.length());
                                    albums.put(bucket);
                                }
                            } while (cursor.moveToNext());
                        }
                        cursor.close();
                        callbackContext.success(albums);
                    }
                } catch (JSONException e) {
                    callbackContext.error(e.getMessage());
                }
            }
        });
        return true;
    }

    private boolean getPhotoThumbnail(CordovaArgs args, final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    long imgId = args.getLong(0);
                    Bitmap bitmap = null;
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        Uri uri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, Long.toString(imgId));
                        bitmap = cordova.getContext().getContentResolver().loadThumbnail(uri, new Size(256, 256), null);
                    } else {
                        bitmap = MediaStore.Images.Thumbnails.getThumbnail(cordova.getContext().getContentResolver(), imgId, MediaStore.Images.Thumbnails.MINI_KIND, null);
                    }
                    if (bitmap == null) {
                        callbackContext.error("出错了");
                        return;
                    }
                    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 70, byteArrayOutputStream);
                    byte[] byteArray = byteArrayOutputStream.toByteArray();
                    String encoded = Base64.encodeToString(byteArray, Base64.DEFAULT);
                    callbackContext.success(String.format("data:image/jpeg;base64,%s", encoded));
                } catch (JSONException | IOException e) {
                    callbackContext.error(e.getMessage());
                }
            }
        });
        return true;
    }

    private boolean getPhotoData(CordovaArgs args, final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    String imgPath = args.getString(0);
                    File file = new File(imgPath);
                    Uri fileUri = Uri.fromFile(file);
                    InputStream inputStream = cordova.getContext().getContentResolver().openInputStream(fileUri);
                    if (inputStream != null) {
                        ByteArrayOutputStream byteBuffer = new ByteArrayOutputStream();
                        int bufferSize = (int) file.length();
                        byte[] buffer = new byte[bufferSize];
                        int len;
                        while ((len = inputStream.read(buffer)) != -1) {
                            byteBuffer.write(buffer, 0, len);
                        }
                        byte[] imageData = byteBuffer.toByteArray();
                        String encoded = Base64.encodeToString(imageData, Base64.DEFAULT);
                        String mimeType = URLConnection.guessContentTypeFromName(file.getName());
                        callbackContext.success(String.format("data:%s;base64,%s", mimeType, encoded));
                        inputStream.close();
                    } else {
                        callbackContext.error("get image error");
                    }
                } catch (JSONException | IOException e) {
                    callbackContext.error(e.getMessage());
                }
            }
        });
        return true;
    }
}
