{** Various tree implementations.
 *
 * Last changed:    $Date$ <br />
 * Revision:        $Rev$ <br />
 * Author:          $Author$ <br />
}
unit X2UtTrees;

interface
uses
  SysUtils;

type
  EBTKeyExists        = class(Exception);
  EBTKeyNotFound      = class(Exception);
  EBTCursorEof        = class(Exception);

  {** Internal representation of a binary tree node.
   *
   * For the sake of easy lookups and cleaner code I chose to let nodes know
   * who their parent is. It costs 4 bytes... but that's only 4 megabytes
   * overhead for each million nodes, not much of a burden nowadays.
  *}
  TX2BTLinks          = array[0..11] of Byte;
  PX2BTNode           = ^TX2BTNode;
  TX2BTNode           = record
    Key:          Cardinal;

    case Boolean of
      True:
        (
          Parent:   PX2BTNode;
          Left:     PX2BTNode;
          Right:    PX2BTNode;
        );
      False:
        (
          Links:    TX2BTLinks;
        );
  end;


  {** Abstract cursor.
   *
   * Trees implement a descendant to traverse through the tree.
  *}
  TX2BTCustomCursor   = class(TObject)
  private
    FRoot:        PX2BTNode;
  protected
    function GetCurrentNode(): PX2BTNode; virtual; abstract;
    function GetEof(): Boolean; virtual; abstract;
  public
    constructor Create(const ARoot: PX2BTNode); virtual;

    procedure First(); virtual; abstract;
    procedure Next(); virtual; abstract;

    property CurrentNode:     PX2BTNode read GetCurrentNode;
    property Eof:             Boolean   read GetEof;
  end;

  TX2BTCursorClass    = class of TX2BTCustomCursor;


  {** Default tree cursor.
   *
   * The default cursor traverses through the tree from top to bottom, left
   * to right.
  *}
  TX2BTDefaultCursor  = class(TX2BTCustomCursor)
  private
    FNode:        PX2BTNode;
  protected
    function GetCurrentNode(): PX2BTNode; override;
    function GetEof(): Boolean; override;
  public
    procedure First(); override;
    procedure Next(); override;
  end;


  {** Binary Tree implementation.
   *
   * Implements the basic binary tree operations, allowing room for descendants
   * to implement data storage and node management.
  *}
  TX2BinaryTree       = class(TObject)
  private
    FCursor:      TX2BTCustomCursor;
    FRoot:        PX2BTNode;
    FLastNode:    PX2BTNode;

    function GetCurrentKey(): Cardinal;
    function GetEof(): Boolean;
  protected
    procedure CursorNeeded();
    procedure InvalidateCursor();

    //property Root:    PX2BTNode read FRoot  write FRoot;
  protected
    // Methods which don't really need to be virtual
    // (if you have a good reason; share it with me so I can make it
    // virtual, until then it's kept normal for performance reasons)
    procedure ClearNodes();

    function FindLowestNode(const ANode: PX2BTNode): PX2BTNode;
    function FindHighestNode(const ANode: PX2BTNode): PX2BTNode;
    function FindNode(const AKey: Cardinal; out AParent: PX2BTNode): PX2BTNode;
    function FindNodeOnly(const AKey: Cardinal): PX2BTNode;

    function LeftChild(const ANode: PX2BTNode): Boolean;
    function RightChild(const ANode: PX2BTNode): Boolean;

    procedure SwapNodes(const ANode1, ANode2: PX2BTNode);

    // Virtual methods (commonly needed in descendants)
    function GetCursorClass(): TX2BTCursorClass; virtual;

    procedure AllocateNode(var ANode: PX2BTNode); virtual;
    procedure DeallocateNode(var ANode: PX2BTNode); virtual;

    procedure InsertNode(const AKey: Cardinal); virtual;
    procedure DeleteNode(const AKey: Cardinal); virtual;

    procedure DeleteCleanNode(var ANode: PX2BTNode); virtual;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    {** Removes all nodes from the tree.
    *}
    procedure Clear();

    {** Checks if a key already exists within the tree.
     *
     * @param AKey  the key to search for
     * @result      True if the key exists, False otherwise
    *}
    function Exists(const AKey: Cardinal): Boolean;

    {** Inserts a key into the tree.
     *
     * If a key already exists, an exception is raised.
     *
     * @param AKey  the key for the new node
    *}
    procedure Insert(const AKey: Cardinal);

    {** Deletes a key from the tree.
     *
     * If the key could not be found, an exception is raised.
     *
     * @param AKey  the key to delete
    *}
    procedure Delete(const AKey: Cardinal);

    {** Resets the cursor to the first node.
     *
     * Call First before iterating over all nodes. If no nodes are available,
     * Eof will be set to True.
    *}
    procedure First();

    {** Sets the cursor to the next node.
     *
     * Call Next while iterating over all nodes. If no more nodes are available,
     * Eof will be set to True.
    *}
    procedure Next();

    {** Returns the current key.
     *
     * Note: CurrentKey is only available when the cursor is valid.
    *}
    property CurrentKey:      Cardinal  read GetCurrentKey;

    {** Determines if there are more nodes available.
     *
     * Read Eof before accessing CurrentKey to determine if the cursor is
     * positioned at a valid node.
    *}
    property Eof:             Boolean   read GetEof;
  end;

