unit TechStore.Mcp;

interface

uses
  System.JSON,
  TechStore.Data,
  TechStore.Services;

type
  TLegacyState = (lsNone, lsAwaitInitialized, lsReady);

  { Perfil moderno sem estado com compatibilidade local para clientes 2025-11-25. }
  TTechStoreMcpServer = class
  private
    FDatabase: TTechStoreDatabase;
    FServices: TTechStoreServices;
    FActor: string;
    FLegacyState: TLegacyState;
    function ErrorResponse(const AId, ACode, AMessage: string;
      const ADataJson: string = ''): string;
    function CompleteResponse(const AId, AFields: string): string;
    function JsonString(const AValue: string): string;
    function ValidateRequestMeta(const AParamsJson: string;
      out AErrorResponse: string): Boolean;
    function TryGetInteger(const AObject: TJSONObject; const AName: string;
      out AValue: Integer): Boolean;
    function HasOnlyArguments(const AObject: TJSONObject;
      const AAllowed: array of string): Boolean;
    function HandleDiscover(const AId: string): string;
    function HandleLegacyInitialize(const AId, AParamsJson: string): string;
    function HandleToolsList(const AId: string): string;
    function HandleToolsCall(const AId, AParamsJson: string): string;
    function ToolResult(const AId: string; const AData: TJSONValue): string;
    function HandleResourcesList(const AId: string): string;
    function HandleResourcesRead(const AId, AParamsJson: string): string;
    function HandlePromptsList(const AId: string): string;
    function HandlePromptsGet(const AId, AParamsJson: string): string;
  public
    constructor Create(ADatabase: TTechStoreDatabase; const AActor: string = '');
    destructor Destroy; override;
    function ProcessLine(const ALine: string): string;
  end;

implementation

uses
  System.SysUtils,
  TechStore.Authorization;

const
  McpProtocolVersion = '2026-07-28';
  LegacyProtocolVersion = '2025-11-25';
  ServerVersion = '0.4.0';

constructor TTechStoreMcpServer.Create(ADatabase: TTechStoreDatabase;
  const AActor: string);
begin
  inherited Create;
  FDatabase := ADatabase;
  FActor := AActor;
  FServices := TTechStoreServices.Create(FDatabase);
end;

destructor TTechStoreMcpServer.Destroy;
begin
  FServices.Free;
  inherited Destroy;
end;

function TTechStoreMcpServer.JsonString(const AValue: string): string;
var
  Json: TJSONString;
begin
  Json := TJSONString.Create(AValue);
  try
    Result := Json.ToJSON;
  finally
    Json.Free;
  end;
end;

function TTechStoreMcpServer.ErrorResponse(const AId, ACode, AMessage,
  ADataJson: string): string;
var
  DataFragment: string;
begin
  if ADataJson = '' then
    DataFragment := ''
  else
    DataFragment := ',"data":' + ADataJson;
  Result := Format(
    '{"jsonrpc":"2.0","id":%s,"error":{"code":%s,"message":%s%s}}',
    [AId, ACode, JsonString(AMessage), DataFragment]);
end;

function TTechStoreMcpServer.CompleteResponse(const AId, AFields: string): string;
begin
  Result := Format(
    '{"jsonrpc":"2.0","id":%s,"result":{"resultType":"complete",%s,' +
    '"_meta":{"io.modelcontextprotocol/serverInfo":{' +
    '"name":"techstore-erp","version":"%s"}}}}',
    [AId, AFields, ServerVersion]);
end;

function TTechStoreMcpServer.ValidateRequestMeta(const AParamsJson: string;
  out AErrorResponse: string): Boolean;
var
  Params, Meta: TJSONObject;
  Value: TJSONValue;
