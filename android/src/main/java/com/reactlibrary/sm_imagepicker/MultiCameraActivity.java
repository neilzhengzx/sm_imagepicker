package com.reactlibrary.sm_imagepicker;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.MediaStore;
import android.text.format.DateFormat;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

import com.reactlibrary.sm_imagepicker.camare.CameraPreview;
import com.reactlibrary.sm_imagepicker.camare.FocusView;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;

/**
 * Created by zzx on 2018/6/25.
 */

public class MultiCameraActivity extends Activity implements CameraPreview.OnCameraStatusListener{
    private static final String TAG = "ReactNativeJS";
    public static final Uri IMAGE_URI = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
    public static final String PATH = Environment.getExternalStorageDirectory()
            .toString() + "/AndroidMedia/";
    CameraPreview mCameraPreview;

    private static int mCameraNumberLimit = 3;
    private static int mImageCount = 0;

    ArrayList<String> mImagePaths;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // 设置全屏
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);

        if (Build.VERSION.SDK_INT > 11 && Build.VERSION.SDK_INT < 19) { // lower api
            View v = this.getWindow().getDecorView();
            v.setSystemUiVisibility(View.GONE);
        } else if (Build.VERSION.SDK_INT >= 19) {
            //for new api versions.
            View decorView = getWindow().getDecorView();
            int uiOptions = View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_FULLSCREEN;
            decorView.setSystemUiVisibility(uiOptions);
        }

        setContentView(R.layout.activity_take_photo);
        // Initialize components of the app
        mCameraPreview = (CameraPreview) findViewById(R.id.cameraPreview);
        FocusView focusView = (FocusView) findViewById(R.id.view_focus);

        mCameraPreview.setFocusView(focusView);
        mCameraPreview.setOnCameraStatusListener(this);

        mImagePaths = new ArrayList<>();
        mImageCount = 0;
        mCameraNumberLimit = getIntent().getIntExtra("numberLimit", 3);
    }

    @TargetApi(Build.VERSION_CODES.HONEYCOMB)
    @Override
    protected void onResume() {
        super.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        Log.e(TAG, "onConfigurationChanged");
        super.onConfigurationChanged(newConfig);
    }

    public void takePhoto(View view) {
        if(mCameraPreview != null) {
            mCameraPreview.takePicture();
        }
    }

    public void change(View view)
    {
        if(mCameraPreview != null) {
            mCameraPreview.change(view);
        }
    }

    public void openlight(View view)
    {
        if (mCameraPreview != null)
        {
            mCameraPreview.openLight();
            view.setVisibility(View.GONE);
            View v = findViewById(R.id.nolight);
            v.setVisibility(View.VISIBLE);
        }
    }
    public void offlight(View v)
    {
        if (mCameraPreview != null)
        {
            mCameraPreview.offLight();
            v.setVisibility(View.GONE);
            View view = findViewById(R.id.light);
            view.setVisibility(View.VISIBLE);
        }
    }

    public void cancelClose(View view) {
        Intent i = new Intent();
        setResult(RESULT_CANCELED, i);
        finish();
    }

    public void successClose(View view) {
        Intent i = new Intent();
        i.putStringArrayListExtra("imagepaths", mImagePaths);
        setResult(RESULT_OK, i);
        finish();
    }

    /**
     * 拍照成功后回调
     * 存储图片并显示截图界面
     * @param data
     */
    @Override
    public void onCameraStopped(byte[] data) {
        Log.i("TAG", "==onCameraStopped==");
        // 创建图像
        Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);

        Matrix matrix = new Matrix();
        matrix.postRotate((float)90.0);
        bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);

        // 系统时间
        long dateTaken = System.currentTimeMillis();
        // 图像名称
        String filename = DateFormat.format("yyyy-MM-dd kk.mm.ss", dateTaken)
                .toString() + ".jpg";
        String filePath = PATH + filename;
        Log.d(TAG, "imageth:" + filePath);
        // 存储图像（PATH目录）
        insertImage(getContentResolver(), filename, dateTaken, PATH,
                filename, bitmap, data);

        mImageCount++;
        mImagePaths.add(filePath);

        if(mImageCount == mCameraNumberLimit){
            successClose(null);
        }else{
            //继续启动摄像头
            mCameraPreview.start();
        }
    }

    /**
     * 存储图像并将信息添加入媒体数据库
     */
    private Uri insertImage(ContentResolver cr, String name, long dateTaken,
                            String directory, String filename, Bitmap source, byte[] jpegData) {
        OutputStream outputStream = null;
        String filePath = directory + filename;
        try {
            File dir = new File(directory);
            if (!dir.exists()) {
                dir.mkdirs();
            }
            File file = new File(directory, filename);
            if (file.createNewFile()) {
                outputStream = new FileOutputStream(file);
                if (source != null) {
                    source.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                } else {
                    outputStream.write(jpegData);
                }
            }
        } catch (FileNotFoundException e) {
            Log.e(TAG, e.getMessage());
            return null;
        } catch (IOException e) {
            Log.e(TAG, e.getMessage());
            return null;
        } finally {
            if (outputStream != null) {
                try {
                    outputStream.close();
                } catch (Throwable t) {
                }
            }
        }
        ContentValues values = new ContentValues(7);
        values.put(MediaStore.Images.Media.TITLE, name);
        values.put(MediaStore.Images.Media.DISPLAY_NAME, filename);
        values.put(MediaStore.Images.Media.DATE_TAKEN, dateTaken);
        values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
        values.put(MediaStore.Images.Media.DATA, filePath);
        return cr.insert(IMAGE_URI, values);
    }
}