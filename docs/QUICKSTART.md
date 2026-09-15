# Laboratório reproduzível

Este roteiro produz uma integração MCP local e verificável. Ele não configura um ERP real, não
abre portas de rede e não usa credenciais.

## Requisitos

- Windows 10 ou posterior;
- Delphi 13 Florence com a plataforma Windows que será compilada;
- Node.js 22.19 ou posterior, somente para usar a versão atual do MCP Inspector na validação independente;
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
dcc64 -B TechStore.Mcp.Process.Tests.dpr
TechStore.Mcp.Process.Tests.exe
```

Os testes devem terminar com `Todos os testes MCP passaram.` e
`Teste de processo MCP e UTF-8 passou.`. O segundo programa inicia o executável por pipes,
envia texto acentuado em UTF-8, separa `stdout` de `stderr` e verifica o encerramento após fechar
`stdin`. O executável do MiniERP
cria `techstore.db` em `Documentos\TechStoreERP`, contendo somente dados fictícios. A suíte
usa bancos SQLite temporários próprios e não acrescenta orçamentos ao banco em Documentos.

## Validar com um cliente MCP independente

O Inspector inicia o processo, conversa pelo transporte `stdio` e permite inspecionar as tools,
resources e prompts. Copie `docs/inspector.config.example.json` para
`docs/inspector.local.json`, troque `command` pelo caminho
absoluto do seu executável e mantenha `args` como `--mcp-stdio`. No diretório do repositório,
execute:

```powershell
npx -y @modelcontextprotocol/inspector --cli --config .\docs\inspector.local.json --server techstore --method tools/list
npx -y @modelcontextprotocol/inspector --cli --config .\docs\inspector.local.json --server techstore --method tools/call --tool-name consultar_estoque_baixo
```

O resultado deve listar as cinco tools e depois Mouse Orbital, Notebook Atlas 14 e SSD Aurora
1 TB. Em seguida, chame
`criar_orcamento` com `customerId: 1`, `productId: 2` e `quantity: 20`; o retorno deve
conter `PREPARADO` e `requiresHumanApproval: true`.

O Inspector é usado apenas como cliente de validação. Ele não é dependência do servidor Delphi
nem do livro.

Para uma pergunta executada por um host de IA, consulte
[HOST_CODEX_CLI.md](HOST_CODEX_CLI.md). Esse segundo teste foi feito com um banco
fictício isolado e registra também o cancelamento observado sob sandbox somente leitura.

## Contrato para hosts locais

Qualquer host MCP compatível deve iniciar o programa abaixo com caminho absoluto:

```text
comando: C:\caminho\absoluto\TechStoreERP.exe
argumentos: --mcp-stdio
```

O host pode falar MCP `2026-07-28` pelo perfil moderno: cada requisição JSON-RPC carrega
`params._meta.io.modelcontextprotocol/protocolVersion` e
`params._meta.io.modelcontextprotocol/clientCapabilities`. O servidor responde a
`server/discover`. Para hosts que ainda usam MCP `2025-11-25`, o servidor também aceita
`initialize`, espera `notifications/initialized` e só então atende o catálogo legado. O modo
de compatibilidade é por processo; não misture os dois fluxos no mesmo processo.

Não registre caminhos relativos, não escreva texto em `stdout` e não coloque credenciais em
argumentos. O processo é local e deve ser encerrado pelo host ao fechar o fluxo de entrada.

## Diagnóstico rápido

| Sintoma | Verificação |
| --- | --- |
| O host não encontra o executável | Use caminho absoluto e confirme a plataforma Win32/Win64. |
| O banco não abre | Execute o binário uma vez sem argumentos e confira a pasta Documentos. |
| O host acusa versão inválida | Confirme se ele fala MCP `2026-07-28` ou `2025-11-25` e se iniciou o executável atualizado. |
| JSON inválido no host | Garanta UTF-8, uma mensagem JSON-RPC por linha e nenhum log em `stdout`. |
| Uma ação crítica parece disponível | Interrompa o teste: o exemplo só permite consulta e preparação; não há tool de confirmação. |

## Adapte ao seu ERP

Depois de executar o laboratório, siga [ADAPTAR_AO_ERP.md](ADAPTAR_AO_ERP.md). O roteiro parte de
uma única consulta existente no sistema do leitor e chega a uma tool testada, com critérios de
aceite e pontos explícitos para identidade, configuração e operação.
