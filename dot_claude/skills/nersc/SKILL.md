---
name: nersc
description: How to work on the NERSC HPC center (Perlmutter) through the `nersc` SSH host - fast remote command form, running on an interactive compute node, conda env, installing extra software with uv/pixi, Slurm jobs (never submitted without explicit request), data locations (legend-simflow and legend-dataflow productions, CFS, $SCRATCH), and filesystem search limits. Load before any NERSC access - whenever NERSC, Perlmutter, `ssh nersc`, `nersc-*` hosts, `nid*` compute nodes, Slurm (`sbatch`, `salloc`, `squeue`, interactive nodes), `/global/cfs`, `/dvs_ro/cfs`, project m2676, or simflow/dataflow productions at NERSC are mentioned.
---

# NERSC

## Running commands

- SSH runs outside the sandbox (its network filter blocks SSH).
- Command form, about 1 s per call (mostly network round trip):
  ```bash
  ssh -n -q nersc "zsh -c '<cmd>' </dev/null"
  ```
  - Group related commands into one call: each call costs about 1 s of
    network round trip to Berkeley, so five checks in one call take 1 s
    instead of 5.
  - `zsh -c` reads `.zshenv`, which activates the mamba env `pertoldi`
    (LEGEND software, `pixi`, `uv`). Plain `ssh nersc '<cmd>'` runs bash:
    no env.
  - Always pass `-n` and the remote `</dev/null`: a remote command that reads
    input otherwise hangs forever.
- For anything beyond a one-liner, copy a script to `$SCRATCH/<task>/` and run
  it there with `zsh` (gets the env; `bash` does not). Nested quoting through
  ssh + zsh breaks easily.
- SSH to `nersc*` hosts reuses one open connection (`ControlMaster`, closes
  after 4 h idle), so all calls land on the same login node. If `ssh` hangs,
  run `ssh -O exit nersc` and retry.
- NERSC clocks, logs and Slurm times are in US Pacific time
  (`America/Los_Angeles`). When reporting a time to the user, convert it to
  the local time zone of this machine (check with `date`), e.g.
  `date -d 'TZ="America/Los_Angeles" 2026-10-14 07:08'`.

## Compute node

- Use an interactive compute node for anything CPU- or memory-heavy. Login
  nodes are shared by all users and limit CPU and memory per user: heavy
  processes there are slow, and NERSC may kill them. Short checks can stay on
  the login node.
- The user starts the node with `--job-name=claude`, so it is easy to find
  among their other jobs. If no such job is running, ask the user to start
  one.
- Find the node: `squeue --me -n claude -h -o %N` (via `ssh nersc`).
- Run commands with the same form as on the login node, about 1 s per call:
  ```bash
  ssh -n -q <node> "zsh -c '<cmd>' </dev/null"
  ```
  The connection goes through the login node and stays open. Processes run
  inside the job (its CPUs and memory) and are killed when it ends.
- All rules below apply on the node as well.

## Batch jobs

- Never submit jobs to the queue (`sbatch`, `salloc`, `srun` outside an
  existing job) unless the user explicitly asks: they cost allocation hours.
- Never cancel jobs either: the user may be working in that job's shell, or it
  may be a production job. Cancelling it loses their work.
- Running commands on the node of the user's running `claude` job is fine.

## Environment (`~/.zshenv_bis`)

Set in every zsh. The home directory has little space, so caches and software
go to `$SCRATCH`:

| Variable | Value |
|---|---|
| `XDG_CACHE_HOME` | `$SCRATCH/cache` |
| `SWPREFIX` | `$SCRATCH/software` |
| `CONDA_ENVS_DIRS` | `$SWPREFIX/conda/envs:/global/common/software/m2676/users/pertoldi/conda/envs` |
| `CONDA_PKGS_DIRS` | `$XDG_CACHE_HOME/conda/pkgs` |
| `UV_PYTHON_INSTALL_DIR` | `$SWPREFIX/share/uv/python` |
| `UV_TOOL_DIR`, `UV_PYTHON_BIN_DIR` | `$SWPREFIX/share`, `$SWPREFIX/bin` |
| `PIXI_HOME` | `$SWPREFIX/pixi` |
| `NUMBA_CACHE_DIR` | `$XDG_CACHE_HOME/numba` |
| `HDF5_USE_FILE_LOCKING` | `FALSE` |

