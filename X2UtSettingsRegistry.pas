{
  :: X2UtSettingsRegistry extends X2UtSettings with registry reading/writing.
  ::
  :: Subversion repository available at:
  ::   $URL$
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtSettingsRegistry;

interface
uses
  Classes,
  Registry,
  Windows,
  X2UtSettings;

type
  {
    :$ Registry-based settings implementation

    :: It is highly recommended to create instances using
    :: TX2RegistrySettingsFactory instead of directly.
  }
  TX2RegistrySettings         = class(TX2Settings)
  private
    FData:        TRegistry;
    FKey:         String;
    FOpen:        Boolean;
    FReadOnly:    Boolean;

    function OpenRead(): Boolean;
    function OpenWrite(): Boolean;
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
                           const AKey, ASection: String;
                           const ARoot: Cardinal);
    destructor Destroy(); override;
  end;

  {
    :$ Factory for Registry-based settings

    :: Before use, assign Root and Key to valid values.
  }
  TX2RegistrySettingsFactory  = class(TX2SettingsFactory)
  private
    FKey:           String;
    FRoot:          HKEY;
  protected
    function GetSection(const ASection: String): TX2Settings; override;
  public
    //:$ Specifies the base registry key
    property Key:           String    read FKey     write FKey;

    //:$ Specifies the root key
    property Root:          HKEY      read FRoot    write FRoot;
  end;

implementation
uses
  SysUtils;

{============= TX2RegistrySettingsFactory
  Section
========================================}
function TX2RegistrySettingsFactory.GetSection;
begin
  Result  := TX2RegistrySettings.CreateInit(Self, FKey, ASection, FRoot);
end;


{==================== TX2RegistrySettings
  Initialization
========================================}
constructor TX2RegistrySettings.CreateInit;
begin
  inherited Create(AFactory, ASection);

  FData         := TRegistry.Create();
  FData.RootKey := ARoot;

  FKey          := IncludeTrailingPathDelimiter(AKey) +
                      StringReplace(ASection, '.', '\', [rfReplaceAll]);
end;

destructor TX2RegistrySettings.Destroy;
begin
  FreeAndNil(FData);

  inherited;
end;


function TX2RegistrySettings.OpenRead;
begin
  if not FOpen then begin
    FReadOnly := True;
    FOpen     := FData.OpenKey(FKey, False);
  end;

  Result  := FOpen;
end;

function TX2RegistrySettings.OpenWrite;
begin
  if (FOpen) and (FReadOnly) then begin
    FData.CloseKey();
    FOpen := False;
  end;

  if not FOpen then begin
    FReadOnly := False;
    FOpen     := FData.OpenKey(FKey, True);
  end;

  Result  := FOpen;
end;


{==================== TX2RegistrySettings
  Read
========================================}
function TX2RegistrySettings.InternalReadBool;
begin
  Result  := False;

  if OpenRead() then
  begin
    Result  := ValueExists(AName);

    if Result then
      AValue  := FData.ReadBool(AName);
  end;
end;

function TX2RegistrySettings.InternalReadFloat;
begin
  Result  := False;

  if OpenRead() then
  begin
    Result  := ValueExists(AName);

    if Result then
      AValue  := FData.ReadFloat(AName);
  end;
end;

function TX2RegistrySettings.InternalReadInteger;
begin
  Result  := False;

  if OpenRead() then
  begin
    Result  := ValueExists(AName);

    if Result then
      AValue  := FData.ReadInteger(AName);
  end;
end;

function TX2RegistrySettings.InternalReadString;
begin
  Result  := False;

  if OpenRead() then
  begin
    Result  := ValueExists(AName);

    if Result then
      AValue  := FData.ReadString(AName);
  end;
end;


{==================== TX2RegistrySettings
  Write
========================================}
procedure TX2RegistrySettings.InternalWriteBool;
begin
  if OpenWrite() then
    FData.WriteBool(AName, AValue);
end;

procedure TX2RegistrySettings.InternalWriteFloat;
begin
  if OpenWrite() then
    FData.WriteFloat(AName, AValue);
end;

procedure TX2RegistrySettings.InternalWriteInteger;
begin
  if OpenWrite() then
    FData.WriteInteger(AName, AValue);
end;

procedure TX2RegistrySettings.InternalWriteString;
begin
  if OpenWrite() then
    FData.WriteString(AName, AValue);
end;


{==================== TX2RegistrySettings
  Enumeration
========================================}
procedure TX2RegistrySettings.GetSectionNames;
begin
  if OpenRead() then
    FData.GetKeyNames(ADest);
end;


procedure TX2RegistrySettings.GetValueNames;
begin
  if OpenRead() then
    FData.GetValueNames(ADest);
end;


{==================== TX2RegistrySettings
  Delete
========================================}
procedure TX2RegistrySettings.DeleteSection;
begin
  // On Delphi 6 at least DeleteKey recursively calls itself for subkeys,
  // eliminating issues with WinNT based systems. Might need to verify
  // for Delphi 5 or lower if it's ever used.
  FData.CloseKey();
  FData.DeleteKey(FKey);
  FOpen := False;
end;

procedure TX2RegistrySettings.DeleteValue;
begin
  if OpenRead() then
    if FData.ValueExists(AName) then
      FData.DeleteValue(AName);
end;

function TX2RegistrySettings.ValueExists;
begin
  Result  := False;
  
  if OpenRead() then
    Result  := FData.ValueExists(AName);
end;

end.
