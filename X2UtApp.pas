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
  public
    constructor Create();
    destructor Destroy(); override;

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
    FPath:            String;
  protected
    function GetModule(): String; virtual;
    procedure GetPath(); virtual;
    procedure GetVersion(); virtual;
  public
    constructor Create();
    destructor Destroy(); override;

    //:$ Returns the formatted version information
    //:: If ABuild is False, the return value will not include the
    //:: application's Build number. If AProductName is True, the
    //:: product name will be included as well.
    function FormatVersion(const ABuild: Boolean = True;
                           const AProductName: Boolean = False): String;

    //:$ Contains the path to the application's executable
    //:! This path in unaffected by the working directory which may be
    //:! specified in the shortcut launching the application. A trailing
    //:! slash is included in the path.
    property Path:      String          read FPath;

    //:$ Contains the application's version information
    property Version:   TX2AppVersion   read FVersion;
  end;

  //:$ Returns a singleton App object
  function App(): TX2App;

implementation
uses
  SysUtils,
  TypInfo,
  Windows;

const
  tkStrings = [tkString, tkLString, tkWString];

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
constructor TX2AppVersion.Create;
begin
  inherited;

  FStrings  := TX2AppVersionStrings.Create();
end;

destructor TX2AppVersion.Destroy;
begin
  FreeAndNil(FStrings);

  inherited;
end;


{================================= TX2App
  Initialization
========================================}
constructor TX2App.Create;
begin
  inherited;

  FVersion  := TX2AppVersion.Create();

  GetPath();
  GetVersion();
end;

destructor TX2App.Destroy;
begin
  FreeAndNil(FVersion);

  inherited;
end;


{================================= TX2App
  Path
========================================}
function TX2App.GetModule;
var
  cModule:  array[0..MAX_PATH] of Char;

begin
  FillChar(cModule, SizeOf(cModule), #0);
  GetModuleFileName(hInstance, @cModule, SizeOf(cModule));
  Result  := String(cModule);
end;


procedure TX2App.GetPath;
begin
  {$IFDEF D6}
  FPath   := IncludeTrailingPathDelimiter(ExtractFilePath(GetModule()));
  {$ELSE}
  FPath   := IncludeTrailingBackslash(ExtractFilePath(GetModule()));
  {$ENDIF}
end;


{================================= TX2App
  Version
========================================}
function TX2App.FormatVersion;
var
  sBuild:     String;

begin
  sBuild    := '';

  if ABuild then
    sBuild  := Format(' build %d', [FVersion.Build]);

  Result    := '';
  if AProductName then
    Result  := FVersion.Strings.ProductName + ' ';

  with FVersion do
    Result := Result + Format('v%d.%d.%d%s', [Major, Minor, Release, sBuild]);
end;


procedure TX2App.GetVersion;
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
  with FVersion do begin
    Major   := 0;
    Minor   := 0;
    Release := 0;
    Build   := 0;
  end;

  pFile := PChar(GetModule());
  dSize := GetFileVersionInfoSize(pFile, dTemp);

  if dSize <> 0 then begin
    GetMem(pBuffer, dSize);

    try
      if GetFileVersionInfo(pFile, dTemp, dSize, pBuffer) then
        // Get version numbers
        with FVersion do begin
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

            iCount  := GetPropList(FVersion.Strings.ClassInfo, tkStrings, nil);
            iSize   := iCount * SizeOf(TPropInfo);
            GetMem(pProps, iSize);

            try
              GetPropList(FVersion.Strings.ClassInfo, tkStrings, pProps);

              for iProp := 0 to iCount - 1 do begin
                if VerQueryValue(pBuffer, PChar(cName + '\' + pProps^[iProp]^.Name),
                                 Pointer(pValue), dVer) then
                  SetStrProp(FVersion.Strings, pProps[iProp], pValue);
              end;
            finally
              FreeMem(pProps, iSize);
            end;
          end;
        end;
    finally
      FreeMem(pBuffer, dSize);
    end;
  end;
end;


initialization
finalization
  FreeAndNil(GApp);

end.
 