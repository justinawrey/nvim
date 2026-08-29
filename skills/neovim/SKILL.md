---
name: neovim
description: Control the user's running Neovim instance remotely via `nvim --server`, always in the background without stealing focus. Use whenever the user mentions "neovim", "nvim", "vim", or asks to open/close/name/navigate splits, windows, panes, tabs/tabpages, buffers, or terminals in their editor — e.g. "open a horizontal terminal", "name this tab", "run lazygit in a new pane", "what buffers do I have open".
compatibility: Assumes this agent is running inside a Neovim `:terminal` (so `$NVIM` is set) and describes justinawrey's config at ~/.config/nvim, where this skill ships (found via Neovim's runtimepath, so its install path is irrelevant).
---

# Controlling Neovim remotely

This agent runs inside a `:terminal` buffer of the user's live Neovim instance, so it can drive
that editor over its RPC socket. Everything below is specific to the user's config
(`~/.config/nvim`) — commands like `:T`, `:Ht`, `:TabName` and the `<leader>n` terminal-rename
prompt are theirs, not stock Neovim.

## Rule zero: NEVER GRAB FOCUS

**The user is working in the editor at the same time as you. Every action you take must happen
in the background.** The current window, the current tabpage, the cursor position and the
current mode must be exactly what they were when you started. No exceptions, no "just for a
second", no flicker.

Concretely, this bans:

- **`--remote-send` for anything structural.** It types keys into whatever window is focused,
  which is both destructive and focus-dependent. Treat it as unavailable.
- **Bare Ex commands over RPC** (`:e`, `:b`, `:split`, `:tabnew`, `:tabn`, `:T`, `:Tt`) — they
  are all defined in terms of *the current window*, so they move it.
- **`nvim_set_current_win` / `nvim_set_current_tabpage` / `nvim_set_current_buf`** as the goal of
  an action, rather than as part of restoring what you disturbed.
- **Keymap-driven UI** (`<leader>n`, `<leader>t`, `<leader>x`, pickers) — a prompt or picker
  steals the cmdline and the keyboard.

The only exception is an **explicit** request to move: "switch me to tab 3", "open X and take me
there", "focus the terminal". Absent those words, work in the background. If a request can
*only* be satisfied by a focus-grabbing UI (see "Focus-grabbing things" below), say so and ask —
don't just do it.

### How to not grab focus

Address windows and buffers **by handle** through the API. Then focus is never involved:

```lua
vim.fn.bufadd(path); vim.fn.bufload(buf)             -- load a file, no window at all
vim.api.nvim_win_set_buf(win, buf)                    -- "edit" in another window
vim.api.nvim_open_win(buf, false, {                   -- new split, enter = false
  split = 'below', win = target_win })
vim.api.nvim_buf_set_lines(buf, ...)                  -- edit an unfocused buffer
vim.api.nvim_buf_get_lines(buf, -40, -1, false)       -- read an unfocused buffer
vim.api.nvim_win_call(win, fn)                        -- run fn "there", auto-returns
vim.api.nvim_buf_call(buf, fn)
vim.api.nvim_chan_send(job, 'cmd\r')                  -- drive a terminal you're not in
```

For the handful of things with no handle-based form (`:tabnew` above all), snapshot and restore
around them — including the mode, because leaving a window drops terminal mode, and a stray
`TermOpen`/`BufEnter` autocmd can queue a `startinsert` that would otherwise land in the user's
window. `scripts/bg.lua` does this for you; don't hand-roll it.

## Connect

The socket path is in `$NVIM`, exported into every process spawned from a `:terminal`:

```bash
nvim --server "$NVIM" --remote-expr 'tabpagenr()'
```

If `$NVIM` is empty, this shell isn't inside the editor — say so instead of guessing at
sockets under `$TMPDIR/nvim.*/`.

## Rules

- **Never grab focus.** See Rule zero. This outranks everything else here.
- **Never send keys into this agent's own terminal buffer** — it types into itself. Identify it
  by walking `$$`'s ppid chain and matching a pid against the `term://{cwd}//{pid}:{cmd}` buffer
  names (see "Find my own buffer"). With `nvim_chan_send` this is the whole risk surface, since
  nothing else you do depends on where focus is.
