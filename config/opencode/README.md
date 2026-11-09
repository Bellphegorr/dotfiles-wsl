# OpenCode — agentes

## Em uso (instalados)

Instalados em `~/.config/opencode/agent/` e versionados em
`config/opencode/agent/`:

| Agente        | Modo    | Modelo             | Papel                                                                                                                       |
| ------------- | ------- | ------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| `agent-0.2`   | primary | herdado da sessão  | Implementação e orquestração de uma fase aprovada, com artefatos em `.agents/work/` e gates de aprovação humana (HITL).      |
| `planner-0.2` | primary | herdado da sessão  | Planejamento portátil com artefatos fixos em `.agents/work/` (request, PRD, execution, tasks e progress) antes da implementação. |

## Em teste (ainda não instalados)

Versionados em `config/opencode/agents/`, mas **não instalados** em
`~/.config/opencode/agents/`:

| Agente         | Modo     | Modelo                        | Papel                                                    |
| -------------- | -------- | ----------------------------- | -------------------------------------------------------- |
| `orchestrator` | primary  | DeepSeek V4 Pro (`#high`)     | Planeja, delega ao `implementer` e revisa o resultado.   |
| `implementer`  | subagent | DeepSeek V4.1 Flash (`#high`) | Edita arquivos, roda testes e reporta o que foi feito.   |

Para ativar o setup de teste:

```bash
mkdir -p ~/.config/opencode/agents
cp config/opencode/agents/*.md ~/.config/opencode/agents/
opencode debug agents
```

O `implementer` é `subagent`, então não aparece no seletor de agentes
principais; quem o chama é o `orchestrator`.

## T3 Code

No T3 Code 0.1.7 com OpenCode 2.x, o seletor de agentes customizados não
aparece: o caminho do OpenCode 2 monta apenas as variantes de raciocínio e cai
no fallback fixo **Build/Plan**. Use a TUI ou a CLI do OpenCode para escolher
`agent-0.2` ou `planner-0.2`:

```bash
opencode run --agent agent-0.2 "..."
opencode run --agent planner-0.2 "..."
```
