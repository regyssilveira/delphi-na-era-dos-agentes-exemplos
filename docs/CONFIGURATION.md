# Configuração mínima por ambiente

O TechStore de demonstração usa banco SQLite fictício em `Documentos\TechStoreERP`. Não contém
configuração de produção. Ao conectar outro ERP, separe desenvolvimento, homologação e produção
antes de publicar a primeira tool.

| Valor | Desenvolvimento | Homologação | Produção |
| --- | --- | --- | --- |
| Executável | build local | versão candidata | versão aprovada |
| Fonte de dados | dados fictícios | cópia sintética ou isolada | serviço autorizado do ERP |
| Identidade | operador de teste | conta de teste com escopo | identidade verificável por usuário/serviço |
| Logs | arquivo local sem segredos | destino de teste | destino protegido e retido por política |
| Capabilities | leitura em estudo | lista aprovada para piloto | lista aprovada por perfil |
| Desativação | encerrar processo | retirar configuração do host | procedimento operacional documentado |

O host deve usar o caminho absoluto do executável e passar `--mcp-stdio`. Não coloque senha,
token ou string de conexão na linha de comando, no repositório ou no `inputSchema` de uma tool.
Mantenha a obtenção de segredos no mecanismo aprovado pela organização. Antes da implantação,
teste explicitamente a falha de configuração: ausência de credencial ou indisponibilidade do ERP
deve impedir a chamada sem enviar dados para uma fonte alternativa por engano.
