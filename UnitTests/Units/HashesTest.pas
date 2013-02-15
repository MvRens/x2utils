unit HashesTest;

{$I X2UtCompilerVersion.inc}

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
    procedure TearDown; override;
    procedure FillTestItems; virtual; abstract;
  published
    procedure testSet; virtual; abstract;
    procedure testGet; virtual; abstract;
    procedure testClear;
    procedure testDelete; virtual; abstract;
    procedure testIterate; virtual; abstract;
    procedure testEnumerator; virtual; abstract;
  end;

  // Two test cases involving all value managers.
  // This should be sufficient for a realistic scenario.
  THashesSITest = class(THashesTest)
  private
    function GetHash: TX2SIHash;

    property Hash:      TX2SIHash read GetHash;
  protected
    procedure SetUp; override;
    procedure FillTestItems; override;
  published
    procedure testSet; override;
    procedure testGet; override;
    procedure testDelete; override;
    procedure testIterate; override;
    procedure testIterateEmpty;
    procedure testEnumerator; override;
  end;

  THashesPOTest = class(THashesTest)
  private
    function GetHash: TX2POHash;

    property Hash:      TX2POHash read GetHash;
  protected
    procedure SetUp; override;
    procedure FillTestItems; override;
  published
    procedure testSet; override;
    procedure testGet; override;
    procedure testDelete; override;
    procedure testIterate; override;
    procedure testEnumerator; override;
  end;

  THashesVariantTest  = class(THashesTest)
  private
    function GetHash: TX2SVHash;

    property Hash:      TX2SVHash read GetHash;
  protected
    procedure SetUp; override;
    procedure FillTestItems; override;
  published
    procedure testSet; override;
    procedure testGet; override;
    procedure testDelete; override;
    procedure testIterate; override;
    procedure testEnumerator; override;
  end;

  THashesBugTest = class(TTestCase)
  published
    procedure testAccessViolation;
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
  FillTestItems;
  FHash.Clear;
  CheckEquals(0, FHash.Count);
end;


{ THashesSITest }
procedure THashesSITest.SetUp;
begin
  inherited;

  FHash := TX2SIHash.Create;
end;

procedure THashesSITest.FillTestItems;
begin
  Hash['Key1']  := 1;
  Hash['Key2']  := 2;
  Hash['Key3']  := 3;
end;

procedure THashesSITest.testSet;
begin
  FillTestItems;
  CheckEquals(3, Hash.Count);
end;

procedure THashesSITest.testGet;
begin
  FillTestItems;
  CheckEquals(1, Hash['Key1']);
  CheckEquals(2, Hash['Key2']);
  CheckEquals(3, Hash['Key3']);
end;

