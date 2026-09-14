# Segurança

O TechStore é um laboratório local com dados fictícios. Ele não deve receber dados pessoais,
credenciais, segredos empresariais ou ser exposto em rede.

## Limites de segurança desta versão

- somente `stdio` local; sem HTTP, TLS, OAuth ou autenticação;
- nenhuma tool confirma operação crítica;
- validação estrita dos argumentos de cada tool;
- `stdout` reservado exclusivamente ao protocolo; diagnósticos devem ir para `stderr`.

Para relatar uma vulnerabilidade, abra uma issue privada no repositório ou contate o autor pelo
canal indicado no livro. Não publique credenciais, bases de dados ou passos de exploração com
dados de terceiros em issues públicas.
