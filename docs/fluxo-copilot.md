# Fluxo de trabalho no GitHub Copilot

Este fluxo adapta o `builder` do OpenCode ao Copilot CLI. Os agentes e skills
ficam versionados neste repositório e podem ser instalados no perfil pessoal do
Copilot, sem colocar configuração pessoal dentro de repositórios de trabalho.

## Instalação pessoal

Na raiz do dotfiles:

```bash
bash config/copilot/scripts/install.sh
```

O instalador cria links para os agentes em `~/.copilot/agents/`, expõe as
skills compartilhadas de `config/agent-workflow/` em `~/.copilot/skills/` e
instala o comando comum `agent-workflow-init` (mantém também
`copilot-workflow-init` como alias). Arquivos existentes diferentes são
preservados em `~/.local/state/copilot-dotfiles-backup/`. Reinicie o Copilot
CLI depois da instalação.

Para conferir e escolher agentes no CLI, use `/agent`. Escolha **Builder** para
o fluxo novo. Os agentes `Planner 0.2` e `Agent 0.2` continuam disponíveis
como fluxo legado.

## Preparar um projeto

```bash
cd ~/caminho/do/projeto
agent-workflow-init .
```

O comando cria `AGENTS.md`, `.agents/memory/` e `.agents/work/` sem
sobrescrever arquivos existentes. Preencha `AGENTS.md` com os comandos de
teste, lint, typecheck e build, além dos invariantes do projeto.

O mesmo `AGENTS.md`, memória e artefatos de trabalho podem ser lidos pelo
Copilot e pelo OpenCode. A memória deve conter apenas conhecimento apropriado
para o repositório; não coloque credenciais, dados privados ou contexto de
outro projeto.

## Como o Builder trabalha

| Pedido | Comportamento |
| --- | --- |
| Pergunta, explicação ou exploração | Responde diretamente |
| Mudança pequena e clara | Implementa e valida diretamente |
| Mudança multi-arquivo, ambígua ou arriscada | Usa `plan`, apresenta o plano e espera aprovação explícita |
| Plano aprovado | `implement` executa uma tarefa aprovada por vez |
| Implementação concluída | `review` inspeciona o diff sem editar |
| Commit, push ou release | `ship` só é usado quando você pedir |

As skills são carregadas pelo Copilot quando relevantes. Também é possível
pedir, por exemplo, "Use a skill plan para propor a mudança". O Builder não
deve começar a implementar enquanto um plano aguarda aprovação.

O formato de planejamento é compartilhado com o OpenCode:

```text
.agents/work/<slug>/
├── plan.md
└── progress.md
```

O `plan.md` contém objetivo, critérios de aceite, restrições, tarefas e
validação. `progress.md` registra estado, evidências, decisões e bloqueios.
Planos devem ser curtos; requisitos detalhados adicionais só são necessários
quando a tarefa realmente pede uma especificação maior.

## Agentes legados

`Planner 0.2` e `Agent 0.2` continuam versionados e instaláveis. Eles usam o
formato antigo de cinco arquivos (`request.md`, `prd.md`,
`execution-plan.md`, `tasks.md` e `progress.md`). Para o fluxo novo, escolha
**Builder** e não misture os dois formatos na mesma tarefa.

## Arquivos

| Caminho | Finalidade |
| --- | --- |
| `config/copilot/agents/builder.agent.md` | Agente principal do fluxo novo |
| `config/agent-workflow/skills/` | Skills compartilhadas com o OpenCode |
| `config/copilot/agents/{planner,agent}.agent.md` | Agentes legados |
| `config/agent-workflow/templates/` | Templates compartilhados |
| `config/copilot/scripts/install.sh` | Instala o agente Copilot e expõe as skills compartilhadas |
| `config/agent-workflow/scripts/init-agent-workflow.sh` | Prepara o contexto de um projeto |

Referências oficiais: [custom agents no Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli) e [agent skills no Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills).
