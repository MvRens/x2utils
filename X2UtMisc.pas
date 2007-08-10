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
uses
  Types;
  
  
  //:$ Returns IfTrue or IfFalse depending on the Value
  function iif(const AValue: Boolean; const AIfTrue: Integer;
               const AIfFalse: Integer = 0): Integer; overload;

  //:$ Returns IfTrue or IfFalse depending on the Value
  function iif(const AValue: Boolean; const AIfTrue: String;
               const AIfFalse: String = ''): String; overload;

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
  //:: the value is returned. The overloads without a Default parameter
  //:: return the nearest Min or Max value. 
  function InRange(const AValue, AMin, AMax, ADefault: Integer): Integer; overload;
  function InRange(const AValue, AMin, AMax, ADefault: Int64): Int64; overload;
  function InRange(const AValue, AMin, AMax: Integer): Integer; overload;
  function InRange(const AValue, AMin, AMax: Int64): Int64; overload;

  //:$ Returns the width of a rectangle
  function RectWidth(const ARect: TRect): Integer; inline;

  //:$ Returns the height of a rectangle
  function RectHeight(const ARect: TRect): Integer; inline;


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


function InRange(const AValue, AMin, AMax, ADefault: Integer): Integer;
begin
  Result  := ADefault;

  if (AValue >= AMin) and (AValue <= AMax) then
    Result  := AValue;
end;


function InRange(const AValue, AMin, AMax, ADefault: Int64): Int64;
begin
  Result  := ADefault;

  if (AValue >= AMin) and (AValue <= AMax) then
    Result  := AValue;
end;


function InRange(const AValue, AMin, AMax: Integer): Integer;
begin
  Result  := AValue;

  if Result < AMin then
    Result  := AMin
  else if Result > AMax then
    Result  := AMax;
end;


function InRange(const AValue, AMin, AMax: Int64): Int64;
begin
  Result  := AValue;

  if Result < AMin then
    Result  := AMin
  else if Result > AMax then
    Result  := AMax;
end;


function RectWidth(const ARect: TRect): Integer;
begin
  Result  := (ARect.Right - ARect.Left);
end;


function RectHeight(const ARect: TRect): Integer;
begin
  Result  := (ARect.Bottom - ARect.Top);
end;

end.