implementation
resourcestring
  RSBTKeyExists   = 'The key "%d" already exists in the tree.';
  RSBTKeyNotFound = 'The key "%d" could not be found in the tree.';
  RSBTCursorEof   = 'Cursor is at Eof.';



{====================== TX2BTCustomCursor
  Initialization
========================================}
constructor TX2BTCustomCursor.Create;
begin
  inherited Create();

  FRoot := ARoot;
end;


{===================== TX2BTDefaultCursor
  Traversal
========================================}
procedure TX2BTDefaultCursor.First;
begin
  FNode := FRoot;
end;

procedure TX2BTDefaultCursor.Next;
var
  pChild:       PX2BTNode;

begin
  if Eof then
    raise EBTCursorEof.Create(RSBTCursorEof);

  if Assigned(FNode^.Left) then
    // Node has a left child
    FNode := FNode^.Left
  else if Assigned(FNode^.Right) then
    // Node has a right child
    FNode := FNode^.Right
  else
  begin
    // Traverse up the path. If we encounter a left direction, it means we
    // can attempt to search the right part of that parent node.
    repeat
      pChild  := FNode;
      FNode   := FNode^.Parent;

      if Assigned(FNode) then
      begin
        if (FNode^.Left = pChild) and Assigned(FNode^.Right) then
        begin
          FNode := FNode^.Right;
          break;
        end;
      end else
      begin
        FNode := nil;
        break;
      end;
    until False;
  end;
end;


function TX2BTDefaultCursor.GetCurrentNode;
begin
  Result  := FNode;
end;

function TX2BTDefaultCursor.GetEof;
begin
  Result  := not Assigned(FNode);
end;


{========================== TX2BinaryTree
  Initialization
========================================}
constructor TX2BinaryTree.Create;
begin
  inherited;
end;

destructor TX2BinaryTree.Destroy;
begin
  ClearNodes();
  FreeAndNil(FCursor);

  inherited;
end;


{========================== TX2BinaryTree
  Interface
========================================}
procedure TX2BinaryTree.Clear;
begin
  ClearNodes();
end;

function TX2BinaryTree.Exists;
begin
  Result  := Assigned(FindNodeOnly(AKey));
end;

procedure TX2BinaryTree.Insert;
begin
  InsertNode(AKey);
end;

procedure TX2BinaryTree.Delete;
begin
  DeleteNode(AKey);
end;


procedure TX2BinaryTree.First;
begin
  CursorNeeded();
  FCursor.First();
end;

procedure TX2BinaryTree.Next;
begin
  CursorNeeded();
  FCursor.Next();
end;


