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

  //:$ Callback method for defines
  TX2SettingsCallback   = procedure(const ASection, AName: String;
                                    var AValue: Variant) of object;

  {
    :$ Internal representation of defines
  }
  TX2SettingsDefine     = class(TObject)
  private

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
    procedure WriteBool(const AName: String; AValue: Boolean); virtual; abstract;

    //:$ Writes a floating point value to the settings.
    procedure WriteFloat(const AName: String; AValue: Double); virtual; abstract;

    //:$ Writes an integer value to the settings.
    procedure WriteInteger(const AName: String; AValue: Integer); virtual; abstract;

    //:$ Writes a string value to the settings.
    procedure WriteString(const AName, AValue: String); virtual; abstract;

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
  protected
    function GetSection(const ASection: String): TX2Settings; virtual; abstract;
  public
    //:$ Loads a section from the settings.
    //:: Sub-sections are indicated by seperating the sections with a dot ('.')
    //:: characters, ex: Sub.Section. The underlying extension will translate
    //:: this into a compatible section.
    //:! The application is responsible for freeing the returned class.
    property Sections[const ASection: String]:    TX2Settings read GetSection; default;

    //:$ Defines a persistent setting
    //:: Persistent settings are a way for the application to register it's
    //:: configuration settings on startup with a default value and a range.
    //:: When reading a setting it will be checked against the specified range
    //:: (if supplied), or if not found, the registered default value will be
    //:: returned. This allows the setting to be read in many places without
    //:: having to do all the checks every time. In addition you may provide
    //:: a callback method to handle more advanced checks.
    //:: /n/n
    //:: Ranges must be specified as an array where each pair of values
    //:: specifies the minimum and maximum value of that range. The type
    //:: of the values in the ranges must be the same as the type of the
    //:: value, and is used later on for type checking. The only exception
    //:: to this rule is that you are allowed to specify integer ranges for
    //:: a floating value.
    procedure Define(const ASection, AName: String; const AValue: Variant;
                     const ARanges: array of const;
                     const ACallback: TX2SettingsCallback = nil);
  end;


implementation
resourcestring
  RSInvalidRange  = 'Invalid range';
  RSInvalidType   = 'Invalid type';
  RSUndefined     = 'Undefined setting: %s';


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
  Read
========================================}
function TX2Settings.ReadBool(const AName: String): Boolean;
begin
  if not InternalReadBool(AName, Result) then
    raise EX2SettingsUndefined.CreateFmt(RSUndefined, [AName]);
end;

function TX2Settings.ReadBool(const AName: String;
                              const ADefault: Boolean): Boolean;
begin
  if not InternalReadBool(AName, Result) then
    Result  := ADefault;
end;

function TX2Settings.ReadFloat(const AName: String): Double;
begin
  if not InternalReadFloat(AName, Result) then
    raise EX2SettingsUndefined.CreateFmt(RSUndefined, [AName]);
end;

function TX2Settings.ReadFloat(const AName: String;
                               const ADefault: Double): Double;
begin
  if not InternalReadFloat(AName, Result) then
    Result  := ADefault;
end;

function TX2Settings.ReadInteger(const AName: String): Integer;
begin
  if not InternalReadInteger(AName, Result) then
    raise EX2SettingsUndefined.CreateFmt(RSUndefined, [AName]);
end;

function TX2Settings.ReadInteger(const AName: String;
                                 const ADefault: Integer): Integer;
begin
  if not InternalReadInteger(AName, Result) then
    Result  := ADefault;
end;

function TX2Settings.ReadString(const AName: String): String;
begin
  if not InternalReadString(AName, Result) then
    raise EX2SettingsUndefined.CreateFmt(RSUndefined, [AName]);
end;

function TX2Settings.ReadString(const AName, ADefault: String): String;
begin
  if not InternalReadString(AName, Result) then
    Result  := ADefault;
end;


{===================== TX2SettingsFactory
  Defines
========================================}
procedure TX2SettingsFactory.Define;
begin
  //
end;

end.
