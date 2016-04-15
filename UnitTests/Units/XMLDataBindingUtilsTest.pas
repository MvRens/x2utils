unit XMLDataBindingUtilsTest;

interface
uses
  TestFramework;


type
  TXMLDataBindingUtilsTest = class(TTestCase)
  published
    procedure TestIsValidXMLChar;
    procedure TestGetValidXMLText;
    procedure TestXMLToDateTime;
    procedure TestXMLToDate;
    procedure TestDateTimeToXML;
    procedure TestDateToXML;
  end;


implementation
uses
  XMLDataBindingUtils, DateUtils, SysUtils;


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


procedure TXMLDataBindingUtilsTest.TestXMLToDateTime;
var
  dateInWintertime, dateInSummerTime : TDateTime;
begin
  // Local Time
  dateInWintertime := EncodeDateTime(2016, 2, 2, 00, 59, 59, 0);
  dateInSummerTime := EncodeDateTime(2016, 4, 9, 00, 59, 59, 0);

  // Wintertijd
  CheckEquals(dateInWintertime, XMLToDateTime('2016-02-01T23:59:59Z', xdtDateTime));
  CheckEquals(IncMilliSecond(dateInWintertime, 678), XMLToDateTime('2016-02-01T23:59:59.678Z', xdtDateTime));
  CheckEquals(dateInWintertime,  XMLToDateTime('2016-02-02T00:59:59+01:00', xdtDateTime));
  CheckEquals(IncMilliSecond(dateInWintertime, 678), XMLToDateTime('2016-02-02T00:59:59.678+01:00', xdtDateTime));

  // Zomertijd
  CheckEquals(dateInSummerTime, XMLToDateTime('2016-04-08T22:59:59Z', xdtDateTime));
  CheckEquals(IncMilliSecond(dateInSummerTime, 678), XMLToDateTime('2016-04-08T22:59:59.678Z', xdtDateTime));
  CheckEquals(dateInSummerTime, XMLToDateTime('2016-04-09T00:59:59+02:00', xdtDateTime));
  CheckEquals(IncMilliSecond(dateInSummerTime, 678), XMLToDateTime('2016-04-09T00:59:59.678+02:00', xdtDateTime));
end;


procedure TXMLDataBindingUtilsTest.TestXMLToDate;
begin
  CheckEquals(EncodeDate(2016, 2, 2), XMLToDateTime('2016-02-02', xdtDate));
  CheckEquals(EncodeDate(2016, 4, 9), XMLToDateTime('2016-04-09', xdtDate));
end;


procedure TXMLDataBindingUtilsTest.TestDateTimeToXML;
var
  dateInWintertime, dateInSummerTime : TDateTime;
begin
  dateInWintertime := EncodeDateTime(2016, 2, 1, 14, 59, 59, 0);
  dateInSummerTime := EncodeDateTime(2016, 4, 8, 14, 59, 59, 0);

  // Wintertijd
  CheckEquals('2016-02-01T13:59:59+01:00', DateTimeToXML(XMLToDateTime('2016-02-01T12:59:59Z', xdtDateTime), xdtDateTime, [xtfTimezone]));
  CheckEquals('2016-02-01T13:59:59.678+01:00', DateTimeToXML(IncMilliSecond(XMLToDateTime('2016-02-01T12:59:59Z', xdtDateTime), 678), xdtDateTime, [xtfTimezone, xtfMilliseconds]));
  CheckEquals('2016-02-01T14:59:59+01:00', DateTimeToXML(dateInWintertime, xdtDateTime, [xtfTimezone]));
  CheckEquals('2016-02-01T14:59:59.678+01:00', DateTimeToXML(IncMilliSecond(dateInWintertime, 678), xdtDateTime, [xtfTimezone, xtfMilliseconds]));

  // Zomertijd
  CheckEquals('2016-04-08T14:59:59+02:00', DateTimeToXML(XMLToDateTime('2016-04-08T12:59:59Z', xdtDateTime), xdtDateTime, [xtfTimezone]));
  CheckEquals('2016-04-08T14:59:59.678+02:00', DateTimeToXML(IncMilliSecond(XMLToDateTime('2016-04-08T12:59:59Z', xdtDateTime), 678), xdtDateTime, [xtfTimezone, xtfMilliseconds]));
  CheckEquals('2016-04-08T14:59:59+02:00', DateTimeToXML(dateInSummerTime, xdtDateTime, [xtfTimezone]));
  CheckEquals('2016-04-08T14:59:59.678+02:00', DateTimeToXML(IncMilliSecond(dateInSummerTime, 678), xdtDateTime, [xtfTimezone, xtfMilliseconds]));
end;


procedure TXMLDataBindingUtilsTest.TestDateToXML;
begin
  CheckEquals('2016-02-02', DateTimeToXML(EncodeDate(2016, 2, 2), xdtDate));
  CheckEquals('2016-04-09', DateTimeToXML(EncodeDate(2016, 4, 9), xdtDate));
end;



initialization
  RegisterTest(TXMLDataBindingUtilsTest.Suite);

end.
