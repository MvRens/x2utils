unit UBits;

interface
uses
  TestFramework;

type
  TBitsTest = class(TTestCase)
  published
    procedure testGet();
    procedure testSet();
    procedure testCombine();

    procedure testBitsToString();
    procedure testStringToBits();
  end;

implementation
uses
  X2UtBits;

const
  BitsTest    = [bit1, bit2, bit4, bit7];
  BitsValue   = 150;
  BitsString  = '10010110';


{ TBitsTest }
procedure TBitsTest.testGet;
var
  bValue:         Byte;
  eBits:          T8Bits absolute bValue;

begin
  bValue  := BitsValue;
  Check(eBits = BitsTest, 'Bits do not match the value!');
end;

procedure TBitsTest.testSet;
var
  bValue:         Byte;
  eBits:          T8Bits absolute bValue;

begin
  eBits   := BitsTest;
  Check(bValue = BitsValue, 'Value does not match the bits!');
end;

procedure TBitsTest.testCombine;
var
  eBits1:         T8Bits;
  eBits2:         T8Bits;
  bValue:         Byte absolute eBits1;

begin
  eBits1  := [bit1, bit7];
  eBits2  := [bit2, bit4];
  eBits1  := eBits1 + eBits2;

  Check(bValue = BitsValue, 'Value does not match the bits!');
end;


procedure TBitsTest.testBitsToString;
var
  eBits:          T8Bits;
  sValue:         String;

begin
  eBits   := BitsTest;
  sValue  := BitsToString(eBits, bs8);

  Check(sValue = BitsString, 'Bits do not match the string!');
end;

procedure TBitsTest.testStringToBits;
var
  eBits:          T8Bits;
  sValue:         String;

begin
  sValue  := BitsString;
  eBits   := StringToBits(sValue);

  Check(eBits = BitsTest, 'String does not match the bits!');
end;


initialization
  RegisterTest('Bits', TBitsTest.Suite);

end.