procedure THashesSITest.testDelete;
begin
  FillTestItems;
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
  {$IFDEF D2006PLUS}
  FillTestItems;
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
  {$ENDIF}

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
  FillTestItems;
  FillChar(aPresent, SizeOf(aPresent), #0);
  Hash.First;
  while Hash.Next do
    if ((Hash.CurrentKey = 'Key1') and (Hash.CurrentValue = 1)) or
       ((Hash.CurrentKey = 'Key2') and (Hash.CurrentValue = 2)) or
       ((Hash.CurrentKey = 'Key3') and (Hash.CurrentValue = 3)) then
      aPresent[Hash.CurrentValue] := True;

  CheckTrue(aPresent[1], 'Key1 was not in the iteration!');
  CheckTrue(aPresent[2], 'Key2 was not in the iteration!');
  CheckTrue(aPresent[3], 'Key3 was not in the iteration!');
end;


procedure THashesSITest.testIterateEmpty;
begin
  Hash.First;
  CheckFalse(Hash.Next, 'Next');
end;


function THashesSITest.GetHash: TX2SIHash;
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
  Hash[Pointer(0)]  := TObject0.Create;
  Hash[Pointer(1)]  := TObject1.Create;
  Hash[Pointer(2)]  := TObject2.Create;
end;

procedure THashesPOTest.testSet;
begin
  FillTestItems;
  CheckEquals(3, Hash.Count);
end;

procedure THashesPOTest.testGet;
begin
  FillTestItems;
  CheckTrue(Hash[Pointer(0)] is TObject0);
  CheckTrue(Hash[Pointer(1)] is TObject1);
  CheckTrue(Hash[Pointer(2)] is TObject2);
end;

procedure THashesPOTest.testDelete;
begin
  FillTestItems;
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
  {$IFDEF D2006PLUS}
  FillTestItems;
  FillChar(aPresent, SizeOf(aPresent), #0);

  for pKey in Hash do
    aPresent[Integer(pKey)] := True;

  CheckTrue(aPresent[0], 'Key1 was not in the enumeration!');
  CheckTrue(aPresent[1], 'Key2 was not in the enumeration!');
  CheckTrue(aPresent[2], 'Key3 was not in the enumeration!');
  {$ENDIF}
end;

procedure THashesPOTest.testIterate;
var
  aPresent:     array[0..2] of Boolean;

begin
  FillTestItems;
  FillChar(aPresent, SizeOf(aPresent), #0);
  Hash.First;
  while Hash.Next do
    if ((Hash.CurrentKey = Pointer(0)) and (Hash.CurrentValue is TObject0)) or
       ((Hash.CurrentKey = Pointer(1)) and (Hash.CurrentValue is TObject1)) or
       ((Hash.CurrentKey = Pointer(2)) and (Hash.CurrentValue is TObject2)) then
      aPresent[Integer(Hash.CurrentKey)]  := True;

  CheckTrue(aPresent[0], 'Key1 was not in the iteration!');
  CheckTrue(aPresent[1], 'Key2 was not in the iteration!');
  CheckTrue(aPresent[2], 'Key3 was not in the iteration!');
end;


function THashesPOTest.GetHash: TX2POHash;
begin
  Result  := TX2POHash(FHash);
end;

{ THashesVariantTest }
procedure THashesVariantTest.SetUp;
begin
  inherited;

  FHash := TX2SVHash.Create;
end;

function THashesVariantTest.GetHash: TX2SVHash;
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
  FillTestItems;
  CheckEquals(3, Hash.Count);
end;

procedure THashesVariantTest.testGet;
begin
  FillTestItems;
  CheckTrue(Hash['Key1'] = 'String');
  CheckTrue(Hash['Key2'] = 5);
  CheckTrue(Hash['Key3'] = 40.4);
end;

procedure THashesVariantTest.testDelete;
begin
  FillTestItems;
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
  FillTestItems;
  FillChar(aPresent, SizeOf(aPresent), #0);
  Hash.First;
  while Hash.Next do
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


{ THashesBugTest }
procedure THashesBugTest.testAccessViolation;
const
  TestValues: array[0..878] of Integer =
              (
                2480044, 2480046, 2480174, 2480187, 2480188, 2480210,
                2490187, 2500044, 2500046, 2500174, 2500187, 2500188,
                2500210, 2530046, 2530174, 2530187, 2530188, 2530210,
                2550046, 2550174, 2550187, 2550188, 2550210, 2560046,
                4920097, 4920098, 4920218, 4930098, 4930099, 4930218,
                4940097, 4940098, 4950098, 4950099, 4950218, 5070102,
                5070164, 5090102, 5090164, 5090222, 5100102, 5110102,
                5110164, 5120102, 5130104, 5130159, 5130177, 5140104,
                5140105, 5140159, 5140177, 5160159, 5160177, 5210105,
                5210159, 5210177, 5210184, 5210236, 5210237, 5210238,
                5210290, 5210297, 5210321, 5220105, 5220159, 5220177,
                5220184, 5220236, 5220237, 5220238, 5220290, 5220297,
                5220321, 5240105, 5240159, 5240177, 5240184, 5240236,
                5240237, 5240238, 5370105, 5370159, 5370177, 5370184,
                5370236, 5370237, 5370238, 5370290, 5370297, 5380105,
                5380159, 5380177, 5380184, 5380236, 5380237, 5380238,
                5380290, 5380297, 5400105, 5400159, 5400177, 5400184,
                5400236, 5400237, 5400238, 5450107, 5460107, 5480108,
                5480109, 5480220, 5480238, 5530107, 5530158, 5540107,
                5540112, 5540158, 5550112, 5550113, 5550176, 5550253,
                5560108, 5560109, 5560158, 5560176, 5560220, 5560237,
                5560238, 5690105, 5690107, 5690108, 5690109, 5690176,
                5690184, 5690220, 5700105, 5700107, 5700112, 5700184,
                5700220, 5770110, 5790112, 5790114, 5790158, 5800110,
                5850111, 5930105, 5930107, 5930159, 5930177, 5930184,
                5940107, 5940238, 5950105, 5950107, 5950159, 5950177,
                5950184, 5960107, 5960112, 5960158, 5960238, 5980108,
                5980109, 5980158, 5980220, 5980237, 5980238, 6000112,
                6000113, 6000176, 6330108, 6330109, 6330176, 6330220,
                6340105, 6340184, 6350108, 6350109, 6350176, 6350220,
                6350238, 6360238, 6370108, 6370109, 6370176, 6370220,
                6370237, 6370238, 6380220, 6380238, 6400119, 6400120,
                6410119, 6410120, 6410121, 6410125, 6410221, 6420119,
                6420120, 6420121, 6430119, 6430120, 6430121, 6430221,
                6430251, 6440119, 6440120, 6440121, 6440124, 6440125,
                6440221, 6490120, 6490121, 6490125, 6490221, 8290152,
                8290153, 8290155, 8300152, 8300153, 8300154, 8300155,
                8300156, 8300157, 8310152, 8310153, 8310154, 8310155,
                8310156, 8310157, 8320153, 8320154, 8320155, 8320156,
                8320157, 8330153, 8330154, 8330155, 8330156, 8330157,
                8330302, 8340152, 8340153, 8340155, 8340255, 8340273,
                8340275, 8340299, 8340300, 8340335, 8340375, 8350152,
                8350153, 8350154, 8350155, 8350156, 8350157, 8350256,
                8350275, 8350299, 8350300, 8350302, 8350335, 8360152,
                8360153, 8360154, 8360155, 8360156, 8360157, 8370154,
                8370155, 8370156, 8370157, 8370241, 8370302, 8380152,
                8380153, 8380155, 8390152, 8390153, 8390154, 8390155,
                8390156, 8390157, 8400152, 8400153, 8400154, 8400155,
                8400156, 8400157, 8410153, 8410154, 8410155, 8410156,
                8410157, 8420153, 8420154, 8420155, 8420156, 8420157,
                8420302, 8430152, 8430153, 8430155, 8430255, 8430273,
                8430275, 8430299, 8430300, 8430335, 8430375, 8440152,
                8440153, 8440154, 8440155, 8440156, 8440157, 8440256,
                8440275, 8440299, 8440300, 8440302, 8440335, 8450152,
                8450153, 8450154, 8450155, 8450156, 8450157, 8460154,
                8460155, 8460156, 8460157, 8460241, 8460302, 8470098,
                8480102, 8480164, 8490110, 8490158, 8490176, 8490220,
                8500110, 8500158, 8500176, 8500220, 8600119, 8600120,
                8600121, 8600124, 8600125, 8600221, 8600251, 8620120,
                8630119, 8700188, 8700210, 8700211, 8710188, 8710210,
                8710211, 8720158, 8720220, 8730102, 8730164, 8740102,
                8740103, 8740164, 8740165, 8780215, 8780216, 8790215,
                8790216, 8790217, 8800216, 8800217, 8800258, 8800259,
                8800338, 8810215, 8810216, 8810217, 8810257, 8810258,
                8810259, 8810281, 8820152, 8820153, 8820154, 8820155,
                8820156, 8820157, 8830152, 8830153, 8830154, 8830155,
                8830156, 8830157, 8840152, 8840153, 8840154, 8840155,
                8840156, 8840157, 8850152, 8850153, 8850154, 8850155,
                8850156, 8850157, 8930119, 8930120, 8930121, 8950158,
                8950219, 9150223, 9150224, 9150276, 9160223, 9160224,
                9160225, 9160276, 9170223, 9170224, 9170225, 9170291,
                9330223, 9330224, 9340223, 9340224, 9340225, 9340226,
                9350223, 9350224, 9350225, 9370224, 9380226, 9380229,
                9380230, 9510224, 9510227, 9520224, 9520225, 9520227,
                9520254, 9520276, 9530224, 9530225, 9530254, 9530276,
                9530292, 9550224, 9560227, 9560229, 9560230, 9560254,
                9560276, 9560292, 9630224, 9640224, 9640225, 9640226,
                9640254, 9640276, 9650224, 9650225, 9650254, 9650276,
                9650292, 9680226, 9680229, 9680230, 9690224, 9690254,
                9690276, 9700224, 9700225, 9700226, 9700254, 9700276,
                9710224, 9710225, 9710254, 9710276, 9710291, 9710292,
                9720232, 9740226, 9740229, 9740230, 9740254, 9740276,
                9740292, 9930227, 9930228, 9940227, 9940228, 9960232,
                9960233, 9980227, 9980230, 9980292, 9990224, 9990227,
                10000224, 10000225, 10000227, 10010224, 10010225, 10020232,
                10020254, 10020293, 10040227, 10040230, 10040254, 10040276,
                10040292, 10050224, 10050227, 10060224, 10060225, 10060227,
                10060254, 10060276, 10070224, 10070225, 10070254, 10070276,
                10070292, 10080232, 10080254, 10080293, 10100227, 10100230,
                10100254, 10100276, 10100292, 10230228, 10240227, 10240228,
                10260233, 10350234, 10350235, 10350295, 10350343, 10360235,
                10360295, 10370234, 10370235, 10370295, 10370343, 10380235,
                10380295, 10390119, 10390120, 10390121, 10390125, 10390221,
                10390251, 10390317, 10390342, 10400119, 10400120, 10400121,
                10400125, 10400221, 10400251, 10400317, 10400342, 10450239,
                10450240, 10460240, 10470240, 10470241, 10480239, 10480240,
                10480241, 10500152, 10500153, 10500155, 10500255, 10500273,
                10500275, 10500299, 10500300, 10500335, 10500375, 10520152,
                10520153, 10520154, 10520155, 10520156, 10520157, 10520256,
                10520275, 10520300, 10520302, 10520335, 10520376, 10530152,
                10530153, 10530154, 10530155, 10530156, 10530157, 10530256,
                10530275, 10530300, 10530335, 10550152, 10550153, 10550155,
                10550255, 10550273, 10550275, 10550299, 10550300, 10550335,
                10550375, 10560152, 10560153, 10560154, 10560155, 10560156,
                10560157, 10560256, 10560275, 10560300, 10560302, 10560335,
                10560376, 10570152, 10570153, 10570154, 10570155, 10570156,
                10570157, 10570256, 10570275, 10570300, 10570335, 10580152,
                10580153, 10580154, 10580155, 10580156, 10580157, 10580256,
                10580300, 10580302, 10580335, 10590152, 10590153, 10590154,
                10590155, 10590156, 10590157, 10590256, 10590300, 10590302,
                10590335, 10600187, 10600188, 10600210, 10610187, 10610188,
                10610210, 10630216, 10630217, 10630258, 10630259, 10630281,
                10640215, 10640216, 10640217, 10640257, 10640258, 10640338,
                10650215, 10650216, 10650217, 10650257, 10650258, 10650259,
                10660097, 10660098, 10660218, 10670097, 10670098, 10680098,
                10680099, 10680218, 10690102, 10690164, 10700102, 10700164,
                10700222, 10700320, 10710102, 10710103, 10710165, 10720244,
                10720245, 10720277, 10720309, 10720336, 10720346, 10730244,
                10730245, 10730246, 10730248, 10730260, 10730277, 10740245,
                10750246, 10750248, 10750260, 10760246, 10760260, 10760336,
                10760346, 10770246, 10770260, 10770336, 10770346, 10780247,
                10780334, 10790244, 10790245, 10790246, 10790277, 10790309,
                10800244, 10800245, 10800246, 10800260, 10800277, 10810246,
                10810247, 10810248, 10810260, 10810334, 10810366, 10820244,
                10820245, 10820246, 10820249, 10820277, 10820309, 10820336,
                10820346, 10830244, 10830245, 10830246, 10830248, 10830249,
                10830260, 10830277, 10840245, 10850246, 10850248, 10850249,
                10850260, 10860246, 10860249, 10860260, 10860336, 10860346,
                10870246, 10870249, 10870260, 10870336, 10870346, 10870365,
                10880244, 10880245, 10880246, 10880249, 10880277, 10880309,
                10890244, 10890245, 10890246, 10890249, 10890260, 10890277,
                10900246, 10900247, 10900248, 10900249, 10900260, 10900366,
                10910154, 10910302, 10920154, 10920302, 10930241, 10930252,
                10930302, 10940241, 10940252, 10940302, 10950188, 10950210,
                10960216, 10960217, 10960258, 10960259, 10960281, 10970223,
                10970224, 10980223, 10980224, 10980226, 10980254, 10980276,
                10990223, 10990224, 10990254, 10990276, 10990291, 10990292,
                11000226, 11000229, 11000230, 11000254, 11000276, 11000292,
                11010224, 11010276, 11020119, 11020120, 11020121, 11020125,
                11020221, 11020251, 11020317, 11020342, 11080264, 11080265,
                11090264, 11120264, 11130264, 11130265, 11140264, 11140265,
                11150264, 11160264, 11160265, 11170264, 11170265, 11180264,
                11190264, 11200264, 11210264, 11210265, 11220264, 11220265,
                11230264, 11240264, 11250264, 11260264, 11280264, 11290264,
                11300264, 11310264, 11320264, 11330264, 11340264, 11350264,
                11360264, 11370264, 11390264, 11400264, 11410264, 11420264,
                11430264, 11440264, 11450264);

var
  hash: TX2IIHash;
  valueIndex: Integer;

begin
  { Bug found in an import application when a bucket overflows }
  hash := TX2IIHash.Create;
  try
    for valueIndex := Low(TestValues) to High(TestValues) do
      hash[TestValues[valueIndex]] := valueIndex;

    for valueIndex := Low(TestValues) to High(TestValues) do
      CheckEquals(hash[TestValues[valueIndex]], valueIndex, 'Index: ' + IntToStr(valueIndex));
  finally
    FreeAndNil(hash);
  end;
end;


initialization
  RegisterTest('Hashes', THashesSITest.Suite);
  RegisterTest('Hashes', THashesPOTest.Suite);
  RegisterTest('Hashes', THashesVariantTest.Suite);
  RegisterTest('Hashes', THashesBugTest.Suite);

end.
