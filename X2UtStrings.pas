{
  :: X2UtStrings provides various string-related functions.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtStrings;

interface
type
  TSplitArray = array of String;
  
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

  //:$ Splits a string on the specified delimiter
  procedure Split(const ASource, ADelimiter: String; out ADest: TSplitArray);

  //:$ Appends the strings with the specified glue string
  function Join(const ASource: TSplitArray; const AGlue: String): String;

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


procedure Split;
  // StrPos is slow. Sloooooow slow. This function may not be advanced or
  // the fastest one around, but it sure kicks StrPos' ass.
  // 11.5 vs 1.7 seconds on a 2.4 Ghz for 10.000 iterations, baby!
  function StrPosEx(const ASource, ASearch: PChar): PChar;
  var
    pPos:           PChar;
    pSub:           PChar;

  begin
    Result  := nil;

    // Search for the first character
    pPos    := ASource;

    while pPos^ <> #0 do
    begin
      if pPos^ = ASearch^ then
      begin
        // Found the first character, match the rest
        pSub    := ASearch;
        Result  := pPos;
        Inc(pSub);
        Inc(pPos);


        while pSub^ <> #0 do
        begin
          if pPos^ <> pSub^ then
          begin
            // No match, resume as normal
            Result  := nil;
            break;
          end;

          Inc(pSub);
          Inc(pPos);
        end;

        // If still assigned, all characters matched
        if Assigned(Result) then
          exit;
      end else
        Inc(pPos);
    end;
  end;

const
  GrowStart = 32;
  GrowMax   = 256;

var
  iCapacity:          Integer;
  iCount:             Integer;
  iDelimLen:          Integer;
  iLength:            Integer;
  iPos:               Integer;
  iSize:              Integer;
  pDelimiter:         PChar;
  pLast:              PChar;
  pPos:               PChar;

begin
  // Reserve some space
  iCapacity   := GrowStart;
  iCount      := 0;
  SetLength(ADest, iCapacity);

  iDelimLen   := Length(ADelimiter);
  iLength     := Length(ASource);
  iPos        := -1;
  pDelimiter  := PChar(ADelimiter);
  pPos        := PChar(ASource);

  repeat
    // Find delimiter
    pLast     := pPos;
    pPos      := StrPosEx(pPos, pDelimiter);

    if pPos <> nil then
    begin
      // Make space
      Inc(iCount);
      if iCount > iCapacity then
      begin
        if iCapacity < GrowMax then
          Inc(iCapacity, iCapacity)
        else
          Inc(iCapacity, GrowMax);

        SetLength(ADest, iCapacity);
      end;

      // Copy substring
      iSize := Integer(pPos) - Integer(pLast);
      SetString(ADest[iCount - 1], pLast, iSize);

      // Move pointer
      Inc(pPos, iDelimLen);
      Inc(iPos, iSize + iDelimLen);
    end else
    begin
      if iPos < iLength then
      begin
        // Copy what's left
        Inc(iCount);
        if iCount > iCapacity then
          SetLength(ADest, iCount);

        ADest[iCount - 1] := pLast;
      end;

      if iCount <> iCapacity then
        // Shrink array
        SetLength(ADest, iCount);

      break;
    end;
  until False;
end;

function Join;
var
  iGlue:          Integer;
  iHigh:          Integer;
  iItem:          Integer;
  iLength:        Integer;
  pGlue:          PChar;
  pPos:           PChar;

begin
  if High(ASource) = -1 then
  begin
    Result  := '';
    exit;
  end;

  iGlue   := Length(AGlue);
  pGlue   := PChar(AGlue);
  iLength := -iGlue;

  // First run: calculate the size we need to reserve (two loops should
  // generally be more efficient than a lot of memory resizing)
  iHigh := High(ASource);
  for iItem := iHigh downto 0 do
    Inc(iLength, Length(ASource[iItem]) + iGlue);

  SetLength(Result, iLength);
  pPos    := PChar(Result);
  Inc(pPos, Length(Result));

  // Copy last item
  iLength := Length(ASource[iHigh]);
  Dec(pPos, iLength);
  Move(PChar(ASource[iHigh])^, pPos^, iLength);

  // Copy remaining items and glue strings
  for iItem := iHigh - 1 downto 0 do
  begin
    Dec(pPos, iGlue);
    Move(pGlue^, pPos^, iGlue);

    iLength := Length(ASource[iItem]);
    Dec(pPos, iLength);
    Move(PChar(ASource[iItem])^, pPos^, iLength);
  end;
end;

end.