- **Prefer Lua over keystrokes, always.** `--remote-expr` returns a value, so the action is
  verifiable and focus-independent; `--remote-send` is fire-and-forget, focus-dependent, and
  usually a focus grab. The only sane use for `--remote-send` is feeding text to a program in
  a terminal that is *already* focused — and `nvim_chan_send` does that better.
- **Verify after acting, by handle.** `nvim_get_current_win()` must equal what it was;
  `nvim_get_current_tabpage()` likewise. Read buffers with `nvim_buf_get_lines(buf, ...)`, never
  `getline()` — `getline()` reads the *current* buffer and tempts you into focusing it.
- **Sleep between steps.** UI actions are async; ~0.5–1s between a command and the next one,
  and 2–8s before checking that a spawned TUI (lazygit, an agent) has painted.
- **Don't submit input the user didn't ask you to submit.** Typing a prompt into a REPL/agent is
  not the same as pressing `<CR>`. Send the text and the `\r` as two separate calls.
- **Don't edit `~/.config/nvim` when asked to *drive* the editor.** Changing config is a
  separate, explicit request.
- **Never split unless the user explicitly asks for a split.** Words like "split", "pane",
  "vertical"/"horizontal", "beside"/"below", or a named command (`:T`, `:Vt`, `:Ht`, `:vsplit`)
  are the only licence to carve up an existing window. Otherwise open a **new tabpage** — it
  leaves the user's current layout untouched. If a request is ambiguous, use a tab; don't guess
  a split. Either way it happens in the background.

## Running Lua remotely

Inline Lua through `--remote-expr` is a quoting minefield. Write a heredoc to a temp file and
`dofile` it — the file's return value comes back on stdout:

```bash
cat > /tmp/nv.lua <<'EOF'
local bg = dofile(vim.api.nvim_get_runtime_file('skills/neovim/scripts/bg.lua', false)[1])
return vim.fn.tabpagenr() .. '/' .. vim.fn.tabpagenr('$')
EOF
nvim --server "$NVIM" --remote-expr "luaeval(\"dofile('/tmp/nv.lua')\")"
```

Return a string (or `vim.inspect(...)` a table); `--remote-expr` can't print a raw Lua table.

Two scripts live next to this file:

- **`scripts/state.lua`** — dumps tabpages, windows, buffers and terminals in one call. Good
  first move when the layout matters.
- **`scripts/bg.lua`** — the background toolkit. `dofile` it at the top of every remote script.

```bash
nvim --server "$NVIM" --remote-expr "luaeval(\"dofile(vim.api.nvim_get_runtime_file('skills/neovim/scripts/state.lua', false)[1])\")"
```

### Locating the scripts

This skill ships inside the user's Neovim config repo, so **ask Neovim where the scripts are**
rather than hardcoding a path:

```lua
dofile(vim.api.nvim_get_runtime_file('skills/neovim/scripts/bg.lua', false)[1])
```

That is the only supported way to load them. `nvim_get_runtime_file` searches every
runtimepath entry, `~/.config/nvim` among them, so the lookup survives the skill being
symlinked into `~/.pi/agent/skills/`, `~/.agents/skills/`, or anywhere else, and survives the
repo being checked out under a different `$HOME`.

Don't reach for `os.getenv(...)` here: the Lua runs **inside the Neovim process**, so it sees
Neovim's environment, not the shell's — a variable exported in the `bash` step is invisible to
it. If the lookup returns `nil` (`attempt to index a nil value`), the config repo isn't on the
runtimepath; report that instead of guessing at absolute paths.

### `scripts/bg.lua`

