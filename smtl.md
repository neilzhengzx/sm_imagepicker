### ImagePicker
提供系统接口拍照。http返回图片。支持单图和多图上传

- **请求对象**

        { 
            "method" : "imagePicker",
            "params" : { 
                method: <string>, 
                filename: <string>
                isEdit: <number>,  
                compressedPixel: <number>
                quality:<number>
                number: <number> 
                comeraQialityMode: <number>  
            }
        }

    - method: 
          `imageFromCamera`：直接打开相机 
          `imageFromCameraAlbum`：打开一个选择列表，用于选择相机或相册
          `imageFromAlbum`：直接打开相册
          `multiImage`：多图上传
    - isEdit: 默认值: false， 是否允许剪裁  //不支持多图上传
    - filename: 默认值: '' 上传图片的名称  //不支持多图上传
    - compressedPixel: 默认值: 1280， 图片压缩像素值
    - quality: 默认值: 60， 图片压缩质量
    - comeraQialityMode: 默认值: 0， `0`:打开一个选择列表，用于选择压缩上传或原题上传  
                    `1`:压缩上传
                    `2`:原图上传  
    - number: 默认值: 9，上传图片的最大值  //仅支持多图上传

- **响应对象**

        { 
          "id": <number>, 
          "result": { "success" : <bool>, "error" : <string>}
        }
  - success:  false:失败 
  - error: 错误信息  Cancel:取消 
