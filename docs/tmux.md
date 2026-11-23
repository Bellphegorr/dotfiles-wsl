# tmux

> Guia detalhado; o índice do repositório está no [README](../README.md).

## startup.sh

Restaura sessões tmux salvas ao abrir o primeiro terminal (cold start) ou apenas
attacha se o servidor já estiver rodando.

- Restaura do snapshot `~/.local/share/tmux/resurrect/last` via `tmux-resurrect`.
- Se não houver snapshot, cria uma sessão `main` vazia.
- Necessita do plugin `tmux-resurrect` instalado (veja setup abaixo).
- É disparado pelo `autostart.sh` — um hook que o instalador do tmux deixa no
  `bashrc` (só um `source`; a lógica do tmux vive toda aqui).

## mksession.sh

Cria (ou conecta a) uma sessão tmux com as janelas `agent`, `terminal` e `git`,
todas abertas no diretório informado.

```bash
# Usar defaults (sessão "projetos", diretório "~/projetos")
bash config/tmux/scripts/mksession.sh

# Sessão com nome e diretório personalizados
bash config/tmux/scripts/mksession.sh meuapp ~/code/meuapp
```

Para chamar de qualquer lugar, o instalador do tmux cria o symlink em
`~/.local/bin` (diretório já presente no `PATH`). Para refazer manualmente:

```bash
ln -sf ~/dotfiles/config/tmux/scripts/mksession.sh ~/.local/bin/mksession
mksession meuapp ~/code/meuapp
```

O diretório aceita `~` e caminhos relativos, e precisa existir. Se a sessão já
existir, apenas conecta a ela (ou troca o cliente, se já estiver dentro do tmux).

## Tema Matte Black

O tema é o bloco oficial do
[tmux.conf do Omarchy](https://github.com/omacom/omarchy/blob/quattro/config/tmux/tmux.conf):
barra no topo e transparente (`bg=default`), sessão num chip laranja
(`fg=black,bg=blue`), janela ativa em laranja (`fg=blue`), janelas
inativas e hostname em `brightblack`, indicadores COPY/PREFIX/ZOOM no
status-right, divisórias `brightblack` com a ativa em `blue`, e seleção do
copy-mode `bg=blue,fg=black`. O truque do oficial é usar nomes ANSI em vez
de hex: as cores reais vêm do esquema "Matte Black" do Windows Terminal
(blue `#E68E0D`, brightBlack `#8A8A8D`), então o mesmo bloco funciona com
qualquer tema. O autor do tema (tahayvr) não publica tmux — o repo dele
cobre waybar, Ghostty, Alacritty, Neovim, VS Code, Zed e iTerm2. O ícone
de auto-save do continuum continua injetado no status-right; atalhos,
plugins e nomes de janela do `mksession.sh` seguem como antes.
Divergências deliberadas do oficial: sem `bold` no chip e na janela ativa,
porque este terminal clareia texto bold para a variante bright do esquema
(a janela ativa sairia `#f59e0b` em vez de `#e68e0d`); e os
`window-status-*-style` são resetados (o `source-file` não limpa opções
antigas), com activity/bell no `reverse` nativo do tmux, como no oficial.
Recarregue com `prefix + r`.

## Salvamento e restore

- **Auto-save**: a cada 10 minutos, via `tmux-continuum`.
- **Save manual**: dentro do tmux, `prefix + Ctrl + s` (binding do `tmux-resurrect`).
- **Restore**: acontece automaticamente no primeiro terminal após `wsl --shutdown`.

## Setup em uma nova máquina

```bash
# Instalar tmux.conf, scripts (startup, autostart) e o symlink do mksession
bash ~/dotfiles/config/tmux/scripts/install.sh

# Clonar o TPM
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Baixar os plugins listados no tmux.conf
# Abra o tmux e rode:
# prefix + I
```

Depois disso, ao abrir um novo terminal o `startup.sh` restabelece as sessões salvas.
