{
  :: X2UtStrings provides various string-related functions.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtStrings;

interface
  //:$ Formats the specified size
  //:: If KeepBytes is true, the size will be formatted for decimal separators
  //:: and 'bytes' will be appended. If KeepBytes is false the best suitable
  //:: unit will be chosen (KB, MB, GB).
  function FormatSize(const Bytes: Int64; KeepBytes: Boolean = False): String;

  //:$ Compares two strings by ordinal value without case sensitivity up to
  //:$ ALength characters.
  function CompareTextL(const AMatch, AAgainst: String;
                        const ALength: Integer): Integer;

  //:$ Compares two strings by ordinal value without case sensitivity up to
  //:$ ALength characters.
  function SameTextL(const AMatch, AAgainst: String;
                     const ALength: Integer): Boolean;

  //:$ Compares AMatch against AAgainst using AAgainst's length.
  function CompareTextS(const AMatch, AAgainst: String): Integer;

  //:$ Compares AMatch against AAgainst using AAgainst's length.
  function SameTextS(const AMatch, AAgainst: String): Boolean;

implementation
uses
  SysUtils;

function FormatSize;
const
  KB  = 1024;
  MB  = KB * 1024;
  GB  = MB * 1024;

var
  dSize:      Double;
  sExt:       String;

begin
  sExt  := ' bytes';
  dSize := Bytes;

  if (not KeepBytes) and (Bytes >= KB) then
    if (Bytes >= KB) and (Bytes < MB) then begin
      // 1 kB ~ 1 MB
      dSize := Bytes / KB;
      sExt  := ' KB';
    end else if (Bytes >= MB) and (Bytes < GB) then begin
      // 1 MB ~ 1 GB
      dSize := Bytes / MB;
      sExt  := ' MB';
    end else begin
      // 1 GB ~ x
      dSize := Bytes / GB;
      sExt  := ' GB';
    end;

  Result  := FormatFloat(',0.##', dSize) + sExt;
end;

function CompareTextL;
var
  sMatch:       String;
  sAgainst:     String;

begin
  // If there is no reason to copy; don't.
  if Length(AMatch) <= ALength then
    sMatch    := AMatch
  else
    sMatch    := Copy(AMatch, 1, ALength);

  if Length(AAgainst) <= ALength then
    sAgainst  := AAgainst
  else
    sAgainst  := Copy(AAgainst, 1, ALength);

  Result  := CompareText(sMatch, sAgainst);
end;

function SameTextL;
begin
  Result  := (CompareTextL(AMatch, AAgainst, ALength) = 0);
end;

function CompareTextS;
begin
  Result  := CompareTextL(AMatch, AAgainst, Length(AAgainst));
end;

function SameTextS;
begin
  Result  := SameTextL(AMatch, AAgainst, Length(AAgainst));
end;

end.

