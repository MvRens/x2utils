{
  :: X2UtSettings provides a generic access mechanism for application settings.
  :: Include one of the extensions (X2UtSettingsINI, X2UtSettingsRegistry) for
  :: an implementation.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtSettings;

interface
uses
  Classes,
  SysUtils,
  Variants,
  X2UtHashes;

type
  //:$ Raised when an unregistered setting is requested without providing a
  //:$ default value.
  EX2SettingsUndefined  = class(Exception);

  //:$ Raised when trying to read a registered setting as a different type than
  //:$ it was registered with.
  EX2SettingsType       = class(Exception);

  //:$ Raised when the specified range is invalid.
  EX2SettingsRange      = class(Exception);

  //:$ Raised when the specified define already exists
  EX2SettingsExists     = class(Exception);

  //:$ Callback method for defines
  TX2SettingsAction     = (saRead, saWrite);
  TX2SettingsCallback   = procedure(const AAction: TX2SettingsAction;
                                    const ASection, AName: String;
                                    var AValue: Variant) of object;

  {
    :$ Internal representation of a persistent setting
  }
  TX2SettingsDefine     = class(TObject)
  private
    FCallback:      TX2SettingsCallback;
    FValue:         Variant;
  public
    constructor Create(const AValue: Variant;
                       const ACallback: TX2SettingsCallback);

    procedure Action(const AAction: TX2SettingsAction;
                     const ASection, AName: String;
                     var AValue: Variant); 

    property Callback:  TX2SettingsCallback read FCallback;
    property Value:     Variant             read FValue;
  end;


  // Forward declaration
  TX2SettingsFactory    = class;

  {
    :$ Abstract settings object.

    :: Provides access to the settings regardless of the storage backend.
  }
  TX2Settings           = class(TObject)
  private
    FFactory:         TX2SettingsFactory;
    FSection:         String;
  protected
    function InternalReadBool(const AName: String; out AValue: Boolean): Boolean; virtual; abstract;
    function InternalReadFloat(const AName: String; out AValue: Double): Boolean; virtual; abstract;
    function InternalReadInteger(const AName: String; out AValue: Integer): Boolean; virtual; abstract;
    function InternalReadString(const AName: String; out AValue: String): Boolean; virtual; abstract;

    procedure InternalWriteBool(const AName: String; AValue: Boolean); virtual; abstract;
    procedure InternalWriteFloat(const AName: String; AValue: Double); virtual; abstract;
    procedure InternalWriteInteger(const AName: String; AValue: Integer); virtual; abstract;
    procedure InternalWriteString(const AName, AValue: String); virtual; abstract;

    property Factory:         TX2SettingsFactory  read FFactory;
    property Section:         String              read FSection;
  public
    constructor Create(const AFactory: TX2SettingsFactory;
                       const ASection: String); virtual;

    //:$ Reads a boolean value from the settings.
    //:: If the ADefault parameter is used, that value will be returned if the
    //:: setting could not be found. Otherwise the setting must have been
    //:: registered with the factory's Register() method.
    function ReadBool(const AName: String): Boolean; overload; virtual;
    function ReadBool(const AName: String; const ADefault: Boolean): Boolean; overload; virtual;

    //:$ Reads a floating point value from the settings.
    //:: If the ADefault parameter is used, that value will be returned if the
    //:: setting could not be found. Otherwise the setting must have been
    //:: registered with the factory's Register() method.
    function ReadFloat(const AName: String): Double; overload; virtual;
    function ReadFloat(const AName: String; const ADefault: Double): Double; overload; virtual;

    //:$ Reads an integer value from the settings.
    //:: If the ADefault parameter is used, that value will be returned if the
    //:: setting could not be found. Otherwise the setting must have been
    //:: registered with the factory's Register() method.
    function ReadInteger(const AName: String): Integer; overload; virtual;
    function ReadInteger(const AName: String; const ADefault: Integer): Integer; overload; virtual;

    //:$ Reads a string value from the settings.
    //:: If the ADefault parameter is used, that value will be returned if the
    //:: setting could not be found. Otherwise the setting must have been
    //:: registered with the factory's Register() method.
    function ReadString(const AName: String): String; overload; virtual;
    function ReadString(const AName, ADefault: String): String; overload; virtual;

    //:$ Writes a boolean value to the settings.
    procedure WriteBool(const AName: String; AValue: Boolean); virtual;

    //:$ Writes a floating point value to the settings.
    procedure WriteFloat(const AName: String; AValue: Double); virtual;

    //:$ Writes an integer value to the settings.
    procedure WriteInteger(const AName: String; AValue: Integer); virtual;

    //:$ Writes a string value to the settings.
    procedure WriteString(const AName, AValue: String); virtual;

    //:$ Checks if the specified setting exists.
    function ValueExists(const AName: String): Boolean; virtual; abstract;

    //:$ Retrieves the list of sub-sections for this section.
    procedure GetSectionNames(const ADest: TStrings); virtual; abstract;

    //:$ Retrieves the list of values for this section.
    procedure GetValueNames(const ADest: TStrings); virtual; abstract;

    //:$ Deletes this section.
    procedure DeleteSection(); virtual; abstract;

    //:$ Deletes the specified value.
    procedure DeleteValue(const AName: String); virtual; abstract;
  end;

  {
    :$ Settings factory.

    :: Extensions must implement a factory descendant which an application can
    :: create to provide application-wide access to the same settings.
  }
  TX2SettingsFactory    = class(TObject)
  private
    FDefines:         TX2ObjectHash;
  protected
    function GetSection(const ASection: String): TX2Settings; virtual; abstract;
    function GetDefine(const ASection, AName: String): TX2SettingsDefine; virtual;
  public
    constructor Create();
    destructor Destroy(); override;

    //:$ Loads a section from the settings.
    //:: Sub-sections are indicated by seperating the sections with a dot ('.')
    //:: characters, ex: Sub.Section. The underlying extension will translate
    //:: this into a compatible section.
    //:! The application is responsible for freeing the returned class.
    property Sections[const ASection: String]:    TX2Settings read GetSection; default;

    //:$ Defines a persistent setting
    //:: Persistent settings are a way for the application to register it's
    //:: configuration settings on startup with a default value and a possible
    //:: callback method to perform centralized checks.
    procedure Define(const ASection, AName: String; const AValue: Variant;
                     const ACallback: TX2SettingsCallback = nil);
  end;


implementation
resourcestring
  RSInvalidRange  = 'Invalid range!';
  RSInvalidType   = 'Invalid type!';
  RSUndefined     = 'Undefined setting: %s!';
  RSDefineExists  = 'Define already exists!';


{============================ TX2Settings
  Initialization
========================================}
constructor TX2Settings.Create;
begin
  inherited Create();

  FFactory  := AFactory;
  FSection  := ASection;
end;


{============================ TX2Settings
  Reading
========================================}
function TX2Settings.ReadBool(const AName: String): Boolean;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  pDefine := FFactory.GetDefine(FSection, AName);

  if not InternalReadBool(AName, Result) then
  begin
    if Assigned(pDefine) then
      Result  := pDefine.Value
    else
      raise EX2SettingsUndefined.CreateFmt(RSUndefined, [AName])

    if Assigned(pDefine) then
    begin
      vValue  := Result;
      pDefine.Action(saRead, FSection, AName, vValue);
      Result  := vValue;
    end;
  end;
end;

function TX2Settings.ReadBool(const AName: String;
                              const ADefault: Boolean): Boolean;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  if not InternalReadBool(AName, Result) then
    Result  := ADefault;

  pDefine := FFactory.GetDefine(FSection, AName);
  if Assigned(pDefine) then
  begin
    vValue  := Result;
    pDefine.Action(saRead, FSection, AName, vValue);
    Result  := vValue;
  end;
end;

function TX2Settings.ReadFloat(const AName: String): Double;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  pDefine := FFactory.GetDefine(FSection, AName);

  if not InternalReadFloat(AName, Result) then
    if Assigned(pDefine) then
      Result  := pDefine.Value
    else
      raise EX2SettingsUndefined.CreateFmt(RSUndefined, [AName]);

  if Assigned(pDefine) then
  begin
    vValue  := Result;
    pDefine.Action(saRead, FSection, AName, vValue);
    Result  := vValue;
  end;
end;

function TX2Settings.ReadFloat(const AName: String;
                               const ADefault: Double): Double;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  if not InternalReadFloat(AName, Result) then
    Result  := ADefault;

  pDefine := FFactory.GetDefine(FSection, AName);
  if Assigned(pDefine) then
  begin
    vValue  := Result;
    pDefine.Action(saRead, FSection, AName, vValue);
    Result  := vValue;
  end;
end;

function TX2Settings.ReadInteger(const AName: String): Integer;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  pDefine := FFactory.GetDefine(FSection, AName);

  if not InternalReadInteger(AName, Result) then
    if Assigned(pDefine) then
      Result  := pDefine.Value
    else
      raise EX2SettingsUndefined.CreateFmt(RSUndefined, [AName]);

  if Assigned(pDefine) then
  begin
    vValue  := Result;
    pDefine.Action(saRead, FSection, AName, vValue);
    Result  := vValue;
  end;
end;

function TX2Settings.ReadInteger(const AName: String;
                                 const ADefault: Integer): Integer;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  if not InternalReadInteger(AName, Result) then
    Result  := ADefault;

  pDefine := FFactory.GetDefine(FSection, AName);
  if Assigned(pDefine) then
  begin
    vValue  := Result;
    pDefine.Action(saRead, FSection, AName, vValue);
    Result  := vValue;
  end;
end;

function TX2Settings.ReadString(const AName: String): String;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  pDefine := FFactory.GetDefine(FSection, AName);

  if not InternalReadString(AName, Result) then
    if Assigned(pDefine) then
      Result  := pDefine.Value
    else
      raise EX2SettingsUndefined.CreateFmt(RSUndefined, [AName]);

  if Assigned(pDefine) then
  begin
    vValue  := Result;
    pDefine.Action(saRead, FSection, AName, vValue);
    Result  := vValue;
  end;
end;

function TX2Settings.ReadString(const AName, ADefault: String): String;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  if not InternalReadString(AName, Result) then
    Result  := ADefault;

  pDefine := FFactory.GetDefine(FSection, AName);
  if Assigned(pDefine) then
  begin
    vValue  := Result;
    pDefine.Action(saRead, FSection, AName, vValue);
    Result  := vValue;
  end;
end;


{============================ TX2Settings
  Writing
========================================}
procedure TX2Settings.WriteBool;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  pDefine := FFactory.GetDefine(FSection, AName);
  if Assigned(pDefine) then
  begin
    vValue  := AValue;
    pDefine.Action(saWrite, FSection, AName, vValue);
  end;

  InternalWriteBool(AName, vValue);
end;

procedure TX2Settings.WriteFloat;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  pDefine := FFactory.GetDefine(FSection, AName);
  if Assigned(pDefine) then
  begin
    vValue  := AValue;
    pDefine.Action(saWrite, FSection, AName, vValue);
  end;

  InternalWriteFloat(AName, vValue);
end;

procedure TX2Settings.WriteInteger;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  pDefine := FFactory.GetDefine(FSection, AName);
  if Assigned(pDefine) then
  begin
    vValue  := AValue;
    pDefine.Action(saWrite, FSection, AName, vValue);
  end;

  InternalWriteInteger(AName, vValue);
end;

procedure TX2Settings.WriteString;
var
  pDefine:      TX2SettingsDefine;
  vValue:       Variant;

begin
  pDefine := FFactory.GetDefine(FSection, AName);
  if Assigned(pDefine) then
  begin
    vValue  := AValue;
    pDefine.Action(saWrite, FSection, AName, vValue);
  end;

  InternalWriteInteger(AName, vValue);
end;


{===================== TX2SettingsFactory
  Defines
========================================}
constructor TX2SettingsFactory.Create;
begin
  inherited;

  FDefines  := TX2ObjectHash.Create();
end;

destructor TX2SettingsFactory.Destroy;
begin
  FreeAndNil(FDefines);

  inherited;
end;


procedure TX2SettingsFactory.Define;
  function CheckVarType(const AValue: Variant): TVarType;
  begin
    case VarType(AValue) of
      varBoolean:     Result  := varBoolean;
      varByte,
      varSmallint,
      varInteger,
      varWord,
      varLongWord:    Result  := varInteger;
      varSingle,
      varDouble,
      varDate:        Result  := varDouble;
      varOleStr,
      varStrArg,
      varString:      Result  := varString;
    else
      raise EX2SettingsType.Create(RSInvalidType);
    end;
  end;

var
  sHash:          String;
  vtValue:        TVarType;

begin
  sHash := ASection + #0 + AName;
  if FDefines.Exists(sHash) then
    raise EX2SettingsExists.Create(RSDefineExists);

  // Validate type
  vtValue         := CheckVarType(AValue);
  FDefines[sHash] := TX2SettingsDefine.Create(VarAsType(AValue, vtValue),
                                              ACallback);
end;


function TX2SettingsFactory.GetDefine;
begin
  Result  := TX2SettingsDefine(FDefines[ASection + #0 + AName]);
end;


{====================== TX2SettingsDefine
  Initialization
========================================}
constructor TX2SettingsDefine.Create;
begin
  FValue    := AValue;
  FCallback := ACallback;
end;

procedure TX2SettingsDefine.Action;
begin
  if Assigned(FCallback) then
    FCallback(AAction, ASection, AName, AValue);
end;

end.
