unit Starter.ProductForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Starter.Contracts;

type
  TProductForm = class(TForm)
    ProductIdEdit: TEdit;
    SearchButton: TButton;
    StockLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SearchButtonClick(Sender: TObject);
  private
    FProductService: IProductQueryService;
  end;

var
  ProductForm: TProductForm;

implementation

uses Starter.ExampleProductService;

{$R *.dfm}

procedure TProductForm.FormCreate(Sender: TObject);
begin
  // PONTO DE ADAPTAÇÃO: injete aqui a implementação ligada ao ERP real.
  FProductService := TExampleProductService.Create;
end;

procedure TProductForm.FormDestroy(Sender: TObject);
begin
  FProductService := nil;
end;

procedure TProductForm.SearchButtonClick(Sender: TObject);
var
  ProductId: Integer;
  Product: TProductInfo;
begin
  if not TryStrToInt(ProductIdEdit.Text, ProductId) or (ProductId <= 0) then
  begin
    StockLabel.Caption := 'Informe um identificador inteiro positivo.';
    Exit;
  end;
  if not FProductService.FindById(ProductId, Product) then
    StockLabel.Caption := 'Produto não encontrado.'
  else
    StockLabel.Caption := Format('%s — saldo: %g',
      [Product.Name, Product.StockQuantity]);
end;

end.
