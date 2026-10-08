# Seedance 本地桥接工具

该工具使用用户环境变量 `ARK_API_KEY` 调用火山方舟，不会把密钥写入项目。

默认模型为 `doubao-seedance-2-0-fast-260128`，默认生成 5 秒、720p、1:1、无音频、无水印视频。

## 安全预览

预览请求参数，不提交任务、不计费：

```powershell
.\tools\seedance\seedance.ps1 preview -Prompt "固定镜头，一只猫在纯绿色背景前做自然的待机循环" -Ratio 1:1 -Duration 5
```

带本地参考图预览：

```powershell
.\tools\seedance\seedance.ps1 preview -Prompt "保持角色造型，生成待机循环" -Image ".\reference.png"
```

## 提交与下载

`submit` 会创建付费任务：

```powershell
.\tools\seedance\seedance.ps1 submit -Prompt "固定镜头，一只猫在纯绿色背景前做自然的待机循环" -Ratio 1:1 -Duration 5
```

记录返回的任务 ID，然后等待并下载：

```powershell
.\tools\seedance\seedance.ps1 wait -TaskId "任务ID"
```

视频默认下载到 `output/seedance/`。
