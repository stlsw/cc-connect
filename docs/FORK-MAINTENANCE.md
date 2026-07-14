# Maintaining the stlsw/cc-connect fork

Fork: https://github.com/stlsw/cc-connect  
Upstream: https://github.com/chenhg5/cc-connect

## Branch layout

| Branch | Role |
|--------|------|
| `main` | Mirror of upstream (optional; update with fetch/merge) |
| `patch/quiet-acp` | **Our maintained branch** — upstream + quiet/ACP patches |

## Patches we keep

1. **ACP thinking** (`agent/acp/mapping.go`)  
   Map `agent_thought_chunk` (Grok) to thinking so `thinking_messages = false` works.

2. **Quiet spacing** (`core/engine.go`)  
   One separator per text segment in quiet mode (no stacked `\n\n` on every tool).

## Install / update this machine

```bash
git clone https://github.com/stlsw/cc-connect.git
cd cc-connect
git checkout patch/quiet-acp
./scripts/install-local.sh
```

Installs to `~/.cc-connect/bin/cc-connect` and restarts the LaunchAgent.

## Automation (GitHub Actions)

Workflow: [`.github/workflows/sync-upstream.yml`](../.github/workflows/sync-upstream.yml)

| Trigger | What it does |
|---------|----------------|
| **Daily 08:00 UTC** | Rebase `patch/quiet-acp` onto `upstream/main`, push; also point fork `main` at upstream |
| **Actions → Sync upstream → Run workflow** | Same, optional strategy `rebase` / `merge` |

On **conflict**, the job fails and opens a GitHub Issue titled `Upstream sync conflict…` with fix steps.

**Important:** Scheduled workflows only run from the repo **default branch**. This fork should use `patch/quiet-acp` as default (set once in GitHub settings or `gh repo edit --default-branch patch/quiet-acp`).

**This machine still needs a rebuild** after a successful sync if you want the new upstream code on the daemon:

```bash
cd /path/to/stlsw/cc-connect
git pull origin patch/quiet-acp
./scripts/install-local.sh
```

(Optional later: a self-hosted runner or SSH deploy action could run `install-local.sh` automatically.)

## Pull new upstream releases (manual)

```bash
git checkout patch/quiet-acp
git fetch upstream
# Prefer rebase so our 1–2 commits stay on top of latest main:
git rebase upstream/main
# fix conflicts if any, then:
git push --force-with-lease origin patch/quiet-acp
./scripts/install-local.sh
```

Or cherry-pick our commits onto a release tag:

```bash
git fetch upstream --tags
git checkout -B patch/quiet-acp-v1.4.1 upstream/v1.4.1
git cherry-pick 21d269d   # or the commit hash of the quiet patch
./scripts/install-local.sh
```

## Do not rely on npm for the daemon

`npm install -g cc-connect` installs **stock** upstream and can overwrite  
`node_modules/.../bin/cc-connect`. This fork’s daemon should always run from:

```text
~/.cc-connect/bin/cc-connect
```

Check:

```bash
~/.cc-connect/bin/cc-connect --version
# expect: v1.3.4-quiet (or similar custom tag)
launchctl list | grep cc-connect
```