{========================== TX2BinaryTree
  Internal node operations
========================================}
procedure TX2BinaryTree.AllocateNode;
begin
  GetMem(ANode, SizeOf(TX2BTNode));
  FillChar(ANode^, SizeOf(TX2BTNode), #0);
end;

procedure TX2BinaryTree.DeallocateNode;
begin
  FreeMem(ANode, SizeOf(TX2BTNode));
  ANode := nil;
end;


procedure TX2BinaryTree.ClearNodes;
var
  pNode:      PX2BTNode;
  pParent:    PX2BTNode;

begin
  pNode := FRoot;;

  while Assigned(pNode) do
  begin
    if Assigned(pNode^.Left) then
      // Move down on the left side
      pNode := pNode^.Left
    else if Assigned(pNode^.Right) then
      // Move down on the right side
      pNode := pNode^.Right
    else
    begin
      // Disconnect node from parent
      pParent := pNode^.Parent;
      if Assigned(pParent) then
        if LeftChild(pNode) then
          pParent^.Left   := nil
        else
          pParent^.Right  := nil;

      DeallocateNode(pNode);

      // Continue on the parent
      if Assigned(pParent) then
        pNode := pParent;
    end;
  end;

  FLastNode := nil;
  FRoot     := nil;
end;


function TX2BinaryTree.FindHighestNode;
begin
  Result  := ANode;

  while Assigned(Result) and Assigned(Result^.Right) do
    Result  := Result^.Right;
end;

function TX2BinaryTree.FindLowestNode;
begin
  Result  := ANode;

  while Assigned(Result) and Assigned(Result^.Left) do
    Result  := Result^.Left;
end;

function TX2BinaryTree.FindNode;
var
  pNode:        PX2BTNode;

begin
  // Quick check; was this node found previously
  if Assigned(FLastNode) and (FLastNode^.Key = AKey) then
  begin
    Result  := FLastNode;
    exit;
  end;

  AParent   := nil;
  FLastNode := nil;
  Result    := nil;
  pNode     := FRoot;

  while Assigned(pNode) do
    if AKey = pNode^.Key then
    begin
      Result  := pNode;
      break;
    end else
    begin
      AParent := pNode;

      if AKey < pNode^.Key then
        pNode := pNode^.Left
      else
        pNode := pNode^.Right;
    end;

  if Assigned(Result) then
    FLastNode := Result;
end;

function TX2BinaryTree.FindNodeOnly;
var
  pDummy:       PX2BTNode;

begin
  Result  := FindNode(AKey, pDummy);
end;


function TX2BinaryTree.LeftChild;
begin
  Assert(Assigned(ANode^.Parent), 'Node has no parent!');
  Result  := (ANode^.Parent^.Left = ANode);
end;

function TX2BinaryTree.RightChild;
begin
  Result  := not LeftChild(ANode);
end;


procedure TX2BinaryTree.SwapNodes;
  procedure FixLinks(const ANode, AOld: PX2BTNode);
  begin
    if Assigned(ANode^.Parent) then
      if ANode^.Parent^.Left = AOld then
        ANode^.Parent^.Left   := ANode
      else
        ANode^.Parent^.Right  := ANode;

    if Assigned(ANode^.Left) then
      ANode^.Left^.Parent     := ANode;

    if Assigned(ANode^.Right) then
      ANode^.Right^.Parent    := ANode;
  end;

var
  pBuffer:      TX2BTLinks;

begin
  pBuffer       := ANode1.Links;
  ANode1.Links  := ANode2.Links;
  ANode2.Links  := pBuffer;

  FixLinks(ANode1, ANode2);
  FixLinks(ANode2, ANode1);

  if FRoot = ANode1 then
    FRoot       := ANode2
  else if FRoot = ANode2 then
    FRoot       := ANode1;
end;


procedure TX2BinaryTree.InsertNode;
var
  pNode:      PX2BTNode;
  pParent:    PX2BTNode;

begin
  pNode := FindNode(AKey, pParent);
  if Assigned(pNode) then
    raise EBTKeyExists.CreateFmt(RSBTKeyExists, [AKey]);

  InvalidateCursor();
  AllocateNode(pNode);
  FLastNode       := pNode;
  if not Assigned(FRoot) then
    FRoot         := pNode;
    
  pNode^.Key      := AKey;

  if Assigned(pParent) then
  begin
    pNode^.Parent     := pParent;

    if AKey < pParent^.Key then
      pParent^.Left   := pNode
    else
      pParent^.Right  := pNode;
  end;
end;

procedure TX2BinaryTree.DeleteNode;
var
  pNode:      PX2BTNode;
  pLowest:    PX2BTNode;

begin
  pNode := FindNodeOnly(AKey);
  if not Assigned(pNode) then
    raise EBTKeyNotFound.CreateFmt(RSBTKeyNotFound, [AKey]);

  InvalidateCursor();
  
  // If the node to be deleted has either one or no branch, it can simply be
  // taken out of the chain. If it has two branches, find the lowest key on
  // the right branch and swap it.
  //
  // Ex. delete 7 from the tree:
  //
  //      8                       8
  //     7    <-+                4
  //  2     5   |     >>>     2     5
  // 1 3   4 6  |            1 3     6
  //       +----+
  if Assigned(pNode^.Left) and Assigned(pNode^.Right) then
  begin
    pLowest := FindLowestNode(pNode^.Right);
    SwapNodes(pNode, pLowest);
  end;

  // At this point, the node is a leaf node or has only one branch
  DeleteCleanNode(pNode);
end;

procedure TX2BinaryTree.DeleteCleanNode;
var
  pParent:        PX2BTNode;
  pChild:         PX2BTNode;

begin
  pParent := ANode^.Parent;

  // A 'clean' node is defined as a node with 0 or 1 child, which is easy
  // to remove from the chain.
  Assert(not (Assigned(ANode^.Left) and
              Assigned(ANode^.Right)), 'Node is not a clean node!');

  if Assigned(ANode^.Left) then
    pChild  := ANode^.Left
  else
    pChild  := ANode^.Right;

  // Link the parent to the new child
  if Assigned(pParent) then
    if LeftChild(ANode) then
      pParent^.Left   := pChild
    else
      pParent^.Right  := pChild;

  // Link the child to the new parent
  if Assigned(pChild) then
    pChild^.Parent    := pParent;

  if ANode = FRoot then
    FRoot := pChild;
    
  DeallocateNode(ANode);
end;


procedure TX2BinaryTree.CursorNeeded;
begin
  if not Assigned(FCursor) then
    FCursor := GetCursorClass().Create(FRoot);
end;

procedure TX2BinaryTree.InvalidateCursor;
begin
  FreeAndNil(FCursor);
end;


function TX2BinaryTree.GetCursorClass;
begin
  Result  := TX2BTDefaultCursor;
end;


function TX2BinaryTree.GetCurrentKey;
begin
  if Eof then
    raise EBTCursorEof.Create(RSBTCursorEof);

  Result  := FCursor.CurrentNode^.Key;
end;

function TX2BinaryTree.GetEof;
begin
  Result  := Assigned(FCursor) and (FCursor.Eof);
end;

end.
