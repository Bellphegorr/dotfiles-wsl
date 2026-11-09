# Orquestração de Agentes — Guia Prático

> Como usar vários modelos e agentes sem transformar uma tarefa simples num circo.
> Atualizado em 08/11/2026.

## 1. O conceito em 30 segundos

Orquestração de agentes é dividir um trabalho entre agentes especializados, com
contextos separados, em vez de pedir tudo a um modelo só.

O padrão mais útil para código:

```text
Você
└── Orquestrador (modelo forte) — entende, planeja, divide e revisa
    └── Executor (modelo barato/rápido) — implementa, testa e reporta
```

Por que funciona:

- Contexto limpo para o executor — menos ruído, menos tokens.
- Modelo caro só pensa; modelo barato queima token no trabalho mecânico.
- Verificação explícita entre as etapas.

O que **não** é orquestração: trocar o modelo manualmente no meio da conversa.
Isso é roteamento manual. Orquestração envolve delegação automática e contexto
isolado.

## 2. Quando orquestrar

| Situação                                   | Orquestrar?    | Por quê                                                   |
| ------------------------------------------ | -------------- | --------------------------------------------------------- |
| Pergunta conceitual, explicação            | Não            | Um modelo responde direto                                 |
| Ajuste de uma linha, typo                  | Não            | O overhead é maior que o ganho                            |
| Feature pequena, 1 arquivo, critério claro | Depende        | Se precisa explorar + implementar + testar, pode valer    |
| Feature multi-arquivo                      | Sim            | Plano e implementação se beneficiam da separação          |
| Refactor amplo                             | Sim            | Planejar antes reduz retrabalho                           |
| Bug com teste de reprodução                | Sim            | Executor itera até o teste passar                         |
| Várias tarefas independentes               | Sim (paralelo) | Subagentes em background e/ou worktrees                   |
| Tarefa ambígua                             | Não (ainda)    | Primeiro esclareça o pedido; delegar cedo gera retrabalho |

**Regra de bolso:** decomponível + verificável = orquestre. Caso contrário,
modelo único.

Sinais de que **não** vale orquestrar:

- o briefing ficaria maior que a tarefa;
- não há como validar o resultado (sem teste, lint ou diff claro);
- as partes são fortemente acopladas (mexem nos mesmos arquivos).

## 3. As ferramentas: mapa do ecossistema

Ferramenta é camada. O erro mais comum é comparar coisas que vivem em camadas
diferentes: um cockpit não substitui o harness, e um agente pessoal não
substitui o coding agent.

```text
Camada 1 — Modelos
  OpenCode Go/Console · OpenRouter · API própria · Ollama/LM Studio (local)
        ↓
Camada 2 — Harness (o motor que executa o agente)
  OpenCode · Claude Code · Codex CLI · Gemini CLI · Aider · Amp · Pi · Cline/Roo
  IDEs com agente embutido: Cursor · Windsurf · Zed · VS Code
        ↓
Camada 3 — Cockpit/ADE (a sala de controle)
  OpenChamber · T3 Code · Conductor · Vibe Kanban · Crystal · Claude Squad
        ↓
Camada 4 — Operação contínua (fora do terminal)
  Hermes · OpenBot · Grok Bot (assistentes always-on)
  OpenHands · Devin · Jules (código assíncrono)
        ↓
Camada 5 — Construir o seu
  LangGraph · CrewAI · AutoGen/Agent Framework · SDKs
```

| Camada | O que resolve | Ferramentas |
| --- | --- | --- |
| 1. Modelos | acesso e roteamento de modelos | OpenCode Go/Console, OpenRouter, LiteLLM, Ollama/LM Studio/vLLM |
| 2. Harness | executa o agente no código | OpenCode, Claude Code, Codex CLI, Gemini CLI, Aider, Amp, Pi, Goose, Cline/Roo/Kilo |
| 2b. IDE com agente | editor + agente numa peça só | Cursor, Windsurf, Zed, VS Code |
| 3. Cockpit | sala de controle, revisão e paralelismo | OpenChamber, T3 Code, Conductor, Vibe Kanban, Crystal, Claude Squad |
| 4a. Código assíncrono | delega uma issue e recebe um PR | OpenHands, Devin, Jules |
| 4b. Always-on pessoal | assistente 24/7 com memória | Hermes, OpenBot, Grok Bot |
| 5. Frameworks | construir um produto de agentes | LangGraph, CrewAI, AutoGen/Agent Framework, SDKs |
| Transversal | memória, integrações e automação | MCP, Composio, n8n/Zapier/Make, Letta/Mem0/Zep, Browser Use/Playwright |

