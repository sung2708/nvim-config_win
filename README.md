# sungp Neovim

Language: [English](README.md) | [Tiếng Việt](README.vi.md)

An IDE-oriented Neovim configuration for Python, Go, JavaScript/TypeScript,
Java, C/C++, Lua, and Markdown. It uses `lazy.nvim`, native LSP, Blink
completion, FzfLua, Treesitter, DAP, Neotest, and a compact Snacks dashboard.

The configuration is designed around five goals:

- Fast startup through event, command, keymap, and filetype-based lazy loading.
- Fast navigation through a single FzfLua picker stack.
- Complete coding support with LSP, completion, formatting, linting, testing,
  debugging, and Git integrations.
- One configuration for Windows, Linux, and macOS.
- Clear ownership boundaries between plugin specifications and integrations.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Install System Tools](#install-system-tools)
- [Install the Configuration](#install-the-configuration)
- [First Start](#first-start)
- [Managed Dependencies](#managed-dependencies)
- [Language Support](#language-support)
- [Configuration Layout](#configuration-layout)
- [Operating System Behavior](#operating-system-behavior)
- [User Interface](#user-interface)
- [Keymaps](#keymaps)
- [Optional Features](#optional-features)
- [Performance](#performance)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

## Features

| Area           | Components                                                        |
| -------------- | ----------------------------------------------------------------- |
| Plugin manager | lazy.nvim and `lazy-lock.json`                                    |
| LSP            | Native `vim.lsp`, nvim-lspconfig, Mason                           |
| Completion     | blink.cmp, friendly-snippets, signature help                      |
| Formatting     | Conform, Ruff, Prettier, Stylua, gofumpt, goimports               |
| Linting        | nvim-lint, ESLint, Ruff, markdownlint, ShellCheck                 |
| Search         | FzfLua, Snacks Picker, Grug Far                                   |
| Navigation     | Flash, Neo-tree, Oil, Bufferline, Treesitter and Mini textobjects |
| Editing        | Dial cycling, IncRename previews, Yanky, surround, autopairs      |
| Workflow       | Overseer tasks, Persistence sessions, Yanky history               |
| AI             | CodeCompanion v19 agent chat through Codex ACP                    |
| Diagnostics    | Trouble, Todo Comments, Lualine                                   |
| Git            | Gitsigns, Fugitive, Diffview                                      |
| Debugging      | nvim-dap, nvim-dap-ui, debugpy, Delve, JS Debug, Java Debug       |
| Testing        | Neotest for Python, Go, Jest, and Java                            |
| UI             | Catppuccin, Snacks dashboard, WhichKey, Noice, Notify             |
| Cursor         | smear-cursor.nvim in Normal mode; disabled while inserting        |

## Requirements

### Core Requirements

| Tool              | Purpose                                             |
| ----------------- | --------------------------------------------------- |
| Neovim `>= 0.12`  | Native LSP APIs and nvim-treesitter `main` support  |
| Git               | Bootstrap lazy.nvim and download plugins            |
| Internet access   | Required only for initial installation and updates  |
| ripgrep (`rg`)    | File search, live grep, Todo, and FzfLua            |
| fzf               | FzfLua backend                                      |
| C compiler or Zig | Build native extensions and Treesitter parsers      |
| tree-sitter-cli   | Compile and update Treesitter parsers               |
| unzip, gzip, tar  | Extract packages installed by Mason                 |
| curl              | CodeCompanion HTTP requests and Mason downloads     |

`fd` is optional. The current FzfLua file picker uses `rg --files`, but other
picker configurations may still benefit from `fd`.

A Nerd Font is not required for Neovim itself, but it is strongly recommended.
Without one, icons in WhichKey, Neo-tree, Trouble, Lualine, and the dashboard
may appear as empty squares.

### Language Runtimes

Install only the runtimes for the languages you use:

| Language              | External requirement                                         |
| --------------------- | ------------------------------------------------------------ |
| Python                | Python 3; `uv` is optional                                   |
| Go                    | Go toolchain                                                 |
| JavaScript/TypeScript | Node.js and npm                                              |
| Java                  | JDK 21; Maven or Gradle when the project has no wrapper      |
| C/C++                 | Clang, GCC, or Zig                                           |
| Lua                   | No separate runtime is required to edit Neovim configuration |

Mason installs language servers, formatters, linters, and debug adapters. It
does not replace the runtime or compiler required by a project. For example,
Mason can install `gopls`, but the Go toolchain is still required to build and
test Go code.

### Optional Tools

| Tool                         | Used by                                   |
| ---------------------------- | ----------------------------------------- |
| PowerShell 7 (`pwsh`)        | Improved terminal behavior on Windows     |
| fd                           | Alternative fast file discovery           |
| uv                           | Python environments and the Python REPL   |
| Maven                        | Java projects without `mvnw`              |
| Gradle                       | Java projects without `gradlew`           |
| Lazydocker and Docker        | `Space+ld`                                |
| Codex CLI and `codex-acp`    | CodeCompanion chat through Codex ACP      |
| pngpaste                     | CodeCompanion clipboard images on macOS   |
| xclip, xsel, or wl-clipboard | System clipboard integration on Linux     |

## Install System Tools

### Windows 10/11

The configuration has first-class support for
[Scoop](https://github.com/ScoopInstaller/Install). Open a regular PowerShell
session; Administrator privileges are not required:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

scoop bucket add java
scoop install git neovim ripgrep fd fzf make zig gcc nodejs python go maven unzip gzip curl
scoop install java/temurin21-jdk
npm install --global tree-sitter-cli@0.26.11
```

PowerShell 7 is recommended:

```powershell
scoop install pwsh
```

Verify the installation:

```powershell
nvim --version
git --version
rg --version
fzf --version
zig version
g++ --version
node --version
python --version
go version
java -version
mvn --version
```

When Scoop is present, the configuration automatically detects:

- `%USERPROFILE%\scoop\apps\go\current\bin`
- `%USERPROFILE%\scoop\apps\maven\current\bin`
- `%USERPROFILE%\scoop\apps\temurin21-jdk\current`
- `%USERPROFILE%\scoop\apps\gcc\current\bin\g++.exe`

`JAVA_HOME` is assigned from Scoop only when the variable is not already set.
An existing user-defined value always takes precedence.

### Providers and document preview tools (Windows)

This configuration uses `uv` for Neovim's Python provider and Volta/npm for
the Node provider. Install them with:

```powershell
$provider = "$env:LOCALAPPDATA\nvim-data\python-provider"
uv venv --python 3.13 $provider
uv pip install --python "$provider\Scripts\python.exe" pynvim

volta install node yarn
npm install --global neovim @mermaid-js/mermaid-cli
```

Verify both providers after installation:

```powershell
nvim --headless -i NONE `
  +'lua print("Python provider: " .. (vim.g.python3_host_prog or "missing"))' `
  +'lua print("Node provider: " .. (vim.g.node_host_prog or "missing"))' +qa
& "$env:LOCALAPPDATA\nvim-data\python-provider\Scripts\python.exe" -c "import pynvim; print(pynvim.__version__)"
neovim-node-host --version
```

The Python path should point to `nvim-data\python-provider`, and both provider
commands should run successfully.

For Snacks image, PDF, math, and Mermaid previews:

```powershell
scoop install imagemagick ghostscript tectonic
```

Restart PowerShell and Neovim after installation so the updated PATH is
available. Neovim automatically uses the Python provider at
`%LOCALAPPDATA%\nvim-data\python-provider` when it exists.

### Ubuntu/Debian

```bash
sudo apt update
sudo apt install git ripgrep fd-find fzf make gcc g++ \
  nodejs npm python3 python3-venv python3-pip golang-go \
  openjdk-21-jdk maven unzip gzip curl
```

Some Debian and Ubuntu releases install `fd` as `fdfind`:

```bash
mkdir -p ~/.local/bin
ln -s "$(command -v fdfind)" ~/.local/bin/fd
```

Ensure `~/.local/bin` is in `PATH`. Distribution packages may provide an older
Neovim release. If it is below `0.12`, install a current build using the
[official Neovim instructions](https://github.com/neovim/neovim/blob/master/INSTALL.md).

Optional clipboard packages:

```bash
# Wayland
sudo apt install wl-clipboard

# X11
sudo apt install xclip
```

If the distribution does not provide `openjdk-21-jdk`, install another JDK 21
distribution and export:

```bash
export JAVA_HOME=/path/to/jdk-21
export PATH="$JAVA_HOME/bin:$PATH"
```

### macOS

Install Xcode Command Line Tools and Homebrew packages:

```bash
xcode-select --install
brew install neovim git ripgrep fd fzf zig node python go openjdk@21 maven pngpaste
```

Add JDK 21 to the shell profile:

```bash
export JAVA_HOME="$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
```

macOS already provides `pbcopy` and `pbpaste`, so no separate clipboard package
is required.

## Install the Configuration

### 1. Back Up an Existing Configuration

Windows PowerShell:

```powershell
Rename-Item "$env:LOCALAPPDATA\nvim" "nvim.backup" -ErrorAction SilentlyContinue
Rename-Item "$env:LOCALAPPDATA\nvim-data" "nvim-data.backup" -ErrorAction SilentlyContinue
```

Linux/macOS:

```bash
mv "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" \
  "${XDG_CONFIG_HOME:-$HOME/.config}/nvim.backup" 2>/dev/null || true
mv "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/nvim-data.backup" 2>/dev/null || true
```

### 2. Clone the Repository

Windows PowerShell:

```powershell
git clone https://github.com/sung2708/nvim-config.git "$env:LOCALAPPDATA\nvim"
```

Linux/macOS:

```bash
git clone https://github.com/sung2708/nvim-config.git \
  "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
```

### 3. Open Neovim

```bash
nvim README.md
```

`lazy.nvim` bootstraps itself into Neovim's data directory. Because plugins
are lazy-loaded, the dashboard may appear before Mason has finished installing
development tools. Opening `README.md` also loads the Markdown-specific
Treesitter and rendering integrations.

## First Start

Run these commands inside Neovim:

```vim
:Lazy sync
:MasonToolsInstall
:TSUpdate
:Lazy load nvim-dap
:Lazy load neotest
:NeotestJava setup
:checkhealth lazy vim.lsp vim.provider vim.deprecated vim.treesitter
```

What each command does:

1. `Lazy sync` installs plugins at the commits recorded in `lazy-lock.json`.
2. `MasonToolsInstall` installs LSP servers, formatters, linters, and Java/JS
   debug adapters.
3. `TSUpdate` installs or updates Treesitter parsers.
4. Loading `nvim-dap` allows Mason to install debugpy, Delve, and codelldb.
5. `NeotestJava setup` downloads the JUnit Console required by Java tests.
6. The targeted `checkhealth` command validates Neovim, LSP, Treesitter, and
   the plugin manager without running checks for disabled Snacks modules or
   Neovim's unused built-in `vim.pack` manager.

Plugins can also be bootstrapped without opening the UI:

```bash
nvim --headless "+Lazy! sync" +qa
```

After installation, open one file for each language you use. LSP servers and
language-specific plugins start only when a matching buffer is opened.

### Final Validation

After restarting Neovim, run:

```vim
:ConfigHealth
:messages
:checkhealth lazy vim.lsp vim.provider vim.deprecated vim.treesitter
```

`:messages` should not contain startup errors. The targeted health report
should show no errors; warnings about a newer Neovim release are informational.
For CodeCompanion with Codex ACP, also run this in a terminal:

```powershell
codex login
codex login status
codex doctor --summary
```

`codex doctor` should report configured authentication and healthy databases.
If it reports an authentication problem, run `codex login` again before
opening CodeCompanion.

On Windows, check dependencies before opening Neovim:

```powershell
.\\bin\\check-environment.ps1
```

On Linux or macOS:

```bash
sh ./bin/check-environment.sh
```

If `tree-sitter` is missing, open a new PowerShell after installing it with npm
so the updated PATH is inherited. Inside Neovim, verify it with
`:echo executable('tree-sitter')`.

This repository uses the `main` branch of `nvim-treesitter`, so it requires the
`0.26.x` Tree-sitter CLI line. The documented version is `0.26.11`, which meets
the `0.26.1` minimum reported by `:checkhealth nvim-treesitter`.

On Windows with Volta, the configuration automatically prefers the real
Tree-sitter binary over Volta's `Volta\\bin\\tree-sitter.cmd` shim. The shim can
fail when a parser is built inside a temporary grammar directory.
language-specific plugins start only when a matching buffer is opened.

## Managed Dependencies

### lazy.nvim

`lazy.nvim` manages every plugin. Tested plugin commits are recorded in
`lazy-lock.json`; keep the lockfile under version control to use identical
versions across machines.

Plugin specifications are grouped by responsibility:

| File                         | Responsibility                                   |
| ---------------------------- | ------------------------------------------------ |
| `lua/plugins/lsp.lua`        | LSP, Mason, formatting, and linting              |
| `lua/plugins/completion.lua` | Completion, snippets, and signatures             |
| `lua/plugins/ai.lua`         | CodeCompanion v19 chat through Codex ACP         |
| `lua/plugins/treesitter.lua` | Parsers and textobjects                          |
| `lua/plugins/search.lua`     | FzfLua and Grug Far                              |
| `lua/plugins/ui.lua`         | Dashboard, statusline, notifications, WhichKey   |
| `lua/plugins/git.lua`        | Gitsigns, Fugitive, and Diffview                 |
| `lua/plugins/editor.lua`     | Explorers, Trouble, Flash, Todo, folds, editing  |
| `lua/plugins/debug.lua`      | DAP, Neotest, and adapters                       |
| `lua/plugins/languages.lua`  | Python, Go, TypeScript, and Java                 |
| `lua/plugins/terminal.lua`   | Terminals and Overseer tasks                     |
| `lua/plugins/sessions.lua`   | Persistent project sessions                      |

### Mason

Language servers installed and enabled automatically:

```text
clangd  cssls  eslint  gopls  html  jsonls
lua_ls  pyright  ruff  vimls
```

Tools managed by `mason-tool-installer`:

```text
clang-format           eslint_d             gomodifytags
gofumpt                goimports            google-java-format
gotests                iferr                impl
java-debug-adapter     jdtls                js-debug-adapter
markdownlint-cli2      prettier             ruff
shellcheck             stylua              typescript-language-server
```

Debug adapters managed through Mason:

```text
debugpy  delve  codelldb
```

These packages do not need to be installed globally unless they are also used
outside Neovim.

### Treesitter

Parsers installed automatically:

```text
bash  c  cpp  css  go  gomod  gosum  gotmpl  gowork  html
javascript  java  json  latex  lua  markdown  markdown_inline
python  query  regex  toml  tsx  typescript  vim  vimdoc  yaml
```

On Windows, `bin/zig-cc.cmd` and `bin/zig-cxx.cmd` expose Zig as a C/C++
compiler for Treesitter. These `.cmd` wrappers are Windows-only. Linux and
macOS use `CC`/`CXX` when set, then fall back to `cc`, `clang`, `gcc`, `c++`,
`clang++`, or `g++`.

## Language Support

### C/C++

| Role       | Tool                 |
| ---------- | -------------------- |
| LSP        | clangd through Mason |
| Formatting | clang-format         |
| Compiler   | GCC, Clang, or Zig   |

On Windows, Scoop GCC is supported directly. The `clangd` configuration allows
Scoop GCC through `--query-driver` and provides fallback include paths for
single C/C++ files that do not have `compile_commands.json`.

For regular projects, prefer generating `compile_commands.json` with the build
system. For one-file practice programs, this configuration should still find
standard headers such as `<iostream>` when Scoop GCC is installed.

### Python

| Role                   | Tool               |
| ---------------------- | ------------------ |
| LSP and types          | Pyright            |
| Lint and quick fixes   | Ruff LSP           |
| Formatting and imports | Ruff               |
| Virtual environments   | venv-selector.nvim |
| Debugging              | debugpy            |
| Testing                | neotest-python     |

The Python terminal chooses an interpreter in this order:

1. `uv run python`
2. `python3`
3. `python`

### Go

| Role                   | Tool                                            |
| ---------------------- | ----------------------------------------------- |
| LSP                    | gopls                                           |
| Formatting and imports | gofumpt, goimports                              |
| Code generation        | gopher.nvim, gomodifytags, gotests, impl, iferr |
| Debugging              | Delve                                           |
| Testing                | neotest-golang                                  |

On Windows x86_64, the configuration sets `GOARCH=amd64` only when `GOARCH`
does not already exist.

### JavaScript/TypeScript

| Role         | Tool                  |
| ------------ | --------------------- |
| LSP          | ts_ls (typescript-language-server) |
| Diagnostics  | ESLint                |
| Formatting   | Prettier              |
| Debugging    | js-debug-adapter      |
| Testing      | neotest-jest          |
| JSX/TSX tags | nvim-ts-autotag       |

`ts_ls` owns TypeScript LSP; the optional `typescript-tools.nvim` spec is disabled.
Import and fix mappings are registered when ts_ls attaches.

### Java

| Role        | Tool                           |
| ----------- | ------------------------------ |
| LSP         | nvim-jdtls and Eclipse JDTLS   |
| Annotations | Lombok                         |
| Formatting  | google-java-format             |
| Debugging   | java-debug-adapter             |
| Testing     | neotest-java and JUnit Console |

This configuration runs JDTLS with JDK 21. A project should contain at least
one recognized root marker: `.git`, `mvnw`, `pom.xml`, `gradlew`,
`build.gradle`, or `settings.gradle`.

The first Java project open may take longer while JDTLS indexes the workspace
and downloads sources. Run `:NeotestJava setup` once for each new Neovim data
directory.

### Filetype Indentation

| Filetype                         | Settings                   |
| -------------------------------- | -------------------------- |
| Python, Lua, Java                | 4 spaces                   |
| JavaScript, TypeScript, JSX, TSX | 2 spaces                   |
| Go                               | Tabs displayed at width 4  |
| Markdown                         | Wrap and linebreak enabled |

## Configuration Layout

```text
nvim/
|-- init.lua
|-- lazy-lock.json
|-- bin/
|   |-- zig-cc.cmd
|   `-- zig-cxx.cmd
|-- lua/
|   |-- config/
|   |   |-- init.lua
|   |   |-- options.lua
|   |   |-- keymaps.lua
|   |   |-- autocmds.lua
|   |   `-- lazy.lua
|   |-- plugins/
|   |-- integrations/
|   `-- helper/
|-- after/
|   `-- ftplugin/
|-- snippets/
|-- spell/
`-- README.md
```

Responsibilities:

- `init.lua`: the only configuration entrypoint. Do not add `init.vim`; Neovim
  reports `E5422: Conflicting configs` when both files exist.
- `lua/config/`: global options, keymaps, autocmds, and lazy bootstrap.
- `lua/plugins/`: plugin specifications, dependencies, and lazy-load rules.
- `lua/integrations/`: plugin setup and cross-plugin integration.
- `lua/helper/project.lua`: portable search directory/root resolution.
- `lua/helper/format.lua`: autoformat size guards and timeout policy.
- `after/ftplugin/`: per-filetype options.
- `lazy-lock.json`: pinned plugin commits.

Do not manually prepend `runtimepath` or `packpath`. The repository already
lives in `stdpath("config")`, and lazy.nvim owns plugin runtime paths.

## Operating System Behavior

### PATH and Environment Variables

`lua/config/options.lua`:

- Uses `;` as the Windows `PATH` separator and `:` on Linux/macOS.
- Adds `UV_PYTHON_BIN_DIR` and `UV_TOOL_BIN_DIR` when they exist.
- Detects Scoop installations of Go, Maven, and Temurin 21 on Windows.
- Sets `JAVA_HOME` only when the user has not already set it.
- Sets `GOARCH=amd64` only on Windows x86_64 when the variable is unset.

Environment variables may be set before starting Neovim.

Windows PowerShell:

```powershell
$env:JAVA_HOME = "C:\path\to\jdk-21"
$env:CC = "clang"
$env:CXX = "clang++"
nvim
```

Linux/macOS:

```bash
export JAVA_HOME=/path/to/jdk-21
export CC=clang
export CXX=clang++
nvim
```

### Machine-local overrides

Keep paths and preferences that only apply to one machine outside the shared
configuration. Copy the tracked example to the ignored `local.lua` file:

Windows PowerShell:

```powershell
Copy-Item .\lua\config\local.example.lua .\lua\config\local.lua
```

Linux/macOS:

```bash
cp ./lua/config/local.example.lua ./lua/config/local.lua
```

Plugin databases and history use `stdpath("data")`, not this repository.

### Clipboard

- Windows uses `clipboard=unnamed`.
- Linux and macOS use `clipboard=unnamedplus`.

Check clipboard providers with:

```vim
:checkhealth provider
```

### Shell and Terminal

- Windows prefers `pwsh` and falls back to Windows PowerShell.
- The Windows shell is configured for UTF-8 input and output.
- Linux and macOS retain the shell inherited by Neovim.

### Treesitter Compiler

- Windows prefers the Zig wrappers in `bin/`.
- Linux and macOS honor `CC` and `CXX`, then detect a system compiler.

## User Interface

### Dashboard

The Snacks dashboard displays the `SUNGP` header, shortcuts, four recent
files, and a compact Git status section.

Lualine and Bufferline are hidden while the dashboard is active so the content
can remain vertically centered. Both are restored automatically when the
dashboard closes or a file is opened.

Dashboard spacing is intentionally compact:

- No empty row between every shortcut.
- Small gaps separate the header, shortcut list, recent files, and Git status.
- Width and pane spacing are reduced to avoid an excessively wide layout.

### Command Line and Completion

Noice renders the centered command line. Blink supplies command completion
after `:` and uses a separate rounded menu with horizontal content padding.
The menu is positioned below the Noice border with a visible row of separation.

### Popup Spacing

- Noice content popups use rounded borders and inner padding.
- WhichKey uses one row and two columns of padding.
- FzfLua uses one row and two columns of internal padding.
- Trouble adds top and left spacing to result views.
- Notify uses its wrapped renderer for message padding.

### Smear Cursor

Smear Cursor is loaded after the first frame and animates Normal-mode cursor
movement. Insert-mode smearing is disabled to keep typing visually stable:

```lua
smear_insert_mode = false
vertical_bar_cursor_insert_mode = true
```

Toggle it at runtime with:

```vim
:SmearCursorToggle
```

## Keymaps

`Leader` is `Space`. `LocalLeader` is `\`.

Press `Space` and wait briefly to open WhichKey. All major groups include
descriptions and icons.

### Core Navigation

| Key                 | Mode            | Action                                 |
| ------------------- | --------------- | -------------------------------------- |
| `Alt+h/j/k/l`       | Normal/Terminal | Move between windows                   |
| `Ctrl+Arrow`        | Normal          | Resize the current window              |
| `Space+j/k`         | Normal/Visual   | Move a line or selection               |
| `<` / `>`           | Visual          | Indent and retain the selection        |
| `Ctrl+d/u`          | Normal          | Half-page scroll and center            |
| `n` / `N`           | Normal          | Next/previous search result and center |
| `Esc`               | Normal          | Clear search highlighting              |
| `Tab` / `Shift+Tab` | Normal          | Next/previous buffer                   |
| `Space+bc`          | Normal          | Close buffer while preserving layout   |
| `Space+bp`          | Normal          | Pin or unpin buffer                    |
| `Space+be/bq`       | Normal          | Move buffer right/left                 |

### Explorer and Dashboard

| Key        | Action                                          |
| ---------- | ----------------------------------------------- |
| `Ctrl+n`   | Reveal the current file in Neo-tree             |
| `Ctrl+t`   | Toggle Neo-tree                                 |
| `Ctrl+f`   | Focus Neo-tree                                  |
| `-`        | Open the current file's parent directory in Oil |
| `Space+fo` | Open Oil in a floating window                   |
| `Space+sd` | Open the SUNGP dashboard                        |

Dashboard keys:

| Key | Action                           |
| --- | -------------------------------- |
| `f` | Find file                        |
| `g` | Live grep                        |
| `b` | List buffers                     |
| `e` | Open file explorer               |
| `s` | Git status                       |
| `d` | Git diff                         |
| `x` | Diagnostics                      |
| `t` | Test summary                     |
| `c` | Open the configuration directory |
| `n` | Create a new file                |
| `q` | Quit Neovim                      |

### Search

| Key        | Action                                   |
| ---------- | ---------------------------------------- |
| `Space+ff` | Find files in the project               |
| `Space+fg` | Live grep in the project                |
| `Space+fb` | Find buffers with FzfLua                 |
| `Space+fh` | Search help tags                         |
| `Space+fe` | Find files from the buffer directory     |
| `Space+fr` | Project search and replace with Grug Far |
| `Space+fy` | Open yank history                        |
| `Space+fF` / `Space+fG` | Files / grep in the current working directory |
| `Space+fE` | Grep from the buffer directory |
| `Space+fN` | Fast project grep without file/git icons |
| `Space+fR` | Resume the last picker, including query and original scope |
| `Space+fw` | Grep the word under the cursor; in Visual mode, the selection |
| `Space+fl` | Search lines in the current buffer |
| `Space+fO` | Recent files across projects |
| `Space+fk` | Search keymaps |

Project search resolves the nearest `.git` ancestor of the current file
(including worktrees), then the nearest language marker such as `package.json`,
`pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, or `.project-root`, then
falls back to the current working directory. Inside a Git monorepo, this means
the repository root; use `fe`/`fE` for a package directory. Unnamed and special
buffers resolve from the current working directory. Search never changes
`:pwd`, terminal directories, or session scope. `fr` retains Grug Far's current
working directory scope; inspect its Paths field before replacing.

All paths are passed as picker options, with no shell-specific `cd` commands.
The existing Windows ripgrep escaping and fd/rg fallback remain in effect.
Fast grep retains ripgrep's ignore behavior but omits icons and Lua result
processing; regular `fg` keeps file icons. Toggle hidden files with `Alt+h`.

Inside FzfLua:

| Key        | Action                 |
| ---------- | ---------------------- |
| `Ctrl+d/u` | Scroll preview down/up |
| `Ctrl+q`   | Select all and accept  |

### UI and Performance Controls

| Key | Action |
| --- | --- |
| `Space+uz` / `Space+uZ` | Toggle Zen / zoom, restoring the previous layout on exit |
| `Space+u.` / `Space+uS` | Markdown scratch notes / select a saved scratch |
| `Space+uw` | Toggle wrap in this window |
| `Space+ud` | Toggle diagnostics globally |
| `Space+ua` | Toggle cursor animation |
| `Space+ui` / `Space+uc` | Toggle indent guides / chunk highlighting |
| `Space+ub` | Toggle breadcrumbs |
| `Space+uf` / `Space+uF` | Toggle autoformat globally / for this buffer |
| `Space+up` | Show plugin load timings (`Lazy profile`) |
| `Space+uP` | Start/stop the Lua runtime profiler and inspect results |

The existing `Space+ci` toggles LSP inlay hints when supported. Scratch notes
are saved under Neovim's data directory, keyed by cwd, Git branch, and count;
copying this config does not copy the notes. Zen does not enable dim animation.
For a slower machine, set `vim.g.sungp_animations = false` in the ignored
`lua/config/local.lua`; `ua` can still enable cursor animation during a session.

### Flash and Treesitter

| Key         | Mode                   | Action                       |
| ----------- | ---------------------- | ---------------------------- |
| `s`         | Normal/Visual/Operator | Flash jump                   |
| `S`         | Normal/Visual/Operator | Flash Treesitter             |
| `am` / `im` | Visual/Operator        | Around/inside function       |
| `ac` / `ic` | Visual/Operator        | Around/inside class          |
| `as`        | Visual/Operator        | Around scope                 |
| `Space+mp`  | Normal                 | Swap with next parameter     |
| `Space+mP`  | Normal                 | Swap with previous parameter |
| `]m` / `[m` | Normal/Visual/Operator | Next/previous function start |
| `]M` / `[M` | Normal/Visual/Operator | Next/previous function end   |
| `]]` / `[[` | Normal/Visual/Operator | Next/previous class start    |
| `][` / `[]` | Normal/Visual/Operator | Next/previous class end      |
| `]o`        | Normal/Visual/Operator | Next loop                    |
| `]s`        | Normal/Visual/Operator | Next scope                   |
| `]z`        | Normal/Visual/Operator | Next fold                    |
| `]C` / `[C` | Normal/Visual/Operator | Next/previous conditional    |

### Editing Helpers and Folds

| Key                       | Mode          | Action                                         |
| ------------------------- | ------------- | ---------------------------------------------- |
| `Space+mh/j/k/l`          | Normal/Visual | Move the current line or selection             |
| `gS`                      | Normal/Visual | Split or join arguments                        |
| `y`, `p`, `P`, `gp`, `gP` | Normal/Visual | Yank and put through Yanky history             |
| `[y` / `]y`               | Normal        | Previous/next yank-ring entry after a put      |
| `zR` / `zM`               | Normal        | Open/close all folds                           |
| `zr` / `zm`               | Normal        | Open/close one fold level                      |
| `zK`                      | Normal        | Preview folded lines, otherwise show LSP hover |

Mini AI enhances built-in `a`/`i` textobjects. Mini Bracketed adds
previous/next navigation for buffers, files, indentation, jumps, location
lists, old files, quickfix entries, windows, and Git conflict markers.

### AI Assistant

CodeCompanion v19 uses Codex through ACP for chat buffers. Ensure `curl`,
`codex`, and `codex-acp` are on `PATH`, then run `codex login` once on each
machine before starting a chat.

| Key        | Mode          | Action                                        |
| ---------- | ------------- | --------------------------------------------- |
| `Space+a?` | Normal/Visual | Open the CodeCompanion action palette         |
| `Space+aa` | Normal        | Open the CodeCompanion action palette         |
| `Space+aa` | Visual        | Add the selection to the current chat         |
| `Space+am` | Visual        | Open the NUI selection-action menu            |
| `Space+aq` | Visual        | Ask a free-form question about selected code  |
| `Space+ae` | Visual        | Explain selected code                         |
| `Space+af` | Visual        | Find and fix issues in selected code          |
| `Space+al` | Visual        | Explain LSP diagnostics in the selection      |
| `Space+at` | Visual        | Generate tests for selected code              |
| `Space+aR` | Visual        | Refactor selected code                        |
| `Space+ac` | Normal/Visual | Add a review comment to the line or selection |
| `Space+ai` | Normal/Visual | Toggle the current chat                       |
| `Space+an` | Normal/Visual | Start a new chat                              |
| `Space+ar` | Normal        | Refresh cached chat/tool availability         |
| `Space+av` | Normal        | Review changes made by the current agent      |
| `Space+aV` | Normal        | Review every worktree change since baseline   |
| `Space+ax` | Normal        | List files changed by CodeCompanion           |
| `Space+aS` | Normal        | Stop the latest chat request                  |

`Space+am` is a compact NUI menu with Ask, Explain, Diagnostics, Fix,
Refactor, Tests, Documentation, and a three-step Code workflow. It captures
the selection before opening the popup, so the selected code remains attached
after choosing an action. `Space+aq` opens the NUI question input directly.

The action palette keeps its Snacks interface but lists only prompts that work
with the Codex ACP chat adapter: Explain, Fix, Diagnostics, Tests, Refactor,
Documentation, the selection workflow, and Commit message. The repository's
inline-only prompt entries are intentionally hidden because they require a
separately configured HTTP adapter.

New chats do not include the current file automatically. Add live file context
with `#{buffer}` in the prompt; use `#{buffer}{all}` when every turn should send
the complete file. Use `/buffer` to select open buffers or `/file` to select
files from the working directory.

The chat buffer and its approval prompts add scoped mappings, so these keys do
not replace editor mappings elsewhere:

| Key                    | Scope                       | Action                                         |
| ---------------------- | --------------------------- | ---------------------------------------------- |
| `<CR>` or `<C-s>`      | Normal; `<C-s>` also Insert | Submit the prompt                              |
| `q`                    | Chat, Normal                | Stop the current request                       |
| `ga`                   | Chat, Normal                | Select the adapter and model                   |
| `Space+ab`             | Chat, Normal                | Select an open buffer with FzfLua              |
| `Space+af`             | Chat, Normal                | Select a file with FzfLua                      |
| `Space+ah`             | Chat, Normal                | Select Neovim help with FzfLua                 |
| `Space+am`             | Chat, Normal                | Change ACP model, mode, or reasoning           |
| `Space+ap`             | Chat, Normal                | Select an image with Snacks                    |
| `Space+aP`             | Chat, Normal                | Paste a clipboard image through img-clip       |
| `Space+aR`             | Fresh chat, Normal          | Resume a previous ACP session                  |
| `Space+as`             | Chat, Normal                | Select file symbols with FzfLua                |
| `Space+ad`             | Chat approval, Normal       | View the proposed diff                         |
| `?`                    | Chat, Normal                | Show available chat options and keymaps        |

Blink supplies completion inside chat. The action palette and image picker use
Snacks, while file-oriented pickers use FzfLua. In a code-review quickfix list,
`d` opens the selected hunk against CodeCompanion's baseline in Diffview; the
built-in `a`, `c`, and `x` mappings accept, comment on, or ignore that hunk.

Use `Space+aP` (or `:PasteImage`) in a chat to attach an image from the
clipboard, or `Space+ap` (or `/image`) to select an image from a file or URL.
Clipboard images require `pngpaste` on macOS and `xclip` or `wl-clipboard` on
Linux.

ACP adapters are available only to CodeCompanion's chat interaction. Use the
action palette, a visual selection action, or `:CodeCompanion /<alias>` here;
the generic inline `:CodeCompanion` prompt, `CodeCompanionCmd`, and CLI
interaction need a separately configured HTTP or CLI adapter.

Codex authentication and configuration stay in the platform-default
`~/.codex`. The configuration sets `CODEX_SQLITE_HOME` to
`stdpath("data")/nvim-config/codex-sqlite`, isolating ACP's live SQLite files
from Codex Desktop without copying authentication tokens or setting
`CODEX_HOME`.

### LSP

LSP mappings are buffer-local and exist only after a language server attaches:

| Key             | Action                             |
| --------------- | ---------------------------------- |
| `gd`            | Definitions through FzfLua         |
| `gy`            | Type definitions through FzfLua    |
| `gi`            | Implementations through FzfLua     |
| `grr`           | References through FzfLua          |
| `gO`            | Document symbols through FzfLua    |
| `Space+cS`      | Workspace symbols                  |
| `K` / `Space+e` | Hover documentation                |
| `Space+ca`      | Code action                        |
| `Space+rn`      | Rename symbol with live preview    |
| `Space+cd`      | Line diagnostics                   |
| `]d` / `[d`     | Next/previous diagnostic           |
| `Space+ci`      | Toggle inlay hints when supported  |
| `Space+cf`      | Format buffer or selection         |
| `Space+cL`      | Run lint                           |
| `Space+cm`      | Open Mason                         |
| `Space+cs`      | Trouble document symbols           |
| `Space+cl`      | Trouble LSP list                   |

Diagnostics do not update while Insert mode is active, which keeps typing
stable and reduces unnecessary redraws.

### Insert Completion

| Key                 | Action                               |
| ------------------- | ------------------------------------ |
| `Ctrl+Space`        | Show completion or documentation     |
| `Ctrl+e`            | Hide completion                      |
| `Ctrl+n/p`          | Select next/previous item            |
| `Ctrl+j/k`          | Select item or jump through snippets |
| `Tab` / `Shift+Tab` | Accept/advance or move backward      |
| `Ctrl+y`            | Accept the selected completion       |
| `Enter`             | Insert a normal newline              |
| `Ctrl+b/f`          | Scroll documentation                 |
| `Ctrl+l`            | Toggle signature help                |

### Command-Line Completion

Typing `:` automatically opens Blink command suggestions. `/` and `?` search
do not open the menu automatically, but completion can still be requested
manually.

| Key          | Action                                |
| ------------ | ------------------------------------- |
| `Tab`        | Show the menu or select the next item |
| `Shift+Tab`  | Select the previous item              |
| `Ctrl+Space` | Show completion manually              |
| `Ctrl+n/p`   | Select next/previous item             |
| `Ctrl+y`     | Accept the selected item              |
| `Ctrl+e`     | Cancel completion                     |

### Formatting and Linting

| Command or key    | Action                                        |
| ----------------- | --------------------------------------------- |
| `Space+cf`        | Format now                                    |
| `Space+cL`        | Lint now                                      |
| `:FormatDisable`  | Disable format-on-save globally               |
| `:FormatDisable!` | Disable format-on-save for the current buffer |
| `:FormatEnable`   | Re-enable format-on-save                      |
| `:ConformInfo`    | Show active formatter information             |

Autoformat waits up to 1000 ms (3000 ms for Java's JVM startup). It skips
special/unmodifiable buffers, buffers marked `bigfile`, files over 1 MiB,
and buffers averaging over 500 bytes per line, including files that grow after
opening. Manual `Space+cf` remains asynchronous and available for large files.
Saving remains synchronous with formatting so watchers see the formatted file.
If a formatter times out, inspect `:ConformInfo`, format manually, or set
`vim.g.autoformat_timeout_ms = 2000` in `lua/config/local.lua`. A buffer-local
`vim.b.autoformat_timeout_ms` overrides that setting. A global autoformat disable
takes precedence over the buffer toggle; `:FormatEnable` clears both disables.

Dial extends Vim's increment/decrement commands for integers, hexadecimal
values, dates, booleans, semantic versions, logical operators, and Markdown
checkboxes:

| Key                 | Mode          | Action                              |
| ------------------- | ------------- | ----------------------------------- |
| `Ctrl+a` / `Ctrl+x` | Normal/Visual | Increment/decrement the value       |
| `g Ctrl+a/x`        | Normal/Visual | Increment/decrement as a sequence   |

### Todo and Trouble

These producers share the same Quickfix workflow: search results from FzfLua
(`Ctrl+q`), Grug Far (`\\q`), TODO comments (`Space+xq`), Git hunks
(`Space+hq`/`Space+hQ`), and LSP diagnostics (`Space+xD`) can all be reviewed
with `Space+qF`, `Enter`, `]q`, and `[q`. This keeps the list useful as a common
handoff between plugins instead of requiring a separate navigation scheme.

Neotest also bridges to DAP: `Space+nt`/`Space+nf` runs tests normally, while
`Space+nd`/`Space+nD` runs the nearest test or current file under the debugger.
DAP remains lazy and loads only when this debug-test path is used.

### Quickfix with Quicker

Quicker improves the normal quickfix list without replacing Trouble. Use
`Space+qf` to toggle quickfix, or `Space+qF` to toggle and focus it. Inside the
quickfix window, press `>` to show two context lines around results and `<` to
collapse them. The list keeps grep syntax highlighting, file/line columns and
diagnostic icons. You can edit source lines directly in the quickfix buffer and
write with `:w`; only source buffers that were unmodified when the list opened
are autosaved. `Space+xQ` remains Trouble's richer tree view.

Quicker requires Neovim 0.10+. It owns `quickfixtextfunc`; avoid adding another
editable quickfix plugin such as quickfix-reflector or replacer. It coexists
with Trouble, but choose one view for each list.

| Key           | Action                          |
| ------------- | ------------------------------- |
| `Space+xx`    | Workspace diagnostics           |
| `Space+xX`    | Current buffer diagnostics      |
| `Space+xL`    | Location list                   |
| `Space+xQ`    | Quickfix list                   |
| `]t` / `[t`   | Next/previous Todo              |
| `Space+xt`    | All Todos in Trouble            |
| `Space+xf`    | All Todos in FzfLua             |
| `Space+xF`    | TODO/FIX/FIXME only in FzfLua   |
| `Space+xR`    | TODO/FIX/FIXME only in Trouble  |
| `Space+xq/xl` | Todos in quickfix/location list |
| `Space+xD`    | LSP diagnostics in quickfix        |
| `]q` / `[q`   | Next/previous quickfix entry      |

Recognized tags: `TODO:`, `FIX:`, `FIXME:`, `HACK:`, `WARN:`, `PERF:`, and
`NOTE:`.

### Git

| Key                 | Action                                       |
| ------------------- | -------------------------------------------- |
| `Space+gs`          | Git status                                   |
| `Space+gc`          | Git commit                                   |
| `Space+gp`          | Git push                                     |
| `Space+gl`          | Git pull                                     |
| `Space+gd`          | Open Diffview                                |
| `Space+gD`          | Close Diffview                               |
| `Space+gh`          | File history                                 |
| `]c` / `[c`         | Next/previous hunk                           |
| `Space+hs/hr`       | Stage/reset hunk                             |
| `Space+hS/hR`       | Stage/reset buffer                           |
| `Space+hp/hi`       | Preview hunk in popup/inline                 |
| `Space+hb`          | Blame current line                           |
| `Space+hd/hD`       | Diff against index/previous commit           |
| `Space+hq/hQ`       | Buffer/all hunks to quickfix                 |
| `Space+tb/tw/tl/tn` | Toggle blame/word diff/line/number highlight |
| `ih`                | Select hunk in Visual/Operator mode          |

### Debugging

| Key        | Action                               |
| ---------- | ------------------------------------ |
| `F5`       | Continue or start                    |
| `F10`      | Step over                            |
| `F11`      | Step into                            |
| `F12`      | Step out                             |
| `Space+db` | Toggle breakpoint                    |
| `Space+dB` | Set conditional breakpoint           |
| `Space+dr` | Open debug REPL                      |
| `Space+dl` | Run the previous debug configuration |
| `Space+du` | Toggle DAP UI                        |

### Testing

| Key        | Action                        |
| ---------- | ----------------------------- |
| `Space+nt` | Run nearest test              |
| `Space+nf` | Run tests in the current file |
| `Space+nT` | Run the complete test suite   |
| `Space+ns` | Toggle test summary           |
| `Space+no` | Open test output              |
| `Space+nO` | Toggle output panel           |
| `Space+nw` | Toggle watch mode             |

### Python Keymaps

| Key        | Action                                   |
| ---------- | ---------------------------------------- |
| `Space+pv` | Select a virtual environment with FzfLua |
| `Space+py` | Open a Python REPL terminal              |

### Go Keymaps

| Key        | Action                              |
| ---------- | ----------------------------------- |
| `Space+Gi` | Insert `if err != nil`              |
| `Space+Gt` | Add JSON struct tags                |
| `Space+GT` | Remove struct tags                  |
| `Space+Gc` | Generate a symbol comment           |
| `Space+Gf` | Generate a function test            |
| `Space+GF` | Generate tests for the current file |

### JavaScript/TypeScript Keymaps

| Key        | Action                         |
| ---------- | ------------------------------ |
| `Space+Ti` | Organize imports               |
| `Space+Ta` | Add missing imports            |
| `Space+Tu` | Remove unused code and imports |
| `Space+Tf` | Apply all available fixes      |

### Java Keymaps

| Key        | Mode          | Action                                     |
| ---------- | ------------- | ------------------------------------------ |
| `Space+Jo` | Normal        | Organize imports                           |
| `Space+Jv` | Normal/Visual | Extract variable                           |
| `Space+Jc` | Normal/Visual | Extract constant                           |
| `Space+Jm` | Visual        | Extract method                             |
| `Space+Jt` | Normal        | Run nearest test                           |
| `Space+JT` | Normal        | Run all tests in the file                  |
| `Space+Ju` | Normal        | Refresh Maven/Gradle project configuration |

### Terminal

| Key            | Mode            | Action                     |
| -------------- | --------------- | -------------------------- |
| `Ctrl+\`       | Normal/Terminal | Toggle terminal            |
| `Space+th`     | Normal          | Horizontal terminal        |
| `Space+tv`     | Normal          | Vertical terminal          |
| `Space+tf`     | Normal          | Floating terminal          |
| `Space+py`     | Normal          | Python REPL                |
| `Space+ld`     | Normal          | Lazydocker, when installed |
| `Space+s`      | Visual          | Send selection to terminal |
| `Esc`          | Terminal        | Return to Normal mode      |
| `Ctrl+h/j/k/l` | Terminal        | Move between windows       |

### Tasks and Sessions

| Key        | Action                                                       |
| ---------- | ------------------------------------------------------------ |
| `Space+or` | Pick and run an Overseer task                                |
| `Space+ot` | Toggle the Overseer task list                                |
| `Space+qs` | Restore the session for the current directory and Git branch |
| `Space+qS` | Select a saved session                                       |
| `Space+ql` | Restore the last session                                     |
| `Space+qd` | Stop saving the current session                              |

Git terminal commands:

```vim
:TermGitPush
:TermGitPushF
```

`TermGitPushF` performs a force push. Use it only when the branch history and
remote impact are understood.

### Comments, Surround, and Multiple Cursors

| Key                | Action                              |
| ------------------ | ----------------------------------- |
| `gcc`              | Toggle line comment                 |
| `gc{motion}`       | Comment by motion                   |
| `gc`               | Comment Visual selection            |
| `ys{motion}{char}` | Add surround                        |
| `ds{char}`         | Delete surround                     |
| `cs{old}{new}`     | Change surround                     |
| `S{char}`          | Surround Visual selection           |
| `Alt+n`            | Start/select next word occurrence   |
| `Alt+a`            | Select all matching words           |
| `Alt+p`            | Previous multiple-cursor occurrence |
| `Alt+x`            | Skip current occurrence             |
| `Esc`              | Exit multiple cursors               |

`Ctrl+n` is reserved for Neo-tree, so vim-visual-multi uses the custom Alt
mappings above instead of its defaults.

## Optional Features

### CodeCompanion v19 with Codex ACP

CodeCompanion requires `curl`. Install the Codex CLI and the current
`codex-acp`, ensure all three commands are on `PATH`, then authenticate on each
machine:

```powershell
npm install --global @openai/codex @agentclientprotocol/codex-acp
codex login
codex login status
```

Open Neovim and use `Space+an` for a new chat or `Space+ai` to toggle it. If
CodeCompanion asks to authenticate the ACP provider, complete that prompt once.
Codex ACP is chat-only, and no `CODEX_HOME` environment variable is required.

### Catppuccin

The default colorscheme is `catppuccin-frappe`. Change `M.name` in
`lua/config/theme.lua` to another Catppuccin flavor if desired.

### Lazydocker

The Lazydocker terminal is created only when `lazydocker` is executable.
Lazygit integration is intentionally disabled on Windows because of a
ConPTY/input issue; Git workflows remain available through Fugitive and
Diffview.

### Python uv

When `uv` is available, the Python terminal prefers `uv run python`. The
following variables are added to `PATH` when they point to existing
directories:

```text
UV_PYTHON_BIN_DIR
UV_TOOL_BIN_DIR
```

## Performance

Enabled optimizations:

- Startup loads core configuration, lazy.nvim, Catppuccin, Snacks, and
  nvim-treesitter. Devicons and Smear Cursor load later.
- LSP and language plugins load when matching files are opened.
- Blink loads on Insert or command-line entry.
- LazyDev loads only for Lua; SchemaStore loads only for JSON and JSONC.
- The nvim-treesitter `main` branch is intentionally non-lazy, as required by
  upstream; highlighting is deferred until a buffer is visible and missing
  parsers install in the background.
- nvim-lint loads only for supported filetypes.
- Mason tool installation checks run after startup and no more than once every
  seven days.
- `checktime` runs only after focus returns to Neovim or the buffer changes.
- LSP document highlights are cleared and suspended in Insert mode.
- LSP detaches from big files and virtual plugin buffers such as Diffview.
- Cursor line, cursor column, and relative numbers are hidden in Insert mode.
- Smear Cursor is disabled in Insert mode.
- `lazyredraw` is not enabled because it can conflict with Noice.
- Dashboard statusline and tabline are hidden and restored automatically.

Snacks marks a buffer as a big file when:

- The file is larger than 1 MB; or
- The average line length exceeds 500 characters, which commonly indicates a
  minified file.

For big files, the configuration disables Treesitter, LSP, completion, and
hlchunk rendering. Relative numbers, cursor line, and cursor column are also
disabled. Basic filetype syntax remains enabled so the file does not become
completely unhighlighted text.

## Maintenance

### Useful Commands

```vim
:Lazy
:Lazy sync
:Lazy profile
:Mason
:MasonToolsInstall
:MasonUpdate
:TSUpdate
:LspInfo
:LspRestart
:ConformInfo
:checkhealth
:checkhealth vim.lsp
:checkhealth nvim-treesitter
```

### Safe Update Process

1. Commit or back up `lazy-lock.json`.
2. Run `:Lazy sync`.
3. Run `:MasonUpdate` and `:TSUpdate`.
4. Open Python, Go, TypeScript, and Java projects and verify LSP behavior.
5. If an update causes a regression, restore `lazy-lock.json` and run
   `:Lazy restore`.

### Startup Profiling

```bash
nvim --startuptime startup.log
```

Inside Neovim:

```vim
:Lazy profile
```

Heavy plugins should load through filetypes, commands, or keymaps instead of
all loading during startup.

Also profile opening a file and typing immediately, grep in a large repository,
and saving with a formatter. Deferred loading moves work after the first frame;
it does not eliminate that work. `Space+uP` records Lua calls only while enabled;
profiling adds overhead, so use it to locate expensive calls rather than as an
unbiased latency benchmark. No profiler runs automatically.

Regression checks (from the configuration directory):

```sh
nvim --headless -u NONE -i NONE -l tests/upgrades.lua
nvim --headless -u NONE -i NONE -l tests/startup.lua
nvim --headless -u NONE -i NONE -l tests/dashboard_pick.lua
```

The upgrade check uses temporary fixtures and installed plugins, without
updating plugins or writing to your real scratch/session data. Keep
the installed `fzf`, `rg`, and plugin dependencies available for the startup
test, which checks the first Insert and real picker results headlessly. Keep
`lazy-lock.json` when copying the config and run `:Lazy restore`. The existing
Treesitter first-frame deferral and Blink first-insert workaround are retained;
verify first insert/completion and dashboard selection after plugin updates.

## Troubleshooting

### Generic `:checkhealth` Shows Snacks or `vim.pack` Errors

This configuration uses Snacks dashboard, bigfile, quickfile, input, and
picker modules with Snacks as the single `vim.ui.select` owner. It does not
enable Snacks image rendering or notifier, and it uses lazy.nvim instead of
Neovim's built-in `vim.pack`. A generic `:checkhealth` still checks disabled
modules. In a headless terminal it may report missing Kitty graphics, a
dashboard that did not run, disabled modules, or an absent
`nvim-pack-lock.json`; those reports do not indicate a startup failure.

Use the configuration-specific check instead:

```vim
:checkhealth lazy vim.lsp vim.provider vim.deprecated vim.treesitter
```

CodeCompanion is lazy-loaded. To run its own health check, load it first:

```vim
:Lazy load codecompanion.nvim
:checkhealth codecompanion
```

An offline `vim.provider` run may fail only its optional PyPI version lookup;
the configured Python provider remains usable when its executable and `pynvim`
version are reported successfully.

Node, Perl, and Ruby remote providers are intentionally disabled because none
of the configured plugins use them. This does not disable Node-based language
servers, formatters, Treesitter CLI, or ordinary Lua plugins.

### Headless Commands Print a PSReadLine Prediction Error

This message comes from the PowerShell profile, not Neovim. Guard prediction
setup so it only runs in an interactive terminal:

```powershell
if ($Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource History
}
```

Place the guard in `Microsoft.PowerShell_profile.ps1`, then restart the
terminal. This prevents redirected commands such as headless health checks
from printing an unrelated PSReadLine error.

### Codex ACP Reports SQLite or `arg0` Access Errors

Do not set `CODEX_HOME` in the Neovim configuration. Sign in with the normal
Codex home:

```powershell
codex login
codex doctor --summary
```

CodeCompanion keeps Codex authentication/configuration in the platform-default
`~/.codex`, while `CODEX_SQLITE_HOME` isolates ACP's runtime in
`stdpath("data")/nvim-config/codex-sqlite`. This prevents Codex Desktop and
`codex-acp` from competing for the same live databases. Close old Neovim/ACP
processes and restart Neovim after changing authentication.

### Markdown Leaves `E31: No such mapping`

Update this configuration and restart Neovim. Neovim 0.12 provides Lua
Markdown heading mappings, so the older duplicate Vimscript mappings are
disabled here. `[[` and `]]` remain available for previous/next headings.

### Neovim Works Only After `:source %`

Check the `VIMINIT` environment variable.

Windows PowerShell:

```powershell
Get-ChildItem Env:VIMINIT
```

Linux/macOS:

```bash
printf '%s\n' "$VIMINIT"
```

If it points to an older configuration, remove it from the shell profile and
restart the terminal. This repository uses `init.lua` as its only entrypoint;
do not create an `init.vim` compatibility file. Manual `runtimepath` or
`packpath` changes are not required.

### `module 'helper.utils' not found`

Confirm the repository is installed directly in the Neovim configuration
directory:

```vim
:echo stdpath('config')
```

That directory must directly contain `init.lua` and `lua/helper/utils.lua`.
There should not be another nested `nvim-config/` directory between them.

### Treesitter Cannot Find a Compiler

Check:

```vim
:echo executable('zig')
:echo $CC
:checkhealth nvim-treesitter
```

Windows requires Zig and the two wrappers in `bin/`. Linux and macOS require
GCC, Clang, or explicit `CC`/`CXX` variables. After fixing the compiler, run:

```vim
:TSUpdate
```

For parser ABI or `range` errors, uninstall and reinstall the affected parser:

```vim
:TSUninstall <language>
:TSInstall <language>
```

### C/C++ Standard Headers Are Missing

If `clangd` reports errors such as `'iostream' file not found`, first check
that a real C++ compiler is installed in the environment that starts Neovim.

Windows PowerShell with Scoop GCC:

```powershell
g++ --version
where g++
```

Linux/macOS:

```bash
g++ --version || clang++ --version
```

Then open a C or C++ buffer and check LSP:

```vim
:LspInfo
:Mason
```

Restart `clangd` after changing compiler installation or `PATH`:

```vim
:LspRestart clangd
```

If `Too many errors emitted, stopping now` appears, inspect the first real
diagnostic instead of the final summary:

```vim
:lua vim.diagnostic.setqflist()
:copen
```

For CMake, Meson, or larger projects, generate `compile_commands.json` so
`clangd` can use the same compiler flags as the build system.

### JDTLS Does Not Start

Check:

```vim
:echo $JAVA_HOME
:echo executable('java')
:LspInfo
:Mason
```

JDK 21 is required by this configuration. Start Neovim from a project root
containing `pom.xml`, `build.gradle`, `mvnw`, `gradlew`, or `.git`.

### Java Tests Do Not Run

Run:

```vim
:Lazy load neotest
:NeotestJava setup
```

Verify that the Maven or Gradle wrapper works outside Neovim. The
`vscode-java-test` `java-test` package is not managed through Mason here;
`neotest-java` and JUnit Console are used to avoid dependency conflicts.

### `gopls` Does Not Start or Update

Check the Go runtime and Mason:

```vim
:echo executable('go')
:LspInfo
:Mason
```

Then run `:MasonUpdate` and restart the server with `:LspRestart`.

### File Search or Grep Returns No Results

Check:

```vim
:echo executable('rg')
:echo executable('fzf')
```

FzfLua uses `rg` for files and live grep. Ensure the command is available in
the environment that starts Neovim.

### Linux Clipboard Does Not Work

Run:

```vim
:checkhealth provider
```

Install `wl-clipboard` on Wayland or `xclip`/`xsel` on X11, then restart the
terminal and Neovim.

### Dashboard Is Cropped or Shifted Up

The dashboard automatically hides `laststatus` and `showtabline`. If another
plugin forces them back on, check:

```vim
:set laststatus?
:set showtabline?
:set filetype?
```

The dashboard buffer should use `filetype=snacks_dashboard`; its open and close
events then hide and restore Lualine and Bufferline.

### Smear Cursor Is Too Bright or Distracting

Toggle it temporarily:

```vim
:SmearCursorToggle
```

To change its color or disable Insert-mode animation, edit the
`sphamba/smear-cursor.nvim` options in `lua/plugins/editor.lua`.

## References

- [Neovim installation](https://github.com/neovim/neovim/blob/master/INSTALL.md)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [Mason](https://github.com/mason-org/mason.nvim)
- [Blink completion](https://github.com/Saghen/blink.cmp)
- [CodeCompanion](https://github.com/olimorris/codecompanion.nvim)
- [CodeCompanion documentation](https://codecompanion.olimorris.dev/)
- [codex-acp](https://github.com/agentclientprotocol/codex-acp)
- [Snacks dashboard](https://github.com/folke/snacks.nvim)
- [Smear Cursor](https://github.com/sphamba/smear-cursor.nvim)
- [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls)
- [neotest-java](https://github.com/rcasia/neotest-java)


See [CONFIG_AUDIT.md](CONFIG_AUDIT.md) for the full configuration audit, fixes, and verification limits.
