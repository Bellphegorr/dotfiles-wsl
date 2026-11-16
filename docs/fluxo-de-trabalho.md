# Fluxo de trabalho com o builder

> Um agente, sete skills e o contexto do projeto em arquivos.
> Atualizado em 16/11/2026. Para o porquê desse desenho, veja
> [multiagentes.md](multiagentes.md).
>
> As regras e os artefatos compartilhados ficam em `config/agent-workflow/`.
> Harnesses usados: **OpenCode** e **GitHub Copilot CLI**. O fluxo e as skills
> são os mesmos; cada harness tem seu perfil e instalador.

## Visão geral

```text
dotfiles (instalado uma vez por máquina)
├── perfis      → um builder específico para cada harness
└── workflow    → skills, templates e inicializador compartilhados

cada projeto (criado uma vez por projeto)
├── AGENTS.md            → manual do projeto para o agente
└── .agents/
    ├── memory/          → o que vale lembrar entre sessões
    │   ├── decisions.md
    │   ├── gotchas.md
    │   └── handoff.md
    └── work/<tarefa>/   → plano e progresso quando necessários
        ├── plan.md
        └── progress.md
```

## Harnesses

| Harness | Perfil | Instalação | Como escolher o Builder |
| --- | --- | --- | --- |
| OpenCode | `config/opencode/agents/builder.md` | `bash config/opencode/scripts/install.sh` | TUI/CLI (`opencode`) |
| GitHub Copilot CLI | `config/copilot/agents/builder.agent.md` | `bash config/copilot/scripts/install.sh` | `/agent` |

O T3 Code é o cockpit usado com o OpenCode, não um harness separado. As skills
compartilhadas ficam em `~/.config/opencode/skills/` no OpenCode e em
`~/.copilot/skills/` no Copilot CLI. `notion-note` exige o MCP do Notion
configurado no harness escolhido.

## Adicionar outro harness

Não copie as skills nem os templates. Reuse `config/agent-workflow/` e crie
somente o adaptador específico do harness: perfil/instruções do agente,
instalação e descoberta das skills. Antes de declarar suporte, confirme que o
harness encontra e carrega `SKILL.md`, interpreta seu frontmatter e consegue
usar os arquivos ou recursos referenciados; valide também invocação,
permissões, aprovações e uma instalação repetida. Se o formato não for
compatível, prefira um adaptador ou gerador a manter cópias manuais.

## Editar o Builder

O texto do Builder fica só em `config/agent-workflow/agents/builder.md`. Cada
perfil (`config/opencode/agents/builder.md` e
`config/copilot/agents/builder.agent.md`) mantém apenas o próprio frontmatter
— modelo, permissões, descrição. Depois de editar o texto:

```bash
config/agent-workflow/scripts/sync-agents.sh   # reescreve o corpo dos perfis
config/agent-workflow/scripts/check.sh         # valida tudo num HOME descartável
```

O `check.sh` confere sintaxe dos scripts, perfis sincronizados, frontmatter das
skills, links locais da documentação, os dois instaladores (duas vezes) e o
inicializador, sem tocar no seu `HOME`.

## Instalação

**Uma vez por máquina, no harness que você usa:**

```bash
# OpenCode
bash ~/dotfiles/config/opencode/scripts/install.sh

# GitHub Copilot CLI
bash ~/dotfiles/config/copilot/scripts/install.sh
```

Cada instalador cria os links do respectivo perfil e expõe as mesmas skills
compartilhadas de `config/agent-workflow/`. Os templates e o inicializador
ficam nessa pasta; os dois instaladores apontam para a mesma fonte e para o
comando `agent-workflow-init`.

Ao adicionar uma skill nova ou aposentar um perfil, rode novamente o instalador
do harness: os links são individuais e links órfãos de skills/agentes são
removidos. Alterar uma skill já ligada não exige reinstalar, mas uma sessão em
andamento pode precisar ser reiniciada para relê-la.

Pode rodar de novo; arquivos diferentes vão para
`~/.local/state/*-dotfiles-backup/` antes de serem trocados. Reinicie o harness
depois.

**Uma vez por projeto:**

