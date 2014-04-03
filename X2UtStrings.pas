{** Provides various string-related functions.
 *
 * Last changed:  $Date$ <br />
 * Revision:      $Rev$ <br />
 * Author:        $Author$ <br />
*}
unit X2UtStrings;

interface
uses
  Types;

type
  {** Backwards compatibility }
  TSplitArray = TStringDynArray;
  
  
  {** Formats the specified size.
   *
   * @param ABytes      the size to format in bytes.
   * @param AKeepBytes  if true, only decimal separators will be added and
   *                    the text 'bytes' appended. If False, a suitable unit
   *                    will be chosen (KB, MB, GB).
   * @param AFormat     the format used for the output, see the Delphi Help for
   *                    FormatFloat.
   * @result            the formatted size.
  *}
  function FormatSize(const ABytes: Int64; AKeepBytes: Boolean = False;
                      const AFormat: String = ',0.##'): String;

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
  procedure Split(const ASource, ADelimiter: String; out ADest: TStringDynArray; ASkipEmptyItems: Boolean = False);

  {** Appends string parts with a specified glue value.
   *
   * @param ASource         the source parts
   * @param AGlue           the string added between the parts
   * @param ASkipEmptyItems if True, include only items of Length > 0
   * @result                the composed parts
  *}
  function Join(ASource: array of string; const AGlue: String; ASkipEmptyItems: Boolean = False): String; 

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

function FormatSize(const ABytes: Int64; AKeepBytes: Boolean;
                    const AFormat: String): String;
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

  Result  := FormatFloat(AFormat, dSize) + sExt;
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


procedure Split(const ASource, ADelimiter: String; out ADest: TStringDynArray; ASkipEmptyItems: Boolean);
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
  capacity: Integer;
  count: Integer;
  delimiterLength: Integer;
  sourceLength: Integer;
  position: Integer;
  size: Integer;
  delimiter: PChar;
  lastPos: PChar;
  currentPos: PChar;

begin
  // Reserve some space
  capacity := GrowStart;
  count := 0;
  SetLength(ADest, capacity);

  delimiterLength := Length(ADelimiter);
  sourceLength := Length(ASource);
  position := 0;
  delimiter := PChar(ADelimiter);
  currentPos := PChar(ASource);

  repeat
    // Find delimiter
    lastPos := currentPos;
    currentPos := StrPosEx(currentPos, delimiter);

    if currentPos <> nil then
    begin
      size := (Integer(currentPos) - Integer(lastPos)) div SizeOf(Char);

      if (size > 0) or (not ASkipEmptyItems) then
      begin
        // Make space
        Inc(count);
        if count > capacity then
        begin
          if capacity < GrowMax then
            Inc(capacity, capacity)
          else
            Inc(capacity, GrowMax);

          SetLength(ADest, capacity);
        end;

        // Copy substring
        SetString(ADest[count - 1], lastPos, size);
      end;

      // Move pointer
      Inc(currentPos, delimiterLength);
      Inc(position, size + delimiterLength);
    end else
    begin
      if position < sourceLength then
      begin
        // Copy what's left
        Inc(count);
        if count > capacity then
          SetLength(ADest, count);

        ADest[count - 1] := lastPos;
      end;

      if count <> capacity then
        // Shrink array
        SetLength(ADest, count);

      break;
    end;
  until False;
end;


function Join(ASource: array of string; const AGlue: string; ASkipEmptyItems: Boolean): string;
var
  totalLength: Integer;
  itemIndex: Integer;
  itemLength: Integer;
  itemCount: Integer;
  glueLength: Integer;
  resultPos: PChar;
  firstItem: Boolean;

begin
  if High(ASource) = -1 then
  begin
    Result  := '';
    exit;
  end;

  { Om geheugen-reallocaties te verminderen, vantevoren even
    uitrekenen hoe groot het resultaat gaat worden. }
  itemCount := 0;
  totalLength := 0;

  for itemIndex := High(ASource) downto Low(ASource) do
  begin
    if (not ASkipEmptyItems) or (Length(ASource[itemIndex]) > 0) then
    begin
      Inc(totalLength, Length(ASource[itemIndex]));
      Inc(itemCount);
    end;
  end;

  glueLength := Length(AGlue);
  Inc(totalLength, Pred(itemCount) * glueLength);
  
  SetLength(Result, totalLength);

  firstItem := True;
  resultPos := PChar(Result);

  for itemIndex := Low(ASource) to High(ASource) do
  begin
    itemLength := Length(ASource[itemIndex]);

    if (not ASkipEmptyItems) or (itemLength > 0) then
    begin
      if not firstItem then
      begin
        Move(PChar(AGlue)^, resultPos^, glueLength);
        Inc(resultPos, glueLength);
      end else
        firstItem := False;

      Move(PChar(ASource[itemIndex])^, resultPos^, itemLength);
      Inc(resultPos, itemLength);
    end;
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

