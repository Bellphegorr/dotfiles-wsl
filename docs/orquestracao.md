# Orquestração: quando dividir e como fazer

> Quando vale dividir o trabalho entre agentes e o passo a passo para quando
> vale. **Não é o fluxo padrão.** O dia a dia está em
> [fluxo-de-trabalho.md](fluxo-de-trabalho.md); a mecânica no T3, em
> [t3-code.md](t3-code.md).

## 1. Vale a pena dividir?

Orquestrar é dividir um trabalho entre agentes com contextos separados, em vez
de pedir tudo a um modelo só. Trocar de modelo à mão no meio da conversa não é
orquestração; é roteamento manual.

Os testes do Akita (nov/2026) mostram que, para código do dia a dia, a divisão
não se paga:

| Abordagem | Resultado |
| --- | --- |
| Um modelo bom sozinho no OpenCode | 97/100, 18 min, ~$4 |
| Planejador + executor | 90–95/100, +7 a +35 min |

- Uma cadeia de 10 agentes com 90% de acerto por etapa acerta ~35% no fim.
- A Anthropic reporta ~15x mais tokens em multi-agente e cita código como um
  domínio ruim para isso.

Código é trabalho acoplado: cada peça depende da outra, então dividir só
acrescenta repasse de contexto, latência e retrabalho.

O que funciona melhor: um agente por projeto, skills para procedimentos
recorrentes, `AGENTS.md` com comandos e armadilhas, memória em arquivo,
verificação por testes, CI e revisão. É o que o
[fluxo do builder](fluxo-de-trabalho.md) implementa.

Adaptamos as skills do Akita com redação própria (`planning`, `implement`,
`change-review`, `reflect`, `ship`) e não importamos o pipeline completo,
especialistas obrigatórios, limiares por tickets, limpeza automática nem uma
skill de worktree. Nosso ponto de entrega é **draft PR**, sem merge, release ou
deploy implícito.

### Quando o modo pesado se justifica

Pelo menos uma condição:

- **3 ou mais fatias independentes e substanciais**, cada uma com aceite e
  comando de validação;
- mudança em múltiplos repos ou packages;
- auditoria ou migração grande;
- risco alto que exige verificador independente;
- operação recorrente com orçamento e monitoramento.

Fora disso — pergunta, ajuste pequeno, feature acoplada, tarefa ambígua ou
brief maior que a tarefa — o builder sozinho é mais rápido e mais barato.

**Regra de bolso:** só divida o que não depende entre si, e só quando a
coordenação custa menos que o trabalho. Três comandos minúsculos são
independentes, mas não justificam o modo pesado.

### Como pedir

```text
Você:    Quero fazer X, Y e Z, que não dependem entre si. Planeje, me mostre o
         plano e pare antes de disparar os workers.
Builder: [usa planning; escreve plan.md e progress.md com fatias, donos,
         aceite, orçamento e stop conditions; para no G1]
Você:    Aprovado, pode orquestrar.
Builder: [usa orchestrate e segue o fluxo abaixo]
```

## 2. Papéis

| Papel | Quem | Faz | Não faz |
| --- | --- | --- | --- |
| Planejador | builder com a skill `planning` | Escreve `plan.md` e `progress.md`; define fatias, donos, aceite e orçamento | Não implementa |
| Dispatcher | builder | Valida o plano, cria as threads filhas, distribui tarefas e acompanha bloqueios | Não edita arquivos dos workers enquanto eles rodam |
| Worker | um subagente por tarefa | Implementa só o escopo, valida e reporta | Não toca arquivo de outro worker nem o checkout do pai |
| Verificador | subagente independente, read-only | Lê diff + critério de aceite e reporta achados | Não implementa, não corrige, não vê o raciocínio do implementador |
| Integrador | builder | Integra o trabalho aceito, roda a suíte completa e atualiza o progresso | Não declara verde sem evidência |
| Ship | builder com a skill `ship` | Commits, push e PR conforme o pedido; confere CI no SHA | Não faz merge, release ou deploy implícito |

A execução no T3 — `delegate_task`, worktrees, permissões — está em
[t3-code.md](t3-code.md).

## 3. Artefatos

| Arquivo | Papel |
| --- | --- |
| `plan.md` | outcome, boundaries, aceite, tarefas, decisões e orçamento |
| `progress.md` | status, unidade atual, evidências e changelog |
| `tasks/<task-id>.md` | brief autossuficiente do worker |
| `reports/<task-id>.md` | relatório curto do worker |
| `review.md` | achados e veredito do verificador independente |
| `ship.md` | evidências de integração, SHA, CI e PR |

Tudo em `.agents/work/<slug>/`. Não recrie `00-request`, `01-prd`,
`02-execution`, `03-tasks` e `04-progress`: o `plan.md` e o `progress.md` já
cobrem pedido, escopo, estratégia, tarefas e progresso.

Fora do `orchestrate`, o builder **não** cria `tasks/`, `reports/`, `review.md`
nem `ship.md`. Esses arquivos são coordenação do modo pesado, não um contrato
padrão. O dispatcher cria `tasks/` e grava `reports/`, `review.md` e `ship.md` a
partir do que os workers e o verificador devolvem no chat; nenhum worker edita
os artefatos do pai.

