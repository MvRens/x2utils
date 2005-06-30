program X2UtHashesTest2;

{$APPTYPE CONSOLE}

uses
  madExcept,
  madLinkDisAsm,
  MemCheck,
  SysUtils,
  X2UtHashes;

{
var
  fDic:     TextFile;
  iCount:   Integer;
  sWord:    String;
}

begin
  MemChk();

  {
  with TX2POHash.Create(True) do
  try
    Values[Pointer(0)]  := TObject.Create();
    Values[Pointer(1)]  := TObject.Create();
    Values[Pointer(0)]  := TObject.Create();
  finally
    Free();
  end;
  }

  (*
  with TX2SIHash.Create() do
  try
    AssignFile(fDic, 'dic.txt');
    try
      iCount  := 0;
      Reset(fDic);
      while not Eof(fDic) do
      begin
        ReadLn(fDic, sWord);
        Values[sWord] := iCount;
        Inc(iCount);
      end;

      WriteLn(iCount, ' items read');
      WriteLn(Count, ' items in the hash');

      Delete('ABUTTING');
      Delete('ABUTTED');
      Delete('ABUTTED');
      WriteLn(Count, ' items in the hash after deleting');

      iCount  := 0;
      First();
      while Next() do
      begin
        //WriteLn(iCount, '. ', CurrentKey, '=', CurrentValue);
        Inc(iCount);
      end;

      WriteLn(iCount, ' items iterated');
      {
      WriteLn(Exists('ABUTTING'));
      WriteLn(Exists('AARDVARK'));
      }

    finally
      CloseFile(fDic);
    end;
  finally
    Free();
  end;
  *)

  {
  with TX2PPHash.Create() do
  try
    Values[Pointer(1)] := Pointer(1);
    Values[Pointer(2)] := Pointer(2);
    Values[Pointer(3)] := Pointer(3);
    Values[Pointer(4)] := Pointer(4);

    WriteLn(Integer(Values[Pointer(1)]));
    WriteLn(Integer(Values[Pointer(2)]));
    WriteLn(Integer(Values[Pointer(3)]));
    WriteLn(Integer(Values[Pointer(4)]));
  finally
    Free();
  end;
  }

  with TX2SSHash.Create() do
  try
    Values['Item1'] := 'Item1?';
    Values['Item2'] := 'Item2?';
    Values['Item3'] := 'Item3?';
    Values['Item4'] := 'Item4?';

    WriteLn(Values['Item1']);
    WriteLn(Values['Item2']);
    WriteLn(Values['Item3']);
    WriteLn(Values['Item4']);
  finally
    Free();
  end;

  WriteLn('Done!');
  ReadLn;
end.
