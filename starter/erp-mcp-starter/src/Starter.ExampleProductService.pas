unit Starter.ExampleProductService;

interface

uses Starter.Contracts;

type
  TExampleProductService = class(TInterfacedObject, IProductQueryService)
  public
    function FindById(AId: Integer; out AProduct: TProductInfo): Boolean;
  end;

implementation

function TExampleProductService.FindById(AId: Integer;
  out AProduct: TProductInfo): Boolean;
begin
  // PONTO DE ADAPTAÇÃO: chame aqui a regra/repositório do ERP, nunca a tela.
  Result := AId = 1;
  if Result then
    AProduct := TProductInfo.Create(1, 'Produto de demonstração', 12);
end;

end.
