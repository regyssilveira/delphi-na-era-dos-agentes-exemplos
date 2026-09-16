# ERP MCP Starter

Projeto-modelo mínimo para transportar uma consulta existente de um ERP Delphi para uma tool MCP. Ele é propositalmente neutro: não depende do banco nem das regras do TechStore. Inclui uma pequena tela VCL apenas para provar que tela e MCP reutilizam o mesmo contrato.

1. Compile `src/ErpMcpStarter.dpr`, o servidor MCP por stdio.
2. Compile e execute `tests/ErpMcpStarter.Tests.dpr`.
3. Compile e execute `tests/ErpMcpStarter.Process.Tests.dpr` a partir da pasta `tests`.
4. Compile `vcl/ErpMcpVclDemo.dpr` e confirme que o produto 1 tem saldo 12.
5. Substitua somente `TExampleProductService` por um adaptador para a camada de negócio do seu ERP.
6. Preserve `IProductQueryService`: a tela e a tool devem chamar o mesmo contrato.
7. Troque o registro de demonstração pelos testes do seu domínio antes de conectar um cliente de IA.

Os comentários `PONTO DE ADAPTAÇÃO` indicam os lugares que o leitor deve preencher. O projeto entrega uma consulta funcional em memória, uma tela VCL, um servidor MCP 2026-07-28 e testes diretos e por processo. O contrato da tool é `consultar_produto` com `{"id":1}`.

O servidor aceita `server/discover`, `tools/list` e `tools/call`. Cada requisição carrega a versão e as capabilities em `params._meta`, conforme o perfil moderno usado no livro. Diagnósticos vão para `stderr`; `stdout` contém somente uma resposta JSON-RPC por linha.

Este starter termina deliberadamente na fronteira da primeira consulta. Antes de um piloto, ligue o ator autenticado, a autorização e a auditoria já existentes no ERP nos pontos indicados pelo Capítulo 13. Para uma implementação executável dessas políticas, consulte `TechStore.Authorization.pas`; não copie o usuário demonstrativo para produção.
