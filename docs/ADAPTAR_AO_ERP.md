# Da consulta existente à primeira tool do seu ERP

## Exemplo completo no código: faturas de um cliente

Antes de adaptar o próprio sistema, execute `consultar_faturas_cliente`. Esta é uma segunda
consulta, adicionada depois das três consultas básicas para mostrar todas as fronteiras:

1. `TechStore.Data.ListInvoicesByCustomerId` executa SQL parametrizado sobre `invoices` e
   devolve somente `id`, `issuedAt` e `totalAmount`, em ordem estável. O limite de crédito do
   cadastro não é copiado para a resposta.
2. `TechStore.Services.ConsultInvoicesByCustomer` exige ator, verifica que o cliente existe e
   só então chama o repositório. O serviço não depende de JSON-RPC.
3. `TechStore.Mcp.HandleToolsList` publica o `inputSchema` com `id` inteiro obrigatório;
   `HandleToolsCall` recusa campos extras e tipos inválidos, chama o serviço e usa o mesmo
   `ToolResult` para `content` e `structuredContent`.
4. A suíte prova a recusa sem ator (`-32003`), o sucesso com ator de demonstração, o cliente
   inexistente e a ausência de `creditLimit`; o teste de processo prova o caminho `stdio`.

Para testar no Inspector com dados fictícios, configure `TECHSTORE_DEMO_ACTOR=operador-demo`
no ambiente do processo iniciado pelo host. Sem a variável, a tool permanece listada, mas sua
chamada é negada. Esse valor é autodeclarado pelo ambiente, não uma identidade autenticada:
serve apenas para mostrar onde uma identidade confiável precisaria entrar. Não use essa variável
para autorizar dados reais. Em um ERP, substitua-a por identidade emitida e verificada pelo
mecanismo aprovado, aplique escopo por usuário/filial e teste a negação em todos os caminhos.

Os testes usam um arquivo SQLite temporário diferente a cada execução; o banco em Documentos
não é alterado pela suíte. O executável de demonstração aceita `TECHSTORE_DB_PATH` para apontar
um banco fictício isolado. Não use essa variável para passar credenciais ou apontar um ERP real.

Use os quatro passos acima como um diff guiado: duplique o percurso para uma única consulta
existente do seu ERP, trocando a query por uma chamada ao serviço de domínio já autorizado.
O aceite exige conferir significado, campos, negação e processo com o responsável pelo dado.

Este roteiro é para uma integração local em homologação. Escolha uma consulta de baixo risco que
já exista em um serviço Delphi do seu ERP. O exemplo usa `consultar_produto`; troque nome,
campos e serviço conforme o seu domínio. Não conecte o banco de produção durante esta etapa.

## 1. Registre o contrato antes do código

Preencha uma ficha curta:

| Campo | Exemplo |
| --- | --- |
| Pergunta respondida | Qual é o saldo atual de um produto conhecido? |
| Tool | `consultar_produto` |
| Entrada | `id` inteiro positivo |
| Saída | `id`, nome, saldo e estoque mínimo |
| Fonte de verdade | Serviço de produto do ERP |
| Identidade exigida | Operador com permissão de leitura de produtos |
| Dado excluído | Custo, fornecedor e dados de outras filiais |
| Efeito | Nenhum |

Verifique se a pergunta exige mesmo uma tool. Políticas estáticas podem ser resources; um roteiro
de conversa pode ser prompt. Evite uma tool de SQL livre.

## 2. Preserve o serviço de negócio

Crie ou localize um método Delphi equivalente a `ConsultProduct(Id)`. Ele recebe um tipo simples,
valida identificador e escopo de acesso, consulta o repositório que o ERP já usa e devolve apenas
os dados autorizados. O serviço não deve receber JSON-RPC, escrever em `stdout` nem conhecer um
host de IA. Teste esse método diretamente com produto existente, inexistente e acesso negado.

## 3. Publique o adaptador MCP

Em `TechStore.Mcp.pas`, siga o caminho de `consultar_produto`:

1. Acrescente nome, descrição e `inputSchema` em `HandleToolsList`.
2. Leia `params.name` e `params.arguments` em `HandleToolsCall`.
3. Rejeite tipo incorreto, campo adicional e identificador fora da faixa.
4. Chame o serviço Delphi após a validação de protocolo e de autorização.
5. Construa `content` e `structuredContent` apenas com os campos da ficha.

O contrato publicado por `tools/list` deve corresponder exatamente ao que `tools/call` aceita.
Não copie `TJSONObject` inteiro do banco para a saída: selecione os campos do caso de uso.

## 4. Teste pelas fronteiras

Acrescente à suíte Delphi pelo menos um caso para descoberta, sucesso, identificador ausente,
tipo incorreto, entidade inexistente, propriedade inesperada e acesso negado. Acrescente ao teste
de processo uma chamada pelo binário compilado para verificar JSON-RPC por linha, UTF-8,
`stdout`, `stderr` e encerramento. Execute os dois programas de testes do
[QUICKSTART.md](QUICKSTART.md). Use o MCP Inspector para conferir o schema e a resposta como um
cliente independente. O Inspector é ferramenta de verificação, não dependência do servidor.

## 5. Faça o aceite em homologação

Configure o host escolhido com caminho absoluto para o executável e `--mcp-stdio`. Confirme que
ele usa o perfil moderno anunciado por `server/discover` ou o modo legado `2025-11-25`.
Use uma conta e dados de homologação.
Peça a uma pessoa da área de negócio para fazer a pergunta da ficha e conferir o significado do
resultado, inclusive resposta vazia e negação. Registre versão do executável, ambiente, resultado
dos testes e decisão de liberar ou corrigir.

## Critério de conclusão

A primeira capability está pronta para piloto local quando outra pessoa consegue compilar o
projeto, executar os testes, configurar o host, descobrir a tool, obter uma resposta correta e
entender seus limites sem pedir ao autor que explique o código. Para dados reais, também são
necessários identidade confiável, autorização por escopo, configuração por ambiente, logs sem
segredos e procedimento de desativação. O exemplo público demonstra essas decisões, mas não
fornece a infraestrutura específica da sua empresa.
