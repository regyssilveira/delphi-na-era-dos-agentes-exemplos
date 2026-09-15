# Teste ponta a ponta com um host de IA: Codex CLI

Este teste foi executado no Windows em 15/09/2026 com Codex CLI `0.147.0`,
Delphi 13 Florence e o executável `src/TechStoreERP.exe` deste repositório.
Ele usa somente dados fictícios. O Codex CLI é um **host opcional**, não uma
dependência do servidor Delphi nem uma exigência para acompanhar o livro.
A configuração transitória `mcp_servers` segue a
[documentação oficial do Codex](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).

## Prepare um banco isolado

Compile o projeto e rode as duas suítes descritas em [QUICKSTART.md](QUICKSTART.md).
Depois, no PowerShell, substitua os caminhos abaixo pelos caminhos absolutos da
sua máquina. Não aponte `TECHSTORE_DB_PATH` para o banco do seu ERP.

```powershell
$techStoreExe = 'D:\Livros\techstore-erp\src\TechStoreERP.exe'
$techStoreDb = 'D:\Livros\techstore-erp\dist\codex-host-test.db'
$env:TECHSTORE_DB_PATH = $techStoreDb
& $techStoreExe
```

A última linha cria as tabelas e os dados de demonstração e informa o caminho
do banco. O servidor também executa essa inicialização ao começar no modo MCP;
por isso uma política que bloqueia qualquer escrita do processo pode impedir
até uma consulta de estoque. Separe esse banco de dados de produção.

## Execute uma pergunta com o host

O exemplo abaixo usa opções temporárias: `--ignore-user-config` não lê seus
servidores MCP pessoais e `--ephemeral` não guarda a sessão do teste. Ajuste os
dois caminhos TOML escapando cada `\` como `\\`. A opção
`-s danger-full-access` foi necessária **neste teste local** para permitir que
o processo Delphi abrisse/inicializasse o SQLite; ela amplia o acesso do agente
ao computador e não é uma configuração recomendada para um ERP real. Use-a
apenas em uma máquina de laboratório com dados fictícios. Em ambiente de
empresa, crie uma política restrita que permita somente os arquivos necessários.

```powershell
codex exec --ignore-user-config --ephemeral -s danger-full-access `
  -C D:\Livros\techstore-erp `
  -c 'mcp_servers.techstore.command="D:\\Livros\\techstore-erp\\src\\TechStoreERP.exe"' `
  -c 'mcp_servers.techstore.args=["--mcp-stdio"]' `
  -c 'mcp_servers.techstore.env.TECHSTORE_DB_PATH="D:\\Livros\\techstore-erp\\dist\\codex-host-test.db"' `
  -c 'mcp_servers.techstore.required=true' `
  -c 'mcp_servers.techstore.default_tools_approval_mode="auto"' `
  'Use apenas a ferramenta MCP techstore consultar_estoque_baixo uma vez. Informe os nomes dos produtos abaixo do mínimo. Não execute comandos de shell nem altere dados.'
```

Na execução registrada, o host descobriu
`techstore/consultar_estoque_baixo`, completou uma chamada e respondeu:
Mouse Orbital, Notebook Atlas 14 e SSD Aurora 1 TB. Nenhuma tool de escrita
foi chamada. Uma execução anterior com `-s read-only`, inclusive com o banco
já criado, descobriu a tool mas terminou com `user cancelled MCP tool call`;
isso não é uma resposta de estoque nem prova de incompatibilidade do protocolo.

## Se não funcionar

1. Confirme o caminho absoluto do executável e o argumento `--mcp-stdio`.
2. Execute as suítes Delphi e, separadamente, o Inspector do QUICKSTART.
3. Confirme que o banco fictício pode ser criado e aberto pelo processo host.
4. Verifique a versão do Codex CLI e o perfil MCP realmente negociado. A
   mensagem `user cancelled MCP tool call` pode refletir política do host; não
   a trate automaticamente como erro da tool Delphi.
5. Se o host descobrir a tool mas não conseguir chamá-la, registre versão,
   sistema, política de execução e erro antes de tentar outra configuração.

Não coloque credenciais, banco corporativo ou tool de confirmação nesse
experimento. O servidor continua sendo um laboratório `stdio` local.
