package com.reactlibrary.sm_imagepicker.camare;

import android.annotation.TargetApi;
import android.content.Context;
import android.graphics.PixelFormat;
import android.graphics.Rect;
import android.hardware.Camera;
import android.hardware.Camera.AutoFocusCallback;
import android.hardware.Camera.PictureCallback;
import android.hardware.Camera.ShutterCallback;
import android.hardware.Camera.Size;
import android.os.Build;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.RelativeLayout;
import android.widget.Toast;

import com.reactlibrary.sm_imagepicker.MultiCameraUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.List;

/**
 * Created by zzx on 2018/6/25.
 */

public class CameraPreview extends SurfaceView implements
        SurfaceHolder.Callback, AutoFocusCallback {
    private static final String TAG = "ReactNativeJS";

    private int viewWidth = 0;
    private int viewHeight = 0;
    private final CameraSizeComparator sizeComparator = new CameraSizeComparator();

    /** 监听接口 */
    private OnCameraStatusListener listener;

    private SurfaceHolder holder;
    private Camera camera;
    private FocusView mFocusView;
    private int cameraPosition = 1;//0代表前置摄像头，1代表后置摄像头

    //创建一个PictureCallback对象，并实现其中的onPictureTaken方法
    private PictureCallback pictureCallback = new PictureCallback() {

        // 该方法用于处理拍摄后的照片数据
        @Override
        public void onPictureTaken(byte[] data, Camera camera) {
            // 停止照片拍摄
            try {
                camera.stopPreview();
            } catch (Exception e) {
            }
            // 调用结束事件
            if (null != listener) {
                listener.onCameraStopped(data);
            }
        }
    };

    private ShutterCallback shutterCallback = new ShutterCallback() {
        @Override
        public void onShutter() {
            // 按下快门之后进行的操作
        }
    };

    // Preview类的构造方法
    public CameraPreview(Context context, AttributeSet attrs) {
        super(context, attrs);
        // 获得SurfaceHolder对象
        holder = getHolder();
        // 指定用于捕捉拍照事件的SurfaceHolder.Callback对象
        holder.addCallback(this);
        // 设置SurfaceHolder对象的类型
        holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
        setOnTouchListener(onTouchListener);
    }

    // 在surface创建时激发
    public void surfaceCreated(SurfaceHolder holder) {
        Log.e(TAG, "==surfaceCreated==");
        if(!MultiCameraUtils.checkCameraHardware(getContext())) {
            Toast.makeText(getContext(), "摄像头打开失败！", Toast.LENGTH_SHORT).show();
            return;
        }
        // 获得Camera对象
        camera = getCameraInstance();
        try {
            // 设置用于显示拍照摄像的SurfaceHolder对象
            camera.setPreviewDisplay(holder);
        } catch (IOException e) {
            e.printStackTrace();
            // 释放手机摄像头
            camera.release();
            camera = null;
        }
        updateCameraParameters();
        if (camera != null) {
            camera.startPreview();
        }
        setFocus();
    }
    //打开闪光灯
    public void openLight(){
        if (camera != null) {
            Camera.Parameters parameter;
            parameter = camera.getParameters();
            parameter.setFlashMode(Camera.Parameters.FLASH_MODE_TORCH);
            camera.setParameters(parameter);
        }
    }
    //关闭闪光灯
    public void offLight(){
        if (camera != null) {
            Camera.Parameters parameter;
            parameter = camera.getParameters();
            parameter.setFlashMode(Camera.Parameters.FLASH_MODE_OFF);
            camera.setParameters(parameter);
        }
    }
    // 在surface销毁时激发
    public void surfaceDestroyed(SurfaceHolder holder) {
        Log.e(TAG, "==surfaceDestroyed==");
        // 释放手机摄像头
        camera.release();
        camera = null;
    }

    // 在surface的大小发生改变时激发
    public void surfaceChanged(final SurfaceHolder holder, int format, int w,
                               int h) {
        // stop preview before making changes
        try {
            camera.stopPreview();
        } catch (Exception e){
            // ignore: tried to stop a non-existent preview
        }
        // set preview size and make any resize, rotate or
        // reformatting changes here
        updateCameraParameters();
        // start preview with new settings
        try {
            camera.setPreviewDisplay(holder);
            camera.startPreview();

        } catch (Exception e){
            Log.d(TAG, "Error starting camera preview: " + e.getMessage());
        }
        setFocus();
    }

    /**
     * 点击显示焦点区域
     */
    OnTouchListener onTouchListener = new OnTouchListener() {
        @TargetApi(Build.VERSION_CODES.HONEYCOMB)
        @SuppressWarnings("deprecation")
        @Override
        public boolean onTouch(View v, MotionEvent event) {
            if (event.getAction() == MotionEvent.ACTION_DOWN) {
                int width = mFocusView.getWidth();
                int height = mFocusView.getHeight();
                mFocusView.setX(event.getX(0) - (width / 2));
                mFocusView.setY(event.getY(0) - (height / 2));
                mFocusView.beginFocus();
            } else if (event.getAction() == MotionEvent.ACTION_UP) {
                focusOnTouch(event);
            }
            return true;
        }
    };

    /**
     * 获取摄像头实例
     * @return
     */
    private Camera getCameraInstance() {
        Camera c = null;
        try {
            int cameraCount = 0;
            Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
            cameraCount = Camera.getNumberOfCameras(); // get cameras number

            for (int camIdx = 0; camIdx < cameraCount; camIdx++) {
                Camera.getCameraInfo(camIdx, cameraInfo); // get camerainfo
                // 代表摄像头的方位，目前有定义值两个分别为CAMERA_FACING_FRONT前置和CAMERA_FACING_BACK后置
                if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_BACK) {
                    try {
                        c = Camera.open(camIdx);   //打开后置摄像头
                        cameraPosition = 1;
                    } catch (RuntimeException e) {
                        Toast.makeText(getContext(), "摄像头打开失败！", Toast.LENGTH_SHORT).show();
                    }
                }
            }
            if (c == null) {
                c = Camera.open(0); // attempt to get a Camera instance
            }
        } catch (Exception e) {
            Toast.makeText(getContext(), "摄像头打开失败！", Toast.LENGTH_SHORT).show();
        }
        return c;
    }

    public void change(View v) {
        //切换前后摄像头
        int cameraCount = 0;
        Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
        cameraCount = Camera.getNumberOfCameras();//得到摄像头的个数

        for (int i = 0; i < cameraCount; i++) {
            Camera.getCameraInfo(i, cameraInfo);//得到每一个摄像头的信息
            if (cameraPosition == 1) {
                //现在是后置，变更为前置
                if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {//代表摄像头的方位，CAMERA_FACING_FRONT前置      CAMERA_FACING_BACK后置
                    camera.stopPreview();//停掉原来摄像头的预览
                    camera.release();//释放资源
                    camera = null;//取消原来摄像头
                    camera = Camera.open(i);//打开当前选中的摄像头
                    try {
                        camera.setPreviewDisplay(holder);//通过surfaceview显示取景画面
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    updateCameraParameters();
                    camera.startPreview();
                    setFocus(); //开始预览
                    cameraPosition = 0;
                    break;
                }
            } else {
                //现在是前置， 变更为后置
                if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_BACK) {//代表摄像头的方位，CAMERA_FACING_FRONT前置      CAMERA_FACING_BACK后置
                    camera.stopPreview();//停掉原来摄像头的预览
                    camera.release();//释放资源
                    camera = null;//取消原来摄像头
                    camera = Camera.open(i);//打开当前选中的摄像头
                    try {
                        camera.setPreviewDisplay(holder);//通过surfaceview显示取景画面
                    } catch (IOException e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                    }
                    updateCameraParameters();
                    camera.startPreview();
                    setFocus(); //开始预览
                    cameraPosition = 1;
                    break;
                }
            }
        }
    }

    private void updateCameraParameters() {
        if (camera != null) {
            Camera.Parameters p = camera.getParameters();
            setParameters(p);
        }
    }

    /**
     * @param p
     */
    private void setParameters(Camera.Parameters p) {
        List<String> focusModes = p.getSupportedFocusModes();
        if (focusModes
                .contains(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE)) {
            p.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE);
        }

        long time = new Date().getTime();
        p.setGpsTimestamp(time);
        // 设置照片格式
        p.setPictureFormat(PixelFormat.JPEG);

        //图片大小
        Size pictureSize = getPictureSize(p.getSupportedPictureSizes(), 800);
