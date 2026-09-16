# Do evento VCL ao serviço reutilizável

O objetivo não é fazer a tool chamar o formulário. É retirar a regra do evento e criar uma fronteira que possa ser chamada tanto pela VCL quanto pelo MCP. Os blocos desta página mostram a transformação; a versão integral e compilável está em `starter/erp-mcp-starter/vcl/ErpMcpVclDemo.dpr`.

## Antes: consulta presa ao botão

```pascal
procedure TProductForm.SearchButtonClick(Sender: TObject);
begin
  ProductQuery.ParamByName('ID').AsInteger := StrToInt(ProductIdEdit.Text);
  ProductQuery.Open;
  if ProductQuery.IsEmpty then
    ShowMessage('Produto não encontrado')
  else
    StockLabel.Caption := ProductQuery.FieldByName('STOCK').AsString;
end;
```

Esse código mistura entrada visual, acesso a dados, decisão e apresentação. Um servidor MCP não deve instanciar o formulário para reutilizá-lo.

## Depois: uma fronteira compartilhada

Crie o DTO e `IProductQueryService` como em `starter/erp-mcp-starter/src/Starter.Contracts.pas`. Mova a consulta para uma implementação da interface. No ERP real, ela recebe o repositório ou data module por construtor.

```pascal
function TErpProductService.FindById(AId: Integer;
  out AProduct: TProductInfo): Boolean;
begin
  FQuery.Close;
  FQuery.ParamByName('ID').AsInteger := AId;
  FQuery.Open;
  Result := not FQuery.IsEmpty;
  if Result then
    AProduct := TProductInfo.Create(
      FQuery.FieldByName('ID').AsInteger,
      FQuery.FieldByName('NAME').AsString,
      FQuery.FieldByName('STOCK').AsFloat);
end;
```

O evento passa a cuidar apenas da tela:

```pascal
procedure TProductForm.SearchButtonClick(Sender: TObject);
var
  Product: TProductInfo;
begin
  if not FProductService.FindById(StrToInt(ProductIdEdit.Text), Product) then
    ShowMessage('Produto não encontrado')
  else
    StockLabel.Caption := Product.StockQuantity.ToString;
end;
```

A tool recebe a mesma interface e serializa o resultado. Assim, corrigir uma regra no serviço corrige os dois caminhos. A composição cria uma instância do serviço para a tela e outra por sessão/processo MCP, conforme a segurança de thread do acesso a dados.

## Execute a transformação completa

Compile `vcl/ErpMcpVclDemo.dpr`, abra a tela e consulte o identificador 1. Em seguida, compile `src/ErpMcpStarter.dpr` e execute os dois programas da pasta `tests`. A tela e o servidor não chamam um ao outro: ambos dependem de `IProductQueryService`.

No ERP real, substitua `TExampleProductService` por uma classe que receba o repositório ou data module no construtor. Se o data module não for seguro para uso concorrente, crie uma instância por processo ou requisição; não compartilhe a conexão da thread visual sem uma política explícita.

## Verificação antes de expor

- teste o serviço sem formulário;
- mantenha mensagens e códigos de erro estáveis;
- não aceite SQL, nomes de tabela ou filtros livres vindos do modelo;
- aplique autorização antes do serviço em operações sensíveis;
- registre correlação, duração e resultado sem gravar segredos;
- teste novamente o evento VCL para impedir regressão.
