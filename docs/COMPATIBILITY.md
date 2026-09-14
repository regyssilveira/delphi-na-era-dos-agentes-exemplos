# Compatibilidade e limites

| Item | Situação desta versão |
| --- | --- |
| MCP | `2026-07-28`, perfil moderno e sem estado |
| Transporte | `stdio`, JSON-RPC UTF-8 delimitado por nova linha |
| Descoberta | `server/discover` |
| Tools | consulta de cliente, produto e estoque; preparação de orçamento |
| Resources e prompts | uma policy e um prompt didáticos |
| Resultado estruturado | entregue em `structuredContent` e também como texto JSON |
| Rede | não implementada |
| Autenticação | não implementada; não exponha este executável em rede |
| Efeitos críticos | bloqueados; não há confirmação, baixa de estoque ou emissão fiscal |

Esta matriz descreve o que foi compilado e testado no repositório. Ela não declara
compatibilidade com hosts que só implementam o ciclo legado `initialize` /
`notifications/initialized`.

Antes de adotar uma versão nova do MCP, siga
[o roteiro de atualização](PROTOCOL_UPGRADE.md).