//        //预览大小
        Size previewSize = getPreviewSize(p.getSupportedPreviewSizes(), viewHeight);
        if(previewSize!=null) {
            p.setPreviewSize(previewSize.width, previewSize.height);
        }
        if(pictureSize!=null) {
            p.setPictureSize(pictureSize.width, pictureSize.height);
        }

        camera.setDisplayOrientation(90);
        p.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);

        try {
            camera.setParameters(p);
        } catch (Exception e) {
            Size previewSize2 = findBestPreviewSize(p);
            p.setPreviewSize(previewSize2.width, previewSize2.height);
            p.setPictureSize(previewSize2.width, previewSize2.height);
            camera.setParameters(p);
        }
    }

    // 进行拍照，并将拍摄的照片传入PictureCallback接口的onPictureTaken方法
    public void takePicture() {
        if (camera != null) {
            try {
                camera.takePicture(shutterCallback, null, pictureCallback);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

        // 设置监听事件
    public void setOnCameraStatusListener(OnCameraStatusListener listener) {
        this.listener = listener;
    }

    @Override
    public void onAutoFocus(boolean success, Camera camera) {

    }

    public void start() {
        if (camera != null) {
            camera.startPreview();
        }
    }

    public void stop() {
        if (camera != null) {
            camera.stopPreview();
        }
    }

    /**
     * 相机拍照监听接口
     */
    public interface OnCameraStatusListener {
        // 相机拍照结束事件
        void onCameraStopped(byte[] data);
    }

    @Override
    protected void onMeasure(int widthSpec, int heightSpec) {
        viewWidth = MeasureSpec.getSize(widthSpec);
        viewHeight = MeasureSpec.getSize(heightSpec);
        super.onMeasure(
                MeasureSpec.makeMeasureSpec(viewWidth, MeasureSpec.EXACTLY),
                MeasureSpec.makeMeasureSpec(viewHeight, MeasureSpec.EXACTLY));
    }

    /**
     * 将预览大小设置为屏幕大小
     * @param parameters
     * @return
     */
    private Camera.Size findPreviewSizeByScreen(Camera.Parameters parameters) {
        if (viewWidth != 0 && viewHeight != 0) {
            return camera.new Size(Math.max(viewWidth, viewHeight),
                    Math.min(viewWidth, viewHeight));
        } else {
            return camera.new Size(MultiCameraUtils.getScreenWH(getContext()).heightPixels,
                    MultiCameraUtils.getScreenWH(getContext()).widthPixels);
        }
    }

    /**
     * 找到最合适的显示分辨率 （防止预览图像变形）
     * @param parameters
     * @return
     */
    private Camera.Size findBestPreviewSize(Camera.Parameters parameters) {

        // 系统支持的所有预览分辨率
        String previewSizeValueString = null;
        previewSizeValueString = parameters.get("preview-size-values");

        if (previewSizeValueString == null) {
            previewSizeValueString = parameters.get("preview-size-value");
        }

        if (previewSizeValueString == null) { // 有些手机例如m9获取不到支持的预览大小 就直接返回屏幕大小
            return camera.new Size(MultiCameraUtils.getScreenWH(getContext()).widthPixels,
                    MultiCameraUtils.getScreenWH(getContext()).heightPixels);
        }
        float bestX = 0;
        float bestY = 0;

        float tmpRadio = 0;
        float viewRadio = 0;

        if (viewWidth != 0 && viewHeight != 0) {
            viewRadio = Math.min((float) viewWidth, (float) viewHeight)
                    / Math.max((float) viewWidth, (float) viewHeight);
        }

        String[] COMMA_PATTERN = previewSizeValueString.split(",");
        for (String prewsizeString : COMMA_PATTERN) {
            prewsizeString = prewsizeString.trim();

            int dimPosition = prewsizeString.indexOf('x');
            if (dimPosition == -1) {
                continue;
            }

            float newX = 0;
            float newY = 0;

            try {
                newX = Float.parseFloat(prewsizeString.substring(0, dimPosition));
                newY = Float.parseFloat(prewsizeString.substring(dimPosition + 1));
            } catch (NumberFormatException e) {
                continue;
            }

            float radio = Math.min(newX, newY) / Math.max(newX, newY);
            if (tmpRadio == 0) {
                tmpRadio = radio;
                bestX = newX;
                bestY = newY;
            } else if (tmpRadio != 0 && (Math.abs(radio - viewRadio)) < (Math.abs(tmpRadio - viewRadio))) {
                tmpRadio = radio;
                bestX = newX;
                bestY = newY;
            }
        }

        if (bestX > 0 && bestY > 0) {
            return camera.new Size((int) bestX, (int) bestY);
        }
        return null;
    }

    /**
     * 设置焦点和测光区域
     *
     * @param event
     */
    @TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
    public void focusOnTouch(MotionEvent event) {

        int[] location = new int[2];
        RelativeLayout relativeLayout = (RelativeLayout)getParent();
        relativeLayout.getLocationOnScreen(location);

        Rect focusRect = MultiCameraUtils.calculateTapArea(mFocusView.getWidth(),
                mFocusView.getHeight(), 1f, event.getRawX(), event.getRawY(),
                location[0], location[0] + relativeLayout.getWidth(), location[1],
                location[1] + relativeLayout.getHeight());
        Rect meteringRect = MultiCameraUtils.calculateTapArea(mFocusView.getWidth(),
                mFocusView.getHeight(), 1.5f, event.getRawX(), event.getRawY(),
                location[0], location[0] + relativeLayout.getWidth(), location[1],
                location[1] + relativeLayout.getHeight());

        Camera.Parameters parameters = camera.getParameters();
        parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);

        if (parameters.getMaxNumFocusAreas() > 0) {
            List<Camera.Area> focusAreas = new ArrayList<Camera.Area>();
            focusAreas.add(new Camera.Area(focusRect, 1000));

            parameters.setFocusAreas(focusAreas);
        }

        if (parameters.getMaxNumMeteringAreas() > 0) {
            List<Camera.Area> meteringAreas = new ArrayList<Camera.Area>();
            meteringAreas.add(new Camera.Area(meteringRect, 1000));

            parameters.setMeteringAreas(meteringAreas);
        }

        try {
            camera.setParameters(parameters);
        } catch (Exception e) {
        }
        camera.autoFocus(this);
    }

    /**
     * 设置聚焦的图片
     * @param focusView
     */
    public void setFocusView(FocusView focusView) {
        this.mFocusView = focusView;
    }

    /**
     * 设置自动聚焦，并且聚焦的圈圈显示在屏幕中间位置
     */
    @TargetApi(Build.VERSION_CODES.HONEYCOMB)
    public void setFocus() {
        if(!mFocusView.isFocusing()) {
            try {
                camera.autoFocus(this);
                mFocusView.setX((MultiCameraUtils.getWidthInPx(getContext())-mFocusView.getWidth()) / 2);
                mFocusView.setY((MultiCameraUtils.getHeightInPx(getContext())-mFocusView.getHeight()) / 2);
                mFocusView.beginFocus();
            } catch (Exception e) {
            }
        }
    }

    public  Size getPreviewSize(List<Camera.Size> list, int th){
        Collections.sort(list, sizeComparator);
        Size size=null;
        for(int i=0;i<list.size();i++){
            size=list.get(i);
            int x = Math.max(viewWidth, viewHeight);
            int y = Math.min(viewWidth, viewHeight);
            if((size.width>th)&&equalRate(size, (float)x/y)){
                break;
            }
        }
        return size;
    }

    public Size getPictureSize(List<Camera.Size> list, int th){
        Collections.sort(list, sizeComparator);
        Size size=null;
        for(int i=0;i<list.size();i++){
            size=list.get(i);
            int x = Math.max(viewWidth, viewHeight);
            int y = Math.min(viewWidth, viewHeight);
            if(size.width>th && equalRate(size, (float)x/y)){
                break;
            }
        }
        return size;
    }

    public boolean equalRate(Size s, float rate) {
        float r = (float) (s.width) / (float) (s.height);
        if (Math.abs(r - rate) <= 0.1) {
            return true;
        } else {
            return false;
        }
    }

    //图片尺寸获取
    public  class CameraSizeComparator implements Comparator<Size> {
        //按升序排列
        @Override
        public int compare(Size lhs, Size rhs) {
            // TODO Auto-generated method stub
            if (lhs.width == rhs.width) {
                return 0;
            } else if (lhs.width > rhs.width) {
                return 1;
            } else {
                return -1;
            }
        }
    }

}