# GitHub CI/CD 使用说明

本项目使用GitHub Actions自动化构建和发布Flutter应用。

## 可用工作流

### 1. Flutter CI/CD (`flutter-ci.yml`)

这个工作流会在以下情况下触发：
- 向`main`或`master`分支推送代码
- 创建指向这些分支的Pull Request
- 推送版本标签（格式为`v*`，例如`v1.0.0`）
- 手动触发工作流

工作流包含以下任务：
- **代码分析**：检查代码质量
- **运行测试**：运行所有测试用例
- **构建Android应用**：生成发布版APK
- **构建iOS应用**：生成未签名的IPA文件

构建产物将作为工作流的工件（Artifacts）保存。

### 2. 应用发布 (`release.yml`)

这个工作流在推送版本标签时触发，用于创建GitHub Release。

工作流会：
- 验证标签版本与`pubspec.yaml`中的版本一致
- 自动生成变更日志（优先使用`CHANGELOG.md`，如果没有则使用提交记录）
- 创建GitHub Release

### 3. Android签名发布 (`android-release.yml`)

这个工作流需要手动触发，用于构建签名版的Android应用。

工作流会：
- 验证输入的版本标签与`pubspec.yaml`中的版本一致
- 使用配置的签名密钥构建签名APK和AAB
- 创建新的GitHub Release或更新现有Release

## 如何发布新版本

1. 更新`pubspec.yaml`中的版本号
2. 提交更改并推送到远程仓库
3. 创建并推送对应版本的标签：

```bash
# 假设当前版本是1.0.0
git tag v1.0.0
git push origin v1.0.0
```

4. GitHub Actions将自动构建应用并创建Release

## 设置Android签名密钥

要使用Android签名发布工作流，需要在GitHub仓库设置以下密钥：

1. 前往仓库 Settings → Secrets and variables → Actions
2. 添加以下Repository secrets:
   - `KEY_JKS`：将keystore文件用base64编码的内容
   - `STORE_PASSWORD`：keystore的密码
   - `KEY_PASSWORD`：签名密钥的密码
   - `KEY_ALIAS`：签名密钥的别名

将keystore转为base64的命令：
```bash
base64 -i path/to/keystore.jks | pbcopy  # macOS (复制到剪贴板)
# 或
base64 -i path/to/keystore.jks -o key_jks_base64.txt  # 保存到文件
```

## 常见问题

### 版本号格式

版本号应遵循语义化版本规范（[Semantic Versioning](https://semver.org/lang/zh-CN/)），格式为：`X.Y.Z+build`，其中：
- X = 主版本号
- Y = 次版本号
- Z = 修订号
- build = 构建号（可选）

标签版本只需包含`X.Y.Z`部分。

### 手动触发工作流

1. 前往GitHub仓库页面
2. 点击"Actions"标签
3. 在左侧选择要运行的工作流
4. 点击"Run workflow"
5. 输入必要参数（如适用）并点击"Run workflow"按钮

### 构建失败排查

如果构建失败，请检查：
1. 日志输出，查看具体错误
2. 代码是否通过分析和测试
3. 版本标签是否与`pubspec.yaml`中的版本一致
4. 是否有所需的密钥和证书 