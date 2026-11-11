# Plan: fluxo enxuto do Builder, adaptado do Akita

## Goal
Um agente com skills: entender, planejar se necessario, implementar/testar/revisar
uma unidade por vez, fazer commits autorizados e entregar por PR quando solicitado.
Aprender com problemas reais, sem modos de execucao, ai-memory ou nova orquestracao.

## Acceptance criteria

Implementados nas instrucoes e conferidos por leitura cruzada e ensaios locais.
Isto nao comprova obediencia do modelo nem execucao real de PR/CI; veja as
limitacoes e evidencias em progress.md.

- [x] Um pedido explicito que inclua implementacao, commits e PR autoriza essa
  sequencia no escopo definido; nao exige outro "ok" por etapa. Pedidos limitados
  continuam limitados; pausas adicionais ocorrem nos pontos pedidos pelo usuario.
- [x] A branch e a base de comparacao sao definidas antes de implementar; commits
  pequenos so apos validacao focada e review. O conjunto final tem revisao e
  verificacoes aplicaveis antes de publicar, sem repetir toda a suite por commit.
- [x] Review abrange tambem commits ja feitos e mudancas nao commitadas, nao apenas
  um `git diff` vazio. Evidencias correspondem ao candidato realmente entregue.
- [x] Draft PR, CI no SHA publicado e limitacoes sao relatados com precisao.
  Bloqueios preservam o trabalho; nao se promete arvore limpa ou testes verdes.
- [x] Somente uma skill nova: reflect. Melhorias globais sao propostas, nao
  aplicadas silenciosamente; registrar uma licao nao exige inventar nova regra.

## Constraints and invariants
- Implementacao aprovada pelo usuario em 2026-11-10; executar as oito tarefas
  e a validacao, inicialmente sem commit ou publicacao do dotfiles.
- Entrega autorizada posteriormente em 2026-11-10: instalar no perfil real
  do Copilot, fazer commit e push de agent/builder-workflow. Nao abrir PR;
  o usuario fara isso. O remoto usa main como principal, nao master.
- Manter a skill Notion e sua integracao preexistentes fora do commit,
  preservadas na arvore local. A entrega publica inclui cinco skills;
  o perfil local continua com as seis skills, incluindo Notion.
- Manter permissoes do CLI e restricoes do projeto. Nao usar --auto/yolo, tratar
  worktree como sandbox ou executar contribuicao suspeita nesta maquina compartilhada.
- Sem commits nas branches principais/protegidas, force push, descarte ou
  merge/release/deploy implicitos. Preservar alteracoes locais existentes.
- Adaptar os principios com redacao propria; nao copiar premissas, comandos
  destrutivos, especialistas ou configuracoes pessoais do Akita.

## Tasks and likely areas
Paths de skills abaixo sao relativos a `config/agent-workflow/skills/`.
Cada linha e uma unidade de implementacao com seu aceite e verificacao.

