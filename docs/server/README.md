# Barcelona Server Overview (Draft)

This document will outline the infrastructure that replaces the old proxy stack.

## Sections to include

1. **Architecture diagram** – DigitalOcean droplet, managed DB (if any), backups, monitoring.
2. **Provisioning steps** – scripts or Terraform commands, required credentials, SSH key handling.
3. **Deployment pipeline** – how code moves from GitHub to the droplet (CI job, manual SSH, etc.).
4. **Runtime configuration** – environment variables, secrets management, RSA key rotation.
5. **Operational tasks** – patching cadence, log inspection, alerts.

Populate each section once the backend decisions are finalized.
