{
  :: X2UtOS provides a singleton OS object to access properties associated
  :: with the Operating System, such as the version number.
  :: It is part of the X2Utils suite.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtOS;

interface
uses
  Windows;

type
  {$IF CompilerVersion < 23}
  TOSVersionInfoEx = packed record
    dwOSVersionInfoSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformId: DWORD;
    szCSDVersion: array[0..127] of AnsiChar;
    wServicePackMajor: WORD;
    wServicePackMinor: WORD;
    wSuiteMask: WORD;
    wProductType: Byte;
    wReserved: Byte;
  end;
  {$IFEND}


  //:$ Enumeration of the recognized Operating System versions
  TX2OSVersion  = (osWin95, osWin98, osWinME, osWinNT3, osWinNT4,
                   osWin2K, osWinXP, osWin2003, osWinVista, osWinServer2008,
                   osWinServer2008R2, osWin7, osWinServer2012, osWin8,
                   osWinServer2012R2, osWin81, osUnknown);

  //:$ Record to hold the Common Controls version
  TX2CCVersion  = record
    Major:            Cardinal;
    Minor:            Cardinal;
    Build:            Cardinal;
  end;

  {
    :$ Contains extended version information for the Operating System
  }
  TX2OSVersionEx  = class(TObject)
  private
    FName:            String;
    FVersionString:   String;
    FBuild:           Cardinal;
    FRawInfo:         TOSVersionInfoEx;
  public
    //:$ Contains the name of the OS
    property Name:            String            read FName          write FName;

    //:$ Contains a string representation of the OS' version
    property VersionString:   String            read FVersionString write FVersionString;

    //:$ Contains the build number of the OS
    property Build:           Cardinal          read FBuild         write FBuild;

    //:$ Contains the raw version information as provided by the OS
    property RawInfo:         TOSVersionInfoEx  read FRawInfo       write FRawInfo;
  end;

  {
    :$ Container for the Operating System's information
  }
  TX2OS           = class(TObject)
  private
    FCCVersion:       TX2CCVersion;
    FVersion:         TX2OSVersion;
    FVersionEx:       TX2OSVersionEx;

    function GetSupportsUAC: Boolean;
    function GetXPManifest: Boolean;
  protected
    procedure GetVersion; virtual;
    procedure GetCCVersion; virtual;
  public
    constructor Create;
    destructor Destroy; override;

    //:$ Returns the formatted version information
    //:: If Build is False, the return value will not include the
    //:: OS' Build number.
    function FormatVersion(Build: Boolean = True): String;


    //:$ Contains the Common Controls version
    property ComCtlVersion: TX2CCVersion    read FCCVersion;

    //:$ Checks if the OS supports User Account Control
    property SupportsUAC: Boolean read GetSupportsUAC;

    //:$ Checks if the application uses an XP manifest
    //:: If present, Common Controls version 6 or higher is available.
    property XPManifest:    Boolean         read GetXPManifest;

    //:$ Contains the detected OS version
    property Version:       TX2OSVersion    read FVersion;

    //:$ Contains extended OS version information
    property VersionEx:     TX2OSVersionEx  read FVersionEx;
  end;

  function OS: TX2OS;


const
  { NT Product types: used by dwProductType field }
  VER_NT_WORKSTATION = $0000001;
  VER_NT_DOMAIN_CONTROLLER = $0000002;
  VER_NT_SERVER = $0000003;

  { NT product suite mask values: used by wSuiteMask field }
  VER_SUITE_SMALLBUSINESS = $00000001;
  VER_SUITE_ENTERPRISE = $00000002;
  VER_SUITE_BACKOFFICE = $00000004;
  VER_SUITE_COMMUNICATIONS = $00000008;
  VER_SUITE_TERMINAL = $00000010;
  VER_SUITE_SMALLBUSINESS_RESTRICTED = $00000020;
  VER_SUITE_EMBEDDEDNT = $00000040;
  VER_SUITE_DATACENTER = $00000080;
  VER_SUITE_SINGLEUSERTS = $00000100;
  VER_SUITE_PERSONAL = $00000200;
  VER_SUITE_SERVERAPPLIANCE = $00000400;
  VER_SUITE_BLADE = VER_SUITE_SERVERAPPLIANCE;


  X2OSVersionString: array[TX2OSVersion] of string =
                     (
                       '95', '98', 'ME', 'NT 3.51', 'NT 4',
                       '2000', 'XP', 'Server 2003', 'Vista', 'Server 2008',
                       'Server 2008 R2', '7', 'Server 2012', '8',
                       'Server 2012 R2', '8.1', 'Onbekend'
                     );

  
implementation
uses
  SysUtils;

const
  ComCtl32  = 'comctl32.dll';

type
  PDllVersionInfo = ^TDllVersionInfo;
  TDllVersionInfo = record
    cbSize:             DWORD;
    dwMajorVersion:     DWORD;
    dwMinorVersion:     DWORD;
    dwBuildNumber:      DWORD;
    dwPlatformID:       DWORD;
  end;

  TDllGetVersion  = function(pdvi: PDllVersionInfo): HRESULT; stdcall;

var
  GOS:        TX2OS;


{========================================
  Singleton
========================================}
function OS;
begin
  if not Assigned(GOS) then
    GOS := TX2OS.Create;

  Result  := GOS;
end;


{================================== TX2OS
  Initialization
========================================}
constructor TX2OS.Create;
begin
  inherited;

  FVersionEx  := TX2OSVersionEx.Create;
  GetVersion;
  GetCCVersion;
end;

destructor TX2OS.Destroy;
begin
  FreeAndNil(FVersionEx);

  inherited;
end;


{================================== TX2OS
  Version
========================================}
procedure TX2OS.GetVersion;
var
  versionInfo:    TOSVersionInfoEx;
  versionInfoPtr: POSVersionInfo;

begin
  FVersion  := osUnknown;

  { Get version information }
  FillChar(versionInfo, SizeOf(versionInfo), 0);
  versionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfoEx);

  versionInfoPtr := @versionInfo;

  if not GetVersionEx(versionInfoPtr^) then
  begin
    { Maybe this is an older Windows version, not supporting the Ex fields }
    versionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
    if not GetVersionEx(versionInfoPtr^) then
      RaiseLastOSError;
  end;

  with FVersionEx do
  begin
    { No Kylix support yet, sorry! }
    RawInfo := versionInfo;
    Name    := 'Windows';

    case versionInfo.dwMajorVersion of
      3:      { Windows NT 3.51 }
        FVersion := osWinNT3;
      4:      { Windows 95/98/ME/NT 4 }
        case versionInfo.dwMinorVersion of
          0:  { Windows 95/NT 4 }
            case versionInfo.dwPlatformId of
              VER_PLATFORM_WIN32_NT:        { Windows NT 4 }
                FVersion := osWinNT4;
              VER_PLATFORM_WIN32_WINDOWS:   { Windows 95 }
                FVersion := osWin95;
            end;
          10: { Windows 98 }
            FVersion := osWin98;
          90: { Windows ME }
            FVersion := osWinME;
        end;
      5:      { Windows 2000/XP/2003 }
        case versionInfo.dwMinorVersion of
          0:  { Windows 2000 }
            FVersion := osWin2K;
          1:  { Windows XP }
            FVersion := osWinXP;
          2:  { Windows Server 2003 }
            FVersion := osWin2003;
        end;
      6:      { Windows Vista/Server 2008/7/2012/8 }
        if versionInfo.wProductType = VER_NT_WORKSTATION then
        begin
          case versionInfo.dwMinorVersion of
            0: { Windows Vista }
              FVersion := osWinVista;
            1: { Windows 7 }
              FVersion := osWin7;
            2: { Windows 8 }
              FVersion := osWin8;
            3: { Windows 8.1 }
              FVersion := osWin81;
          end;
        end else
        begin
          case versionInfo.dwMinorVersion of
            0: { Windows Server 2008 }
              FVersion := osWinServer2008;
            1: { Windows Server 2008 R2 }
              FVersion := osWinServer2008R2;
            2: { Windows Server 2012 }
              FVersion := osWinServer2012;
            3: { Windows Server 2012 R2 }
              FVersion := osWinServer2012R2;
          end;
        end;
    end;

    if Version <> osUnknown then
      VersionString := X2OSVersionString[Version]
    else
      VersionString := Format('%d.%d', [versionInfo.dwMajorVersion,
                                        versionInfo.dwMinorVersion]);

    if StrLen(versionInfo.szCSDVersion) > 0 then
      VersionString := VersionString + ' ' + string(versionInfo.szCSDVersion);

    case versionInfo.dwPlatformId of
      VER_PLATFORM_WIN32_NT:
        Build := versionInfo.dwBuildNumber;
      VER_PLATFORM_WIN32_WINDOWS:
        Build := LoWord(versionInfo.dwBuildNumber);
    end;
  end;
