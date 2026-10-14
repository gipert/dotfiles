# Global preferences

## Tooling

- `gh` (GitHub CLI) must always be invoked outside the sandbox. The default
  sandbox blocks the auth/config writes it performs and `gh` commands fail in
  non-obvious ways. This applies to every `gh` subcommand (auth, pr, issue,
  api, repo, …).
- `pre-commit` must be always invoked outside the sandbox, since it needs write
  permissions under `~/.cache`.
- `ssh`, `scp`, `rsync` to remote hosts must run outside the sandbox: its
  network filter blocks SSH (host names do not even resolve).
- On `cannot enable executable stack as shared object requires` from a pixi/conda
  Julia: clear the flag in the rattler cache in place, never in the repo. Patch a
  copy with `patchelf --clear-execstack`, then `cat` it back over
  `~/.cache/rattler/cache/pkgs/libopenlibm4-*/lib/libopenlibm.so.4.0` so the inode
  survives and every env is fixed at once. Then retry.

## Git commits

- Commit style: Conventional Commits (https://www.conventionalcommits.org)
- AI agents must not be listed as co-authors of commits (e.g., via
  `Co-authored-by:` trailers) or pull requests. Instead a trailer should be added
  `Assisted-by: Generative AI`.
- When the user asks for a small follow-up fix to the most recent commit (e.g.
  polishing a description, fixing a typo, tweaking wording in code just added),
  default to `git commit --amend` + force-push-with-lease rather than stacking
  a separate commit. This keeps history tidy. Only stack a new commit when the
  change is logically distinct from the previous one, or when the previous
  commit has already been merged / interacted with by others.

## Writing style

### Prose

- Never use em dashes (the `—` character) in any prose you produce, whether in
  chat replies, code comments, documentation, READMEs, or commit messages.
  Rephrase instead using commas, parentheses, colons, or separate sentences.
- `AGENTS.md` or `CLAUDE.md` file content length is usually limited by context
  size requirements. Write these files in a dry and very concise way,
  preferring bullet lists and selecting the text representation that maximizes
  clarity and minimizes number of characters.

### Code

Applies to code, documentation, docstrings, code comments, commit messages, PR
descriptions and issue comments. The audience is physicists, not software
engineers. Clarity first, brevity second: when they conflict, choose clarity.

- Plain language. Prefer the physics term to the CS term: "energy deposition",
  not "payload"; "detector table", not "data structure"
- Avoid CS jargon that has an everyday equivalent: leverage, instantiate,
  orchestrate, performant, seamless, robust, utilize, boilerplate. Say what
  happens to the data instead
- Plain words over inflated ones: "before", not "prior to"; "about", not "with
  regard to". Normal formal register is fine, the target is inflation
- An unavoidable technical term is introduced once, with a short definition in
  parentheses
- Short, direct sentences, active voice, present tense. Split sentences above
  ~30 words
- No filler: "it is worth noting", "in order to", chains of "additionally",
  "furthermore", "moreover". Do not close every section with a summary sentence
- Spell out units, coordinate conventions and physical assumptions. This is what
  a reader needs and the code cannot state it
- When updating documentation for something that has changed behavior, do not
  mention the old behavior, just document the feature as is
- In documenting a new feature in a general library or tool that was prompted
  by a specific application in a consumer software, do not mention that
  consumer

- Do not add structure the change does not need:
  - No module constant for a value used once or twice; use a literal or an
    argument default, meaning in the docstring. Exception: user-facing knobs and
    parameters that must stay in sync across callers.
  - No helper function for a few lines used once; inline them.
  - Docstring length follows complexity: one line or none for tiny functions.
    Rationale goes in the commit/PR, not in docstrings or comments.
  - Prefer editing an existing function over adding one.
  - Private functions (name starting with underscore) need only a one-line
    docstring.
  - Tests don't need any docstring most of the time. Add one only if there are
    some facts that are very hard to understand from the test code and are key
    to know.

### GitHub

- Do not hard-wrap prose in GitHub messages (PR descriptions, PR/issue
  comments, issue bodies, release notes). Write each paragraph as a single long
  line and let GitHub soft-wrap it. Hard wrapping is fine elsewhere (commit
  messages, code, docs) unless stated otherwise.
- Make sure to include a concise description of the changes in a PR and link the
  relevant related PRs or issues
- Commit subject in the imperative, max 72 characters; the body explains why,
  not what the diff already shows
- A PR description says what changed and why, plus any change in behavior or API
  and how to update calling code. Do not narrate the diff file by file
- State plainly what was verified (tests, linting, docs build) and what was not

## SSH hosts

### LNGS LEGEND computing cluster

- On the `lngs-legend` SSH host, the `legend-dataflow` production cycles live
  under `/data2/public/prodenv/prod-blind`. A specific cycle such as
  `ref/v3.3.0` is therefore at `/data2/public/prodenv/prod-blind/ref/v3.3.0`
- When SSH-ing to `lngs-legend` (or other `lngs-legend-*` hosts) as the
  `pertoldi` user, activate the global uv venv before running Python:
  ```bash
  source /data1/users/pertoldi/.local/venvs/global/bin/activate
  ```
  you will find the LEGEND software there.
- If you need another Python package, ask the user to install it.
- Treat all access through the `lngs-legend` SSH host as **read-only**. Inspect
  files and run non-mutating commands, but do not modify files, write to the
  prodenv, or launch real production jobs there. Note that `snakemake -n` also
  requires write access.
- If a fix needs to be applied, make it locally / via git and let the user
  deploy it, rather than editing files on the host.

## NERSC HPC center

- Load the `nersc` skill before any NERSC access.
- Even without it: never submit jobs to the queue unless explicitly asked
  (they cost allocation hours), and never recursively traverse shared
  top-level directories (`/`, `/global`, `/global/cfs`, `/global/homes`,
  `/pscratch`, `/opt`, `/usr`).

## LaTeX

- Use latexmk to compile documents. The configuration file is in `~/.latexmkrc`
- The log/aux files are stored in a `.auxtex` directory
- Pass latexmk options `-file-line-error -verbose -interaction=nonstopmode -shell-escape`
- `revtex4-1` cold builds intermittently abort a pass with `! Missing
  \begin{document}` and exit 12 while still writing a valid PDF. It's
  transient, not a real error.
- Fix: re-run `latexmk` 1–3× until exit 0; if it won't converge, `rm -rf
  .auxtex` (not `latexmk -c/-C`) and rebuild.
- Use the `\toprule`, `\midrule`, `\bottomrule` commands from the `booktabs`
  pachage for tables, unless `revtex` is used (then use the recommended
  `revtex` commands)
