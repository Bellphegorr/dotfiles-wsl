# Dotfiles

Configurações pessoais para sincronizar entre máquinas.

## Arquivos

| Arquivo                            | Descrição                                             |
| ---------------------------------- | ----------------------------------------------------- |
| `bashrc`                           | Configuração do bash (aliases, PATH, tmux auto-start) |
| `profile`                          | Configuração de login shell (mise shims)              |
| `config/git/configure-gcm.sh`      | Configura o GCM do Windows no Git do WSL              |
| `config/tmux/tmux.conf`            | Configuração do tmux                                  |
| `config/tmux/scripts/startup.sh`   | Script de inicialização do tmux                       |
| `config/tmux/scripts/mksession.sh` | Script para criar sessões tmux                        |
| `config/mise/config.toml`          | Gerenciador de versões (mise)                         |
| `config/opencode/opencode.jsonc`   | Configuração do opencode                              |
| `config/opencode/agents/*.md`      | Agentes do OpenCode (builder e legados)               |
| `config/copilot/agents/*.agent.md` | Agentes pessoais do GitHub Copilot                    |
| `config/agent-workflow/skills/*`   | Skills compartilhadas entre os harnesses              |
| `config/agent-workflow/templates/` | Templates compartilhados de contexto e memória        |
| `config/agent-workflow/agents/builder.md` | Texto único do Builder (`sync-agents.sh` gera os perfis) |
| `config/agent-workflow/scripts/init-agent-workflow.sh` | Inicializa o contexto de um projeto |
| `config/agent-workflow/scripts/check.sh` | Valida o fluxo de agentes num `HOME` descartável |
| `config/opencode/scripts/install.sh` | Instala a configuração pessoal do OpenCode          |
| `config/copilot/scripts/install.sh` | Instala agente Copilot e expõe skills comuns         |
| `docs/fluxo-de-trabalho.md`        | Como usar o builder, skills, memória e templates      |
| `docs/fluxo-copilot.md`            | Como usar o novo fluxo no Copilot                     |
| `docs/orquestracao-de-agentes.md`  | Orquestração de agentes e mapa de ferramentas         |

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

O `config/opencode/opencode.jsonc` também registra o MCP remoto do Notion.
Em cada máquina nova, autentique uma vez pelo `/mcps` do OpenCode.

Para instalar os agentes pessoais do Copilot no CLI:

```bash
bash ~/dotfiles/config/copilot/scripts/install.sh
```

O `Builder` oferece o fluxo novo. `Planner 0.2` e `Agent 0.2` permanecem
disponíveis como agentes legados. Veja [o guia do Copilot](docs/fluxo-copilot.md).

### Editores

- VS Code
- Zed
- vim

## Git no WSL (Git Credential Manager)

No WSL, o Git usa o **Git Credential Manager (GCM) do Windows** via interop.
As credenciais ficam no Windows Credential Manager, não em `~/.git-credentials`.

### Configuração

```bash
bash config/git/configure-gcm.sh --check  # verifica sem alterar
bash config/git/configure-gcm.sh          # aplica
```

O script detecta o WSL, localiza o `git-credential-manager.exe` (ou usa
`GCM_PATH`) e configura `credential.helper` e
`credential.https://github.com.provider`. Ele não altera `user.name`,
`user.email` nem credenciais salvas.

```bash
# GCM em outro caminho
GCM_PATH="/mnt/c/caminho/git-credential-manager.exe" bash config/git/configure-gcm.sh
```

### Como funciona

O `~/.gitconfig` fica com o helper apontando para o `.exe` do Windows. O WSL
executa esse binário via interop e o GCM guarda a credencial no **Windows
Credential Manager** (entrada `git:https://github.com`).

Para verificar:

```bash
git config --show-origin --get-all credential.helper
printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed 's/^password=.*/password=<oculto>/'
```

### Token embutido na URL

Se o remote tiver `https://ghp_xxxxxxxx@github.com/usuario/repo.git`, o Git usa
esse token **antes** do GCM. Se ele estiver expirado, o push falha com
`Invalid username or token`. Foi o que aconteceu neste repositório. Remova da
URL e reautentique:

```bash
git remote set-url origin https://github.com/usuario/repo.git
printf 'protocol=https\nhost=github.com\n\n' | git credential reject
git push
```

> **Segurança:** não deixe tokens em URLs ou arquivos versionados. Se um token
> foi exposto, revogue em https://github.com/settings/tokens.

### Limitações

- Só funciona no WSL com Git for Windows/GCM instalado; em Linux nativo use
  `libsecret`, `store` ou SSH.
- O GCM precisa de terminal interativo para abrir o login; em CI use token ou SSH.

## TMUX

#### `startup.sh`

Restaura sessões tmux salvas ao abrir o primeiro terminal (cold start) ou apenas attacha se o servidor já estiver rodando.

- Restaura do snapshot `~/.local/share/tmux/resurrect/last` via `tmux-resurrect`.
- Se não houver snapshot, cria uma sessão `main` vazia.
- Necessita do plugin `tmux-resurrect` instalado (veja setup abaixo).

#### `mksession.sh`

Cria (ou conecta a) uma sessão tmux com as janelas `agent`, `terminal` e `git`,
todas abertas no diretório informado.

```bash
# Usar defaults (sessão "projetos", diretório "~/projetos")
bash config/tmux/scripts/mksession.sh

# Sessão com nome e diretório personalizados
bash config/tmux/scripts/mksession.sh meuapp ~/code/meuapp
```

Para chamar de qualquer lugar, basta linkar o script em `~/.local/bin`
(diretório já presente no `PATH`):

```bash
ln -sf ~/dotfiles/config/tmux/scripts/mksession.sh ~/.local/bin/mksession
mksession meuapp ~/code/meuapp
```

O diretório aceita `~` e caminhos relativos, e precisa existir. Se a sessão já
existir, apenas conecta a ela (ou troca o cliente, se já estiver dentro do tmux).

#### Salvamento e restore

- **Auto-save**: a cada 10 minutos, via `tmux-continuum`.
- **Save manual**: dentro do tmux, `prefix + Ctrl + s` (binding do `tmux-resurrect`).
- **Restore**: acontece automaticamente no primeiro terminal após `wsl --shutdown`.

#### Setup em uma nova máquina

```bash
# Clonar o TPM
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Baixar os plugins listados no tmux.conf
# Abra o tmux e rode:
# prefix + I
```

Depois disso, ao abrir um novo terminal o `startup.sh` restabelece as sessões salvas.

## Como usar

```bash
# Clonar em outra máquina
git clone <url> ~/dotfiles

# Aplicar a configuração do Git no WSL (se aplicável)
bash ~/dotfiles/config/git/configure-gcm.sh

# Ver histórico
git log --oneline
```
