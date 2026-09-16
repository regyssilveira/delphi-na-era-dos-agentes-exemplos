# Exemplos da 1ª edição — revisão r4

Esta revisão substitui a r3 como referência reproduzível para a prova atual do livro.
A tag r3 permanece imutável para quem já a utilizou.

## Correção do perfil MCP 2026-07-28

- `server/discover` deixou de repetir `serverInfo` diretamente no corpo do resultado;
  a identidade continua em `result._meta['io.modelcontextprotocol/serverInfo']`.
- A suíte Delphi verifica a localização da identidade na descoberta e em `tools/list`.
- O perfil legado `2025-11-25` não mudou: `initialize` ainda retorna `serverInfo`.

## Verificação

Compilado com Delphi 13 Florence, compilador Win64 `37.0`. As suítes
`TechStore.Mcp.Tests.dpr` e `TechStore.Mcp.Process.Tests.dpr` passaram em
15/09/2026. A revisão não afirma conformidade integral com todos os recursos MCP
nem substitui testes de identidade, autorização e operação antes de usar dados reais.
