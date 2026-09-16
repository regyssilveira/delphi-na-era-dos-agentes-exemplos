unit Starter.Mcp;

interface

uses Starter.Contracts;

type
  TStarterMcpServer = class
  private
    FService: IProductQueryService;
    function JsonString(const AValue: string): string;
    function ErrorResponse(const AId, ACode, AMessage: string): string;
    function CompleteResponse(const AId, AFields: string): string;
    function ValidateMeta(const AParams: string; out AMessage: string): Boolean;
    function HandleToolsCall(const AId, AParams: string): string;
  public
    constructor Create(const AService: IProductQueryService);
    function ProcessLine(const ALine: string): string;
  end;

implementation

uses System.JSON, System.SysUtils, System.Generics.Collections, Starter.Tool;

const
  ProtocolVersion = '2026-07-28';
  ServerVersion = '1.0.0';

constructor TStarterMcpServer.Create(const AService: IProductQueryService);
begin
  inherited Create;
  if not Assigned(AService) then raise EArgumentNilException.Create('AService');
  FService := AService;
end;

function TStarterMcpServer.JsonString(const AValue: string): string;
var Value: TJSONString;
begin
  Value := TJSONString.Create(AValue);
  try Result := Value.ToJSON finally Value.Free end;
end;

function TStarterMcpServer.ErrorResponse(const AId, ACode, AMessage: string): string;
begin
  Result := Format('{"jsonrpc":"2.0","id":%s,"error":{"code":%s,"message":%s}}',
    [AId, ACode, JsonString(AMessage)]);
end;

function TStarterMcpServer.CompleteResponse(const AId, AFields: string): string;
begin
  Result := Format('{"jsonrpc":"2.0","id":%s,"result":{"resultType":"complete",%s,' +
    '"_meta":{"io.modelcontextprotocol/serverInfo":{"name":"erp-mcp-starter",' +
    '"version":"%s"}}}}', [AId, AFields, ServerVersion]);
end;

function TStarterMcpServer.ValidateMeta(const AParams: string;
  out AMessage: string): Boolean;
var Params, Meta: TJSONObject; Value: TJSONValue;
begin
  Result := False;
  Params := TJSONObject.ParseJSONValue(AParams) as TJSONObject;
  try
    if Params = nil then begin AMessage := 'Params deve ser objeto.'; Exit end;
    Value := Params.GetValue('_meta');
    if not (Value is TJSONObject) then begin AMessage := 'params._meta é obrigatório.'; Exit end;
    Meta := TJSONObject(Value);
    Value := Meta.GetValue('io.modelcontextprotocol/protocolVersion');
    if not (Value is TJSONString) or not SameText(Value.Value, ProtocolVersion) then
      begin AMessage := 'Versão MCP não suportada.'; Exit end;
    Value := Meta.GetValue('io.modelcontextprotocol/clientCapabilities');
    if not (Value is TJSONObject) then
      begin AMessage := 'clientCapabilities deve ser objeto.'; Exit end;
    Result := True;
  finally
    Params.Free;
  end;
end;

function TStarterMcpServer.HandleToolsCall(const AId, AParams: string): string;
var
  Params, Arguments: TJSONObject;
  Value: TJSONValue;
  ProductId, Index: Integer;
  Tool: TProductTool;
  DataText: string;
  Data: TJSONValue;
  IsError: Boolean;
begin
  Params := TJSONObject.ParseJSONValue(AParams) as TJSONObject;
  try
    if Params = nil then Exit(ErrorResponse(AId, '-32602', 'Params deve ser objeto.'));
    Value := Params.GetValue('name');
    if not (Value is TJSONString) or not SameText(Value.Value, 'consultar_produto') then
      Exit(ErrorResponse(AId, '-32601', 'Tool não encontrada.'));
    Value := Params.GetValue('arguments');
    if not (Value is TJSONObject) then
      Exit(ErrorResponse(AId, '-32602', 'Arguments deve ser objeto.'));
    Arguments := TJSONObject(Value);
    for Index := 0 to Arguments.Count - 1 do
      if not SameText(Arguments.Pairs[Index].JsonString.Value, 'id') then
        Exit(ErrorResponse(AId, '-32602', 'Arguments contém propriedade não permitida.'));
    Value := Arguments.GetValue('id');
    if not (Value is TJSONNumber) or
       not TryStrToInt(TJSONNumber(Value).Value, ProductId) or (ProductId <= 0) then
      Exit(ErrorResponse(AId, '-32602', 'Arguments.id deve ser inteiro positivo.'));
    Tool := TProductTool.Create(FService);
    try DataText := Tool.Execute(ProductId) finally Tool.Free end;
    Data := TJSONObject.ParseJSONValue(DataText);
    try
      IsError := SameText(Data.GetValue<string>('ok'), 'False');
      Result := CompleteResponse(AId, Format(
        '"content":[{"type":"text","text":%s}],"structuredContent":%s,"isError":%s',
        [JsonString(DataText), DataText, LowerCase(BoolToStr(IsError, True))]));
    finally Data.Free end;
  finally Params.Free end;
end;

function TStarterMcpServer.ProcessLine(const ALine: string): string;
var Parsed, Value: TJSONValue; Root, Params: TJSONObject; Id, Method, ParamsText, Message: string;
begin
  Parsed := TJSONObject.ParseJSONValue(ALine);
  if Parsed = nil then Exit(ErrorResponse('null', '-32700', 'JSON inválido.'));
  if not (Parsed is TJSONObject) then
  begin
    Parsed.Free;
    Exit(ErrorResponse('null', '-32600', 'A requisição deve ser um objeto JSON.'));
  end;
  Root := TJSONObject(Parsed);
  try
    Value := Root.GetValue('jsonrpc');
    if not (Value is TJSONString) or (Value.Value <> '2.0') then
      Exit(ErrorResponse('null', '-32600', 'jsonrpc deve ser 2.0.'));
    Value := Root.GetValue('id');
    if Value = nil then Exit(ErrorResponse('null', '-32600', 'id é obrigatório.'));
    Id := Value.ToJSON;
    Value := Root.GetValue('method');
    if not (Value is TJSONString) then Exit(ErrorResponse(Id, '-32600', 'method é obrigatório.'));
    Method := Value.Value;
    Value := Root.GetValue('params');
    if not (Value is TJSONObject) then Exit(ErrorResponse(Id, '-32602', 'params deve ser objeto.'));
    Params := TJSONObject(Value);
    ParamsText := Params.ToJSON;
    if not ValidateMeta(ParamsText, Message) then Exit(ErrorResponse(Id, '-32602', Message));
    if SameText(Method, 'server/discover') then
      Exit(CompleteResponse(Id, '"supportedVersions":["' + ProtocolVersion + '"],' +
        '"capabilities":{"tools":{}},"instructions":"Starter MCP para adaptação ao ERP."'));
    if SameText(Method, 'tools/list') then
      Exit(CompleteResponse(Id, '"tools":[{"name":"consultar_produto",' +
        '"title":"Consultar produto","description":"Consulta um produto pelo identificador.",' +
        '"inputSchema":{"type":"object","properties":{"id":{"type":"integer",' +
        '"minimum":1}},"required":["id"],"additionalProperties":false}}]'));
    if SameText(Method, 'tools/call') then Exit(HandleToolsCall(Id, ParamsText));
    Result := ErrorResponse(Id, '-32601', 'Método não encontrado.');
  finally Root.Free end;
end;

end.
