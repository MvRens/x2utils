unit PersistTest;

interface
uses
  Classes,

  TestFramework;


type
  TPersistTest  = class(TTestCase)
  published
    procedure WriteNoTypeInfo;
    procedure WriteSimpleTypes;
  end;


implementation
uses
  SysUtils,
  
  X2UtPersist;


type
  TX2UtPersistTest = class(TX2CustomPersist)
  private
    FOutput:  TStrings;
  protected
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
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Write(AObject: TObject); override;

    property Output:  TStrings  read FOutput;
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
procedure TPersistTest.WriteNoTypeInfo;
var
  testObject: TTypeInfoLess;

begin
  testObject := TTypeInfoLess.Create;
  try
    with TX2UtPersistTest.Create do
    try
      Write(testObject);

      CheckEquals('', Output.Text);
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

      CheckEquals('Integer:42'#13#10, Output.Text);
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

  FOutput := TStringList.Create();
end;


destructor TX2UtPersistTest.Destroy();
begin
  FreeAndNil(FOutput);

  inherited;
end;


procedure TX2UtPersistTest.Write(AObject: TObject);
begin
  Output.Clear();

  inherited;
end;


function TX2UtPersistTest.BeginSection(const AName: String): Boolean;
begin
  Result := inherited BeginSection(AName);
  if Result then
    Output.Add(AName + ' {');
end;


procedure TX2UtPersistTest.EndSection();
begin
  Output.Add('}');
  inherited EndSection();
end;


function TX2UtPersistTest.ReadFloat(const AName: String; out AValue: Extended): Boolean;
begin
  Result := False;
end;


function TX2UtPersistTest.ReadInt64(const AName: String; out AValue: Int64): Boolean;
begin
  Result := False;
end;


function TX2UtPersistTest.ReadInteger(const AName: String; out AValue: Integer): Boolean;
begin
  Result := False;
end;


function TX2UtPersistTest.ReadString(const AName: String; out AValue: String): Boolean;
begin
  Result := False;
end;


function TX2UtPersistTest.WriteFloat(const AName: String; AValue: Extended): Boolean;
begin
  Output.Add(Format('Float:%.2f', [AValue]));
  Result := True;
end;


function TX2UtPersistTest.WriteInt64(const AName: String; AValue: Int64): Boolean;
begin
  Output.Add(Format('Int64:%d', [AValue]));
  Result := True;
end;


function TX2UtPersistTest.WriteInteger(const AName: String; AValue: Integer): Boolean;
begin
  Output.Add(Format('Integer:%d', [AValue]));
  Result := True;
end;


function TX2UtPersistTest.WriteString(const AName, AValue: String): Boolean;
begin
  Output.Add(Format('String:%s', [AValue]));
  Result := True;
end;


initialization
  RegisterTest(TPersistTest.Suite);
  
end.