begin
  Result := False;
  Params := TJSONObject.ParseJSONValue(AParamsJson) as TJSONObject;
  try
    if Params = nil then
    begin
      AErrorResponse := 'Os parâmetros devem ser um objeto JSON.';
      Exit;
    end;
    Value := Params.GetValue('_meta');
    if not (Value is TJSONObject) then
    begin
      AErrorResponse := 'Cada requisição MCP deve informar params._meta.';
      Exit;
    end;
    Meta := TJSONObject(Value);
    Value := Meta.GetValue('io.modelcontextprotocol/protocolVersion');
    if not (Value is TJSONString) then
    begin
      AErrorResponse := 'params._meta deve informar io.modelcontextprotocol/protocolVersion.';
      Exit;
    end;
    if not SameText(Value.Value, McpProtocolVersion) then
    begin
      AErrorResponse := 'VERSAO_NAO_SUPORTADA';
      Exit;
    end;
    Value := Meta.GetValue('io.modelcontextprotocol/clientCapabilities');
    if not (Value is TJSONObject) then
    begin
      AErrorResponse := 'params._meta deve informar io.modelcontextprotocol/clientCapabilities como objeto.';
      Exit;
    end;
    Value := Meta.GetValue('io.modelcontextprotocol/clientInfo');
    if (Value <> nil) and not (Value is TJSONObject) then
    begin
      AErrorResponse := 'clientInfo, quando informado, deve ser um objeto.';
      Exit;
    end;
    Result := True;
  finally
    Params.Free;
  end;
end;

function TTechStoreMcpServer.TryGetInteger(const AObject: TJSONObject;
  const AName: string; out AValue: Integer): Boolean;
var
  Value: TJSONValue;
begin
  Value := AObject.GetValue(AName);
  Result := (Value is TJSONNumber) and
    TryStrToInt(TJSONNumber(Value).Value, AValue);
end;

function TTechStoreMcpServer.HasOnlyArguments(const AObject: TJSONObject;
  const AAllowed: array of string): Boolean;
var
  Index: Integer;
  AllowedName: string;
  IsAllowed: Boolean;
begin
  Result := True;
  for Index := 0 to AObject.Count - 1 do
  begin
    IsAllowed := False;
    for AllowedName in AAllowed do
      if SameText(AObject.Pairs[Index].JsonString.Value, AllowedName) then
      begin
        IsAllowed := True;
        Break;
      end;
    if not IsAllowed then
      Exit(False);
  end;
end;

function TTechStoreMcpServer.HandleDiscover(const AId: string): string;
begin
  Result := CompleteResponse(AId,
    '"supportedVersions":["' + McpProtocolVersion + '"],' +
    '"capabilities":{"tools":{},"resources":{},"prompts":{}},' +
    '"serverInfo":{"name":"techstore-erp","version":"' + ServerVersion + '"},' +
    '"instructions":"Servidor MCP local do TechStore. Use somente dados fictícios; ' +
    'criar_orcamento prepara uma minuta e não confirma operações.",' +
    '"ttlMs":300000,"cacheScope":"public"');
end;

function TTechStoreMcpServer.HandleLegacyInitialize(const AId,
  AParamsJson: string): string;
var
  Params: TJSONObject;
  VersionValue: TJSONValue;
begin
  Params := TJSONObject.ParseJSONValue(AParamsJson) as TJSONObject;
  try
    if Params = nil then
      Exit(ErrorResponse(AId, '-32602', 'Params de initialize deve ser objeto.'));
    VersionValue := Params.GetValue('protocolVersion');
    if not (VersionValue is TJSONString) then
      Exit(ErrorResponse(AId, '-32602', 'protocolVersion ausente.'));
    FLegacyState := lsAwaitInitialized;
    Result := Format('{"jsonrpc":"2.0","id":%s,"result":{' +
      '"protocolVersion":"%s",' +
      '"capabilities":{"tools":{},"resources":{},"prompts":{}},' +
      '"serverInfo":{"name":"techstore-erp","version":"%s"},' +
      '"instructions":"Perfil local de compatibilidade; dados ficticios."}}',
      [AId, LegacyProtocolVersion, ServerVersion]);
  finally
    Params.Free;
  end;
