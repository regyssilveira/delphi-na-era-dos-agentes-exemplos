unit TechStore.Mcp;

interface

uses
  TechStore.Data;

type
  TTechStoreMcpServer = class
  private
    FDatabase: TTechStoreDatabase;
    FInitialized: Boolean;
    function ErrorResponse(const AId, ACode, AMessage: string): string;
    function HandleInitialize(const AId: string): string;
    function HandleToolsList(const AId: string): string;
    function HandleToolsCall(const AId: string; const AParamsJson: string): string;
  public
    constructor Create(ADatabase: TTechStoreDatabase);
    function ProcessLine(const ALine: string): string;
  end;

implementation

uses
  System.JSON,
  System.SysUtils;

constructor TTechStoreMcpServer.Create(ADatabase: TTechStoreDatabase);
begin
  inherited Create;
  FDatabase := ADatabase;
end;

function TTechStoreMcpServer.ErrorResponse(const AId, ACode, AMessage: string): string;
begin
  Result := Format(
    '{"jsonrpc":"2.0","id":%s,"error":{"code":%s,"message":%s}}',
    [AId, ACode, TJSONString.Create(AMessage).ToJSON]);
end;

function TTechStoreMcpServer.HandleInitialize(const AId: string): string;
begin
  Result := Format(
    '{"jsonrpc":"2.0","id":%s,"result":{' +
    '"protocolVersion":"2026-07-28",' +
    '"serverInfo":{"name":"techstore-erp","version":"0.1.0"},' +
    '"capabilities":{"tools":{}}}}', [AId]);
end;

function TTechStoreMcpServer.HandleToolsList(const AId: string): string;
begin
  Result := Format(
    '{"jsonrpc":"2.0","id":%s,"result":{"tools":[' +
    '{"name":"consultar_estoque_baixo",' +
    '"description":"Retorna produtos cujo saldo está abaixo do estoque mínimo.",' +
    '"inputSchema":{"type":"object","additionalProperties":false}}]}}', [AId]);
end;

function TTechStoreMcpServer.HandleToolsCall(const AId: string;
  const AParamsJson: string): string;
var
  Params: TJSONObject;
  NameValue: TJSONValue;
  Data: TJSONArray;
  Content: string;
begin
  Params := TJSONObject.ParseJSONValue(AParamsJson) as TJSONObject;
  try
    if Params = nil then
      Exit(ErrorResponse(AId, '-32602', 'Os parâmetros devem ser um objeto JSON.'));
    NameValue := Params.GetValue('name');
    if (NameValue = nil) or not SameText(NameValue.Value, 'consultar_estoque_baixo') then
      Exit(ErrorResponse(AId, '-32601', 'Ferramenta não encontrada.'));

    Data := FDatabase.ListLowStock;
    try
      Content := Data.ToJSON;
      Result := Format(
        '{"jsonrpc":"2.0","id":%s,"result":{"content":[' +
        '{"type":"text","text":%s}],"isError":false}}',
        [AId, TJSONString.Create(Content).ToJSON]);
    finally
      Data.Free;
    end;
  finally
    Params.Free;
  end;
end;

function TTechStoreMcpServer.ProcessLine(const ALine: string): string;
var
  Request: TJSONObject;
  MethodValue: TJSONValue;
  IdValue: TJSONValue;
  ParamsValue: TJSONValue;
  Id: string;
  IsNotification: Boolean;
begin
  Request := TJSONObject.ParseJSONValue(ALine) as TJSONObject;
  try
    if Request = nil then
      Exit(ErrorResponse('null', '-32700', 'JSON inválido.'));
    IdValue := Request.GetValue('id');
    IsNotification := IdValue = nil;
    if IsNotification then
      Id := 'null'
    else
      Id := IdValue.ToJSON;
    MethodValue := Request.GetValue('method');
    if MethodValue = nil then
    begin
      if IsNotification then
        Exit('');
      Exit(ErrorResponse(Id, '-32600', 'Método ausente.'));
    end;

    if SameText(MethodValue.Value, 'notifications/initialized') then
    begin
      FInitialized := True;
      Exit('');
    end;

    if IsNotification then
      Exit('');

    if SameText(MethodValue.Value, 'initialize') then
      Exit(HandleInitialize(Id));
    if not FInitialized then
      Exit(ErrorResponse(Id, '-32002',
        'O cliente deve enviar notifications/initialized antes desta chamada.'));
    if SameText(MethodValue.Value, 'tools/list') then
      Exit(HandleToolsList(Id));
    if SameText(MethodValue.Value, 'tools/call') then
    begin
      ParamsValue := Request.GetValue('params');
      if ParamsValue = nil then
        Exit(ErrorResponse(Id, '-32602', 'Parâmetros ausentes.'));
      Exit(HandleToolsCall(Id, ParamsValue.ToJSON));
    end;
    Result := ErrorResponse(Id, '-32601', 'Método não suportado.');
  finally
    Request.Free;
  end;
end;

end.
