{
  Helper functions and classes for writing UAC-compatible elevated COM objects.
  Backwards-compatible with previous Windows versions.
}
unit X2UtElevation;

interface
uses
  ActiveX,
  ComObj;


  { Checks if the current process has the elevation token. }
  function IsElevated: Boolean;

  { Creates an elevated instance of COM object. Returns False if the
    user cancelled the elevation prompt. }
  function CoCreateElevatedInstance(AParentWnd: THandle; AClassID: TCLSID;
                                    AIID: TIID; var AIntf): Boolean; 


type
  (*
    Registers a COM object for elevation.

    The ResourceID must point to a String Table resource in the current
    module and contains the program name to display in the elevation prompt.

    An example .rc file:

    STRINGTABLE
    {
      42, "Elevated COM Object"
    }
  *)
  TElevatedClassFactory = class(TTypedComObjectFactory)
  private
    FResourceID: string;
  public
    constructor Create(const AResourceID: string; AComServer: TComServerObject;
                       ATypedComClass: TTypedComClass; const AClassID: TGUID;
                       AInstancing: TClassInstancing;
                       AThreadingModel: TThreadingModel = tmSingle);

    procedure UpdateRegistry(Register: Boolean); override;

    property ResourceID: string read FResourceID;
  end;


implementation
uses
  ComConst,
  SysUtils,
  Windows,

  X2UtOS;


type
  BIND_OPTS3 = packed record
    cbStruct:            DWORD;
    grfFlags:            DWORD;
    grfMode:             DWORD;
    dwTickCountDeadline: DWORD;
    dwTrackFlags:        DWORD;
    dwClassContext:      DWORD;
    locale:              LCID;
    pServerInfo:         PCOSERVERINFO;
    hwnd:                HWND;
  end;
  PBIND_OPTS3 = ^BIND_OPTS3;

  TOKEN_INFORMATION_CLASS = (
    TokenICPad,
    TokenUser,
    TokenGroups,
    TokenPrivileges,
    TokenOwner,
    TokenPrimaryGroup,
    TokenDefaultDacl,
    TokenSource,
    TokenType,
    TokenImpersonationLevel,
    TokenStatistics,
    TokenRestrictedSids,
    TokenSessionId,
    TokenGroupsAndPrivileges,
    TokenSessionReference,
    TokenSandBoxInert,
    TokenAuditPolicy,
    TokenOrigin,
    TokenElevationType,
    TokenLinkedToken,
    TokenElevation,
    TokenHasRestrictions,
    TokenAccessInformation,
    TokenVirtualizationAllowed,
    TokenVirtualizationEnabled,
    TokenIntegrityLevel,
    TokenUIAccess,
    TokenMandatoryPolicy,
    TokenLogonSid,
    MaxTokenInfoClass
  );

  TOKEN_ELEVATION = packed record
    TokenIsElevated: DWORD;
  end;
  PTOKEN_ELEVATION = ^TOKEN_ELEVATION;
  

  { Who in the advapi32 team came up with this name?! Descriptive for sure. }
  TConvertStringSecurityDescriptorToSecurityDescriptorA = function(StringSecurityDescriptor: PAnsiChar;
                                                                   StringSDRevision: Cardinal;
                                                                   var SecurityDescriptor: PSecurityDescriptor;
                                                                   var SecurityDescriptorSize: Cardinal): LongBool; stdcall;

  TCoGetObject = function(pszName: PWideChar; pBindOptions: PBIND_OPTS3;
                          const iid: TIID; out ppv): HResult; stdcall; //external 'ole32.dll' name 'CoGetObject';

  TOpenProcessToken = function(ProcessHandle: THandle; DesiredAccess: DWORD;
                               var TokenHandle: THandle): BOOL; stdcall;

  TGetTokenInformation = function(TokenHandle: THandle;
                                  TokenInformationClass: TOKEN_INFORMATION_CLASS;
                                  TokenInformation: Pointer;
                                  TokenInformationLength: DWORD;
                                  var ReturnLength: DWORD): BOOL; stdcall;


var
  ConvertStringSecurityDescriptorToSecurityDescriptorA: TConvertStringSecurityDescriptorToSecurityDescriptorA;
  CoGetObject: TCoGetObject;
  OpenProcessToken: TOpenProcessToken;
  GetTokenInformation: TGetTokenInformation;



{ Helper functions }
function IsElevated: Boolean;
var
  tokenHandle: THandle;
  tokenInfo: TOKEN_ELEVATION;
  dummy: Cardinal;

begin
  Result := False;
  if (not Assigned(OpenProcessToken)) or
     (not Assigned(GetTokenInformation)) then
    Exit;
  

  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, tokenHandle) then
  begin
    dummy := 0;

    if GetTokenInformation(tokenHandle, TokenElevation, @tokenInfo, SizeOf(TOKEN_ELEVATION), dummy) then
      Result := (tokenInfo.TokenIsElevated <> 0);

    CloseHandle(tokenHandle);
  end;
end;


function CoCreateElevatedInstance(AParentWnd: THandle; AClassID: TCLSID;
                                  AIID: TIID; var AIntf): Boolean;
var
  bindOptions: BIND_OPTS3;
  monikerName: WideString;
  status: HRESULT;

