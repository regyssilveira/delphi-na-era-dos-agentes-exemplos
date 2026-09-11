unit TechStore.Mcp;

interface

uses
  System.JSON,
  TechStore.Data,
  TechStore.Services;

type
  TTechStoreMcpServer = class
  private
    FDatabase: TTechStoreDatabase;
    FServices: TTechStoreServices;
    FInitialized: Boolean;
    function ErrorResponse(const AId, ACode, AMessage: string): string;
    function HandleInitialize(const AId: string): string;
    function HandleToolsList(const AId: string): string;
    function HandleToolsCall(const AId: string; const AParamsJson: string): string;
    function ToolResult(const AId: string; const AData: TJSONValue): string;
    function HandleResourcesList(const AId: string): string;
    function HandleResourcesRead(const AId, AParamsJson: string): string;
    function HandlePromptsList(const AId: string): string;
    function HandlePromptsGet(const AId, AParamsJson: string): string;
  public
    constructor Create(ADatabase: TTechStoreDatabase);
    destructor Destroy; override;
    function ProcessLine(const ALine: string): string;
  end;

implementation

uses
  System.SysUtils;

constructor TTechStoreMcpServer.Create(ADatabase: TTechStoreDatabase);
begin
  inherited Create;
  FDatabase := ADatabase;
  FServices := TTechStoreServices.Create(FDatabase);
end;

destructor TTechStoreMcpServer.Destroy;
begin
  FServices.Free;
  inherited Destroy;
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
    '"capabilities":{"tools":{},"resources":{},"prompts":{}}}}', [AId]);
end;

function TTechStoreMcpServer.HandleToolsList(const AId: string): string;
begin
  Result := Format(
    '{"jsonrpc":"2.0","id":%s,"result":{"tools":[' +
    '{"name":"consultar_cliente","description":"Retorna o cliente pelo identificador.",' +
    '"inputSchema":{"type":"object","properties":{"id":{"type":"integer"}},' +
    '"required":["id"],"additionalProperties":false}},' +
    '{"name":"consultar_produto","description":"Retorna o produto pelo identificador.",' +
    '"inputSchema":{"type":"object","properties":{"id":{"type":"integer"}},' +
    '"required":["id"],"additionalProperties":false}},' +
    '{"name":"criar_orcamento","description":"Prepara uma cotação que exige aprovação humana.",' +
    '"inputSchema":{"type":"object","properties":{' +
    '"customerId":{"type":"integer"},"productId":{"type":"integer"},' +
    '"quantity":{"type":"integer"}},"required":["customerId","productId","quantity"],' +
    '"additionalProperties":false}},' +
    '{"name":"consultar_estoque_baixo",' +
    '"description":"Retorna produtos cujo saldo está abaixo do estoque mínimo.",' +
    '"inputSchema":{"type":"object","additionalProperties":false}}]}}', [AId]);
end;

function TTechStoreMcpServer.ToolResult(const AId: string;
  const AData: TJSONValue): string;
begin
  Result := Format(
    '{"jsonrpc":"2.0","id":%s,"result":{"content":[{' +
    '"type":"text","text":%s}],"isError":false}}',
    [AId, TJSONString.Create(AData.ToJSON).ToJSON]);
end;

function TTechStoreMcpServer.HandleResourcesList(const AId: string): string;
begin
  Result := Format(
    '{"jsonrpc":"2.0","id":%s,"result":{"resources":[' +
    '{"uri":"techstore://policies/operation-classification",' +
    '"name":"Classificação de operações",' +
    '"description":"Política didática para leitura, preparação e ação crítica.",' +
    '"mimeType":"text/markdown"}]}}', [AId]);
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
    Result := Format(
      '{"jsonrpc":"2.0","id":%s,"result":{"contents":[' +
      '{"uri":"techstore://policies/operation-classification",' +
      '"mimeType":"text/markdown","text":%s}]}}',
      [AId, TJSONString.Create(Text).ToJSON]);
  finally
    Params.Free;
  end;
end;

function TTechStoreMcpServer.HandlePromptsList(const AId: string): string;
begin
  Result := Format(
    '{"jsonrpc":"2.0","id":%s,"result":{"prompts":[' +
    '{"name":"analisar_estoque_baixo",' +
    '"description":"Orienta a análise dos produtos abaixo do estoque mínimo.",' +
    '"arguments":[{"name":"objetivo","description":"Finalidade da análise",' +
    '"required":false}]}]}}', [AId]);
end;

function TTechStoreMcpServer.HandlePromptsGet(const AId,
  AParamsJson: string): string;
var
  Params: TJSONObject;
  NameValue: TJSONValue;
