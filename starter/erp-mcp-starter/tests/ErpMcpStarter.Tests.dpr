program ErpMcpStarter.Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Starter.Contracts in '..\src\Starter.Contracts.pas',
  Starter.ExampleProductService in '..\src\Starter.ExampleProductService.pas',
  Starter.Tool in '..\src\Starter.Tool.pas',
  Starter.Mcp in '..\src\Starter.Mcp.pas';

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

var
  Service: IProductQueryService;
  Tool: TProductTool;
  Server: TStarterMcpServer;
  Json, Response, Meta: string;
begin
  Service := TExampleProductService.Create;
  Tool := TProductTool.Create(Service);
  try
    Json := Tool.Execute(1);
    Check(Json.Contains('"ok":true'), 'produto existente deveria retornar sucesso');
    Check(Json.Contains('Produto de demonstra\u00E7\u00E3o'),
      'texto Unicode deveria ser preservado');
    Json := Tool.Execute(999);
    Check(Json.Contains('product_not_found'), 'ausência deveria ter erro estável');
  finally
    Tool.Free;
  end;
  Meta := '"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28",' +
    '"io.modelcontextprotocol/clientCapabilities":{}}';
  Server := TStarterMcpServer.Create(Service);
  try
    Response := Server.ProcessLine('{"jsonrpc":"2.0","id":1,' +
      '"method":"server/discover","params":{' + Meta + '}}');
    Check(Response.Contains('"supportedVersions":["2026-07-28"]'), 'descoberta MCP');
    Response := Server.ProcessLine('{"jsonrpc":"2.0","id":2,' +
      '"method":"tools/list","params":{' + Meta + '}}');
    Check(Response.Contains('"name":"consultar_produto"'), 'catálogo MCP');
    Response := Server.ProcessLine('{"jsonrpc":"2.0","id":3,' +
      '"method":"tools/call","params":{' + Meta +
      ',"name":"consultar_produto","arguments":{"id":1}}}');
    Check(Response.Contains('Produto de demonstra\u00E7\u00E3o'), 'chamada MCP e UTF-8');
    Check(Response.Contains('"structuredContent"'), 'resultado estruturado');
    Response := Server.ProcessLine('{"jsonrpc":"2.0","id":4,' +
      '"method":"tools/call","params":{' + Meta +
      ',"name":"consultar_produto","arguments":{"id":1,"extra":true}}}');
    Check(Response.Contains('"code":-32602'), 'propriedade extra deveria ser recusada');
    Response := Server.ProcessLine('{"jsonrpc":"2.0","id":5,' +
      '"method":"tools/call","params":{' + Meta +
      ',"name":"consultar_produto","arguments":{"id":999}}}');
    Check(Response.Contains('"isError":true'), 'ausência deveria ser erro visível à IA');
    Response := Server.ProcessLine('[]');
    Check(Response.Contains('"code":-32600'), 'array não deveria derrubar o processo');
    Response := Server.ProcessLine('{invalido');
    Check(Response.Contains('"code":-32700'), 'JSON inválido deveria ter erro de parse');
    Writeln('10 testes aprovados.');
  finally
    Server.Free;
  end;
end.
