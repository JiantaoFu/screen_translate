你的点子很有创意！类似于共享屏幕的权限结合实时翻译功能，确实可以解决许多人在多语言环境中遇到的沟通障碍。这个想法在多个场景下都会非常有用，尤其是在跨语言的工作或学习环境中。

### 这个点子的潜力和优势：
1. **无缝的翻译体验**：
   如果能像共享屏幕一样，允许其他设备或应用访问并实时翻译用户手机屏幕上的文字，用户将不需要切换应用或者手动输入任何内容。只要屏幕上有文字，就能被直接翻译。

2. **适用于多种场景**：
   - **跨语言的团队合作**：例如，团队成员使用不同语言的操作系统或应用程序，实时翻译能让大家无障碍沟通。
   - **实时在线课程/会议**：像Zoom这样的会议工具，可以在屏幕共享时同时开启翻译功能，帮助非母语的参与者更好地理解内容。
   - **游戏和应用内翻译**：尤其对于需要即时理解内容的场景，比如游戏内对话、应用文本等，可以快速获取翻译。

3. **减少误解和困扰**：
   人们在浏览网页、使用应用时可能会遇到不熟悉的语言，实时翻译功能可以减少语言障碍，帮助用户更好地理解内容。

4. **提高用户体验**：
   用户无需退出当前操作界面或切换应用，翻译会实时显示在他们的视野内。这会让体验变得更加流畅和直观。

### 持面临的挑战：
1. **隐私和安全问题**：
   为了实现屏幕共享权限，必须小心处理用户隐私和敏感信息。例如，用户可能不希望某些应用或者他人看到他们的私人信息。因此，必须在设计时加上权限管理和隐私保护机制。

2. **准确度和上下文理解**：
   实时翻译的准确性是一个挑战。机器翻译系统有时不能完全理解上下文，特别是在非标准语言或方言的情况下。因此，需要确保翻译引擎能够准确处理复杂的句子和特定的语境。

3. **兼容性和设备要求**：
   这个功能需要跨平台支持，同时适应各种设备、应用程序和操作系统，确保翻译体验的一致性。

### 可能的实现方式：
- 可以通过在手机操作系统中实现一个全局悬浮窗，用户授权该应用进行屏幕读取，当翻译功能开启时，屏幕上的所有文字可以被识别并翻译。
- 可以结合OCR（光学字符识别）技术，提取屏幕中的文字并翻译，再通过弹出窗口或侧边栏显示翻译结果。

总的来说，你的点子具备非常大的潜力，可以为用户提供更方便、流畅的跨语言交流体验。随着技术的进步，像你说的这种屏幕实时翻译的应用未来可能会变得非常流行。

---

## 👨‍💻 开发者指南 (Developer Guide)

### 1. 发布正式版前置配置 (Release Keystore)
在编译 `Release` 版本的 APK 或 AppBundle 前，您必须配置应用的签名证书秘钥。
请在 `android/` 目录下创建一个名为 `key.properties` 的文件（请不要提交到 Git），并填入以下内容：
```properties
storePassword=您的秘钥库密码
keyPassword=您的密钥密码
keyAlias=screen-trans
storeFile=../screen-trans-key.keystore
```

### 2. 自动化构建与版本升级
本项目包含两个自动化构建脚本，支持多语言转换、版本号自动升级以及一键打包，极大简化了发布流程。

#### Windows 环境 (`build.bat`)
双击运行 `build.bat`，或在 CMD/PowerShell 中执行：
- 选择 **[7] Bump Version + Full Release (APK + AAB)**
- 在二级菜单中，您可以选择升级大版本号(Major)、小版本号(Minor)、补丁号(Patch) 或 仅升级构建号(Build Number)。
- 脚本会自动修改 `pubspec.yaml`，然后进行全局多语言生成的编译打包。
你的点子很有创意！类似于共享屏幕的权限结合实时翻译功能，确实可以解决许多人在多语言环境中遇到的沟通障碍。这个想法在多个场景下都会非常有用，尤其是在跨语言的工作或学习环境中。

### 这个点子的潜力和优势：
1. **无缝的翻译体验**：
   如果能像共享屏幕一样，允许其他设备或应用访问并实时翻译用户手机屏幕上的文字，用户将不需要切换应用或者手动输入任何内容。只要屏幕上有文字，就能被直接翻译。

2. **适用于多种场景**：
   - **跨语言的团队合作**：例如，团队成员使用不同语言的操作系统或应用程序，实时翻译能让大家无障碍沟通。
   - **实时在线课程/会议**：像Zoom这样的会议工具，可以在屏幕共享时同时开启翻译功能，帮助非母语的参与者更好地理解内容。
   - **游戏和应用内翻译**：尤其对于需要即时理解内容的场景，比如游戏内对话、应用文本等，可以快速获取翻译。

