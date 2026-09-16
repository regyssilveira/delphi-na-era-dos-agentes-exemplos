program ErpMcpVclDemo;

uses
  Vcl.Forms,
  Starter.Contracts in '..\src\Starter.Contracts.pas',
  Starter.ExampleProductService in '..\src\Starter.ExampleProductService.pas',
  Starter.ProductForm in 'Starter.ProductForm.pas' {ProductForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TProductForm, ProductForm);
  Application.Run;
end.
