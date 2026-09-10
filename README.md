# TechStore ERP

MiniERP fictício em Delphi 13 Florence, criado como projeto prático do livro *Delphi na Era dos Agentes*.

O repositório demonstrará uma camada de negócio que pode ser exposta com segurança por um servidor Model Context Protocol (MCP). Ele não contém dados reais, credenciais, regras fiscais proprietárias nem funcionalidades destinadas à operação comercial.

## Escopo inicial

- clientes, fornecedores e produtos;
- estoque, vendas, compras e contas a receber;
- consultas de negócio para uso por ferramentas MCP;
- preparação de operações sujeitas à aprovação humana;
- trilha de auditoria e testes reproduzíveis.

## Requisitos

- Delphi 13 Florence;
- requisitos adicionais serão documentados a cada entrega executável.

## Status

O marco inicial já cria um banco SQLite com dados fictícios e demonstra o ponto de partida para a camada de serviços do ERP. O servidor MCP será introduzido na próxima entrega.

## Executar o marco inicial

1. Abra `src/TechStoreERP.dpr` no Delphi 13 Florence.
2. Compile e execute o projeto como aplicação de console.
3. O banco `techstore.db` será criado em `Documentos\TechStoreERP`, com clientes, produtos e notas fictícios.

O projeto usa somente Delphi e bibliotecas fornecidas pelo Delphi: FireDAC e o driver SQLite. Nenhum dado, credencial ou documento fiscal real é utilizado.

## Licença

Este projeto é distribuído sob a [Apache License 2.0](LICENSE).
