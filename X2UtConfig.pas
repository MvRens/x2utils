{
  :: X2UtConfig provides a generic access mechanism for application settings.
  :: Create an instance of one of the TX2xxxConfigSource classes (such as
  :: TX2IniConfigSource in the X2UtConfigIni.pas unit) to gain access to an
  :: IX2ConfigSource interface.
  ::
  :: Though no actual code was ported, credits to Nini for .NET
  :: (http://nini.sourceforge.net/) for some excellent ideas. In fact,
  :: X2UtXMLConfigSource is capable of recognizing, reading and writing
  :: Nini-compatible XML files.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtConfig;

interface
uses
  Classes,

  X2UtHashes,
  X2UtHashesVariants;

type
  // Forward declarations
  IX2Config       = interface;
  IX2ConfigSource = interface;

  {
    :$ Callback for Iterate method.
  }
  TX2ConfigIterateMethod  = procedure(Sender: IX2ConfigSource;
                                      Config: IX2Config;
                                      var Abort: Boolean) of object;


  {
    :$ Interface for configurations.

    :: Implementations are highly recommended to descend from, or simply use,
    :: TX2BaseConfig.
  }
  IX2Config = interface
    ['{25DF95C1-CE09-44A7-816B-A33B8D0D78DC}']
    function GetName(): String;

    function ReadBool(const AName: String; const ADefault: Boolean = False): Boolean;
    function ReadFloat(const AName: String; const ADefault: Double = 0): Double;
    function ReadInteger(const AName: String; const ADefault: Integer = 0): Integer;
    function ReadString(const AName: String; const ADefault: String = ''): String;

    procedure WriteBool(const AName: String; AValue: Boolean);
    procedure WriteFloat(const AName: String; AValue: Double);
    procedure WriteInteger(const AName: String; AValue: Integer);
    procedure WriteString(const AName, AValue: String);

    procedure Clear();
    procedure Delete(const AName: String);
    function Exists(const AName: String): Boolean;

    procedure Save();

    property Name:      String  read GetName;
  end;

  {
    :$ Interface for configuration sources.

    :: For subsections, seperate each section name with a dot (.)
    ::
    :: Implementations are highly recommended to descend from
    :: TX2BaseConfigSource.
  }
  IX2ConfigSource = interface
    ['{1FF5282B-122F-47D7-95E8-3DB60A8CF765}']
    function GetAutoSave(): Boolean;
    procedure SetAutoSave(Value: Boolean);

    function Configs(const AName: String): IX2Config;

    function Add(const AName: String): IX2Config;
    function Exists(const AName: String): Boolean;
    procedure Delete(const AName: String);
    procedure Clear();

    procedure Save();

    procedure List(const AName: String; const ADest: TStrings;
                   const ARecurse: Boolean = False);
    procedure Iterate(const AName: String;
                      const ACallback: TX2ConfigIterateMethod;
                      const AData: Pointer;
                      const ARecurse: Boolean = False); overload;

    property AutoSave:      Boolean read GetAutoSave  write SetAutoSave;
  end;

  // Forward declarations
  TX2BaseConfig       = class;
  TX2BaseConfigSource = class;

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
    :$ Default implementation for configurations.
  }
  TX2BaseConfig = class(TInterfacedObject, IX2Config)
  private
    FConfigItems:     TX2ConfigHash;
    FName:            String;
    FSource:          IX2ConfigSource;
    FValues:          TX2SVHash;
  protected
    procedure WriteValue(const AName: String; const AValue: Variant);

    property Source:        IX2ConfigSource read FSource;
    property Values:        TX2SVHash       read FValues;
    property ConfigItems:   TX2ConfigHash   read FConfigItems;
  public
    constructor Create(const AConfig: String; const ASource: IX2ConfigSource);
    destructor Destroy(); override;

    // IX2Config
    function GetName(): String;

    function ReadBool(const AName: String; const ADefault: Boolean = False): Boolean;
    function ReadFloat(const AName: String; const ADefault: Double = 0): Double;
    function ReadInteger(const AName: String; const ADefault: Integer = 0): Integer;
    function ReadString(const AName: String; const ADefault: String = ''): String;

    procedure WriteBool(const AName: String; AValue: Boolean);
    procedure WriteFloat(const AName: String; AValue: Double);
    procedure WriteInteger(const AName: String; AValue: Integer);
    procedure WriteString(const AName, AValue: String);

    procedure Clear();
    procedure Delete(const AName: String);
    function Exists(const AName: String): Boolean;

    procedure Save(); virtual;

    property Name:      String  read GetName;
  end;

  {
    :$ Default implementation for configuration sources.
  }
  TX2BaseConfigSource = class(TInterfacedObject, IX2ConfigSource)
  private
    FAutoSave:        Boolean;
    FConfigItems:     TX2ConfigHash;
  protected
    function GetConfig(const AName: String;
                       const AAllowCreate: Boolean = True): TX2BaseConfig; virtual;
    function CreateConfig(const AName: String): TX2BaseConfig; virtual; abstract;
    function GetItems(const AName: String): TX2ConfigHash; virtual;

    property ConfigItems:     TX2ConfigHash read FConfigItems;
  public
    constructor Create();
    destructor Destroy(); override;

    // IX2ConfigSource
    function GetAutoSave(): Boolean;
    procedure SetAutoSave(Value: Boolean);

    function Configs(const AName: String): IX2Config; virtual;

    function Add(const AName: String): IX2Config; virtual;
    function Exists(const AName: String): Boolean; virtual;
    procedure Delete(const AName: String); virtual;
    procedure Clear(); virtual;

    procedure Save(); virtual;

    procedure List(const AName: String; const ADest: TStrings;
                   const ARecurse: Boolean = False); virtual;
    procedure Iterate(const AName: String;
                      const ACallback: TX2ConfigIterateMethod;
                      const AData: Pointer = nil;
                      const ARecurse: Boolean = False); overload; virtual;
  end;

  {
    :$ Default implementation for stream-based configuration sources.
  }
  TX2StreamConfigSource = class(TX2BaseConfigSource)
  public
    constructor Create(const AStream: TStream); overload; virtual; abstract;
    constructor Create(const AFileName: String); overload; virtual;
  end;


var
  SectionSeparator: Char  = '.';


implementation
uses
  SysUtils,
  Variants,

  X2UtStrings;

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


{==================== TX2BaseConfigSource
  IX2ConfigSource
========================================}
constructor TX2BaseConfigSource.Create();
begin
  inherited;

  FConfigItems  := TX2ConfigHash.Create(True);
end;

destructor TX2BaseConfigSource.Destroy();
begin
  FreeAndNil(FConfigItems);

  inherited;
end;


function TX2BaseConfigSource.GetAutoSave(): Boolean;
begin
  Result  := FAutoSave;
end;

procedure TX2BaseConfigSource.SetAutoSave(Value: Boolean);
begin
  FAutoSave := Value;
end;


function TX2BaseConfigSource.GetConfig(const AName: String;
                                       const AAllowCreate: Boolean): TX2BaseConfig;
var
  aSections:        TSplitArray;
  iSection:         Integer;
  pItems:           TX2ConfigHash;
  sSection:         String;

begin
  Result  := nil;

  // Separate subsections
  Split(AName, SectionSeparator, aSections);

  for iSection  := Low(aSections) to High(aSections) do
  begin
    sSection  := Trim(aSections[iSection]);
    if Length(sSection) = 0 then
      continue;

    if Assigned(Result) then
      pItems  := Result.ConfigItems
    else
      pItems  := FConfigItems;

    Result  := pItems[sSection];
    if not Assigned(Result) then
      if AAllowCreate then
      begin
        Result            := CreateConfig(sSection);
        pItems[sSection]  := Result;
      end else
        break;
  end;
end;

function TX2BaseConfigSource.GetItems(const AName: String): TX2ConfigHash;
var
  pConfig:        TX2BaseConfig;
  
begin
  Result  := nil;
  if Length(Trim(AName)) > 0 then
  begin
    pConfig := GetConfig(AName, False);
    if Assigned(pConfig) then
      Result  := pConfig.ConfigItems;
  end else
    Result  := FConfigItems;
end;


function TX2BaseConfigSource.Configs(const AName: String): IX2Config;
begin
  Result  := GetConfig(AName, True);
end;

function TX2BaseConfigSource.Add(const AName: String): IX2Config;
begin
end;

function TX2BaseConfigSource.Exists(const AName: String): Boolean;
begin
end;

procedure TX2BaseConfigSource.Delete(const AName: String);
begin
end;

procedure TX2BaseConfigSource.Clear();
begin
end;


procedure TX2BaseConfigSource.Save();
begin
end;

procedure TX2BaseConfigSource.List(const AName: String; const ADest: TStrings;
                                   const ARecurse: Boolean);
begin
end;

procedure TX2BaseConfigSource.Iterate(const AName: String;
                                      const ACallback: TX2ConfigIterateMethod;
                                      const AData: Pointer;
                                      const ARecurse: Boolean);
var
  bAbort:       Boolean;
  pItems:       TX2ConfigHash;

begin
  pItems  := GetItems(AName);
  if not Assigned(pItems) then
    exit;

  bAbort  := False;
  pItems.First();
  while pItems.Next() do
  begin
    ACallback(Self, pItems.CurrentValue, bAbort);
    if bAbort then
      break;

    if ARecurse then
      Iterate(AName + SectionSeparator + pItems.CurrentValue.Name, ACallback,
              AData, ARecurse);
  end;
end;


{================== TX2StreamConfigSource
  Initialization
========================================}
constructor TX2StreamConfigSource.Create(const AFileName: String);
var
  fsData:     TFileStream;

begin
  fsData  := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Create(fsData);
  finally
    FreeAndNil(fsData);
  end;
end;


{========================== TX2BaseConfig
  IX2Config
========================================}
constructor TX2BaseConfig.Create(const AConfig: String;
                                 const ASource: IX2ConfigSource);
begin
  inherited Create();

  FSource       := ASource;
  FName         := AConfig;
  FConfigItems  := TX2ConfigHash.Create(True);
end;

destructor TX2BaseConfig.Destroy();
begin
  FreeAndNil(FConfigItems);

  inherited;
end;


function TX2BaseConfig.GetName(): String;
begin
  Result  := FName;
end;


function TX2BaseConfig.ReadBool(const AName: String;
                                const ADefault: Boolean): Boolean;
begin
  Result  := ADefault;
  if Values.Exists(AName) then
    Result  := VarAsType(Values[AName], vtBoolean);
end;

function TX2BaseConfig.ReadFloat(const AName: String;
                                 const ADefault: Double): Double;
begin
  Result  := ADefault;
  if Values.Exists(AName) then
    Result  := VarAsType(Values[AName], vtExtended);
end;

function TX2BaseConfig.ReadInteger(const AName: String;
                                   const ADefault: Integer): Integer;
begin
  Result  := ADefault;
  if Values.Exists(AName) then
    Result  := VarAsType(Values[AName], vtInteger);
end;

function TX2BaseConfig.ReadString(const AName, ADefault: String): String;
begin
  Result  := ADefault;
  if Values.Exists(AName) then
    Result  := VarAsType(Values[AName], vtString);
end;


procedure TX2BaseConfig.WriteValue(const AName: String; const AValue: Variant);
begin
  Values[AName] := AValue;
  if Source.AutoSave then
    Save();
end;

procedure TX2BaseConfig.WriteBool(const AName: String; AValue: Boolean);
begin
  WriteValue(AName, AValue);
end;

procedure TX2BaseConfig.WriteFloat(const AName: String; AValue: Double);
begin
  WriteValue(AName, AValue);
end;

procedure TX2BaseConfig.WriteInteger(const AName: String; AValue: Integer);
begin
  WriteValue(AName, AValue);
end;

procedure TX2BaseConfig.WriteString(const AName, AValue: String);
begin
  WriteValue(AName, AValue);
end;


procedure TX2BaseConfig.Clear();
begin
  Values.Clear();
end;

procedure TX2BaseConfig.Delete(const AName: String);
begin
  Values.Delete(AName);
end;

function TX2BaseConfig.Exists(const AName: String): Boolean;
begin
  Result  := Values.Exists(AName);
end;


procedure TX2BaseConfig.Save();
begin
  Source.Save();
end;

end.
