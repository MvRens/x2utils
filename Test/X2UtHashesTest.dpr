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
  shData:       TX2UtStringHash;
  btTest:       TX2UtStringBTree;
  iItem:        Integer;
  pItem:        PX2UtBTreeNode;

begin
  // Test binary tree
  {
  btTest  := TX2UtStringBTree.Create();
  try
    Randomize();
    for iItem := 0 to 61 do
      btTest[Random(500)] := 'bla';

    TfrmBTree.Execute(btTest);

    WriteLn;
    btTest.Reset();
    while btTest.Next() do
      WriteLn(btTest.CurrentIndex, ' - ', btTest.CurrentValue);
  finally
    FreeAndNil(btTest);
    //ReadLn;
  end;
  }

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
end.