- Do not override these: the home directory has a small quota, and when
  caches fill it, tools and jobs fail with confusing errors.
- Never put pixi workspaces or environments under `/global/common/software`:
  it is read-only on compute nodes, and pixi writes to its environment when it
  runs. Use `$SCRATCH`.

## Scratch work and extra software

- Put scratch work (scripts, outputs) in `$SCRATCH/<task>/`. `$SCRATCH` is a
  large, fast disk, but NERSC deletes files not read or changed for 8 weeks,
  and there are no backups. Use it for throwaway work only, one directory per
  task so it is easy to find and delete. Anything worth keeping goes to git or
  CFS.
- Install software you need in a temporary environment with `uv` or `pixi`.
  That way nothing remains after the task, and the user's setup stays exactly
  as they configured it.
- Never let `uv` install into the `pertoldi` env. It is the user's shared
  working env, and a broken package there breaks everything. Because a conda
  env is always active, `uv pip install` without an explicit target installs
  straight into it. Never run `uv pip install` (or `uv pip sync`, `--system`)
  without pointing it at a virtual environment you created.
  - Python package on top of the `pertoldi` env, one-off:
    `uv run --no-project --with <pkg> python script.py`
  - Several packages or repeated use: a virtual environment in the task
    directory that also sees the `pertoldi` packages:
    ```bash
    cd $SCRATCH/<task>
    uv venv --system-site-packages --python "$(command -v python)" .venv
    uv pip install --python .venv <pkg>
    .venv/bin/python script.py
    ```
  - Python command-line tool: `uvx <tool>`
  - Conda package (compiled tools, non-Python software):
    `pixi exec -s <pkg> <cmd>`
  - Each takes about 1 s once cached. Caches are in `$SCRATCH/cache`.

## Data locations

- `legend-simflow` production cycles: `/global/cfs/cdirs/m2676/sims/prod`.
  E.g. cycle `l200cfg09/v2.3.0` is at
  `/global/cfs/cdirs/m2676/sims/prod/l200cfg09/v2.3.0`.
- `legend-dataflow` productions (copied from the LNGS cluster):
  `/global/cfs/projectdirs/m2676/data/lngs/l200/public/prodenv/prod-blind`.
- CFS disk I/O is slow. Read through the faster read-only mount of
  `/global/cfs` at `/dvs_ro/cfs`. For even better performance use the SSD
  scratch disk at `$SCRATCH`.
- Reading HDF5 files on CFS needs file locking disabled. The env sets
  `HDF5_USE_FILE_LOCKING=FALSE`; in a clean environment set it yourself or use
  the `h5py` function argument.

## Filesystem discovery

The shared filesystems hold hundreds of millions of files. A recursive scan can
run for hours and slows down the filesystem for every NERSC user, which can get
the account flagged. Fast, targeted lookups are almost always possible.

- Never recursively traverse `/`, `/global`, `/global/cfs`, `/global/homes`,
  `/pscratch`, `/opt`, `/usr`, or another shared top-level directory. This
  applies on compute nodes as well as login nodes.
- This includes `find`, `bfs`, `fd`, `tree`, recursive `du`, `rg --files`,
  recursive `grep`, recursive `ls`, globstar expansion, and recursive
  traversal written in Python or another language.
- Before searching, identify a bounded root inside the current workspace or a
  known project or data directory. Constrain depth and filename patterns where
  possible. If no bounded root is known, stop and ask the user.
- Locate software with `command -v`, `type -a`, `module spider`, package
  metadata, or known environment prefixes. Do not search mounted filesystems
  for executables.
- The user installed a filesystem-traversal hook deliberately. Do not disable
  or bypass it, and do not ask the user to approve an equivalent broad scan
  through another command.
- A compute allocation is not permission for an unbounded traversal of a
  shared filesystem. Narrow the search first; run only bounded,
  computationally substantial searches, on the `claude` compute node.
