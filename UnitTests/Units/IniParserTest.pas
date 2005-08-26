unit IniParserTest;

interface
uses
  Classes,

  TestFramework,
  X2UtIniParser;

type
  TIniParserTest  = class(TTestCase)
  private
    FValue:     String;

    procedure IniComment(Sender: TObject; Comment: String);
    procedure IniSection(Sender: TObject; Section: String);
    procedure IniValue(Sender: TObject; Name, Value: String);

    procedure Parse(const AStream: TStream);
  published
    procedure testSimple();
    procedure testExtended();
  end;

implementation

{ TIniParserTest }
procedure TIniParserTest.IniComment(Sender: TObject; Comment: String);
begin
  FValue  := FValue + '|C-' + Comment;
end;

procedure TIniParserTest.IniSection(Sender: TObject; Section: String);
begin
  FValue  := FValue + '|S-' + Section;
end;

procedure TIniParserTest.IniValue(Sender: TObject; Name, Value: String);
begin
  FValue  := FValue + '|V-' + Name + '=' + Value;
end;

procedure TIniParserTest.Parse(const AStream: TStream);
begin
  with TX2IniParser.Create() do
  try
    OnComment := IniComment;
    OnSection := IniSection;
    OnValue   := IniValue;

    FValue    := '';
    Execute(AStream);
  finally
    Free();
    AStream.Free();
  end;
end;


procedure TIniParserTest.testSimple;
begin
  Parse(TStringStream.Create(';Comment'#13#10 +
                             '[Section]'#13#10 +
                             'Name=Value'));
  CheckEquals('|C-Comment|S-Section|V-Name=Value', FValue);
end;

procedure TIniParserTest.testExtended;
begin
  Parse(TStringStream.Create(';C1'#13#10 +
                             ';C2'#13#10 +
                             '[  Section Two  ] ;  C3   '#13#10 +
                             '[Section Three;Two;One]'#13#10 +
                             'N=V'#13#10 +
                             'X=Y;C4'));
  CheckEquals('|C-C1|C-C2|S-Section Two|C-C3|S-Section Three;Two;One' +
              '|V-N=V|V-X=Y|C-C4', FValue);
end;


initialization
  RegisterTest('IniParser', TIniParserTest.Suite);

end.