```bash
cd ~/meu-projeto
agent-workflow-init .
```

Copia o `AGENTS.md` e os arquivos de memória a partir dos templates. Não
sobrescreve nada que já exista. Depois **preencha o `AGENTS.md`** com os
comandos reais e a política de branches do projeto. Projetos já inicializados
não recebem alterações de template automaticamente.

## O agente: builder

Agente principal. Cada perfil usa o modelo e as permissões do harness. Antes
de mexer em qualquer coisa, lê o `AGENTS.md` e a memória disponíveis. Se
faltarem, consulta as convenções do repositório, sem inventar comandos ou
resultados.

Use um modelo bom para o papel. Nomes, preços e variantes mudam, então a
escolha fica na configuração, não no guia.

| Pedido | O que ele faz |
| --- | --- |
| Pergunta ou explicação | Responde direto |
| Mudança pequena e clara | Usa `implement`, sem plano formal, e revisa o resultado |
| Incerteza, risco ou pedido de planejamento | Usa `planning`; continua se a execução já estiver autorizada e não houver decisão material pendente |
| Escopo ou plano autorizado | Executa uma unidade coerente por vez, sem novo “ok” por tarefa |
| Trabalho grande com fatias independentes | Usa `orchestrate` |
| Commit ou candidato final | Usa `change-review`, incluindo commits já feitos |
| Você pede commit, push, PR ou release | Usa `ship` para executar o pedido |
| Você pede melhoria do processo | Usa `reflect` e propõe o menor ajuste útil |
| Você pede para salvar uma nota no Notion | Usa `notion-note`; requer o MCP do Notion |

Tocar vários arquivos não obriga a criar plano. Regras fixas: não amplia o
escopo, não enfraquece testes e não declara sucesso sem evidência. Duas
tentativas falhas exigem reavaliar o diagnóstico; não provocam uma devolução
automática ao humano nem justificam tentativas sem progresso.

## Autorização e pausas

Não há regra fixa de commit, push ou publicação: o pedido define o que fazer.
Você pode dizer “implemente e commite”, “não commite”, “dê push” ou “abra um PR”.
O agente segue o pedido no escopo definido, sem nova aprovação por etapa.

Você pode acrescentar “pare depois do plano”, “pare a cada entrega” ou
“pare antes de publicar”. O builder respeita esses pontos e para também
quando precisa de uma decisão material ou encontra um bloqueio real.
Restrições do projeto continuam valendo.

**Permissões são outra camada.** Cada harness aplica as próprias regras: no
OpenCode, push, rebase, comandos de descarte e `rm` recursivo pedem
confirmação; no Copilot, depende do modo de aprovação da sessão. A autorização
da tarefa não elimina esses prompts. Este fluxo não recomenda `--auto` nesta
máquina compartilhada.

## Branch, validação e entrega

Antes de implementar, o builder confere o estado local, identifica a política
de branches e prepara uma branch de trabalho não protegida. Registra a base
de comparação e preserva alterações alheias, inclusive as já staged. Se
precisar de worktree no T3 Code, usa a ferramenta nativa para vinculá-la à
thread; uma worktree criada no shell não faz essa vinculação. Branch e
worktree não isolam execução nem credenciais.

Cada unidade recebe validação focada e review antes da entrega.
O conjunto final recebe revisão acumulada e as verificações completas
aplicáveis, após a última mudança material, sem repetir toda a suíte a cada
commit. O review considera commits, staged/unstaged e arquivos novos;
`git diff` vazio não prova que a branch não mudou.

Antes do push, confere remote, base e destino real: estar numa feature branch
não impede um push errado para `HEAD:main`. Nunca publica diretamente na
principal/protegida nem usa force push. Essas instruções não substituem
permissões do harness ou proteções no servidor.

Quando o pedido inclui, abre um **draft PR** e confere CI no SHA publicado.
Pendentes, cancelados ou pulados não são “verde”; sem CI, declara validação
apenas local. No T3, usa os recursos nativos para vincular o PR e aguardar
checks quando necessário. O PR aberto não é prova de conclusão.