end;

procedure TX2OS.GetCCVersion;
var
  DllGetVersion:    TDllGetVersion;
  hLib:             THandle;
  viVersion:        TDllVersionInfo;

begin
  FillChar(FCCVersion, SizeOf(FCCVersion), #0);
  hLib  := LoadLibrary(ComCtl32);

  if hLib <> 0 then
  begin
    @DllGetVersion  := GetProcAddress(hLib, 'DllGetVersion');
    if Assigned(DllGetVersion) then
    begin
      FillChar(viVersion, SizeOf(viVersion), #0);
      viVersion.cbSize  := SizeOf(viVersion);

      DllGetVersion(@viVersion);

      with FCCVersion do
      begin
        Major   := viVersion.dwMajorVersion;
        Minor   := viVersion.dwMinorVersion;
        Build   := viVersion.dwBuildNumber;
      end;
    end;

    FreeLibrary(hLib);
  end;
end;


function TX2OS.FormatVersion;
var
  sBuild:     String;

begin
  sBuild := '';

  if Build then
    sBuild := Format(' build %d', [FVersionEx.Build]);

  with FVersionEx do
    Result := Format('%s %s%s', [Name, VersionString, sBuild]);
end;


function TX2OS.GetXPManifest;
begin
  Result := (FCCVersion.Major >= 6);
end;


function TX2OS.GetSupportsUAC: Boolean;
begin
  Result := (FVersionEx.RawInfo.dwMajorVersion >= 6);
end;


initialization
finalization
  FreeAndNil(GOS);

end.
