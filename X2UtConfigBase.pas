{
  :: X2UtConfigBase provides the base implementation for various
  :: configuration sources.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtConfigBase;

interface
uses
  Classes,
  
  X2UtConfig,
  X2UtHashes;

type
  // Forward declarations
  TX2BaseConfigSource     = class;
  TX2BaseConfig           = class;
  TX2ConfigValueHash      = class;
  TX2ConfigHash           = class;
  TX2ConfigDefinitionHash = class;

  TX2StreamConfigSource   = class;

  TX2ConfigState          = (csClean, csCreate, csUpdate, csDelete);

  {
    :$ Default implementation for configuration sources.
  }
  TX2BaseConfigSource = class(TInterfacedObject, IX2ConfigSource)
  private
    FAutoSave:        Boolean;
    FConfigItems:     TX2ConfigHash;
    FDefinitions:     TX2ConfigDefinitionHash;
  protected
    function GetConfig(const AName: String;
                       const AAllowCreate: Boolean = True): TX2BaseConfig; virtual;

    procedure LoadConfigs(); virtual; abstract;
    function CreateConfig(const AName: String): TX2BaseConfig; virtual; abstract;

    property ConfigItems:     TX2ConfigHash read FConfigItems;
  public
    constructor Create();
    destructor Destroy(); override;

    // IX2ConfigSource
    function GetAutoSave(): Boolean;
    procedure SetAutoSave(Value: Boolean);

    procedure Reload(); virtual;
    procedure Save(); overload; virtual; abstract;
    procedure Save(const AStream: TStream); overload; virtual; abstract;

    function Configs(const AName: String): IX2Config; virtual;
    function Exists(const AName: String): Boolean; virtual;

    procedure Delete(const AName: String); virtual;
    procedure Clear(const AAction: TX2ConfigClearAction); virtual;

    procedure Iterate(const ACallback: TX2ConfigIterateConfigs;
                      const AData: Pointer);

    function Register(const AConfig, AName: String): IX2ConfigDefinition; overload;
    function Register(const AConfig, AName: String;
                      const ADefault: Variant): IX2ConfigDefinition; overload;
    function Definitions(const AConfig, AName: String): IX2ConfigDefinition;

    property AutoSave:      Boolean read GetAutoSave  write SetAutoSave;
  end;

  {
    :$ Default implementation for configurations.
  }
  TX2BaseConfig = class(TObject, IInterface, IX2Config)
  private
    FName:            String;
    FSource:          TX2BaseConfigSource;
    FState:           TX2ConfigState;
    FValues:          TX2ConfigValueHash;
  protected
    // IInterface
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef(): Integer; stdcall;
    function _Release(): Integer; stdcall;

    function InternalRead(const AName: String; const ADefault: Variant;
                          const AUseDefinition: Boolean): Variant; virtual;
    procedure InternalWrite(const AName: String; const AValue: Variant;
                            const AUpdateState: Boolean = True); virtual;

    property Values:        TX2ConfigValueHash  read FValues;
  public
    constructor Create(const AName: String; const ASource: TX2BaseConfigSource); virtual;
    destructor Destroy(); override;

    // IX2Config
    function GetName(): String;
    function GetSource(): IX2ConfigSource;

    function Exists(const AName: String): Boolean; virtual;
    function Read(const AName: String): Variant; overload;
    function Read(const AName: String; const ADefault: Variant): Variant; overload;
    procedure Write(const AName: String; const AValue: Variant); virtual;

    procedure Delete(const AName: String); virtual;
    procedure Clear(const AAction: TX2ConfigClearAction); virtual;

    procedure Iterate(const ACallback: TX2ConfigIterateValues;
                      const AData: Pointer);

    property Name:      String          read GetName;
    property Source:    IX2ConfigSource read GetSource;
    property State:     TX2ConfigState  read FState   write FState;
  end;

  {
    :$ Default implementation for value definitions.
  }
  TX2ConfigDefinition = class(TObject, IInterface, IX2ConfigDefinition)
  private
    FConfig:          String;
    FName:            String;
    FDefault:         Variant;
    FObservers:       TInterfaceList;
  protected
    // IInterface
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef(): Integer; stdcall;
    function _Release(): Integer; stdcall;

    // IX2ConfigDefinition
    function GetDefault(): Variant;
    function GetConfig(): String;
    function GetName(): String;
    procedure SetDefault(Value: Variant);

    procedure Attach(const AObserver: IX2ConfigDefinitionObserver);
    procedure Detach(const AObserver: IX2ConfigDefinitionObserver);

    procedure Read(var AValue: Variant);
    procedure Write(var AValue: Variant);
    
    property Default:   Variant read GetDefault write SetDefault;
    property Config:    String  read GetConfig;
    property Name:      String  read GetName;
  public
    constructor Create(const AConfig, AName: String; const ADefault: Variant);
    destructor Destroy(); override;
  end;

  {
    :$ Internal representation of a value.
  }
  PX2ConfigValue  = ^TX2ConfigValue;
  TX2ConfigValue  = record
    Value:      Variant;
    State:      TX2ConfigState;
  end;

  {
    :$ Hash for configuration values.
  }
  TX2ConfigValueHash  = class(TX2SPHash)
  protected
    function GetCurrentValue(): PX2ConfigValue;
    function GetValue(Key: String): PX2ConfigValue;
    procedure SetValue(Key: String; const Value: PX2ConfigValue);
  public
    property CurrentValue:            PX2ConfigValue  read GetCurrentValue;
    property Values[Key: String]:     PX2ConfigValue  read GetValue       write SetValue; default;
  end;

  {
    :$ Hash for configuration objects.
  }
  TX2ConfigHash = class(TX2SOHash)
  protected
    function GetCurrentValue(): TX2BaseConfig;
    function GetValue(Key: String): TX2BaseConfig;
    procedure SetValue(Key: String; const Value: TX2BaseConfig);
  public
    property CurrentValue:            TX2BaseConfig read GetCurrentValue;
    property Values[Key: String]:     TX2BaseConfig read GetValue       write SetValue; default;
  end;

  {
    :$ Hash for value definitions.
  }
  TX2ConfigDefinitionHash = class(TX2SOHash)
  protected
    function GetCurrentValue(): TX2ConfigDefinition;
    function GetValue(Key: String): TX2ConfigDefinition;
    procedure SetValue(Key: String; const Value: TX2ConfigDefinition);
  public
    property CurrentValue:            TX2ConfigDefinition read GetCurrentValue;
    property Values[Key: String]:     TX2ConfigDefinition read GetValue       write SetValue; default;
  end;

  {
    :$ Default implementation for stream-based configuration sources.
  }
  TX2StreamConfigSource = class(TX2BaseConfigSource)
  private
    FFileName:        String;
  protected
    procedure LoadConfigs(); override;

    procedure LoadFromFile(const AFileName: String); virtual;
    procedure LoadFromStream(const AStream: TStream); virtual; abstract;

    property FileName:    String  read FFileName;
  public
    constructor Create(const AStream: TStream); overload;
    constructor Create(const AFileName: String); overload;

    procedure Save(); override;
  end;

implementation
uses
  SysUtils,
  Variants;


{========================================
  TX2BaseConfigSource
========================================}
constructor TX2BaseConfigSource.Create();
begin
  inherited;

  FConfigItems  := TX2ConfigHash.Create(True);
  FDefinitions  := TX2ConfigDefinitionHash.Create(True);
  LoadConfigs();
end;

destructor TX2BaseConfigSource.Destroy();
begin
  FreeAndNil(FDefinitions);
  FreeAndNil(FConfigItems);
  
  inherited;
end;


function TX2BaseConfigSource.GetConfig(const AName: String;
                                       const AAllowCreate: Boolean): TX2BaseConfig;
begin
  Result  := ConfigItems[AName];
  if Assigned(Result) then
  begin
    if Result.State = csDelete then
      if AAllowCreate then
        Result.State  := csClean
      else
        Result        := nil;
  end else if AAllowCreate then
  begin
    Result              := CreateConfig(AName);
    ConfigItems[AName]  := Result;
  end; 
end;


function TX2BaseConfigSource.GetAutoSave(): Boolean;
begin
  Result  := FAutoSave;
end;

procedure TX2BaseConfigSource.SetAutoSave(Value: Boolean);
begin
  FAutoSave := Value;
end;

procedure TX2BaseConfigSource.Reload();
begin
  ConfigItems.Clear();
  LoadConfigs();
end;

function TX2BaseConfigSource.Configs(const AName: String): IX2Config;
begin
  Result  := (GetConfig(AName) as IX2Config);
end;

function TX2BaseConfigSource.Exists(const AName: String): Boolean;
var
  pConfig:      TX2BaseConfig;

begin
  pConfig := ConfigItems[AName];
  Result  := Assigned(pConfig) and (pConfig.State <> csDelete);
end;

procedure TX2BaseConfigSource.Delete(const AName: String);
var
  pConfig:      TX2BaseConfig;

begin
  pConfig := ConfigItems[AName];
  if Assigned(pConfig) then
    pConfig.State := csDelete;
end;

procedure TX2BaseConfigSource.Clear(const AAction: TX2ConfigClearAction);
begin
  //! Clear
end;

procedure TX2BaseConfigSource.Iterate(const ACallback: TX2ConfigIterateConfigs;
                                      const AData: Pointer);
begin
  ConfigItems.First();
  while ConfigItems.Next() do
    ACallback(Self, ConfigItems.CurrentKey, AData);
end;

function TX2BaseConfigSource.Register(const AConfig,
                                      AName: String): IX2ConfigDefinition;
begin
  Result  := Register(AConfig, AName, Unassigned);
end;

function TX2BaseConfigSource.Register(const AConfig, AName: String;
                                      const ADefault: Variant): IX2ConfigDefinition;
var
  sKey:             String;
  pDefinition:      TX2ConfigDefinition;

begin
  sKey    := AConfig + #255 + AName;
  Result  := FDefinitions[sKey];
  if not Assigned(Result) then
  begin
    pDefinition         := TX2ConfigDefinition.Create(AConfig, AName, ADefault);
    FDefinitions[sKey]  := pDefinition;
    Result              := (pDefinition as IX2ConfigDefinition);
  end;
end;

function TX2BaseConfigSource.Definitions(const AConfig,
                                         AName: String): IX2ConfigDefinition;
var
  sKey:             String;

begin
  sKey    := AConfig + #255 + AName;
  Result  := FDefinitions[sKey];
end;


{========================================
  TX2BaseConfig
========================================}
constructor TX2BaseConfig.Create(const AName: String;
                                 const ASource: TX2BaseConfigSource);
begin
  inherited Create();

  FName   := AName;
  FSource := ASource;
  FValues := TX2ConfigValueHash.Create();
  FState  := csClean;
end;

destructor TX2BaseConfig.Destroy();
var
  pValue:       PX2ConfigValue;

begin
  Values.First();
  while Values.Next() do
  begin
    pValue  := Values.CurrentValue;
    Finalize(pValue^);
    FreeMem(pValue, SizeOf(TX2ConfigValue));
  end;

  FreeAndNil(FValues);

  inherited;
end;


function TX2BaseConfig.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TX2BaseConfig._AddRef(): Integer;
begin
  Result  := -1;
end;

function TX2BaseConfig._Release(): Integer;
begin
  Result  := -1;
end;


function TX2BaseConfig.InternalRead(const AName: String;
                                    const ADefault: Variant;
                                    const AUseDefinition: Boolean): Variant;
var
  ifDefinition:   IX2ConfigDefinition;
  pValue:         PX2ConfigValue;

begin
  Result        := Unassigned;
  ifDefinition  := Source.Definitions(FName, AName);
  pValue        := Values[AName];
  if Assigned(pValue) and (pValue^.State <> csDelete) then
    Result  := pValue^.Value
  else
    if AUseDefinition and (Assigned(ifDefinition)) then
      Result  := ifDefinition.Default
    else
      Result  := ADefault;

  // Observers
  if Assigned(ifDefinition) then
    ifDefinition.Read(Result);
end;

procedure TX2BaseConfig.InternalWrite(const AName: String;
                                      const AValue: Variant;
                                      const AUpdateState: Boolean);
var
  bSave:            Boolean;
  ifDefinition:     IX2ConfigDefinition;
  pValue:           PX2ConfigValue;
  vValue:           Variant;

begin
  // Observers
  vValue        := AValue;
  ifDefinition  := Source.Definitions(FName, AName);
  if Assigned(ifDefinition) then
    ifDefinition.Write(vValue);

  bSave   := False;
  pValue  := Values[AName];
  if not Assigned(pValue) then
  begin
    GetMem(pValue, SizeOf(TX2ConfigValue));
    Initialize(pValue^);
    pValue^.Value   := vValue;

    if AUpdateState then
      pValue^.State   := csCreate
    else
      pValue^.State   := csClean;

    Values[AName]   := pValue;
    bSave           := True;
  end else if AValue <> pValue^.Value then
  begin
    pValue^.Value   := vValue;
    bSave           := True;
  end;

  if bSave then
  begin
    if AUpdateState then
    begin
      if FState <> csCreate then
        FState        := csUpdate;

      if pValue^.State <> csCreate then
        pValue^.State   := csUpdate;
    end;

    if Source.AutoSave then
      Source.Save();
  end;
end;


function TX2BaseConfig.GetName(): String;
begin
  Result  := FName;
end;

function TX2BaseConfig.GetSource(): IX2ConfigSource;
begin
  Result  := (FSource as IX2ConfigSource);
end;

function TX2BaseConfig.Exists(const AName: String): Boolean;
var
  pValue:     PX2ConfigValue;

begin
  pValue  := Values[AName];
  Result  := Assigned(pValue) and (pValue.State <> csDelete);
end;

function TX2BaseConfig.Read(const AName: String): Variant;
begin
  Result  := InternalRead(AName, Unassigned, True);
end;

function TX2BaseConfig.Read(const AName: String;
                            const ADefault: Variant): Variant;
begin
  Result  := InternalRead(AName, ADefault, False);
end;

procedure TX2BaseConfig.Write(const AName: String; const AValue: Variant);
begin
  InternalWrite(AName, AValue);
end;

procedure TX2BaseConfig.Clear(const AAction: TX2ConfigClearAction);
begin
  //! Clear
end;

procedure TX2BaseConfig.Iterate(const ACallback: TX2ConfigIterateValues;
                                const AData: Pointer);
begin
  Values.First();
  while Values.Next() do
    ACallback(Self, Values.CurrentKey, AData);
end;

procedure TX2BaseConfig.Delete(const AName: String);
var
  pValue:     PX2ConfigValue;

begin
  pValue  := Values[AName];
  if Assigned(pValue) then
    if pValue^.State = csCreate then
    begin
      Finalize(pValue^);
      FreeMem(pValue, SizeOf(TX2ConfigValue));
      Values.Delete(AName);
    end else
      pValue^.State := csDelete;
end;


{========================================
  TX2ConfigHash
========================================}
function TX2ConfigHash.GetCurrentValue(): TX2BaseConfig;
begin
  Result  := TX2BaseConfig(inherited GetCurrentValue());
end;

function TX2ConfigHash.GetValue(Key: String): TX2BaseConfig;
begin
  Result  := TX2BaseConfig(inherited GetValue(Key));
end;

procedure TX2ConfigHash.SetValue(Key: String; const Value: TX2BaseConfig);
begin
  inherited SetValue(Key, Value);
end;


{========================================
  TX2ConfigValueHash
========================================}
function TX2ConfigValueHash.GetCurrentValue(): PX2ConfigValue;
begin
  Result  := PX2ConfigValue(inherited GetCurrentValue());
end;

function TX2ConfigValueHash.GetValue(Key: String): PX2ConfigValue;
begin
  Result  := PX2ConfigValue(inherited GetValue(Key));
end;

procedure TX2ConfigValueHash.SetValue(Key: String; const Value: PX2ConfigValue);
begin
  inherited SetValue(Key, Value);
end;


{========================================
  TX2ConfigDefinitionHash
========================================}
function TX2ConfigDefinitionHash.GetCurrentValue(): TX2ConfigDefinition;
begin
  Result  := TX2ConfigDefinition(inherited GetCurrentValue());
end;

function TX2ConfigDefinitionHash.GetValue(Key: String): TX2ConfigDefinition;
begin
  Result  := TX2ConfigDefinition(inherited GetValue(Key));
end;

procedure TX2ConfigDefinitionHash.SetValue(Key: String;
                                           const Value: TX2ConfigDefinition);
begin
  inherited SetValue(Key, Value);
end;


{========================================
  TX2StreamConfigSource
========================================}
constructor TX2StreamConfigSource.Create(const AFileName: String);
begin
  inherited Create();

  FFileName := AFileName;
  LoadFromFile(AFileName);
end;

constructor TX2StreamConfigSource.Create(const AStream: TStream);
begin
  inherited Create();

  FFileName := '';
  LoadFromStream(AStream);
end;


procedure TX2StreamConfigSource.LoadConfigs();
begin
  if Length(FFileName) > 0 then
    LoadFromFile(FFileName);
end;


procedure TX2StreamConfigSource.LoadFromFile(const AFileName: String);
var
  fsData:     TFileStream;

begin
  fsData    := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(fsData);
  finally
    FreeAndNil(fsData);
  end;
end;

procedure TX2StreamConfigSource.Save();
var
  fsData:     TFileStream;

begin
  if Length(FFileName) > 0 then
  begin
    fsData    := TFileStream.Create(FFileName, fmCreate or fmShareExclusive);
    try
      Save(fsData);
    finally
      FreeAndNil(fsData);
    end;
  end;
end;


{========================================
  TX2ConfigDefinition
========================================}
constructor TX2ConfigDefinition.Create(const AConfig, AName: String;
                                       const ADefault: Variant);
begin
  inherited Create();

  FConfig   := AConfig;
  FName     := AName;
  FDefault  := ADefault;
end;

destructor TX2ConfigDefinition.Destroy();
begin
  FreeAndNil(FObservers);

  inherited;
end;


function TX2ConfigDefinition.QueryInterface(const IID: TGUID;
                                            out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TX2ConfigDefinition._AddRef(): Integer;
begin
  Result  := -1;
end;

function TX2ConfigDefinition._Release(): Integer;
begin
  Result  := -1;
end;


procedure TX2ConfigDefinition.Attach(const AObserver: IX2ConfigDefinitionObserver);
begin
  if not Assigned(FObservers) then
    FObservers  := TInterfaceList.Create();

  FObservers.Add(AObserver);
end;

procedure TX2ConfigDefinition.Detach(const AObserver: IX2ConfigDefinitionObserver);
begin
  if Assigned(FObservers) then
    FObservers.Remove(AObserver);
end;


procedure TX2ConfigDefinition.Read(var AValue: Variant);
var
  iObserver:        Integer;

begin
  if Assigned(FObservers) then
    for iObserver := 0 to Pred(FObservers.Count) do
      (FObservers[iObserver] as IX2ConfigDefinitionObserver).Read(FConfig, FName, AValue);
end;

procedure TX2ConfigDefinition.Write(var AValue: Variant);
var
  iObserver:        Integer;

begin
  if Assigned(FObservers) then
    for iObserver := 0 to Pred(FObservers.Count) do
      (FObservers[iObserver] as IX2ConfigDefinitionObserver).Write(FConfig, FName, AValue);
end;


function TX2ConfigDefinition.GetDefault(): Variant;
begin
  Result  := FDefault;
end;

function TX2ConfigDefinition.GetConfig(): String;
begin
  Result  := FConfig;
end;

function TX2ConfigDefinition.GetName(): String;
begin
  Result  := FName;
end;

procedure TX2ConfigDefinition.SetDefault(Value: Variant);
begin
  FDefault  := Value;
end;

end.
