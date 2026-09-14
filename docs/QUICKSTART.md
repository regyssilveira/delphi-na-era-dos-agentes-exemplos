# Laboratório reproduzível

Este roteiro produz uma integração MCP local e verificável. Ele não configura um ERP real, não
abre portas de rede e não usa credenciais.

## Requisitos

- Windows 10 ou posterior;
- Delphi 13 Florence com a plataforma Windows que será compilada;
- Node.js 20 ou posterior, somente para usar o MCP Inspector na validação independente;
- acesso de escrita à pasta Documentos do usuário, onde o banco fictício será criado.

O projeto usa exclusivamente units do Delphi e FireDAC/SQLite. Para evitar dependência de DLL no
laboratório, deixe a unit de ligação estática do SQLite configurada como está em
`TechStore.Data.pas`.

## Compilar e testar

Abra `src/TechStoreERP.dpr` no Delphi e compile para a plataforma desejada. Em um Prompt de
Comando do Desenvolvedor, a mesma compilação pode ser feita assim:

```bat
cd src
dcc64 -B TechStoreERP.dpr
cd ..\tests
dcc64 -B TechStore.Mcp.Tests.dpr
TechStore.Mcp.Tests.exe
```

O último comando deve terminar com `Todos os testes MCP passaram.`. O executável do MiniERP
cria `techstore.db` em `Documentos\TechStoreERP`, contendo somente dados fictícios.

## Validar com um cliente MCP independente

O Inspector inicia o processo, conversa pelo transporte `stdio` e permite inspecionar as tools,
resources e prompts. Com o caminho absoluto do executável, execute:

```powershell
npx -y @modelcontextprotocol/inspector "C:\caminho\absoluto\TechStoreERP.exe" --mcp-stdio
```

Abra a URL exibida pelo Inspector, conecte e execute `consultar_estoque_baixo`. O resultado
deve listar Mouse Orbital, Notebook Atlas 14 e SSD Aurora 1 TB. Em seguida, chame
`criar_orcamento` com `customerId: 1`, `productId: 2` e `quantity: 20`; o retorno deve
conter `PREPARADO` e `requiresHumanApproval: true`.

O Inspector é usado apenas como cliente de validação. Ele não é dependência do servidor Delphi
nem do livro.

## Contrato para hosts locais

Qualquer host MCP compatível deve iniciar o programa abaixo com caminho absoluto:

```text
comando: C:\caminho\absoluto\TechStoreERP.exe
argumentos: --mcp-stdio
```

O host precisa falar MCP `2026-07-28` pelo perfil moderno: cada requisição JSON-RPC carrega
`params._meta.io.modelcontextprotocol/protocolVersion` e
`params._meta.io.modelcontextprotocol/clientCapabilities`. O servidor responde a
`server/discover`; não há `initialize` nem `notifications/initialized`.

Não registre caminhos relativos, não escreva texto em `stdout` e não coloque credenciais em
argumentos. O processo é local e deve ser encerrado pelo host ao fechar o fluxo de entrada.

## Diagnóstico rápido

| Sintoma | Verificação |
| --- | --- |
| O host não encontra o executável | Use caminho absoluto e confirme a plataforma Win32/Win64. |
| O banco não abre | Execute o binário uma vez sem argumentos e confira a pasta Documentos. |
| O host acusa versão inválida | Confirme suporte ao MCP `2026-07-28`; hosts legados usam o ciclo `initialize`, que este laboratório não implementa. |
| JSON inválido no host | Garanta UTF-8, uma mensagem JSON-RPC por linha e nenhum log em `stdout`. |
| Uma ação crítica parece disponível | Interrompa o teste: o exemplo só permite consulta e preparação; não há tool de confirmação. |