3. **减少误解和困扰**：
   人们在浏览网页、使用应用时可能会遇到不熟悉的语言，实时翻译功能可以减少语言障碍，帮助用户更好地理解内容。

4. **提高用户体验**：
   用户无需退出当前操作界面或切换应用，翻译会实时显示在他们的视野内。这会让体验变得更加流畅和直观。

### 持面临的挑战：
1. **隐私和安全问题**：
   为了实现屏幕共享权限，必须小心处理用户隐私和敏感信息。例如，用户可能不希望某些应用或者他人看到他们的私人信息。因此，必须在设计时加上权限管理和隐私保护机制。

2. **准确度和上下文理解**：
   实时翻译的准确性是一个挑战。机器翻译系统有时不能完全理解上下文，特别是在非标准语言或方言的情况下。因此，需要确保翻译引擎能够准确处理复杂的句子和特定的语境。

3. **兼容性和设备要求**：
   这个功能需要跨平台支持，同时适应各种设备、应用程序和操作系统，确保翻译体验的一致性。

### 可能的实现方式：
- 可以通过在手机操作系统中实现一个全局悬浮窗，用户授权该应用进行屏幕读取，当翻译功能开启时，屏幕上的所有文字可以被识别并翻译。
- 可以结合OCR（光学字符识别）技术，提取屏幕中的文字并翻译，再通过弹出窗口或侧边栏显示翻译结果。

总的来说，你的点子具备非常大的潜力，可以为用户提供更方便、流畅的跨语言交流体验。随着技术的进步，像你说的这种屏幕实时翻译的应用未来可能会变得非常流行。

---

## 👨‍💻 开发者指南 (Developer Guide)

### 1. 发布正式版前置配置 (Release Keystore)
在编译 `Release` 版本的 APK 或 AppBundle 前，您必须配置应用的签名证书秘钥。
请在 `android/` 目录下创建一个名为 `key.properties` 的文件（请不要提交到 Git），并填入以下内容：
```properties
storePassword=您的秘钥库密码
keyPassword=您的密钥密码
keyAlias=screen-trans
storeFile=../screen-trans-key.keystore
```

### 2. 自动化构建与版本升级
本项目包含两个自动化构建脚本，支持多语言转换、版本号自动升级以及一键打包，极大简化了发布流程。

#### Windows 环境 (`build.bat`)
双击运行 `build.bat`，或在 CMD/PowerShell 中执行：
- 选择 **[7] Bump Version + Full Release (APK + AAB)**
- 在二级菜单中，您可以选择升级大版本号(Major)、小版本号(Minor)、补丁号(Patch) 或 仅升级构建号(Build Number)。
- 脚本会自动修改 `pubspec.yaml`，然后进行全局多语言生成的编译打包。

#### Mac / Linux 环境 (`build.sh`)
打开终端执行以下命令：
- **常规发布构建**：`./build.sh --release`
- **升级构建号并发布**：`./build.sh --release --bump build`
- **升级补丁号并发布**：`./build.sh --release --bump patch`
- **升级小版本并发布**：`./build.sh --release --bump minor`
- **升级大版本并发布**：`./build.sh --release --bump major`

### 3. 一键发布到 Google Play (`tools/release.py`)
把测试、签名打包、上传和打 tag 串成一条命令，任何一步失败都会停下，不会上传半成品：

1. **预检**：工作区没有未提交的改动；正式签名密钥存在（否则 Gradle 会悄悄改用 debug 签名）；JDK 17–23 可用；Play 凭据可用；versionCode 高于 Play 上已有的最大值
2. **测试**：`flutter test` 和 Android 单元测试
3. **构建**：可选升级版本号，生成多语言资源，构建签名 AAB，并确认不是 debug 签名
4. **上传**：上传 AAB 和 R8 mapping（Play 管理中心的崩溃堆栈才可读），分配到轨道并附上发布说明；Play 校验通过后，确认才提交
5. **打 tag**：提交版本号改动，打 tag `v<版本>+<构建号>`；加 `--push` 会一并推送

**一次性配置**（每台发版用的电脑做一次）
1. GCP 项目 `screentranslation-cff83`（即 Firebase 项目）已启用 *Google Play Android Developer API*。
2. 服务账号 `play-publisher@screentranslation-cff83.iam.gserviceaccount.com` 已在 Play 管理中心 → 用户和权限中获得本应用的发布权限：查看应用信息、发布到测试轨道、发布到正式版。
3. 在 Cloud Console → IAM → 服务账号 → `play-publisher` → 密钥，为这台电脑新建一个 JSON 密钥。把它放在仓库之外，例如 `C:\Users\<你>\keys\play-publisher.json`，然后设置环境变量：`setx PLAY_SERVICE_ACCOUNT_JSON C:\Users\<你>\keys\play-publisher.json`。密钥不要提交；`.gitignore` 已忽略常见的密钥文件名。
4. 安装依赖：`pip install -r tools/requirements-release.txt`
5. `android/key.properties` 和正式签名密钥库要就位（见上文第 1 节）。

