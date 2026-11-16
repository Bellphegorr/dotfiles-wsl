# Multiagentes: quando usar e o que aprendi

> O que é orquestração, quando vale a pena e o que os pilotos mostraram.
> Atualizado em 16/11/2026. O fluxo diário está em
> [fluxo-de-trabalho.md](fluxo-de-trabalho.md); o playbook pesado está em
> [trabalho-pesado-com-workers.md](trabalho-pesado-com-workers.md) e o mapa de
> ferramentas em [mapa-de-ferramentas.md](mapa-de-ferramentas.md).

## 1. O conceito

Orquestrar é dividir um trabalho entre agentes com contextos separados, em vez
de pedir tudo a um modelo só. O desenho clássico:

```text
Você
└── Orquestrador — planeja, divide e revisa
    └── Executor — implementa, testa e reporta
```

A promessa: contexto limpo para o executor e o orquestrador cuidando do
planejamento e da revisão, sem carregar o histórico inteiro.

Trocar de modelo à mão no meio da conversa **não** é orquestração; é
roteamento manual.

## 2. Na prática: um agente bom ganha

Os testes do Akita (nov/2026) mostram que, para código do dia a dia, a
promessa não se paga:

- Um modelo bom sozinho no OpenCode: **97/100, 18 min, ~$4**.
- Planejador + executor: **90–95/100, +7 a +35 min**. Nenhuma combinação bateu
  o solo em qualidade, tempo e custo ao mesmo tempo.
- Uma cadeia de 10 agentes com 90% de acerto por etapa acerta ~35% no fim.
- A Anthropic reporta ~15x mais tokens em multi-agente e cita código como um
  domínio ruim para isso.

O motivo: código é trabalho acoplado. Cada peça depende da outra, então
dividir só adiciona repasse de contexto, latência e retrabalho. É como
`Promise.all` em chamadas que dependem umas das outras: não paraleliza nada.

O que funciona melhor:

- **um agente por projeto**, com um modelo bom para a tarefa;
- **skills** (`SKILL.md`) para procedimentos recorrentes;
- **`AGENTS.md`** com comandos, invariantes e armadilhas;
- **memória em arquivo** por projeto;
- **verificação** por testes, CI e revisão humana;
- **falhas comprovadas viram testes ou lições úteis**, sem criar regras
  automaticamente para cada erro.

É o que o [fluxo do builder](fluxo-de-trabalho.md) implementa. O uso de subagentes
fica a cargo do harness, sem regras adicionais nos perfis do Builder.

### O que adaptamos do Akita

Mantemos um agente como ponto de entrada e usamos as skills como procedimentos,
sem adicionar modos de execução ou um novo orquestrador. As instruções foram
adaptadas ao nosso ambiente, não copiadas com as premissas pessoais dele:

| No nosso fluxo | Referência do Akita |
| --- | --- |
| `planning`: resultado e evidência proporcional | `verification-planning` |
| `implement`: uma unidade, teste, revisão e entrega conforme o pedido | `github-resolution` |
| `change-review`: evidência independente e revisão do conjunto final | `pr-audit`, `pr-post-audit` |
| Critério de clareza dentro de `change-review`, sem skill extra | `simplify` |
| `reflect`: melhorar o processo com evidência e aprovação | `reflect` |
| `ship`: entrega conforme o pedido e checks no SHA entregue | Limites de `github-resolution` e `release` |

O pedido do usuário define o caminho até o PR e as pausas, em linguagem comum,
como “pare a cada entrega”. Isso reduz aprovações repetidas do procedimento,
não as permissões reais do harness.

Nosso ponto de entrega é **draft PR**, sem merge, release ou deploy implícito.
O fluxo dele também prevê merges autorizados. Não importamos o pipeline inteiro,
especialistas obrigatórios, limiares por quantidade de tickets, limpeza
automática ou uma skill para worktrees: no T3, a vinculação da worktree é
responsabilidade das ferramentas nativas. Worktree não isola execução.

Kaizen é a prática de aprender com o trabalho; a skill pública usada como
referência para essa reflexão chama-se `reflect`. Ela pode concluir que nada
precisa mudar. Mudanças nas próprias skills/configurações exigem aprovação;
não há obrigação de criar uma nova regra após cada tarefa.

## 3. Quando multi-agente vale

| Situação | Multi-agente? |
| --- | --- |
| Pergunta, explicação, ajuste pequeno | Não |
| Feature ou refactor num projeto | Execução direta por padrão; delegação pontual se trouxer benefício |
| Leitura, investigação ou revisão independente com escopo claro | Sim, quando o contexto separado compensar o custo |
| Muitas tarefas **independentes** (mesmo refactor em 20 repos, varrer 500 arquivos) | Sim, em paralelo |
| Operação noturna com verificador independente e orçamento | Talvez |
| Tarefa ambígua | Não — esclareça antes |

**Regra de bolso:** só divida o que não depende entre si. Se o briefing fica
maior que a tarefa, não divida.

O desenho operacional para o caso pesado — papéis, artefatos, gates e stops —
está em [trabalho-pesado-com-workers.md](trabalho-pesado-com-workers.md).

## 4. Ferramentas

O mapa de camadas (modelos, harness, cockpit, MCP etc.) e os exemplos estão em
[mapa-de-ferramentas.md](mapa-de-ferramentas.md).

## 5. Escolha de modelo

Use um modelo bom para o papel. Nomes, preços e variantes mudam rápido, então a
escolha fica na configuração, não neste guia. O critério continua sendo
evidência: teste, diff revisado e validação real.

## 6. O que os pilotos no T3 mostraram

Em nov/2026 rodei três pilotos com o T3 Code:

1. **Research read-only.** Três agentes com escopos independentes, em paralelo,
   produziram relatórios curtos em ~4 min, sem editar arquivo. Funcionou bem
   para inventário e auditoria.
2. **Implementação.** Duas fatias independentes em worktrees separadas, com
   merge limpo e suíte completa verde. O contrato foi o que garantiu a
   independência: cada worker só podia editar os próprios arquivos.
3. **Review independente.** Um revisor separado, vendo só diff e critério de
   aceite, encontrou um bug de Unicode que os testes dos implementadores não
   pegavam. O pai corrigiu e adicionou regressão.

Lições:

- delegue só o que é independente;
- um dono por arquivo/área;
- brief autossuficiente e relatório curto;
- verificador independente pega o que o executor não vê;
- `isolation: "worktree"` do T3 exige um projeto cuja raiz seja o repo; no
  scratch, use worktree manual ou um projeto dedicado.

## Referências

- Workflow do Akita: https://ailair.akitaonrails.com/pt-br/workflow/
- Skills do Akita, usadas como referência para adaptação:
  https://github.com/akitaonrails/my-skills
- Hot take: Harness, Loop Engineering, Graph Engineering são Bullshit:
  https://akitaonrails.com/2026/08/18/hot-take-harness-loop-engineering-graph-engineering-sao-bullshit/
- Vale a pena misturar 2 modelos?:
  https://akitaonrails.com/2026/04/25/llm-benchmarks-vale-a-pena-misturar-2-modelos/
- Tweet que motivou o teste: https://x.com/TheAhmadOsman/status/2115249215802896719
