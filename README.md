# Dotfiles

Configurações pessoais para sincronizar entre máquinas.

## Começando

```bash
git clone <url> ~/dotfiles

# Harnesses (instale os que usa)
bash ~/dotfiles/config/opencode/scripts/install.sh
bash ~/dotfiles/config/copilot/scripts/install.sh

# Git no WSL (opcional)
bash ~/dotfiles/config/git/configure-gcm.sh
```

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
| `config/git/configure-gcm.sh` | Configura o GCM do Windows no Git do WSL |
| `config/tmux/` | Configuração, scripts de sessão e startup |
| `config/mise/config.toml` | Gerenciador de versões (mise) |
| `config/opencode/` | Configuração e perfil do OpenCode |
| `config/copilot/` | Perfil e instalador do Copilot CLI |
| `config/agent-workflow/` | Fonte do Builder, skills, templates e scripts |
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
- GitHub Copilot

O `config/opencode/opencode.jsonc` registra o MCP remoto do Notion. Em cada
máquina nova, autentique uma vez pelo `/mcps` do OpenCode.

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