## 4. Gates

| Gate | Critério | Evidência |
| --- | --- | --- |
| **G1 — Plano aprovado** | escopo, fatias, donos, aceite, orçamento e stop conditions claros | `plan.md` revisado pelo usuário |
| **G2 — Task aceita** | worker entregou só o escopo, rodou o aceite e reportou | `tasks/<id>.md` + `reports/<id>.md` + comando e resultado |
| **G3 — Integração verde** | integração limpa e suíte completa passando | saída da suíte + diff acumulado + `progress.md` |
| **G4 — Review limpo** | nenhum blocker aberto | `review.md` |
| **G5 — Entrega conferida** | entrega conforme o pedido e CI conferido | `ship.md` + status do CI no SHA |

Nada avança porque o agente disse "pronto". Cada gate tem comando, saída ou
diff.

## 5. Fluxo

```text
Pedido
└── builder + plan → plan.md + progress.md
    └── G1: plano aprovado
        └── orchestrate
            ├── Worker A → tasks/A.md, reports/A.md
            ├── Worker B → tasks/B.md, reports/B.md
            └── Worker C → tasks/C.md, reports/C.md
                └── G2: cada task aceita
                    └── Integrador → suíte completa + progress.md
                        └── G3: integração verde
                            └── Verificador → review.md
                                └── G4: review limpo
                                    └── Ship → ship.md
                                        └── G5: entrega conferida
```

## 6. Contrato do worker

Cada `tasks/<task-id>.md` cabe em aproximadamente uma página e contém:

- objetivo e resultado esperado;
- arquivos ou áreas permitidas;
- branch/worktree e base;
- comando de aceite;
- formato do relatório;
- stop conditions.

```markdown
# tasks/csv-export.md

Objetivo: exportar o relatório em CSV com as mesmas colunas da tela.
Escopo: `src/reports/export.ts` e `src/reports/export.test.ts`.
Base: `main`; worktree `../relatorio-csv-export`.
Aceite: `npm test -- export` verde e `npm run lint` limpo.
Relatório: arquivos tocados, saída do aceite, riscos e próximo passo.
Pare se: precisar mudar o contrato de `ReportRow` ou tocar em outro package.
```

Regras: um dono por arquivo/área; editar só o próprio escopo; rodar o aceite
antes de reportar; relatório curto (o que mudou, evidência, riscos e próximo
passo); parar e perguntar se o repositório contradiz o plano. Se o brief não
cabe em uma página ou o resultado não é validável por um comando, ainda não
está pronto para delegar.

## 7. Falhas e stops

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

## 8. Como o desenho foi validado

Dois cenários, cada um rodado no builder solo e no `orchestrate`: uma tarefa
**acoplada** (rename em três chamadas) e uma **independente** (três partes sem
dependência). O esperado é que cada workflow ganhe no seu terreno.

| Cenário | Workflow | Tempo | Testes | Artefatos | Resultado |
| --- | --- | --- | --- | --- | --- |
| Acoplado | builder solo | 34s | 11/11 | nenhum | rename completo em 7 arquivos |
| Acoplado | `orchestrate` | 38s | 11/11 | nenhum | recusou e fez downgrade; diff idêntico ao solo |
| Independente | builder solo | 47s | 31/31 | nenhum | 6 arquivos novos |
| Independente | `orchestrate` | 237s | 32/32 | todos | 3 workers + 1 revisor; review aprovou com nit |

Leitura: o modo pesado foi **5x mais lento** em três comandos minúsculos; por
isso o critério ganhou um piso de tamanho/risco. O review apontou um teste
automatizado previsto no plano que faltava, mas classificou como nit; G4 agora
trata critério do plano sem evidência como blocker.

## 9. Primeiro uso real

Escolha uma tarefa de baixo risco com três fatias claras — auditoria de três
áreas de um repo, a mesma mudança em três packages, ou uma migração de
documentação em três partes. Rode uma vez e meça tempo, custo, qualidade,
intervenções e conflitos. Se não for melhor que o builder sozinho, o modo
pesado continua sendo opção rara — não vira o fluxo padrão.

## 10. Decisões em aberto

- calibrar o piso de tamanho do `orchestrate` com uma tarefa maior;
- confirmar `.agents/work/<slug>/` como raiz dos briefs e relatórios;
- criar um projeto T3 dedicado para testar `isolation: "worktree"` nativo;
- definir orçamento e stop conditions por tipo de tarefa.

## Referências

- Workflow do Akita: https://ailair.akitaonrails.com/pt-br/workflow/
- Skills do Akita, usadas como referência para adaptação:
  https://github.com/akitaonrails/my-skills
- Hot take: Harness, Loop Engineering, Graph Engineering são Bullshit:
  https://akitaonrails.com/2026/08/18/hot-take-harness-loop-engineering-graph-engineering-sao-bullshit/
- Vale a pena misturar 2 modelos?:
  https://akitaonrails.com/2026/04/25/llm-benchmarks-vale-a-pena-misturar-2-modelos/
- Tweet que motivou o teste: https://x.com/TheAhmadOsman/status/2115249215802896719
