unit Apollo_DPM_Pipes;

interface

function RunCommandPrompt(const aCommandLine: string): string;

implementation

uses
  Winapi.Windows;

function RunCommandPrompt(const aCommandLine: string): string;
var
  Buffer: array[0..255] of AnsiChar;
  BytesRead: Cardinal;
  Handle: Boolean;
  ProcessInformation: TProcessInformation;
  SecurityAttributes: TSecurityAttributes;
  StartupInfo: TStartupInfo;
  StdOutPipeRead: THandle;
  StdOutPipeWrite: THandle;
  WasOK: Boolean;
begin
  Result := '';

  SecurityAttributes.nLength := SizeOf(SecurityAttributes);
  SecurityAttributes.bInheritHandle := True;
  SecurityAttributes.lpSecurityDescriptor := nil;

  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SecurityAttributes, 0);
  try
    FillChar(StartupInfo, SizeOf(StartupInfo), 0);
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    StartupInfo.wShowWindow := SW_HIDE;
    StartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE); // don't redirect stdin
    StartupInfo.hStdOutput := StdOutPipeWrite;
    StartupInfo.hStdError := StdOutPipeWrite;

    Handle := CreateProcess(nil, PChar('cmd.exe /C ' + aCommandLine),
                            nil, nil, True, 0, nil,
                            nil, StartupInfo, ProcessInformation);
    CloseHandle(StdOutPipeWrite);
    if Handle then
      try
        repeat
          WasOK := ReadFile(StdOutPipeRead, Buffer, 255, BytesRead, nil);
          if BytesRead > 0 then
          begin
            Buffer[BytesRead] := #0;
            Result := Result + string(Buffer);
          end;
        until not WasOK or (BytesRead = 0);
        WaitForSingleObject(ProcessInformation.hProcess, INFINITE);
      finally
        CloseHandle(ProcessInformation.hThread);
        CloseHandle(ProcessInformation.hProcess);
      end;
  finally
    CloseHandle(StdOutPipeRead);
  end;
end;

end.
