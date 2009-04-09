unit X2UtProcess;

interface
uses
  Classes,
  Windows;

type
  TProcess = class(TObject)
  private
    FEnvironment:       TStrings;
    FCommandLine:       String;
    FVisible:           Boolean;
    FWorkingPath:       String;
  protected
    function BuildEnvironment(): String;
  public
    constructor Create();
    destructor Destroy(); override;

    function Execute(const AStream: TStream; out AExitCode: Cardinal): Boolean; overload;
    function Execute(const AStream: TStream): Boolean; overload;

    function Execute(out AExitCode: Cardinal): String; overload;
    function Execute(): String; overload;

    property CommandLine:   String    read FCommandLine write FCommandLine;
    property Environment:   TStrings  read FEnvironment;
    property Visible:       Boolean   read FVisible     write FVisible;
    property WorkingPath:   String    read FWorkingPath write FWorkingPath;
  end;


implementation
uses
  SysUtils;


{ TProcess }
constructor TProcess.Create();
begin
  inherited;

  FEnvironment  := TStringList.Create();
  FVisible      := False;
  FWorkingPath  := GetCurrentDir();
end;

destructor TProcess.Destroy();
begin
  FreeAndNil(FEnvironment);

  inherited;
end;


function TProcess.BuildEnvironment(): String;
var
  charPos: Integer;
  resultLength: Integer;
  value: String;
  valueIndex: Integer;

begin
  if FEnvironment.Count = 0 then
  begin
    Result := '';
    exit;
  end;

  resultLength := 1;
  for valueIndex := 0 to Pred(FEnvironment.Count) do
    Inc(resultLength, Length(FEnvironment[valueIndex]));

  Result  := StringOfChar(#0, resultLength);
  charPos := 1;

  for valueIndex := 0 to Pred(FEnvironment.Count) do
  begin
    value := FEnvironment[valueIndex];

    if Length(value) > 0 then
      Move(value[1], Result[charPos], Length(value));

    Inc(charPos, Succ(Length(value)));
  end;
end;


function TProcess.Execute(const AStream: TStream;
                          out AExitCode: Cardinal): Boolean;
  function NilString(const AValue: String): PChar;
  begin
    Result := nil;
    if Length(AValue) > 0 then
      Result := PChar(AValue);
  end;

const
  BufferSize  = 2048;

var
  buffer: PChar;
  processInfo: TProcessInformation;
  readPipe: Cardinal;
  securityAttr: TSecurityAttributes;
  startupInfo: TStartupInfo;
  writePipe: Cardinal;
  bytesRead: Cardinal;
  newConsole: Boolean;
  consoleOutput: THandle;
  bytesWritten: Cardinal;

begin
  Result := False;

  FillChar(processInfo, SizeOf(TProcessInformation), #0);
  FillChar(startupInfo, SizeOf(TStartupInfo), #0);
  FillChar(securityAttr, SizeOf(TSecurityAttributes), #0);

  securityAttr.nLength              := SizeOf(TSecurityAttributes);
  securityAttr.lpSecurityDescriptor := nil;
  securityAttr.bInheritHandle       := True;

  if CreatePipe(readPipe, writePipe, @securityAttr, 0) then
  try
    SetHandleInformation(readPipe, HANDLE_FLAG_INHERIT, HANDLE_FLAG_INHERIT);

    startupInfo.cb          := SizeOf(TStartupInfo);
    startupInfo.dwFlags     := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    startupInfo.wShowWindow := SW_HIDE;
    startupInfo.hStdOutput  := writePipe;
    startupInfo.hStdError   := writePipe;

    if CreateProcess(nil, NilString(FCommandLine), nil, nil, True, 0,
                     NilString(BuildEnvironment()), NilString(FWorkingPath),
                     startupInfo, processInfo) then
    begin
      CloseHandle(writePipe);
      writePipe  := 0;

      newConsole := False;
      consoleOutput := 0;
      if Visible then
      begin
        newConsole := AllocConsole;
        consoleOutput := GetStdHandle(STD_OUTPUT_HANDLE);
      end;

      try
        GetMem(buffer, BufferSize);
        try
          repeat
            ReadFile(readPipe, buffer^, BufferSize, bytesRead, nil);
            if bytesRead > 0 then
            begin
              AStream.WriteBuffer(buffer^, bytesRead);

              if consoleOutput <> 0 then
                WriteFile(consoleOutput, buffer^, bytesRead, bytesWritten, nil);
            end;
          until bytesRead = 0;
        finally
          FreeMem(buffer, BufferSize);
        end;
      finally
        if newConsole then
          FreeConsole;
      end;

      GetExitCodeProcess(processInfo.hProcess, AExitCode);
      Result := True;
    end else
      RaiseLastOSError();
  finally
    CloseHandle(readPipe);
    if writePipe <> 0 then
      CloseHandle(writePipe);
  end;
end;

function TProcess.Execute(const AStream: TStream): Boolean;
var
  exitCode: Cardinal;

begin
  Result := Execute(AStream, exitCode);
end;


function TProcess.Execute(out AExitCode: Cardinal): String;
var
  resultStream: TStringStream;

begin
  Result        := '';
  resultStream  := TStringStream.Create('');
  try
    if Execute(resultStream, AExitCode) then
      Result    := resultStream.DataString;
  finally
    FreeAndNil(resultStream);
  end;
end;

function TProcess.Execute(): String;
var
  exitCode: Cardinal;

begin
  Result := Execute(exitCode);
end;

end.