Se houver bloqueio, preserva o trabalho e relata o último estado validado,
as falhas e o que falta para avançar. Não descarta alterações nem commita
trabalho incompleto só para apresentar uma branch limpa.

## As skills

Cada skill é um `SKILL.md` com o passo a passo de uma etapa. O agente vê só o
nome e a descrição; o conteúdo é lido quando ele decide usar a skill ou quando
você pede ("use a skill planning"). As sete skills são compartilhadas pelos
dois harnesses.

| Skill | O que faz | O que não faz |
| --- | --- | --- |
| `planning` | Define resultado, limites, critérios e evidências; cria plano/progresso quando necessários | Não implementa; pedido só de plano termina no plano |
| `orchestrate` | Coordena trabalho grande com fatias independentes: briefs, workers, relatórios, verificação independente e gates | Não substitui `planning`/`implement`; não use em tarefa acoplada ou pequena |
| `implement` | Executa uma unidade por vez, testa, revisa e entrega conforme o pedido | Não exige plano artificial nem publica fora do pedido |
| `change-review` | Audita a unidade ou o conjunto final, incluindo commits e alterações locais | Não edita, commita, publica nem transforma aprovação técnica em autorização |
| `ship` | Executa commits, push, PR ou release quando o pedido pedir; verifica evidências e CI | Não força push nem faz merge/release implícitos |
| `reflect` | Analisa atritos recorrentes e propõe o menor ajuste útil em regras ou ferramentas | Não muda skills/configurações silenciosamente nem cria algo sem necessidade |
| `notion-note` | Salva ou atualiza notas no Second Brain; requer o MCP do Notion | Regras detalhadas ficam no próprio `SKILL.md` |

`orchestrate` só entra em trabalho grande; o playbook está em
[trabalho-pesado-com-workers.md](trabalho-pesado-com-workers.md). `notion-note`
fica fora do ciclo de código e exige o MCP do Notion.

> A revisão (`change-review`) é feita pelo próprio builder. Para algo
> importante, rode numa sessão nova ou com outro modelo.

## O contexto do projeto

**`AGENTS.md`** — a peça mais importante. Comandos de teste, lint, typecheck e
build; invariantes; mapa das pastas; armadilhas; definição de pronto. O harness
lê esse arquivo automaticamente quando aplicável. Sem comandos reais, o agente
não sabe validar o que fez.

**`.agents/memory/`** — arquivos de texto que o agente lê no início e atualiza
quando aprende algo:

| Arquivo | Guarda |
| --- | --- |
| `decisions.md` | Decisões e o porquê, para não refazer o que foi descartado |
| `gotchas.md` | Erros que já custaram tempo: sintoma, causa e contorno |
| `handoff.md` | Estado, branch/base, evidências, bloqueios e próximo passo |

Uma falha comprovada pode virar teste ou lição; não é necessário inventar uma
regra após cada erro. Você também pode editar. Nunca guarde segredos ou
histórico de outros projetos nessa memória.

**`.agents/work/<tarefa>/`** — plano e progresso quando o trabalho justifica
esses artefatos, criados pela skill `planning` e atualizados durante a execução.

## Um dia de uso

Abra o harness e escolha o Builder:

- **OpenCode:** `opencode`
- **Copilot CLI:** `copilot`, depois `/agent`

O Builder segue a linha do fluxo do Akita: um único agente que carrega a skill
de cada etapa, lê `AGENTS.md` e a memória do projeto e vai até onde você
autorizou, sem pedir aprovação a cada passo. O pedido define os limites.

### 1. Correção pequena

```text
Você:    Corrija o erro de digitação no help do mksession.sh e commite.
Builder: [sem plano formal: lê, corrige e roda uma checagem simples]
         [revisa o diff e commita na branch de trabalho, sem push]
         [relata o hash e o que validou]
```

Se preferir a mudança só no working tree, peça “não commite”.

### 2. Funcionalidade com pausa no plano

```text
Você:    Planeje e implemente X, mas me mostre o plano antes.
Builder: [cria .agents/work/<slug>/plan.md e progress.md e para]
Você:    Aprovado.
Builder: [implementa unidade por unidade: valida, revisa, atualiza o progresso]
         [entrega conforme o pedido]
```

