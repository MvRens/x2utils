{
  :: Implements the IX2ConfigSource for INI files.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtConfigIni;

interface
uses
  Classes,

  X2UtConfig,
  X2UtConfigBase;

type
  TX2IniConfigSource  = class(TX2StreamConfigSource)
  protected
    function CreateConfig(const AName: String): TX2BaseConfig; override;
    procedure LoadFromStream(const AStream: TStream); override;

    procedure IniSection(Sender: TObject; Section: String);
    procedure SaveValue(Sender: IX2Config; const Name: String;
                        const Data: Pointer);
  public
    procedure Save(const AStream: TStream); override;
  end;

  TX2IniConfig        = class(TX2BaseConfig)
  protected
    procedure IniValue(Sender: TObject; Name, Value: String);
  end;

implementation
uses
  Variants,
  
  X2UtIniParser;


{========================================
  TX2IniConfigSource
========================================}
function TX2IniConfigSource.CreateConfig(const AName: String): TX2BaseConfig;
begin
  Result  := TX2IniConfig.Create(AName, Self);
end;

procedure TX2IniConfigSource.LoadFromStream(const AStream: TStream);
begin
  with TX2IniParser.Create() do
  try
    OnSection := IniSection;
    Execute(AStream);
  finally
    Free();
  end;
end;

procedure TX2IniConfigSource.Save(const AStream: TStream);
  procedure WriteLine(const ALine: String);
  var
    sLine:      String;

  begin
    sLine := ALine + #13#10;
    AStream.WriteBuffer(PChar(sLine)^, Length(sLine));
  end;

begin
  ConfigItems.First();
  while ConfigItems.Next() do
  begin
    WriteLine('[' + ConfigItems.CurrentValue.Name + ']');
    ConfigItems.CurrentValue.Iterate(SaveValue, Pointer(AStream));
    WriteLine('');
  end;
end;


procedure TX2IniConfigSource.IniSection(Sender: TObject; Section: String);
begin
  (Sender as TX2IniParser).OnValue  := (GetConfig(Section) as TX2IniConfig).IniValue;
end;


{========================================
  TX2IniConfig
========================================}
procedure TX2IniConfig.IniValue(Sender: TObject; Name, Value: String);
begin
  InternalWrite(Name, Value, False);
end;

procedure TX2IniConfigSource.SaveValue(Sender: IX2Config;
                                       const Name: String;
                                       const Data: Pointer);
var
  sLine:      String;

begin
  sLine   := Name + '=' + VarAsType(Sender.Read(Name), varString) + #13#10;
  TStream(Data).WriteBuffer(PChar(sLine)^, Length(sLine));
end;

end.
