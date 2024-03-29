{** Provides application related information
 *
 * Provides a singleton App object to access properties associated
 * with the application, such as the version number or executable path.
 * It is part of the X2Utils suite.
 * <br /><br />
 *
 * Last changed:  $Date$ <br />
 * Revision:      $Rev$ <br />
 * Author:        $Author$ <br />
*}
unit X2UtApp;

interface
uses
  Classes;

type
  {
    :$ Stores version info strings

    :! This class descends from TPersistent, allowing the use of RTTI to
    :! retrieve version info names.
  }
  TX2AppVersionStrings  = class(TPersistent)
  private
    FValues:          TStringList;

    function GetValue(const Index: Integer): String;
    procedure SetValue(const Index: Integer; const Value: String);
  public
    constructor Create();
    destructor Destroy(); override;
  published
    //:$ Contains the Company Name as specified in the version information
    //:! Default to an empty string if no version information is available
    property CompanyName:       String index 0  read GetValue write SetValue;

    //:$ Contains the File Description as specified in the version information
    //:! Default to an empty string if no version information is available
    property FileDescription:   String index 1  read GetValue write SetValue;

    //:$ Contains the File Version as specified in the version information
    //:! Default to an empty string if no version information is available
    property FileVersion:       String index 2  read GetValue write SetValue;

    //:$ Contains the Internal Name as specified in the version information
    //:! Default to an empty string if no version information is available
    property InternalName:      String index 3  read GetValue write SetValue;

    //:$ Contains the Legal Copyright as specified in the version information
    //:! Default to an empty string if no version information is available
    property LegalCopyright:    String index 4  read GetValue write SetValue;

    //:$ Contains the Legal Trademark as specified in the version information
    //:! Default to an empty string if no version information is available
    property LegalTrademark:    String index 5  read GetValue write SetValue;

    //:$ Contains the Original Filename as specified in the version information
    //:! Default to an empty string if no version information is available
    property OriginalFilename:  String index 6  read GetValue write SetValue;

    //:$ Contains the Product Name as specified in the version information
    //:! Default to an empty string if no version information is available
    property ProductName:       String index 7  read GetValue write SetValue;

    //:$ Contains the Product Version as specified in the version information
    //:! Default to an empty string if no version information is available
    property ProductVersion:    String index 8  read GetValue write SetValue;

    //:$ Contains the Comments as specified in the version information
    //:! Default to an empty string if no version information is available
    property Comments:          String index 9  read GetValue write SetValue;
  end;

  {
    :$ Stores the application's version information
  }
  TX2AppVersion = class(TObject)
  private
    FMajor:           Integer;
    FMinor:           Integer;
    FRelease:         Integer;
    FBuild:           Integer;
    FDebug:           Boolean;
    FPrerelease:      Boolean;
    FSpecial:         Boolean;
    FPrivate:         Boolean;
    FStrings:         TX2AppVersionStrings;
  protected
    procedure GetVersion(const AFileName: String); virtual;
  public
    constructor Create(const AFileName: String);
    destructor Destroy(); override;

    //:$ Returns the formatted version information
    //:: If ABuild is False, the return value will not include the
    //:: application's Build number. If AProductName is True, the
    //:: product name will be included as well.
    function FormatVersion(const ABuild: Boolean = True;
                           const AProductName: Boolean = False): String;

    //:$ Contains the application's Major version
    //:! Defaults to 0 if no version information is available
    property Major:           Integer               read FMajor       write FMajor;

    //:$ Contains the application's Minor version
    //:! Defaults to 0 if no version information is available
    property Minor:           Integer               read FMinor       write FMinor;

    //:$ Contains the application's Release number
    //:! Defaults to 0 if no version information is available
    property Release:         Integer               read FRelease     write FRelease;

    //:$ Contains the application's Build number
    //:! Defaults to 0 if no version information is available
    property Build:           Integer               read FBuild       write FBuild;

    //:$ Contains the value of the Debug Build flag
    //:! Defaults to False if no version information is available
    property Debug:           Boolean               read FDebug       write FDebug;

    //:$ Contains the value of the Prerelease Build flag
    //:! Defaults to False if no version information is available
    property Prerelease:      Boolean               read FPrerelease  write FPrerelease;

    //:$ Contains the value of the Special Build flag
    //:! Defaults to False if no version information is available
    property Special:         Boolean               read FSpecial     write FSpecial;

    //:$ Contains the value of the Private Build flag
    //:! Defaults to False if no version information is available
    property Private:         Boolean               read FPrivate     write FPrivate;

    //:$ Contains extended version information
    property Strings:         TX2AppVersionStrings  read FStrings;
  end;


  TX2App  = class(TObject)
  private
    FVersion:         TX2AppVersion;
    FFileName:        String;
    FPath:            String;
    FMainPath:        String;
    FUserPath:        String;
    FProgramDataPath: String;

    function GetVersion(): TX2AppVersion;
  protected
    function GetModule(const AModule: THandle): String; virtual;
    procedure GetPath(); virtual;
  public
    constructor Create();
    destructor Destroy(); override;

    //:$ Returns the formatted version information
    //:: If ABuild is False, the return value will not include the
    //:: application's Build number. If AProductName is True, the
    //:: product name will be included as well.
    function FormatVersion(const ABuild: Boolean = True;
                           const AProductName: Boolean = False): String;

    //:$ Contains the filename of the current module
    //:! In DLL's and BPL's, this points to the filename of the current library.
    //:! Note that for packages using X2Utils.bpl, this will point to the path
    //:! of X2Utils.bpl, not the calling package! If you want the main
    //:! executable's path, use the MainPath property.
    property FileName: String read FFileName;

    //:$ Contains the path to the current module
    //:! In DLL's and BPL's, this points to the path of the current library.
    //:! Note that for packages using X2Utils.bpl, this will point to the path
    //:! of X2Utils.bpl, not the calling package! If you want the main
    //:! executable's path, use the MainPath property.
    property Path: String read FPath;

    //:$ Contains the path to the application's executable
    //:! This path in unaffected by the working directory which may be
    //:! specified in the shortcut launching the application. A trailing
    //:! slash is included in the path.
    property MainPath: String read FMainPath;

    //:$ Contains the path to the user's Application Data
    property UserPath: String read FUserPath;

    //:$ Contains the path to the system's Program Data
    property ProgramDataPath: String read FProgramDataPath;

    //:$ Contains the application's version information
    property Version: TX2AppVersion read GetVersion;
  end;

  //:$ Returns a singleton App object
  function App(): TX2App;