> **Você não precisa de tudo isso.** A maioria é alternativa, não complemento.
> O que soma ao seu setup atual é, no máximo, um cockpit (OpenChamber) e, se
> fizer sentido, um assistente pessoal (Hermes/OpenBot/Grok Bot).

### 3.1 Modelos e acesso (camada 1)

| Opção                         | O que é                                                                               | Quando usar                                              |
| ----------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **OpenCode Go**               | assinatura (US$ 10/mês) com DeepSeek, Kimi, Gemini, Grok, GLM, Claude Haiku           | acesso barato a modelos bons sem API key                 |
| **OpenCode Console**          | serviço com workspaces, créditos, orçamento e modelos proprietários (Claude/GPT etc.) | quando precisar de modelos de topo com controle de gasto |
| **API própria**               | Anthropic, OpenAI, DeepSeek, Google via chave                                         | controle de custo e cota                                 |
| **OpenRouter**                | API única para centenas de modelos                                                    | testar modelos sem trocar de provider                    |
| **LiteLLM**                   | proxy/roteador de modelos                                                             | fallback, limite de gasto, padronização                  |
| **Ollama / LM Studio / vLLM** | inferência local                                                                      | privacidade, offline, custo fixo                         |

No OpenCode, tudo isso entra como _provider_. Você pode misturar: orquestrador
no Go e executor em modelo local, por exemplo.

### 3.2 Harness de código (camada 2)

O harness é o motor que roda o agente: lê arquivos, executa comandos, aplica
edições e gerencia permissões.

**OpenCode** — o que você já usa. Harness de código (terminal, desktop e web)
com agentes nativos:

- **primary agent**: agente principal da sessão.
- **subagent**: agente filho com contexto novo, chamado pelo principal.
- Cada agente pode ter modelo, prompt, permissões e limites próprios.

**Use quando:** trabalhar em repositório, no terminal, num fluxo interativo de
código.

**Não use quando:** quiser um agente rodando sozinho 24/7, fora do seu terminal.

Outros harnesses que as pessoas citam:

| Ferramenta                       | O que é                                    | Onde se encaixa                             |
| -------------------------------- | ------------------------------------------ | ------------------------------------------- |
| **Claude Code**                  | agente de terminal da Anthropic            | alternativa ao OpenCode; ecossistema Claude |
| **Codex CLI**                    | agente de terminal da OpenAI               | alternativa; integra com ChatGPT/Codex      |
| **Gemini CLI**                   | agente de terminal do Google               | alternativa; contexto longo                 |
| **Aider**                        | pair programming no terminal, forte em Git | edição focada com commits                   |
| **Amp**                          | agente de terminal e cloud (Sourcegraph)   | trabalho delegado                           |
| **Pi**                           | agente pequeno e extensível                | customização e experimentos                 |
| **Goose**                        | agente local open-source (Block)           | automação local com extensões               |
| **Cline / Roo Code / Kilo Code** | extensões de VS Code                       | agente dentro do editor                     |
| **GitHub Copilot**               | extensão e plataforma                      | integração com GitHub e editores            |

Trocar de harness é trocar o motor. Só vale se ele tiver algo que o seu não tem
— não é camada que se soma.

**IDEs com agente embutido** (Cursor, Windsurf, Zed, VS Code + Copilot/Continue)
juntam editor e harness numa peça só. Use se você prefere trabalhar no editor;
não é uma camada adicional ao OpenCode.

### 3.3 Cockpit / ADE (camada 3)