**发版流程**
1. **准备**：功能分支合并进 `main`，并在 `main` 上发版。在 `main` 以外的分支发正式版时，脚本会给出警告。然后写好更新说明，目录结构如 `release_notes/1.2.2/en-US.txt`、`zh-CN.txt`，每种语言最多 500 个字符。
2. **发到内部测试**：
   ```bash
   python tools/release.py --bump patch --track internal --notes-dir release_notes/1.2.2 --push
   ```
   只改构建号时用 `--bump build`。第一次用、或改过脚本后，可以先加 `--dry-run`：会完整上传并由 Play 校验，然后丢弃，不会发布。
3. **真机验证**：测试人员名单里的账号可以从 Play 安装内部测试版。重点测视频或游戏画面上的实时翻译，以及横屏。
4. **推广到正式版**：在 Play 管理中心 → 内部测试 → 对应版本 → "推广版本" → "正式版"。不用重新上传，更新说明会一起带过去。建议先选分阶段发布（比如 20%），Crashlytics 没问题再扩大到 100%。
5. **审核与监控**：正式版要经过 Google 审核，通常几小时到两天。上线后关注 Crashlytics 崩溃率、ANR 和退款率；出问题就在 Play 管理中心暂停发布。

也可以一步直接发正式版（跳过内部测试）：`python tools/release.py --bump patch --track production --rollout 0.2 --notes-dir release_notes/1.2.2 --push`

**其他命令**
```bash
python tools/release.py --build-only          # 只构建签名 AAB，不上传
python tools/release.py --help                # 全部选项
python tools/test_release.py                  # 发版脚本自身的测试
```
`build.bat` 的 **[8]** 和 `./build.sh --publish [track]` 调用的都是这个脚本。

**常见问题**
- **403 / 没有权限**：服务账号在 Play 管理中心的权限没配好，或者刚配好、还没生效，过一会儿再试。
- **提示 changes cannot be sent for review automatically**：加上 `--changes-not-sent-for-review` 重跑，然后到 Play 管理中心手动提交审核。
- **提示 versionCode must be higher**：Play 上已经有这个构建号了，加 `--bump build`。
- **构建失败，提示 JDK 版本不对**：Gradle 需要 JDK 17–23（Android Studio 自带的 JBR 25 不行），用 `--java-home` 指定，或设置 `RELEASE_JAVA_HOME`。

---

## 🍏 iOS 支持与配置指南 (iOS Setup Guide - Mac Only)

由于 iOS 系统的限制（不允许类似 Android 的全局悬浮窗），我们在 iOS 上采用 **Share Extension（分享扩展）** 和 **应用内选择图片（Image Picker）** 的方式来实现屏幕翻译。

如果您要在 Mac 上编译和运行 iOS 版本，请务必完成以下手动配置步骤：

### 1. 更新 Podfile
确保您的 `ios/Podfile` 的平台目标版本至少为 iOS 12.0（Google ML Kit 的最低要求）。
在 Mac 上打开终端，进入项目目录并执行：
```bash
flutter pub get
cd ios
pod install
```

### 2. 在 Xcode 中配置 Share Extension（分享扩展）
为了让应用出现在系统的“分享菜单”中，您必须在 Xcode 中创建一个 Share Extension target：
1. 在 Xcode 中打开 `ios/Runner.xcworkspace`。
2. 点击菜单 **File > New > Target...**，选择 **Share Extension**，将其命名为 `ShareExtension`。
3. 为 `Runner` target 和 `ShareExtension` target 分别配置相同的 **App Groups**，以便两者可以共享数据。
4. 按照 [receive_sharing_intent 官方文档](https://pub.dev/packages/receive_sharing_intent) 完成 Swift 代码的配置。

### 3. 配置 Firebase (GoogleService-Info.plist)
1. 前往 Firebase 控制台，为您的项目添加一个 iOS 应用。
2. 下载生成的 `GoogleService-Info.plist` 文件。
3. 将该文件拖入 Xcode 项目中（放置在 `Runner` 目录下），并确保勾选了 `Copy items if needed`。

> **提示**：即使在完成 Share Extension 配置之前，应用内的 **“选择图片进行翻译”** 功能也已完全可用。您可以在模拟器中直接测试该回退方案！
