# certbot-dns-all

`certbot-dns-all` 是一个基于 Docker 的 Certbot 镜像，集成了以下 DNS 插件，可统一完成证书签发与续期（含通配符证书）：

- AliDNS（`certbot-dns-alicloud`）
- DNSPod（`certbot-dns-dnspod`）
- Cloudflare（`certbot-dns-cloudflare`）

## 目录结构

```text
certbot-dns-all/
├── Dockerfile
├── credentials/
│   ├── alicloud.ini
│   ├── dnspod.ini
│   └── cloudflare.ini
└── letsencrypt/
```

## 镜像内容

当前 `Dockerfile` 基于 `certbot/certbot`，并安装了：

- `zope.interface`
- `certbot-dns-alicloud`
- `certbot-dns-dnspod`
- `certbot-dns-cloudflare`

## 凭据文件准备

请在 `credentials/` 下配置对应平台凭据（示例键名如下）：

```ini
# credentials/alicloud.ini
dns_alicloud_access_key = xxx
dns_alicloud_secret_key = xxx
dns_alicloud_region = cn-hangzhou
```

```ini
# credentials/dnspod.ini
dns_dnspod_token = ID,Token
```

```ini
# credentials/cloudflare.ini
dns_cloudflare_api_token = your_api_token
```

建议设置最小权限：

```bash
chmod 600 /opt/certbot-dns-all/credentials/*.ini
```

## 构建 certbot-dns-all 镜像

### 推荐（本仓库实际路径）

```bash
cd /opt/certbot-dns-all
docker build -t certbot-dns-all .
```

## 🚀 签发通配符证书（AliDNS）

```bash
docker run --rm \
  -v /opt/certbot-dns-all/letsencrypt:/etc/letsencrypt \
  -v /opt/certbot-dns-all/credentials:/credentials:ro \
  certbot-dns-all certonly \
  -a dns-alicloud \
  --dns-alicloud-credentials /credentials/alicloud.ini \
  -d "*.example.com" -d "example.com" \
  --email admin@example.com \
  --agree-tos \
  --non-interactive
```

## 🚀 签发通配符证书（DNSPod）

```bash
docker run --rm \
  -v /opt/certbot-dns-all/letsencrypt:/etc/letsencrypt \
  -v /opt/certbot-dns-all/credentials:/credentials:ro \
  certbot-dns-all certonly \
  -a dns-dnspod \
  --dns-dnspod-credentials /credentials/dnspod.ini \
  -d "*.example.com" -d "example.com" \
  --email admin@example.com \
  --agree-tos \
  --non-interactive
```

## 🚀 签发通配符证书（Cloudflare）

```bash
docker run --rm \
  -v /opt/certbot-dns-all/letsencrypt:/etc/letsencrypt \
  -v /opt/certbot-dns-all/credentials:/credentials:ro \
  certbot-dns-all certonly \
  -a dns-cloudflare \
  --dns-cloudflare-credentials /credentials/cloudflare.ini \
  -d "*.mysite.com" -d "mysite.com" \
  --email admin@example.com \
  --agree-tos \
  --non-interactive
```

## 🔁 续期所有证书（全部平台）

```bash
docker run --rm \
  -v /opt/certbot-dns-all/letsencrypt:/etc/letsencrypt \
  -v /opt/certbot-dns-all/credentials:/credentials:ro \
  certbot-dns-all renew
```

可先做续期演练：

```bash
docker run --rm \
  -v /opt/certbot-dns-all/letsencrypt:/etc/letsencrypt \
  -v /opt/certbot-dns-all/credentials:/credentials:ro \
  certbot-dns-all renew --dry-run
```

## 🔁 续期后热重载 Nginx（零停机）

```bash
docker run --rm \
  -v /opt/certbot-dns-all/letsencrypt:/etc/letsencrypt \
  -v /opt/certbot-dns-all/credentials:/credentials:ro \
  certbot-dns-all renew \
  && docker exec nginx nginx -s reload
```

## ⏰ 生产环境 Cron（推荐）

编辑计划任务：

```bash
crontab -e
```

添加（建议使用以下格式，避免 PATH 与 shell 差异）：

```cron
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 3 * * * docker run --rm -v /opt/certbot-dns-all/letsencrypt:/etc/letsencrypt -v /opt/certbot-dns-all/credentials:/credentials:ro certbot-dns-all renew && docker exec nginx nginx -s reload
```

表示每天凌晨 3 点执行续期并重载 Nginx。

## 📌 证书位置（供 Nginx 使用）

签发完成后，证书默认位于：

```text
/opt/certbot-dns-all/letsencrypt/live/example.com/
```

如果在 Nginx 容器中将宿主机路径挂载为 `/etc/letsencrypt`，可使用：

```nginx
ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
```
