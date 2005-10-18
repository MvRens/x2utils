unit SettingsTest;

interface
uses
  TestFramework,
  X2UtConfig;

type
  TSettingsTest = class(TTestCase)
  protected
    function CreateSource(): IX2ConfigSource; virtual; abstract;
  published
    procedure Read();
    procedure Write();
    procedure Delete();
    procedure Save(); virtual; abstract;
  end;

  TSettingsINITest  = class(TSettingsTest)
  protected
    function CreateSource(): IX2ConfigSource; override;
  published
    procedure Save(); override;

    procedure StringRange();
    procedure IntegerRange();
  private
    procedure FloatRange();
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
uses
  Classes,
  SysUtils,

  madExcept,

  X2UtConfigIni,
  X2UtConfigRanges;

{ TSettingsINITest }
function TSettingsINITest.CreateSource(): IX2ConfigSource;
var
  ssData:     TStringStream;

begin
  ssData  := TStringStream.Create('[ReadTest]'#13#10 +
                                  'SomeKey=SomeValue');
  try
    Result  := TX2IniConfigSource.Create(ssData);
  finally
    FreeAndNil(ssData);
  end;
end;

procedure TSettingsINITest.Save;
var
  ssData:     TStringStream;

begin
  ssData  := TStringStream.Create('');
  try     
    with CreateSource() do
    begin
      with Configs('SaveTest') do
      begin
        Write('String', 'Test');
        Write('Integer', 5);
        Write('Float', 3.5);
        Write('Boolean', True);
      end;

      Save(ssData);
    end;

    ssData.Seek(0, soFromBeginning);
    with (TX2IniConfigSource.Create(ssData) as IX2ConfigSource) do
    begin        
      CheckTrue(Exists('ReadTest'), 'ReadTest not found');
      CheckTrue(Exists('SaveTest'), 'SaveTest not found');

      with Configs('ReadTest') do
        CheckTrue(Exists('SomeKey'), 'ReadTest.SomeKey not found');

      with Configs('SaveTest') do
      begin
        CheckTrue(Exists('String'), 'SaveTest.String not found');
        CheckTrue(Exists('Integer'), 'SaveTest.Integer not found');
        CheckTrue(Exists('Float'), 'SaveTest.Float not found');
        CheckTrue(Exists('Boolean'), 'SaveTest.Boolean not found');
      end;
    end;        
  finally
    FreeAndNil(ssData);
  end;
end;

procedure TSettingsINITest.StringRange;
begin
  with CreateSource() do
  begin
    Register('RangeTest', 'String').Attach(TX2ConfigStringLengthRange.Create(5, 5, '0', spLeft));

    with Configs('RangeTest') do
    begin
      Write('String', '1');
      CheckEquals('00001', Read('String'));

      Write('String', '1234567890');
      CheckEquals('12345', Read('String'));
    end;
  end;
end;

procedure TSettingsINITest.IntegerRange;
begin
  with CreateSource() do
  begin
    Register('RangeTest', 'Integer').Attach(TX2ConfigIntegerRange.Create(5, 10, 8));

    with Configs('RangeTest') do
    begin
      Write('String', '1');
      CheckEquals('00001', Read('String'));

      Write('String', '1234567890');
      CheckEquals('12345', Read('String'));
    end;
  end;
end;

procedure TSettingsINITest.FloatRange;
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


{ TSettingsTest }
procedure TSettingsTest.Read;
begin
  with CreateSource() do
    CheckEquals('SomeValue', Configs('ReadTest').Read('SomeKey'));
end;

procedure TSettingsTest.Write;
begin
  with CreateSource() do
  begin
    with Configs('WriteTest') do
    begin
      Write('NewKey', 255);
      CheckEquals(255, Read('NewKey'));
    end;

    with Configs('ReadTest') do
    begin
      Write('SomeKey', 'NewValue');
      CheckEquals('NewValue', Read('SomeKey'));
    end;
  end;
end;

procedure TSettingsTest.Delete;
begin
  with CreateSource() do
  begin
    with Configs('DeleteTest') do
    begin
      Write('SomeKey', 'SomeValue');
      Delete('SomeKey');
      CheckFalse(Exists('SomeKey'));
    end;

    Delete('DeleteTest');
    CheckFalse(Exists('DeleteTest')); 
  end;
end;


initialization
  RegisterTest('Settings', TSettingsINITest.Suite);
  {
  RegisterTest('Settings', TSettingsRegistryTest.Suite);
  RegisterTest('Settings', TSettingsXMLTest.Suite);
  RegisterTest('Settings', TSettingsNiniXMLTest.Suite);
  RegisterTest('Settings', TSettingsCmdLineTest.Suite);
  }

end.
