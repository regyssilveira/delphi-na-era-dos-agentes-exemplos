unit TechStore.Services;

interface

uses
  System.SysUtils,
  System.JSON,
  TechStore.Data;

type
  ETechStoreBusinessRule = class(Exception);

  TTechStoreServices = class
  private
    FDatabase: TTechStoreDatabase;
    procedure RequirePositiveId(const AId: Integer; const AEntityName: string);
  public
    constructor Create(ADatabase: TTechStoreDatabase);
    function ConsultCustomer(const AId: Integer): TJSONObject;
    function ConsultProduct(const AId: Integer): TJSONObject;
    function ConsultLowStock: TJSONArray;
    function PrepareQuote(const ACustomerId, AProductId, AQuantity: Integer): TJSONObject;
  end;

implementation

constructor TTechStoreServices.Create(ADatabase: TTechStoreDatabase);
begin
  inherited Create;
  FDatabase := ADatabase;
end;

function TTechStoreServices.PrepareQuote(const ACustomerId, AProductId,
  AQuantity: Integer): TJSONObject;
var
  Customer: TJSONObject;
  Product: TJSONObject;
  QuoteId: Integer;
begin
  RequirePositiveId(ACustomerId, 'Cliente');
  RequirePositiveId(AProductId, 'Produto');
  if AQuantity <= 0 then
    raise ETechStoreBusinessRule.Create('Quantidade deve ser positiva.');
  Customer := ConsultCustomer(ACustomerId);
  try
    Product := ConsultProduct(AProductId);
    try
      QuoteId := FDatabase.CreateQuoteDraft(ACustomerId, AProductId, AQuantity);
      Result := TJSONObject.Create;
      Result.AddPair('quoteId', TJSONNumber.Create(QuoteId));
      Result.AddPair('status', 'PREPARADO');
      Result.AddPair('customerName', Customer.GetValue('name').Value);
      Result.AddPair('productName', Product.GetValue('name').Value);
      Result.AddPair('quantity', TJSONNumber.Create(AQuantity));
      Result.AddPair('requiresHumanApproval', TJSONTrue.Create);
    finally
      Product.Free;
    end;
  finally
    Customer.Free;
  end;
end;

procedure TTechStoreServices.RequirePositiveId(const AId: Integer;
  const AEntityName: string);
begin
  if AId <= 0 then
    raise ETechStoreBusinessRule.Create(AEntityName + ' deve ter identificador positivo.');
end;

function TTechStoreServices.ConsultCustomer(const AId: Integer): TJSONObject;
begin
  RequirePositiveId(AId, 'Cliente');
  Result := FDatabase.FindCustomerById(AId);
  if Result = nil then
    raise ETechStoreBusinessRule.Create('Cliente não encontrado.');
end;

function TTechStoreServices.ConsultProduct(const AId: Integer): TJSONObject;
begin
  RequirePositiveId(AId, 'Produto');
  Result := FDatabase.FindProductById(AId);
  if Result = nil then
    raise ETechStoreBusinessRule.Create('Produto não encontrado.');
end;

function TTechStoreServices.ConsultLowStock: TJSONArray;
begin
  Result := FDatabase.ListLowStock;
end;

end.
