unit TechStore.Mcp.LocalClient;

interface

uses
  TechStore.Mcp;

type
  { Cliente didático em memória. Ele modela as mensagens MCP sem implementar pipes. }
  TTechStoreMcpLocalClient = class
  private
    FServer: TTechStoreMcpServer;
    FNextId: Integer;
    function Request(const AMethod, AParamsJson: string): string;
    procedure Notify(const AMethod, AParamsJson: string);
  public
    constructor Create(AServer: TTechStoreMcpServer);
    procedure Initialize;
    function ListTools: string;
    function ListResources: string;
    function GetPrompt(const AName: string): string;
  end;

implementation

uses
  System.SysUtils;

constructor TTechStoreMcpLocalClient.Create(AServer: TTechStoreMcpServer);
begin
  inherited Create;
  FServer := AServer;
  FNextId := 1;
end;

function TTechStoreMcpLocalClient.Request(const AMethod, AParamsJson: string): string;
begin
  Result := FServer.ProcessLine(Format(
    '{"jsonrpc":"2.0","id":%d,"method":"%s","params":%s}',
    [FNextId, AMethod, AParamsJson]));
  Inc(FNextId);
end;

procedure TTechStoreMcpLocalClient.Notify(const AMethod, AParamsJson: string);
begin
  FServer.ProcessLine(Format(
    '{"jsonrpc":"2.0","method":"%s","params":%s}',
    [AMethod, AParamsJson]));
end;

procedure TTechStoreMcpLocalClient.Initialize;
begin
  Request('initialize', '{}');
  Notify('notifications/initialized', '{}');
end;

function TTechStoreMcpLocalClient.ListTools: string;
begin
  Result := Request('tools/list', '{}');
end;

function TTechStoreMcpLocalClient.ListResources: string;
begin
  Result := Request('resources/list', '{}');
end;

function TTechStoreMcpLocalClient.GetPrompt(const AName: string): string;
begin
  Result := Request('prompts/get',
    Format('{"name":"%s"}', [AName]));
end;

end.
