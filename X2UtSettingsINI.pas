{
  :: X2UtSettingsINI extends X2UtSettings with INI reading/writing.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtSettingsINI;

interface
uses
  Classes,
  IniFiles,
  X2UtSettings;

type
  {
    :$ INI-based settings implementation

    :: It is highly recommended to create instances using TX2INISettingsFactory
    :: instead of directly.
  }
  TX2INISettings        = class(TX2Settings)
  private
    FData:        TMemIniFile;
    FSection:     String;
  protected
    function InternalReadBool(const AName: String; out AValue: Boolean): Boolean; override;
    function InternalReadFloat(const AName: String; out AValue: Double): Boolean; override;
    function InternalReadInteger(const AName: String; out AValue: Integer): Boolean; override;
    function InternalReadString(const AName: String; out AValue: String): Boolean; override;

    procedure InternalWriteBool(const AName: String; AValue: Boolean); override;
    procedure InternalWriteFloat(const AName: String; AValue: Double); override;
    procedure InternalWriteInteger(const AName: String; AValue: Integer); override;
    procedure InternalWriteString(const AName, AValue: String); override;
  public
    function ValueExists(const AName: String): Boolean; override;

    procedure GetSectionNames(const ADest: TStrings); override;
    procedure GetValueNames(const ADest: TStrings); override;

    procedure DeleteSection(); override;
    procedure DeleteValue(const AName: String); override;
  public
    constructor CreateInit(const AFactory: TX2SettingsFactory;
                           const ASection, AFilename: String);
    destructor Destroy(); override;
  end;

  {
    :$ Factory for INI-based settings

    :: Before use, assign Filename with a valid path.
  }
  TX2INISettingsFactory = class(TX2SettingsFactory)
  private
    FFilename:      String;
  protected
    function GetSection(const ASection: String): TX2Settings; override;
  public
    //:$ Specifies the filename of the INI
    property Filename:      String  read FFilename  write FFilename;
  end;

implementation
uses
  SysUtils;

{================== TX2INISettingsFactory
  Section
========================================}
function TX2INISettingsFactory.GetSection;
begin
  Result  := TX2INISettings.CreateInit(Self, ASection, FFilename);
end;


{========================= TX2INISettings
  Initialization
========================================}
constructor TX2INISettings.CreateInit;
begin
  inherited Create(AFactory, ASection);

  FData     := TMemIniFile.Create(AFilename);
  FSection  := ASection;
end;

destructor TX2INISettings.Destroy;
begin
  FData.UpdateFile();
  FreeAndNil(FData);

  inherited;
end;


{========================= TX2INISettings
  Read
========================================}
function TX2INISettings.InternalReadBool;
begin
  Result  := inherited InternalReadBool(AName, AValue);
  if Result then
    exit;

  Result  := ValueExists(AName);

  if Result then
    AValue  := FData.ReadBool(FSection, AName, False);
end;

function TX2INISettings.InternalReadFloat;
begin
  Result  := inherited InternalReadFloat(AName, AValue);
  if Result then
    exit;

  Result  := ValueExists(AName);

  if Result then
    AValue  := FData.ReadFloat(FSection, AName, 0);
end;

function TX2INISettings.InternalReadInteger;
begin
  Result  := inherited InternalReadInteger(AName, AValue);
  if Result then
    exit;

  Result  := ValueExists(AName);

  if Result then
    AValue  := FData.ReadInteger(FSection, AName, 0);
end;

function TX2INISettings.InternalReadString;
begin
  Result  := inherited InternalReadString(AName, AValue);
  if Result then
    exit;

  Result  := ValueExists(AName);

  if Result then
    AValue  := FData.ReadString(FSection, AName, '');
end;


{========================= TX2INISettings
  Write
========================================}
procedure TX2INISettings.InternalWriteBool;
begin
  inherited;
  FData.WriteBool(FSection, AName, AValue);
end;

procedure TX2INISettings.InternalWriteFloat;
begin
  inherited;
  FData.WriteFloat(FSection, AName, AValue);
end;

procedure TX2INISettings.InternalWriteInteger;
begin
  inherited;
  FData.WriteInteger(FSection, AName, AValue);
end;

procedure TX2INISettings.InternalWriteString;
begin
  inherited;
  FData.WriteString(FSection, AName, AValue);
end;


{========================= TX2INISettings
  Enumeration
========================================}
function TX2INISettings.ValueExists;
begin
  Result  := FData.ValueExists(FSection, AName);
end;


procedure TX2INISettings.GetSectionNames;
var
  slSections:       TStringList;
  slFound:          TStringList;
  iSection:         Integer;
  sCompare:         String;
  iCompareLen:      Integer;
  sSection:         String;
  iPos:             Integer;

begin
  sCompare    := FSection;
  iCompareLen := Length(sCompare);

  if iCompareLen > 0 then begin
    sCompare  := sCompare + '.';
    Inc(iCompareLen);
  end;

  slSections  := TStringList.Create();
  slFound     := TStringList.Create();
  try
    slFound.Sorted      := True;
    slFound.Duplicates  := dupIgnore;
    FData.ReadSections(slSections);

    // Filter out non-subsections
    for iSection  := slSections.Count - 1 downto 0 do
      if (iCompareLen = 0) or
         (SameText(sCompare, Copy(slSections[iSection], 1, iCompareLen))) then begin
        sSection  := slSections[iSection];

        Delete(sSection, 1, iCompareLen);
        iPos      := AnsiPos('.', sSection);

        if iPos > 0 then
          SetLength(sSection, iPos - 1);

        slFound.Add(sSection);
      end;

    ADest.AddStrings(slFound);
  finally
    FreeAndNil(slFound);
    FreeAndNil(slSections);
  end;
end;

procedure TX2INISettings.GetValueNames;
begin
  FData.ReadSection(FSection, ADest);
end;


{========================= TX2INISettings
  Delete
========================================}
procedure TX2INISettings.DeleteSection;
var
  slSections:       TStringList;
  iSection:         Integer;
  sCompare:         String;
  iCompareLen:      Integer;

begin
  sCompare    := FSection;
  iCompareLen := Length(sCompare);

  if iCompareLen > 0 then begin
    sCompare  := sCompare + '.';
    Inc(iCompareLen);
  end;

  slSections  := TStringList.Create();
  try
    // At first thought, parsing the sections again seems redundant, but it
    // eliminates the need for recursive calls, any section that matches the
    // start is automatically a sub-(sub-etc-)section of the current section.
    FData.ReadSections(slSections);

    for iSection  := slSections.Count - 1 downto 0 do
      if (iCompareLen = 0) or
         (SameText(sCompare, Copy(slSections[iSection], 1, iCompareLen))) then
        FData.EraseSection(slSections[iSection]);
  finally
    FreeAndNil(slSections);
  end;
  FData.EraseSection(FSection);
end;

procedure TX2INISettings.DeleteValue;
begin
  inherited;
  FData.DeleteKey(FSection, AName);
end;

end.
