#!/usr/bin/env bash
# Functional checks after install.sh: runs each tool on a small real task rather
# than just asking for its version. Prints PASS/FAIL per check, exits non-zero on any FAIL.
#   test/verify.sh          # headless checks
#   test/verify.sh --gui    # also launch GUI apps under a virtual X display
set -uo pipefail

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/.local/bin:$PYENV_ROOT/shims:$PYENV_ROOT/bin:$HOME/.cargo/bin:$HOME/.elan/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
SETUP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV="$HOME/.virtualenvs/neovim"
LAZY="$HOME/.local/share/nvim/lazy"
WORK="$(mktemp -d)"
cd "$WORK"

failures=()
check() {
    local name="$1"
    shift
    local out
    if out="$(timeout 600 bash -c "$*" 2>&1)"; then
        printf '\033[32mPASS\033[0m  %s\n' "$name"
    else
        printf '\033[31mFAIL\033[0m  %s\n' "$name"
        printf '%s\n' "$out" | tail -n 15 | sed 's/^/      /'
        failures+=("$name")
    fi
}

section() { printf '\n\033[1m%s\033[0m\n' "$*"; }

section "shell"
check "login shell finds pyenv, nvim, tmux, go, node" \
    'bash -ic "command -v pyenv nvim tmux go node cargo lean" 2>/dev/null | wc -l | grep -qx 7'

section "python"
check "python stdlib modules built (ssl sqlite3 bz2 lzma readline ctypes tkinter)" \
    'python -c "import ssl, sqlite3, bz2, lzma, readline, ctypes, tkinter, zlib; print(ssl.OPENSSL_VERSION)"'
check "neovim venv packages import" \
    "$VENV/bin/python -c 'import pynvim, jupyter_client, cairosvg, plotly, pnglatex, pylatexenc, jupytext'"
check "jupyter kernel executes code" "$VENV/bin/python - <<'EOF'
from jupyter_client.manager import start_new_kernel
km, kc = start_new_kernel(kernel_name='python3')
msg_id = kc.execute('print(6*7)')
while True:
    m = kc.get_iopub_msg(timeout=30)
    if m['msg_type'] == 'stream':
        assert m['content']['text'].strip() == '42', m
        break
km.shutdown_kernel()
EOF"

section "neovim"
check "starts with config, no startup errors" \
    'nvim --headless "+lua if #vim.v.errmsg > 0 then print(vim.v.errmsg) vim.cmd(\"cquit 1\") end" +qa'
check "python3 provider uses ~/.virtualenvs/neovim" \
    'nvim --headless "+lua if vim.fn.has(\"python3\") ~= 1 then vim.cmd(\"cquit 1\") end" +qa'
check "all lazy.nvim plugins installed" \
    'nvim --headless "+lua local bad={} for _,p in ipairs(require(\"lazy\").plugins()) do if not p._.installed then table.insert(bad,p.name) end end if #bad>0 then io.stderr:write(table.concat(bad,\" \")) vim.cmd(\"cquit 1\") end" +qa'
check "telescope-fzf-native compiled" "ls $LAZY/telescope-fzf-native.nvim/build/libfzf.so"
check "markdown-preview node deps installed" "test -d $LAZY/markdown-preview.nvim/app/node_modules"
check "molten remote plugin registered" "grep -q MoltenInit $HOME/.local/share/nvim/rplugin.vim"
check "treesitter parsers load (python c lua markdown latex)" \
    'nvim --headless "+lua for _,l in ipairs({\"python\",\"c\",\"lua\",\"markdown\",\"latex\"}) do assert(vim.treesitter.language.add(l), l) end" +qa'
# Compare against the deployed config's ensure_installed list. clangd/clang-format
# have no mason build on linux-arm64; install.sh gets them from apt instead.
check "mason tools from the config installed" '
    pending=$(nvim --headless "+luafile $SETUP_DIR/lib/mason_pending.lua" +qa 2>/dev/null | grep -vxE "clangd|clang-format")
    [[ -z "$pending" ]] || { echo "missing: $pending"; exit 1; }'
check "clangd + clang-format available (mason or apt)" 'command -v clangd && command -v clang-format'

# Open a real file per language and wait for the server to attach.
printf 'x = 1\n' >t.py
printf 'int main(void) { return 0; }\n' >t.c
printf 'package main\nfunc main() {}\n' >t.go
printf 'module t\n\ngo 1.26\n' >go.mod
printf 'local x = 1\n' >t.lua
printf 'echo hi\n' >t.sh
for pair in t.py:pyright t.c:clangd t.go:gopls t.lua:lua_ls t.sh:bashls t.py:cspell_ls; do
    file="${pair%%:*}" server="${pair##*:}"
    check "LSP $server attaches to $file" \
        "nvim --headless $file '+lua local ok = vim.wait(30000, function() return #vim.lsp.get_clients({bufnr=0, name=\"$server\"}) > 0 end, 200) vim.cmd(ok and \"qa!\" or \"cquit 1\")'"
done

printf 'local   x =   1\n' >fmt.lua
check "conform formats on save (stylua)" \
    "nvim --headless fmt.lua '+lua vim.wait(3000)' +w +qa && grep -qx 'local x = 1' fmt.lua"

