# tmux

> Guia detalhado; o índice do repositório está no [README](../README.md).

## startup.sh

Restaura sessões tmux salvas ao abrir o primeiro terminal (cold start) ou apenas
attacha se o servidor já estiver rodando.

- Restaura do snapshot `~/.local/share/tmux/resurrect/last` via `tmux-resurrect`.
- Se não houver snapshot, cria uma sessão `main` vazia.
- Necessita do plugin `tmux-resurrect` instalado (veja setup abaixo).

## mksession.sh

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

## Salvamento e restore

- **Auto-save**: a cada 10 minutos, via `tmux-continuum`.
- **Save manual**: dentro do tmux, `prefix + Ctrl + s` (binding do `tmux-resurrect`).
- **Restore**: acontece automaticamente no primeiro terminal após `wsl --shutdown`.

## Setup em uma nova máquina

```bash
# Clonar o TPM
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Baixar os plugins listados no tmux.conf
# Abra o tmux e rode:
# prefix + I
```

Depois disso, ao abrir um novo terminal o `startup.sh` restabelece as sessões salvas.
