{** Provides various string-related functions.
 *
 * Last changed:  $Date$ <br />
 * Revision:      $Rev$ <br />
 * Author:        $Author$ <br />
*}
unit X2UtStrings;

interface
type
  //** Array of string values.
  TSplitArray = array of String;

  {** Formats the specified size.
   *
   * @param ABytes      the size to format in bytes.
   * @param AKeepBytes  if true, only decimal separators will be added and
   *                    the text 'bytes' appended. If False, a suitable unit
   *                    will be chosen (KB, MB, GB).
   * @result            the formatted size.
  *}
  function FormatSize(const ABytes: Int64; AKeepBytes: Boolean = False): String;

  {** Compares two strings without case sensitivity.
   *
   * @param AMatch      the string to match.
   * @param AAgainst    the string to match against.
   * @param ALength     the maximum length to compare.
   * @result            -1 if AMatch is lower by ordinal value than AAgainst,
   *                    0 if the two are equal, 1 if AMatch is higher.
  *}
  function CompareTextL(const AMatch, AAgainst: String;
                        const ALength: Integer): Integer;

  {** Compares two strings without case sensitivity.
   *
   * @param AMatch      the string to match.
   * @param AAgainst    the string to match against.
   * @param ALength     the maximum length to compare.
   * @result            True if the comparison is a match, False otherwise.
  *}
  function SameTextL(const AMatch, AAgainst: String;
                     const ALength: Integer): Boolean;

  {** Compares two strings without case sensitivity.
   *
   * The length of AAgainst is used as the maximum length to check.
   *
   * @param AMatch      the string to match
   * @param AAgainst    the string to match against
   * @result            -1 if AMatch is lower by ordinal value than AAgainst,
   *                    0 if the two are equal, 1 if AMatch is higher.
  *}
  function CompareTextS(const AMatch, AAgainst: String): Integer;

  {** Compares two strings without case sensitivity.
   *
   * The length of AAgainst is used as the maximum length to check.
   *
   * @param AMatch      the string to match.
   * @param AAgainst    the string to match against.
   * @result            True if the comparison is a match, False otherwise.
  *}
  function SameTextS(const AMatch, AAgainst: String): Boolean;

  {** Splits a string on a specified delimiter.
   *
   * @param ASource     the source string.
   * @param ADelimiter  the delimiter to split on.
   * @param ADest       the array which will receive the split parts.
   * @todo              though optimized, it now fails on #0 characters, need
   *                    to determine the end by checking the AnsiString length.
  *}
  procedure Split(const ASource, ADelimiter: String; out ADest: TSplitArray);

  {** Appends string parts with a specified glue value.
   *
   * @param ASource     the source parts
   * @param AGlue       the string added between the parts
   * @result            the composed parts
  *}
  function Join(const ASource: TSplitArray; const AGlue: String): String;

  {** Determines if one path is the child of another path.
   *
   * Matches the start of two normalized paths. Either of the path may contain
   * parent-references (ex. 'some\..\..\path\'). Note that the file system is
   * not actually accessed, all checks are performed on the strings only.
   *
   * @param AChild      the path to check
   * @param AParent     the path which is supposed to be the parent
   * @param AFailIfSame if True, fails if the child path is the parent path
   * @result            True if the child is indeed a child of the parent,
   *                    False otherwise.
  *}
  function ChildPath(const AChild, AParent: String;
                     const AFailIfSame: Boolean = False): Boolean;

  {** Determines if one path is the child of another path.
   *
   * Matches the start of two normalized paths. Either of the path may contain
   * parent-references (ex. 'some\..\..\path\'). Note that the file system is
   * not actually accessed, all checks are performed on the strings only.
   *
   * The parameters are modified to return the expanded file names, stripped
   * of any trailing path delimiter.
   *
   * @param AChild      the path to check
   * @param AParent     the path which is supposed to be the parent
   * @param AFailIfSame if True, fails if the child path is the parent path
   * @result            True if the child is indeed a child of the parent,
   *                    False otherwise.
  *}
  function ChildPathEx(var AChild, AParent: String;
                       const AFailIfSame: Boolean = False): Boolean;

  function ReplacePart(const ASource: String; const AStart, ALength: Integer;
                       const AReplace: String): String;

implementation
uses
  SysUtils,
  Windows;

function FormatSize(const ABytes: Int64; AKeepBytes: Boolean = False): String;
const
  KB  = 1024;
  MB  = KB * 1024;
  GB  = MB * 1024;

var
  dSize:      Double;
  sExt:       String;

begin
  sExt  := ' bytes';
  dSize := ABytes;

  if (not AKeepBytes) and (ABytes >= KB) then
    if (ABytes >= KB) and (ABytes < MB) then begin
      // 1 kB ~ 1 MB
      dSize := ABytes / KB;
      sExt  := ' KB';
    end else if (ABytes >= MB) and (ABytes < GB) then begin
      // 1 MB ~ 1 GB
      dSize := ABytes / MB;
      sExt  := ' MB';
    end else begin
      // 1 GB ~ x
      dSize := ABytes / GB;
      sExt  := ' GB';
    end;

  Result  := FormatFloat(',0.##', dSize) + sExt;
end;

function CompareTextL(const AMatch, AAgainst: String;
                      const ALength: Integer): Integer;
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

function SameTextL(const AMatch, AAgainst: String;
                   const ALength: Integer): Boolean;
begin
  Result  := (CompareTextL(AMatch, AAgainst, ALength) = 0);
end;

function CompareTextS(const AMatch, AAgainst: String): Integer;
begin
  Result  := CompareTextL(AMatch, AAgainst, Length(AAgainst));
end;

function SameTextS(const AMatch, AAgainst: String): Boolean;
begin
  Result  := SameTextL(AMatch, AAgainst, Length(AAgainst));
end;


procedure Split(const ASource, ADelimiter: String; out ADest: TSplitArray);
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

function Join(const ASource: TSplitArray; const AGlue: String): String;
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


function ChildPath(const AChild, AParent: String;
                   const AFailIfSame: Boolean): Boolean;
var
  sChild:       String;
  sParent:      String;

begin
  sChild  := AChild;
  sParent := AParent;
  Result  := ChildPathEx(sChild, sParent, AFailIfSame);
end;

function ChildPathEx(var AChild, AParent: String;
                     const AFailIfSame: Boolean): Boolean;
begin
  AChild  := ExcludeTrailingPathDelimiter(ExpandFileName(AChild));
  AParent := ExcludeTrailingPathDelimiter(ExpandFileName(AParent));
  Result  := SameTextS(AChild, AParent) and
             ((not AFailIfSame) or
              (Length(AChild) > Length(AParent)));
end;


function ReplacePart(const ASource: String; const AStart, ALength: Integer;
                     const AReplace: String): String;
var
  iSrcLength: Integer;
  iLength:    Integer;
  iDiff:      Integer;
  iDest:      Integer;

begin
  iSrcLength  := Length(ASource);
  iLength     := Length(AReplace);
  iDiff       := iLength - ALength;
  iDest       := 1;

  SetLength(Result, iSrcLength + iDiff);

  // Write first part
  CopyMemory(@Result[iDest], @ASource[1], AStart - 1);
  Inc(iDest, AStart - 1);

  // Write replacement
  CopyMemory(@Result[iDest], @AReplace[1], iLength);
  Inc(iDest, iLength);

  // Write last part
  CopyMemory(@Result[iDest], @ASource[AStart + ALength],
             iSrcLength - AStart - (ALength - 1));
end;

end.