Cockpit (ou ADE, _agentic development environment_) é a sala de controle em
cima do harness: sessões, diffs, worktrees, revisão, histórico e acesso remoto.

**OpenChamber** — o cockpit open-source que usa o **OpenCode** como motor.

- Desktop (macOS, Windows, Linux), navegador, celular (iOS/Android beta) e
  extensão de VS Code.
- Começa uma sessão numa máquina e continua em outra.
- Manda o mesmo prompt para vários modelos, cada um com worktree/branch própria;
  escolhe o melhor resultado ou funde as respostas.
- Diff walkthrough: transforma um diff grande numa leitura guiada.
- Integra GitHub, Linear e mais de 160 serviços; suporta MCP.
- Metas de longo prazo e tarefas agendadas.
- Mostra consumo/cotas de provedores (Claude, Codex, Gemini, OpenRouter etc.).
- MIT e independente do time do OpenCode.

**Use quando:** quer uma interface melhor para o OpenCode, acessar do celular,
comparar modelos, revisar diffs grandes ou agendar tarefas.

**Não use quando:** a TUI já resolve e você não quer mais uma camada.

Outros cockpits:

| Ferramenta       | O que é                                  | Onde se encaixa                   |
| ---------------- | ---------------------------------------- | --------------------------------- |
| **T3 Code**      | interface comum para agentes suportados  | cockpit multiplataforma           |
| **Conductor**    | várias sessões em paralelo com worktrees | rodar agentes simultâneos         |
| **Vibe Kanban**  | kanban para orquestrar agentes           | fila visual de tarefas            |
| **Crystal**      | múltiplas sessões em desktop             | paralelismo local                 |
| **Claude Squad** | gerenciador de agentes no terminal       | vários agentes via tmux/worktrees |

Cockpit **não** substitui o harness: ele só torna o trabalho visível e
gerenciável.

### 3.4 Agentes autônomos de código (camada 4a)

São agentes assíncronos: você delega uma issue ou tarefa e recebe um PR ou um
relatório depois.

| Ferramenta                  | O que é                                                    | Onde se encaixa                           |
| --------------------------- | ---------------------------------------------------------- | ----------------------------------------- |
| **OpenHands**               | engenheiro de software autônomo open-source (ex-OpenDevin) | self-host ou cloud; tarefas bem definidas |
| **Devin**                   | engenheiro autônomo cloud da Cognition                     | delegação de issues                       |
| **Jules**                   | agente assíncrono do Google                                | tarefas de código no ecossistema Google   |
| **Codex/Claude Code cloud** | versões assíncronas dos harnesses                          | delegar e revisar depois                  |

**Use quando:** a tarefa é bem definida, verificável e você não precisa dirigir
cada passo.

**Não use quando:** o trabalho é exploratório, acoplado ou exige decisões
frequentes — aí o custo de corrigir o agente supera o ganho.

### 3.5 Agentes pessoais always-on (camada 4b)

Aqui o foco não é código: é um assistente que vive em vários canais, tem memória
e roda tarefas contínuas.

**Hermes (Nous Research)** — agente pessoal open-source (MIT), self-hosted ou
em cloud.

- Um agente, uma memória, em Telegram, Discord, Slack, WhatsApp, Signal, Email e
  CLI.
- Memória persistente: aprende seus projetos e gera skills sozinho.
- Agendamento em linguagem natural para relatórios, backups e briefings.
- Subagentes isolados, com conversas e terminais próprios.
- Sandboxes: local, Docker, SSH, Singularity ou Modal.
- Busca web, automação de browser, visão, geração de imagem, TTS e raciocínio
  multi-modelo.
- Planos: free pay-as-you-go; Plus US$ 20/mês; Super US$ 100/mês; Ultra
  US$ 200/mês (com cloud hosting incluso).

**Use quando:** quer um assistente pessoal 24/7 com memória, mensageria,
agendamento e automação — e quer self-host.

**Não use quando:** o objetivo é codar no repositório com controle fino. Para
isso, o OpenCode é mais direto.

