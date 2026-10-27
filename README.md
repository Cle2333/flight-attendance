# 航班打卡

一个有趣的生活记录应用，用"起飞"来记录你的每一次重要时刻。

> **架构**：Flutter 前端（`app/`）+ Spring Boot 后端（`server/`）。
> 前端仅在 Flutter，后端仅作为 API 服务，**不负责 serve 任何 web 静态资源**。

## 功能特性

- **双击起飞** — 双击屏幕即可打卡，带粒子特效
- **起飞记录** — 日历视图查看历史记录，支持周/月切换
- **起飞感受** — 打卡后可选择感受或自定义填写
- **排行榜** — 查看自己和朋友的起飞次数
- **个人设置** — 自定义昵称、头像、计时精度、起飞特效、机长语录
- **云端同步** — 登录账号后数据自动同步到服务器
- **本地模式** — 无需登录，数据保存在设备本地
- **离线优先** — server 暂时不可达时 App 仍能用本地缓存继续打卡，顶条提示重试
- **管理员 API** — `/api/admin/**` 提供统计数据、排行榜、用户列表（**详见安全说明**）

## 技术栈

- **前端（App）**：Flutter 3.44+，GetX 状态管理 + 路由
- **后端**：Spring Boot 3.3 + Java 17 + Spring Data JPA + Spring Security（仅 BCrypt + JWT 过滤器）
- **数据库**：MariaDB 10.5+（本地开发可用 docker compose 一键起）
- **迁移**：Flyway
- **认证**：JWT (jjwt 0.12)
- **CI**：GitHub Actions（同时构建 Spring Boot JAR 和 Flutter APK）

## 目录结构

```
flight-attendance-web/
├── app/                  # Flutter 前端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── api/          # HTTP 客户端
│   │   ├── models/
│   │   ├── screens/      # 登录 / 首页 / 记录 / 排行 / 我的
│   │   ├── state/        # AppState (GetxController)
│   │   ├── storage/      # SharedPreferences 封装
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/      # 粒子 / 日历 / 起飞遮罩 / 选择器
│   ├── android/
│   ├── pubspec.yaml
│   └── ...
├── server/               # Spring Boot 后端
│   ├── pom.xml
│   ├── Dockerfile
│   ├── docker-compose.yml # 本地起 MariaDB
│   ├── src/main/java/com/cle2333/flightattendance/
│   │   ├── FlightAttendanceApplication.java
│   │   ├── config/        # SecurityConfig, StaticResourceConfig
│   │   ├── controller/    # Auth/User/Record/Settings/Admin/Test
│   │   ├── dto/
│   │   ├── entity/        # User, Record, Settings
│   │   ├── exception/
│   │   ├── repository/
│   │   ├── security/      # JwtTokenProvider, JwtAuthenticationFilter
│   │   └── service/
│   ├── src/main/resources/
│   │   ├── application.yml        # 公共配置
│   │   ├── application-dev.yml    # 默认 profile，连 MariaDB
│   │   ├── application-prod.yml   # 生产 profile
│   │   ├── application-test.yml   # H2，集成测试用
│   │   └── db/migration/V1__init.sql
│   └── src/test/java/...
├── .github/workflows/
│   └── build.yml          # CI: server JAR + app APK
└── README.md
```

## 快速开始

### 1. 启动 MariaDB

最方便是用项目自带的 `docker-compose.yml`：

```bash
cd server
docker compose up -d
# 等待 healthcheck 通过（约 5-10 秒）
```

手动安装的 MariaDB 也可以，创建一个 `flight_attendance` 库即可。

### 2. 启动后端

> **环境要求**：Java 17 + Maven 3.6+（项目本身不带 wrapper，走全局 `mvn`）。

```bash
cd server
mvn spring-boot:run
# 或
mvn -DskipTests package && java -jar target/flight-attendance-server.jar
```

默认监听 `http://localhost:8080`：

- API 根：`http://localhost:8080/api/`
- 测试：`curl http://localhost:8080/api/test`
- 管理员 API：`/api/admin/stats`、`/api/admin/leaderboard?type=all|week` 等（**⚠️ 无鉴权，仅内网/加保护后再暴露**）

第一次启动会自动跑 Flyway 迁移（`V1__init.sql`），建好三张表。

#### 备胎 profile：`h2`（本机没装 MariaDB 时）

开发机如果起不动 MariaDB（Arch/权限/systemd 都有坑），可以直接用内嵌 H2（文件模式，重启保留数据）：

```bash
SPRING_PROFILES_ACTIVE=h2 java -jar target/flight-attendance-server.jar
# 数据落在 ./data/flight_attendance.mv.db
```

注意：`h2` profile 没有 Flyway 迁移（用 Hibernate `ddl-auto: update`），**不能直接当生产**。生产请用 `dev` 或 `prod` profile + 真 MariaDB。

### 3. 运行 Flutter 前端

```bash
cd app
flutter pub get
flutter run
```

### 4. 在 App 内配置后端地址

