# Dotfiles

Configurações pessoais do lado **WSL/Ubuntu** para sincronizar entre máquinas.
(O desktop Windows tem repo próprio: `my-dotfiles`.)

## Instalação

Cada unidade é independente. O `install.sh` da raiz é só um dispatcher fino:
os scripts por ferramenta continuam sendo a fonte da verdade.

```bash
git clone <url> ~/dotfiles
bash ~/dotfiles/install.sh --help
bash ~/dotfiles/install.sh all        # shell, tmux, opencode, claude, copilot, t3code
bash ~/dotfiles/install.sh verify     # somente leitura; exit 1 se houver drift
```

Rode só o que for usar: `bash ~/dotfiles/install.sh shell`, `tmux`,
`opencode`, `claude`, `copilot` ou `t3code`. O `all` não inclui `git`; para o
credential manager do Windows use `bash ~/dotfiles/install.sh git` (ou
`config/git/configure-gcm.sh`).

Para a instância do Claude do T3:

```bash
CLAUDE_CONFIG_DIR="$HOME/.claude_opencode_go" \
  bash ~/dotfiles/install.sh claude
```

Todos os instaladores podem ser rodados de novo após atualizar o repo:
atualizam apenas o que não foi editado localmente, guardam backup em
`~/.local/state/<tool>-dotfiles-backup/` e abortam se encontrarem uma edição
local (`--force` autoriza a substituição). `--verify` só relata o estado
(`ok`, `missing`, `outdated`, `differs`, `stale`) e não escreve nada; o
dispatcher aceita `--force` e o encaminha aos instaladores.

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
| `install.sh` | Dispatcher fino dos instaladores (`all`, `verify`, `--force`) |
| `config/shell/` | `bashrc`, `profile` (prompt Matte Black) e instalador |
| `config/tmux/` | `tmux.conf`, instalador e scripts (`startup`, `autostart`, `mksession`) |
| `scripts/install-lib.sh` | Motor comum dos instaladores (cópia, link, conflito, backup e verify) |
| `config/agent-workflow/` | Builder, skills, templates e scripts |
| `config/opencode/`, `config/copilot/`, `config/claude/`, `config/t3code/` | Harnesses de agentes |
| `config/git/`, `config/mise/` | Git (GCM) e gerenciador de versões |
| `docs/` | Guias acima |
