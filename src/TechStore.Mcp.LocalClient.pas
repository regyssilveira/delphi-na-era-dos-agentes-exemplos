unit TechStore.Mcp.LocalClient;

interface

uses
  TechStore.Mcp;

type
  { Cliente didático em memória. Ele modela o perfil MCP moderno, sem pipes. }
  TTechStoreMcpLocalClient = class
  private
    FServer: TTechStoreMcpServer;
    FNextId: Integer;
    function Meta: string;
    function Request(const AMethod, AFields: string): string;
  public
    constructor Create(AServer: TTechStoreMcpServer);
    function Discover: string;
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

function TTechStoreMcpLocalClient.Meta: string;
begin
  Result :=
    '"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28",' +
    '"io.modelcontextprotocol/clientInfo":{"name":"techstore-local-client","version":"0.2.0"},' +
    '"io.modelcontextprotocol/clientCapabilities":{}}';
end;

function TTechStoreMcpLocalClient.Request(const AMethod, AFields: string): string;
var
  Params: string;
begin
  Params := Meta;
  if AFields <> '' then
    Params := Params + ',' + AFields;
  Result := FServer.ProcessLine(Format(
    '{"jsonrpc":"2.0","id":%d,"method":"%s","params":{%s}}',
    [FNextId, AMethod, Params]));
  Inc(FNextId);
end;

function TTechStoreMcpLocalClient.Discover: string;
begin
  Result := Request('server/discover', '');
end;

function TTechStoreMcpLocalClient.ListTools: string;
begin
  Result := Request('tools/list', '');
end;

function TTechStoreMcpLocalClient.ListResources: string;
begin
  Result := Request('resources/list', '');
end;

function TTechStoreMcpLocalClient.GetPrompt(const AName: string): string;
begin
  Result := Request('prompts/get', Format('"name":"%s"', [AName]));
end;

end.
