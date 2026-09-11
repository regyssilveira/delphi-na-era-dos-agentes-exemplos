# TechStore ERP

MiniERP fictício em Delphi 13 Florence, criado como projeto prático do livro *Delphi na Era dos Agentes*.

O repositório demonstrará uma camada de negócio que pode ser exposta com segurança por um servidor Model Context Protocol (MCP). Ele não contém dados reais, credenciais, regras fiscais proprietárias nem funcionalidades destinadas à operação comercial.

## Escopo do exemplo

- clientes, produtos e estoque;
- consultas de negócio para uso por ferramentas MCP;
- preparação de operações sujeitas à aprovação humana;
- política de autorização demonstrativa e testes reproduzíveis.

## Requisitos

- Delphi 13 Florence;
- requisitos adicionais serão documentados a cada entrega executável.

## Estado atual

O exemplo já cria um banco SQLite com dados fictícios e inclui um servidor MCP nativo em Delphi sobre `stdio`. O servidor implementa o ciclo de inicialização, descoberta de ferramentas, recursos e prompts, além das consultas e da preparação de orçamento abaixo:

- `consultar_cliente` e `consultar_produto`;
- `consultar_estoque_baixo`;
- `criar_orcamento`, que apenas cria um rascunho com estado `PREPARADO` e exige aprovação humana para qualquer confirmação posterior;
- o recurso `techstore://policies/operation-classification`;
- o prompt `analisar_estoque_baixo`.

O código separa acesso a dados, regras de negócio, autorização e adaptação MCP. A política de autorização aceita consultas e preparação, mas bloqueia explicitamente ações críticas de confirmação.

## Executar

1. Abra `src/TechStoreERP.dpr` no Delphi 13 Florence.
2. Compile e execute o projeto como aplicação de console.
3. O banco `techstore.db` será criado em `Documentos\TechStoreERP`, com clientes, produtos e notas fictícios.

O projeto usa somente Delphi e bibliotecas fornecidas pelo Delphi: FireDAC e o driver SQLite. Nenhum dado, credencial ou documento fiscal real é utilizado.

## Servidor MCP didático

Execute `TechStoreERP.exe --mcp-stdio` para iniciar o perfil MCP local. Cada linha recebida em `stdin` deve conter uma mensagem JSON-RPC; cada resposta é escrita em `stdout`. Os diagnósticos não devem ser enviados a `stdout`.

O núcleo atual suporta `initialize`, `notifications/initialized`, `tools/list`, `tools/call`, `resources/list`, `resources/read`, `prompts/list` e `prompts/get`. Após receber `initialize`, o cliente deve enviar a notificação de inicialização antes de usar uma capacidade.

Exemplo de sequência mínima (uma mensagem por linha):

```json
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"teste","version":"1.0"}}}
{"jsonrpc":"2.0","method":"notifications/initialized"}
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"criar_orcamento","arguments":{"customerId":1,"productId":2,"quantity":20}}}
```

O resultado da última chamada contém um identificador de orçamento, o estado `PREPARADO` e `requiresHumanApproval: true`. Não existe ferramenta para confirmar a operação neste recorte.

### Testes

Abra e execute `tests/TechStore.Mcp.Tests.dpr` no Delphi. O programa verifica o ciclo de inicialização, descoberta de capacidades, consultas, recursos, prompts, cliente local didático, regras de negócio, autorização e tratamento de JSON inválido. Os testes usam somente unidades fornecidas pelo Delphi e os dados fictícios do projeto.

## Limitações assumidas

Este é um perfil didático, deliberadamente menor que uma implementação MCP de produção:

- transporte somente local por `stdio`; não há Streamable HTTP, múltiplos clientes, streaming ou cancelamento;
- não há autenticação de rede, gestão de segredos, persistência de identidade nem trilha de auditoria distribuída;
- a confirmação de operações críticas está fora do escopo: o exemplo demonstra como bloqueá-la e exigir aprovação humana;
- a interoperabilidade UTF-8 do transporte de console deve ser validada no ambiente de destino;
- o protocolo evolui: antes de produção, compare as mensagens e capacidades com a especificação MCP vigente.

## Relação com o livro

O livro principal mantém um recorte de 200 a 260 páginas e apresenta apenas os trechos de código necessários para compreender cada decisão. Este repositório reúne o código integral, versões executáveis e extensões progressivas.

Evoluções naturais após o núcleo MCP com `stdio`:

- Streamable HTTP;
- autenticação, autorização e auditoria de rede;
- suporte a múltiplos clientes, streaming e cancelamento;
- implantação e observabilidade distribuída.

## Licença

Este projeto é distribuído sob a [Apache License 2.0](LICENSE).
