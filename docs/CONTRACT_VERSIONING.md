# Evolução de contratos sem surpreender o host

O nome de uma tool, seu `inputSchema`, os campos de saída e a semântica de erro formam um contrato.
Antes de alterá-lo, guarde uma requisição e uma resposta de referência nos testes.

| Mudança | Conduta recomendada |
| --- | --- |
| Melhorar descrição sem alterar comportamento | Atualize descrição e teste de descoberta. |
| Adicionar campo opcional de entrada | Garanta padrão anterior e teste chamadas antigas. |
| Adicionar campo de saída | Verifique que clientes aceitam campos adicionais e que não há vazamento de dados. |
| Tornar entrada obrigatória, mudar significado ou remover campo | Publique uma nova tool ou versão explícita; mantenha a antiga por prazo anunciado. |
| Remover uma tool | Registre descontinuação, migração, prazo e teste de host antes de retirar. |

Versão do protocolo MCP e versão do contrato de negócio são decisões diferentes. A primeira
descreve o envelope e as capabilities MCP; a segunda descreve o significado de uma operação do
ERP. Não aumente `McpProtocolVersion` para sinalizar uma mudança de preço, saldo ou regra interna.

Na implantação, registre versão do executável, commit, versão de cada contrato alterado,
resultado da suíte e host em que a integração foi exercitada. Se o catálogo mudar por permissão,
teste com as identidades relevantes e não anuncie uma tool que a mesma identidade não pode chamar.
