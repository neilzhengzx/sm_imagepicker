
package com.reactlibrary.sm_imagepicker;

import android.app.Activity;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.UUID;

import me.nereo.multi_image_selector.MultiImageSelectorActivity;

public class RNSmImagepickerModule extends ReactContextBaseJavaModule implements ActivityEventListener{

  private final ReactApplicationContext reactContext;
  private static Activity mCurrentActivety;
  public static Uri photoUri;
  private static String cropImagePath = "";
  private static ArrayList<String> mOriginData;
  private static int mMultiImageNum = 9;
  private static boolean mCameraAndAlbumIsEdit = false;
  private static int mCameraAndAlbumCompressedPixel = 1280;
  private static int mCameraAndAlbumQuality = 60;
  private Callback mCallBack;

  private static final int CAMERA_PIC = 10;
  private static final int SELECT_PIC_KITKAT = 11;
  private static final int SELECT_PIC = 12;
  private static final int MULTIIMAGE = 13;
  private static final int CROPIMAGE = 14;

  public RNSmImagepickerModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    reactContext.addActivityEventListener(this);
  }

  @Override
  public String getName() {
    return "RNSmImagepicker";
  }
  
  
  @ReactMethod
  public void imageFromCamera(ReadableMap params, Callback callback){
    // imageFromCamera 实现, 返回参数用WritableMap封装, 调用callback.invoke(WritableMap)
    mCallBack = callback;

    mCurrentActivety = getCurrentActivity();
    if (mCurrentActivety == null) {
      callbackWithSuccess("","",0);
      return;
    }

    if (params.hasKey("isEdit")) {
      mCameraAndAlbumIsEdit = params.getBoolean("isEdit");
    }
    if (params.hasKey("compressedPixel")) {
      mCameraAndAlbumCompressedPixel = params.getInt("compressedPixel");
    }
    if (params.hasKey("quality")) {
      mCameraAndAlbumQuality = params.getInt("quality");
    }

    imageCapture();
  }


  @ReactMethod
  public void imageFromCameraAlbum(ReadableMap params, Callback callback){
    // imageFromCameraAlbum 实现, 返回参数用WritableMap封装, 调用callback.invoke(WritableMap)
    mCallBack = callback;

    mCurrentActivety = getCurrentActivity();
    if (mCurrentActivety == null) {
      callbackWithSuccess("","",0);
      return;
    }

    if (params.hasKey("isEdit")) {
      mCameraAndAlbumIsEdit = params.getBoolean("isEdit");
    }
    if (params.hasKey("compressedPixel")) {
      mCameraAndAlbumCompressedPixel = params.getInt("compressedPixel");
    }
    if (params.hasKey("quality")) {
      mCameraAndAlbumQuality = params.getInt("quality");
    }

    imageAlbum();
  }

  @ReactMethod
  public void multiImage(ReadableMap params, Callback callback){
    // multiImage 实现, 返回参数用WritableMap封装, 调用callback.invoke(WritableMap)
    mCallBack = callback;

    mCurrentActivety = getCurrentActivity();
    if (mCurrentActivety == null) {
      callbackWithSuccess("","",0);
      return;
    }

    if (params.hasKey("number")) {
      mMultiImageNum = params.getInt("number");
    }
    if (params.hasKey("compressedPixel")) {
      mCameraAndAlbumCompressedPixel = params.getInt("compressedPixel");
    }
    if (params.hasKey("quality")) {
      mCameraAndAlbumQuality = params.getInt("quality");
    }

    multiImageAlbum();
  }

  @ReactMethod
  public void cropImage(ReadableMap params, Callback callback){
    // cropImage 实现, 返回参数用WritableMap封装, 调用callback.invoke(WritableMap)
    mCallBack = callback;

    mCurrentActivety = getCurrentActivity();
    if (mCurrentActivety == null) {
      callbackWithSuccess("","",0);
      return;
    }

    if (params.hasKey("number")) {
      mMultiImageNum = params.getInt("number");
    }
    if (params.hasKey("compressedPixel")) {
      mCameraAndAlbumCompressedPixel = params.getInt("compressedPixel");
    }

    String imageUrl = "";
    if (params.hasKey("url") && params.getString("url").length() > 0) {
      imageUrl = params.getString("url");
    }else{
      callbackWithSuccess("","",0);
    }

    BufferedOutputStream bos = null;
    FileOutputStream fos = null;
    File file = null;

    try{
      URL url = new URL(imageUrl);
      HttpURLConnection conn = (HttpURLConnection)url.openConnection();
      conn.setConnectTimeout(30000);//设置超时
      conn.setDoInput(true); //设置请求可以放服务器写入数据
      conn.setReadTimeout(30000); //设置连接去读取数据的超时时间
      //4.真正请求图片,然后把从网络上请求到的二进制流保存到了inputStream里面
      conn.connect();
      InputStream inStream = conn.getInputStream();//通过输入流获取图片数据

      ByteArrayOutputStream outStream = new ByteArrayOutputStream();
      byte[] buffer = new byte[1024];
      int len = 0;
      while( (len=inStream.read(buffer)) != -1 ){
        outStream.write(buffer, 0, len);
      }
      inStream.close();
      byte[] btImg = outStream.toByteArray();

      File dir = new File(mCurrentActivety.getExternalCacheDir()+"/UploadImage/");
      if(!dir.exists())
      {
        dir.mkdir();
      }
      cropImagePath = mCurrentActivety.getExternalCacheDir()+"/UploadImage/crop"+System.currentTimeMillis() + ".jpg";
      file = new File(cropImagePath);

      fos = new FileOutputStream(file);
      bos = new BufferedOutputStream(fos);
      bos.write(btImg);

      cropImageFromFile(file, CROPIMAGE);
    } catch (Exception e){
      callbackWithSuccess("","",0);
    }finally {
      if (bos != null) {
        try {
          bos.close();
        } catch (IOException e1) {
          e1.printStackTrace();
        }
      }
      if (fos != null) {
        try {
          fos.close();
        } catch (IOException e1) {
          e1.printStackTrace();
        }
      }
    }
  }

  @ReactMethod
  public void cleanImage(ReadableMap params, Callback callback){
    // cleanImage 实现, 返回参数用WritableMap封装, 调用callback.invoke(WritableMap)

    File imageDir = new File(this.reactContext.getExternalCacheDir() + "/UploadImage/");
    deleteAllFilesOfDir(imageDir);
  }

  interface SaveThumbListerner{
    public void finishToSaveThumb(String thumbPath);
  }

  public void imageCapture()
  {
    SimpleDateFormat timeStampFormat = new SimpleDateFormat(
            "yyyy_MM_dd_HH_mm_ss");
    String filename = timeStampFormat.format(new Date(0));
    ContentValues values = new ContentValues();
    values.put(MediaStore.Images.Media.TITLE, filename);

    try{
      photoUri = mCurrentActivety.getContentResolver().insert(
              MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);

    } catch (Exception e){
      photoUri = mCurrentActivety.getContentResolver().insert(
              MediaStore.Images.Media.INTERNAL_CONTENT_URI, values);
    } finally {
      Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
      intent.putExtra(MediaStore.EXTRA_OUTPUT, photoUri);
      try{
        mCurrentActivety.startActivityForResult(intent,CAMERA_PIC);
      } catch (Exception e){
        callbackWithSuccess("","",0);
      }
    }
  }

  public  void imageAlbum()
  {
    Intent intent = new Intent(Intent.ACTION_GET_CONTENT);//ACTION_OPEN_DOCUMENT
    intent.setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*");
    try{
      if(android.os.Build.VERSION.SDK_INT>=android.os.Build.VERSION_CODES.KITKAT){
        mCurrentActivety.startActivityForResult(intent, SELECT_PIC_KITKAT);
      }else{
        mCurrentActivety.startActivityForResult(intent, SELECT_PIC);
      }
    } catch (Exception e){
      callbackWithSuccess("","",0);
    }
  }

  public void multiImageAlbum()
  {
    Intent intent = new Intent(mCurrentActivety, MultiImageSelectorActivity.class);
    intent.putExtra(MultiImageSelectorActivity.EXTRA_SHOW_CAMERA, true);
    intent.putExtra(MultiImageSelectorActivity.EXTRA_SELECT_COUNT, mMultiImageNum);
    intent.putExtra(MultiImageSelectorActivity.EXTRA_SELECT_MODE, MultiImageSelectorActivity.MODE_MULTI);
    try{
      mCurrentActivety.startActivityForResult(intent, MULTIIMAGE);
    } catch (Exception e){
      callbackWithSuccess("","",0);
    }
  }

  public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent intent) {
    if (resultCode == activity.RESULT_OK) {
      switch (requestCode) {
        case CAMERA_PIC:
        case SELECT_PIC:  // Photo
        case SELECT_PIC_KITKAT:
          Uri takePhoto = null;
          if (intent != null){
            takePhoto= intent.getData();
          }
          if(takePhoto == null && requestCode == CAMERA_PIC){
            takePhoto = photoUri;
          }
          final String path2 = getPath(activity, takePhoto);
          if(mCameraAndAlbumIsEdit == false)
          {
            getImageThumbnail(activity, path2, new SaveThumbListerner(){

              @Override
              public void finishToSaveThumb(String thumbPath) {
                if(thumbPath.equalsIgnoreCase("")) thumbPath = path2;
                callbackWithSuccess(thumbPath, path2, 1);
//                Cocos2dxActivity.dismiss();
              }
            });
//            Cocos2dxActivity.showProgressDialog("正在处理");
          }
          else
          {
            cropImageUri(path2, CROPIMAGE);
          }
          break;
        case MULTIIMAGE:
          String ImagesPath = "";
          int number = 0;
          ArrayList<String> list = new ArrayList<>();
          if (intent != null){
            mOriginData = intent.getStringArrayListExtra(MultiImageSelectorActivity.EXTRA_RESULT);
            if(mOriginData.size() != 0)
            {
              Iterator<String> it1 = mOriginData.iterator();
              while(it1.hasNext())
              {
                String image = it1.next();
                ImagesPath += image  + ",*";
                list.add(image);
                number++;
              }
            }
          }

          final String ImagesPaths = ImagesPath;
          final int numbers  = number;
          getImagesThumbnail(mCurrentActivety, list, new SaveThumbListerner(){

            @Override
            public void finishToSaveThumb(String thumbPath) {
              if(thumbPath.equalsIgnoreCase("")) thumbPath = ImagesPaths;
              callbackWithSuccess(thumbPath, ImagesPaths, numbers);
//              Cocos2dxActivity.dismiss();
            }
          });
          mOriginData.clear();
//          Cocos2dxActivity.showProgressDialog("正在处理");
          break;
        case CROPIMAGE:
          getImageThumbnail(activity, cropImagePath, new SaveThumbListerner(){

            @Override
            public void finishToSaveThumb(String CropPath) {
              if(CropPath.equalsIgnoreCase("")) CropPath = cropImagePath;
              callbackWithSuccess(CropPath, cropImagePath, 1);
//              Cocos2dxActivity.dismiss();
            }
          });
//          Cocos2dxActivity.showProgressDialog("正在处理");
          break;
        default:
          break;
      }
    } else {
      switch (requestCode) {
        case CAMERA_PIC:
        case SELECT_PIC:
        case SELECT_PIC_KITKAT:
        case CROPIMAGE:
        case MULTIIMAGE:
          callbackWithSuccess("","",0);
          break;
        default:
          break;
      }
    }
  }

  public void onNewIntent(Intent intent) {
  }

  private void callbackWithSuccess(String path, String initialPaths, int number){
    if(mCallBack == null) return;
    WritableMap response = Arguments.createMap();
    response.putString("paths", path);
    response.putString("initialPaths", initialPaths);
    response.putInt("number", number);
    mCallBack.invoke(response);
    mCallBack = null;
  }

  public static Boolean creatThumbImage(final Context context, final String imagepath, String name)
  {
    try {
      Bitmap bitmap = ImageUtils.safeDecodeStream(imagepath, mCameraAndAlbumCompressedPixel, mCameraAndAlbumCompressedPixel);
      if (bitmap == null) {
        return false;
      }
      File thumbDir = new File(context.getExternalCacheDir() + "/UploadImage/");
      if (!thumbDir.exists())
      {
        thumbDir.mkdir();
      }
      String path = context.getExternalCacheDir() + "/UploadImage/" + name;
      FileUtil.saveBitmapToSD(bitmap, path, mCameraAndAlbumQuality);
      if (new File(path).exists())
      {
        return true;
      }
    } catch (Exception e) {
//      VTBuglyLog.e(TAG, "safeDecodeStream ... " + e.getMessage());
    }
    return false;
  }

  public static void getImageThumbnail(final Context context, final String imagepath, final SaveThumbListerner listerner) {

    if( imagepath.length() == 0){
      if(listerner != null){
        listerner.finishToSaveThumb("");
      }
      return;
    }

    Thread thread =  new Thread(new Runnable() {
      @Override
      public void run() {
        String name = getUUID()+".jpg";
        String path = context.getExternalCacheDir()+"/UploadImage/"+name;
        if(listerner != null)
        {
          if(creatThumbImage(context, imagepath, name))
          {
            listerner.finishToSaveThumb(path);
          }
          else
          {
            listerner.finishToSaveThumb("");
          }
        }
      }
    });
    thread.start();
  }

  public static void getImagesThumbnail(final Context context, final ArrayList<String> imagepaths, final SaveThumbListerner listerner) {

    if(imagepaths.size() == 0)
    {
      if(listerner != null)
      {
        listerner.finishToSaveThumb("");
      }
      return;
    }
    Thread thumbget =  new Thread(new Runnable() {
      @Override
      public void run() {
        int index = 0;
        String thumbPaths = "";
        for (String imagepath : imagepaths)
        {
          String name = getUUID()+".jpg";
          String path = context.getExternalCacheDir()+"/UploadImage/"+name;
          if(creatThumbImage(context, imagepath, name))
          {
            thumbPaths = thumbPaths + path + ",*";
          }
          else
          {
            thumbPaths = thumbPaths + imagepath + ",*";
          }
          index++;
        }
        if(listerner != null)
        {
          listerner.finishToSaveThumb(thumbPaths);
        }
      }
    });
    thumbget.start();
  }

  private static void cropImageUri(String path, int requestCode)
  {
    File initialImage = new File(path);
    cropImageFromFile(initialImage, requestCode);
  }

  private static void cropImageFromFile(File initialImage, int requestCode)
  {
    File thumbDir = new File(mCurrentActivety.getExternalCacheDir()+"/UploadImage/");
    if(!thumbDir.exists())
    {
      thumbDir.mkdir();
    }
    cropImagePath = mCurrentActivety.getExternalCacheDir()+"/UploadImage/"+getUUID() + ".jpg";
    File tempFile = new File(cropImagePath);

    Intent intent = new Intent("com.android.camera.action.CROP");
    intent.setDataAndType(Uri.fromFile(initialImage), "image/*");
    intent.putExtra("crop", "true");
//    intent.putExtra("aspectX", 1);   //不设置时可动态改变长宽比
//    intent.putExtra("aspectY", 1);
//    intent.putExtra("outputX", 400);  //不设置时不固定像素大小
//    intent.putExtra("outputY", 400);
    intent.putExtra("scale", true);
    intent.putExtra(MediaStore.EXTRA_OUTPUT, Uri.fromFile(tempFile));
    intent.putExtra("outputFormat", Bitmap.CompressFormat.JPEG.toString());
    intent.putExtra("return-data", false);
    intent.putExtra("noFaceDetection", true);
    mCurrentActivety.startActivityForResult(intent, requestCode);
  }

  public static String getPath(final Context context, final Uri uri) {

    if(uri == null){
      return "";
    }

    final boolean isKitKat = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT;

    // DocumentProvider
    if (isKitKat && DocumentsContract.isDocumentUri(context, uri)) {
      // ExternalStorageProvider
      if (isExternalStorageDocument(uri)) {
        final String docId = DocumentsContract.getDocumentId(uri);
        final String[] split = docId.split(":");
        final String type = split[0];

        if ("primary".equalsIgnoreCase(type)) {
          return Environment.getExternalStorageDirectory() + "/" + split[1];
        }

        // TODO handle non-primary volumes
      }
      // DownloadsProvider
      else if (isDownloadsDocument(uri)) {

        final String id = DocumentsContract.getDocumentId(uri);
        final Uri contentUri = ContentUris.withAppendedId(
                Uri.parse("content://downloads/public_downloads"), Long.valueOf(id));

        return getDataColumn(context, contentUri, null, null);
      }
      // MediaProvider
      else if (isMediaDocument(uri)) {
        final String docId = DocumentsContract.getDocumentId(uri);
        final String[] split = docId.split(":");
        final String type = split[0];

        Uri contentUri = null;
        if ("image".equals(type)) {
          contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
        } else if ("video".equals(type)) {
          contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
        } else if ("audio".equals(type)) {
          contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
        }

        final String selection = "_id=?";
        final String[] selectionArgs = new String[] {
                split[1]
        };

        return getDataColumn(context, contentUri, selection, selectionArgs);
      }
    }
    // MediaStore (and general)
    else if ("content".equalsIgnoreCase(uri.getScheme())) {

      // Return the remote address
      if (isGooglePhotosUri(uri))
        return uri.getLastPathSegment();

      return getDataColumn(context, uri, null, null);
    }
    // File
    else if ("file".equalsIgnoreCase(uri.getScheme())) {
      return uri.getPath();
    }

    return "";
  }

  /**
   * Get the value of the data column for this Uri. This is useful for
   * MediaStore Uris, and other file-based ContentProviders.
   *
   * @param context The context.
   * @param uri The Uri to query.
   * @param selection (Optional) Filter used in the query.
   * @param selectionArgs (Optional) Selection arguments used in the query.
   * @return The value of the _data column, which is typically a file path.
   */
  public static String getDataColumn(Context context, Uri uri, String selection,
                                     String[] selectionArgs) {

    Cursor cursor = null;
    final String column = "_data";
    final String[] projection = {
            column
    };

    try {
      cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs,
              null);
      if (cursor != null && cursor.moveToFirst()) {
        final int index = cursor.getColumnIndexOrThrow(column);
        return cursor.getString(index);
      }
    } finally {
      if (cursor != null)
        cursor.close();
    }
    return null;
  }

  /**
   * @param uri The Uri to check.
   * @return Whether the Uri authority is ExternalStorageProvider.
   */
  public static boolean isExternalStorageDocument(Uri uri) {
    return "com.android.externalstorage.documents".equals(uri.getAuthority());
  }

  /**
   * @param uri The Uri to check.
   * @return Whether the Uri authority is DownloadsProvider.
   */
  public static boolean isDownloadsDocument(Uri uri) {
    return "com.android.providers.downloads.documents".equals(uri.getAuthority());
  }

  /**
   * @param uri The Uri to check.
   * @return Whether the Uri authority is MediaProvider.
   */
  public static boolean isMediaDocument(Uri uri) {
    return "com.android.providers.media.documents".equals(uri.getAuthority());
  }

  /**
   * @param uri The Uri to check.
   * @return Whether the Uri authority is Google Photos.
   */
  public static boolean isGooglePhotosUri(Uri uri) {
    return "com.google.android.apps.photos.content".equals(uri.getAuthority());
  }

  public static String getUUID() {
        /*UUID uuid = UUID.randomUUID();
        String str = uuid.toString();
        // 去掉"-"符号
        String temp = str.substring(0, 8) + str.substring(9, 13)
                + str.substring(14, 18) + str.substring(19, 23)
                + str.substring(24);
        return temp;*/

    return UUID.randomUUID().toString().replace("-", "");
  }

  public static void deleteAllFilesOfDir(File path) {
    if (!path.exists())
      return;
    if (path.isFile()) {
      path.delete();
      return;
    }
    File[] files = path.listFiles();
    for (int i = 0; i < files.length; i++) {
      deleteAllFilesOfDir(files[i]);
    }
    path.delete();
  }
}
