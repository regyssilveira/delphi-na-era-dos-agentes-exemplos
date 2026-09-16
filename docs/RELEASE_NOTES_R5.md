# Exemplos da 1ª edição — revisão r5

Esta revisão preserva o estado reproduzível dos exemplos correspondente ao fechamento do livro
com 236 páginas. Ela mantém o protocolo e o executável validados em `r4` e acrescenta a jornada
didática que passou a integrar a prova final.

## O que foi acrescentado

- `docs/CONSTRUIR_DO_ZERO.md`, do projeto Console vazio ao servidor usado por um host;
- conversa composta em `docs/HOST_CODEX_CLI.md`, com quatro tools e distinção entre fato e
  interpretação;
- ligação explícita entre o Apêndice Q e o repositório em `docs/BOOK_ALIGNMENT.md`;
- entrada do roteiro do zero no README e no QUICKSTART.
- inclusão explícita das units auxiliares usadas pelas rotinas inline do Delphi, eliminando os
  *hints* de compilação observados em `Data.DB`, parâmetros FireDAC e coleções genéricas.

## Comportamento preservado

- Delphi 13 Florence, Win64 e compilador 37.0;
- MCP moderno `2026-07-28` e compatibilidade `2025-11-25`;
- cinco tools, um resource e um prompt;
- orçamento apenas `PREPARADO`, sem confirmação ou baixa de estoque;
- testes de contrato e de processo com UTF-8.

Para reproduzir a edição, selecione a release indicada no README, compile o servidor e execute
as duas suítes antes de iniciar o Inspector ou um host de IA.
