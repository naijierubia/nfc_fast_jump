# NFC快速跳转 (NFC Fast Jump)

一个基于Flutter开发的NFC标签写入工具，可以将音乐链接等信息写入NFC标签，通过触碰NFC标签快速跳转到指定内容。

## 功能特性

- 支持将网易云音乐歌曲链接写入NFC标签
- 通过NFC标签快速跳转到指定歌曲播放页面
- 支持批量写入多首歌曲
- 可扩展支持其他音乐平台（如QQ音乐等，正在开发中）

## 技术栈

- Flutter框架
- NFC Manager插件用于NFC功能
- HTTP库用于获取歌曲信息
- Go Router用于页面路由管理

## 使用方法

1. 打开应用，选择要写入的音乐平台（目前支持网易云音乐）
2. 输入音乐分享链接（支持多行输入）
3. 点击"解析链接"按钮解析链接并获取歌曲信息
4. 在录入界面选择要写入的歌曲
5. 点击"开始录入"按钮，将NFC标签靠近设备进行写入
6. 写入成功后，可以通过触碰NFC标签快速跳转到对应歌曲

## 项目结构

- `lib/pages/`: 页面文件
  - `main_screen.dart`: 主界面
  - `netease_music_page.dart`: 网易云音乐链接解析页面
  - `nfc_write_page.dart`: NFC写入页面
  - `read_page.dart`: NFC读取页面
  - `other_page.dart`: 其他功能页面
- `lib/routes/`: 路由配置
- `lib/services/`: 服务类

## 安装与运行

1. 确保已安装Flutter开发环境
2. 克隆项目代码
3. 运行 `flutter pub get` 安装依赖
4. 连接设备并运行 `flutter run` 启动应用

## 注意事项

- 需要支持NFC功能的Android设备
- 确保设备NFC功能已开启
- 部分Android设备可能需要在系统设置中授权NFC权限