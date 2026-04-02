
├─ README.md
├─ docs/
│  ├─ linux/
│  │  ├─ common-commands.md
│  │  ├─ networking.md
│  │  ├─ processes-and-services.md
│  │  ├─ disks-and-filesystems.md
│  │  ├─ users-and-permissions.md
│  │  └─ troubleshooting.md
│  ├─ deployment/
│  │  ├─ ubuntu-server-setup.md
│  │  ├─ reverse-proxy-nginx.md
│  │  ├─ ssl-certbot.md
│  │  ├─ systemd-services.md
│  │  └─ docker-deployment.md
│  ├─ terraform/
│  │  ├─ concepts.md
│  │  ├─ state-management.md
│  │  └─ workflow.md
│  ├─ ansible/
│  │  ├─ concepts.md
│  │  ├─ inventory.md
│  │  └─ roles.md
│  ├─ kubernetes/
│  │  ├─ basics.md
│  │  ├─ kubectl-cheatsheet.md
│  │  ├─ deployments-services-ingress.md
│  │  └─ troubleshooting.md
│  └─ cheat-sheets/
│     ├─ git.md
│     ├─ docker.md
│     ├─ ssh.md
│     └─ sql-backup-restore.md
│
├─ scripts/
│  ├─ linux/
│  │  ├─ cleanup.sh
│  │  ├─ disk-usage-report.sh
│  │  ├─ find-large-files.sh
│  │  ├─ process-monitor.sh
│  │  └─ system-info.sh
│  ├─ ubuntu/
│  │  ├─ init-server.sh
│  │  ├─ setup-user.sh
│  │  ├─ install-docker.sh
│  │  ├─ install-nginx.sh
│  │  ├─ configure-firewall.sh
│  │  └─ deploy-app.sh
│  ├─ docker/
│  │  ├─ build-and-push.sh
│  │  ├─ clean-dangling-images.sh
│  │  └─ exec-into-container.sh
│  ├─ backup/
│  │  ├─ postgres-backup.sh
│  │  ├─ sqlserver-backup.sh
│  │  └─ restore-example.sh
│  ├─ network/
│  │  ├─ port-check.sh
│  │  ├─ dns-debug.sh
│  │  └─ curl-healthcheck.sh
│  └─ helpers/
│     ├─ common.sh
│     └─ log.sh
│
├─ deployments/
│  ├─ ubuntu-single-vm/
│  │  ├─ README.md
│  │  ├─ app/
│  │  │  ├─ docker-compose.yml
│  │  │  ├─ .env.example
│  │  │  └─ nginx.conf
│  │  ├─ systemd/
│  │  │  └─ myapp.service
│  │  └─ scripts/
│  │     ├─ provision.sh
│  │     └─ deploy.sh
│  ├─ docker-vps/
│  │  ├─ README.md
│  │  ├─ compose/
│  │  └─ scripts/
│  └─ k8s-homelab/
│     ├─ README.md
│     └─ manifests/
│
├─ terraform/
│  ├─ modules/
│  │  ├─ network/
│  │  ├─ linux-vm/
│  │  ├─ storage/
│  │  └─ monitoring/
│  ├─ environments/
│  │  ├─ dev/
│  │  ├─ stage/
│  │  └─ prod/
│  ├─ examples/
│  │  ├─ azure-vm/
│  │  └─ aws-basic-vpc/
│  └─ README.md
│
├─ ansible/
│  ├─ inventories/
│  │  ├─ dev/
│  │  │  ├─ hosts.ini
│  │  │  └─ group_vars/
│  │  ├─ stage/
│  │  └─ prod/
│  ├─ playbooks/
│  │  ├─ bootstrap-server.yml
│  │  ├─ install-docker.yml
│  │  ├─ deploy-app.yml
│  │  └─ harden-ssh.yml
│  ├─ roles/
│  │  ├─ common/
│  │  ├─ docker/
│  │  ├─ nginx/
│  │  ├─ node_exporter/
│  │  └─ app_deploy/
│  ├─ templates/
│  └─ README.md
│
├─ kubernetes/
│  ├─ base/
│  │  ├─ namespace.yaml
│  │  ├─ deployment.yaml
│  │  ├─ service.yaml
│  │  └─ ingress.yaml
│  ├─ overlays/
│  │  ├─ dev/
│  │  ├─ stage/
│  │  └─ prod/
│  ├─ helm/
│  │  └─ myapp/
│  ├─ monitoring/
│  └─ README.md
│
├─ cicd/
│  ├─ github-actions/
│  │  ├─ ci.yml
│  │  ├─ docker-build.yml
│  │  └─ terraform-plan.yml
│  └─ azure-devops/
│     ├─ build.yml
│     └─ deploy.yml
│
├─ monitoring/
│  ├─ prometheus/
│  ├─ grafana/
│  ├─ loki/
│  └─ alerts/
│
├─ templates/
│  ├─ env/
│  │  ├─ app.env.example
│  │  └─ terraform.tfvars.example
│  ├─ systemd/
│  ├─ nginx/
│  └─ docker/
│
├─ .github/
│  ├─ workflows/
│  ├─ pull_request_template.md
│  └─ ISSUE_TEMPLATE/
│
├─ Makefile
├─ .editorconfig
├─ .gitignore
└─ LICENSE