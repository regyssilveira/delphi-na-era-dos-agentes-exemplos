# Construir o MVP do zero no Delphi

Este roteiro acompanha o Apêndice Q do livro. Ele parte de um projeto Console vazio no Delphi
13 Florence e termina com um servidor MCP testado. O código completo deste repositório é a
referência para comparar cada marco; não é necessário redigitar todas as units.

## 1. Crie o processo

1. Crie uma Console Application Win64 chamada `TechStoreERP` dentro de `src`.
2. Confirme `{$APPTYPE CONSOLE}`.
3. Adicione `TechStore.Stdio.pas` com `ReadMcpLine`, `WriteMcpLine` e `WriteDiagnostic`.
4. Preserve a regra: `stdout` contém somente MCP; diagnóstico vai para `stderr`.

Compare com [TechStore.Stdio.pas](../src/TechStore.Stdio.pas). A leitura por bytes e a conversão
UTF-8 são necessárias para funcionar do mesmo modo no console e em pipes.

## 2. Acrescente persistência fictícia

Adicione [TechStore.Data.pas](../src/TechStore.Data.pas) e as dependências FireDAC/SQLite. A
classe deve criar `customers`, `products`, `invoices` e `quote_drafts`, inserir os dados de
demonstração e expor consultas parametrizadas. Use `TECHSTORE_DB_PATH` para apontar os testes a
um arquivo descartável.

Checkpoint: `Initialize` termina e `ListLowStock` devolve três produtos. Não prossiga ao MCP se
essa consulta direta falhar.

## 3. Separe regra e autorização

Adicione [TechStore.Services.pas](../src/TechStore.Services.pas) e
[TechStore.Authorization.pas](../src/TechStore.Authorization.pas). Valide IDs e quantidade no
serviço. `PrepareQuote` deve criar somente um rascunho `PREPARADO`, com
`requiresHumanApproval: true`; não existe confirmação de venda ou baixa de estoque.

Checkpoint: `ConsultProduct(2)` devolve Mouse Orbital e `PrepareQuote(1, 2, 20)` cria um rascunho
revisável. `TECHSTORE_DEMO_ACTOR` é demonstração, não autenticação.

## 4. Implemente a borda MCP

Adicione [TechStore.Mcp.pas](../src/TechStore.Mcp.pas). Implemente nesta ordem:

1. análise e validação do envelope JSON-RPC;
2. `server/discover`;
3. `tools/list`;
4. `tools/call` para `consultar_produto`;
5. as quatro tools restantes;
6. resources e prompts;
7. perfil de compatibilidade `2025-11-25`.

O catálogo e o despachante devem compartilhar nomes e contratos. Rejeite campos extras, tipos
incorretos e versões não suportadas. No perfil `2026-07-28`, `serverInfo` fica em
`result._meta.io.modelcontextprotocol/serverInfo`.

## 5. Monte o `.dpr`

Compare com [TechStoreERP.dpr](../src/TechStoreERP.dpr). Ele inicializa o banco e, quando recebe
`--mcp-stdio`, mantém este ciclo:

```pascal
while ReadMcpLine(Line) do
begin
  if Line.Trim <> '' then
  begin
    Response := Server.ProcessLine(Line);
    if Response <> '' then
      WriteMcpLine(Response);
  end;
end;
```

Use `try/finally` para liberar banco e servidor. Exceções externas vão para `stderr` e resultam
em código de saída 1.

## 6. Verifique em duas camadas

Compile e execute [TechStore.Mcp.Tests.dpr](../tests/TechStore.Mcp.Tests.dpr). Ele verifica o
contrato no mesmo processo. Depois compile o servidor e execute
[TechStore.Mcp.Process.Tests.dpr](../tests/TechStore.Mcp.Process.Tests.dpr) a partir de `tests`.
Ele verifica pipes, UTF-8, separação de canais e encerramento.

Os resultados esperados são:

```text
Todos os testes MCP passaram.
Teste de processo MCP e UTF-8 passou.
```

Os comandos completos estão em [QUICKSTART.md](QUICKSTART.md).

## 7. Use um cliente e um host

Valide primeiro com MCP Inspector, conforme o QUICKSTART. Em seguida, reproduza a conversa de
[HOST_CODEX_CLI.md](HOST_CODEX_CLI.md). Confira a trilha de quatro chamadas e o estado
`PREPARADO`; uma resposta textual sem chamadas não é evidência obtida do ERP.

## Passagem para o seu ERP

Substitua uma consulta por vez: persistência fictícia por serviço autorizado do ERP, serviço de
demonstração por caso de uso real, ator de ambiente por identidade validada e SQLite por conexão
gerenciada. Preserve schema fechado, projeção mínima, testes de negativa, separação de canais e
trilha de auditoria. Para escrita, adicione preparação, aprovação, idempotência e revalidação na
transação antes de permitir confirmação.
