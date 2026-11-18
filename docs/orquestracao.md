# Orquestração: quando dividir e como fazer

> Quando vale dividir o trabalho entre agentes e o passo a passo para quando
> vale. **Não é o fluxo padrão.** O dia a dia está em
> [fluxo-de-trabalho.md](fluxo-de-trabalho.md); as camadas de ferramentas, em
> [mapa-de-ferramentas.md](mapa-de-ferramentas.md).
>
> As seções 1 a 3 decidem **se** vale dividir. Da seção 4 em diante está o modo
> pesado, para quem já decidiu. Atualizado em 18/11/2026.

## 1. O conceito

Orquestrar é dividir um trabalho entre agentes com contextos separados, em vez
de pedir tudo a um modelo só. O desenho clássico:

```text
Você
└── Orquestrador — planeja, divide e revisa
    └── Executor — implementa, testa e reporta
```

A promessa: contexto limpo para o executor e o orquestrador cuidando do
planejamento e da revisão, sem carregar o histórico inteiro.

Trocar de modelo à mão no meio da conversa **não** é orquestração; é
roteamento manual.

## 2. Na prática: um agente bom ganha

Os testes do Akita (nov/2026) mostram que, para código do dia a dia, a promessa
não se paga:

- Um modelo bom sozinho no OpenCode: **97/100, 18 min, ~$4**.
- Planejador + executor: **90–95/100, +7 a +35 min**. Nenhuma combinação bateu
  o solo em qualidade, tempo e custo ao mesmo tempo.
- Uma cadeia de 10 agentes com 90% de acerto por etapa acerta ~35% no fim.
- A Anthropic reporta ~15x mais tokens em multi-agente e cita código como um
  domínio ruim para isso.

O motivo: código é trabalho acoplado. Cada peça depende da outra, então dividir
só adiciona repasse de contexto, latência e retrabalho. É como `Promise.all` em
chamadas que dependem umas das outras: não paraleliza nada.

O que funciona melhor:

- **um agente por projeto**, com um modelo bom para a tarefa;
- **skills** (`SKILL.md`) para procedimentos recorrentes;
- **`AGENTS.md`** com comandos, invariantes e armadilhas;
- **memória em arquivo** por projeto;
- **verificação** por testes, CI e revisão humana;
- **falhas comprovadas viram testes ou lições úteis**, sem criar regras
  automaticamente para cada erro.

É o que o [fluxo do builder](fluxo-de-trabalho.md) implementa. O uso de
subagentes fica a cargo do harness, sem regras adicionais nos perfis do
Builder. A escolha de modelo segue a mesma regra — um modelo bom para o papel;
nomes, preços e variantes mudam, então a escolha fica na configuração.

### O que adaptamos do Akita

Mantemos um agente como ponto de entrada e usamos as skills como procedimentos,
sem adicionar modos de execução ou um novo orquestrador. As instruções foram
adaptadas ao nosso ambiente, não copiadas com as premissas pessoais dele:

| No nosso fluxo | Referência do Akita |
| --- | --- |
| `planning`: resultado e evidência proporcional | `verification-planning` |
| `implement`: uma unidade, teste, revisão e entrega conforme o pedido | `github-resolution` |
| `change-review`: evidência independente e revisão do conjunto final | `pr-audit`, `pr-post-audit` |
| Critério de clareza dentro de `change-review`, sem skill extra | `simplify` |
| `reflect`: melhorar o processo com evidência e aprovação | `reflect` |
| `ship`: entrega conforme o pedido e checks no SHA entregue | Limites de `github-resolution` e `release` |

O pedido do usuário define o caminho até o PR e as pausas, em linguagem comum,
como "pare a cada entrega". Isso reduz aprovações repetidas do procedimento,
não as permissões reais do harness.

Nosso ponto de entrega é **draft PR**, sem merge, release ou deploy implícito.
O fluxo dele também prevê merges autorizados. Não importamos o pipeline
inteiro, especialistas obrigatórios, limiares por quantidade de tickets,
limpeza automática ou uma skill para worktrees: no T3, a vinculação da worktree
é responsabilidade das ferramentas nativas. Worktree não isola execução.

Kaizen é a prática de aprender com o trabalho; a skill pública usada como
referência para essa reflexão chama-se `reflect`. Ela pode concluir que nada
precisa mudar. Mudanças nas próprias skills/configurações exigem aprovação;
não há obrigação de criar uma nova regra após cada tarefa.

