program TechStoreMcpTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
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

function Meta: string;
begin
  Result :=
    '"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28",' +
    '"io.modelcontextprotocol/clientInfo":{"name":"testes-delphi","version":"0.2.0"},' +
    '"io.modelcontextprotocol/clientCapabilities":{}}';
end;

function Request(const AId: Integer; const AMethod, AFields: string): string;
var
  Fields: string;
begin
  Fields := Meta;
  if AFields <> '' then
    Fields := Fields + ',' + AFields;
  Result := Format('{"jsonrpc":"2.0","id":%d,"method":"%s","params":{%s}}',
    [AId, AMethod, Fields]);
end;

procedure Run;
var
  Database: TTechStoreDatabase;
  Server: TTechStoreMcpServer;
  Client: TTechStoreMcpLocalClient;
  Services: TTechStoreServices;
  Authorization: TTechStoreAuthorization;
  Response: string;
  ProductSnapshot: TJSONObject;
  DatabaseFileName: string;
  TestId: TGUID;
begin
  CreateGUID(TestId);
  DatabaseFileName := TPath.Combine(TPath.GetTempPath,
    'techstore-mcp-' + GUIDToString(TestId) + '.db');
  Database := TTechStoreDatabase.Create(DatabaseFileName);
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
        '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}');
      RequireContains(Response, '"code":-32602');

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{"_meta":{' +
        '"io.modelcontextprotocol/protocolVersion":"incompativel",' +
        '"io.modelcontextprotocol/clientCapabilities":{}}}}');
      RequireContains(Response, '"code":-32022');
      RequireContains(Response, '"supported":["2026-07-28"]');

      Response := Server.ProcessLine(Request(3, 'server/discover', ''));
      RequireContains(Response, '"supportedVersions":["2026-07-28"]');
      RequireContains(Response, '"resultType":"complete"');
      RequireContains(Response,
        '"_meta":{"io.modelcontextprotocol/serverInfo":{"name":"techstore-erp"');
      Require(not Response.Contains('"serverInfo":{"name":"techstore-erp"'),
        'serverInfo não deve aparecer no corpo da descoberta moderna.');

      Response := Server.ProcessLine(Request(4, 'tools/list', ''));
      RequireContains(Response, '"consultar_estoque_baixo"');
      RequireContains(Response, '"ttlMs":300000');
      RequireContains(Response,
        '"_meta":{"io.modelcontextprotocol/serverInfo":{"name":"techstore-erp"');

      Response := Server.ProcessLine(Request(5, 'tools/call',
        '"name":"consultar_estoque_baixo","arguments":{}'));
      RequireContains(Response, '"isError":false');
      RequireContains(Response, '"structuredContent":');
      RequireContains(Response, 'Mouse Orbital');

      Response := Server.ProcessLine(Request(6, 'tools/call',
        '"name":"consultar_cliente","arguments":{"id":999}'));
      RequireContains(Response, '"code":-32602');
      RequireContains(Response, 'encontrado.');

      Response := Server.ProcessLine(Request(7, 'tools/call',
        '"name":"consultar_cliente","arguments":{"id":1}'));
      RequireContains(Response, 'Ana Martins');

      Response := Server.ProcessLine(Request(8, 'tools/call',
        '"name":"consultar_produto","arguments":{"id":2.5}'));
      RequireContains(Response, '"code":-32602');
      Response := Server.ProcessLine(Request(21, 'tools/call',
        '"name":"consultar_produto","arguments":{"id":2}'));
      RequireContains(Response, 'Mouse Orbital');
      RequireContains(Response, '"stockQuantity":3');
      RequireContains(Response, '"minimumStock":10');
      Response := Server.ProcessLine(Request(22, 'tools/call',
        '"name":"tool_inexistente","arguments":{}'));
      RequireContains(Response, '"code":-32601');

      Response := Server.ProcessLine(Request(9, 'tools/call',
        '"name":"criar_orcamento","arguments":{' +
        '"customerId":1,"productId":2,"quantity":20}'));
      RequireContains(Response, 'PREPARADO');
      RequireContains(Response, 'requiresHumanApproval');
      ProductSnapshot := Database.FindProductById(2);
      try
        RequireContains(ProductSnapshot.ToJSON, '"stockQuantity":3');
      finally
        ProductSnapshot.Free;
      end;
      Response := Server.ProcessLine(Request(20, 'tools/call',
        '"name":"criar_orcamento","arguments":{' +
        '"customerId":1,"productId":2,"quantity":0}'));
      RequireContains(Response, '"code":-32602');
      ProductSnapshot := Database.FindProductById(2);
      try
        RequireContains(ProductSnapshot.ToJSON, '"stockQuantity":3');
      finally
        ProductSnapshot.Free;
      end;

      Response := Server.ProcessLine(Request(14, 'tools/call',
        '"name":"consultar_faturas_cliente","arguments":{"id":1}'));
      RequireContains(Response, '"code":-32003');

      Server.Free;
      Server := TTechStoreMcpServer.Create(Database, 'operador-demo');
      Response := Server.ProcessLine(Request(15, 'tools/call',
        '"name":"consultar_faturas_cliente","arguments":{"id":1}'));
      RequireContains(Response, '8450');
      Require(not Response.Contains('creditLimit'), 'Resposta expôs limite de crédito.');
      Response := Server.ProcessLine(Request(16, 'tools/call',
        '"name":"consultar_faturas_cliente","arguments":{"id":999}'));
      RequireContains(Response, '"code":-32602');
      Response := Server.ProcessLine(Request(17, 'tools/call',
        '"name":"consultar_faturas_cliente","arguments":{"id":1.5}'));
      RequireContains(Response, '"code":-32602');
      Response := Server.ProcessLine(Request(18, 'tools/call',
        '"name":"consultar_faturas_cliente","arguments":{"id":1,"extra":true}'));
      RequireContains(Response, '"code":-32602');
      Response := Server.ProcessLine(Request(19, 'tools/call',
        '"name":"consultar_faturas_cliente","arguments":{"id":0}'));
      RequireContains(Response, '"code":-32602');

      Response := Server.ProcessLine(Request(10, 'resources/list', ''));
      RequireContains(Response, 'techstore://policies/operation-classification');
      Response := Server.ProcessLine(Request(11, 'resources/read',
        '"uri":"techstore://policies/operation-classification"'));
      RequireContains(Response, 'techstore://policies/operation-classification');

      Response := Server.ProcessLine(Request(12, 'prompts/list', ''));
      RequireContains(Response, 'analisar_estoque_baixo');
      Response := Server.ProcessLine(Request(13, 'prompts/get',
        '"name":"analisar_estoque_baixo"'));
      RequireContains(Response, 'consultar_estoque_baixo');

      Response := Server.ProcessLine('não é JSON');
      RequireContains(Response, '"code":-32700');

      Client := TTechStoreMcpLocalClient.Create(Server);
      try
        RequireContains(Client.Discover(), '"supportedVersions":["2026-07-28"]');
        RequireContains(Client.ListTools(), 'consultar_estoque_baixo');
        RequireContains(Client.ListResources(),
          'techstore://policies/operation-classification');
        RequireContains(Client.GetPrompt('analisar_estoque_baixo'),
          'consultar_estoque_baixo');
      finally
        Client.Free;
      end;

      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":30,"method":"initialize","params":{' +
        '"protocolVersion":"2025-11-25","capabilities":{},' +
        '"clientInfo":{"name":"teste-legado","version":"1.0"}}}');
      RequireContains(Response, '"protocolVersion":"2025-11-25"');
      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","method":"notifications/initialized"}');
      Require(Response = '', 'Notificação legada não deve gerar resposta.');
      Response := Server.ProcessLine(
        '{"jsonrpc":"2.0","id":31,"method":"tools/list","params":{}}');
      RequireContains(Response, 'consultar_estoque_baixo');
    finally
      Server.Free;
    end;
  finally
    Database.Free;
    if FileExists(DatabaseFileName) then
      DeleteFile(DatabaseFileName);
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
