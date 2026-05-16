# CodeBridge Bridge Agent — Runbook

Personal ops note for the CodeBridge bridge agent that runs on this Mac.
Lives in this repo because it's where the author keeps Mac-side ops notes.

> All secrets (`BRIDGE_SECRET`, `JWT_SECRET`, `DEEPGRAM_API_KEY`, VAPID keys)
> live exclusively in `.env` files on disk (mode `600`) — never commit them.
> Source code repo: <https://github.com/pepperonas/code-bridge>.

## Locations

| Thing | Path |
|---|---|
| Source checkout | `/Users/martin/claude/code-bridge` |
| Bridge agent | `/Users/martin/claude/code-bridge/bridge-agent` |
| Bridge venv | `/Users/martin/claude/code-bridge/bridge-agent/venv` |
| Bridge `.env` (secrets) | `/Users/martin/claude/code-bridge/bridge-agent/.env` |
| Session JSONLs | `~/.claude/projects/<encoded-path>/<uuid>.jsonl` |
| Session metadata | `~/.codebridge/session_meta.json` |
| Shell aliases | `~/.claude/aliases/aliases.zsh` |
| PM2 dump | `~/.pm2/dump.pm2` |

## PM2 process

Process name: `codebridge-bridge` (registered once, then named-referenceable).

### First-time registration

Run from a **clean shell**, not from inside Claude Code, otherwise the
`CLAUDECODE` env var leaks into the subprocess and causes silent hangs.

```bash
cd /Users/martin/claude/code-bridge/bridge-agent
pm2 start venv/bin/python --name codebridge-bridge -- -m bridge_agent
pm2 save              # persist to ~/.pm2/dump.pm2 (survives reboot)
```

### Daily operations (aliases)

Defined in `~/.claude/aliases/aliases.zsh` — only work after the initial
registration above. They reference the PM2 process by name.

```bash
cb-start              # alias for: pm2 start codebridge-bridge
cb-stop               # alias for: pm2 stop codebridge-bridge
codebridge            # alias for: pm2 start codebridge-bridge  (kept as legacy)
```

Useful PM2 commands:

```bash
pm2 ls                                  # list registered processes
pm2 describe codebridge-bridge          # full config (cwd, script path)
pm2 logs codebridge-bridge --lines 50   # tail recent logs
pm2 restart codebridge-bridge           # restart after code changes
pm2 delete codebridge-bridge            # de-register (requires re-registration after)
```

### Restart after pulling changes

The bridge imports Python modules from `bridge-agent/bridge_agent/` at start
time. Pulling new code requires a process restart:

```bash
cd /Users/martin/claude/code-bridge && git pull
pm2 restart codebridge-bridge
pm2 logs codebridge-bridge --lines 30   # verify clean startup
```

## VPS side (briefly)

The bridge connects to a FastAPI backend on the VPS over WSS. Both must be
restarted in sync after a backend code change.

| Thing | Identifier |
|---|---|
| SSH alias | `celox` |
| Backend path | `/opt/codebridge/backend/` |
| Systemd unit | `codebridge-backend` |
| Service user | `codebridge` |
| Frontend root | `/var/www/codebridge/` |
| Health check | `https://<host>/api/health` → `{"status":"ok"}` |

Deploy script (from this Mac):

```bash
cd /Users/martin/claude/code-bridge
./deploy/deploy-vps.sh
# builds frontend, rsyncs both, restarts systemd, reloads nginx
```

After a deploy:

```bash
ssh celox 'systemctl status codebridge-backend --no-pager | head -10'
curl -fsS https://<host>/api/health
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `cb-start` says "process not found" | First-time registration was never done, or `pm2 delete` was used | Re-register (see above) |
| Bridge hangs on startup, no output | `CLAUDECODE` env leaked from Claude Code shell | `pm2 delete codebridge-bridge`, then re-register from a fresh terminal |
| `pm2 ls` is empty after reboot | `pm2 save` was never run, or PM2 startup hook missing | `pm2 save && pm2 startup` (follow the printed command) |
| Frontend shows old version after deploy | Service worker served stale JS | Clear site data, or wait — `index.html` ships `Clear-Site-Data: "cache"` |
| WS keeps closing on phone | Expired JWT (>1h backgrounded) — handled transparently since v2.2 | If still failing, log out / back in to mint fresh tokens |

## Health checklist

```bash
pm2 ls | grep codebridge-bridge                              # bridge online
ssh celox 'systemctl is-active codebridge-backend'           # backend active
curl -fsS https://<host>/api/health                          # backend reachable
```

All three green ⇒ system healthy.
