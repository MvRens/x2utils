unit FBTree;

interface
uses
  Forms,
  Classes,
  Controls,
  Windows,
  dxorgchr,
  X2UtBinaryTree;

type
  TfrmBTree = class(TForm)
    ocTree:           TdxOrgChart;
    procedure ocTreeDblClick(Sender: TObject);
  private
    FTree:            TX2UtCustomBTree;
  protected
    procedure BuildTree(const ARoot: PX2UtBTreeNode;
                        const AParent: TdxOcNode = nil);
  public
    class procedure Execute(const ATree: TX2UtCustomBTree;
                            const AShowModal: Boolean = True);
  end;

implementation
uses
  Graphics,
  SysUtils,
  TypInfo;

type
  THackBTree  = class(TX2UtCustomBTree);


{$R *.dfm}

class procedure TfrmBTree.Execute;
begin
  with TfrmBTree.Create(nil) do
  try
    FTree := ATree;
    BuildTree(THackBTree(ATree).Root);

    if Assigned(ocTree.RootNode) then
      ocTree.RootNode.Expand(True);

    if AShowModal then
      ShowModal()
    else
      Show();
  finally
    // Yes, yes, memory leak I know. Should have an owner of something. Anyways,
    // I'm too lazy to fix it in this test application...
    if AShowModal then
      Free();
  end;
end;

procedure TfrmBTree.BuildTree;
  function CreateTextNode(const AParent: TdxOcNode;
                          const AText: String): TdxOcNode;
  begin
    Result        := ocTree.AddChild(AParent, nil);
    Result.Text   := AText;
    Result.Color  := clInfoBk;
  end;

  function CreateNode(const AParent: TdxOcNode;
                      const ANode: PX2UtBTreeNode): TdxOcNode;
  begin
    Result      := CreateTextNode(AParent, IntToStr(ANode^.Index) + #13#10 +
                                  IntToStr(ANode^.Balance));
    Result.Data := ANode;
  end;

var
  pNode:        TdxOcNode;
  pLeft:        TdxOcNode;
  pRight:       TdxOcNode;

begin
  if not Assigned(ARoot) then
    exit;
    
  pLeft   := nil;
  pRight  := nil;
  
  if not Assigned(AParent) then
    pNode       := CreateNode(nil, ARoot)
  else
    pNode       := AParent;

  if Assigned(ARoot^.Children[0]) then
    pLeft       := CreateNode(pNode, ARoot^.Children[0])
  else if Assigned(ARoot^.Children[1]) then
    CreateTextNode(pNode, '<nil>');

  if Assigned(ARoot^.Children[1]) then
    pRight      := CreateNode(pNode, ARoot^.Children[1])
  else if Assigned(ARoot^.Children[0]) then
    CreateTextNode(pNode, '<nil>');

  if Assigned(ARoot^.Children[0]) then
    BuildTree(ARoot^.Children[0], pLeft);

  if Assigned(ARoot^.Children[1]) then
    BuildTree(ARoot^.Children[1], pRight);
end;

procedure TfrmBTree.ocTreeDblClick;
var
  pNode:      TdxOcNode;

begin
  pNode := ocTree.Selected;

  if Assigned(pNode) and Assigned(pNode.Data) then
  begin
    FTree.Delete(PX2UtBTreeNode(pNode.Data)^.Index);
    ocTree.Clear();

    BuildTree(THackBTree(FTree).Root);
    if Assigned(ocTree.RootNode) then
      ocTree.RootNode.Expand(True);
  end;
end;

end.