end;

function TTechStoreMcpServer.HandleToolsList(const AId: string): string;
begin
  Result := CompleteResponse(AId,
    '"tools":[' +
    '{"name":"consultar_cliente","title":"Consultar cliente",' +
    '"description":"Retorna um cliente fictício pelo identificador.",' +
    '"inputSchema":{"type":"object","properties":{"id":{"type":"integer"}},' +
    '"required":["id"],"additionalProperties":false}},' +
    '{"name":"consultar_produto","title":"Consultar produto",' +
    '"description":"Retorna um produto fictício pelo identificador.",' +
    '"inputSchema":{"type":"object","properties":{"id":{"type":"integer"}},' +
    '"required":["id"],"additionalProperties":false}},' +
    '{"name":"consultar_faturas_cliente","title":"Consultar faturas de cliente",' +
    '"description":"Lista faturas fictícias de um cliente; exige ator configurado no servidor.",' +
    '"inputSchema":{"type":"object","properties":{"id":{"type":"integer"}},' +
    '"required":["id"],"additionalProperties":false}},' +
    '{"name":"criar_orcamento","title":"Preparar orçamento",' +
    '"description":"Prepara uma cotação fictícia que exige aprovação humana.",' +
    '"inputSchema":{"type":"object","properties":{' +
    '"customerId":{"type":"integer"},"productId":{"type":"integer"},' +
    '"quantity":{"type":"integer"}},"required":["customerId","productId","quantity"],' +
    '"additionalProperties":false}},' +
    '{"name":"consultar_estoque_baixo","title":"Consultar estoque baixo",' +
    '"description":"Retorna produtos fictícios cujo saldo está abaixo do mínimo.",' +
    '"inputSchema":{"type":"object","additionalProperties":false}}],' +
    '"ttlMs":300000,"cacheScope":"public"');
end;

function TTechStoreMcpServer.ToolResult(const AId: string;
  const AData: TJSONValue): string;
var
  DataJson: string;
begin
  DataJson := AData.ToJSON;
  Result := CompleteResponse(AId,
    Format('"content":[{"type":"text","text":%s}],' +
      '"structuredContent":%s,"isError":false',
      [JsonString(DataJson), DataJson]));
end;

function TTechStoreMcpServer.HandleResourcesList(const AId: string): string;
begin
  Result := CompleteResponse(AId,
    '"resources":[' +
    '{"uri":"techstore://policies/operation-classification",' +
    '"name":"Classificação de operações",' +
    '"description":"Política didática para leitura, preparação e ação crítica.",' +
    '"mimeType":"text/markdown"}],' +
    '"ttlMs":300000,"cacheScope":"public"');
end;

function TTechStoreMcpServer.HandleResourcesRead(const AId,
  AParamsJson: string): string;
var
  Params: TJSONObject;
  UriValue: TJSONValue;
  Text: string;
begin
  Params := TJSONObject.ParseJSONValue(AParamsJson) as TJSONObject;
  try
    if Params = nil then
      Exit(ErrorResponse(AId, '-32602', 'Os parâmetros devem ser um objeto JSON.'));
    UriValue := Params.GetValue('uri');
    if (UriValue = nil) or not SameText(UriValue.Value,
      'techstore://policies/operation-classification') then
      Exit(ErrorResponse(AId, '-32602', 'Recurso não encontrado.'));
    Text := '# Classificação de operações' + sLineBreak + sLineBreak +
      '- Leitura: consulta dados fictícios sem efeito externo.' + sLineBreak +
      '- Preparação: cria uma minuta sujeita à revisão humana.' + sLineBreak +
      '- Ação crítica: exige identidade, autorização e aprovação explícita.';
    Result := CompleteResponse(AId,
      Format('"contents":[{"uri":"techstore://policies/operation-classification",' +
        '"mimeType":"text/markdown","text":%s}]', [JsonString(Text)]));
  finally
    Params.Free;
  end;
