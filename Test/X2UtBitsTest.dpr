program X2UtBitsTest;

{$APPTYPE CONSOLE}

uses
  X2UtBits;

var
  iTest:          Integer;
  bTest:          T32Bits absolute iTest;
  sTest:          String;

begin
  Randomize();
  iTest := Random(MaxInt);
  sTest := BitsToString(bTest, bs32);

  WriteLn('Value:    ', iTest);
  WriteLn('Bits:     ', sTest);

  bTest := StringToBits(sTest);
  WriteLn('Reversed: ', iTest);
  ReadLn;
end.
