program X2UtHashesTest;

{$APPTYPE CONSOLE}

uses
  madExcept,
  madLinkDisAsm,
  SysUtils,
  X2UtHashes,
  X2UtBinaryTree,
  FBTree in 'Forms\FBTree.pas' {frmBTree};


<<<<<<< .working
procedure DebugBTree(const ANode: PX2UtBTreeNode; const AIndent: Integer = 0);
begin
  WriteLn(StringOfChar(' ', AIndent), ANode^.Index);

  if Assigned(ANode^.Left) then
    DebugBTree(ANode^.Left, AIndent + 2);

  if Assigned(ANode^.Right) then
    DebugBTree(ANode^.Right, AIndent + 2);
end;


type
  THackBTree  = class(TX2UtCustomBTree);

=======
>>>>>>> .merge-right.r40
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

<<<<<<< .working
    btTest[300] := 'bla';
    btTest.Delete(300);
=======
    TfrmBTree.Execute(btTest);
>>>>>>> .merge-right.r40

<<<<<<< .working
    // Heh, hacking my own class. This is just for debugging the tree,
    // there should never be any need to access the root node outside of the
    // class otherwise, so I made it protected.
    pItem := THackBTree(btTest).Root;
    DebugBTree(pItem);

=======
>>>>>>> .merge-right.r40
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