end;

function TTechStoreMcpServer.HandlePromptsList(const AId: string): string;
begin
  Result := CompleteResponse(AId,
    '"prompts":[' +
    '{"name":"analisar_estoque_baixo",' +
    '"description":"Orienta a análise dos produtos abaixo do estoque mínimo.",' +
    '"arguments":[{"name":"objetivo","description":"Finalidade da análise",' +
    '"required":false}]}],' +
    '"ttlMs":300000,"cacheScope":"public"');
end;

function TTechStoreMcpServer.HandlePromptsGet(const AId,
  AParamsJson: string): string;
var
  Params: TJSONObject;
  NameValue: TJSONValue;
  ArgumentsValue, ObjectiveValue: TJSONValue;
  Objective: string;
begin
  Params := TJSONObject.ParseJSONValue(AParamsJson) as TJSONObject;
  try
    if Params = nil then
      Exit(ErrorResponse(AId, '-32602', 'Os parâmetros devem ser um objeto JSON.'));
    NameValue := Params.GetValue('name');
    if (NameValue = nil) or not SameText(NameValue.Value,
      'analisar_estoque_baixo') then
      Exit(ErrorResponse(AId, '-32602', 'Prompt não encontrado.'));
    Objective := '';
    ArgumentsValue := Params.GetValue('arguments');
    if ArgumentsValue <> nil then
    begin
      if not (ArgumentsValue is TJSONObject) then
        Exit(ErrorResponse(AId, '-32602', 'Arguments deve ser um objeto JSON.'));
      if not HasOnlyArguments(TJSONObject(ArgumentsValue), ['objetivo']) then
        Exit(ErrorResponse(AId, '-32602', 'Arguments contém propriedades não permitidas.'));
      ObjectiveValue := TJSONObject(ArgumentsValue).GetValue('objetivo');
      if ObjectiveValue <> nil then
      begin
        if not (ObjectiveValue is TJSONString) then
          Exit(ErrorResponse(AId, '-32602', 'Arguments.objetivo deve ser texto.'));
        Objective := ObjectiveValue.Value;
      end;
    end;
    if Objective <> '' then
      Objective := ' Objetivo da análise: ' + Objective + '.';
    Result := CompleteResponse(AId,
      '"description":"Análise didática de estoque baixo.","messages":[' +
      '{"role":"user","content":{"type":"text","text":' +
      JsonString('Consulte consultar_estoque_baixo. Explique os itens encontrados, ' +
      'priorize o maior desvio em relação ao mínimo e não execute ações externas.' +
      Objective) + '}}]');
  finally
    Params.Free;
  end;
end;

function TTechStoreMcpServer.HandleToolsCall(const AId,
  AParamsJson: string): string;
var
  Params: TJSONObject;
  NameValue: TJSONValue;
  ArgumentsValue: TJSONValue;
  Data: TJSONArray;
  ObjectData: TJSONObject;
  CustomerId, ProductId, Quantity, EntityId: Integer;