| Call | Effect |
|---|---|
| `bg.pick_win([exclude])` | A normal, non-float, non-special window that isn't yours |
| `bg.keep_focus(fn)` | Run `fn`, then restore window **and** mode. The escape hatch for `:tabnew` and friends |
| `bg.load(path)` | `bufadd` + `bufload` → buffer handle. No window involved |
| `bg.show(path[, win])` | Put a file in another window without focusing it → `win, buf` |
| `bg.split(path[, dir[, host]])` | New split via `nvim_open_win(..., false, ...)`, not entered → `win, buf` |
| `bg.tab([path])` | New tabpage in the background → tabpage handle |
| `bg.term_tab([cmd])` | Terminal in its own new tabpage, backgrounded → `{ tab, win, buf, job }` |
| `bg.send(buf, text[, submit])` | `nvim_chan_send` to a terminal buffer; `submit` appends `\r` |
| `bg.peek(buf[, n])` | Last `n` lines of any buffer, focus-free |
| `bg.in_win(win, fn)` / `bg.in_buf(buf, fn)` | `nvim_win_call` / `nvim_buf_call` |
| `bg.noauto(fn)` | Run `fn` with `eventignore=all` |

The canonical "spawn a terminal in a new tab and drive it" flow, entirely in the background:

```bash
cat > /tmp/nv.lua <<'EOF'
local bg = dofile(vim.api.nvim_get_runtime_file('skills/neovim/scripts/bg.lua', false)[1])
local t = bg.term_tab()
vim.g._bg_buf = t.buf                      -- stash the handle for later calls
return ('tab=%s buf=%s job=%s'):format(t.tab, t.buf, t.job)
EOF
nvim --server "$NVIM" --remote-expr "luaeval(\"dofile('/tmp/nv.lua')\")"

cat > /tmp/nv.lua <<'EOF'
local bg = dofile(vim.api.nvim_get_runtime_file('skills/neovim/scripts/bg.lua', false)[1])
bg.send(vim.g._bg_buf, 'lazygit', true)
return 'sent'
EOF
nvim --server "$NVIM" --remote-expr "luaeval(\"dofile('/tmp/nv.lua')\")"; sleep 3

# read it back without focusing it
cat > /tmp/nv.lua <<'EOF'
local bg = dofile(vim.api.nvim_get_runtime_file('skills/neovim/scripts/bg.lua', false)[1])
return bg.peek(vim.g._bg_buf, 30)
EOF
nvim --server "$NVIM" --remote-expr "luaeval(\"dofile('/tmp/nv.lua')\")" | grep -i lazygit
```

## Gotchas

- **`--remote-expr` is a blocking request** — nvim stops to service it. Keep the Lua fast; wrap
  slow work in `vim.schedule` / `vim.uv` (but then you can't return a value).
- **Autocmds still fire.** `nvim_win_call` triggers `WinEnter`/`WinLeave`, which can confuse the
  user's custom statusline/winbar/tabline. Use `bg.noauto` or `:noautocmd` if you see flicker.
- **Textlock**: some API calls are refused while a prompt/cmdline is pending. `vim.schedule`
  sidesteps it.
- **`nvim_win_set_buf` isn't `:edit`** — no `BufReadCmd` path, so `bufload` first (`bg.load`
  does).
- **Guard every handle** with `nvim_buf_is_valid` / `nvim_win_is_valid` before reading
  `vim.b`/`vim.bo` — a buffer deleted between listing and reading raises "Invalid buffer id".

## The user's custom commands

These are all **focus-grabbing** by design — they're meant to be typed by a human. Don't invoke
them over RPC. They're documented so you can recognise what the user is asking for and
reproduce the *effect* with `bg.lua`.

| Command | Effect | Background equivalent |
|---|---|---|
| `:T [cmd]` | **Default terminal.** Alias for `:Vt` | `bg.keep_focus` + `nvim_open_win(..., false, {split='right'})` then `:terminal` via `bg.in_win` |
| `:Vt [cmd]` | Vertical split terminal, opens to the **right** (`splitright`), enters terminal mode | as above |
| `:Ht [cmd]` | Horizontal split terminal, opens **below** (`splitbelow`), enters terminal mode | as above with `split='below'` |
| `:Tt` (`tt`, `<leader>x`) | The single scratch terminal in a fullscreen float; reuses the same shell. `<C-q>` hides it | none — a float over the user's work *is* a focus grab; ask first |
| `:TabName [name]` | Name the current tabpage; no arg clears it | `vim.t[tab].tabname = name` |
| `:H [subject]` | `:help` in a vertical split | `bg.split` + `bg.in_win(w, function() vim.cmd('help ' .. s) end)` |
| `:Monitors N` | Tell the config how many displays the editor spans (float centering) | safe as-is; it doesn't move focus |

