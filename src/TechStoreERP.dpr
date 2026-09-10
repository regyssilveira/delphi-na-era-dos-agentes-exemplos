program TechStoreERP;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TechStore.Data in 'TechStore.Data.pas',
  TechStore.Mcp in 'TechStore.Mcp.pas';

var
  Database: TTechStoreDatabase;
  Server: TTechStoreMcpServer;
  Line: string;
begin
  try
    Database := TTechStoreDatabase.Create;
    try
      Database.Initialize;
      if (ParamCount > 0) and SameText(ParamStr(1), '--mcp-stdio') then
      begin
        Server := TTechStoreMcpServer.Create(Database);
        try
          while not Eof(Input) do
          begin
            ReadLn(Line);
            if Line.Trim <> '' then
              Writeln(Server.ProcessLine(Line));
          end;
        finally
          Server.Free;
        end;
      end
      else
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
