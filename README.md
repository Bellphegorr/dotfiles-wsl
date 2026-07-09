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

## TMUX

#### `startup.sh`

Restaura sessões tmux salvas ao abrir o primeiro terminal (cold start) ou apenas attacha se o servidor já estiver rodando.

- Restaura do snapshot `~/.local/share/tmux/resurrect/last` via `tmux-resurrect`.
- Se não houver snapshot, cria uma sessão `main` vazia.
- Necessita do plugin `tmux-resurrect` instalado (veja setup abaixo).

#### `mksession.sh`

Cria (ou conecta a) uma sessão tmux com as janelas `agent`, `terminal` e `git`.

```bash
# Usar defaults (sessão "projetos", diretório "~/projetos")
bash config/tmux/scripts/mksession.sh

# Sessão com nome e diretório personalizados
bash config/tmux/scripts/mksession.sh meuapp ~/code/meuapp
```

Se a sessão já existir, apenas conecta a ela (ou troca o cliente, se já estiver dentro do tmux).

#### Salvamento e restore

- **Auto-save**: a cada 10 minutos, via `tmux-continuum`.
- **Save manual**: dentro do tmux, `prefix + Ctrl + s` (binding do `tmux-resurrect`).
- **Restore**: acontece automaticamente no primeiro terminal após `wsl --shutdown`.

#### Setup em uma nova máquina

```bash
# Clonar o TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Baixar os plugins listados no tmux.conf
# Abra o tmux e rode:
# prefix + I
```

Depois disso, ao abrir um novo terminal o `startup.sh` restabelece as sessões salvas.

## Como usar

```bash
# Clonar em outra máquina
git clone <url> ~/dotfiles

# Ver histórico
git log --oneline
```
