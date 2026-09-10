program TechStoreMcpTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TechStore.Data in '..\src\TechStore.Data.pas',
  TechStore.Mcp in '..\src\TechStore.Mcp.pas';

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure RequireContains(const AText, AExpected: string);
begin
  Require(AText.Contains(AExpected),
    Format('Resposta não contém "%s": %s', [AExpected, AText]));
end;

procedure Run;
var
  Database: TTechStoreDatabase;
  Server: TTechStoreMcpServer;
  Response: string;
begin
  Database := TTechStoreDatabase.Create;
  try
    Database.Initialize;
    Server := TTechStoreMcpServer.Create(Database);
    try
      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}');
      RequireContains(Response, '"protocolVersion":"2026-07-28"');
      RequireContains(Response, '"tools":{}');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}');
      Require(Response = '', 'Notificação não deve gerar resposta JSON-RPC.');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}');
      RequireContains(Response, '"consultar_estoque_baixo"');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":3,"method":"tools/call",' +
        '"params":{"name":"consultar_estoque_baixo","arguments":{}}}');
      RequireContains(Response, '"isError":false');
      RequireContains(Response, 'Mouse Orbital');

      Response := Server.ProcessLine('não é JSON');
      RequireContains(Response, '"code":-32700');
    finally
      Server.Free;
    end;
  finally
    Database.Free;
  end;
end;

begin
  try
    Run;
    Writeln('Todos os testes MCP passaram.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
