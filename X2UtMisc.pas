{
  :: X2UtMisc is a collection of functions not fitting into any of the other
  :: categories.
  ::
  :: Subversion repository available at:
  ::   $URL$
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$

  :$
  :$
  :$ X2Utils is released under the zlib/libpng OSI-approved license.
  :$ For more information: http://www.opensource.org/
  :$ /n/n
  :$ /n/n
  :$ Copyright (c) 2003 X2Software
  :$ /n/n
  :$ This software is provided 'as-is', without any express or implied warranty.
  :$ In no event will the authors be held liable for any damages arising from
  :$ the use of this software.
  :$ /n/n
  :$ Permission is granted to anyone to use this software for any purpose,
  :$ including commercial applications, and to alter it and redistribute it
  :$ freely, subject to the following restrictions:
  :$ /n/n
  :$ 1. The origin of this software must not be misrepresented; you must not
  :$ claim that you wrote the original software. If you use this software in a
  :$ product, an acknowledgment in the product documentation would be
  :$ appreciated but is not required.
  :$ /n/n
  :$ 2. Altered source versions must be plainly marked as such, and must not be
  :$ misrepresented as being the original software.
  :$ /n/n
  :$ 3. This notice may not be removed or altered from any source distribution.
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

end.