implementation
uses
  ActiveX,
  ShlObj,
  SysUtils,
  TypInfo,
  System.IOUtils,
  Windows;

const
  tkStrings = [tkString, tkLString, tkWString{$IF CompilerVersion >= 23}, tkUString{$IFEND}];

var
  GApp:       TX2App;

{$I X2UtCompilerVersion.inc}


{========================================
  Singleton
========================================}
function App;
begin
  if not Assigned(GApp) then
    GApp  := TX2App.Create();

  Result  := GApp;
end;


{=================== TX2AppVersionStrings
  Initialization
========================================}
constructor TX2AppVersionStrings.Create;
begin
  inherited;

  FValues := TStringList.Create();
end;

destructor TX2AppVersionStrings.Destroy;
begin
  FreeAndNil(FValues);

  inherited;
end;


function TX2AppVersionStrings.GetValue;
begin
  if (Index > -1) and (Index < FValues.Count) then
    Result  := FValues[Index]
  else
    Result  := '';
end;

procedure TX2AppVersionStrings.SetValue;
var
  iAdd:     Integer;

begin
  if Index >= FValues.Count then
    for iAdd := FValues.Count to Index do
      FValues.Add('');

  FValues[Index]  := Value;
end;


{========================== TX2AppVersion
  Initialization
========================================}
constructor TX2AppVersion.Create(const AFileName: String);
begin
  inherited Create();

  FStrings  := TX2AppVersionStrings.Create();
  GetVersion(AFileName);
end;

destructor TX2AppVersion.Destroy;
begin
  FreeAndNil(FStrings);

  inherited;
end;


function TX2AppVersion.FormatVersion(const ABuild,
                                     AProductName: Boolean): String;
var
  sBuild:     String;

begin
  sBuild    := '';

  if ABuild then
    sBuild  := Format(' build %d', [Build]);

  Result    := '';
  if AProductName then
    Result  := Strings.ProductName + ' ';

  Result := Result + Format('v%d.%d.%d%s', [Major, Minor, Release, sBuild]);
end;

procedure TX2AppVersion.GetVersion(const AFileName: String);
type
  PLongInt  = ^LongInt;

var
  pInfo:    PVSFixedFileInfo;
  dInfo:    Cardinal;
  dSize:    Cardinal;
  dVer:     Cardinal;
  dTemp:    Cardinal;
  pBuffer:  PChar;
  pFile:    PChar;
  iCount:   Integer;
  iSize:    Integer;
  iProp:    Integer;
  pProps:   PPropList;
  pCode:    PLongInt;
  pValue:   PChar;
  aCode:    array[0..1] of Word;
  cName:    array[0..25] of Char;

