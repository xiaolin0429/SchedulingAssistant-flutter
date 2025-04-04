# Android签名配置指南

本文档介绍如何配置Android应用签名，包括本地开发环境和CI/CD环境。

## 创建签名密钥

要创建新的密钥库文件，请使用以下命令：

```bash
# 导航到项目目录
cd /path/to/SchedulingAssistant-flutter

# 创建密钥目录
mkdir -p android/app/keys

# 生成密钥 (交互式，需要回答几个问题)
keytool -genkey -v -keystore android/app/keys/scheduling_assistant.jks -keyalg RSA -keysize 2048 -validity 10000 -alias scheduling_assistant
```

在执行上述命令后，您需要提供以下信息：
- 密钥库密码
- 姓名和组织信息
- 密钥密码 (可以与密钥库密码相同)

## 本地配置

1. 创建`android/key.properties`文件，内容如下：

```
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=scheduling_assistant
storeFile=app/keys/scheduling_assistant.jks
```

2. 替换`YOUR_KEYSTORE_PASSWORD`和`YOUR_KEY_PASSWORD`为您在创建密钥时设置的实际密码。

## GitHub Actions配置

对于GitHub Actions CI/CD，您需要设置以下Secrets：

1. 将JKS文件编码为base64：

```bash
base64 -i android/app/keys/scheduling_assistant.jks | pbcopy  # macOS (复制到剪贴板)
# 或
base64 -i android/app/keys/scheduling_assistant.jks > key_jks_base64.txt  # 保存到文件
```

2. 在GitHub仓库中，前往 Settings → Secrets and variables → Actions

3. 添加以下Repository secrets:
   - `KEY_JKS`：输入上一步中生成的base64编码内容
   - `STORE_PASSWORD`：keystore的密码
   - `KEY_PASSWORD`：签名密钥的密码
   - `KEY_ALIAS`：`scheduling_assistant`

## 注意事项

- **不要**将密钥库文件和`key.properties`提交到版本控制系统
- 确保在本地机器和CI/CD环境中都完成了配置
- 在发布生产应用之前，考虑使用更安全的密钥管理方案

## 验证签名

要验证应用是否正确签名，可以使用以下命令：

```bash
# 对于已安装的应用
keytool -list -printcert -jarfile app-release.apk

# 或者检查APK的签名
jarsigner -verify -verbose -certs app-release.apk
``` 