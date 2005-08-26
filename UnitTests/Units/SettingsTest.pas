unit SettingsTest;

interface
uses
  TestFramework,
  X2UtConfig;

type
  TSettingsTest = class(TTestCase)
  protected
    function CreateSource(): IX2ConfigSource; virtual; abstract;
  end;

  TSettingsINITest  = class(TSettingsTest)
  protected
    function CreateSource(): IX2ConfigSource; override;
  end;

  TSettingsRegistryTest = class(TSettingsTest)
  protected
    function CreateSource(): IX2ConfigSource; override;
  end;

  TSettingsXMLTest  = class(TSettingsTest)
  protected
    function CreateSource(): IX2ConfigSource; override;
  end;

  TSettingsNiniXMLTest  = class(TSettingsTest)
  protected
    function CreateSource(): IX2ConfigSource; override;
  end;

  TSettingsCmdLineTest  = class(TSettingsTest)
  protected
    function CreateSource(): IX2ConfigSource; override;
  end;

implementation

{ TSettingsINITest }
function TSettingsINITest.CreateSource(): IX2ConfigSource;
begin

end;

{ TSettingsRegistryTest }
function TSettingsRegistryTest.CreateSource(): IX2ConfigSource;
begin

end;

{ TSettingsXMLTest }
function TSettingsXMLTest.CreateSource(): IX2ConfigSource;
begin

end;

{ TSettingsNiniXMLTest }
function TSettingsNiniXMLTest.CreateSource(): IX2ConfigSource;
begin

end;

{ TSettingsCmdLineTest }
function TSettingsCmdLineTest.CreateSource(): IX2ConfigSource;
begin

end;


initialization
  RegisterTest('Settings', TSettingsINITest.Suite);
  RegisterTest('Settings', TSettingsRegistryTest.Suite);
  RegisterTest('Settings', TSettingsXMLTest.Suite);
  RegisterTest('Settings', TSettingsNiniXMLTest.Suite);
  RegisterTest('Settings', TSettingsCmdLineTest.Suite);

end.
