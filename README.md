# Dotfiles

Configurações pessoais do lado **WSL/Ubuntu** para sincronizar entre máquinas.
(O desktop Windows tem repo próprio: `my-dotfiles`.)

## Instalação

Cada unidade é independente. Depois de clonar, rode só o que for usar:

```bash
git clone <url> ~/dotfiles

# Shell: bashrc e profile -> ~/.bashrc e ~/.profile
bash ~/dotfiles/config/shell/scripts/install.sh

# tmux: tmux.conf, startup, auto-start e mksession -> ~/.config/tmux, ~/.local/bin
bash ~/dotfiles/config/tmux/scripts/install.sh

# Harnesses de agentes (instale os que usa)
bash ~/dotfiles/config/opencode/scripts/install.sh
bash ~/dotfiles/config/copilot/scripts/install.sh
bash ~/dotfiles/config/claude/scripts/install.sh

# Claude Code com config próprio (por exemplo, a instância do T3)
CLAUDE_CONFIG_DIR="$HOME/.claude_opencode_go" \
  bash ~/dotfiles/config/claude/scripts/install.sh

# T3 Code (tema e keybindings; T3CODE_DEFAULT_THEME=matte-black-minimal usa o minimal)
bash ~/dotfiles/config/t3code/scripts/install.sh

# Git no WSL (credential manager do Windows)
bash ~/dotfiles/config/git/configure-gcm.sh
```

Todos os instaladores podem ser rodados de novo após atualizar o repo:
atualizam apenas o que não foi editado localmente, guardam backup em
`~/.local/state/<tool>-dotfiles-backup/` e abortam se encontrarem uma edição
local (`--force` autoriza a substituição).

## Agentes

O fluxo de agentes é compartilhado entre OpenCode, GitHub Copilot CLI e Claude
Code; o Builder é o agente ativo. Instalação e uso em
[docs/fluxo-de-trabalho.md](docs/fluxo-de-trabalho.md). Para preparar um
projeto:

```bash
cd ~/meu-projeto && agent-workflow-init .
```

O `config/opencode/opencode.jsonc` registra o MCP remoto do Notion e o MCP
local do `browse`. Autentique o Notion uma vez por máquina pelo `/mcps`; o
`browse` é opcional e exige o binário em `~/.local/bin/browse`. O arquivo é
sincronizado entre máquinas: use `{env:HOME}` e `~` em vez de paths absolutos
e deixe segredos fora dele.

## Documentação

| Guia | Conteúdo |
| --- | --- |
| [Fluxo de trabalho](docs/fluxo-de-trabalho.md) | Builder, skills, memória e uso |
| [Orquestração](docs/orquestracao.md) | Quando dividir o trabalho |
| [T3 Code](docs/t3-code.md) | Tema, keybindings, threads e worktrees |
| [Mapa de ferramentas](docs/mapa-de-ferramentas.md) | Modelos, harness, cockpit e MCP |
| [Git no WSL](docs/git-wsl-gcm.md) | Credential Manager do Windows |
| [tmux](docs/tmux.md) | Sessões, scripts, plugins e restore |

## Estrutura

| Caminho | Conteúdo |
| --- | --- |
| `config/shell/` | `bashrc`, `profile` (prompt Matte Black) e instalador |
| `config/tmux/` | `tmux.conf`, instalador e scripts (`startup`, `autostart`, `mksession`) |
| `scripts/install-lib.sh` | Motor comum dos instaladores (conflito, backup, estado) |
| `config/agent-workflow/` | Builder, skills, templates e scripts |
| `config/opencode/`, `config/copilot/`, `config/claude/`, `config/t3code/` | Harnesses de agentes |
| `config/git/`, `config/mise/` | Git (GCM) e gerenciador de versões |
| `docs/` | Guias acima |