**OpenBot** — workspace self-hostable de "AI coworkers", com agentes
persistentes rodando no seu computador. Dá para trazer agentes que você já usa
— inclusive OpenCode — via AG-UI.

**Grok Bot** — time de agentes always-on da xAI. Cada agente tem o próprio
"computador", usa as ferramentas como você e não desliga.

| Ferramenta   | Código        | Onde roda       | Foco                                        |
| ------------ | ------------- | --------------- | ------------------------------------------- |
| **Hermes**   | aberto (MIT)  | local ou cloud  | assistente pessoal com memória e mensageria |
| **OpenBot**  | aberto        | local/self-host | workspace de AI coworkers                   |
| **Grok Bot** | fechado (xAI) | cloud           | time always-on com máquina própria          |

Esses três se sobrepõem. Escolha um pela preferência de hospedagem e
ecossistema — não instale os três.

### 3.6 Construir o seu (camada 5)

Frameworks servem para **construir** aplicações de agentes (produto ou
serviço), não para usar como coding agent no dia a dia.

| Ferramenta                                       | O que é                                | Onde se encaixa                 |
| ------------------------------------------------ | -------------------------------------- | ------------------------------- |
| **LangGraph**                                    | grafos de estado para agentes          | fluxos com estado e ciclos      |
| **CrewAI**                                       | times de agentes por papéis            | automações multiagente          |
| **AutoGen / Microsoft Agent Framework**          | conversas multiagente, foco enterprise | sistemas corporativos           |
| **OpenAI Agents SDK / Google ADK / Pydantic AI** | SDKs dos fabricantes                   | integração com cada ecossistema |
| **SDK do OpenCode**                              | embutir o OpenCode numa aplicação      | produto baseado no harness      |

**Use quando:** estiver desenvolvendo um sistema de agentes com estado,
ferramentas e deploy próprios.

**Não use quando:** o objetivo for só planejar e executar no seu projeto.

### 3.7 Camadas transversais

Ferramentas que plugam em qualquer camada acima:

| Ferramenta                   | O que é                                               | Onde se encaixa                     |
| ---------------------------- | ----------------------------------------------------- | ----------------------------------- |
| **MCP**                      | protocolo para conectar ferramentas e dados a agentes | dar superpoderes ao harness         |
| **Composio**                 | catálogo de integrações para agentes                  | conectar SaaS sem escrever conector |
| **n8n / Zapier / Make**      | automação de workflow por nós e gatilhos              | processos fora do código            |
| **Letta / Mem0 / Zep**       | memória de longo prazo para agentes                   | contexto persistente                |
| **Browser Use / Playwright** | automação de navegador                                | tarefas web                         |

### 3.8 O que faz sentido para o seu caso

| Ferramenta                               | Categoria           | Precisa?                    | Por quê                                          |
| ---------------------------------------- | ------------------- | --------------------------- | ------------------------------------------------ |
| **OpenCode**                             | harness             | Já usa                      | é o motor do setup                               |
| **OpenCode Go**                          | modelos             | Já usa                      | acesso aos modelos                               |
| **OpenChamber**                          | cockpit             | Próximo passo opcional      | UI, celular, worktrees, review                   |
| **Hermes**                               | agente pessoal      | Só se quiser 24/7           | memória/mensageria; não substitui o coding agent |
| **OpenBot / Grok Bot**                   | always-on           | Não, por enquanto           | mesma categoria do Hermes                        |
| **Claude Code / Codex CLI / Gemini CLI** | harness alternativo | Não                         | evitar trocar de motor sem motivo                |
| **Cursor / Windsurf / Zed**              | IDE                 | Se preferir editor          | agente embutido no editor                        |
| **OpenHands / Devin / Jules**            | agente assíncrono   | Talvez                      | delegar issues e receber PR                      |
| **LangGraph / CrewAI / SDKs**            | framework           | Só se construir produto     | não é ferramenta de uso diário                   |
| **Ollama / LM Studio**                   | inferência local    | Se quiser local/privacidade | modelos abertos                                  |
| **MCP**                                  | integrações         | Quando precisar             | conectar ferramentas                             |
| **Letta / Mem0**                         | memória             | Raramente no código         | contexto de longo prazo                          |

