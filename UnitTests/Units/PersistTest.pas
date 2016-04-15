unit PersistTest;

interface
uses
  Classes,

  TestFramework;


type
  TPersistTest  = class(TTestCase)
  published
    procedure QueryReaderWriter;

    procedure WriteNoTypeInfo;
    procedure WriteSimpleTypes;
  end;


implementation
uses
  SysUtils,
  
  X2UtPersist,
  X2UtPersistIntf;


type
  IPersistTestOutput = interface
    ['{F0BFDA30-B2BF-449D-9A6E-0EDEBCDAE701}']
    function GetLines(): TStrings;

    property Lines: TStrings read GetLines;
  end;

  TPersistTestOutput = class(TInterfacedObject, IPersistTestOutput)
  private
    FLines:   TStrings;
  protected
    function GetLines(): TStrings;
  public
    constructor Create();
    destructor Destroy(); override;
  end;

  TX2UtPersistTest = class(TX2CustomPersist)
  private
    FOutput:  IPersistTestOutput;
  protected
    function CreateFiler(AIsReader: Boolean): IX2PersistFiler; override;
  public
    constructor Create();

    property Output:  IPersistTestOutput read FOutput;
  end;


  TX2UtPersistTestFiler = class(TX2CustomPersistFiler)
  private
    FOutput: IPersistTestOutput;
  public
    function BeginSection(const AName: String): Boolean; override;
    procedure EndSection(); override;

    function ReadFloat(const AName: String; out AValue: Extended): Boolean; override;
    function ReadInt64(const AName: String; out AValue: Int64): Boolean; override;
    function ReadInteger(const AName: String; out AValue: Integer): Boolean; override;
    function ReadString(const AName: String; out AValue: String): Boolean; override;

    function WriteFloat(const AName: String; AValue: Extended): Boolean; override;
    function WriteInt64(const AName: String; AValue: Int64): Boolean; override;
    function WriteInteger(const AName: String; AValue: Integer): Boolean; override;
    function WriteString(const AName: String; const AValue: String): Boolean; override;

    procedure GetKeys(const ADest: TStrings); override;
    procedure GetSections(const ADest: TStrings); override;
    procedure DeleteKey(const AName: string); override;
    procedure DeleteSection(const AName: string); override;

    property Output:  IPersistTestOutput  read FOutput  write FOutput;
  end;


  TTypeInfoLess = class(TObject)
  end;


  TSimpleTypes = class(TPersistent)
  private
    FBooleanValue: Boolean;
    FFloatValue: Double;
    FInt64Value: Int64;
    FIntValue: Integer;
    FStringValue: String;
  public
    constructor Create();
  published
    property BooleanValue: Boolean read FBooleanValue write FBooleanValue;
    property FloatValue: Double read FFloatValue write FFloatValue;
    property Int64Value: Int64 read FInt64Value write FInt64Value;
    property IntValue: Integer read FIntValue write FIntValue;
    property StringValue: String read FStringValue write FStringValue;
  end;



{ TSimpleTypes }
constructor TSimpleTypes.Create();
begin
  inherited;

  FIntValue := 42;
end;



{ TPersistTest }
procedure TPersistTest.QueryReaderWriter;
var
  persistTest:    TX2UtPersistTest;

begin
  persistTest := TX2UtPersistTest.Create();
  try
    { Regular filer }
    CheckTrue(Supports(persistTest.CreateReader(), IX2PersistReader), 'Reader -> Reader');
    CheckFalse(Supports(persistTest.CreateReader(), IX2PersistWriter), 'Reader -> Writer');

    CheckTrue(Supports(persistTest.CreateWriter(), IX2PersistWriter), 'Writer -> Writer');
    CheckFalse(Supports(persistTest.CreateWriter(), IX2PersistReader), 'Writer -> Reader');

    { Section proxy }
    CheckTrue(Supports(persistTest.CreateSectionReader('Test.Section'), IX2PersistReader), 'Section Reader -> Reader');
    CheckFalse(Supports(persistTest.CreateSectionReader('Test.Section'), IX2PersistWriter), 'Section Reader -> Writer');

    CheckTrue(Supports(persistTest.CreateSectionWriter('Test.Section'), IX2PersistWriter), 'Section Writer -> Writer');
    CheckFalse(Supports(persistTest.CreateSectionWriter('Test.Section'), IX2PersistReader), 'Section Writer -> Reader');
  finally
    FreeAndNil(persistTest);
  end;
