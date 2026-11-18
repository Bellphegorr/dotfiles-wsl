# T3 Code

> Cockpit usado com o OpenCode, não um harness separado. Tema, keybindings,
> instalação e mecânica de orquestração (threads, worktrees, permissões). O
> fluxo diário está em [fluxo-de-trabalho.md](fluxo-de-trabalho.md); a
> orquestração, em [orquestracao.md](orquestracao.md).

## Instalação

```bash
bash ~/dotfiles/config/t3code/scripts/install.sh
```

O T3 Code não sincroniza configurações pela conta. Keybindings e tema ficam no
ambiente; aparência, fontes e tamanhos ficam em cada dispositivo. O instalador
publica os temas de `config/t3code/themes/` em `~/.t3/userdata/themes/` e linka
os keybindings. Por padrão ele ativa o `matte-black`; use
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

## Orquestração no T3

- `delegate_task` por worker, com `role: implementation`;
- `isolation: "worktree"` quando a raiz do projeto for o repo; caso contrário,
  worktree manual + `isolation: "shared"` com caminho absoluto;
- `create_threads` só para fan-out em lote sem lineage; prefira `delegate_task`
  quando precisar de aprovações e resultado amarrado ao pai;
- `t3_thread_read` para relatórios e `task_cancel` para abortar;
- `schedule_task` para auditorias recorrentes;
- `watch_pull_request` para CI;
- em linked environment, o filho pode rodar em outra máquina e o resultado
  acorda a thread original.

O filho nunca recebe mais permissão que o pai. Aprovações sobem para a thread
pai; Stop na pai para os subagentes. Uma worktree criada no shell não é
vinculada à thread: use a ferramenta nativa. Worktree não isola execução nem
credenciais.

## Pilotos (nov/2026)

1. **Research read-only.** Três agentes com escopos independentes, em paralelo,
   produziram relatórios curtos em ~4 min, sem editar arquivo. Funcionou bem
   para inventário e auditoria.
2. **Implementação.** Duas fatias independentes em worktrees separadas, com
   merge limpo e suíte completa verde. O contrato foi o que garantiu a
   independência: cada worker só podia editar os próprios arquivos.
3. **Review independente.** Um revisor separado, vendo só diff e critério de
   aceite, encontrou um bug de Unicode que os testes dos implementadores não
   pegavam. O pai corrigiu e adicionou regressão.

Lições: um dono por arquivo/área, brief autossuficiente e relatório curto, e o
verificador independente pega o que o executor não vê. `isolation: "worktree"`
exige um projeto cuja raiz seja o repo; no scratch, use worktree manual ou um
projeto dedicado.
