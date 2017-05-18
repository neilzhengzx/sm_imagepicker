package com.reactlibrary.sm_imagepicker;

import android.graphics.Bitmap;
import android.os.Environment;
import android.util.Log;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;

/**
 * Created by sun on 14-5-5.
 */
public class FileUtil {

	private static  String TAG = "SUN-File";
	private static String urlNull = "原文件路径不存在";
	private static String isFile = "原文件不是文件";
	private static String canRead = "原文件不能读";
	private static String notWrite = "备份文件不能写入";
	private static String message = "OK";
	private static String cFromFile = "创建原文件出错:";
	private static String ctoFile = "创建备份文件出错:";

	private static String img_xml = "file.xml";

	public static final int TYPE_IMAGE = 0;
	public static final int TYPE_VOICE = 1;
	/**
	 *
	 * @param fromFileUrl
	 *            旧文件地址和名称
	 * @param toFileUrl
	 *            新文件地址和名称
	 * @return 返回备份文件的信息，ok是成功，其它就是错误
	 */
	public static String copyFile(String fromFileUrl, String toFileUrl) {
		File fromFile = null;
		File toFile = null;
		try {
			fromFile = new File(fromFileUrl);
		} catch (Exception e) {
			return cFromFile + e.getMessage();
		}
		try {
			toFile = new File(toFileUrl);
		} catch (Exception e) {
			return ctoFile + e.getMessage();
		}
		if (!fromFile.exists()) {
			return urlNull;
		}
		if (!fromFile.isFile()) {
			return isFile;
		}
		if (!fromFile.canRead()) {
			return canRead;
		}
		// 复制到的路径如果不存在就创建
		if (!toFile.getParentFile().exists()) {
			toFile.getParentFile().mkdirs();
		}
		if (toFile.exists()) {
			toFile.delete();
		} else {
			try {
				toFile.createNewFile();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		if (!toFile.canWrite()) {
			return notWrite;
		}
		try {
			FileInputStream fosfrom = new FileInputStream(
			                                                             fromFile);
			FileOutputStream fosto = new FileOutputStream(toFile);
			byte bt[] = new byte[1024];
			int c;
			while ((c = fosfrom.read(bt)) > 0) {
				fosto.write(bt, 0, c); // 将内容写到新文件当中
			}
			//关闭数据流
			fosfrom.close();
			fosto.close();

		} catch (Exception e) {
			e.printStackTrace();
			message = "备份失败!";

		}
		return message;
	}

	public static String generaFileStatusXml(final String path, final String server, final String fromfile, final int type){
		String guid = java.util.UUID.randomUUID().toString();
		if(fromfile.startsWith(path)) {
			guid = fromfile.substring(path.length());
		}
		final String guid2 = guid;

		new Thread(new Runnable() {
			@Override
			public void run() {
				if(!fromfile.startsWith(path)) {
					File file = new File(path, guid2);
					if(file.exists()){
						file.delete();
					}
					String result = copyFile(fromfile, file.getPath());
					Log.d(TAG, "generaImageStatusXml : copyFile .. result = "+result);
				} else {
					Log.d(TAG, "generaImageStatusXml: 已在目录下 不用复制 guid2 = " + guid2);
				}
				saveCacheImgToXML(path, "<Image ID =\""+guid2+"\" Server=\""+server+"\" Type=\""+type+"\"/>", true);
			}
		}).run();
		return guid2;
	}

	public static String readImageCacheFromXML(String path){
		File file = new File(path, img_xml);
		if(!file.exists()) {
			return "";
		} else {
			String content = "";
			try {
				InputStream instream = new FileInputStream(file);
				if (instream != null){
					InputStreamReader inputreader = new InputStreamReader(instream);
					BufferedReader buffreader = new BufferedReader(inputreader);
					String line;
					//分行读取
					while ((line = buffreader.readLine()) != null) {
						content += line + "\n";
					}
					instream.close();
				}
			}
			catch (FileNotFoundException e){
				Log.d(TAG, "The File doesn't not exist.");
			}
			catch (IOException e){
				Log.d(TAG, e.getMessage());
			}

			return content;
		}
	}

	/**
	 *  从xml中读取等待上传的图片信息
	 * @param path   图片目录
	 * @param content 新内容
	 * @param append 是否追加
	 */
	public synchronized static void saveCacheImgToXML(String path, String content, boolean append){

		File file = new File(path, img_xml);

		if(content.length() == 0 && !append){
			if(file.exists()) {
				file.delete();
			}
			return;
		}
		if(!file.exists()){
			try {
				file.createNewFile();
			} catch (IOException e) {
				e.printStackTrace();
				Log.d(TAG, "createNewFile faied... path = "+file.getPath());
			}
		}

		BufferedWriter out = null;
		try {
			out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(file, append)));
			out.write(content);
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				out.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	public synchronized static void saveBitmapToSD(Bitmap bitmap, String path, int quality) {
		File f = new File(path);
		FileOutputStream fOut = null;
		try {
			if(f.exists()){
				f.delete();
			}
			f.createNewFile();
			fOut = new FileOutputStream(f);
			bitmap.compress(Bitmap.CompressFormat.JPEG, quality, fOut);
			fOut.flush();
			fOut.close();
		} catch (Exception e) {
			Log.e(TAG, "保存图片失败... path = "+path+" error = "+e.getMessage());
			return;
		}
		Log.e(TAG, "保存图片成功!!... path = "+path);

	}

	public synchronized static void clearImageCache(String path){
		final File f = new File(path);
		if(!f.isDirectory()){
			return;
		}
		new Thread(new Runnable() {
			@Override
			public void run() {
				File[] files = f.listFiles();
				for (int i = 0; i < files.length; i++){
					File file = files[i];
					if(file.exists()){
						file.delete();
					}
				}
			}
		}).run();

	}

    public static String  getAppDirPath(){
        return Environment.getExternalStorageDirectory().toString()+"/camera";
    }
}
