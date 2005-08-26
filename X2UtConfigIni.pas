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
  X2UtConfig;

type
  TX2IniConfigSource  = class(TX2StreamConfigSource)
  protected
    procedure IniSection(Sender: TObject; Section: String);
    procedure IniValue(Sender: TObject; Name, Value: String);
  public
    constructor Create(const AStream: TStream); override;
  end;

implementation
uses
  X2UtIniParser;

{===================== TX2IniConfigSource
  Initialization
========================================}
constructor TX2IniConfigSource.Create(const AStream: TStream);
begin
  
end;


procedure TX2IniConfigSource.IniSection(Sender: TObject; Section: String);
begin
  //
end;

procedure TX2IniConfigSource.IniValue(Sender: TObject; Name, Value: String);
begin
  //
end;

end.
 