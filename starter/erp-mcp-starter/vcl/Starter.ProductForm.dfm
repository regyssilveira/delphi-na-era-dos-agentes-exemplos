object ProductForm: TProductForm
  Left = 0
  Top = 0
  Caption = 'ERP MCP Starter — VCL'
  ClientHeight = 160
  ClientWidth = 460
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  Position = poScreenCenter
  object ProductIdEdit: TEdit
    Left = 24
    Top = 24
    Width = 121
    Height = 23
    TabOrder = 0
    Text = '1'
  end
  object SearchButton: TButton
    Left = 160
    Top = 22
    Width = 113
    Height = 27
    Caption = 'Consultar'
    TabOrder = 1
    OnClick = SearchButtonClick
  end
  object StockLabel: TLabel
    Left = 24
    Top = 80
    Width = 104
    Height = 15
    Caption = 'Aguardando consulta.'
  end
end
