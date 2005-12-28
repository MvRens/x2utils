unit HashesTest;

interface
uses
  TestFramework,
  X2UtHashes,
  X2UtHashesVariants;

type
  THashesTest = class(TTestCase)
  private
    FHash:        TX2CustomHash;
  protected
    procedure TearDown(); override;
    procedure FillTestItems(); virtual; abstract;
  published
    procedure testSet(); virtual; abstract;
    procedure testGet(); virtual; abstract;
    procedure testClear();
    procedure testDelete(); virtual; abstract;
    procedure testIterate(); virtual; abstract;
    procedure testEnumerator(); virtual; abstract;
  end;

  // Two test cases involving all value managers.
  // This should be sufficient for a realistic scenario.
  THashesSITest = class(THashesTest)
  private
    function GetHash(): TX2SIHash;

    property Hash:      TX2SIHash read GetHash;
  protected
    procedure SetUp(); override;
    procedure FillTestItems(); override;
  published
    procedure testSet(); override;
    procedure testGet(); override;
    procedure testDelete(); override;
    procedure testIterate(); override;
    procedure testEnumerator(); override;
  end;

  THashesPOTest = class(THashesTest)
  private
    function GetHash(): TX2POHash;

    property Hash:      TX2POHash read GetHash;
  protected
    procedure SetUp(); override;
    procedure FillTestItems(); override;
  published
    procedure testSet(); override;
    procedure testGet(); override;
    procedure testDelete(); override;
    procedure testIterate(); override;
    procedure testEnumerator(); override;
  end;

  THashesVariantTest  = class(THashesTest)
  private
    function GetHash(): TX2SVHash;

    property Hash:      TX2SVHash read GetHash;
  protected
    procedure SetUp(); override;
    procedure FillTestItems(); override;
  published
    procedure testSet(); override;
    procedure testGet(); override;
    procedure testDelete(); override;
    procedure testIterate(); override;
    procedure testEnumerator(); override;
  end;

implementation
uses
  SysUtils;

type
  TObject0  = class(TObject);
  TObject1  = class(TObject);
  TObject2  = class(TObject);


{ THashesTest }
procedure THashesTest.TearDown;
begin
  FreeAndNil(FHash);

  inherited;
end;


procedure THashesTest.testClear;
begin
  FillTestItems();
  FHash.Clear();
  CheckEquals(0, FHash.Count);
end;


{ THashesSITest }
procedure THashesSITest.SetUp;
begin
  inherited;

  FHash := TX2SIHash.Create();
end;

procedure THashesSITest.FillTestItems;
begin
  Hash['Key1']  := 1;
  Hash['Key2']  := 2;
  Hash['Key3']  := 3;
end;

procedure THashesSITest.testSet;
begin
  FillTestItems();
  CheckEquals(3, Hash.Count);
end;

procedure THashesSITest.testGet;
begin
  FillTestItems();
  CheckEquals(1, Hash['Key1']);
  CheckEquals(2, Hash['Key2']);
  CheckEquals(3, Hash['Key3']);
end;

procedure THashesSITest.testDelete;
begin
  FillTestItems();
  Hash.Delete('Key2');

  CheckEquals(2, Hash.Count);
  CheckTrue(Hash.Exists('Key1'), 'Key1 does not exist!');
  CheckFalse(Hash.Exists('Key2'), 'Key2 still exists!');
  CheckTrue(Hash.Exists('Key3'), 'Key3 does not exist!');
end;

procedure THashesSITest.testEnumerator;
var
  aPresent:     array[1..3] of Boolean;
  sKey:         String;

