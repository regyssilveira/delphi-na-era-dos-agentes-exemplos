# Alinhamento com o livro

Este repositório é o código executável de **Delphi na Era dos Agentes**. A matriz abaixo evita que uma explicação de evolução seja confundida com uma capability já disponível no MiniERP.

## Implementado e reproduzível

| Tema do livro | Implementação pública |
|---|---|
| Servidor MCP nativo Delphi sobre `stdio` | `src/TechStoreERP.dpr`, `src/TechStore.Stdio.pas` e `src/TechStore.Mcp.pas` |
| Descoberta MCP | `server/discover` e `_meta` no perfil atual; handshake `2025-11-25` para hosts legados |
| Descoberta de capabilities | `tools/list`, `resources/list` e `prompts/list` |
| Consultas de negócio | `consultar_cliente`, `consultar_produto`, `consultar_estoque_baixo` e `consultar_faturas_cliente` |
| Preparação controlada | `criar_orcamento`, que retorna estado `PREPARADO` |
| Política demonstrativa | `TechStore.Authorization.pas` bloqueia confirmação crítica e nega faturas sem ator demonstrativo; não verifica identidade real |
| Testes reproduzíveis | `tests/TechStore.Mcp.Tests.dpr` e `tests/TechStore.Mcp.Process.Tests.dpr` |
| Adaptação a um ERP existente | `docs/ADAPTAR_AO_ERP.md` e Laboratório 6 do livro |

## Contratos de evolução, ainda não implementados

Os apêndices do livro também apresentam nomes e contratos de referência, tais como `estoque.listar_alertas`, `vendas.obter_resumo` e `estoque.confirmar_baixa`. Eles representam uma evolução posterior do MiniERP, não tools disponíveis nesta revisão pública.

Esses contratos dependem de recursos que o exemplo atual deliberadamente não oferece:

- filtros por categoria, paginação e isolamento por filial;
- identidade autenticada, escopos e correlação de chamadas;
- auditoria operacional persistente;
- confirmação de efeitos, idempotência e recuperação após resposta perdida;
- transporte remoto, múltiplos clientes e observabilidade distribuída.

Antes de uma capability passar desta seção para a seção anterior, ela deve incluir implementação Delphi, testes de contrato e processo, documentação no `README.md` e atualização da matriz.

## Limite intencional

O servidor atual é um laboratório local. `criar_orcamento` prepara um rascunho, mas não confirma compra, não baixa estoque e não emite documento fiscal. O livro usa essa ausência para ensinar que operações críticas exigem identidade verificável, autorização, aprovação humana, idempotência e auditoria antes de serem liberadas.
