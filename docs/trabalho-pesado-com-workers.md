# Trabalho pesado com workers

> Fluxo para trabalho grande, decomponível ou de alto risco. **Não é o padrão.**
> O fluxo diário está em [fluxo-de-trabalho.md](fluxo-de-trabalho.md); os
> conceitos e limites estão em [multiagentes.md](multiagentes.md).

## 1. Quando usar

Use apenas quando pelo menos uma condição for verdadeira:

- **3 ou mais fatias independentes e substanciais**, cada uma com aceite e
  comando de validação;
- mudança em múltiplos repos ou packages;
- auditoria ou migração grande;
- mudança de alto risco que exige verificador independente;
- operação recorrente com orçamento e monitoramento.

Não use para pergunta, ajuste pequeno, feature acoplada, tarefa ambígua ou
quando o brief fica maior que a tarefa. Nesses casos, o builder sozinho é mais
rápido e mais barato.

**Regra de bolso:** se o trabalho total cabe em uma sessão curta do builder, ou
cada fatia é um arquivo pequeno, não use o modo pesado. Três comandos minúsculos
são independentes, mas não justificam a coordenação.

## 2. Papéis

| Papel | Quem | Faz | Não faz |
| --- | --- | --- | --- |
| Planejador | builder com a skill `planning`, ou um adapter equivalente | Escreve `plan.md` e `progress.md`; define fatias, donos, aceite e orçamento | Não implementa |
| Dispatcher | builder | Valida o plano, cria as threads filhas, distribui tarefas e acompanha bloqueios | Não edita arquivos dos workers enquanto eles rodam |
| Worker | um subagente por tarefa | Implementa só os arquivos do seu escopo, valida e reporta | Não toca arquivo de outro worker nem o checkout do pai |
| Verificador | subagente independente, read-only | Lê diff + critério de aceite e reporta achados | Não implementa, não corrige, não vê o raciocínio do implementador |
| Integrador | builder | Integra commits ou diffs, roda a suíte completa, resolve integração e atualiza o progresso | Não declara verde sem evidência |
| Ship | builder com a skill `ship` | Executa commits, push e PR conforme o pedido; confere CI no SHA | Não faz merge, release ou deploy implícito |

## 3. Artefatos

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
progresso. O que o modo pesado acrescenta é o que o `planning` não precisa no dia a
dia: **briefs por worker, relatórios, review independente e ship**.

Fora do `orchestrate`, o builder **não** cria `tasks/`, `reports/`, `review.md`
nem `ship.md`. `planning`, `implement`, `change-review` e `ship` continuam leves; esses
arquivos são artefatos de coordenação do modo pesado, não um novo contrato
padrão.

Quem escreve o quê: o dispatcher cria `tasks/`; o worker devolve o relatório no
chat e o dispatcher grava `reports/`; o verificador devolve o parecer e o
dispatcher grava `review.md`; o `ship` devolve o resultado e o dispatcher grava
`ship.md`. Nenhum worker edita os artefatos de coordenação do pai.

## 4. Gates

| Gate | Critério | Evidência |
| --- | --- | --- |
| **G1 — Plano aprovado** | escopo, fatias, donos, aceite, orçamento e stop conditions claros | `plan.md` revisado pelo usuário |
| **G2 — Task aceita** | worker entregou só o escopo, rodou o aceite e reportou o resultado | `tasks/<task-id>.md` + `reports/<task-id>.md` + comando de validação e resultado |
| **G3 — Integração verde** | integração limpa e suíte completa passando | saída da suíte + diff acumulado + `progress.md` |
| **G4 — Review limpo** | nenhum blocker aberto | `review.md` |
| **G5 — Entrega conferida** | entrega conforme o pedido e CI conferido | `ship.md` + status do CI no SHA |

Nada avança porque o agente disse “pronto”. Cada gate tem comando, saída ou
diff.

## 5. Fluxo

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

## 6. Contrato do worker

Cada `tasks/<task-id>.md` precisa caber em aproximadamente uma página e conter:

- objetivo e resultado esperado;
- arquivos ou áreas permitidas;
- branch/worktree e base;
- comando de aceite;
- formato do relatório;
- stop conditions.

Regras do worker:

- um dono por arquivo/área;
- editar somente o próprio escopo;
- rodar o aceite antes de reportar;
- relatório curto: o que mudou, evidência, riscos e próximo passo;
- parar e perguntar se o repositório contradiz o plano.

Se o brief não cabe em uma página ou o resultado não é validável por um
comando, ainda não está pronto para delegar.

## 7. Mecânica no T3

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

## 8. Agentes antigos

`planner-0.2` e `agent-0.2` foram aposentados. O `orchestrate` não depende
deles: a estação de planejamento é a skill `planning` e a integração é o builder.
Não há um segundo sistema em paralelo nem um contrato de cinco arquivos como
base.

Os perfis e as referências nos guias foram removidos. Rode novamente o
instalador de cada harness já usado: ele remove links órfãos de skills e de
agentes em `~/.config/opencode/agents/` e `~/.copilot/agents/`. O histórico fica
no git; o fluxo ativo passa a ser builder + skills.

## 9. Falhas e stops

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

## 10. Como validar o desenho

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

## 11. Primeiro uso real

Escolha uma tarefa de baixo risco com três fatias claras:

- auditoria de três áreas de um repo;
- mesma mudança em três packages;
- migração de documentação em três partes.

Rode uma vez e meça tempo, custo, qualidade, intervenções e conflitos. Se não
for melhor que o builder sozinho, o modo pesado continua sendo opção rara — não
vira o fluxo padrão.

## 12. Decisões em aberto

- calibrar o piso de tamanho do `orchestrate` com uma tarefa maior;
- confirmar `.agents/work/<slug>/` como raiz dos briefs e relatórios;
- criar um projeto T3 dedicado para testar `isolation: "worktree"` nativo;
- definir orçamento e stop conditions por tipo de tarefa.