### 3.9 Resumo da decisão

```text
O que você quer fazer?
├── Codar no repositório, interativo
│   ├── Só o básico → OpenCode (build/Flash)
│   ├── Tarefa multi-arquivo → OpenCode + orchestrator/implementer
│   ├── Quero cockpit, celular, comparar modelos → OpenChamber
│   └── Muitas tarefas independentes → worktrees/subagentes em paralelo
├── Delegar uma issue e receber um PR → OpenHands / Devin / Jules
├── Assistente pessoal 24/7 com memória → Hermes / OpenBot / Grok Bot
└── Construir um produto de agentes → LangGraph / CrewAI / SDKs
```

## 4. Agentes: em uso x em teste

### 4.1 Em uso (instalados)

Estes são os agentes ativos hoje, em `~/.config/opencode/agent/` (versionados
em `config/opencode/agent/`):

| Agente        | Modo    | Modelo            | Papel                                                                                          |
| ------------- | ------- | ----------------- | ---------------------------------------------------------------------------------------------- |
| `agent-0.2`   | primary | herdado da sessão | Implementação/orquestração de uma fase aprovada, com artefatos em `.agents/work/` e gates HITL. |
| `planner-0.2` | primary | herdado da sessão | Planejamento portátil com artefatos fixos em `.agents/work/` antes da implementação.            |

### 4.2 Em teste (não instalados): DeepSeek V4 Pro planeja, Flash executa

> **Nota (09/11/2026):** este é um setup de teste, ainda não instalado. Os
> arquivos estão em `config/opencode/agents/` no dotfiles, mas não em
> `~/.config/opencode/agents/`. O T3 Code 0.1.7 com OpenCode 2.x não lista
> agentes customizados no seletor; use a TUI ou a CLI do OpenCode para
> escolhê-los.

Dois agentes de teste em `config/opencode/agents/` (para instalar em
`~/.config/opencode/agents/`):

| Agente         | Modo     | Modelo                        | Papel                             |
| -------------- | -------- | ----------------------------- | --------------------------------- |
| `orchestrator` | primary  | DeepSeek V4 Pro (`#high`)     | Explora, planeja, delega e revisa |
| `implementer`  | subagent | DeepSeek V4.1 Flash (`#high`) | Edita, roda testes e reporta      |

Com acesso somente ao OpenCode Go, o orquestrador usa o DeepSeek V4 Pro para
economizar créditos. Se quiser mais qualidade de planejamento, troque para Kimi
K3.1 Pro, Gemini 4 Argon ou Grok 4.7.

O `orchestrator` tem as ferramentas de edição bloqueadas (`edit: deny`): na
prática, quem altera código é o `implementer`. O shell fica liberado para
inspeção e testes. Ele também só pode lançar o subagente `implementer`.

### Como usar

1. No seletor de agentes da TUI ou da CLI do OpenCode, escolha `orchestrator`.
   No T3 Code com OpenCode 2.x, esse seletor customizado não aparece (veja a
   nota acima).
2. Peça a tarefa com critérios de aceite: "Implemente X. Deve passar em Y."
3. O orquestrador explora, monta o briefing, chama o `implementer`, confere o
   diff e roda as checagens.
4. Se quiser torná-lo padrão, adicione no `opencode.jsonc` (o T3 pode
   sobrescrever com `build`):

```jsonc
{
  "default_agent": "orchestrator",
}
```

5. Se o agente não aparecer na hora, rode `/reload`.

### Quando usar este setup

- Feature ou bug que envolve vários arquivos.
- Refactor com comportamento que precisa ser preservado.
- Tarefa em que o "como fazer" não é óbvio, mas o "pronto" é verificável.

### Quando usar um modelo só

- Perguntas, explicações e exploração de código.
- Correções triviais.
- Quando não existe teste ou critério objetivo para validar.

## 5. Roteamento de custo

Preços do catálogo do OpenCode em nov/2026, em USD por 1 milhão de tokens
(confira os valores atuais antes de decidir):