### O que os pilotos no T3 mostraram

Em nov/2026 rodei três pilotos com o T3 Code:

1. **Research read-only.** Três agentes com escopos independentes, em paralelo,
   produziram relatórios curtos em ~4 min, sem editar arquivo. Funcionou bem
   para inventário e auditoria.
2. **Implementação.** Duas fatias independentes em worktrees separadas, com
   merge limpo e suíte completa verde. O contrato foi o que garantiu a
   independência: cada worker só podia editar os próprios arquivos.
3. **Review independente.** Um revisor separado, vendo só diff e critério de
   aceite, encontrou um bug de Unicode que os testes dos implementadores não
   pegavam. O pai corrigiu e adicionou regressão.

Lições:

- delegue só o que é independente;
- um dono por arquivo/área;
- brief autossuficiente e relatório curto;
- verificador independente pega o que o executor não vê;
- `isolation: "worktree"` do T3 exige um projeto cuja raiz seja o repo; no
  scratch, use worktree manual ou um projeto dedicado.

## 3. Quando vale dividir

Use o modo pesado apenas quando **pelo menos uma** condição for verdadeira:

- **3 ou mais fatias independentes e substanciais**, cada uma com aceite e
  comando de validação;
- mudança em múltiplos repos ou packages;
- auditoria ou migração grande;
- mudança de alto risco que exige verificador independente;
- operação recorrente com orçamento e monitoramento.

Para o dia a dia:

| Situação | Multi-agente? |
| --- | --- |
| Pergunta, explicação, ajuste pequeno | Não |
| Feature ou refactor num projeto | Execução direta por padrão; delegação pontual se trouxer benefício |
| Leitura, investigação ou revisão independente com escopo claro | Sim, quando o contexto separado compensar o custo |
| Muitas tarefas **independentes** (mesmo refactor em 20 repos, varrer 500 arquivos) | Sim, em paralelo |
| Operação noturna com verificador independente e orçamento | Talvez |
| Tarefa ambígua | Não — esclareça antes |

Não use para pergunta, ajuste pequeno, feature acoplada, tarefa ambígua ou
quando o brief fica maior que a tarefa. Nesses casos, o builder sozinho é mais
rápido e mais barato.

**Regras de bolso:**

- só divida o que não depende entre si; se o briefing fica maior que a tarefa,
  não divida;
- se o trabalho total cabe em uma sessão curta do builder, ou cada fatia é um
  arquivo pequeno, não use o modo pesado. Três comandos minúsculos são
  independentes, mas não justificam a coordenação.

### Como pedir

```text
Você:    Quero fazer X, Y e Z, que não dependem entre si. Planeje, me mostre o
         plano e pare antes de disparar os workers.
Builder: [usa planning; escreve plan.md e progress.md com fatias, donos,
         aceite, orçamento e stop conditions; para no G1]
Você:    Aprovado, pode orquestrar.
Builder: [usa orchestrate e segue o fluxo da seção 7]
```

## 4. Papéis

| Papel | Quem | Faz | Não faz |
| --- | --- | --- | --- |
| Planejador | builder com a skill `planning`, ou um adapter equivalente | Escreve `plan.md` e `progress.md`; define fatias, donos, aceite e orçamento | Não implementa |
| Dispatcher | builder | Valida o plano, cria as threads filhas, distribui tarefas e acompanha bloqueios | Não edita arquivos dos workers enquanto eles rodam |
| Worker | um subagente por tarefa | Implementa só os arquivos do seu escopo, valida e reporta | Não toca arquivo de outro worker nem o checkout do pai |
| Verificador | subagente independente, read-only | Lê diff + critério de aceite e reporta achados | Não implementa, não corrige, não vê o raciocínio do implementador |
| Integrador | builder | Integra commits ou diffs, roda a suíte completa, resolve integração e atualiza o progresso | Não declara verde sem evidência |
| Ship | builder com a skill `ship` | Executa commits, push e PR conforme o pedido; confere CI no SHA | Não faz merge, release ou deploy implícito |

## 5. Artefatos

O modo pesado parte do contrato atual da skill `planning`:

