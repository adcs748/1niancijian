# 一念词间 · 备份服务

客户授权后，把 App 中选择/授权的照片与文件备份到**你自己的服务器**，并可在管理台查看、下载与追回。

## 部署

需要 Node.js 18+。

```bash
cd backup-server
npm install
TOKEN="请设置一个高强度令牌" PORT=8787 DATA_DIR="./data" npm start
```

- `PORT`：监听端口，默认 8787。
- `TOKEN`：访问令牌，App 与管理台都需要填写；**必须修改**。
- `DATA_DIR`：备份数据目录，默认 `./data`。

建议在 Nginx/Caddy 等反向代理后面启用 **HTTPS**，并把服务放在内网或受控网络。

## 接口

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/api/backups/:batchId/files` | 上传单个文件（multipart 字段名 `file`） |
| GET | `/api/backups` | 批次列表（文件数、总大小、更新时间） |
| GET | `/api/backups/:batchId` | 批次文件清单 |
| GET | `/api/backups/:batchId/files/:name` | 下载文件 |

所有接口都需要请求头：

```
Authorization: Bearer <TOKEN>
```

## 客户端配置

- App：首页「安全备份」→ 填写服务器地址（如 `https://backup.example.com`）与同一 Token。
- 管理台：直接打开 `web-preview/backup-console.html`（或部署到服务器），填写地址与 Token 后刷新。

## 数据追回

备份文件按批次保存在：

```
data/<batchId>/<文件名>
data/<batchId>/manifest.json
```

客户需要追回时，按批次 ID 直接取目录，或用管理台下载。

## 隐私边界

- 只接收客户端**主动上传**的文件；
- 不扫描、不抓取客户端其他数据；
- 请妥善保管 Token 与数据目录，建议加密磁盘与访问审计；
- iOS App 受系统沙盒限制，只能读取用户授权的照片/视频库与用户通过文件选择器选中的文件，无法读取其他 App 或系统文件。