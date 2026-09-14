# Changelog

## 0.4.0 — 2026-09-14

- transporte `stdio` com leitura e escrita explícitas em UTF-8;
- teste de processo em Delphi com pipes, texto acentuado e encerramento por EOF;
- argumento `objetivo` do prompt aplicado à mensagem;
- roteiro de adaptação a outro ERP, configuração por ambiente e versionamento de contratos.
- compatibilidade `initialize`/`notifications/initialized` para clientes MCP 2025-11-25,
  verificada com o MCP Inspector CLI, além do perfil moderno principal.

## 0.2.0 — 2026-09-14

- migração para MCP `2026-07-28` moderno e sem estado;
- implementação de `server/discover` e metadados `_meta` por requisição;
- resultados com `resultType`, metadados do servidor e `structuredContent`;
- documentação de instalação, compatibilidade, segurança e evolução do protocolo.
