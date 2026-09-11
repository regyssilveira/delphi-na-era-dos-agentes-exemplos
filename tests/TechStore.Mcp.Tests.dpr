program TechStoreMcpTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TechStore.Data in '..\src\TechStore.Data.pas',
  TechStore.Services in '..\src\TechStore.Services.pas',
  TechStore.Authorization in '..\src\TechStore.Authorization.pas',
  TechStore.Mcp in '..\src\TechStore.Mcp.pas',
  TechStore.Mcp.LocalClient in '..\src\TechStore.Mcp.LocalClient.pas';

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
  Client: TTechStoreMcpLocalClient;
  Services: TTechStoreServices;
  Authorization: TTechStoreAuthorization;
  Response: string;
begin
  Database := TTechStoreDatabase.Create;
  try
    Database.Initialize;
    Authorization := TTechStoreAuthorization.Create;
    try
      Authorization.RequireAllowed('operador-demo', 'consultar_produto', tsaRead);
      try
        Authorization.RequireAllowed('operador-demo', 'confirmar_compra', tsaConfirmCritical);
        Require(False, 'Confirmação crítica deveria ser bloqueada.');
      except
        on E: ETechStoreAuthorization do
          RequireContains(E.Message, 'aprovação humana');
      end;
    finally
      Authorization.Free;
    end;
    Services := TTechStoreServices.Create(Database);
    try
      Response := Services.ConsultCustomer(1).ToJSON;
      RequireContains(Response, 'Ana Martins');
      Response := Services.ConsultProduct(2).ToJSON;
      RequireContains(Response, 'Mouse Orbital');
    finally
      Services.Free;
    end;
    Server := TTechStoreMcpServer.Create(Database);
    try
      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":0,"method":"tools/list","params":{}}');
      RequireContains(Response, '"code":-32002');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}');
      Require(Response = '', 'Notificação não deve gerar resposta JSON-RPC.');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":0,"method":"tools/list","params":{}}');
      RequireContains(Response, '"code":-32002');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{' +
        '"protocolVersion":"2026-07-28","capabilities":{},' +
        '"clientInfo":{"name":"teste","version":"1.0"}}}');
      RequireContains(Response, '"protocolVersion":"2026-07-28"');
      RequireContains(Response, '"tools":{}');
      RequireContains(Response, '"resources":{}');
      RequireContains(Response, '"prompts":{}');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":11,"method":"initialize","params":{' +
        '"protocolVersion":"incompativel"}}');
      RequireContains(Response, '"code":-32602');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}');
      Require(Response = '', 'Notificação não deve gerar resposta JSON-RPC.');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}');
      RequireContains(Response, '"consultar_estoque_baixo"');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":"request-a","method":"tools/list","params":{}}');
      RequireContains(Response, '"id":"request-a"');

      Response := Server.ProcessLine(
        '{"jsonrpc":"1.0","id":21,"method":"tools/list","params":{}}');
      RequireContains(Response, '"id":null');
      RequireContains(Response, '"code":-32600');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":22,"method":42,"params":{}}');
      RequireContains(Response, '"code":-32600');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":3,"method":"tools/call",' +
        '"params":{"name":"consultar_estoque_baixo","arguments":{}}}');
      RequireContains(Response, '"isError":false');
      RequireContains(Response, 'Mouse Orbital');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":31,"method":"tools/call",' +
        '"params":{"name":"consultar_cliente","arguments":{"id":999}}}');
      RequireContains(Response, '"code":-32602');
      RequireContains(Response, 'encontrado.');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":32,"method":"tools/call",' +
        '"params":{"name":"consultar_cliente","arguments":{"id":1}}}');
      RequireContains(Response, '"isError":false');
      RequireContains(Response, 'Ana Martins');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":33,"method":"tools/call",' +
        '"params":{"name":"consultar_produto","arguments":{"id":2}}}');
      RequireContains(Response, '"isError":false');
      RequireContains(Response, 'Mouse Orbital');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":34,"method":"tools/call",' +
        '"params":{"name":"consultar_produto","arguments":{"id":0}}}');
      RequireContains(Response, '"code":-32602');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":341,"method":"tools/call",' +
        '"params":{"name":"consultar_produto","arguments":{"id":2.5}}}');
      RequireContains(Response, '"code":-32602');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":342,"method":"tools/call",' +
        '"params":{"name":"consultar_produto","arguments":{' +
        '"id":2,"unexpected":true}}}');
      RequireContains(Response, '"code":-32602');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":35,"method":"tools/call",' +
        '"params":{"name":"criar_orcamento","arguments":{' +
        '"customerId":1,"productId":2,"quantity":20}}}');
      RequireContains(Response, '"isError":false');
      RequireContains(Response, 'PREPARADO');
      RequireContains(Response, 'requiresHumanApproval');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":36,"method":"tools/call",' +
        '"params":{"name":"criar_orcamento","arguments":{' +
        '"customerId":1,"productId":2,"quantity":0}}}');
      RequireContains(Response, '"code":-32602');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":361,"method":"tools/call",' +
        '"params":{"name":"criar_orcamento","arguments":{' +
        '"customerId":1,"productId":2,"quantity":1.5}}}');
      RequireContains(Response, '"code":-32602');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":362,"method":"tools/call",' +
        '"params":{"name":"criar_orcamento","arguments":{' +
        '"customerId":1,"productId":2,"quantity":1,"unexpected":true}}}');
      RequireContains(Response, '"code":-32602');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":4,"method":"resources/list","params":{}}');
      RequireContains(Response, 'techstore://policies/operation-classification');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":5,"method":"resources/read",' +
        '"params":{"uri":"techstore://policies/operation-classification"}}');
      RequireContains(Response, 'techstore://policies/operation-classification');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":6,"method":"prompts/list","params":{}}');
      RequireContains(Response, 'analisar_estoque_baixo');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":7,"method":"prompts/get",' +
        '"params":{"name":"analisar_estoque_baixo"}}');
      RequireContains(Response, 'consultar_estoque_baixo');

      Response := Server.ProcessLine('não é JSON');
      RequireContains(Response, '"code":-32700');

      Client := TTechStoreMcpLocalClient.Create(Server);
      try
        Client.Initialize;
        RequireContains(Client.ListTools(), 'consultar_estoque_baixo');
        RequireContains(Client.ListResources(),
          'techstore://policies/operation-classification');
        RequireContains(Client.GetPrompt('analisar_estoque_baixo'),
          'consultar_estoque_baixo');
      finally
        Client.Free;
      end;
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
