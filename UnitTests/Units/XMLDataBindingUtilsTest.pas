unit XMLDataBindingUtilsTest;

interface
uses
  TestFramework;


type
  TXMLDataBindingUtilsTest = class(TTestCase)
  published
    procedure TestIsValidXMLChar;
    procedure TestGetValidXMLText;
  end;


implementation
uses
  XMLDataBindingUtils;


{ TXMLDataBindingUtilsTest }
procedure TXMLDataBindingUtilsTest.TestIsValidXMLChar;
begin
  CheckTrue(IsValidXMLChar('A'));
  CheckTrue(IsValidXMLChar('ë'));
  CheckFalse(IsValidXMLChar(#$1A));
end;


procedure TXMLDataBindingUtilsTest.TestGetValidXMLText;
begin
  CheckEquals('AB', GetValidXMLText('AB'));
end;


initialization
  RegisterTest(TXMLDataBindingUtilsTest.Suite);

end.
