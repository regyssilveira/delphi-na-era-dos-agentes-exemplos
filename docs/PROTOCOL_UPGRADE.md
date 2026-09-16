# Atualização do protocolo MCP

O servidor fixa o perfil `2026-07-28`. A versão não deve ser trocada apenas no texto de uma
mensagem: ela define o ciclo de vida, os metadados por requisição e a forma de descoberta.
Na revisão final dessa versão, `server/discover` não traz `serverInfo` diretamente no
resultado: a identidade do servidor fica em `result._meta['io.modelcontextprotocol/serverInfo']`
e é enviada nas demais respostas modernas. O perfil legado conserva `serverInfo` no
resultado de `initialize`. Uma amostra de uma revisão preliminar não substitui o schema final.

Ao avaliar uma nova revisão:

1. leia a especificação e o changelog oficiais;
2. compare o schema de `server/discover`, `tools/list`, `tools/call`, resources e prompts;
3. atualize a constante de versão, as validações de `_meta` e os testes Delphi;
4. execute a suíte local e a validação pelo MCP Inspector;
5. atualize `COMPATIBILITY.md`, o README e os capítulos do livro na mesma mudança;
6. publique uma release com changelog; não substitua silenciosamente o contrato.

Se for necessário interoperar com hosts legados, crie um adaptador de compatibilidade separado,
com testes próprios. Não misture o handshake legado ao perfil moderno no mesmo fluxo sem uma
negociação de versão claramente implementada.
