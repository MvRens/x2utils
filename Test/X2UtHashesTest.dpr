program X2UtHashesTest;

{$APPTYPE CONSOLE}

uses
  madExcept,
  madLinkDisAsm,
  SysUtils,
  X2UtHashes,
  X2UtBinaryTree,
  FBTree in 'Forms\FBTree.pas' {frmBTree};


var
  shData:       TX2StringHash;
  btTest:       TX2StringBTree;
  iItem:        Integer;
  pItem:        PX2BTreeNode;

begin
  // Test binary tree
  btTest  := TX2StringBTree.Create();
  try
    Randomize();
    for iItem := 0 to 61 do
      btTest[Random(500)] := 'bla';
    btTest[40]  := 'bla2';
    btTest[50]  := 'bla3';

    if btTest.Exists(40, True) then
      WriteLn(btTest.CurrentValue);

    WriteLn;
    btTest.Reset();
    while btTest.Next() do
      WriteLn(btTest.CurrentIndex, ' - ', btTest.CurrentValue);

    TfrmBTree.Execute(btTest);
  finally
    FreeAndNil(btTest);
    ReadLn;
  end;

  (*
  shData  := TX2UtStringHash.Create();
  try
    shData['thisakslhalskdjfhaslkdfjhaslkfjh']  := 'is';
    shData['a']     := 'test';

    TfrmBTree.Execute(shData);

    {
    shData.Reset();
    while shData.Next() do
      WriteLn(shData.CurrentKey, ': ', shData.CurrentValue, ' (',
              shData[shData.CurrentKey], ')');
      }
  finally
    FreeAndNil(shData);
    //ReadLn;
  end;
  *)
end.
