program TechStoreERP;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TechStore.Data in 'TechStore.Data.pas',
  TechStore.Mcp in 'TechStore.Mcp.pas',
  TechStore.Stdio in 'TechStore.Stdio.pas';

var
  Database: TTechStoreDatabase;
  Server: TTechStoreMcpServer;
  Line: string;
  Response: string;
begin
  try
    Database := TTechStoreDatabase.Create;
    try
      Database.Initialize;
      if (ParamCount > 0) and SameText(ParamStr(1), '--mcp-stdio') then
      begin
        Server := TTechStoreMcpServer.Create(Database);
        try
          while ReadMcpLine(Line) do
          begin
            if Line.Trim <> '' then
            begin
              Response := Server.ProcessLine(Line);
              if Response <> '' then
                WriteMcpLine(Response);
            end;
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
      WriteDiagnostic(E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
