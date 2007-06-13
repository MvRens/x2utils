{
  :: X2UtSingleInstance provides functions to detect previous instances of an
  :: application and pass it the new command-line parameters.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtSingleInstance;

interface
uses
  Classes,
  SysUtils,
  Messages;

const
  IM_COMMANDLINE  = $00000001;
  IM_APP          = $00000100;

type
  EInstanceNotActive  = class(Exception);
  EInstanceNoAppID    = class(Exception);


  {
    :$ Notifier observer interface.

    :: Applications that want to receive notifications on new instances must
    :: implement this interface and call Attach(Instance).
  }
  IX2InstanceObserver = interface
    ['{4C435D46-6A7F-4CD7-9400-338E3E8FB5C6}']
    procedure OnInstance(const ACmdLine: String);
  end;

  {
    :$ Extended notifier observer interface.

    :: Applications that want to receive custom notifications as well must
    :: implement this interface and call Attach(Instance).
  }
  IX2InstanceObserverEx = interface(IX2InstanceObserver)
    ['{755A6548-3EA8-46C2-9FF5-FDE4BD67B699}']
    procedure OnNotify(AMessage: Integer; const AData: String);
  end;


  {
    :$ Internal file mapping layout.
  }
  PX2InstanceMapData  = ^TX2InstanceMapData;
  TX2InstanceMapData  = record
    RefCount:     Integer;
    Window:       THandle;
  end;

  {
    :$ Instance object.

    :: Manages an instance. Instances are identified by an ApplicationID, which
    :: must be unique. For simple single instance checking you can use the
    :: SingleInstance wrapper function.
  }
  TX2Instance = class(TObject)
  private
    FActive:            Boolean;
    FApplicationID:     String;
    FFirstInstance:     Boolean;
    FGlobal:            Boolean;

    FFileMapData:       PX2InstanceMapData;
    FFileMapping:       THandle;
    FObservers:         TInterfaceList;
  protected
    function GetCount(): Integer; virtual;
    procedure SetApplicationID(const Value: String); virtual;
    procedure SetGlobal(const Value: Boolean); virtual;
    procedure SetActive(const Value: Boolean); virtual;

    procedure WindowProc(var Message: TMessage); virtual;

    property FileMapping: THandle             read FFileMapping;
    property FileMapData: PX2InstanceMapData  read FFileMapData;
    property Observers:   TInterfaceList      read FObservers;
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Open(); virtual;
    procedure Close(); virtual;

    //:$ Sends a notification to the first instance.
    //:! For custom messages you are recommended to start message IDs counting
    //:! from IM_APP. Anything below is reserved for internal use.
    procedure Notify(AMessage: Integer; const AData: String); virtual;

    //:$ Registers the instance for notifications.
    //:: If an application wants to be notified of new instances it must
    //:: implement the IInstanceNotifier and register the interface using
    //:: this function.
    procedure Attach(const ANotifier: IX2InstanceObserver);

    //:$ Unregisters a previously registered instance.
    procedure Detach(const ANotifier: IX2InstanceObserver);

    property Active:          Boolean   read FActive          write SetActive;
    property ApplicationID:   String    read FApplicationID   write SetApplicationID;
    property FirstInstance:   Boolean   read FFirstInstance;
    property Global:          Boolean   read FGlobal          write SetGlobal;
    property Count:           Integer   read GetCount;
  end;

  {
    :$ Checks for a previous instance of the application.

    :: Returns False if a previous instance was found, True if this is the
    :: first registered instance. ApplicationID must be unique to prevent
    :: application conflicts, usage of a generated GUID is recommended.
    ::
    :: If AGlobal is True, the check is performed system-wide. This only
    :: affects Terminal Services and XP Fast User Switching sessions.
    ::
    :: This function is a wrapper for the TX2Instance object. You can access
    :: the created object through the Instance function.

    :! Set ANotify to False if you're using SingleInstance in a console
    :! application without a message loop.
    :!
    :! If AGlobal is True, ANotify only works if the previous instance was
    :! started by the same user.
  }
  function SingleInstance(const AApplicationID: String;
                          ANotify: Boolean = True;
                          AGlobal: Boolean = True): Boolean;

  {
    :$ Returns a singleton TX2Instance object.

    :: The object is automatically configured when using the SingleInstance
    :: function.
  }
  function Instance(): TX2Instance;


  {
    :$ Registers the instance for notifications

    :: Calls Attach on the singleton Instance.
  }
  procedure AttachInstance(const ANotifier: IX2InstanceObserver);

  {
    :$ Unregisters a previously registered instance.

    :: Calls Detach on the singleton Instance.
  }
  procedure DetachInstance(const ANotifier: IX2InstanceObserver);



  {
    :$ Works like System.ParamCount, but uses the specified string instead
    :$ of the actual command line.
  }
  function ParamCountEx(const ACmdLine: String): Integer;

  {
    :$ Works like System.ParamStr, but uses the specified string instead
    :$ of the actual command line
  }
  function ParamStrEx(const ACmdLine: String; AIndex: Integer): String;

  {
    :$ Works like SysUtils.FindCmdLineSwitch, but uses the specified string
    :$ instead of the actual command line
  }
  function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String;
                               const AChars: TSysCharSet;
                               const AIgnoreCase: Boolean): Boolean; overload;

  {
    :$ Works like SysUtils.FindCmdLineSwitch, but uses the specified string
    :$ instead of the actual command line
  }
  function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String): Boolean; overload;

  {
    :$ Works like SysUtils.FindCmdLineSwitch, but uses the specified string
    :$ instead of the actual command line
  }
  function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String;
                               const AIgnoreCase: Boolean): Boolean; overload;


