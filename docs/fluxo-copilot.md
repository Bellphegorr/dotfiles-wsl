# Fluxo de trabalho no GitHub Copilot

Este guia cobre a integração específica do Copilot CLI. As regras do fluxo,
as skills e o formato dos planos são compartilhados com o OpenCode e estão em
[Fluxo de trabalho com o builder](fluxo-de-trabalho.md).

Os perfis dos agentes e as skills são instalados no perfil pessoal do Copilot.
Já `agent-workflow-init` cria `AGENTS.md` e `.agents/` no projeto para guardar
instruções, memória e planos desse repositório.

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

Para expor uma skill nova, como `reflect`, rode novamente o instalador:
os links são individuais. As skills já ligadas apontam para a fonte compartilhada,
mas uma sessão em andamento pode precisar reiniciar para reler mudanças.

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
teste, lint, typecheck e build, além dos invariantes e da política de branches.
Alterar os templates do dotfiles não migra projetos existentes automaticamente.

O mesmo `AGENTS.md`, memória e artefatos de trabalho podem ser lidos pelo
Copilot e pelo OpenCode. A memória deve conter apenas conhecimento apropriado
para o repositório; não coloque credenciais, dados privados ou contexto de
outro projeto.

## Usar o fluxo compartilhado

No CLI, use `/agent` e escolha **Builder**. Para mudanças pequenas e claras,
peça a implementação diretamente. O Builder usa `plan` quando incerteza, risco
ou seu pedido justificam um plano, não apenas por haver vários arquivos.
Se você já autorizou a execução do escopo, ele segue depois de planejar;
se pediu só um plano, ele espera.

Um pedido como “implemente X, valide, faça commits pequenos e abra um PR”
autoriza essa sequência sem novo “ok” por tarefa. “Faça commit” fica local;
PR não autoriza merge/release. Para avaliar entregas intermediárias, acrescente
“pare depois do plano” ou “pare a cada entrega”. As permissões do CLI/T3 e as
restrições do projeto continuam valendo; o Builder não as desativa.

As seis skills são compartilhadas: `plan`, `implement`, `review`, `ship`,
`reflect` e `notion-note`. O Copilot as carrega quando relevantes; também é
possível pedir explicitamente, como “use reflect para propor melhorias com
base nesta tarefa”. Reflexão não autoriza mudanças globais silenciosas.

`notion-note` salva ou atualiza notas no Second Brain e requer o MCP do Notion.
As regras de preenchimento ficam no próprio `SKILL.md`.

Para branch/PR, validação, bloqueios e artefatos, consulte o
[guia compartilhado](fluxo-de-trabalho.md). No T3, uma worktree necessária deve
ser vinculada à thread pelas ferramentas nativas; não é uma sandbox de execução.

## Agentes legados

`Planner 0.2` e `Agent 0.2` continuam versionados e instaláveis. Eles usam o
formato antigo de cinco arquivos (`request.md`, `prd.md`,
`execution-plan.md`, `tasks.md` e `progress.md`). Para o fluxo novo, escolha
**Builder** e não misture os dois formatos na mesma tarefa.

## Arquivos

| Caminho | Finalidade |
| --- | --- |
| `config/copilot/agents/builder.agent.md` | Agente principal do fluxo novo; o corpo é gerado de `config/agent-workflow/agents/builder.md` ([como editar](fluxo-de-trabalho.md#editar-o-builder)) |
| `config/agent-workflow/skills/` | Skills compartilhadas com o OpenCode |
| `config/copilot/agents/{planner,agent}.agent.md` | Agentes legados |
| `config/agent-workflow/templates/` | Templates compartilhados |
| `config/copilot/scripts/install.sh` | Instala o agente Copilot e expõe as skills compartilhadas |
| `config/agent-workflow/scripts/init-agent-workflow.sh` | Prepara o contexto de um projeto |

Ao integrar outro harness, siga a seção
[Adicionar outro harness](fluxo-de-trabalho.md#adicionar-outro-harness) em vez
de duplicar skills ou templates.

Referências oficiais: [custom agents no Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli) e [agent skills no Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills).
