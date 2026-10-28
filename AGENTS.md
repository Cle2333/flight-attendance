# 航班打卡项目规则

## 构建与验证

```powershell
cd app
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

Flutter 工具在本机沙箱内会卡在 SDK 缓存锁，需在沙箱外执行。

## 硬约束

- 这是纯本地应用：不得重新引入 HTTP/API、账号登录、服务器配置、排行榜或云端同步。
- 记录、资料、设置只能写入 `lib/data/app_database.dart` 管理的 SQLite；`shared_preferences` 仅用于旧数据一次性迁移。
- 修改记录时间后必须调用单一路径刷新内存记录并重算 `AppState.lastTakeoff`，避免首页倒计时与数据库不一致。
- 所有用户可见文案使用中文。
- 导入导出保持 JSON 与 CSV 兼容；导入按“起飞时间 + 感受”去重。
- 头像图片保存在应用支持目录，SQLite 只保存本地路径；不要再引入 emoji 头像选择器。
