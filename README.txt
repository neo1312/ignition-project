===============================================================
  IGNITION 8.3 + DOCKER + POSTGRESQL + GIT — QUICK INSTALL
===============================================================

PREREQUISITES (once per machine)
----------------------------------
sudo apt update
sudo apt install -y docker.io docker-compose-plugin git
sudo usermod -aG docker $USER
newgrp docker

git config --global user.name "Your Name"
git config --global user.email "you@example.com"


===============================================================
STEP 1 — CLONE THE REPO
===============================================================
git clone https://github.com/YOURUSER/YOURREPO.git
cd YOURREPO
git checkout develop


===============================================================
STEP 2 — CREATE .env.prod MANUALLY (never in git)
===============================================================
cp .env.dev .env.prod
nano .env.prod
  → Change POSTGRES_PASSWORD to a strong password
  → Change GATEWAY_ADMIN_PASSWORD to a strong password
  → Change POSTGRES_DB to ignition_prod
  → Change POSTGRES_USER to ignition_prod


===============================================================
STEP 3 — FIX FOLDER OWNERSHIP (CRITICAL — do this every time)
===============================================================

# First boot the container briefly to find the real uid
docker compose -f compose/docker-compose.dev.yml --env-file .env.dev up -d
docker exec -it ignition-dev id
  → Look for uid=XXXX — note that number (for Ignition 8.3 it is 2003)
docker compose -f compose/docker-compose.dev.yml --env-file .env.dev down

# Pre-create the folder Ignition needs
sudo mkdir -p ignition/data/projects/.resources

# Set correct ownership using the real uid (2003 for Ignition 8.3)
sudo chown -R 2003:2003 ignition/
sudo chmod -R 775 ignition/

# Add your Linux user to that group so you can write too
sudo usermod -aG 2003 $USER
newgrp 2003

# Verify — every line must show 2003 2003
ls -lan ignition/
ls -lan ignition/data/
ls -lan ignition/data/projects/
ls -lan ignition/data/modules/
ls -lan ignition/conf/


===============================================================
STEP 4 — BOOT THE DEV STACK
===============================================================
docker compose -f compose/docker-compose.dev.yml --env-file .env.dev up -d


===============================================================
STEP 5 — WATCH LOGS UNTIL READY
===============================================================
docker logs ignition-dev -f

  → Wait for: "Commissioning State updated ... needs_commissioning"
  → Then open: http://localhost:8088


===============================================================
STEP 6 — COMMISSIONING WIZARD (browser)
===============================================================
1. Accept EULA
2. Select Trial edition
3. Gateway name: ignition-dev
4. Skip redundancy (Standalone)
5. Admin username: admin
6. Admin password: password  (from .env.dev)
7. Click Finish — gateway restarts, takes ~30 seconds
8. Log in at http://localhost:8088


===============================================================
STEP 7 — VERIFY POSTGRESQL
===============================================================
docker exec postgres-dev psql -U ignition_dev -d ignition_dev -c "\dt"

  → Should show 3 tables:
     alarm_journal
     audit_log
     tag_history


===============================================================
DAILY COMMANDS
===============================================================

Start dev:
  docker compose -f compose/docker-compose.dev.yml --env-file .env.dev up -d

Stop dev:
  docker compose -f compose/docker-compose.dev.yml --env-file .env.dev down

Check status:
  docker compose -f compose/docker-compose.dev.yml --env-file .env.dev ps

Restart only Ignition (after project changes):
  docker compose -f compose/docker-compose.dev.yml --env-file .env.dev restart ignition

Check Ignition logs:
  docker logs ignition-dev --tail 50

Check PostgreSQL logs:
  docker logs postgres-dev --tail 20


===============================================================
GIT VERSION CONTROL FLOW
===============================================================

Start a new feature:
  git checkout develop
  git pull origin develop
  git checkout -b feature/your-feature-name
  git commit --allow-empty -m "chore: init feature branch"
  git push -u origin feature/your-feature-name

Save work after Designer changes:
  git add ignition/data/projects/
  git commit -m "feat: describe what you changed"
  git push origin feature/your-feature-name

Merge to develop (via GitHub Pull Request):
  → Open PR on GitHub: feature/xxx → develop
  → Review diff, merge

Promote to production:
  git checkout main
  git merge develop
  git tag -a v1.0.0 -m "Release description"
  git push origin main --tags

Pull on prod server:
  ssh user@prod-server
  cd /opt/ignition-project
  git pull origin main
  docker compose -f compose/docker-compose.prod.yml \
    --env-file .env.prod \
    up -d --no-deps ignition


===============================================================
IMPORTANT REMINDERS
===============================================================

[!] Never commit .env.prod — always create it manually on each machine
[!] Ignition 8.3 runs as uid 2003 inside the container — not 999
[!] If you wipe volumes (down -v), redo Step 3 before booting again
[!] projects/.resources/ is a runtime folder — it is in .gitignore
[+] Designer saves go directly to ignition/data/projects/ via bind mount
[+] Run: git add . && git commit to version control your Designer work


===============================================================
TROUBLESHOOTING
===============================================================

Gateway fails with "unable to create resource dir":
  → You forgot Step 3 or used the wrong uid
  → docker compose down, redo chown with correct uid, restart

Gateway fails to start after commissioning:
  → Check: docker logs ignition-dev --tail 50
  → Trial license may have expired — restart container to reset

PostgreSQL tables missing:
  → Init script only runs on empty volume
  → If volume existed before: docker compose down -v, restart
  → WARNING: down -v deletes all data — backup first on prod

Cannot write to ignition/ folders from terminal:
  → Your user is not in group 2003
  → Run: sudo usermod -aG 2003 $USER && newgrp 2003

===============================================================
