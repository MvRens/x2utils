unit StringsTest;

interface
uses
  TestFramework;


type
  TStringsTest = class(TTestCase)
  published
    procedure TestSplit;
  end;


implementation
uses
  System.Types,

  X2UtStrings;


{ TStringsTest }
procedure TStringsTest.TestSplit;
var
  items: TStringDynArray;

begin
  Split('value1/value2', '/', items);
  CheckEquals(2, Length(items), 'Length');
  CheckEquals('value1', items[0], 'Items[0]');
  CheckEquals('value2', items[1], 'Items[1]');
end;

initialization
  RegisterTest('Strings', TStringsTest.Suite);

end.
