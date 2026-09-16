# TechStore ERP

MiniERP fictício em Delphi 13 Florence, criado como projeto prático do livro *Delphi na Era dos Agentes*.

O repositório demonstrará uma camada de negócio que pode ser exposta com segurança por um servidor Model Context Protocol (MCP). Ele não contém dados reais, credenciais, regras fiscais proprietárias nem funcionalidades destinadas à operação comercial.

## Escopo do exemplo

- clientes, produtos e estoque;
- consultas de negócio para uso por ferramentas MCP;
- preparação de operações sujeitas à aprovação humana;
- política de autorização demonstrativa e testes reproduzíveis.

## Comece aqui

Siga o [laboratório reproduzível](docs/QUICKSTART.md). Ele informa pré-requisitos,
compilação, testes, validação com um cliente MCP independente e diagnóstico de falhas comuns.
Para construir a solução a partir de um projeto Console vazio, use
[o roteiro do zero](docs/CONSTRUIR_DO_ZERO.md).
Para levar uma consulta ao seu sistema, use [o roteiro de adaptação](docs/ADAPTAR_AO_ERP.md).

## Versões correspondentes às edições do livro

A 1ª edição do livro corresponde à release identificada como
`livro-1edicao-2026-exemplos-r4`. Para reproduzir os exercícios exatamente como
publicados, clone o repositório e selecione essa versão antes de compilar:

```bash
git checkout livro-1edicao-2026-exemplos-r4
```

O ramo `main` contém a evolução mais recente e pode divergir das páginas
impressas. O histórico técnico da revisão está em
[`docs/RELEASE_NOTES_R4.md`](docs/RELEASE_NOTES_R4.md). Versões publicadas não
devem ser alteradas silenciosamente; uma correção futura receberá nova identificação.

## Estado atual

O exemplo cria um banco SQLite com dados fictícios e inclui um servidor MCP nativo em Delphi
sobre `stdio`, no perfil MCP `2026-07-28` moderno e sem estado, com compatibilidade local para
clientes `2025-11-25`. O servidor implementa
`server/discover`, descoberta de ferramentas, recursos e prompts, além das consultas e da
preparação de orçamento abaixo:

- `consultar_cliente` e `consultar_produto`;
- `consultar_estoque_baixo`;
- `consultar_faturas_cliente`, segunda consulta de ponta a ponta, negada sem ator demonstrativo;
- `criar_orcamento`, que apenas cria um rascunho com estado `PREPARADO` e exige aprovação humana para qualquer confirmação posterior;
- o recurso `techstore://policies/operation-classification`;
- o prompt `analisar_estoque_baixo`.

O código separa acesso a dados, regras de negócio e adaptação MCP. A unit de autorização é
exercitada diretamente e no despacho de `consultar_faturas_cliente`. O ator demonstrativo vem
de `TECHSTORE_DEMO_ACTOR`; ele não é autenticado e não permite usar dados reais. A confirmação
crítica não está publicada como tool.

Consulte [a matriz de alinhamento com o livro](docs/BOOK_ALIGNMENT.md) para distinguir o que já é executável das arquiteturas e contratos de evolução discutidos nos apêndices.

O projeto usa somente Delphi e bibliotecas fornecidas pelo Delphi: FireDAC e o driver SQLite.
Nenhum dado, credencial ou documento fiscal real é utilizado.

## Servidor MCP didático

Execute `TechStoreERP.exe --mcp-stdio` para iniciar o perfil MCP local. Cada linha recebida em
`stdin` deve conter uma mensagem JSON-RPC UTF-8; cada resposta é escrita em `stdout`.
Os diagnósticos não devem ser enviados a `stdout`.
`TECHSTORE_DB_PATH` permite um SQLite fictício isolado; sem ela, o banco fica em Documentos.

O núcleo atual suporta `server/discover`, `tools/list`, `tools/call`, `resources/list`,
`resources/read`, `prompts/list` e `prompts/get`. Cada requisição deve informar em
`params._meta` a versão `2026-07-28` e as capabilities do cliente. O adaptador valida versão
JSON-RPC, metadados MCP, tipo de `method`, identificadores válidos e argumentos de cada tool;
números decimais ou propriedades extras são rejeitados quando o contrato exige inteiros e
`additionalProperties: false`.

Clientes legados `2025-11-25` podem iniciar com `initialize` e
`notifications/initialized`. O modo legado fica isolado por processo. O MCP Inspector CLI foi
testado com listagem e chamada de tool; veja o comando reproduzível no guia rápido.

Exemplo de sequência mínima (uma mensagem por linha):

```json
{"jsonrpc":"2.0","id":1,"method":"server/discover","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"teste","version":"1.0"},"io.modelcontextprotocol/clientCapabilities":{}}}}
{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"criar_orcamento","arguments":{"customerId":1,"productId":2,"quantity":20},"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"teste","version":"1.0"},"io.modelcontextprotocol/clientCapabilities":{}}}}
```

O resultado da última chamada contém um identificador de orçamento, o estado `PREPARADO` e `requiresHumanApproval: true`. Não existe ferramenta para confirmar a operação neste recorte.

Os contratos de evolução apresentados no livro — por exemplo, alertas paginados por categoria, resumo de venda e confirmação idempotente de baixa — ainda não fazem parte do catálogo público. Eles só serão adicionados quando tiverem implementação, política e testes correspondentes.

### Testes

Abra e execute `tests/TechStore.Mcp.Tests.dpr` no Delphi. O programa verifica descoberta,
metadados por requisição, envelope JSON-RPC, consultas, recursos, prompts, cliente local
didático, regras de negócio, autorização, schemas de argumentos e tratamento de JSON inválido.
Compile também `tests/TechStore.Mcp.Process.Tests.dpr` depois do servidor. Ele inicia o
executável por pipes, verifica UTF-8 bidirecional, `stdout`, `stderr` e encerramento ao fechar
`stdin`. Os testes usam somente units fornecidas pelo Delphi e os dados fictícios do projeto.
Cada execução cria e remove seu próprio arquivo SQLite temporário.

## Limitações assumidas

Este é um perfil didático, deliberadamente menor que uma implementação MCP de produção:

- transporte somente local por `stdio`; não há Streamable HTTP, múltiplos clientes, streaming ou cancelamento;
- não há autenticação de rede, gestão de segredos, persistência de identidade nem trilha de auditoria distribuída;
- a confirmação de operações críticas está fora do escopo: o exemplo demonstra como bloqueá-la e exigir aprovação humana;
- o adaptador `stdio` e o teste de processo usam UTF-8; a interoperabilidade com o host escolhido ainda deve ser verificada no ambiente de destino;
- o protocolo evolui: antes de produção, compare as mensagens e capacidades com a especificação MCP vigente.

Consulte também [compatibilidade](docs/COMPATIBILITY.md),
[segurança](SECURITY.md), [configuração por ambiente](docs/CONFIGURATION.md),
[versionamento de contratos](docs/CONTRACT_VERSIONING.md) e
[atualização do protocolo](docs/PROTOCOL_UPGRADE.md).

## Relação com o livro

O livro principal mantém um recorte de 200 a 260 páginas e apresenta apenas os trechos de código necessários para compreender cada decisão. Este repositório reúne o código integral, versões executáveis e extensões progressivas.

Evoluções naturais após o núcleo MCP com `stdio`:

- Streamable HTTP;
- autenticação, autorização e auditoria de rede;
- suporte a múltiplos clientes, streaming e cancelamento;
- implantação e observabilidade distribuída.

## Licença

Este projeto é distribuído sob a [Apache License 2.0](LICENSE).
