program TechStoreERP;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TechStore.Data in 'TechStore.Data.pas';

var
  Database: TTechStoreDatabase;
begin
  try
    Database := TTechStoreDatabase.Create;
    try
      Database.Initialize;
      Writeln('TechStore ERP pronto. Banco: ' + Database.DatabaseFileName);
    finally
      Database.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
