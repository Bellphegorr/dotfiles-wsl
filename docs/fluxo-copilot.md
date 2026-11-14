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

Para expor uma skill nova, como `reflect`, ou limpar um agente aposentado, rode
novamente o instalador: os links são individuais e links órfãos são removidos.
As skills já ligadas apontam para a fonte compartilhada, mas uma sessão em
andamento pode precisar reiniciar para reler mudanças.

Para conferir e escolher agentes no CLI, use `/agent`. O **Builder** é o único
agente ativo; os antigos `Planner 0.2` e `Agent 0.2` foram aposentados.

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
peça a implementação diretamente. O Builder usa `planning` quando incerteza, risco
ou seu pedido justificam um plano, não apenas por haver vários arquivos.
Se você já autorizou a execução do escopo, ele segue depois de planejar;
se pediu só um plano, ele espera.

Não há regra fixa de commit, push ou publicação: diga no pedido o que quer, por
exemplo “implemente e commite”, “não commite”, “dê push” ou “abra um PR”. Para
avaliar entregas intermediárias, acrescente “pare depois do plano” ou “pare a
cada entrega”. As permissões do CLI/T3 e as restrições do projeto continuam
valendo; o Builder não as desativa.

As sete skills são compartilhadas: `planning`, `orchestrate`, `implement`,
`change-review`, `ship`, `reflect` e `notion-note`. O Copilot as carrega quando
relevantes; também é possível pedir explicitamente, como “use reflect para
propor melhorias com base nesta tarefa”. Reflexão não autoriza mudanças globais
silenciosas.

Os nomes `planning` e `change-review` evitam os comandos nativos `/plan` e
`/review` do Copilot CLI. O `name` do frontmatter é sempre lowercase e igual ao
nome do diretório, como exige a especificação de skills.

`notion-note` salva ou atualiza notas no Second Brain e requer o MCP do Notion.
As regras de preenchimento ficam no próprio `SKILL.md`.

Para branch/PR, validação, bloqueios e artefatos, consulte o
[guia compartilhado](fluxo-de-trabalho.md). No T3, uma worktree necessária deve
ser vinculada à thread pelas ferramentas nativas; não é uma sandbox de execução.

## Agentes antigos

`Planner 0.2` e `Agent 0.2` foram aposentados. O formato antigo de cinco
arquivos não é mais usado; o fluxo ativo é o Builder com `plan.md` e
`progress.md`. O histórico fica no git.

## Arquivos

| Caminho | Finalidade |
| --- | --- |
| `config/copilot/agents/builder.agent.md` | Agente principal; o corpo é gerado de `config/agent-workflow/agents/builder.md` ([como editar](fluxo-de-trabalho.md#editar-o-builder)) |
| `config/agent-workflow/skills/` | Skills compartilhadas com o OpenCode |
| `config/agent-workflow/templates/` | Templates compartilhados |
| `config/copilot/scripts/install.sh` | Instala o agente Copilot e expõe as skills compartilhadas |
| `config/agent-workflow/scripts/init-agent-workflow.sh` | Prepara o contexto de um projeto |

Ao integrar outro harness, siga a seção
[Adicionar outro harness](fluxo-de-trabalho.md#adicionar-outro-harness) em vez
de duplicar skills ou templates.

Referências oficiais: [custom agents no Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli) e [agent skills no Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills).
