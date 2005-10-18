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
  :: To accomodate for tree structures, configuration names may contain a
  :: dot (.) to separate the sections. While they are used as-is in flat
  :: sources (INI), they are used for subkeys in tree source (Registry, XML).
  :: The SectionSeparator variable is available for this purpose.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtConfig;

interface
uses
  Classes,

  X2UtHashes;

type
  // Forward declarations
  IX2ConfigSource             = interface;
  IX2Config                   = interface;
  IX2ConfigDefinition         = interface;
  IX2ConfigDefinitionObserver = interface;

  {
    :$ Callback method for config iteration
  }
  TX2ConfigIterateConfigs = procedure(Sender: IX2ConfigSource;
                                      const Name: String;
                                      const Data: Pointer) of object;

  {
    :$ Callback method for value iteration
  }
  TX2ConfigIterateValues  = procedure(Sender: IX2Config;
                                      const Name: String;
                                      const Data: Pointer) of object;

  {
    :$ Determines which values should be cleared.

    :: caAll          clears all values
    :: caDefined      clears only values which have been defined using
    ::                IX2ConfigSource.Register
    :: caUndefined    clears only values which have not been defined using
    ::                IX2ConfigSource.Register
  }
  TX2ConfigClearAction  = (caAll, caDefined, caUndefined);

  {
    :$ Interface for configuration sources.
  }
  IX2ConfigSource = interface
    ['{1FF5282B-122F-47D7-95E8-3DB60A8CF765}']
    function GetAutoSave(): Boolean;
    procedure SetAutoSave(Value: Boolean);

    procedure Reload();
    procedure Save(); overload;
    procedure Save(const AStream: TStream); overload;

    function Configs(const AName: String): IX2Config;
    function Exists(const AName: String): Boolean;

    procedure Delete(const AName: String);
    procedure Clear(const AAction: TX2ConfigClearAction);

    procedure Iterate(const ACallback: TX2ConfigIterateConfigs;
                      const AData: Pointer);

    function Register(const AConfig, AName: String): IX2ConfigDefinition; overload;
    function Register(const AConfig, AName: String;
                      const ADefault: Variant): IX2ConfigDefinition; overload;
    function Definitions(const AConfig, AName: String): IX2ConfigDefinition;

    property AutoSave:      Boolean read GetAutoSave  write SetAutoSave;
  end;

  {
    :$ Interface for configurations.
  }
  IX2Config = interface
    ['{25DF95C1-CE09-44A7-816B-A33B8D0D78DC}']
    function GetName(): String;
    function GetSource(): IX2ConfigSource;

    function Exists(const AName: String): Boolean;
    function Read(const AName: String): Variant; overload;
    function Read(const AName: String; const ADefault: Variant): Variant; overload;
    procedure Write(const AName: String; const AValue: Variant);

    procedure Delete(const AName: String);
    procedure Clear(const AAction: TX2ConfigClearAction);

    procedure Iterate(const ACallback: TX2ConfigIterateValues;
                      const AData: Pointer);

    property Name:      String          read GetName;
    property Source:    IX2ConfigSource read GetSource;
  end;

  {
    :$ Interface for configuration value definitions.
  }
  IX2ConfigDefinition = interface
    ['{00C67656-24FB-4CBE-81DC-B064A5550820}']
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
  end;

  {
    :$ Interface for configuration value definition observers.
  }
  IX2ConfigDefinitionObserver = interface
    ['{EE20E59D-6642-42D7-A520-6A4F1C5FD3EA}']
    procedure Read(const AConfig, AName: String; var AValue: Variant);
    procedure Write(const AConfig, AName: String; var AValue: Variant);
  end;


var
  SectionSeparator: Char  = '.';


implementation
end.
