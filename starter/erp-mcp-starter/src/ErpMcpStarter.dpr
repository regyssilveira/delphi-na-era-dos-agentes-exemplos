program ErpMcpStarter;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Starter.Contracts in 'Starter.Contracts.pas',
  Starter.ExampleProductService in 'Starter.ExampleProductService.pas',
  Starter.Tool in 'Starter.Tool.pas',
  Starter.Mcp in 'Starter.Mcp.pas',
  Starter.Stdio in 'Starter.Stdio.pas';

var
  Service: IProductQueryService;
  Server: TStarterMcpServer;
  Line, Response: string;
begin
  try
    Service := TExampleProductService.Create;
    Server := TStarterMcpServer.Create(Service);
    try
      while ReadMcpLine(Line) do
        if Line.Trim <> '' then
        begin
          Response := Server.ProcessLine(Line);
          if Response <> '' then WriteMcpLine(Response);
        end;
    finally Server.Free end;
  except
    on E: Exception do begin WriteDiagnostic(E.ClassName + ': ' + E.Message); ExitCode := 1 end;
  end;
end.
