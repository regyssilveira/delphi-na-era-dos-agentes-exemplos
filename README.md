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

## Servidor MCP didático

Execute `TechStoreERP.exe --mcp-stdio` para iniciar o perfil MCP local. Cada linha recebida em `stdin` deve conter uma mensagem JSON-RPC; cada resposta é escrita em `stdout`. Os diagnósticos não devem ser enviados a `stdout`.

O núcleo atual suporta `initialize`, `notifications/initialized`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list` e `prompts/get`. Ele publica a ferramenta de leitura `consultar_estoque_baixo`, a política `techstore://policies/operation-classification` e o prompt `analisar_estoque_baixo`. Após receber `initialize`, o cliente deve enviar a notificação de inicialização antes de usar uma capacidade. Ele é um perfil didático, não uma implementação completa do MCP nem um servidor de rede.

### Testes do núcleo MCP

Abra e execute `tests/TechStore.Mcp.Tests.dpr` no Delphi. O programa verifica o ciclo de inicialização, a descoberta da ferramenta, a chamada de consulta e o tratamento de JSON inválido. Os testes usam somente unidades fornecidas pelo Delphi e os dados fictícios do projeto.

## Relação com o livro

O livro principal mantém um recorte de 200 a 260 páginas e apresenta apenas os trechos de código necessários para compreender cada decisão. Este repositório reúne o código integral, versões executáveis e extensões progressivas.

Evoluções previstas após o núcleo MCP com `stdio`:

- Streamable HTTP;
- autenticação, autorização e auditoria de rede;
- suporte a múltiplos clientes, streaming e cancelamento;
- implantação e observabilidade distribuída.

## Licença

Este projeto é distribuído sob a [Apache License 2.0](LICENSE).
