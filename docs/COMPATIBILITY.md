# Compatibilidade e limites

| Item | Situação desta versão |
| --- | --- |
| MCP | `2026-07-28` moderno e `2025-11-25` em compatibilidade |
| Transporte | `stdio`, JSON-RPC UTF-8 delimitado por nova linha |
| Descoberta | `server/discover` |
| Tools | consulta de cliente, produto e estoque; preparação de orçamento |
| Resources e prompts | uma policy e um prompt didáticos |
| Resultado estruturado | entregue em `structuredContent` e também como texto JSON |
| Rede | não implementada |
| Autenticação | não implementada; não exponha este executável em rede |
| Efeitos críticos | bloqueados; não há confirmação, baixa de estoque ou emissão fiscal |

O perfil moderno exige `_meta` por requisição. O perfil legado usa `initialize` e
`notifications/initialized` no mesmo processo. O Inspector CLI foi exercitado com
`tools/list` e `tools/call`; isso não equivale a validar todo host ou toda extensão MCP.

## Matriz de interoperabilidade observada

Esta matriz relata testes, não uma garantia universal. Versões não testadas
ficam como **não verificadas**, mesmo quando anunciam suporte a MCP.

| Cliente/host | Versão e ambiente | Perfil e transporte | Exercício | Resultado | Limite |
| --- | --- | --- | --- | --- | --- |
| Cliente Delphi do exemplo | Checkout desta edição, Windows/Delphi 13 | `2026-07-28`, chamada em memória | `server/discover`, `tools/list`, `tools/call` | Passou na suíte Delphi em 15/09/2026 | Não inicia processo nem representa um host de IA |
| Teste Delphi de processo | Checkout desta edição, Windows/Delphi 13 | `2026-07-28`, `stdio` | Processo filho, UTF-8, `stdout`/`stderr`, fechamento | Passou em 15/09/2026 | Não avalia decisão de agente |
| MCP Inspector CLI | Execução documentada no QUICKSTART | Perfil negociado pelo Inspector, `stdio` | `tools/list`, `tools/call` | Passou no recorte documentado | Não prova conformidade completa ou todos os hosts |
| Codex CLI | `0.147.0`, Windows, 15–16/09/2026 | Perfil negociado pelo host, `stdio` | Consulta isolada e conversa composta com quatro tools | Passou com banco fictício isolado e acesso local amplo | Sandbox `read-only` descobriu a tool, mas cancelou a chamada; ver HOST_CODEX_CLI.md |
| Outros hosts | Não verificados | Não verificado | Nenhum | Sem alegação | Validar versão, descoberta, chamada, política e efeitos antes de usar dados reais |

Não inferimos o perfil efetivamente escolhido pelo Codex CLI apenas da chamada
bem-sucedida: esse dado deve vir de captura do tráfego ou diagnóstico do host.
O servidor oferece `2025-11-25` e `2026-07-28`, mas um resultado funcional não
identifica sozinho qual caminho foi exercitado. Para detalhes e comandos do
teste de host, veja [HOST_CODEX_CLI.md](HOST_CODEX_CLI.md).

Antes de adotar uma versão nova do MCP, siga
[o roteiro de atualização](PROTOCOL_UPGRADE.md).
