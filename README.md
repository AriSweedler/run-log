# run-log

`run_log` runs a command in an interactive zsh and captures it into a directory: stdout and
stderr byte for byte, each on its own pty, a plain-text copy of each with escapes stripped, and
a `metadata` file with the command, its exit code and its duration. It is built for handing a
command's output to an AI agent: the agent reads the capture directory instead of a terminal
scrape.

```zsh
nix run github:AriSweedler/run-log -- --dir /tmp/caps -- kubectl get pods
cat /tmp/caps/001_*/stdout.plain
cat /tmp/caps/001_*/metadata      # user=, command=, exit=0, duration_s=…
```

Install: `nix profile install github:AriSweedler/run-log`. It puts four commands on PATH.

| Command | What it does |
|---|---|
| `run_log` | run a command and capture it; `run_log --help` lists the flags |
| `run_log-capture.py` | the capture engine `run_log` calls: one pty per stream |
| `irun` | run a command in an interactive zsh, so aliases and functions work |
| `strip-ansi` | copy stdin to stdout without ANSI escape sequences |

`run_log` reads its shell library from [ari-zshlib](https://github.com/AriSweedler/ari-zshlib);
the Nix package pins it. Without Nix, set `ARI_ZSHLIB` and `ARI_PLUGINS` to that repo's `lib`
directory.
