unit Starter.Contracts;

interface

type
  TProductInfo = record
    Id: Integer;
    Name: string;
    StockQuantity: Double;
    class function Create(AId: Integer; const AName: string;
      AStockQuantity: Double): TProductInfo; static;
  end;

  IProductQueryService = interface
    ['{32E41372-A4CF-452D-9AAA-6AFD83B8840B}']
    function FindById(AId: Integer; out AProduct: TProductInfo): Boolean;
  end;

implementation

class function TProductInfo.Create(AId: Integer; const AName: string;
  AStockQuantity: Double): TProductInfo;
begin
  Result.Id := AId;
  Result.Name := AName;
  Result.StockQuantity := AStockQuantity;
end;

end.
