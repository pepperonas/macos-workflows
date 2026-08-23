# New Textfile

Finder Quick Action: right-click a folder (or any file in it) →
**New Textfile** → an empty `Untitled.txt` is created in that folder and
opened in your default text editor. The one thing Finder inexplicably
still lacks.

## Behavior

- Right-clicking a folder creates the file inside it; right-clicking a
  file creates it next to that file
- If `Untitled.txt` exists, the name auto-increments:
  `Untitled 1.txt`, `Untitled 2.txt`, …
- The new file opens immediately (`open`, i.e. your default `.txt` app)

## Requirements

None.

## Install

```bash
open "New Textfile.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                               # commit first, restore with git checkout
```

> Historical note: this bundle was once lost from the repo for exactly
> that reason — `open`-install *moved* it to `~/Library/Services/` and it
> was never restored. It was recovered from the installed copy in 2026-08;
> the repo-wide test `test_repo_every_workflow_has_bundle` now guards
> against a repeat.