begin
  Result := True;

  if OS.SupportsUAC and (not IsElevated) then
  begin
    { Use elevation moniker }
    monikerName := 'Elevation:Administrator!new:' + GUIDToString(AClassID);

    FillChar(bindOptions, SizeOf(bindOptions), 0);
    bindOptions.cbStruct := SizeOf(bindOptions);
    bindOptions.dwClassContext := CLSCTX_LOCAL_SERVER;
    bindOptions.hwnd := AParentWnd;

    status := CoGetObject(PWideChar(monikerName), @bindOptions, aIID, AIntf);
    if HResultCode(status) = ERROR_CANCELLED then
      Result := False
    else
      OleCheck(status);
  end else
    { Use good ole' CoCreateInstance }
    OleCheck(CoCreateInstance(AClassID, nil, CLSCTX_ALL, AIID, AIntf));
end;


{ Internal helper functions }
procedure LoadAPIFunctions;
var
  dllHandle: THandle;

begin
  dllHandle := GetModuleHandle(advapi32);
  if dllHandle <> 0 then
  begin
    @ConvertStringSecurityDescriptorToSecurityDescriptorA := GetProcAddress(dllHandle, 'ConvertStringSecurityDescriptorToSecurityDescriptorA');
    @OpenProcessToken := GetProcAddress(dllHandle, 'OpenProcessToken');
    @GetTokenInformation := GetProcAddress(dllHandle, 'GetTokenInformation');
  end;

  dllHandle := GetModuleHandle('ole32.dll');
  if dllHandle <> 0 then
    @CoGetObject := GetProcAddress(dllHandle, 'CoGetObject');
end;


procedure CreateRegKeyDWORD(const AKey, AValue: string; AData: DWORD; ARootKey: HKEY = HKEY_CLASSES_ROOT);
var
  keyHandle: HKEY;
  status: Integer;
  disposition: Integer;

begin
  status := RegCreateKeyEx(ARootKey, PChar(AKey), 0, '',
                           REG_OPTION_NON_VOLATILE, KEY_READ or KEY_WRITE, nil,
                           keyHandle, @disposition);

  if status = ERROR_SUCCESS then
  begin
    status := RegSetValueEx(keyHandle, PChar(AValue), 0, REG_DWORD,
                            @AData, SizeOf(DWORD));
    RegCloseKey(keyHandle);
  end;

  if status <> ERROR_SUCCESS then
    raise EOleRegistrationError.CreateRes(@SCreateRegKeyError);
end;


procedure SetAccessPermission(const AKey: string);
const
  LocalCallSecDesc  = 'O:BAG:BAD:(A;;0x3;;;IU)(A;;0x3;;;SY)';

const
  SDDL_REVISION_1 = 1;
  
var
  descriptor: PSecurityDescriptor;
  size: Cardinal;
  keyHandle: HKEY;

begin
  if not Assigned(ConvertStringSecurityDescriptorToSecurityDescriptorA) then
    Exit;

  if not ConvertStringSecurityDescriptorToSecurityDescriptorA(LocalCallSecDesc,
                                                              SDDL_REVISION_1,
                                                              descriptor, size) then
    RaiseLastOSError;

  try
    if RegOpenKeyEx(HKEY_CLASSES_ROOT, PChar(AKey), 0, KEY_READ or KEY_WRITE, keyHandle) = ERROR_SUCCESS then
    try
      if RegSetValueEx(keyHandle, PChar('AccessPermission'), 0, REG_BINARY, descriptor, size) <> ERROR_SUCCESS then
        RaiseLastOSError;
    finally
      RegCloseKey(keyHandle);
    end else
      RaiseLastOSError;
  finally
    LocalFree(Cardinal(descriptor));
  end;
end;


{ TElevatedClassFactory }
constructor TElevatedClassFactory.Create(const AResourceID: string;
                                         AComServer: TComServerObject;
                                         ATypedComClass: TTypedComClass;
                                         const AClassID: TGUID;
                                         AInstancing: TClassInstancing;
                                         AThreadingModel: TThreadingModel);
begin
  inherited Create(AComServer, ATypedComClass, AClassID, AInstancing,
                   AThreadingModel);

  FResourceID := AResourceID;
end;


procedure TElevatedClassFactory.UpdateRegistry(Register: Boolean);
var
  classIDAsString: string;
  filePath: string;
  fileName: string;
  appRegKey: string;
  classRegKey: string;

begin
  if not OS.SupportsUAC then
  begin
    inherited;
    Exit;
  end;

  try
    classIDAsString := GUIDToString(Self.ClassID);
    filePath        := ComServer.ServerFileName;
    fileName        := ExtractFileName(filePath);

    appRegKey       := 'AppID\' + classIDAsString;
    classRegKey     := 'CLSID\' + classIDAsString;

    if Register then
    begin
      inherited;

      { Out-of-process }
      CreateRegKey(appRegKey, '', Description);
      CreateRegKey(appRegKey, 'DllSurrogate', '');
      CreateRegKey('AppID\' + fileName, 'AppID', classIDAsString);

      { Over-The-Shoulder elevation }
      SetAccessPermission(appRegKey);

      { COM object elevation }
      CreateRegKey(classRegKey, 'AppID', classIDAsString);
      CreateRegKey(classRegKey, 'LocalizedString', '@' + filePath + ',-' + fResourceId);
      CreateRegKeyDWORD(classRegKey + '\Elevation', 'Enabled', 1);
    end else begin
      DeleteRegKey(classRegKey + '\Elevation');
      DeleteRegKey(appRegKey);
      DeleteRegKey('AppID\' + fileName);

      inherited;
    end;
  except
    on E: Exception do
      {$IF CompilerVersion >= 23}
      raise EOleRegistrationError.Create(E.Message, 0, 0);
      {$ELSE}
      raise EOleRegistrationError.Create(E.Message);
      {$IFEND}
  end;
end;


initialization
  LoadAPIFunctions;

end.
