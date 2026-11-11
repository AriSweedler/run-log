---
name: ari-dotfile--submodule-run-log
description: Work on run-log, the public repo behind `run_log` (a command's stdout and stderr captured into a directory an agent reads back), its capture engine `run_log-capture.py`, `irun` and `strip-ansi`. The repo is a dotfiles dev repo, a plain clone at ~/dotfiles/.config/run-log (linked to ~/.config/run-log) whose package.nix the shared Nix flake builds and places at ~/.config/bin. Use when editing any of those bins, package.nix or the repo's flake, or when ~/.config/bin/run_log lacks a change. The capture contract is ari-driving-tmux's; commits, pushes and the flake.lock bump follow ari-dotfile--submodule.
---

# run-log in the dotfiles

run-log holds `run_log` and the three bins it ships with, packaged by one
`package.nix`. The dotfiles build that package with their own shell library and
place the four bins at `~/.config/bin`, where `/ari-driving` and its tests call
them. The repo is a dotfiles *dev repo*: `/ari-dotfile--submodule` has what
every dev repo shares (`main`, identity, commits, Ari's push and the lock bump
it makes, the generic failures); this skill has what is run-log's. What
`run_log` writes and its flags are `/ari-driving-tmux` § The run_log contract:
change that section with any change to the contract, and never restate it here.

## Rules

- **`~/.config/bin/run_log` is a commit, never the working tree.** It is the store build of the checkout's HEAD at the last `dotfiles switch`, pushed or not. An uncommitted edit runs only as `zsh ~/dotfiles/.config/run-log/bin/run_log …`.
- **Change a live default only together with `package.nix`.** The install phase rewrites these strings with `--replace-fail`; a commit that changes one MUST change its `package.nix` line too:

  | File | Live default | `package.nix` |
  |---|---|---|
  | `bin/run_log` | `${ARI_ZSHLIB:-${HOME}/.config/zsh/plugins}` | `libDefault` |
  | `bin/run_log` | `"${XDG_CONFIG_HOME:-$HOME/.config}/claude/lib/tmux-pane.sh"` | `paneDefault` |
  | `bin/run_log` | `python3 -I "${CAPTURE_HELPER}"` | the third `--replace-fail` |
  | `bin/strip-ansi` | `${ARI_PLUGINS:-${HOME}/.config/zsh/plugins}` | `pluginsDefault` |

  A bin that sources a library file not in this table, or calls `python3` another way, passes **Check** and breaks only when packaged: add it here and to `package.nix`.
- **Edit a library file in the dotfiles, NEVER in `~/dotfiles/.config/ari-zshlib`.** `log.zsh` and `strip_ansi.zsh` live at `~/dotfiles/.config/zsh/plugins/`, `tmux-pane.sh` at `~/dotfiles/.config/claude/lib/`, committed per `/ari-dotfiles`; `nix/pkgs/ari-zshlib` builds them. `github.com/AriSweedler/ari-zshlib` (not in `dev-repos`) mirrors that `lib/` byte for byte for this repo's standalone `flake.nix`; the dotfiles build ignores it.
- **No hooks, no bootstrap step, no denylist: these parent rules change.** `core.hooksPath` correctly prints nothing (run no `dotfiles apply`); **Check** passes when `nix build` exits 0 (there is no `[OK]` line); the missing denylist is by design (do not report it). The parent's `main`, `user.email` and author checks still apply, and with no hook behind them they are yours at **Commit**.
- **Claude NEVER pushes**: no `git push`, no `git -C ~/.config/run-log push`, no `dotfiles push` (`/ari-dotfile--submodule` § Pushing).

## Reference

### Layout

`~/dotfiles/.config/run-log` and `~/.config/run-log` are one directory; commands below use `~/.config/run-log`.

| Piece | Path |
|---|---|
| Checkout (public) | upstream `github.com/AriSweedler/run-log`; ignored by `~/dotfiles/.gitignore`; `[repo ".config/run-log"]`, `input = run-log` in `~/dotfiles/.config/dotfiles/dev-repos` |
| Bins | `bin/run_log` (the zsh front end), `bin/run_log-capture.py` (the capture engine: one pty per stream), `bin/irun`, `bin/strip-ansi` |
| Package | `package.nix`: installs the four bins and pins their live defaults (**Rules**) to `zshlib`'s store copy and the store's `python3` |
| Standalone flake | `flake.nix`, `flake.lock`: `packages.default` from `package.nix` with `github:AriSweedler/ari-zshlib` |
| Docs | `README.md` (install, the four commands, running without Nix) |
| This skill | `skills/ari-dotfile--submodule-run-log/`, linked into `~/.claude/skills` by `nix/claude-skills.nix` at the switch after its commit |

### The build

- `~/dotfiles/.config/dotfiles/nix/pkgs/default.nix` builds `"${devInputs.run-log}/package.nix"` with `zshlib = self.ari_zshlib`; `ari-bins.nix` places the bins at `~/.config/bin/` (`/ari-dotfiles-nix` § Ari's packages).
- `dotfiles switch` locks the `run-log` input at the checkout's HEAD in `~/.local/share/dotfiles/nix/flake.lock`, then builds; so does `--build`, which activates nothing.
- **Check** is `nix build --no-link path:$HOME/dotfiles/.config/run-log`: the standalone flake and its install check (`installCheckPhase`: a capture of `echo hello` lands with `exit=0`; `strip-ansi` strips a color). It builds the working tree, untracked files included; the switch builds HEAD only.
- A host without Nix gets no `run_log` from the dotfiles.

## Workflow

### Change run-log

1. **Edit** under `bin/`, `package.nix` or `flake.nix`.
2. **Try it** from the working tree, in a fresh directory, always with `--no-copy`:
   ```zsh
   d=$(mktemp -d /tmp/run_log-try.XXXXXX); zsh ~/dotfiles/.config/run-log/bin/run_log --dir "$d" --no-copy -- echo hello
   ```
   Read the capture its `capture_dir=` line names, per `/ari-driving-tmux` § Read a capture. **NEVER pass `--deliver-to` or `--focus-after` in a try you run**: hand Ari that command per `/ari-driving-tmux`.
3. **Contract.** If the diff adds, removes or renames a flag, or changes `--help`, the capture directory's name or files, the `metadata` keys, the artifact line or the exit code: run `/ari-skill-update ari-driving-tmux` for § The run_log contract, and name both commits to Ari.
4. **Check** (Reference). Red → fix and re-run; two fixes that do not clear it → stop and show Ari the first error and what you changed.
5. **Commit.** Every line MUST print as shown:
   ```zsh
   git -C ~/.config/run-log branch --show-current        # main
   git -C ~/.config/run-log config --local user.email    # ari@sweedler.com
   ```
   `git -C ~/.config/run-log add <files>` (never `-A` or `.`; every file **Check** built, or the switch builds something else). **Read `git -C ~/.config/run-log diff --cached` and the message for company hostnames, ids, ticket numbers or colleagues; remove any and re-stage.** Commit as `type(scope): subject`: scope `run_log`, `capture`, `irun`, `strip-ansi`, `nix` (package.nix, flake.nix, flake.lock), `readme` or `skills`, e.g. `fix(run_log): keep the exit line when the pane closes mid-run`. Then `git -C ~/.config/run-log log -1 --format='%an <%ae> %cn <%ce>'` prints `Ari Sweedler <ari@sweedler.com>` twice. Nothing staged (`git -C ~/.config/run-log diff --cached --quiet` exits 0) → no commit; go to step 6.
6. **Switch** per `/ari-dotfiles-nix` § Switch after a commit touching `bin/`, `package.nix` or `skills/`; a `README.md`-only commit needs none.
7. **Link test**, when the commit touched `bin/run_log`: `zsh $HOME/.claude/skills/ari-driving-tmux/tests/link.test.zsh` (it runs `~/.config/bin/run_log`, so only after the switch). Red → the live `run_log` is broken: tell Ari, then fix forward (steps 1–6) or `git -C ~/.config/run-log revert HEAD` and switch.
8. Tell Ari "Run `dotfiles push` when ready." per `/ari-dotfile--submodule` § Pushing.

### Set up a machine

`dotfiles apply dotfiles_repo` clones the checkout. No step pins its identity: `git -C ~/.config/run-log config user.name "Ari Sweedler"` and `git -C ~/.config/run-log config user.email ari@sweedler.com`. Then `dotfiles switch`. After a pull moves the checkout, switch again.

## When it fails

Generic rows (detached HEAD, push log lines, lock-bump refusals): `/ari-dotfile--submodule` § When it fails.

| symptom | cause | do |
|---|---|---|
| healthcheck `fail dotfiles_repo submodule_undocumented ~/.claude/skills lacks ari-dotfile--submodule-run-log …` | this skill uncommitted, or committed after the last switch | `git -C ~/.config/run-log add skills/ari-dotfile--submodule-run-log`, commit (step 5), switch; ignore the healthcheck's registry `link` fix line |
| `~/.config/bin/run_log` lacks a change | uncommitted, or committed after the last switch | `jq -er '.nodes["run-log"].locked.rev' ~/.local/share/dotfiles/nix/flake.lock` against `git -C ~/.config/run-log rev-parse HEAD`: differ → switch; equal after a `--build` alone → switch (`--build` moved the lock, not `~/.config/bin`); HEAD an ancestor of the locked rev → `git -C ~/.config/run-log pull --ff-only origin main` first. Until then run `zsh ~/dotfiles/.config/run-log/bin/run_log …`; NEVER copy it into `~/.config/bin` |
| `substituteStream() in derivation run-log-0: ERROR: pattern … doesn't match anything` | a live default changed without `package.nix` | update its `package.nix` line (Rules table) |
| **Check** fails in `installCheckPhase` | the capture did not land, or `strip-ansi` kept an escape | run step 2 against the checkout and read its capture |
| the standalone build's `run_log` cannot source a library file (e.g. `tmux-pane.sh` on `--deliver-to`) | `flake.lock` pins an ari-zshlib older than the file | `nix flake update ari-zshlib --refresh --flake path:$HOME/dotfiles/.config/run-log` (`--refresh` because Nix caches a GitHub ref for about an hour, so without it a recent ari-zshlib push locks the older commit again), commit as `build(nix): …` |
| the checkout's `bin/run_log` or `bin/strip-ansi` fails sourcing `log.zsh` or `strip_ansi.zsh` | no `~/.config/zsh/plugins` on this machine | `ARI_ZSHLIB=~/dotfiles/.config/ari-zshlib/lib ARI_PLUGINS=~/dotfiles/.config/ari-zshlib/lib zsh ~/dotfiles/.config/run-log/bin/<bin> …` (read-only use of the mirror) |