begin
  Params := TJSONObject.ParseJSONValue(AParamsJson) as TJSONObject;
  try
    try
      if Params = nil then
        Exit(ErrorResponse(AId, '-32602', 'Os parâmetros devem ser um objeto JSON.'));
      NameValue := Params.GetValue('name');
      if not (NameValue is TJSONString) then
        Exit(ErrorResponse(AId, '-32601', 'Ferramenta não encontrada.'));
      if SameText(NameValue.Value, 'consultar_cliente') or
         SameText(NameValue.Value, 'consultar_produto') or
         SameText(NameValue.Value, 'criar_orcamento') or
         SameText(NameValue.Value, 'consultar_faturas_cliente') then
      begin
        ArgumentsValue := Params.GetValue('arguments');
        if not (ArgumentsValue is TJSONObject) then
          Exit(ErrorResponse(AId, '-32602', 'Arguments deve ser um objeto JSON.'));
        if SameText(NameValue.Value, 'criar_orcamento') then
        begin
          if not HasOnlyArguments(TJSONObject(ArgumentsValue),
            ['customerId', 'productId', 'quantity']) then
            Exit(ErrorResponse(AId, '-32602', 'Arguments contém propriedades não permitidas.'));
          if not TryGetInteger(TJSONObject(ArgumentsValue), 'customerId', CustomerId) then
            Exit(ErrorResponse(AId, '-32602', 'Arguments.customerId deve ser inteiro.'));
          if not TryGetInteger(TJSONObject(ArgumentsValue), 'productId', ProductId) then
            Exit(ErrorResponse(AId, '-32602', 'Arguments.productId deve ser inteiro.'));
          if not TryGetInteger(TJSONObject(ArgumentsValue), 'quantity', Quantity) then
            Exit(ErrorResponse(AId, '-32602', 'Arguments.quantity deve ser inteiro.'));
          ObjectData := FServices.PrepareQuote(CustomerId, ProductId, Quantity);
        end
        else
        begin
          if not HasOnlyArguments(TJSONObject(ArgumentsValue), ['id']) then
            Exit(ErrorResponse(AId, '-32602', 'Arguments contém propriedades não permitidas.'));
          if not TryGetInteger(TJSONObject(ArgumentsValue), 'id', EntityId) then
            Exit(ErrorResponse(AId, '-32602', 'Arguments.id deve ser inteiro.'));
          if SameText(NameValue.Value, 'consultar_cliente') then
            ObjectData := FServices.ConsultCustomer(EntityId)
          else if SameText(NameValue.Value, 'consultar_faturas_cliente') then
          begin
            Data := FServices.ConsultInvoicesByCustomer(FActor, EntityId);
            try
              Exit(ToolResult(AId, Data));
            finally
              Data.Free;
            end;
          end
          else
            ObjectData := FServices.ConsultProduct(EntityId);
        end;
        try
          Exit(ToolResult(AId, ObjectData));
        finally
          ObjectData.Free;
        end;
      end;
      if not SameText(NameValue.Value, 'consultar_estoque_baixo') then
        Exit(ErrorResponse(AId, '-32601', 'Ferramenta não encontrada.'));
      ArgumentsValue := Params.GetValue('arguments');
      if (ArgumentsValue <> nil) and
         ((not (ArgumentsValue is TJSONObject)) or
          (not HasOnlyArguments(TJSONObject(ArgumentsValue), []))) then
        Exit(ErrorResponse(AId, '-32602', 'Arguments contém propriedades não permitidas.'));
      Data := FServices.ConsultLowStock;
      try
        Result := ToolResult(AId, Data);
      finally
        Data.Free;
      end;
    except
      on E: ETechStoreBusinessRule do
        Result := ErrorResponse(AId, '-32602', E.Message);
      on E: ETechStoreAuthorization do
        Result := ErrorResponse(AId, '-32003', 'Acesso negado.');
    end;
  finally
    Params.Free;
  end;
end;

function TTechStoreMcpServer.ProcessLine(const ALine: string): string;
var
  Request: TJSONObject;
  VersionValue, MethodValue, IdValue, ParamsValue: TJSONValue;
  Id, MetaError: string;
  IsNotification: Boolean;
  MetaObject, RequestedVersion: TJSONValue;
  ParamsJson: string;