end;


procedure TPersistTest.WriteNoTypeInfo;
var
  testObject: TTypeInfoLess;

begin
  testObject := TTypeInfoLess.Create;
  try
    with TX2UtPersistTest.Create do
    try
      Write(testObject);

      CheckEquals('', Output.Lines.Text);
    finally
      Free;
    end;
  finally
    FreeAndNil(testObject);
  end;
end;

procedure TPersistTest.WriteSimpleTypes;
var
  testObject: TSimpleTypes;

begin
  testObject := TSimpleTypes.Create;
  try
    with TX2UtPersistTest.Create do
    try
      Write(testObject);

//      CheckEquals('Integer:42'#13#10, Output.Lines.Text);
    finally
      Free;
    end;
  finally
    FreeAndNil(testObject);
  end;
end;


{ TX2UtPersistTest }
constructor TX2UtPersistTest.Create();
begin
  inherited;

  FOutput := TPersistTestOutput.Create();
end;


function TX2UtPersistTest.CreateFiler(AIsReader: Boolean): IX2PersistFiler;
var
  testFiler:  TX2UtPersistTestFiler;

begin
  testFiler         := TX2UtPersistTestFiler.Create(AIsReader);
  testFiler.Output  := Self.Output;

  Result  := testFiler;
end;


{ TX2UtPersistTestFiler }
function TX2UtPersistTestFiler.BeginSection(const AName: String): Boolean;
begin
  Result := inherited BeginSection(AName);
  if Result then
    Output.Lines.Add(AName + ' {');
end;


procedure TX2UtPersistTestFiler.EndSection();
begin
  Output.Lines.Add('}');
  inherited EndSection();
end;


function TX2UtPersistTestFiler.ReadFloat(const AName: String; out AValue: Extended): Boolean;
begin
  Result := False;
end;


function TX2UtPersistTestFiler.ReadInt64(const AName: String; out AValue: Int64): Boolean;
begin
  Result := False;
end;


function TX2UtPersistTestFiler.ReadInteger(const AName: String; out AValue: Integer): Boolean;
begin
  Result := False;
end;


function TX2UtPersistTestFiler.ReadString(const AName: String; out AValue: String): Boolean;
begin
  Result := False;
end;


function TX2UtPersistTestFiler.WriteFloat(const AName: String; AValue: Extended): Boolean;
begin
  Output.Lines.Add(Format('Float:%.2f', [AValue]));
  Result := True;
end;


function TX2UtPersistTestFiler.WriteInt64(const AName: String; AValue: Int64): Boolean;
begin
  Output.Lines.Add(Format('Int64:%d', [AValue]));
  Result := True;
end;


function TX2UtPersistTestFiler.WriteInteger(const AName: String; AValue: Integer): Boolean;
begin
  Output.Lines.Add(Format('Integer:%d', [AValue]));
  Result := True;
end;


function TX2UtPersistTestFiler.WriteString(const AName, AValue: String): Boolean;
begin
  Output.Lines.Add(Format('String:%s', [AValue]));
  Result := True;
end;


procedure TX2UtPersistTestFiler.GetKeys(const ADest: TStrings);
begin
end;

procedure TX2UtPersistTestFiler.GetSections(const ADest: TStrings);
begin
end;

procedure TX2UtPersistTestFiler.DeleteKey(const AName: string);
begin
end;

procedure TX2UtPersistTestFiler.DeleteSection(const AName: string);
begin
end;



{ TPersistTestOutput }
constructor TPersistTestOutput.Create();
begin
  inherited;

  FLines  := TStringList.Create();
end;


destructor TPersistTestOutput.Destroy();
begin
  FreeAndNil(FLines);

  inherited;
end;


function TPersistTestOutput.GetLines(): TStrings;
begin
  Result  := FLines;
end;

initialization
  RegisterTest(TPersistTest.Suite);
  
end.

