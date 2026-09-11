unit TechStore.Data;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.DApt,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite;

type
  TTechStoreDatabase = class
  private
    FConnection: TFDConnection;
    FSQLiteDriver: TFDPhysSQLiteDriverLink;
    FDatabaseFileName: string;
    procedure CreateSchema;
    procedure SeedData;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Initialize;
    function ListLowStock: TJSONArray;
    function FindCustomerById(const AId: Integer): TJSONObject;
    function FindProductById(const AId: Integer): TJSONObject;
    function CreateQuoteDraft(const ACustomerId, AProductId, AQuantity: Integer): Integer;
    property DatabaseFileName: string read FDatabaseFileName;
  end;

implementation

constructor TTechStoreDatabase.Create;
begin
  inherited Create;
  FDatabaseFileName := TPath.Combine(TPath.GetDocumentsPath, 'TechStoreERP\techstore.db');
  ForceDirectories(ExtractFilePath(FDatabaseFileName));

  FSQLiteDriver := TFDPhysSQLiteDriverLink.Create(nil);
  FConnection := TFDConnection.Create(nil);
  FConnection.LoginPrompt := False;
  FConnection.DriverName := 'SQLite';
  FConnection.Params.Values['Database'] := FDatabaseFileName;
end;

function TTechStoreDatabase.CreateQuoteDraft(const ACustomerId, AProductId,
  AQuantity: Integer): Integer;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text :=
      'INSERT INTO quote_drafts (customer_id, product_id, quantity, status) ' +
      'VALUES (:customer_id, :product_id, :quantity, ''PREPARADO'')';
    Query.ParamByName('customer_id').AsInteger := ACustomerId;
    Query.ParamByName('product_id').AsInteger := AProductId;
    Query.ParamByName('quantity').AsInteger := AQuantity;
    Query.ExecSQL;
    Query.SQL.Text := 'SELECT last_insert_rowid() AS id';
    Query.Open;
    Result := Query.FieldByName('id').AsInteger;
  finally
    Query.Free;
  end;
end;

function TTechStoreDatabase.FindCustomerById(const AId: Integer): TJSONObject;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text :=
      'SELECT id, name, credit_limit FROM customers WHERE id = :id';
    Query.ParamByName('id').AsInteger := AId;
    Query.Open;
    if not Query.IsEmpty then
    begin
      Result := TJSONObject.Create;
      Result.AddPair('id', TJSONNumber.Create(Query.FieldByName('id').AsInteger));
      Result.AddPair('name', Query.FieldByName('name').AsString);
      Result.AddPair('creditLimit',
        TJSONNumber.Create(Query.FieldByName('credit_limit').AsFloat));
    end;
  finally
    Query.Free;
  end;
end;

function TTechStoreDatabase.FindProductById(const AId: Integer): TJSONObject;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text :=
      'SELECT id, name, stock_quantity, minimum_stock FROM products WHERE id = :id';
    Query.ParamByName('id').AsInteger := AId;
    Query.Open;
    if not Query.IsEmpty then
    begin
      Result := TJSONObject.Create;
      Result.AddPair('id', TJSONNumber.Create(Query.FieldByName('id').AsInteger));
      Result.AddPair('name', Query.FieldByName('name').AsString);
      Result.AddPair('stockQuantity',
        TJSONNumber.Create(Query.FieldByName('stock_quantity').AsFloat));
      Result.AddPair('minimumStock',
        TJSONNumber.Create(Query.FieldByName('minimum_stock').AsFloat));
    end;
  finally
    Query.Free;
  end;
end;

destructor TTechStoreDatabase.Destroy;
begin
  FConnection.Free;
  FSQLiteDriver.Free;
  inherited Destroy;
end;

procedure TTechStoreDatabase.Initialize;
begin
  FConnection.Connected := True;
  CreateSchema;
  SeedData;
end;

procedure TTechStoreDatabase.CreateSchema;
begin
  FConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS customers (' +
    '  id INTEGER PRIMARY KEY, ' +
    '  name TEXT NOT NULL, ' +
    '  credit_limit NUMERIC NOT NULL DEFAULT 0' +
    ')');

  FConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS products (' +
    '  id INTEGER PRIMARY KEY, ' +
    '  name TEXT NOT NULL, ' +
    '  stock_quantity NUMERIC NOT NULL DEFAULT 0, ' +
    '  minimum_stock NUMERIC NOT NULL DEFAULT 0' +
    ')');

  FConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS invoices (' +
    '  id INTEGER PRIMARY KEY, ' +
    '  customer_id INTEGER NOT NULL, ' +
    '  issued_at TEXT NOT NULL, ' +
    '  total_amount NUMERIC NOT NULL, ' +
    '  FOREIGN KEY(customer_id) REFERENCES customers(id)' +
    ')');

  FConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS quote_drafts (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    '  customer_id INTEGER NOT NULL, ' +
    '  product_id INTEGER NOT NULL, ' +
    '  quantity INTEGER NOT NULL, ' +
    '  status TEXT NOT NULL, ' +
    '  FOREIGN KEY(customer_id) REFERENCES customers(id), ' +
    '  FOREIGN KEY(product_id) REFERENCES products(id)' +
    ')');
end;

procedure TTechStoreDatabase.SeedData;
begin
  FConnection.ExecSQL(
    'INSERT OR IGNORE INTO customers (id, name, credit_limit) VALUES ' +
    '(1, ''Ana Martins'', 15000), ' +
    '(2, ''Mercado Horizonte'', 30000)');

  FConnection.ExecSQL(
    'INSERT OR IGNORE INTO products (id, name, stock_quantity, minimum_stock) VALUES ' +
    '(1, ''Notebook Atlas 14'', 2, 5), ' +
    '(2, ''Mouse Orbital'', 3, 10), ' +
    '(3, ''SSD Aurora 1 TB'', 1, 8)');

  FConnection.ExecSQL(
    'INSERT OR IGNORE INTO invoices (id, customer_id, issued_at, total_amount) VALUES ' +
    '(1, 1, ''2026-09-01'', 8450.00), ' +
    '(2, 2, ''2026-09-05'', 18342.57)');
end;

function TTechStoreDatabase.ListLowStock: TJSONArray;
var
  Query: TFDQuery;
  Product: TJSONObject;
begin
  Result := TJSONArray.Create;
  try
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := FConnection;
      Query.SQL.Text :=
        'SELECT id, name, stock_quantity, minimum_stock ' +
        'FROM products ' +
        'WHERE stock_quantity < minimum_stock ' +
        'ORDER BY name';
      Query.Open;
      while not Query.Eof do
      begin
        Product := TJSONObject.Create;
        Product.AddPair('id', TJSONNumber.Create(Query.FieldByName('id').AsInteger));
        Product.AddPair('name', Query.FieldByName('name').AsString);
        Product.AddPair('stockQuantity',
          TJSONNumber.Create(Query.FieldByName('stock_quantity').AsFloat));
        Product.AddPair('minimumStock',
          TJSONNumber.Create(Query.FieldByName('minimum_stock').AsFloat));
        Result.AddElement(Product);
        Query.Next;
      end;
    finally
      Query.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
