unit TechStore.Data;

interface

uses
  System.SysUtils,
  System.IOUtils,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
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

end.
