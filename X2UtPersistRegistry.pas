unit X2UtPersistRegistry;

interface
uses
  Classes,
  Registry,
  Windows,

  X2UtPersist;

  
type
  TX2UtPersistRegistry = class(TX2CustomPersist)
  private
    FKey:       String;
    FRootKey:   HKEY;

    FRegistry:  TRegistry;
    FReading:   Boolean;
  protected
    procedure InitRegistry(AReading: Boolean);
    procedure FinalizeRegistry();

    function OpenKey(const ANewKey: String): Boolean;

    function DoRead(AObject: TObject): Boolean; override;
    procedure DoWrite(AObject: TObject); override;

    function BeginSection(const AName: String): Boolean; override;
    procedure EndSection(); override;

    
    function ReadInteger(const AName: String; out AValue: Integer): Boolean; override;
    function ReadFloat(const AName: String; out AValue: Extended): Boolean; override;
    function ReadString(const AName: String; out AValue: String): Boolean; override;
    function ReadInt64(const AName: String; out AValue: Int64): Boolean; override;


    function WriteInteger(const AName: String; AValue: Integer): Boolean; override;
    function WriteFloat(const AName: String; AValue: Extended): Boolean; override;
    function WriteString(const AName, AValue: String): Boolean; override;
    function WriteInt64(const AName: String; AValue: Int64): Boolean; override;

    procedure ClearCollection(); override;

    property Registry:    TRegistry read FRegistry;
  public
    constructor Create();
    destructor Destroy(); override;
    
    property Key:       String  read FKey     write FKey;
    property RootKey:   HKEY    read FRootKey write FRootKey;
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


destructor TX2UtPersistRegistry.Destroy();
begin
  inherited;
end;


procedure TX2UtPersistRegistry.InitRegistry(AReading: Boolean);
begin
  FReading  := AReading;

  if AReading then
    FRegistry := TRegistry.Create(KEY_READ)
  else
    FRegistry := TRegistry.Create();

  FRegistry.RootKey := Self.RootKey;
end;


procedure TX2UtPersistRegistry.FinalizeRegistry();
begin
  FreeAndNil(FRegistry);
end;


function TX2UtPersistRegistry.OpenKey(const ANewKey: String): Boolean;
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
   if FReading then
      Result  := FRegistry.OpenKeyReadOnly(keyName)
    else
      Result  := FRegistry.OpenKey(keyName, True);
  end else
    Result  := False;
end;


function TX2UtPersistRegistry.DoRead(AObject: TObject): Boolean;
begin
  InitRegistry(True);
  try
    OpenKey('');
    Result  := inherited DoRead(AObject);
  finally
    FinalizeRegistry();
  end;
end;


procedure TX2UtPersistRegistry.DoWrite(AObject: TObject);
begin
  InitRegistry(False);
  try
    OpenKey('');
    inherited DoWrite(AObject);
  finally
    FinalizeRegistry();
  end;
end;


function TX2UtPersistRegistry.BeginSection(const AName: String): Boolean;
begin
  Result  := OpenKey(AName);

  if Result then
    inherited BeginSection(AName);
end;


procedure TX2UtPersistRegistry.EndSection();
begin
  inherited;

  { Re-open the previous section }
  OpenKey('');
end;


function TX2UtPersistRegistry.ReadInteger(const AName: String; out AValue: Integer): Boolean;
begin
  Result  := Registry.ValueExists(AName);
  if Result then
    AValue  := Registry.ReadInteger(AName);
end;


function TX2UtPersistRegistry.ReadFloat(const AName: String; out AValue: Extended): Boolean;
begin
  Result  := Registry.ValueExists(AName);
  if Result then
    AValue  := Registry.ReadFloat(AName);
end;


function TX2UtPersistRegistry.ReadString(const AName: String; out AValue: String): Boolean;
begin
  Result  := Registry.ValueExists(AName);
  if Result then
    AValue  := Registry.ReadString(AName);
end;


function TX2UtPersistRegistry.ReadInt64(const AName: String; out AValue: Int64): Boolean;
begin
  Result  := (Registry.GetDataSize(AName) = SizeOf(AValue));
  if Result then
    Registry.ReadBinaryData(AName, AValue, SizeOf(AValue));
end;


function TX2UtPersistRegistry.WriteInteger(const AName: String; AValue: Integer): Boolean;
begin
  Registry.WriteInteger(AName, AValue);
  Result  := True;
end;


function TX2UtPersistRegistry.WriteFloat(const AName: String; AValue: Extended): Boolean;
begin
  Registry.WriteFloat(AName, AValue);
  Result  := True;
end;


function TX2UtPersistRegistry.WriteString(const AName, AValue: String): Boolean;
begin
  Registry.WriteString(AName, AValue);
  Result  := True;
end;


function TX2UtPersistRegistry.WriteInt64(const AName: String; AValue: Int64): Boolean;
begin
  Registry.WriteBinaryData(AName, AValue, SizeOf(AValue));
  Result  := True;
end;


procedure TX2UtPersistRegistry.ClearCollection();
var
  keyNames:   TStringList;
  keyIndex:   Integer;

begin
  inherited;

  keyNames  := TStringList.Create();
  try
    Registry.GetKeyNames(keyNames);

    for keyIndex := 0 to Pred(keyNames.Count) do
      if SameTextS(keyNames[keyIndex], CollectionItemNamePrefix) then
        Registry.DeleteKey(keyNames[keyIndex]);
  finally
    FreeAndNil(keyNames);
  end;
end;

end.

