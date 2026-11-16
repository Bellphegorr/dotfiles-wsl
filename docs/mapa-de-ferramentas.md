# Mapa de ferramentas

> Camadas de ferramentas que aparecem quando se trabalha com agentes, o que
> cada uma resolve e o que uso hoje. O fluxo diário está em
> [fluxo-de-trabalho.md](fluxo-de-trabalho.md); as decisões sobre dividir
> trabalho estão em [multiagentes.md](multiagentes.md).

Ferramenta é camada. Um cockpit não substitui o harness, e um assistente
pessoal não substitui o agente de código.

## Camadas

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

## O que você quer?

```text
O que você quer?
├── Codar no repositório → OpenCode + builder
├── Mesma mudança em muitos lugares independentes → subagentes/worktrees em paralelo
├── Interface, celular, comparar modelos → T3 Code ou OpenChamber
├── Delegar uma issue e receber PR → OpenHands / Devin / Jules
├── Assistente pessoal 24/7 → Hermes / OpenBot / Grok Bot
└── Construir um produto de agentes → LangGraph / CrewAI / SDKs
```

## Harnesses e cockpit em uso

- **Harnesses:** OpenCode e GitHub Copilot CLI, com o mesmo Builder e as mesmas
  skills compartilhadas.
- **Cockpit:** T3 Code, usado com o OpenCode para sessões, diffs e worktrees.

## Referências

- Agentes do OpenCode: https://opencode.ai/docs/agents
- Configuração do OpenCode: https://opencode.ai/docs/config
- Copilot CLI: https://docs.github.com/en/copilot/how-tos/copilot-cli
- OpenChamber: https://openchamber.dev/
- Hermes Agent: https://hermes-agent.nousresearch.com/
- OpenBot: https://openbot.run/
- Grok Bot: https://x.ai/bot
- Comparativo com 36 agentes de código: https://openchamber.dev/blog/ai-coding-agents/