section "tmux"
check "tmux loads config + tpm plugins (resurrect, continuum, theme)" '
    tmux -L verify new-session -d -s v &&
    sleep 2 &&
    tmux -L verify list-keys -T root | grep -Eq "M-Left +select-pane -L" &&
    tmux -L verify show-options -g status-right | grep -q continuum_save &&
    tmux -L verify show-options -g @resurrect-save-script-path | grep -q tmux-resurrect &&
    tmux -L verify list-keys -T copy-mode-vi | grep -q "copy-pipe-no-clear \"xclip" &&
    test -x ~/.tmux/plugins/tmux-resurrect/strategies/nvim_nvimsession.sh
    rc=$?; tmux -L verify kill-server; exit $rc'

section "build tools + languages"
cat >hello.c <<'EOF'
#include <stdio.h>
int main(void) { puts("hello"); return 0; }
EOF
check "gcc compiles and runs C" 'gcc hello.c -o hello_gcc && ./hello_gcc | grep -qx hello'
mkdir -p cm && cp hello.c cm/ && printf 'cmake_minimum_required(VERSION 3.20)\nproject(h C)\nadd_executable(h hello.c)\n' >cm/CMakeLists.txt
check "cmake configures + builds" 'cmake -S cm -B cm/build >/dev/null && cmake --build cm/build >/dev/null && cm/build/h | grep -qx hello'
printf 'greet:\n    @echo just-ok\n' >justfile
check "just runs a recipe" 'just greet | grep -qx just-ok'
mkdir -p bz && cd bz && printf '9.3.1\n' >.bazelversion && touch MODULE.bazel &&
    printf 'genrule(name="g", outs=["o.txt"], cmd="echo bazel-ok > $@")\n' >BUILD && cd ..
check "bazel (bazelisk) downloads bazel + builds a genrule" \
    'cd bz && bazel build //:g >/dev/null 2>&1 && grep -qx bazel-ok bazel-bin/o.txt; rc=$?; bazel shutdown >/dev/null 2>&1; exit $rc'
check "go builds and runs" 'printf "package main\nimport \"fmt\"\nfunc main() { fmt.Println(\"go-ok\") }\n" >t.go && go run t.go | grep -qx go-ok'
check "cargo builds and runs" 'cargo new -q rs && cd rs && cargo run -q | grep -qx "Hello, world!"'
check "node runs" 'node -e "console.log(6*7)" | grep -qx 42'
check "brew installs a formula" 'brew install -q hello >/dev/null && hello | grep -q "Hello, world"'
check "git clone works (https)" 'git clone -q --depth 1 https://github.com/tmux-plugins/tpm tpm-clone'
check "rg / fd / fzf work" 'rg -q hello hello.c && fd -q hello.c && echo a | fzf -f a | grep -qx a'

section "notebook / docs tooling"
check "quarto renders a document" 'printf -- "---\ntitle: t\n---\n\nquarto-ok\n" >q.qmd && quarto render q.qmd --to html --quiet && grep -q quarto-ok q.html'
check "utftex renders LaTeX" 'utftex "\\frac{a}{b}" | grep -q "─"'
check "imagemagick converts" 'convert -size 10x10 xc:red r.png && file r.png | grep -q PNG'
check "rocq/coq checks a proof" 'printf "Theorem t : 1 + 1 = 2.\nProof. reflexivity. Qed.\n" >t.v && coqc t.v'
check "lean checks a proof" 'printf "theorem t : 1 + 1 = 2 := rfl\n" >t.lean && lean t.lean'

section "dotfiles"
check "chezmoi applied (only lazy-lock.json may differ)" \
    'chezmoi status | grep -v "lazy-lock.json" | grep -q . && { chezmoi status; exit 1; } || true'

if [[ "${1:-}" == --gui ]]; then
    section "GUI (virtual X display)"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq xvfb xauth libgl1-mesa-dri dbus-x11 >/dev/null
    check "JetBrainsMono Nerd Font registered" 'fc-list | grep -q "JetBrainsMono Nerd Font"'
    check "kitty opens a window and runs a command" \
        'rm -f k.ok; xvfb-run -a -s "-screen 0 1280x800x24" timeout 30 kitty sh -c "echo ok > $PWD/k.ok" ; test -f k.ok'
    check "ghostty opens a window and runs a command" \
        'rm -f g.ok; xvfb-run -a -s "-screen 0 1280x800x24" dbus-run-session -- timeout 30 ghostty --gtk-single-instance=false -e sh -c "echo ok > $PWD/g.ok; sleep 1"; test -f g.ok'
    check "zathura starts" 'xvfb-run -a timeout 5 zathura --version'
    check "latexmk builds a PDF" 'printf "\\\\documentclass{article}\\\\begin{document}hi\\\\end{document}\n" >d.tex && latexmk -pdf -quiet d.tex >/dev/null && file d.pdf | grep -q PDF'
    if command -v google-chrome >/dev/null; then
        check "chrome renders a page headless" \
            "google-chrome --headless=new --no-sandbox --disable-gpu --dump-dom 'data:text/html,<p>chrome-ok</p>' | grep -q chrome-ok"
    else
        printf '\033[33mSKIP\033[0m  chrome (not installed on %s)\n' "$(uname -m)"
    fi
fi

printf '\n%d failed\n' "${#failures[@]}"
[[ ${#failures[@]} -eq 0 ]]