| Modelo                                          | Input | Output | Cache read |
| ----------------------------------------------- | ----- | ------ | ---------- |
| Kimi K3.1 Pro (Go) — orquestrador mais forte    | $2,00 | $10,00 | $0,20      |
| DeepSeek V4 Pro (Go) — orquestrador atual       | $0,66 | $1,98  | $0,022     |
| DeepSeek V4.1 Flash (Go) — executor             | $0,15 | $0,60  | $0,003     |
| Claude Opus 5.5 (Console) — referência do tweet | $4,00 | $20,00 | $0,20      |

Com Go, executar no Flash custa cerca de 4,4 vezes menos no input e 3,3 vezes
menos no output que planejar no DeepSeek V4 Pro. Se quiser mais capacidade de
planejamento, o Kimi K3.1 Pro custa $2/$10, e a execução no Flash fica cerca de
13 vezes mais barata no input e 17 vezes no output que ele.

As variantes (`#low`, `#high`, `#max`) controlam o esforço de raciocínio do
modelo. Use `#high` como padrão e `#max` só em tarefas realmente difíceis.

## 6. Boas práticas

- [ ] **Briefing completo.** O subagente começa sem contexto: inclua objetivo,
      arquivos, restrições e critérios de aceite.
- [ ] **Uma tarefa por subagente.** Não misture refactor, feature e correção no
      mesmo pedido.
- [ ] **Sempre verifique.** Leia o diff e rode os testes; nunca aceite o
      relatório do executor sem checar.
- [ ] **Tarefa simples não delega.** O overhead de planejar e revisar não
      compensa.
- [ ] **Defina o "pronto".** Sem critério verificável, orquestração vira
      conversa.
- [ ] **Cuidado com o escopo.** Instrua o executor a não expandir o trabalho.
- [ ] **Permissões são cinto de segurança.** O orquestrador sem `edit` força a
      delegação; o executor continua com acesso de escrita.
- [ ] **Commits ficam com você.** A menos que peça explicitamente, agente não
      faz commit nem push.

## 7. Armadilhas

- **Perda no handoff.** O maior risco é o executor não receber contexto
  suficiente e "adivinhar". Briefing ruim = retrabalho.
- **Loops.** Orquestrador e executor podem ficar se corrigindo sem fim. Se
  duas tentativas falharem, pare e reavalie o plano.
- **Overhead.** Cada delegação adiciona latência e tokens. Em tarefa pequena,
  o resultado sai mais lento e mais caro.
- **Multi-agente não é automaticamente melhor.** Em tarefas acopladas ou sem
  verificação, um modelo único costuma ganhar.
- **Falsa sensação de segurança.** O relatório do executor não substitui teste,
  lint e leitura do diff.

## 8. Cola rápida

**Pedido bom para o orquestrador:**

```text
Implemente validação de e-mail no formulário de cadastro.
Critérios de aceite:
- e-mails inválidos mostram erro inline;
- o teste tests/signup.test.ts passa;
- sem mudanças fora de src/signup/.
Rode a suíte relevante e me mostre o diff resumido.
```

**Pedido que não precisa de orquestração:**

```text
Explique como funciona o cache deste projeto.
```

**Sinais de que era melhor não orquestrar:**

- o briefing tem mais linhas que a mudança;
- o executor voltou sem saber o que fazer;
- você passou mais tempo revisando do que teria levado para fazer.

## Referências

- Tweet original: https://x.com/TheAhmadOsman/status/2115249215802896719
- Documentação de agentes do OpenCode: https://opencode.ai/docs/agents
- Configuração do OpenCode: https://opencode.ai/docs/config
- OpenChamber: https://openchamber.dev/ — https://github.com/openchamber/openchamber
- Hermes Agent: https://hermes-agent.nousresearch.com/ — https://github.com/NousResearch/hermes-agent
- OpenBot: https://openbot.run/ — https://github.com/CopilotKit/openbot
- Grok Bot: https://x.ai/bot
- Comparativo com 36 agentes de código: https://openchamber.dev/blog/ai-coding-agents/