| Arquivo | Papel |
| --- | --- |
| `plan.md` | outcome e boundaries, aceite e evidência, tarefas, decisões e orçamento |
| `progress.md` | status, unidade atual, evidências e changelog |
| `tasks/<task-id>.md` | brief autossuficiente do worker |
| `reports/<task-id>.md` | relatório curto do worker |
| `review.md` | achados e veredito do verificador independente |
| `ship.md` | evidências de integração, SHA, CI e PR |

Não recrie `00-request`, `01-prd`, `02-execution`, `03-tasks` e `04-progress`.
O `plan.md` e o `progress.md` já cobrem pedido, escopo, estratégia, tarefas e
progresso. O que o modo pesado acrescenta é o que o `planning` não precisa no
dia a dia: **briefs por worker, relatórios, review independente e ship**.

Fora do `orchestrate`, o builder **não** cria `tasks/`, `reports/`, `review.md`
nem `ship.md`. `planning`, `implement`, `change-review` e `ship` continuam
leves; esses arquivos são artefatos de coordenação do modo pesado, não um novo
contrato padrão.

Quem escreve o quê: o dispatcher cria `tasks/`; o worker devolve o relatório no
chat e o dispatcher grava `reports/`; o verificador devolve o parecer e o
dispatcher grava `review.md`; o `ship` devolve o resultado e o dispatcher grava
`ship.md`. Nenhum worker edita os artefatos de coordenação do pai.

## 6. Gates

| Gate | Critério | Evidência |
| --- | --- | --- |
| **G1 — Plano aprovado** | escopo, fatias, donos, aceite, orçamento e stop conditions claros | `plan.md` revisado pelo usuário |
| **G2 — Task aceita** | worker entregou só o escopo, rodou o aceite e reportou o resultado | `tasks/<task-id>.md` + `reports/<task-id>.md` + comando de validação e resultado |
| **G3 — Integração verde** | integração limpa e suíte completa passando | saída da suíte + diff acumulado + `progress.md` |
| **G4 — Review limpo** | nenhum blocker aberto | `review.md` |
| **G5 — Entrega conferida** | entrega conforme o pedido e CI conferido | `ship.md` + status do CI no SHA |

Nada avança porque o agente disse "pronto". Cada gate tem comando, saída ou
diff.

## 7. Fluxo

```text
Pedido
└── builder + plan → plan.md + progress.md
    └── G1: plano aprovado
        └── orchestrate
            ├── Worker A (worktree A) → tasks/A.md, reports/A.md
            ├── Worker B (worktree B) → tasks/B.md, reports/B.md
            └── Worker C (worktree C) → tasks/C.md, reports/C.md
                └── G2: cada task aceita
                    └── Integrador → integra o trabalho aceito + suíte completa + progress.md
                        └── G3: integração verde
                            └── Verificador → review.md
                                └── G4: review limpo
                                    └── Ship → ship.md
                                        └── G5: entrega conferida
```

## 8. Contrato do worker

Cada `tasks/<task-id>.md` precisa caber em aproximadamente uma página e conter:

- objetivo e resultado esperado;
- arquivos ou áreas permitidas;
- branch/worktree e base;
- comando de aceite;
- formato do relatório;
- stop conditions.

Exemplo:

```markdown
# tasks/csv-export.md

Objetivo: exportar o relatório em CSV com as mesmas colunas da tela.
Escopo: `src/reports/export.ts` e `src/reports/export.test.ts`.
Base: `main`; worktree `../relatorio-csv-export`.
Aceite: `npm test -- export` verde e `npm run lint` limpo.
Relatório: arquivos tocados, saída do aceite, riscos e próximo passo.
Pare se: precisar mudar o contrato de `ReportRow` ou tocar em outro package.
```

Regras do worker:

- um dono por arquivo/área;
- editar somente o próprio escopo;
- rodar o aceite antes de reportar;
- relatório curto: o que mudou, evidência, riscos e próximo passo;
- parar e perguntar se o repositório contradiz o plano.

Se o brief não cabe em uma página ou o resultado não é validável por um
comando, ainda não está pronto para delegar.

## 9. Mecânica no T3

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
pai; Stop na pai para os subagentes.

## 10. Falhas e stops

| Situação | Ação |
| --- | --- |
| Brief não validável por comando | Não delegue; refine a task ou faça no builder |
| Dois workers no mesmo arquivo | Separe em worktrees ou serialize |
| Worker falhou duas vezes | Pare, reavalie o diagnóstico e refaça o plano |
| Integração vermelha | Não avance para review; corrija primeiro |
| Review com blocker | Corrija e peça novo review; não faça ship |
| Orçamento estourado | Pare e reporte o estado validado |
| Worker pergunta e trava | Responda ou cancele; não deixe pendurado |
| Escopo cresceu | Pare, atualize os artefatos e peça aprovação |

