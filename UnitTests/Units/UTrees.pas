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
    procedure SetUp(); override;
    procedure TearDown(); override;

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
procedure TBinaryTreeTest.SetUp;
begin
  FMemory := GetHeapStatus().TotalAllocated;
  FTree   := TX2BinaryTree.Create();
  FTree.Insert(10);
  FTree.Insert(25);
  FTree.Insert(5);
  FTree.Insert(8);
  FTree.Insert(16);
  FTree.Insert(1);
end;

procedure TBinaryTreeTest.TearDown;
var
  iLeak:        Integer;

begin
  FreeAndNil(FTree);

  iLeak := FMemory - Integer(GetHeapStatus().TotalAllocated);
  CheckEquals(0, iLeak, 'Memory leak');
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
  // In these tests we also assume that iterating through the tree is done
  // from top to bottom, left to right:
  //
  //     10
  //  5      25
  // 1 8   16
  CheckTree('10-5-1-8-25-16');
end;

procedure TBinaryTreeTest.Delete;
begin
  FTree.Delete(8);
  FTree.Delete(10);

  //     16
  //  5      25
  // 1
  CheckTree('16-5-1-25');
end;

procedure TBinaryTreeTest.Clear;
begin
  FTree.Clear();
  CheckTree('');
end;


initialization
  RegisterTest('Trees.BinaryTree', TBinaryTreeTest.Suite);
  
end.
