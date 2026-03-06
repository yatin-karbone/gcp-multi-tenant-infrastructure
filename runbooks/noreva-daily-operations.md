# Noreva Hub — Daily Operations Runbook

**Environment**: Production
**Project**: `noreva-prod-apps-67ca`
**VM**: `noreva-prod-vm` (us-east4-a, e2-standard-2, 100GB disk)
**Last Updated**: March 2026

---

## Overview

This runbook covers the daily morning health check for the Noreva Hub application. The goal is to identify and triage any issues before 8 AM so there is time to repair before business hours.

Checks cover:
- Application uptime and reachability
- Docker container health
- SSL certificate status
- Log-based error triage
- Escalation procedures

---

## 1. Uptime Checks & Alerting Policy

### GCP Uptime Checks
GCP Uptime Checks ping endpoints from multiple global locations every minute. Alerts fire if the endpoint fails for more than the configured threshold.

| Check | Endpoint | Protocol | Purpose |
|-------|----------|----------|---------|
| Noreva Hub | `https://norevahub.ai` | HTTPS/443 | End-to-end check — Nginx, Certbot, Django all must be healthy |
| API Gateway | TBD | HTTPS | To be configured once API Gateway URL is confirmed |

> **Note**: The Hub uptime check validates the full stack — if Nginx is down, SSL is expired, or Django is not responding, the check will fail.

**To enable the uptime check** (currently disabled in Terraform):
```hcl
# infra/noreva/prod/terraform.tfvars
create_uptime_check = true
```
Then run `terraform apply` from `infra/noreva/prod/`.

### Active Alerting Policies
Configured in `noreva-prod-apps-67ca` Cloud Monitoring:

| Policy | Threshold | Notification |
|--------|-----------|-------------|
| `noreva-prod-disk-usage-high` | Disk > 70% for 5 mins | `alerts@noreva.ai` |
| `noreva-prod-application-errors` | ERROR/EXCEPTION/TRACEBACK in logs | `alerts@noreva.ai` (max 1 per 5 mins) |

> **During pentest engagements**: Disable `noreva-prod-application-errors` to avoid alert fatigue from intentional attack traffic. Re-enable when pentest is complete:
> ```hcl
> enable_error_alerts = false  # infra/noreva/prod/main.tf
> ```

---

## 2. Morning Health Check (Daily, before 8 AM)

### Step 1 — Check Automated Alerts
Check `alerts@noreva.ai` inbox for overnight alerts:

