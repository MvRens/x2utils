{
  :: X2UtMisc is a collection of functions not fitting into any of the other
  :: categories.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtMisc;

interface
  //:$ Returns IfTrue or IfFalse depending on the Value
  function iif(const AValue: Boolean; const AIfTrue, AIfFalse: Integer): Integer; overload;

  //:$ Returns IfTrue or IfFalse depending on the Value
  function iif(const AValue: Boolean; const AIfTrue, AIfFalse: String): String; overload;

  //:$ Compares two integers
  //:: Returns 0 if the values are equal, 1 if Value1 is greater than Value2 and
  //:: -1 when Value1 is less than Value2.
  function CompareInt(const AValue1, AValue2: Integer): Integer; overload;

  //:$ Compares two integers
  //:: Returns 0 if the values are equal, 1 if Value1 is greater than Value2 and
  //:: -1 when Value1 is less than Value2.
  function CompareInt(const AValue1, AValue2: Cardinal): Integer; overload;

  //:$ Compares two integers
  //:: Returns 0 if the values are equal, 1 if Value1 is greater than Value2 and
  //:: -1 when Value1 is less than Value2.
  function CompareInt(const AValue1, AValue2: Int64): Integer; overload;

  //:$ Compares two floating point values
  //:: Returns 0 if the values are equal, 1 if Value1 is greater than Value2 and
  //:: -1 when Value1 is less than Value2.
  function CompareFloat(const AValue1, AValue2: Single): Integer; overload;

  //:$ Compares two floating point values
  //:: Returns 0 if the values are equal, 1 if Value1 is greater than Value2 and
  //:: -1 when Value1 is less than Value2.
  function CompareFloat(const AValue1, AValue2: Double): Integer; overload;

  //:$ Checks if the value is within the specified range
  //:: Returns the Default parameter is the range is exceeded, otherwise
  //:: the value is returned.
  function InRange(const AValue, AMin, AMax, ADefault: Integer): Integer;

implementation

function iif(const AValue: Boolean; const AIfTrue, AIfFalse: Integer): Integer;
begin
  if AValue then
    Result  := AIfTrue
  else
    Result  := AIfFalse;
end;

function iif(const AValue: Boolean; const AIfTrue, AIfFalse: String): String;
begin
  if AValue then
    Result  := AIfTrue
  else
    Result  := AIfFalse;
end;

function CompareInt(const AValue1, AValue2: Integer): Integer;
begin
  Result  := 0;
  if AValue1 > AValue2 then
    Result  := 1
  else if AValue1 < AValue2 then
    Result  := -1;
end;

function CompareInt(const AValue1, AValue2: Cardinal): Integer;
begin
  Result  := 0;
  if AValue1 > AValue2 then
    Result  := 1
  else if AValue1 < AValue2 then
    Result  := -1;
end;

function CompareInt(const AValue1, AValue2: Int64): Integer;
begin
  Result  := 0;
  if AValue1 > AValue2 then
    Result  := 1
  else if AValue1 < AValue2 then
    Result  := -1;
end;

function CompareFloat(const AValue1, AValue2: Single): Integer;
begin
  Result  := 0;
  if AValue1 > AValue2 then
    Result  := 1
  else if AValue1 < AValue2 then
    Result  := -1;
end;

function CompareFloat(const AValue1, AValue2: Double): Integer;
begin
  Result  := 0;
  if AValue1 > AValue2 then
    Result  := 1
  else if AValue1 < AValue2 then
    Result  := -1;
end;

function InRange;
begin
  Result  := ADefault;

  if (AValue >= AMin) and (AValue <= AMax) then
    Result  := AValue;
end;

end.
