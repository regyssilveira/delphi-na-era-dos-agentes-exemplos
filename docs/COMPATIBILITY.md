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

Antes de adotar uma versão nova do MCP, siga
[o roteiro de atualização](PROTOCOL_UPGRADE.md).