implementation
uses
  Windows;


const
  WindowClass     = 'X2UtSingleInstance.Window';


var
  GlobalInstance:   TX2Instance;


{$WARN SYMBOL_PLATFORM OFF}



{ TX2Instance }
constructor TX2Instance.Create();
begin
  inherited;

  FObservers  := TInterfaceList.Create;
end;

destructor TX2Instance.Destroy();
begin
  Active  := False;
  FreeAndNil(FObservers);

  inherited;
end;


procedure TX2Instance.Notify(AMessage: Integer; const AData: String);
var
  copyStruct: TCopyDataStruct;

begin
  if not Active then
    raise EInstanceNotActive.Create('Instance not Active');

  if FileMapData^.Window = 0 then
    Exit;

  copyStruct.dwData := AMessage;
  copyStruct.cbData := Length(AData);
  copyStruct.lpData := PChar(AData);

  SendMessage(FileMapData^.Window, WM_COPYDATA, 0, Integer(@copyStruct));
end;


procedure TX2Instance.Open();
const
  ScopePrefix:    array[Boolean] of String  = ('Local\', 'Global\');

begin
  if Active then
    Exit;

  if Length(ApplicationID) = 0 then
    raise EInstanceNoAppID.Create('ApplicationID not specified');

  FFirstInstance  := True;

  { Attempt to create shared memory }
  SetLastError(0);
  FFileMapping  := CreateFileMapping($FFFFFFFF, nil, PAGE_READWRITE, 0,
                                     SizeOf(TX2InstanceMapData),
                                     PChar(ScopePrefix[Global] +
                                           'SingleInstance.' + ApplicationID));
  if FFileMapping = 0 then
    RaiseLastOSError();

  FActive := True;
  try
    FFirstInstance  := (GetLastError() <> ERROR_ALREADY_EXISTS);
    FFileMapData    := MapViewOfFile(FFileMapping, FILE_MAP_WRITE, 0, 0, 0);

    if not Assigned(FFileMapData) then
      RaiseLastOSError();

    if FFirstInstance then
    begin
      FileMapData^.Window := CreateWindow(WindowClass, '', 0, 0, 0, 0, 0, 0,
                                          0, SysInit.HInstance, nil);
      if FileMapData^.Window = 0 then
        RaiseLastOSError();

      SetWindowLong(FileMapData^.Window, GWL_WNDPROC,
                    Integer(MakeObjectInstance(WindowProc)));
    end;

    Inc(FFileMapData^.RefCount);
  except
    Close();
  end;
end;

procedure TX2Instance.Close();
begin
  if not Active then
    Exit;
    
  if Assigned(FileMapData) then
  begin
    Dec(FileMapData^.RefCount);
    if FirstInstance then
      DestroyWindow(FileMapData^.Window);

    UnmapViewOfFile(FileMapData);
  end;

  if FileMapping <> 0 then
    CloseHandle(FileMapping);
  
  FActive := False;
end;


procedure TX2Instance.Attach(const ANotifier: IX2InstanceObserver);
begin
  if Observers.IndexOf(ANotifier) = -1 then
    Observers.Add(ANotifier as IX2InstanceObserver);
end;

procedure TX2Instance.Detach(const ANotifier: IX2InstanceObserver);
begin
  Observers.Remove(ANotifier as IX2InstanceObserver);
end;


procedure TX2Instance.WindowProc(var Message: TMessage);
var
  copyData:           PCopyDataStruct;
  data:               String;
  observerIndex:      Integer;
  observerExIntf:     IX2InstanceObserverEx;

begin
  if Assigned(FileMapData) then
    case Message.Msg of
      WM_COPYDATA:
        begin
          copyData  := PCopyDataStruct(Message.LParam);
          data      := '';

          if copyData^.cbData > 0 then
            SetString(data, PChar(copyData^.lpData), copyData^.cbData);

          case copyData^.dwData of
            IM_COMMANDLINE:
              for observerIndex := 0 to Pred(Observers.Count) do
                IX2InstanceObserver(Observers[observerIndex]).OnInstance(data);
          else
            for observerIndex := 0 to Pred(Observers.Count) do
              if Supports(Observers[observerIndex], IX2InstanceObserverEx, observerExIntf) then
                observerExIntf.OnNotify(copyData^.dwData, data);
          end;
        end;
    else
      Message.Result  := DefWindowProc(FileMapData^.Window, Message.Msg,
                                       Message.WParam, Message.LParam);
    end;
end;


function TX2Instance.GetCount(): Integer;
begin
  Result := 0;
  if Active then
    Result := FileMapData^.RefCount;
end;

procedure TX2Instance.SetActive(const Value: Boolean);
begin
  if Value then
    Open
  else
    Close;
end;

procedure TX2Instance.SetApplicationID(const Value: String);
var
  wasActive: Boolean;

begin
  if Value <> FApplicationID then
  begin
    wasActive       := Active;
    Active          := False;

    FApplicationID  := Value;

    Active          := wasActive;
  end;
end;

procedure TX2Instance.SetGlobal(const Value: Boolean);
var
  wasActive: Boolean;

begin
  if Value <> FGlobal then
  begin
    wasActive       := Active;
    Active          := False;

    FGlobal         := Value;

    Active          := wasActive;
  end;
end;



// Copied from System unit because Borland didn't make it public
function GetParamStr(P: PChar; var Param: String): PChar;
var
  i, Len: Integer;
  Start, S, Q: PChar;
begin
  while True do
  begin
    while (P[0] <> #0) and (P[0] <= ' ') do
      P := CharNext(P);
    if (P[0] = '"') and (P[1] = '"') then Inc(P, 2) else Break;
  end;
  Len := 0;
  Start := P;
  while P[0] > ' ' do
  begin
    if P[0] = '"' then
    begin
      P := CharNext(P);
      while (P[0] <> #0) and (P[0] <> '"') do
      begin
        Q := CharNext(P);
        Inc(Len, Q - P);
        P := Q;
      end;
      if P[0] <> #0 then
        P := CharNext(P);
    end
    else
    begin
      Q := CharNext(P);
      Inc(Len, Q - P);
      P := Q;
    end;
  end;

  SetLength(Param, Len);

  P := Start;
  S := Pointer(Param);
  i := 0;
  while P[0] > ' ' do
  begin
    if P[0] = '"' then
    begin
      P := CharNext(P);
      while (P[0] <> #0) and (P[0] <> '"') do
      begin
        Q := CharNext(P);
        while P < Q do
        begin
          S[i] := P^;
          Inc(P);
          Inc(i);
        end;
      end;
      if P[0] <> #0 then P := CharNext(P);
    end
    else
    begin
      Q := CharNext(P);
      while P < Q do
      begin
        S[i] := P^;
        Inc(P);
        Inc(i);
      end;
    end;
  end;

  Result := P;
end;


{ Single instance wrappers }
function SingleInstance(const AApplicationID: String;
                        ANotify, AGlobal: Boolean): Boolean;
var
  newCmdLine:   String;
  dummy:        String;

begin
  with Instance do
begin
    ApplicationID := AApplicationID;
    Global        := AGlobal;
    Active        := True;

    Result        := FirstInstance;

    if (not Result) and ANotify then
    begin
      { For compatibility with ParamStr(0), we'll modify the command-line to
        include the full executable path. }
      newCmdLine  := '"' + ParamStr(0) + '" ' + GetParamStr(CmdLine, dummy);
      Notify(IM_COMMANDLINE, newCmdLine);
      end;
    end;
  end;

function Instance(): TX2Instance;
begin
  if not Assigned(GlobalInstance) then
    GlobalInstance  := TX2Instance.Create;

  Result  := GlobalInstance;
end;

procedure AttachInstance(const ANotifier: IX2InstanceObserver);
begin
  Instance.Attach(ANotifier);
end;

procedure DetachInstance(const ANotifier: IX2InstanceObserver);
begin
  Instance.Detach(ANotifier);
end;


{ Parameter helpers }
function ParamCountEx(const ACmdLine: String): Integer;
var
  pCmdLine:     PChar;
  sParam:       String;

begin
  Result    := 0;
  pCmdLine  := GetParamStr(PChar(ACmdLine), sParam);

  while True do begin
    pCmdLine  := GetParamStr(pCmdLine, sParam);

    if Length(sParam) = 0 then
      break;

    Inc(Result);
  end;
end;

function ParamStrEx(const ACmdLine: String; AIndex: Integer): String;
var
  pCmdLine:       PChar;

begin
  Result    := '';
  pCmdLine  := PChar(ACmdLine);
  while True do begin
    pCmdLine  := GetParamStr(pCmdLine, Result);

    if (AIndex = 0) or (Length(Result) = 0) then
      break;

    Dec(AIndex);
  end;
end;


function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String;
                             const AChars: TSysCharSet;
                             const AIgnoreCase: Boolean): Boolean;
var
  iParam:         Integer;
  sParam:         String;

begin
  for iParam  := 1 to ParamCountEx(ACmdLine) do begin
    sParam  := ParamStrEx(ACmdLine, iParam);

    if (AChars = []) or (sParam[1] in AChars) then
      if AIgnoreCase then begin
        if (AnsiCompareText(Copy(sParam, 2, Maxint), ASwitch) = 0) then begin
          Result  := True;
          exit;
        end;
      end else begin
        if (AnsiCompareStr(Copy(sParam, 2, Maxint), ASwitch) = 0) then begin
          Result  := True;
          exit;
        end;
      end;
  end;

  Result  := False;
end;

function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String): Boolean;
begin
  Result  := FindCmdLineSwitchEx(ACmdLine, ASwitch, SwitchChars, True);
end;

function FindCmdLineSwitchEx(const ACmdLine, ASwitch: String;
                           const AIgnoreCase: Boolean): Boolean;
begin
  Result  := FindCmdLineSwitchEx(ACmdLine, ASwitch, SwitchChars, AIgnoreCase);
end;



var
  wndClass:       TWndClass;

initialization
  { Register window class }
  FillChar(wndClass, SizeOf(wndClass), #0);
  with wndClass do
  begin
    lpfnWndProc     := @DefWindowProc;
    hInstance       := SysInit.HInstance;
    lpszClassName   := WindowClass;
  end;

  Windows.RegisterClass(wndClass);

finalization
  Windows.UnregisterClass(WindowClass, SysInit.HInstance);

  FreeAndNil(GlobalInstance);

end.
