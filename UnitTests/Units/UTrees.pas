unit UTrees;

interface
uses
  TestFramework,
  X2UtTrees;

type
  TBinaryTreeTest = class(TTestCase)
  private
    FMemory:        Integer;
    FTree:          TX2BinaryTree;
  protected
    // If we test the memory usage in SetUp and TearDown, the values are off.
    // Instead, we manually call these functions to ensure our code is the only
    // one that gets screened...
    procedure CustomSetUp();
    procedure CustomTearDown();

    procedure CheckTree(const AValue: String);
  published
    procedure Insert();
    procedure Delete();
    procedure Clear();
  end;

implementation
uses
  SysUtils;


{ TBinaryTreeTest }
procedure TBinaryTreeTest.CustomSetUp;
begin
  FMemory := AllocMemSize;
  FTree   := TX2BinaryTree.Create();
  FTree.Insert(10);
  FTree.Insert(25);
  FTree.Insert(5);
  FTree.Insert(8);
  FTree.Insert(16);
  FTree.Insert(1);
end;

procedure TBinaryTreeTest.CustomTearDown;
begin
  FreeAndNil(FTree);

  CheckEquals(0, AllocMemSize - FMemory, 'Memory leak');
end;


procedure TBinaryTreeTest.CheckTree;
var
  sTree:        String;

begin
  sTree := '';

  FTree.First();
  while not FTree.Eof do
  begin
    sTree := sTree + Format('-%d', [FTree.CurrentKey]);
    FTree.Next();
  end;

  if Length(sTree) = 0 then
    Check(Length(AValue) = 0, 'Tree is empty')
  else
  begin
    System.Delete(sTree, 1, 1);
    CheckEquals(AValue, sTree, 'Tree content is invalid')
  end;
end;


procedure TBinaryTreeTest.Insert;
begin
  CustomSetUp();

  // In these tests we also assume that iterating through the tree is done
  // from top to bottom, left to right:
  //
  //     10
  //  5      25
  // 1 8   16
  CheckTree('10-5-1-8-25-16');

  CustomTearDown();
end;

procedure TBinaryTreeTest.Delete;
begin
  CustomSetUp();

  //     10
  //  5      25
  // 1     16
  FTree.Delete(8);
  CheckTree('10-5-1-25-16');

  //     16
  //  5      25
  // 1
  //FTree.Delete(10);
  //CheckTree('16-5-1-25');

  CustomTearDown();
end;

procedure TBinaryTreeTest.Clear;
begin
  CustomSetUp();

  FTree.Clear();
  CheckTree('');

  CustomTearDown();
end;


initialization
  RegisterTest('Trees.BinaryTree', TBinaryTreeTest.Suite);
  
end.