begin
  Params := TJSONObject.ParseJSONValue(AParamsJson) as TJSONObject;
  try
    if Params = nil then
      Exit(ErrorResponse(AId, '-32602', 'Os parâmetros devem ser um objeto JSON.'));
    NameValue := Params.GetValue('name');
    if (NameValue = nil) or not SameText(NameValue.Value,
      'analisar_estoque_baixo') then
      Exit(ErrorResponse(AId, '-32602', 'Prompt não encontrado.'));
    Result := Format(
      '{"jsonrpc":"2.0","id":%s,"result":{' +
      '"description":"Análise didática de estoque baixo.","messages":[' +
      '{"role":"user","content":{"type":"text","text":' +
      '"Consulte consultar_estoque_baixo. Explique os itens encontrados, ' +
      'priorize o maior desvio em relação ao mínimo e não execute ações externas."}}]}}',
      [AId]);
  finally
    Params.Free;
  end;
end;

function TTechStoreMcpServer.HandleToolsCall(const AId: string;
  const AParamsJson: string): string;
var
  Params: TJSONObject;
  NameValue: TJSONValue;
  ArgumentsValue: TJSONValue;
  IdValue: TJSONValue;
  Data: TJSONArray;
  ObjectData: TJSONObject;
  Content: string;
begin
  Params := TJSONObject.ParseJSONValue(AParamsJson) as TJSONObject;
  try
    if Params = nil then
      Exit(ErrorResponse(AId, '-32602', 'Os parâmetros devem ser um objeto JSON.'));
    NameValue := Params.GetValue('name');
    if NameValue = nil then
      Exit(ErrorResponse(AId, '-32601', 'Ferramenta não encontrada.'));

    if SameText(NameValue.Value, 'consultar_cliente') or
       SameText(NameValue.Value, 'consultar_produto') or
       SameText(NameValue.Value, 'criar_orcamento') then
    begin
      ArgumentsValue := Params.GetValue('arguments');
      if not (ArgumentsValue is TJSONObject) then
        Exit(ErrorResponse(AId, '-32602', 'Arguments deve ser um objeto JSON.'));
      if SameText(NameValue.Value, 'criar_orcamento') then
      begin
        IdValue := TJSONObject(ArgumentsValue).GetValue('customerId');
        if (IdValue = nil) or not (IdValue is TJSONNumber) then
          Exit(ErrorResponse(AId, '-32602', 'Arguments.customerId deve ser inteiro.'));
        ObjectData := FServices.PrepareQuote(TJSONNumber(IdValue).AsInt,
          TJSONNumber(TJSONObject(ArgumentsValue).GetValue('productId')).AsInt,
          TJSONNumber(TJSONObject(ArgumentsValue).GetValue('quantity')).AsInt);
      end
      else
      begin
        IdValue := TJSONObject(ArgumentsValue).GetValue('id');
        if (IdValue = nil) or not (IdValue is TJSONNumber) then
          Exit(ErrorResponse(AId, '-32602', 'Arguments.id deve ser inteiro.'));
        if SameText(NameValue.Value, 'consultar_cliente') then
          ObjectData := FServices.ConsultCustomer(TJSONNumber(IdValue).AsInt)
        else
          ObjectData := FServices.ConsultProduct(TJSONNumber(IdValue).AsInt);
      end;
      try
        Exit(ToolResult(AId, ObjectData));
      finally
        ObjectData.Free;
      end;
    end;

    if not SameText(NameValue.Value, 'consultar_estoque_baixo') then
      Exit(ErrorResponse(AId, '-32601', 'Ferramenta não encontrada.'));

    Data := FServices.ConsultLowStock;
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
    if SameText(MethodValue.Value, 'resources/list') then
      Exit(HandleResourcesList(Id));
    if SameText(MethodValue.Value, 'resources/read') then
    begin
      ParamsValue := Request.GetValue('params');
      if ParamsValue = nil then
        Exit(ErrorResponse(Id, '-32602', 'Parâmetros ausentes.'));
      Exit(HandleResourcesRead(Id, ParamsValue.ToJSON));
    end;
    if SameText(MethodValue.Value, 'prompts/list') then
      Exit(HandlePromptsList(Id));
    if SameText(MethodValue.Value, 'prompts/get') then
    begin
      ParamsValue := Request.GetValue('params');
      if ParamsValue = nil then
        Exit(ErrorResponse(Id, '-32602', 'Parâmetros ausentes.'));
      Exit(HandlePromptsGet(Id, ParamsValue.ToJSON));
    end;
    Result := ErrorResponse(Id, '-32601', 'Método não suportado.');
  finally
    Request.Free;
  end;
end;

end.