begin
  FillTestItems();
  FillChar(aPresent, SizeOf(aPresent), #0);

  for sKey in Hash do
  begin
    if sKey = 'Key1' then
      aPresent[1] := True
    else if sKey = 'Key2' then
      aPresent[2] := True
    else if sKey = 'Key3' then
      aPresent[3] := True;
  end;

  CheckTrue(aPresent[1], 'Key1 was not in the enumeration!');
  CheckTrue(aPresent[2], 'Key2 was not in the enumeration!');
  CheckTrue(aPresent[3], 'Key3 was not in the enumeration!');

  { Not supported yet, maybe in the future.
  FillChar(aPresent, SizeOf(aPresent), #0);
  for iValue in Hash.Values do
    aPresent[iValue]  := True;

  CheckTrue(aPresent[1], 'Value of Key1 was not in the enumeration!');
  CheckTrue(aPresent[2], 'Value of Key2 was not in the enumeration!');
  CheckTrue(aPresent[3], 'Value of Key3 was not in the enumeration!');
  }
end;

procedure THashesSITest.testIterate;
var
  aPresent:     array[1..3] of Boolean;

begin
  FillTestItems();
  FillChar(aPresent, SizeOf(aPresent), #0);
  Hash.First();
  while Hash.Next() do
    if ((Hash.CurrentKey = 'Key1') and (Hash.CurrentValue = 1)) or
       ((Hash.CurrentKey = 'Key2') and (Hash.CurrentValue = 2)) or
       ((Hash.CurrentKey = 'Key3') and (Hash.CurrentValue = 3)) then
      aPresent[Hash.CurrentValue] := True;

  CheckTrue(aPresent[1], 'Key1 was not in the iteration!');
  CheckTrue(aPresent[2], 'Key2 was not in the iteration!');
  CheckTrue(aPresent[3], 'Key3 was not in the iteration!');
end;


function THashesSITest.GetHash(): TX2SIHash;
begin
  Result  := TX2SIHash(FHash);
end;


{ THashesPOTest }
procedure THashesPOTest.SetUp;
begin
  inherited;

  FHash := TX2POHash.Create(True);
end;

procedure THashesPOTest.FillTestItems;
begin
  Hash[Pointer(0)]  := TObject0.Create();
  Hash[Pointer(1)]  := TObject1.Create();
  Hash[Pointer(2)]  := TObject2.Create();
end;

procedure THashesPOTest.testSet;
begin
  FillTestItems();
  CheckEquals(3, Hash.Count);
end;

procedure THashesPOTest.testGet;
begin
  FillTestItems();
  CheckTrue(Hash[Pointer(0)] is TObject0);
  CheckTrue(Hash[Pointer(1)] is TObject1);
  CheckTrue(Hash[Pointer(2)] is TObject2);
end;

procedure THashesPOTest.testDelete;
begin
  FillTestItems();
  Hash.Delete(Pointer(1));

  CheckEquals(2, Hash.Count);
  CheckTrue(Hash.Exists(Pointer(0)), 'Key1 does not exist!');
  CheckFalse(Hash.Exists(Pointer(1)), 'Key2 still exists!');
  CheckTrue(Hash.Exists(Pointer(2)), 'Key3 does not exist!');
end;

procedure THashesPOTest.testEnumerator;
var
  aPresent:     array[0..2] of Boolean;
  pKey:         Pointer;

begin
  FillTestItems();
  FillChar(aPresent, SizeOf(aPresent), #0);

  for pKey in Hash do
    aPresent[Integer(pKey)] := True;

  CheckTrue(aPresent[0], 'Key1 was not in the enumeration!');
  CheckTrue(aPresent[1], 'Key2 was not in the enumeration!');
  CheckTrue(aPresent[2], 'Key3 was not in the enumeration!');
end;

procedure THashesPOTest.testIterate;
var
  aPresent:     array[0..2] of Boolean;

begin
  FillTestItems();
  FillChar(aPresent, SizeOf(aPresent), #0);
  Hash.First();
  while Hash.Next() do
    if ((Hash.CurrentKey = Pointer(0)) and (Hash.CurrentValue is TObject0)) or
       ((Hash.CurrentKey = Pointer(1)) and (Hash.CurrentValue is TObject1)) or
       ((Hash.CurrentKey = Pointer(2)) and (Hash.CurrentValue is TObject2)) then
      aPresent[Integer(Hash.CurrentKey)]  := True;

  CheckTrue(aPresent[0], 'Key1 was not in the iteration!');
  CheckTrue(aPresent[1], 'Key2 was not in the iteration!');
  CheckTrue(aPresent[2], 'Key3 was not in the iteration!');
end;


function THashesPOTest.GetHash(): TX2POHash;
begin
  Result  := TX2POHash(FHash);
end;

{ THashesVariantTest }
procedure THashesVariantTest.SetUp;
begin
  inherited;

  FHash := TX2SVHash.Create();
end;

function THashesVariantTest.GetHash(): TX2SVHash;
begin
  Result  := TX2SVHash(FHash);
end;

procedure THashesVariantTest.FillTestItems;
begin
  Hash['Key1']  := 'String';
  Hash['Key2']  := 5;
  Hash['Key3']  := 40.4;
end;

procedure THashesVariantTest.testSet;
begin
  FillTestItems();
  CheckEquals(3, Hash.Count);
end;

procedure THashesVariantTest.testGet;
begin
  FillTestItems();
  CheckTrue(Hash['Key1'] = 'String');
  CheckTrue(Hash['Key2'] = 5);
  CheckTrue(Hash['Key3'] = 40.4);
end;

procedure THashesVariantTest.testDelete;
begin
  FillTestItems();
  Hash.Delete('Key2');

  CheckEquals(2, Hash.Count);
  CheckTrue(Hash.Exists('Key1'), 'Key1 does not exist!');
  CheckFalse(Hash.Exists('Key2'), 'Key2 still exists!');
  CheckTrue(Hash.Exists('Key3'), 'Key3 does not exist!');
end;

procedure THashesVariantTest.testEnumerator;
begin
  Check(True, 'Not implemented yet.');
end;

procedure THashesVariantTest.testIterate;
var
  aPresent:     array[0..2] of Boolean;

begin
  FillTestItems();
  FillChar(aPresent, SizeOf(aPresent), #0);
  Hash.First();
  while Hash.Next() do
    if ((Hash.CurrentKey = 'Key1') and (Hash.CurrentValue = 'String')) then
      aPresent[0] := True
    else if ((Hash.CurrentKey = 'Key2') and (Hash.CurrentValue = 5)) then
      aPresent[1] := True
    else if ((Hash.CurrentKey = 'Key3') and (Hash.CurrentValue = 40.4)) then
      aPresent[2] := True;

  CheckTrue(aPresent[0], 'Key1 was not in the iteration!');
  CheckTrue(aPresent[1], 'Key2 was not in the iteration!');
  CheckTrue(aPresent[2], 'Key3 was not in the iteration!');
end;


initialization
  RegisterTest('Hashes', THashesSITest.Suite);
  RegisterTest('Hashes', THashesPOTest.Suite);
  RegisterTest('Hashes', THashesVariantTest.Suite);

end.
