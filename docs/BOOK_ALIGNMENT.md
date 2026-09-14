# Alinhamento com o livro

Este repositório é o código executável de **Delphi na Era dos Agentes**. A matriz abaixo evita que uma explicação de evolução seja confundida com uma capability já disponível no MiniERP.

## Implementado e reproduzível

| Tema do livro | Implementação pública |
|---|---|
| Servidor MCP nativo Delphi sobre `stdio` | `src/TechStoreERP.dpr` e `src/TechStore.Mcp.pas` |
| Descoberta MCP | `server/discover` e metadados `_meta` em cada requisição |
| Descoberta de capabilities | `tools/list`, `resources/list` e `prompts/list` |
| Consultas de negócio | `consultar_cliente`, `consultar_produto` e `consultar_estoque_baixo` |
| Preparação controlada | `criar_orcamento`, que retorna estado `PREPARADO` |
| Política demonstrativa | `TechStore.Authorization.pas` bloqueia confirmação crítica |
| Testes reproduzíveis | `tests/TechStore.Mcp.Tests.dpr` |

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