## 11. Como o desenho foi validado

Dois cenários, cada um rodado nos dois workflows — builder solo e
`orchestrate` — para comparar comportamento, não só sucesso:

| Cenário | Tarefa | O que verificar |
| --- | --- | --- |
| **Acoplada** | mudança que depende de várias partes, como renomear uma função em três chamadas ou alterar um contrato compartilhado | builder solo deve ser rápido e direto; `orchestrate` deve recusar ou fazer downgrade, porque não há fatias independentes |
| **Independente** | três comandos, docs ou packages sem dependência entre si | `orchestrate` deve paralelizar, produzir relatórios e passar pelo verificador; builder solo é o baseline |

Métricas: tempo, custo, artefatos criados, intervenções humanas, defeitos
encontrados pelo verificador e conflitos de integração.

Critério de decisão:

- se `orchestrate` ganhar na tarefa acoplada, os critérios de ativação estão
  frouxos;
- se `orchestrate` perder na tarefa independente, o modo pesado ainda não vale;
- o esperado é que cada workflow ganhe no seu terreno.

### Resultado da validação (14/11/2026)

| Cenário | Workflow | Tempo | Testes | Artefatos | Resultado |
| --- | --- | --- | --- | --- | --- |
| Acoplado | builder solo | 34s | 11/11 | nenhum | rename completo em 7 arquivos |
| Acoplado | `orchestrate` | 38s | 11/11 | nenhum | recusou e fez downgrade; diff idêntico ao solo |
| Independente | builder solo | 47s | 31/31 | nenhum | 6 arquivos novos |
| Independente | `orchestrate` | 237s | 32/32 | `plan`, `progress`, `tasks`, `reports`, `review`, `ship` | 3 workers + 1 revisor; review aprovou com nit |

Leitura: o limite de decisão funcionou. O modo pesado foi **5x mais lento** em
três comandos minúsculos; por isso o critério ganhou um piso de tamanho/risco.
O review apontou que faltava o teste automatizado de descoberta previsto no
plano, mas classificou como nit; G4 agora trata critério do plano sem evidência
como blocker.

## 12. Primeiro uso real

Escolha uma tarefa de baixo risco com três fatias claras:

- auditoria de três áreas de um repo;
- mesma mudança em três packages;
- migração de documentação em três partes.

Rode uma vez e meça tempo, custo, qualidade, intervenções e conflitos. Se não
for melhor que o builder sozinho, o modo pesado continua sendo opção rara — não
vira o fluxo padrão.

## 13. Decisões em aberto

- calibrar o piso de tamanho do `orchestrate` com uma tarefa maior;
- confirmar `.agents/work/<slug>/` como raiz dos briefs e relatórios;
- criar um projeto T3 dedicado para testar `isolation: "worktree"` nativo;
- definir orçamento e stop conditions por tipo de tarefa.

## Notas de migração

`planner-0.2` e `agent-0.2` foram aposentados. O `orchestrate` não depende
deles: a estação de planejamento é a skill `planning` e a integração é o
builder. Não há um segundo sistema em paralelo nem um contrato de cinco
arquivos como base.

Os perfis e as referências nos guias foram removidos. Rode novamente o
instalador de cada harness já usado: ele remove links órfãos de skills e de
agentes em `~/.config/opencode/agents/` e `~/.copilot/agents/`. O histórico fica
no git; o fluxo ativo passa a ser builder + skills.

## Referências

- Workflow do Akita: https://ailair.akitaonrails.com/pt-br/workflow/
- Skills do Akita, usadas como referência para adaptação:
  https://github.com/akitaonrails/my-skills
- Hot take: Harness, Loop Engineering, Graph Engineering são Bullshit:
  https://akitaonrails.com/2026/08/18/hot-take-harness-loop-engineering-graph-engineering-sao-bullshit/
- Vale a pena misturar 2 modelos?:
  https://akitaonrails.com/2026/04/25/llm-benchmarks-vale-a-pena-misturar-2-modelos/
- Tweet que motivou o teste: https://x.com/TheAhmadOsman/status/2115249215802896719
