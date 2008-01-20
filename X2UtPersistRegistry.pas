{
  :: X2UtPersistRegistry implements persistency to the Windows   Registry.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtPersistRegistry;

interface
uses
  Classes,
  Registry,
  Windows,

  X2UtPersist,
  X2UtPersistIntf;


type
  TX2UtPersistRegistry = class(TX2CustomPersist)
  private
    FKey:       String;
    FRootKey:   HKEY;
  protected
    function CreateFiler(AIsReader: Boolean): IX2PersistFiler; override;
  public
    constructor Create();

    property Key:       String  read FKey     write FKey;
    property RootKey:   HKEY    read FRootKey write FRootKey;
  end;


  TX2UtPersistRegistryFiler = class(TX2CustomPersistFiler)
  private
    FKey:       String;
    FRegistry:  TRegistry;
  protected
    function OpenKey(const ANewKey: String): Boolean;
  public
    function BeginSection(const AName: String): Boolean; override;
    procedure EndSection(); override;


    procedure GetKeys(const ADest: TStrings); override;
    procedure GetSections(const ADest: TStrings); override;

    
    function ReadInteger(const AName: String; out AValue: Integer): Boolean; override;
    function ReadFloat(const AName: String; out AValue: Extended): Boolean; override;
    function ReadString(const AName: String; out AValue: String): Boolean; override;
    function ReadInt64(const AName: String; out AValue: Int64): Boolean; override;

    function ReadStream(const AName: string; AStream: TStream): Boolean; override;


    function WriteInteger(const AName: String; AValue: Integer): Boolean; override;
    function WriteFloat(const AName: String; AValue: Extended): Boolean; override;
    function WriteString(const AName, AValue: String): Boolean; override;
    function WriteInt64(const AName: String; AValue: Int64): Boolean; override;

    function WriteStream(const AName: string; AStream: TStream): Boolean; override;

    procedure DeleteKey(const AName: string); override;
    procedure DeleteSection(const AName: string); override;

    
    property Key:         String    read FKey;
    property Registry:    TRegistry read FRegistry;
  public
    constructor Create(AIsReader: Boolean; ARootKey: HKEY; const AKey: String);
    destructor Destroy(); override;
  end;


  { Wrapper functions }
  function ReadFromRegistry(AObject: TObject; const AKey: String; ARootKey: HKEY = HKEY_CURRENT_USER): Boolean;
  procedure WriteToRegistry(AObject: TObject; const AKey: String; ARootKey: HKEY = HKEY_CURRENT_USER);


implementation
uses
  SysUtils,

  X2UtStrings;
  

const
  RegistrySeparator = '\';


{ Wrapper functions }
function ReadFromRegistry(AObject: TObject; const AKey: String; ARootKey: HKEY): Boolean;
begin
  with TX2UtPersistRegistry.Create() do
  try
    RootKey := ARootKey;
    Key     := AKey;
    Result  := Read(AObject);
  finally
    Free();
  end;
end;


procedure WriteToRegistry(AObject: TObject; const AKey: String; ARootKey: HKEY);
begin
  with TX2UtPersistRegistry.Create() do
  try
    RootKey := ARootKey;
    Key     := AKey;
    Write(AObject);
  finally
    Free();
  end;
end;


{ TX2UtPersistRegistry }
constructor TX2UtPersistRegistry.Create();
begin
  inherited;
  
  FRootKey  := HKEY_CURRENT_USER;
end;


function TX2UtPersistRegistry.CreateFiler(AIsReader: Boolean): IX2PersistFiler;
begin
  Result  := TX2UtPersistRegistryFiler.Create(AIsReader, Self.RootKey, Self.Key);
end;


{ TX2UtPersistRegistry }
constructor TX2UtPersistRegistryFiler.Create(AIsReader: Boolean; ARootKey: HKEY; const AKey: String);
begin
  inherited Create(AIsReader);

  if AIsReader then
    FRegistry := TRegistry.Create(KEY_READ)
  else
    FRegistry := TRegistry.Create();

  FRegistry.RootKey := ARootKey;
  FKey              := AKey;

  OpenKey('');
end;


destructor TX2UtPersistRegistryFiler.Destroy();
begin
  FreeAndNil(FRegistry);

  inherited;
end;


function TX2UtPersistRegistryFiler.OpenKey(const ANewKey: String): Boolean;
var
  keyName: String;
  sectionIndex: Integer;

begin
  keyName := Self.Key;
  if (Length(keyName) > 0) and (keyName[Length(keyName)] = RegistrySeparator) then
    SetLength(keyName, Pred(Length(keyName)));


  for sectionIndex := 0 to Pred(Sections.Count) do
    keyName := keyName + RegistrySeparator + Sections[sectionIndex];

  if Length(ANewKey) > 0 then
    keyName := keyName + RegistrySeparator + ANewKey;


  if Length(keyName) > 0 then
  begin
   if IsReader then
      Result  := FRegistry.OpenKeyReadOnly(keyName)
    else
      Result  := FRegistry.OpenKey(keyName, True);
  end else
    Result  := False;
end;


function TX2UtPersistRegistryFiler.BeginSection(const AName: String): Boolean;
begin
  Result  := OpenKey(AName);

  if Result then
    inherited BeginSection(AName);
end;


procedure TX2UtPersistRegistryFiler.EndSection();
begin
  inherited;

  { Re-open the previous section }
  OpenKey('');
end;


procedure TX2UtPersistRegistryFiler.GetKeys(const ADest: TStrings);
begin
  Registry.GetValueNames(ADest);
end;


procedure TX2UtPersistRegistryFiler.GetSections(const ADest: TStrings);
begin
  Registry.GetKeyNames(ADest);
end;


function TX2UtPersistRegistryFiler.ReadInteger(const AName: String; out AValue: Integer): Boolean;
begin
  AValue  := 0;
  Result  := Registry.ValueExists(AName);
  if Result then
    AValue  := Registry.ReadInteger(AName);
end;


function TX2UtPersistRegistryFiler.ReadFloat(const AName: String; out AValue: Extended): Boolean;
begin
  AValue  := 0;
  Result  := Registry.ValueExists(AName);
  if Result then
    AValue  := Registry.ReadFloat(AName);
end;


function TX2UtPersistRegistryFiler.ReadStream(const AName: string; AStream: TStream): Boolean;
var
  bufferSize:     Integer;
  buffer:         PChar;

begin
  Result  := Registry.ValueExists(AName);
  if Result then
  begin
    bufferSize  := Registry.GetDataSize(AName);

    if bufferSize > 0 then
    begin
      AStream.Size  := 0;

      GetMem(buffer, bufferSize);
      try
        Registry.ReadBinaryData(AName, buffer^, bufferSize);
        AStream.WriteBuffer(buffer^, bufferSize);
      finally
        FreeMem(buffer, bufferSize);
      end;
    end;
  end;
end;


function TX2UtPersistRegistryFiler.ReadString(const AName: String; out AValue: String): Boolean;
begin
  AValue  := '';
  Result  := Registry.ValueExists(AName);
  if Result then
  begin
    { Required for conversion of integer-based booleans }
    if Registry.GetDataType(AName) = rdInteger then
      AValue  := BoolToStr(Registry.ReadBool(AName), True)
    else
      AValue  := Registry.ReadString(AName);
  end;
end;


function TX2UtPersistRegistryFiler.ReadInt64(const AName: String; out AValue: Int64): Boolean;
begin
  AValue  := 0;
  Result  := (Registry.GetDataSize(AName) = SizeOf(AValue));
  if Result then
    Registry.ReadBinaryData(AName, AValue, SizeOf(AValue));
end;


function TX2UtPersistRegistryFiler.WriteInteger(const AName: String; AValue: Integer): Boolean;
begin
  Registry.WriteInteger(AName, AValue);
  Result  := True;
end;


function TX2UtPersistRegistryFiler.WriteFloat(const AName: String; AValue: Extended): Boolean;
begin
  Registry.WriteFloat(AName, AValue);
  Result  := True;
end;


function TX2UtPersistRegistryFiler.WriteStream(const AName: string; AStream: TStream): Boolean;
var
  bufferSize:     Integer;
  buffer:         PChar;

begin
  Result            := False;
  AStream.Position  := 0;
  bufferSize        := AStream.Size;

  if bufferSize > 0 then
  begin
    GetMem(buffer, bufferSize);
    try
      AStream.ReadBuffer(buffer^, bufferSize);
      Registry.WriteBinaryData(AName, buffer^, bufferSize);
    finally
      FreeMem(buffer, bufferSize);
    end;

    Result  := True;
  end;
end;


function TX2UtPersistRegistryFiler.WriteString(const AName, AValue: String): Boolean;
begin
  Registry.WriteString(AName, AValue);
  Result  := True;
end;


function TX2UtPersistRegistryFiler.WriteInt64(const AName: String; AValue: Int64): Boolean;
begin
  Registry.WriteBinaryData(AName, AValue, SizeOf(AValue));
  Result  := True;
end;


procedure TX2UtPersistRegistryFiler.DeleteKey(const AName: string);
begin
  Registry.DeleteValue(AName);
end;


procedure TX2UtPersistRegistryFiler.DeleteSection(const AName: string);
begin
  Registry.DeleteKey(AName);
end;

end.

