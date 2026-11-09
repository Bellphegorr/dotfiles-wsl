# Orquestração de agentes e ferramentas

> O que é orquestração, quando vale a pena e quais ferramentas existem.
> Atualizado em 09/11/2026. O fluxo que uso no dia a dia está em
> [fluxo-de-trabalho.md](fluxo-de-trabalho.md).

## 1. O conceito

Orquestrar é dividir um trabalho entre agentes com contextos separados, em vez
de pedir tudo a um modelo só. O desenho clássico:

```text
Você
└── Orquestrador (modelo forte) — planeja, divide e revisa
    └── Executor (modelo barato) — implementa, testa e reporta
```

A promessa: contexto limpo para o executor, modelo caro só pensando, modelo
barato fazendo o trabalho mecânico.

Trocar de modelo à mão no meio da conversa **não** é orquestração; é
roteamento manual.

## 2. Na prática: um agente forte ganha

Os testes do Akita (nov/2026) mostram que, para código do dia a dia, a
promessa não se paga:

- Opus 4.7 sozinho no OpenCode: **97/100, 18 min, ~$4**.
- Planejador + executor: **90–95/100, +7 a +35 min**. Nenhuma combinação bateu
  o solo em qualidade, tempo e custo ao mesmo tempo.
- Uma cadeia de 10 agentes com 90% de acerto por etapa acerta ~35% no fim.
- A Anthropic reporta ~15x mais tokens em multi-agente e cita código como um
  domínio ruim para isso.

O motivo: código é trabalho acoplado. Cada peça depende da outra, então
dividir só adiciona repasse de contexto, latência e retrabalho. É como
`Promise.all` em chamadas que dependem umas das outras: não paraleliza nada.

O que funciona melhor:

- **um agente por projeto**, com modelo forte;
- **skills** (`SKILL.md`) para procedimentos recorrentes;
- **`AGENTS.md`** com comandos, invariantes e armadilhas;
- **memória em arquivo** por projeto;
- **verificação** por testes, CI e revisão humana;
- **cada falha vira regra** na skill ou no `AGENTS.md`.

É o que o [fluxo do builder](fluxo-de-trabalho.md) implementa.

## 3. Quando multi-agente vale

| Situação | Multi-agente? |
| --- | --- |
| Pergunta, explicação, ajuste pequeno | Não |
| Feature ou refactor num projeto | Não — um agente + plano |
| Muitas tarefas **independentes** (mesmo refactor em 20 repos, varrer 500 arquivos) | Sim, em paralelo |
| Operação noturna com verificador independente e orçamento | Talvez |
| Tarefa ambígua | Não — esclareça antes |

**Regra de bolso:** só divida o que não depende entre si. Se o briefing fica
maior que a tarefa, não divida.

## 4. Mapa de ferramentas

Ferramenta é camada. Um cockpit não substitui o harness, e um assistente
pessoal não substitui o agente de código.

| Camada | O que resolve | Exemplos | Para mim |
| --- | --- | --- | --- |
| Modelos | acesso aos modelos | **OpenCode Go**, OpenCode Console, OpenRouter, LiteLLM, Ollama/LM Studio | Já uso o Go |
| Harness | executa o agente no código | **OpenCode**, Claude Code, Codex CLI, Gemini CLI, Aider, Goose, Cline/Roo | Já uso o OpenCode; trocar só com motivo |
| IDE com agente | editor + agente juntos | Cursor, Windsurf, Zed, VS Code + Copilot | Só se preferir editor |
| Cockpit | sessões, diffs, worktrees, celular | **T3 Code**, OpenChamber, Conductor, Vibe Kanban, Claude Squad | T3 em uso; OpenChamber é alternativa |
| Código assíncrono | delega issue, recebe PR | OpenHands, Devin, Jules | Talvez, para tarefas bem definidas |
| Assistente 24/7 | memória, mensageria, agendamento | Hermes, OpenBot, Grok Bot | Só se quiser; escolha um |
| Frameworks | construir produto de agentes | LangGraph, CrewAI, Agent SDKs | Não é uso diário |
| Transversal | integrações e memória | MCP, Composio, n8n, Letta/Mem0, Playwright | Quando precisar |

```text
O que você quer?
├── Codar no repositório → OpenCode + builder
├── Mesma mudança em muitos lugares independentes → subagentes/worktrees em paralelo
├── Interface, celular, comparar modelos → T3 Code ou OpenChamber
├── Delegar uma issue e receber PR → OpenHands / Devin / Jules
├── Assistente pessoal 24/7 → Hermes / OpenBot / Grok Bot
└── Construir um produto de agentes → LangGraph / CrewAI / SDKs
```

## 5. Custo dos modelos (OpenCode)

USD por 1 milhão de tokens, nov/2026 (confira antes de decidir):

| Modelo | Input | Output | Cache read |
| --- | --- | --- | --- |
| Kimi K3.1 Pro (Go) | $2,00 | $10,00 | $0,20 |
| DeepSeek V4 Pro (Go) | $0,66 | $1,98 | $0,022 |
| DeepSeek V4.1 Flash (Go) — builder | $0,15 | $0,60 | $0,003 |
| Claude Opus 5.5 (Console) | $4,00 | $20,00 | $0,20 |

As variantes `#low`, `#high` e `#max` controlam o esforço de raciocínio. Use
`#high` como padrão e `#max` só em tarefa difícil.

## Referências

- Workflow do Akita: https://ailair.akitaonrails.com/pt-br/workflow/
- Hot take: Harness, Loop Engineering, Graph Engineering são Bullshit:
  https://akitaonrails.com/2026/08/18/hot-take-harness-loop-engineering-graph-engineering-sao-bullshit/
- Vale a pena misturar 2 modelos?:
  https://akitaonrails.com/2026/04/25/llm-benchmarks-vale-a-pena-misturar-2-modelos/
- Tweet que motivou o teste: https://x.com/TheAhmadOsman/status/2115249215802896719
- Agentes do OpenCode: https://opencode.ai/docs/agents
- Configuração do OpenCode: https://opencode.ai/docs/config
- OpenChamber: https://openchamber.dev/
- Hermes Agent: https://hermes-agent.nousresearch.com/
- OpenBot: https://openbot.run/
- Grok Bot: https://x.ai/bot
- Comparativo com 36 agentes de código: https://openchamber.dev/blog/ai-coding-agents/
