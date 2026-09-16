program ErpMcpStarterProcessTests;

{$APPTYPE CONSOLE}

uses System.SysUtils, System.Classes, System.JSON, Winapi.Windows;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then raise Exception.Create(AMessage);
end;

procedure SendUtf8(AHandle: THandle; const AText: string);
var Buffer: TBytes; Sent, Count: DWORD;
begin
  Buffer := TEncoding.UTF8.GetBytes(AText); Sent := 0;
  while Sent < DWORD(Length(Buffer)) do
  begin
    Check(WriteFile(AHandle, Buffer[Sent], DWORD(Length(Buffer))-Sent, Count, nil), 'stdin');
    Check(Count > 0, 'escrita incompleta'); Inc(Sent, Count);
  end;
end;

function ReadUtf8(AHandle: THandle): string;
var Stream: TMemoryStream; Buffer: array[0..4095] of Byte; Count: DWORD; Bytes: TBytes;
begin
  Stream := TMemoryStream.Create;
  try
    while ReadFile(AHandle, Buffer, SizeOf(Buffer), Count, nil) and (Count > 0) do
      Stream.WriteBuffer(Buffer, Count);
    SetLength(Bytes, Stream.Size); Stream.Position := 0;
    if Length(Bytes) > 0 then Stream.ReadBuffer(Bytes[0], Length(Bytes));
    Result := TEncoding.UTF8.GetString(Bytes);
  finally Stream.Free end;
end;

procedure Run;
var
  InRead, InWrite, OutRead, OutWrite, ErrRead, ErrWrite: THandle;
  Security: TSecurityAttributes; Startup: TStartupInfo; ProcessInfo: TProcessInformation;
  Executable, CommandLine, Output, Diagnostics, Meta: string;
  Json: TJSONValue;
begin
  Executable := ExpandFileName('..\src\ErpMcpStarter.exe');
  Check(FileExists(Executable), 'Compile o servidor antes do teste de processo.');
  FillChar(Security, SizeOf(Security), 0); Security.nLength := SizeOf(Security); Security.bInheritHandle := True;
  Check(CreatePipe(InRead, InWrite, @Security, 0), 'pipe stdin');
  Check(CreatePipe(OutRead, OutWrite, @Security, 0), 'pipe stdout');
  Check(CreatePipe(ErrRead, ErrWrite, @Security, 0), 'pipe stderr');
  SetHandleInformation(InWrite, HANDLE_FLAG_INHERIT, 0);
  SetHandleInformation(OutRead, HANDLE_FLAG_INHERIT, 0);
  SetHandleInformation(ErrRead, HANDLE_FLAG_INHERIT, 0);
  FillChar(Startup, SizeOf(Startup), 0); Startup.cb := SizeOf(Startup);
  Startup.dwFlags := STARTF_USESTDHANDLES; Startup.hStdInput := InRead;
  Startup.hStdOutput := OutWrite; Startup.hStdError := ErrWrite;
  FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);
  CommandLine := '"' + Executable + '"';
  Check(CreateProcess(nil, PChar(CommandLine), nil, nil, True, CREATE_NO_WINDOW,
    nil, nil, Startup, ProcessInfo), 'iniciar servidor');
  CloseHandle(InRead); CloseHandle(OutWrite); CloseHandle(ErrWrite);
  try
    Meta := '"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28",' +
      '"io.modelcontextprotocol/clientCapabilities":{}}';
    SendUtf8(InWrite, '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{' +
      Meta + ',"name":"consultar_produto","arguments":{"id":1}}}' + #10);
    CloseHandle(InWrite);
    Check(WaitForSingleObject(ProcessInfo.hProcess, 5000) = WAIT_OBJECT_0, 'encerramento');
    Output := ReadUtf8(OutRead); Diagnostics := ReadUtf8(ErrRead);
    Check(Diagnostics = '', 'stderr deveria estar vazio: ' + Diagnostics);
    Json := TJSONObject.ParseJSONValue(Output.Trim);
    try Check(Json is TJSONObject, 'stdout deveria conter uma linha JSON') finally Json.Free end;
    Check(Output.Contains('Produto de demonstra\u00E7\u00E3o'), 'UTF-8 corrompido');
    Check(Output.Contains('"structuredContent"'), 'resultado MCP ausente');
  finally
    CloseHandle(OutRead); CloseHandle(ErrRead);
    CloseHandle(ProcessInfo.hThread); CloseHandle(ProcessInfo.hProcess);
  end;
end;

begin
  try Run; Writeln('Teste de processo e UTF-8 aprovado.')
  except on E: Exception do begin Writeln(E.ClassName + ': ' + E.Message); ExitCode := 1 end end;
end.
