program X2UtStringsTest;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,

  FastStrings,
  
  X2UtStrings;

var
  GFreq:        Int64;
  GStart:       Int64;

procedure TimeStart();
begin
  QueryPerformanceFrequency(GFreq);
  QueryPerformanceCounter(GStart);
end;

procedure TimeEnd();
var
  iEnd:         Int64;

begin
  QueryPerformanceCounter(iEnd);
  WriteLn(Format('%.6f seconds', [(iEnd - GStart) / GFreq]));
end;


procedure OldSplit(const ASource, ADelimiter: String; out ADest: TSplitArray);
var
  iCount:     Integer;
  iPos:       Integer;
  iLength:    Integer;
  sTemp:      String;

begin
  sTemp   := ASource;
  iCount  := 0;
  iLength := Length(ADelimiter) - 1;

  repeat
    iPos := Pos(ADelimiter, sTemp);

    if iPos = 0 then
      break
    else begin
      Inc(iCount);
      SetLength(ADest, iCount);
      ADest[iCount - 1] := Copy(sTemp, 1, iPos - 1);
      Delete(sTemp, 1, iPos + iLength);
    end;
  until False;

  if Length(sTemp) > 0 then begin
    Inc(iCount);
    SetLength(ADest, iCount);
    ADest[iCount - 1] := sTemp;
  end;
end;

procedure OldFastStringsSplit(const ASource, ADelimiter: String; out ADest: TSplitArray);
const
  BufferSize  = 50;

var
  iCount:           Integer;
  iSize:            Integer;
  iPos:             Integer;
  iDelimLength:     Integer;
  iLength:          Integer;
  iLastPos:         Integer;

begin
  iCount        := 0;
  iDelimLength  := Length(ADelimiter);
  iLength       := Length(ASource);
  iPos          := 1;
  iLastPos      := 1;
  iSize         := BufferSize;
  SetLength(ADest, iSize);

  repeat
    iPos  := FastPos(ASource, ADelimiter, iLength, iDelimLength, iPos);

    if iPos = 0 then
      break
    else begin
      ADest[iCount] := Copy(ASource, iLastPos, iPos - iLastPos);
      Inc(iPos, iDelimLength);
      iLastPos      := iPos;

      Inc(iCount);
      if iCount >= iSize then begin
        Inc(iSize, BufferSize);
        SetLength(ADest, iSize);
      end;
    end;
  until False;


  if iLastPos <= iLength then begin
    ADest[iCount] := Copy(ASource, iLastPos, iLength - iLastPos + 1);
    Inc(iCount);
  end;

  if iSize <> iCount then
    SetLength(ADest, iCount);
end;


var
  sTest:          String;
  iCount:         Integer;
  aSplit:         TSplitArray;

begin
  sTest := 'this|isateststring||';
  for iCount  := 0 to 7 do
    sTest := sTest + sTest;

  TimeStart();
  Write('10.000 iterations of OldSplit: ');
  for iCount  := 0 to 9999 do
    OldSplit(sTest, '|', aSplit);
  TimeEnd();

  TimeStart();
  Write('10.000 iterations of OldFastStringsSplit: ');
  for iCount  := 0 to 9999 do
    OldFastStringsSplit(sTest, '|', aSplit);
  TimeEnd();

  TimeStart();
  Write('10.000 iterations of Split: ');
  for iCount  := 0 to 9999 do
    Split(sTest, '||', aSplit);
  TimeEnd();

  ReadLn;
end.