begin
  Request := TJSONObject.ParseJSONValue(ALine) as TJSONObject;
  try
    if Request = nil then
      Exit(ErrorResponse('null', '-32700', 'JSON inválido.'));
    IdValue := Request.GetValue('id');
    VersionValue := Request.GetValue('jsonrpc');
    if not (VersionValue is TJSONString) or not SameText(VersionValue.Value, '2.0') then
      Exit(ErrorResponse('null', '-32600', 'Versão JSON-RPC inválida.'));
    if (IdValue <> nil) and not ((IdValue is TJSONString) or (IdValue is TJSONNumber)) then
      Exit(ErrorResponse('null', '-32600', 'Identificador JSON-RPC inválido.'));
    IsNotification := IdValue = nil;
    if IsNotification then Id := 'null' else Id := IdValue.ToJSON;
    MethodValue := Request.GetValue('method');
    if not (MethodValue is TJSONString) then
      Exit(ErrorResponse(Id, '-32600', 'Método JSON-RPC inválido.'));
    ParamsValue := Request.GetValue('params');
    if SameText(MethodValue.Value, 'initialize') then
    begin
      if IsNotification then Exit('');
      if ParamsValue = nil then
        Exit(ErrorResponse(Id, '-32602', 'Params de initialize ausente.'));
      Exit(HandleLegacyInitialize(Id, ParamsValue.ToJSON));
    end;
    if SameText(MethodValue.Value, 'notifications/initialized') and
      (FLegacyState = lsAwaitInitialized) then
    begin
      if not IsNotification then
        Exit(ErrorResponse(Id, '-32600', 'initialized deve ser notificação.'));
      FLegacyState := lsReady;
      Exit('');
    end;
    if (FLegacyState = lsReady) and (ParamsValue = nil) then
      ParamsJson := '{}'
    else if ParamsValue <> nil then
      ParamsJson := ParamsValue.ToJSON
    else
      ParamsJson := '';
    if not (ParamsValue is TJSONObject) then
    begin
      if (FLegacyState = lsReady) and (ParamsValue = nil) then
      begin
        if IsNotification then Exit('');
      end
      else
      begin
      if IsNotification then Exit('');
      Exit(ErrorResponse(Id, '-32602', 'Cada requisição MCP deve possuir params com _meta.'));
      end;
    end;
    if (FLegacyState <> lsReady) and
       not ValidateRequestMeta(ParamsJson, MetaError) then
    begin
      if IsNotification then Exit('');
      if SameText(MetaError, 'VERSAO_NAO_SUPORTADA') then
      begin
        MetaObject := TJSONObject(ParamsValue).GetValue('_meta');
        RequestedVersion := nil;
        if MetaObject is TJSONObject then
          RequestedVersion := TJSONObject(MetaObject).GetValue(
            'io.modelcontextprotocol/protocolVersion');
        if RequestedVersion = nil then
          Exit(ErrorResponse(Id, '-32602', 'Versão MCP ausente.'));
        Exit(ErrorResponse(Id, '-32022', 'Versão MCP não suportada.',
          '{"supported":["' + McpProtocolVersion + '"],"requested":' +
          JsonString(RequestedVersion.Value) + '}'));
      end;
      Exit(ErrorResponse(Id, '-32602', MetaError));
    end;
    if IsNotification then Exit('');
    if SameText(MethodValue.Value, 'server/discover') then Exit(HandleDiscover(Id));
    if SameText(MethodValue.Value, 'tools/list') then Exit(HandleToolsList(Id));
    if SameText(MethodValue.Value, 'tools/call') then Exit(HandleToolsCall(Id, ParamsJson));
    if SameText(MethodValue.Value, 'resources/list') then Exit(HandleResourcesList(Id));
    if SameText(MethodValue.Value, 'resources/read') then Exit(HandleResourcesRead(Id, ParamsJson));
    if SameText(MethodValue.Value, 'prompts/list') then Exit(HandlePromptsList(Id));
    if SameText(MethodValue.Value, 'prompts/get') then Exit(HandlePromptsGet(Id, ParamsJson));
    Result := ErrorResponse(Id, '-32601', 'Método não suportado.');
  finally
    Request.Free;
  end;
end;

end.