Because `equalalways` is off, a split only divides the window it came from — other panes keep
their sizes.

Default way to open a terminal: **`bg.term_tab()`** — its own tabpage, nothing in the user's
layout is divided, focus never moves.

## Naming a tabpage

There's no built-in tab name in Neovim; the config stores one in `t:tabname` and renders it in
a custom tabline (unnamed tabs show `[No Name]`). Set it on a tabpage handle — no `:TabName`,
no focus change:

```lua
local t = bg.tab()
vim.t[t].tabname = 'lazygit'
```

## Naming a terminal

`<leader>n` renames the terminal in the current window via a `vim.ui.input` prompt. It requires
focus *and* the cmdline, so it's off-limits. The name lives in `b:term_name` — set it directly:

```lua
vim.b[buf].term_name = 'lazygit'
```

That's what the `<leader>t` terminal picker searches and displays; unnamed terminals fall back
to an auto-label `"<folder> · <program>"` derived from the `term://` buffer name. If the user
explicitly asks for "the `<leader>n` prompt" rather than the rename itself, tell them it's an
interactive prompt and let them press it.

## Focus-grabbing things (ask first)

- `:Tt` / `<leader>x` fullscreen scratch float
- `<leader>t` terminal picker, snacks pickers
- `<leader>n` rename prompt, any `vim.ui.input` / `vim.ui.select`
- `<C-h/j/k/l>` window navigation, `<C-1>`…`<C-6>` tab navigation
- Anything whose entire purpose is "put me somewhere else"

If the user explicitly asked for one of these, it's fine — that's the exception in Rule zero.

## Native primitives

```lua
vim.api.nvim_list_tabpages()                    -- tabpage handles
vim.api.nvim_tabpage_get_number(tab)            -- handle -> 1-based number
vim.api.nvim_tabpage_list_wins(tab)             -- windows in a tabpage
vim.api.nvim_win_get_buf(win)                   -- buffer shown in a window
vim.api.nvim_win_get_config(win).relative ~= '' -- is it a float?
vim.api.nvim_win_close(win, true)               -- close a window (no focus needed)
vim.api.nvim_list_bufs()                        -- all buffers
vim.api.nvim_buf_get_name(buf)                  -- 'term://{cwd}//{pid}:{cmd}' for terminals
vim.bo[buf].buftype == 'terminal'               -- is it a terminal?
vim.b[buf].term_name                            -- user-set terminal name
vim.b[buf].terminal_job_id                      -- channel for nvim_chan_send
vim.fn.win_findbuf(buf)                         -- every window showing a buffer
```

Closing things (`nvim_win_close`, `nvim_buf_delete`, `nvim_win_close` on the last window of a
tabpage) is focus-safe *unless* you close the window the user is in — check against
`nvim_get_current_win()` first and refuse.

## Driving a program inside a terminal

**`nvim_chan_send` only** (`bg.send`). It writes straight to the pty: no focus, no mode
juggling, exact bytes.

```lua
bg.send(buf, 'echo hi', true)     -- submits
bg.send(buf, 'echo hi')           -- leaves it sitting in the prompt
bg.send(buf, '\27\r')             -- ESC CR = the config's <S-CR>, a literal newline
                                  -- for Claude/pi-style prompt composers
```

Poll for a TUI to be ready with `bg.peek(buf, 30)` and grep the result. Never `getline()`.

## Find my own buffer

```bash
p=$$; pids=; while [ "$p" -gt 1 ]; do pids="$pids $p"; p=$(ps -o ppid= -p $p | tr -d ' '); done
echo "$pids"   # match against the pid in each term:// buffer name
```

The terminal buffer whose `term://{cwd}//{pid}:{cmd}` pid appears in that chain is the one this
agent lives in. Never send to it, never `:bd!` it.
