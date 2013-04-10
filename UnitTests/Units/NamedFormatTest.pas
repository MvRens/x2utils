unit NamedFormatTest;

interface
uses
  TestFramework;


type
  TNamedFormatTest = class(TTestCase)
  published
    procedure TestString;
    procedure TestNumbers;
    procedure TestUnusedKeys;
    procedure TestLiteralPercent;
    procedure TestLiteralPercentLiteralBracket;
  end;


implementation
uses
  X2UtNamedFormat;


{ TNamedFormatTest }
procedure TNamedFormatTest.TestString;
begin
  CheckEquals('Key = Value', NamedFormat('%<NamedKey>:s = %<NamedValue>:s', ['NamedValue', 'Value',
                                                                             'NamedKey', 'Key']));
end;


procedure TNamedFormatTest.TestNumbers;
begin
  CheckEquals('The answer is, in fact, 42',
              NamedFormat('The %<Answer>:s is, in fact, %<LifeUniverseEverything>:d', ['Answer', 'answer',
                                                                                       'LifeUniverseEverything', 42]));
end;


procedure TNamedFormatTest.TestUnusedKeys;
begin
  CheckEquals('Used', NamedFormat('%<Used>:s', ['Used', 'Used',
                                                'NotUsed', 'NotUsed']));
end;


procedure TNamedFormatTest.TestLiteralPercent;
begin
  CheckEquals('LIKE ''Test%''', NamedFormat('LIKE ''%<Value>:s%%''', ['Value', 'Test']));
end;


procedure TNamedFormatTest.TestLiteralPercentLiteralBracket;
begin
 CheckEquals('%<Test', NamedFormat('%%<%<Value>:s', ['Value', 'Test']));
end;


initialization
  RegisterTest(TNamedFormatTest.Suite);
  
end.