A aprovação do plano autoriza a implementação no escopo definido.

### 3. Do pedido ao PR

```text
Você:    Implemente exportação CSV no relatório, com as colunas visíveis.
         Valide, faça commits pequenos e abra um PR.
Builder: [prepara a branch; planeja só se houver incerteza ou risco]
         [um commit por unidade validada e revisada]
         [validação completa no fim, push só da branch e PR em draft]
         [relata SHA e estado do CI; sem CI, diz que a validação foi local]
```

As permissões de cada harness continuam valendo.

### 4. Melhorar o próprio fluxo

```text
Você:    Use reflect: você pediu aprovação demais nessa tarefa.
Builder: [examina a conversa e o progresso e propõe a menor mudança]
         [espera você aceitar antes de mexer em skill ou configuração]
```

Em todos os casos, ele pergunta só quando falta uma decisão de escopo, design
ou acesso; num bloqueio, preserva o trabalho e relata o último estado
validado. O uso de subagentes fica a critério do harness. Para trabalho grande
com fatias independentes, use a skill `orchestrate`; fora disso, o builder
resolve sozinho. Para salvar uma nota, peça “use notion-note para registrar
...”; a skill exige o MCP do Notion.

## Melhoria contínua com reflect

Peça, por exemplo: “Use reflect para avaliar os atritos desta tarefa e proponha
melhorias no nosso fluxo”. A skill confere a evidência e as regras existentes
antes de sugerir mudanças. Pode recomendar um teste, uma nota de memória, um
ajuste numa skill existente ou nenhuma alteração.

Ela não vasculha históricos de outros projetos nem altera skills, configurações
ou permissões por conta própria. O registro normal de fatos úteis do projeto
não exige rodar reflect depois de cada edição.

## Limitações do OpenCode

- **T3 Code:** o seletor de agentes customizados ainda não aparece com
  OpenCode 2.x. Use a TUI (`opencode`) ou a CLI
  (`opencode run --agent builder "..."`).
- **Modelo:** no OpenCode 2, o `model` de um agente principal **não** define o
  modelo da sessão. Quem decide é o `model` global em
  `config/opencode/opencode.jsonc` ou o modelo escolhido no seletor da TUI/T3.
  O `model` no `builder.md` fica só como referência. Para trocar, mude o
  `opencode.jsonc` ou use `opencode run -m provider/modelo`.
- **Variante:** a variante escolhida no `opencode.jsonc` pode não aparecer no
  export da sessão. Para garantir, use `-m` ou o seletor.

## Notas do Copilot CLI

O Copilot CLI segue o modo de aprovação e a configuração de MCP do próprio
CLI; o perfil em `config/copilot/agents/builder.agent.md` não define modelo nem
permissões. Use `/agent` para escolher o Builder.

## Onde estão os arquivos

| Caminho no dotfiles | O que é |
| --- | --- |
| `config/opencode/opencode.jsonc` | Configuração do OpenCode |
| `config/opencode/agents/builder.md` | Perfil do OpenCode (frontmatter + corpo gerado) |
| `config/copilot/agents/builder.agent.md` | Perfil do Copilot CLI (frontmatter + corpo gerado) |
| `config/agent-workflow/agents/builder.md` | Texto único do Builder, usado pelos dois harnesses |
| `config/agent-workflow/scripts/sync-agents.sh` | Copia esse texto para os perfis (`--check` só verifica) |
| `config/agent-workflow/scripts/check.sh` | Validação completa do fluxo, sem tocar no `HOME` |
| `config/agent-workflow/skills/*/SKILL.md` | Skills compartilhadas pelos harnesses |
| `config/agent-workflow/templates/` | Modelos compartilhados de `AGENTS.md` e memória |
| `config/agent-workflow/scripts/init-agent-workflow.sh` | Inicializador compartilhado de projeto |
| `config/opencode/scripts/install.sh` | Instala o perfil e as skills no OpenCode |
| `config/copilot/scripts/install.sh` | Instala o perfil e as skills no Copilot CLI |