begin
  Major   := 0;
  Minor   := 0;
  Release := 0;
  Build   := 0;

  pFile := PChar(AFileName);
  dSize := GetFileVersionInfoSize(pFile, dTemp);

  if dSize <> 0 then begin
    GetMem(pBuffer, dSize);

    try
      if GetFileVersionInfo(pFile, dTemp, dSize, pBuffer) then
        // Get version numbers
        if VerQueryValue(pBuffer, '\', Pointer(pInfo), dInfo) then begin
          Major       := HiWord(pInfo^.dwFileVersionMS);
          Minor       := LoWord(pInfo^.dwFileVersionMS);
          Release     := HiWord(pInfo^.dwFileVersionLS);
          Build       := LoWord(pInfo^.dwFileVersionLS);
          Debug       := ((pInfo^.dwFileFlags and VS_FF_DEBUG) = VS_FF_DEBUG);
          Prerelease  := ((pInfo^.dwFileFlags and VS_FF_PRERELEASE) = VS_FF_PRERELEASE);
          Special     := ((pInfo^.dwFileFlags and VS_FF_SPECIALBUILD) = VS_FF_SPECIALBUILD);
          Private     := ((pInfo^.dwFileFlags and VS_FF_PRIVATEBUILD) = VS_FF_PRIVATEBUILD);
        end;

        // Get additional version information using RTTI
        VerQueryValue(pBuffer, '\VarFileInfo\Translation', Pointer(pCode), dVer);
        if dVer <> 0 then begin
          aCode[0]  := HiWord(pCode^);
          aCode[1]  := LoWord(pCode^);

          FillChar(cName, SizeOf(cName), #0);
          wvsprintf(cName, '\StringFileInfo\%8.8lx', @aCode);

          iCount  := GetPropList(Strings.ClassInfo, tkStrings, nil);
          iSize   := iCount * SizeOf(TPropInfo);
          GetMem(pProps, iSize);

          try
            GetPropList(Strings.ClassInfo, tkStrings, pProps);

            for iProp := 0 to iCount - 1 do begin
              if VerQueryValue(pBuffer, PChar(string(cName) + '\' + string(pProps^[iProp]^.Name)),
                               Pointer(pValue), dVer) then
                SetStrProp(Strings, pProps[iProp], pValue);
            end;
          finally
            FreeMem(pProps, iSize);
          end;
        end;
    finally
      FreeMem(pBuffer, dSize);
    end;
  end;
end;


{================================= TX2App
  Initialization
========================================}
constructor TX2App.Create();
begin
  inherited;

  GetPath();
end;

destructor TX2App.Destroy();
begin
  FreeAndNil(FVersion);

  inherited;
end;


{================================= TX2App
  Path
========================================}
function TX2App.GetModule(const AModule: THandle): String;
var
  cModule:  array[0..MAX_PATH] of Char;

begin
  FillChar(cModule, SizeOf(cModule), #0);
  GetModuleFileName(AModule, @cModule, SizeOf(cModule));
  Result  := String(cModule);
end;


procedure TX2App.GetPath();
  function FixPath(const APath: String): String;
  begin
    Result  := {$IFDEF D6PLUS}IncludeTrailingPathDelimiter
               {$ELSE}IncludeTrailingBackslash{$ENDIF}
               (APath);
  end;

  {$IFNDEF DXE2PLUS}
  procedure GetPaths;
  var
    ifMalloc:       IMalloc;
    pIDL:           PItemIDList;
    cPath:          array[0..MAX_PATH] of Char;
  begin
    SHGetMalloc(ifMalloc);
    try
      FillChar(cPath, SizeOf(cPath), #0);
      SHGetSpecialFolderLocation(0, CSIDL_APPDATA, pIDL);
      SHGetPathFromIDList(pIDL, @cPath);

      FUserPath := FixPath(cPath);

      cPath := '';
      FillChar(cPath, SizeOf(cPath), #0);
      SHGetSpecialFolderLocation(0, CSIDL_COMMON_APPDATA, pIDL);
      SHGetPathFromIDList(pIDL, @cPath);

      FProgramDataPath := FixPath(cPath);
    finally
      ifMalloc  := nil;
    end;
  end;
  {$ENDIF}

begin
  FFileName := GetModule(SysInit.HInstance);
  FPath     := FixPath(ExtractFilePath(FFileName));
  FMainPath := FixPath(ExtractFilePath(GetModule(0)));
  {$IFDEF DXE2PLUS}
  FUserPath := FixPath(System.IOUtils.TPath.GetHomePath);
  FProgramDataPath := FixPath(System.IOUtils.TPath.GetPublicPath);
  {$ELSE}
  GetPaths;
  {$ENDIF}
end;


function TX2App.GetVersion(): TX2AppVersion;
begin
  if not Assigned(FVersion) then
    FVersion  := TX2AppVersion.Create(FFileName);

  Result  := FVersion;
end;


{================================= TX2App
  Version
========================================}
function TX2App.FormatVersion(const ABuild: Boolean = True;
                              const AProductName: Boolean = False): String;
begin
  Result  := Version.FormatVersion(ABuild, AProductName);
end;


initialization
finalization
  FreeAndNil(GApp);

end.
 