| Task / files | Decisao e mudanca | Aceite e validacao |
| --- | --- | --- |
| 1. `config/opencode/agents/builder.md`, `config/copilot/agents/builder.agent.md` | Manter o nome Builder, reescrever o corpo como entrada leve para skills. Remover gates repetidos de etapas ja autorizadas; preservar escopo, pausas pedidas, decisoes materiais e permissoes. Em T3, worktrees sao vinculadas pela ferramenta nativa, nao pelo shell. | Perfis com o mesmo fluxo, sem orquestracao implicita; comparar cenarios de plano apenas, execucao local, entrega ate PR e pausa por entrega. |
| 2. `plan/SKILL.md` | Manter plano/progresso de uma pagina; adaptar verification-planning para explicitar resultado, invariantes e evidencia que o comprova. Nao exigir plano formal apenas por tocar varios arquivos. | Plano sem codigo nem especificacao pesada; execucao previamente autorizada nao pede novo ok sem decisao material. Conferir cenarios pequeno, arriscado e pedido exclusivamente de plano. |
| 3. `implement/SKILL.md` | Reescrever o nucleo com o loop de github-resolution: reproducao quando viavel, correcao minima, teste focado, review e commit autorizado via ship. Aceitar tarefa clara sem exigir plano artificial. Duas falhas exigem reavaliar a hipotese, nao parar automaticamente; sem progresso verificavel, relatar bloqueio. | Corrige achados do proprio escopo e continua sem nova aprovacao por unidade; nunca enfraquece testes ou publica apesar de bloqueio. Conferir tarefas com/sem plano, falhas e autorizacao so local. |
| 4. `review/SKILL.md` | Adaptar pr-audit/pr-post-audit: evidencia independente, base/SHA explicitos, diff acumulado e interacoes entre mudancas. Absorver simplify como criterio de clareza, sem criar skill extra nem refatorar durante a revisao. | Continua read-only; inclui commits, staged/unstaged e arquivos novos. Conferir um caso com arvore limpa mas commits pendentes de review e outro com mudancas locais; codigo nao confiavel recebe analise estatica antes de qualquer execucao. |
| 5. `ship/SKILL.md` | Reescrever entrega: commits coerentes no escopo autorizado, gate final, conferir remote/base/refspec, push da branch e draft PR quando pedidos. Registrar CI do SHA entregue; nao fechar issues como resolvidas so por abrir draft PR. Manter release como pedido separado, seguindo politica do projeto, sem importar o pipeline do Akita. | Commit nao implica push; PR nao implica merge/release; nunca escreve na principal nem forca push. Ensaiar Git em repo temporario, incluindo destino protegido, remote ausente e push rejeitado. |
| 6. Novo `reflect/SKILL.md` | Adaptar reflect, sem dependencias de orquestrador/oh-my-opencode-slim: examinar evidencia do trabalho autorizado, detectar atritos recorrentes e propor a menor melhoria, inclusive nenhuma. Uso sob pedido; mudancas de skills/config exigem aprovacao. | Nao vasculha dados de outros projetos, duplica skills ou muda permissoes sozinho. Conferir repeticao comprovada, evento isolado e problema ja coberto por regra existente. |
| 7. `config/agent-workflow/templates/AGENTS.md` e `templates/memory/handoff.md` | Manter contexto e memoria locais; alinhar autorizacao por escopo e definicao de pronto. Handoff registra branch/SHA, evidencias e bloqueios quando aplicaveis. decisions/gotchas permanecem como estao. | Sem novo formulario de autorizacao ou migracao automatica; projetos existentes nao sao sobrescritos. Conferir template contra as skills e inicializador em projeto ja preparado. |
| 8. `docs/{fluxo-de-trabalho,fluxo-copilot,orquestracao-de-agentes}.md` | Reescrever exemplos para um fluxo unico; documentar reflect, pausas pedidas e diferencas para o Akita. Manter instaladores/inicializador, cujos loops ja descobrem novas skills; mudar apenas se a verificacao revelar dependencia direta. | Sem contradicoes sobre planos, commits ou duas tentativas. Instalacao repetida expoe as skills da entrega e preserva arquivos/skills locais existentes. |

## Validation
- Leitura cruzada de perfis, frontmatter, skills, templates e exemplos; os cenarios
  acima sao revisao de instrucoes, nao prova automatizada do comportamento do modelo.
- `git diff --check`; `bash -n` em `config/opencode/scripts/install.sh`,
  `config/copilot/scripts/install.sh` e `config/agent-workflow/scripts/init-agent-workflow.sh`.
- Rodar instaladores duas vezes com HOME/XDG temporarios; conferir links e
  inicializador sem sobrescrita. Ensaiar operacoes Git so em repo/remote bare temporarios.
- Um ensaio Git nao comprova protecao por prompt nem criacao real de PR.
  Declarar carga do harness, gh/T3 e CI nao validados onde nao forem exercitados;
  qualquer teste real depende de ambiente isolado e autorizacao apropriada.

## Deliberately not imported
ai-memory; modos interactive/checkpoint/autonomous; deepwork/loop-engineering;
pipeline completo de auditoria de issues/PRs; especialistas obrigatorios;
limiar de mais de tres tickets; skill worktrees; limpeza/release automatica.
Notion, modelos e agentes legados ficam intocados: remove-los nao e requisito do fluxo.

## Sources and open questions
Comparacao com as skills verification-planning, github-resolution, pr-audit,
pr-post-audit, simplify, reflect, deepwork e release em:
https://github.com/akitaonrails/my-skills
Workflow: https://ailair.akitaonrails.com/pt-br/workflow/
Escopo aprovado em 2026-11-10; instalacao real, commit e push da branch foram
autorizados depois da implementacao. A criacao da PR permanece com o usuario.
