# Fluxo de trabalho com o builder

> Um agente, seis skills e o contexto do projeto em arquivos.
> Atualizado em 10/11/2026. Para o porquê desse desenho, veja
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
    └── work/<tarefa>/   → plano e progresso quando necessários
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

Ao adicionar uma skill nova, rode novamente o instalador do harness: os links
são individuais por skill. Alterar uma skill já ligada não exige reinstalar,
mas uma sessão em andamento pode precisar ser reiniciada para relê-la.

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
comandos reais e a política de branches do projeto. Projetos já inicializados
não recebem alterações de template automaticamente.

## O agente: builder

Agente principal. Roda no modelo padrão do `opencode.jsonc` (DeepSeek V4.1
Flash). Antes de
mexer em qualquer coisa, lê o `AGENTS.md` e a memória disponíveis. Se faltarem,
consulta as convenções do repositório, sem inventar comandos ou resultados.

| Pedido | O que ele faz |
| --- | --- |
| Pergunta ou explicação | Responde direto |
| Mudança pequena e clara | Usa `implement`, sem plano formal, e revisa o resultado |
| Incerteza, risco ou pedido de planejamento | Usa `plan`; continua se a execução já estiver autorizada e não houver decisão material pendente |
| Escopo ou plano autorizado | Executa uma unidade coerente por vez, sem novo “ok” por tarefa |
| Commit autorizado ou candidato final | Usa `review`, incluindo commits já feitos |
| Você pede commit, push ou PR | Usa `ship` apenas para as operações autorizadas |
| Você pede melhoria do processo | Usa `reflect` e propõe o menor ajuste útil |

Tocar vários arquivos não obriga a criar plano. Regras fixas: não amplia o
escopo, não enfraquece testes e não declara sucesso sem evidência. Duas
tentativas falhas exigem reavaliar o diagnóstico; não provocam uma devolução
automática ao humano nem justificam tentativas sem progresso.

## Autorização e pausas

Não há modos de execução para configurar. Um pedido explícito para
“implementar, validar, fazer commits e abrir PR” cobre essa sequência no
escopo definido, incluindo o push necessário, sem nova aprovação por etapa.
“Faça commit” não autoriza push; publicar ou abrir PR não autoriza merge,
release ou deploy. Perguntar, pedir apenas um plano ou dizer “termine” não
autoriza publicação.

Você pode acrescentar “pare depois do plano”, “pare a cada entrega” ou
“pare antes de publicar”. O builder respeita esses pontos e para também
quando precisa de uma decisão material ou encontra um bloqueio real.
Restrições do projeto continuam valendo.

**Permissões são outra camada.** O perfil do OpenCode mantém `ask` para
commit/push, rebase, comandos de descarte e `rm` recursivo, inclusive as formas
com opções globais de Git previstas no perfil. O Copilot segue as permissões
do próprio CLI e do ambiente. A autorização da tarefa não elimina esses
prompts. Este fluxo não altera permissões nem recomenda `--auto` nesta
máquina compartilhada: essa flag pode autoaprovar comandos marcados `ask`.

## Branch, validação e entrega

Antes de implementar, o builder confere o estado local, identifica a política
de branches e prepara uma branch de trabalho não protegida. Registra a base
de comparação e preserva alterações alheias, inclusive as já staged. Se
precisar de worktree no T3 Code, usa a ferramenta nativa para vinculá-la à
thread; uma worktree criada no shell não faz essa vinculação. Branch e
worktree não isolam execução nem credenciais.

Cada unidade recebe validação focada e review antes de um commit autorizado.
O conjunto final recebe revisão acumulada e as verificações completas
aplicáveis, após a última mudança material, sem repetir toda a suíte a cada
commit. O review considera commits, staged/unstaged e arquivos novos;
`git diff` vazio não prova que a branch não mudou.

Antes do push, confere remote, base e destino real: estar numa feature branch
não impede um push errado para `HEAD:main`. Nunca publica diretamente na
principal/protegida nem usa force push. Essas instruções não substituem
permissões do harness ou proteções no servidor.

Quando autorizado, abre um **draft PR** e confere CI no SHA publicado.
Pendentes, cancelados ou pulados não são “verde”; sem CI, declara validação
apenas local. No T3, usa os recursos nativos para vincular o PR e aguardar
checks quando necessário. O PR aberto não é prova de conclusão.

Se houver bloqueio, preserva o trabalho e relata o último estado validado,
as falhas e o que falta para avançar. Não descarta alterações nem commita
trabalho incompleto só para apresentar uma branch limpa.

## As skills

Cada skill é um `SKILL.md` com o passo a passo de uma etapa. O agente vê só o
nome e a descrição; o conteúdo é lido quando ele decide usar a skill ou quando
você pede ("use a skill plan").

| Skill | O que faz | O que não faz |
| --- | --- | --- |
| `plan` | Define resultado, limites, critérios e evidências; cria plano/progresso quando necessários | Não implementa; pedido só de plano termina no plano |
| `implement` | Executa uma unidade por vez, testa, revisa e usa `ship` para commits autorizados | Não exige plano artificial nem publica fora do pedido |
| `review` | Audita a unidade ou o conjunto final, incluindo commits e alterações locais | Não edita, commita, publica nem transforma aprovação técnica em autorização |
| `ship` | Faz commits, push da branch e draft PR quando autorizados; verifica evidências e CI | Não força push nem faz merge/release implícitos |
| `reflect` | Analisa atritos recorrentes e propõe o menor ajuste útil em regras ou ferramentas | Não muda skills/configurações silenciosamente nem cria algo sem necessidade |
| `notion-note` | Salva ou atualiza notas no Second Brain; requer o MCP do Notion | Regras detalhadas ficam no próprio `SKILL.md` |

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
| `handoff.md` | Estado, branch/base, evidências, bloqueios e próximo passo |

Uma falha comprovada pode virar teste ou lição; não é necessário inventar uma
regra após cada erro. Você também pode editar. Nunca guarde segredos ou
histórico de outros projetos nessa memória.

**`.agents/work/<tarefa>/`** — plano e progresso quando o trabalho justifica
esses artefatos, criados pela skill `plan` e atualizados durante a execução.

## Um dia de uso

```bash
cd ~/meu-projeto
opencode            # escolha o agente "builder"
```

```text
Você:    Implemente exportação CSV no relatório, com as colunas visíveis.
         Valide, faça commits pequenos e abra um PR.
Builder: [entende, faz plano curto se necessário e prepara a branch]
         [implementa, testa, revisa e commita unidades coerentes]
         [revisa o conjunto, valida, publica a branch e abre draft PR]
         [confere CI e relata resultado ou bloqueio com evidências]
```

Outros pedidos seguem o mesmo fluxo, com limites diferentes:

```text
Implemente X e valide, sem commit nem push.
Use plan para X e pare depois do plano.
Implemente X com commits locais; pare a cada entrega para eu avaliar.
```

Uma aprovação do plano autoriza sua implementação, não acrescenta commit ou
publicação se isso não fazia parte do pedido.

## Melhoria contínua com reflect

Peça, por exemplo: “Use reflect para avaliar os atritos desta tarefa e proponha
melhorias no nosso fluxo”. A skill confere a evidência e as regras existentes
antes de sugerir mudanças. Pode recomendar um teste, uma nota de memória, um
ajuste numa skill existente ou nenhuma alteração.

Ela não vasculha históricos de outros projetos nem altera skills, configurações
ou permissões por conta própria. O registro normal de fatos úteis do projeto
não exige rodar reflect depois de cada edição.

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
