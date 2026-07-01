# Dotfiles

Configurações pessoais para sincronizar entre máquinas.

## Arquivos

| Arquivo                            | Descrição                                             |
| ---------------------------------- | ----------------------------------------------------- |
| `bashrc`                           | Configuração do bash (aliases, PATH, tmux auto-start) |
| `profile`                          | Configuração de login shell (mise shims)              |
| `gitconfig`                        | Configuração do git (nome, email)                     |
| `config/tmux/tmux.conf`            | Configuração do tmux                                  |
| `config/tmux/scripts/startup.sh`   | Script de inicialização do tmux                       |
| `config/tmux/scripts/mksession.sh` | Script para criar sessões tmux                        |
| `config/mise/config.toml`          | Gerenciador de versões (mise)                         |
| `config/opencode/opencode.jsonc`   | Configuração do opencode                              |

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

### Editores

- VS Code
- Zed
- vim

## Como usar

```bash
# Clonar em outra máquina
git clone <url> ~/dotfiles

# Ver histórico
git log --oneline
```
