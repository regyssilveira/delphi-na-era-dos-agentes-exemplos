program TechStoreMcpProcessTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  Winapi.Windows;

procedure Require(const ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure SendUtf8(const AHandle: THandle; const AText: string);
var
  Buffer: TBytes;
  Sent, Count: DWORD;
begin
  Buffer := TEncoding.UTF8.GetBytes(AText);
  Sent := 0;
  while Sent < DWORD(Length(Buffer)) do
  begin
    Require(WriteFile(AHandle, Buffer[Sent], DWORD(Length(Buffer)) - Sent,
      Count, nil), 'Falha ao escrever no stdin do servidor.');
    Require(Count > 0, 'Escrita incompleta no stdin do servidor.');
    Inc(Sent, Count);
  end;
end;

function ReadUtf8(const AHandle: THandle): string;
var
  Stream: TMemoryStream;
  Buffer: array[0..4095] of Byte;
  Count: DWORD;
  Bytes: TBytes;
begin
  Stream := TMemoryStream.Create;
  try
    while ReadFile(AHandle, Buffer, SizeOf(Buffer), Count, nil) and (Count > 0) do
      Stream.WriteBuffer(Buffer, Count);
    SetLength(Bytes, Stream.Size);
    Stream.Position := 0;
    if Length(Bytes) > 0 then
      Stream.ReadBuffer(Bytes[0], Length(Bytes));
    Result := TEncoding.UTF8.GetString(Bytes);
  finally
    Stream.Free;
  end;
end;

function Meta: string;
begin
  Result := '"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28",' +
    '"io.modelcontextprotocol/clientCapabilities":{}}';
end;

procedure Run;
var
  StdInRead, StdInWrite, StdOutRead, StdOutWrite: THandle;
  StdErrRead, StdErrWrite: THandle;
  Security: TSecurityAttributes;
  Startup: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Executable, CommandLine, Output, Diagnostics: string;
  Lines: TArray<string>;
  Json: TJSONValue;
  Index: Integer;
  TestId: TGUID;
  DatabaseFileName, PreviousDatabasePath, PreviousActor: string;
begin
  CreateGUID(TestId);
  DatabaseFileName := TPath.Combine(TPath.GetTempPath,
    'techstore-process-' + GUIDToString(TestId) + '.db');
  PreviousDatabasePath := GetEnvironmentVariable('TECHSTORE_DB_PATH');
  PreviousActor := GetEnvironmentVariable('TECHSTORE_DEMO_ACTOR');
  Executable := ExpandFileName('..\src\TechStoreERP.exe');
  Require(FileExists(Executable), 'Compile src\TechStoreERP.dpr antes do teste.');
  FillChar(Security, SizeOf(Security), 0);
  Security.nLength := SizeOf(Security);
  Security.bInheritHandle := True;
  Require(CreatePipe(StdInRead, StdInWrite, @Security, 0), 'Pipe de stdin.');
  Require(CreatePipe(StdOutRead, StdOutWrite, @Security, 0), 'Pipe de stdout.');
  Require(CreatePipe(StdErrRead, StdErrWrite, @Security, 0), 'Pipe de stderr.');
  Require(SetHandleInformation(StdInWrite, HANDLE_FLAG_INHERIT, 0), 'stdin pai.');
  Require(SetHandleInformation(StdOutRead, HANDLE_FLAG_INHERIT, 0), 'stdout pai.');
  Require(SetHandleInformation(StdErrRead, HANDLE_FLAG_INHERIT, 0), 'stderr pai.');
  FillChar(Startup, SizeOf(Startup), 0);
  Startup.cb := SizeOf(Startup);
  Startup.dwFlags := STARTF_USESTDHANDLES;
  Startup.hStdInput := StdInRead;
  Startup.hStdOutput := StdOutWrite;
  Startup.hStdError := StdErrWrite;
  FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);
  CommandLine := '"' + Executable + '" --mcp-stdio';
  Require(SetEnvironmentVariable('TECHSTORE_DB_PATH', PChar(DatabaseFileName)),
    'Falha ao configurar banco isolado.');
  Require(SetEnvironmentVariable('TECHSTORE_DEMO_ACTOR', 'operador-demo'),
    'Falha ao configurar ator demonstrativo.');
  try
    Require(CreateProcess(nil, PChar(CommandLine), nil, nil, True,
      CREATE_NO_WINDOW, nil, nil, Startup, ProcessInfo), 'Falha ao iniciar servidor.');
  finally
    if PreviousDatabasePath = '' then
      SetEnvironmentVariable('TECHSTORE_DB_PATH', nil)
    else
      SetEnvironmentVariable('TECHSTORE_DB_PATH', PChar(PreviousDatabasePath));
    if PreviousActor = '' then
      SetEnvironmentVariable('TECHSTORE_DEMO_ACTOR', nil)
    else
      SetEnvironmentVariable('TECHSTORE_DEMO_ACTOR', PChar(PreviousActor));
  end;
  CloseHandle(StdInRead);
  CloseHandle(StdOutWrite);
  CloseHandle(StdErrWrite);
  try
    SendUtf8(StdInWrite,
      '{"jsonrpc":"2.0","id":1,"method":"resources/read","params":{' +
      Meta + ',"uri":"techstore://policies/operation-classification"}}' + #10);
    SendUtf8(StdInWrite,
      '{"jsonrpc":"2.0","id":2,"method":"prompts/get","params":{' +
      Meta + ',"name":"analisar_estoque_baixo","arguments":{' +
      '"objetivo":"reposição em São Paulo"}}}' + #10);
    SendUtf8(StdInWrite,
      '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{' +
      Meta + ',"name":"consultar_faturas_cliente","arguments":{"id":1}}}' + #10);
    CloseHandle(StdInWrite);
    Require(WaitForSingleObject(ProcessInfo.hProcess, 5000) = WAIT_OBJECT_0,
      'Servidor não encerrou após fechar stdin.');
    Output := ReadUtf8(StdOutRead);
    Diagnostics := ReadUtf8(StdErrRead);
    Require(Diagnostics = '', 'Servidor escreveu erro: ' + Diagnostics);
    Lines := Output.Trim.Split([#10]);
    Require(Length(Lines) = 3, 'Esperadas três respostas MCP em stdout.');
    for Index := 0 to High(Lines) do
    begin
      Json := TJSONObject.ParseJSONValue(Lines[Index]);
      try
        Require(Json is TJSONObject, 'Linha de stdout não é JSON.');
      finally
        Json.Free;
      end;
    end;
    Require(Output.Contains('Classifica\u00E7\u00E3o'),
      'Texto UTF-8 estático foi corrompido.');
    Require(Output.Contains('reposição em São Paulo') or
      Output.Contains('reposi\u00E7\u00E3o em S\u00E3o Paulo'),
      'Texto UTF-8 recebido pelo stdin foi corrompido.');
    Require(Output.Contains('8450'), 'Consulta de faturas não atravessou o processo.');
  finally
    CloseHandle(StdOutRead);
    CloseHandle(StdErrRead);
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(ProcessInfo.hProcess);
    if FileExists(DatabaseFileName) then
      System.SysUtils.DeleteFile(DatabaseFileName);
  end;
end;

begin
  try
    Run;
    Writeln('Teste de processo MCP e UTF-8 passou.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
