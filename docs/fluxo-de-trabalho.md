# Fluxo de trabalho com o builder

> Um agente, quatro skills e o contexto do projeto em arquivos.
> Atualizado em 09/11/2026. Para o porquê desse desenho, veja
> [orquestracao-de-agentes.md](orquestracao-de-agentes.md).
>
> As regras e os artefatos compartilhados ficam em `config/agent-workflow/`.
> Este guia explica o uso no OpenCode; para instalação e particularidades do
> Copilot, veja [fluxo-copilot.md](fluxo-copilot.md).

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
    └── work/<tarefa>/   → plano e progresso de tarefas grandes
        ├── plan.md
        └── progress.md
```

## Adicionar outro harness

Não copie as skills nem os templates. Reuse `config/agent-workflow/` e crie
somente o adaptador específico do harness: perfil/instruções do agente,
instalação e descoberta das skills. Antes de declarar suporte, confirme que o
harness encontra e carrega `SKILL.md`, interpreta seu frontmatter e consegue
usar os arquivos ou recursos referenciados; valide também invocação,
permissões, aprovações e uma instalação repetida. Se o formato não for
compatível, prefira um adaptador ou gerador a manter cópias manuais.

## Instalação

**Uma vez por máquina:**

```bash
bash ~/dotfiles/config/opencode/scripts/install.sh
```

Cria symlinks para a configuração e os agentes do OpenCode, e instala as skills
compartilhadas em `~/.config/opencode/skills/`. O instalador do Copilot aponta
para as mesmas skills em `~/.copilot/skills/`. Os templates e o inicializador
ficam em `config/agent-workflow/`; ambos os instaladores apontam para essa
mesma fonte e para o comando `agent-workflow-init`.

Pode rodar de novo; arquivos diferentes vão para
`~/.local/state/opencode-dotfiles-backup/` antes de serem trocados. Reinicie o
OpenCode depois.

**Uma vez por projeto:**

```bash
cd ~/meu-projeto
agent-workflow-init .
```

Copia o `AGENTS.md` e os arquivos de memória a partir dos templates. Não
sobrescreve nada que já exista. Depois **preencha o `AGENTS.md`** com os
comandos reais do projeto.

## O agente: builder

Agente principal. Roda no modelo padrão do `opencode.jsonc` (DeepSeek V4.1
Flash). Trabalha sozinho, sem subagentes. Antes de mexer em qualquer coisa, lê o `AGENTS.md` e a memória.

| Pedido | O que ele faz |
| --- | --- |
| Pergunta ou explicação | Responde direto |
| Mudança pequena e clara | Implementa e valida direto |
| Mudança grande, ambígua ou arriscada | Usa `plan` e espera sua aprovação |
| Plano aprovado | Usa `implement`, uma tarefa por vez |
| Implementação pronta | Usa `review` |
| Você pede commit ou push | Usa `ship` |

Regras fixas: não amplia o escopo, não diz que passou sem rodar, e para depois
de duas tentativas falhas na mesma correção.

**Pede confirmação antes de:** `git commit`, `git push`, `git rebase`,
`git reset --hard`, `git clean`, `git restore`, `git checkout -- …`,
`git branch -D`, `git stash drop/clear` e `rm` recursivo. Vale também para
`git -C . commit` e para comandos encadeados com `&&`.

## As skills

Cada skill é um `SKILL.md` com o passo a passo de uma etapa. O agente vê só o
nome e a descrição; o conteúdo é lido quando ele decide usar a skill ou quando
você pede ("use a skill plan").

| Skill | O que faz | O que não faz |
| --- | --- | --- |
| `plan` | Cria `plan.md` de uma página (objetivo, critérios de aceite, tarefas, validação) e `progress.md` | Não escreve código; espera seu "ok" |
| `implement` | Executa **uma** tarefa do plano, valida e registra no `progress.md` | Não amplia escopo nem faz commit |
| `review` | Lê o diff, roda testes e lista achados por gravidade | Não edita nada |
| `ship` | Valida tudo e faz commit/push só dos arquivos certos | Só roda quando você pede; nunca força push |

> O `review` é feito pelo próprio builder. Para algo importante, rode numa
> sessão nova ou com outro modelo.

## O contexto do projeto

**`AGENTS.md`** — a peça mais importante. Comandos de teste, lint, typecheck e
build; invariantes; mapa das pastas; armadilhas; definição de pronto. O
OpenCode já carrega esse arquivo sozinho. Sem comandos reais, o agente não sabe
validar o que fez.

**`.agents/memory/`** — arquivos de texto que o agente lê no início e atualiza
quando aprende algo:

| Arquivo | Guarda |
| --- | --- |
| `decisions.md` | Decisões e o porquê, para não refazer o que foi descartado |
| `gotchas.md` | Erros que já custaram tempo: sintoma, causa e contorno |
| `handoff.md` | Onde parou e o próximo passo, para retomar outro dia |

A ideia: cada erro vira uma regra e não se repete. Você também pode editar.

**`.agents/work/<tarefa>/`** — plano e progresso de uma tarefa grande, criados
pela skill `plan` e atualizados pela `implement`.

## Um dia de uso

```bash
cd ~/meu-projeto
opencode            # escolha o agente "builder"
```

```text
Você:    Use a skill plan para adicionar exportação CSV no relatório.
         Critérios: botão no relatório; CSV com as colunas visíveis; teste passa.
Builder: [cria plan.md com 3 tarefas e espera]
Você:    ok, faça a tarefa 1
Builder: [implementa, roda testes, atualiza progress.md]
Você:    próxima
...
Você:    use a skill review
Você:    use a skill ship para commitar
```

Para mudanças pequenas, peça direto, sem plano.

## Limitações

- **T3 Code:** o seletor de agentes customizados ainda não aparece com
  OpenCode 2.x. Use a TUI (`opencode`) ou a CLI
  (`opencode run --agent builder "..."`).
- **Modelo:** no OpenCode 2, o `model` de um agente principal **não** define o
  modelo da sessão. Quem decide é o `model` global em
  `config/opencode/opencode.jsonc` (hoje o Flash, que vale também para o Build)
  ou o modelo escolhido no seletor da TUI/T3. O `model` no `builder.md` fica só
  como referência. Para trocar, mude o `opencode.jsonc` ou use
  `opencode run -m provider/modelo#variante`.
- **Variante:** pelo `opencode.jsonc` o Flash é aplicado, mas o export da sessão
  não registra o `#high`. Para garantir a variante, use `-m` ou o seletor.

## Onde estão os arquivos

| Caminho no dotfiles | O que é |
| --- | --- |
| `config/opencode/opencode.jsonc` | Configuração e modelo padrão |
| `config/opencode/agents/*.md` | O `builder` e os agentes legados `agent-0.2` e `planner-0.2` |
| `config/agent-workflow/skills/*/SKILL.md` | Skills compartilhadas com o Copilot |
| `config/agent-workflow/templates/` | Modelos compartilhados de `AGENTS.md` e memória |
| `config/agent-workflow/scripts/init-agent-workflow.sh` | Inicializador compartilhado de projeto |
| `config/opencode/scripts/install.sh` | Instala na máquina |