| Alert received | Action |
|---------------|--------|
| Disk usage > 70% | See [Disk Pressure Response](#disk-pressure-response) |
| Application errors | Open Log Explorer, filter by error — see [Log Triage](#log-triage) |
| Uptime check failure | See [Uptime Failure Response](#uptime-failure-response) |
| No alerts | Proceed to manual checks |

---

### Step 2 — Verify Container Health

SSH into the prod VM:
```bash
gcloud compute ssh noreva-prod-vm --project=noreva-prod-apps-67ca --zone=us-east4-a --tunnel-through-iap
```

Check all containers are running and uptime is healthy:
```bash
# Show all container names, status and how long they've been running
docker compose -f /srv/project/docker-compose.yml ps
```

Expected: all 9 containers showing `Up` with consistent uptime. Investigate any container showing `Restarting`, `Exited`, or uptime shorter than expected.

| Container | Role |
|-----------|------|
| `noreva-nginx-1` | Reverse proxy, SSL termination |
| `noreva-django-1` | Main application |
| `noreva-celery-1` | Async task worker |
| `noreva-celery-beat-1` | Task scheduler |
| `noreva-postgres-1` | Database |
| `noreva-redis-1` | Cache and task queue |
| `noreva-imgproxy-1` | Image processing |
| `noreva-certbot-1` | SSL certificate renewal |
| `noreva-portainer-1` | Container management UI |

If a container has restarted unexpectedly, check its recent logs:
```bash
# Replace <container_name> with the affected container
docker logs --tail 50 <container_name>
```

---

### Step 3 — Check SSL Certificate

Certbot runs as a container and renews certificates automatically. Verify it is not approaching expiry:
```bash
# Dry-run renewal check — confirms cert is valid and renewal would succeed
docker exec noreva-certbot-1 certbot renew --dry-run
```

Expected output: `No renewals were attempted` or `Congratulations, all renewals succeeded`.

If renewal fails, check certbot logs:
```bash
docker logs --tail 50 noreva-certbot-1
```

> **Note**: Certbot renews certificates when they are within 30 days of expiry. A dry-run failure is a warning — the cert has not yet expired but will if the issue is not resolved.

---

### Step 4 — Check Disk Usage
```bash
# Overall disk usage
df -h /

# Docker-specific usage breakdown — images, containers, volumes
docker system df
```

Alert if `/dev/root` is above 70%. See [Disk Pressure Response](#disk-pressure-response).

---

### Step 5 — Log Triage

#### Via GCP Log Explorer
Navigate to **GCP Console → Logging → Log Explorer** in project `noreva-prod-apps-67ca`.

**All Docker container errors:**
```
resource.type="gce_instance"
logName="projects/noreva-prod-apps-67ca/logs/docker_containers"
severity>=ERROR
```

**Per-service filters** (add to base query):

| Service | Filter |
|---------|--------|
| Django | `labels."agent.googleapis.com/log_file_path"=~"4a4520ec8c43"` |
| Postgres | `labels."agent.googleapis.com/log_file_path"=~"abdba7a181c2"` |
| Nginx | `labels."agent.googleapis.com/log_file_path"=~"c46bb8ea7cfa"` |
| Celery | `labels."agent.googleapis.com/log_file_path"=~"7e1bc840993d"` |
| Celery Beat | `labels."agent.googleapis.com/log_file_path"=~"0728f5c8bb27"` |
| Redis | `labels."agent.googleapis.com/log_file_path"=~"839744fcbf1e"` |
| imgproxy | `labels."agent.googleapis.com/log_file_path"=~"e5e99d23b85b"` |

> **Note**: Container IDs change after every `docker compose down && up`. Re-run `docker ps --format '{{.Names}}\t{{.ID}}'` and update this table after any full stack restart.

---

### Step 6 — Functional Checks *(to be defined with team)*

The following functional checks should be completed before 8 AM to ensure data integrity:

| Check | Expected Result | Action if Failed |
|-------|----------------|-----------------|
| TBD — e.g. "Verify price data is up-to-date" | TBD | TBD |
| TBD — e.g. "Confirm forecasts are loaded" | TBD | TBD |
| TBD — e.g. "API Gateway returning data" | TBD | TBD |

> These checks require input from the Noreva team to define acceptance criteria.

---

## 3. Service Health Dashboard

A custom dashboard in GCP Monitoring displays the following tiles for `noreva-prod-apps-67ca`:

| Tile | Metric | Alert Threshold |
|------|--------|----------------|
| VM CPU Utilization | `compute.googleapis.com/instance/cpu/utilization` | > 80% for 15 mins |
| API Gateway Traffic | `serviceruntime.googleapis.com/api/request_count` | 0 requests (flatline) — TBD once API Gateway is configured |
| Application Error Rate | `logging.googleapis.com/log_entry_count` filtered by ERROR | > 5% of total traffic |
| Disk Usage | `agent.googleapis.com/disk/percent_used` | > 70% |

> **Dashboard setup**: TBD — to be created in GCP Console → Monitoring → Dashboards once API Gateway is configured.

---

## 4. Daily Status Email *(Backlog)*

A Cloud Scheduler + Cloud Function setup to send a daily 8 AM summary email to `alerts@noreva.ai`:

```
Noreva Hub Daily Summary — 2026-03-06
Uptime (last 24h): 99.9%
Errors: 3
Requests: 1,204
Disk usage: 13%
All containers: healthy
```

**Status**: Not yet implemented. Requires:
- Cloud Function (Python) querying Cloud Monitoring API
- Cloud Scheduler trigger at 8 AM daily
- SendGrid or GCP email integration

---

## 5. Incident Response Procedures

### Disk Pressure Response
```bash
# Check what's consuming disk
docker system df
sudo du -sh /var/lib/docker/*

# Remove stopped containers and dangling images (safe)
docker container prune -f
docker image prune -f --filter "until=168h"

# If still critical, check log file sizes
docker ps -q | xargs -I {} sh -c 'echo "=== {} ===" && \
  docker inspect --format="{{.LogPath}}" {} | xargs sudo ls -lh'
```

> Do NOT run `docker system prune --volumes` on prod — this will delete database volumes.

---

### Uptime Failure Response
```bash
# 1. Check if nginx is running
docker ps | grep nginx

# 2. Check nginx logs
docker logs --tail 50 noreva-nginx-1

# 3. Check if django is responding internally
docker exec noreva-nginx-1 curl -s -o /dev/null -w "%{http_code}" http://django:8000/

# 4. Restart nginx if hung (does not affect other containers)
docker compose -f /srv/project/docker-compose.yml restart nginx

# 5. If SSL error, check certbot
docker exec noreva-certbot-1 certbot renew --dry-run
```

---

### Container Restart Procedure
To restart a single container without affecting the rest of the stack:
```bash
docker compose -f /srv/project/docker-compose.yml restart <service_name>
```

To restart the full stack (causes downtime):
```bash
cd /srv/project
docker compose down && docker compose up -d
```

> After a full stack restart, container IDs change. Update Log Explorer saved filters using:
> ```bash
> docker ps --format '{{.Names}}\t{{.ID}}'
> ```

---

### Application Deployment (Manual)
Pull and deploy the latest images from GHCR:
```bash
cd /srv/project

# Pull latest images
docker compose pull

# Recreate containers with new images (brief downtime per container)
docker compose up -d

# Verify all containers came up healthy
docker compose ps
```

To roll back to a previous image:
```bash
# Edit docker-compose.yml to pin a specific image tag
# e.g. change django:main to django@sha256:<digest>
docker compose up -d django
```

---

## 6. Escalation Matrix

| Tier | Condition | Contact | Response Time |
|------|-----------|---------|--------------|
| Tier 1 — Internal | Any alert. Initial triage, container restart if hung | [ADD CONTACT] | 10–20 mins |
| Tier 2 — Alex Wissa | VM healthy but application returning 500 errors | [ADD CONTACT] | [ADD SLA] |
| Tier 3 — GCP Support | GCP service outage (not VM/application related) | [GCP Support case] | Per support tier |
| Business Escalation | Outage, data not loaded, prices unavailable | [ADD CONTACTS] | Immediate |

**Escalate to business when:**
- Application is completely unreachable (uptime check failing > 15 mins)
- Price data or forecasts have not loaded by the expected time
- Data integrity issues suspected

---

## 7. Reference

### Key Links
| Resource | URL |
|----------|-----|
| GCP Console | `console.cloud.google.com/home/dashboard?project=noreva-prod-apps-67ca` |
| Log Explorer | `console.cloud.google.com/logs/query?project=noreva-prod-apps-67ca` |
| Cloud Monitoring | `console.cloud.google.com/monitoring?project=noreva-prod-apps-67ca` |
| Alerting Policies | `console.cloud.google.com/monitoring/alerting?project=noreva-prod-apps-67ca` |
| Log Archive Bucket | `gs://noreva-prod-apps-67ca-log-archive` |
| Terraform State | `gs://noreva-prod-terraform-state/noreva/prod` |

### Connect to VM
```bash
gcloud compute ssh noreva-prod-vm --project=noreva-prod-apps-67ca --zone=us-east4-a --tunnel-through-iap
```

### Useful Commands Quick Reference
```bash
# Container status
docker compose -f /srv/project/docker-compose.yml ps

# Tail logs for a specific container
docker logs --tail 50 -f <container_name>

# Disk usage
df -h / && docker system df

# SSL check
docker exec noreva-certbot-1 certbot renew --dry-run

# Container ID to service mapping
docker ps --format '{{.Names}}\t{{.ID}}'

# Restart a single service
docker compose -f /srv/project/docker-compose.yml restart <service_name>
```
