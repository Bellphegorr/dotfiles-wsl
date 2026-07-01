# Dotfiles

Configurações pessoais para sincronizar entre máquinas.

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `bashrc` | Configuração do bash (aliases, PATH, tmux auto-start) |
| `profile` | Configuração de login shell (mise shims) |
| `gitconfig` | Configuração do git (nome, email) |
| `config/tmux/tmux.conf` | Configuração do tmux |
| `config/tmux/scripts/startup.sh` | Script de inicialização do tmux |
| `config/mise/config.toml` | Gerenciador de versões de ferramentas |
| `config/opencode/opencode.jsonc` | Configuração do opencode |

## Como usar

```bash
# Clonar em outra máquina
git clone <url> ~/dotfiles

# Ver histórico
git log --oneline
```
