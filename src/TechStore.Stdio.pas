unit TechStore.Stdio;

interface

function ReadMcpLine(out ALine: string): Boolean;
procedure WriteMcpLine(const ALine: string);
procedure WriteDiagnostic(const AText: string);

implementation

uses
  System.SysUtils,
  Winapi.Windows;

const
  MaxLineBytes = 1024 * 1024;

function ReadMcpLine(out ALine: string): Boolean;
var
  Handle: THandle;
  Buffer: TBytes;
  Value: Byte;
  Count: DWORD;
  Size: Integer;
begin
  Handle := GetStdHandle(STD_INPUT_HANDLE);
  if Handle = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  SetLength(Buffer, 256);
  Size := 0;
  while True do
  begin
    if not ReadFile(Handle, Value, 1, Count, nil) then
    begin
      if GetLastError = ERROR_BROKEN_PIPE then
        Count := 0
      else
        RaiseLastOSError;
    end;
    if Count = 0 then
    begin
      Result := Size > 0;
      Break;
    end;
    if Value = 10 then
    begin
      Result := True;
      Break;
    end;
    if Size >= MaxLineBytes then
      raise Exception.Create('Mensagem MCP excede 1 MiB.');
    if Size = Length(Buffer) then
      SetLength(Buffer, Length(Buffer) * 2);
    Buffer[Size] := Value;
    Inc(Size);
  end;
  if (Size > 0) and (Buffer[Size - 1] = 13) then
    Dec(Size);
  SetLength(Buffer, Size);
  ALine := TEncoding.UTF8.GetString(Buffer);
end;

procedure WriteBytes(const AHandle: THandle; const AText: string);
var
  Buffer: TBytes;
  Sent, Count: DWORD;
begin
  Buffer := TEncoding.UTF8.GetBytes(AText);
  Sent := 0;
  while Sent < DWORD(Length(Buffer)) do
  begin
    if not WriteFile(AHandle, Buffer[Sent], DWORD(Length(Buffer)) - Sent,
      Count, nil) then
      RaiseLastOSError;
    if Count = 0 then
      raise Exception.Create('Escrita incompleta no fluxo MCP.');
    Inc(Sent, Count);
  end;
end;

procedure WriteMcpLine(const ALine: string);
begin
  WriteBytes(GetStdHandle(STD_OUTPUT_HANDLE), ALine + #10);
end;

procedure WriteDiagnostic(const AText: string);
begin
  WriteBytes(GetStdHandle(STD_ERROR_HANDLE), AText + #10);
end;

end.