App 启动后：

- 登录页右上角 ⚙️ 打开"服务器设置"
- Android **模拟器**：填 `http://10.0.2.2:8080`
- Android **真机**：填运行后端的机器的局域网 IP，例如 `http://192.168.1.100:8080`

也可用 `--dart-define` 在启动时设置：

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8080
```

## API 接口

后端 API 与原 Node.js 版**完全一致**，Flutter 前端无需改动：

- `POST /api/auth/register` — 注册
- `POST /api/auth/login` — 登录
- `GET  /api/user/profile` — 获取用户信息（需鉴权）
- `PUT  /api/user/profile` — 更新用户信息（需鉴权）
- `GET  /api/records` — 列出所有打卡记录（需鉴权）
- `POST /api/records` — 新增打卡记录（需鉴权）
- `PUT  /api/records/:id` — 更新打卡记录（需鉴权）
- `DELETE /api/records/:id` — 删除打卡记录（需鉴权）
- `POST /api/records/sync` — 同步本地记录到云端（需鉴权）
- `GET  /api/settings` — 获取用户设置（需鉴权）
- `PUT  /api/settings` — 更新用户设置（需鉴权）
- `GET  /api/admin/leaderboard?type=week|all` — 排行榜
- `GET  /api/admin/stats` — 管理员统计

统一响应包络：
```json
{ "success": true,  "data": { ... } }
{ "success": false, "message": "错误说明" }
```

## ⚠️ 安全说明

**`/api/admin/**` 当前没有任何鉴权**。生产环境**必须**在 `AdminController` 加鉴权，可选方案：
- HTTP Basic Auth（最简单）
- 单独的 admin JWT（`/api/auth/admin-login` 返回带 `role: admin` 的 token）
- 内网白名单（`SecurityConfig` 里按 IP 放行 `/api/admin/**`）

> 相关的 issue / PR 跟踪中。

## 配置项

> **集中在一个文件**：`server/src/main/resources/application-config.yml`
>
> 那个文件里有所有可改项的默认值、生产提醒、环境变量名、以及怎么生成强密码。上线只需要改那个文件（或者用环境变量覆盖）。
>
> 其他 yml（`application.yml` / `application-{profile}.yml`）只放"项目固定"和"profile 间的硬差异"，一般不需要动。

### 快速开始

```bash
cd server/src/main/resources
$EDITOR application-config.yml      # 改完后：prod 上线 / dev 本地
```

或用环境变量覆盖（容器推荐）：

```bash
export DB_URL='jdbc:mariadb://your-db:3306/flight_attendance'
export DB_USER='flight'
export DB_PASSWORD='strong-password-here'
export JWT_SECRET=$(openssl rand -hex 32)
java -jar target/flight-attendance-server.jar --spring.profiles.active=prod
```

### Profile 选哪个

| Profile | 什么时候用 | DB | Flyway |
|---|---|---|---|
| `dev` (默认) | 本地开发 | 本地 MariaDB（docker-compose.yml 一键起） | ✅ |
| `prod` | 生产部署 | 外部 MariaDB（必须用环境变量配） | ✅ |
| `test` | 集成测试 | H2 内存 | ❌（自动建表） |
| `h2` | 本机没装 MariaDB 的备胎 | H2 文件（重启保留） | ❌（自动建表） |

application-prod.yml 里 ddl-auto: validate 是生产最安全的设置（不改 schema，只校验）。如果你以后改字段名/类型，记得：

    写新的 Flyway 迁移（V4__xxx.sql）改 DB
    同步改实体
    启动时 validate 会先跑迁移再校验新实体，不会炸


## 构建 / CI

### 本地构建

```bash
# 后端
cd server
mvn -DskipTests package
# 产物：target/flight-attendance-server.jar （fat jar，约 55MB）

# 前端 APK —— 见 app/README
```

### Docker

```bash
cd server
docker build -t flight-attendance-server .
docker run --rm -p 8080:8080 \
  -e DB_URL=jdbc:mariadb://host.docker.internal:3306/flight_attendance \
  -e DB_USER=flight -e DB_PASSWORD=flight \
  -e JWT_SECRET=$(openssl rand -hex 32) \
  flight-attendance-server
```

### GitHub Actions

`.github/workflows/build.yml` 会：

1. **Server job**：Maven 跑 `verify` + `package`，上传 `server-jar` artifact
2. **App job**（依赖 server 成功）：Flutter `analyze` + `test` + `build apk --release`，上传 `app-release` + `app-mapping` artifacts

触发条件：push 到 `master`/`main`、打 `v*` tag、PR、手动触发。

## 部署建议

- **数据库**：阿里云 RDS for MariaDB、腾讯云 TencentDB for MariaDB、自建都行
- **后端**：直接 `java -jar` 或用项目里的 `Dockerfile` 打镜像
- **App**：通过 GitHub Actions 拿 `app-release` artifact 分发（TestFlight / 蒲公英 / 直接 adb install）

## License

GPL-3.0
