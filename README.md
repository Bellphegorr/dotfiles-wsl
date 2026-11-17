# Dotfiles

Configurações pessoais para sincronizar entre máquinas.

## Começando

```bash
git clone <url> ~/dotfiles

# Shell e startup do tmux
bash ~/dotfiles/scripts/install-shell.sh

# Harnesses (instale os que usa)
bash ~/dotfiles/config/opencode/scripts/install.sh
bash ~/dotfiles/config/copilot/scripts/install.sh

# T3 Code (opcional)
bash ~/dotfiles/config/t3code/scripts/install.sh

# Git no WSL (opcional)
bash ~/dotfiles/config/git/configure-gcm.sh
```

O instalador de shell copia `bashrc` para `~/.bashrc` e o `startup.sh` para
`~/.config/tmux/scripts/`. Pode ser rodado de novo após atualizar o repo: ele
atualiza apenas o que não foi editado localmente, guarda backup de cada
substituição em `~/.local/state/shell-dotfiles-backup/` e aborta se encontrar
uma edição local. Use `--force` para autorizar a substituição.

O fluxo de agentes é compartilhado entre **OpenCode** e **GitHub Copilot CLI**.
O Builder é o agente ativo; `Planner 0.2` e `Agent 0.2` foram aposentados.
Instalação, skills e uso estão em
[docs/fluxo-de-trabalho.md](docs/fluxo-de-trabalho.md).

Para preparar um projeto:

```bash
cd ~/meu-projeto
agent-workflow-init .
```

## Documentação

| Guia | Conteúdo |
| --- | --- |
| [Fluxo de trabalho](docs/fluxo-de-trabalho.md) | Builder, skills, memória, instalação e uso |
| [Multiagentes](docs/multiagentes.md) | Quando dividir trabalho e o que os pilotos mostraram |
| [Trabalho pesado com workers](docs/trabalho-pesado-com-workers.md) | Fatias independentes, papéis, gates e T3 |
| [Mapa de ferramentas](docs/mapa-de-ferramentas.md) | Camadas: modelos, harness, cockpit, MCP etc. |
| [Git no WSL (GCM)](docs/git-wsl-gcm.md) | Credential Manager do Windows e troubleshooting |
| [tmux](docs/tmux.md) | Sessões, scripts, plugins e restore |

## Estrutura

| Caminho | Descrição |
| --- | --- |
| `bashrc` / `profile` | Shell, aliases, PATH, mise e auto-start do tmux |
| `scripts/install-shell.sh` | Copia `bashrc` e `startup.sh` do tmux, com backup |
| `config/git/configure-gcm.sh` | Configura o GCM do Windows no Git do WSL |
| `config/tmux/` | Configuração, scripts de sessão e startup |
| `config/mise/config.toml` | Gerenciador de versões (mise) |
| `config/opencode/` | Configuração e perfil do OpenCode |
| `config/copilot/` | Perfil e instalador do Copilot CLI |
| `config/agent-workflow/` | Fonte do Builder, skills, templates e scripts |
| `config/t3code/` | Tema, keybindings e instalador do T3 Code |
| `docs/` | Guias detalhados (índice acima) |

O `~/.gitconfig` não é versionado: nome, email e credenciais são específicos de
cada máquina.

## Ferramentas

### Version Manager

- mise

### Containers

- Docker

### Terminal

- tmux
- bash

### AI

- opencode
- T3 Code
- GitHub Copilot

O `config/opencode/opencode.jsonc` registra o MCP remoto do Notion. Em cada
máquina nova, autentique uma vez pelo `/mcps` do OpenCode.

### T3 Code

O T3 Code não sincroniza configurações pela conta. Keybindings e tema ficam no
ambiente; aparência, fontes e tamanhos ficam em cada dispositivo. O instalador
acima publica os temas de `config/t3code/themes/` em `~/.t3/userdata/themes/` e
linka os keybindings. Por padrão ele ativa o `matte-black`; use
`T3CODE_DEFAULT_THEME=matte-black-minimal` para ativar o minimal já na
instalação.

O `matte-black-minimal` é uma variação opcional inspirada no Neovim: cantos
retos, interface monoespaçada, divisórias brancas, syntax highlight baseado no
`matteblack.nvim` e detalhes âmbar. Para ativá-lo depois da instalação:

```bash
t3 theme set matte-black-minimal --base-dir "$HOME/.t3"
```

Para voltar ao Matte Black original:

```bash
t3 theme set matte-black --base-dir "$HOME/.t3"
```

Em outra máquina que rode um servidor T3 próprio, rode o mesmo instalador. Se
ela apenas se conecta a este ambiente via T3 Connect, não precisa: tema,
keybindings, providers, projetos e threads vêm do servidor.

### Editores

- VS Code
- Zed
- vim

## Git no WSL (GCM)

As credenciais do Git no WSL ficam no Windows Credential Manager. Configuração,
verificação e troubleshooting em [docs/git-wsl-gcm.md](docs/git-wsl-gcm.md).

## tmux

Sessões com as janelas `agent`, `terminal` e `git`, além de restore automático.
Scripts, plugins e setup em [docs/tmux.md](docs/tmux.md).
