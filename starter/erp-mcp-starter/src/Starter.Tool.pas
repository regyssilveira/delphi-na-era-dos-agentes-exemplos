unit Starter.Tool;

interface

uses Starter.Contracts;

type
  TProductTool = class
  private
    FService: IProductQueryService;
  public
    constructor Create(const AService: IProductQueryService);
    function Execute(AProductId: Integer): string;
  end;

implementation

uses System.JSON, System.SysUtils;

constructor TProductTool.Create(const AService: IProductQueryService);
begin
  inherited Create;
  if not Assigned(AService) then
    raise EArgumentNilException.Create('AService');
  FService := AService;
end;

function TProductTool.Execute(AProductId: Integer): string;
var
  Product: TProductInfo;
  Json: TJSONObject;
begin
  Json := TJSONObject.Create;
  try
    if not FService.FindById(AProductId, Product) then
    begin
      Json.AddPair('ok', TJSONBool.Create(False));
      Json.AddPair('error', 'product_not_found');
    end
    else
    begin
      Json.AddPair('ok', TJSONBool.Create(True));
      Json.AddPair('id', TJSONNumber.Create(Product.Id));
      Json.AddPair('name', Product.Name);
      Json.AddPair('stockQuantity', TJSONNumber.Create(Product.StockQuantity));
    end;
    Result := Json.ToJSON;
  finally
    Json.Free;
  end;
end;

end.
