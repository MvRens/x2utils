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
  RX2BTNode           = ^PX2BTNode;
  PX2BTNode           = ^TX2BTNode;
  TX2BTNode           = record
    Key:          Cardinal;
    Parent:       PX2BTNode;
    Left:         PX2BTNode;
    Right:        PX2BTNode;
  end;


  {** Abstract cursor.
   *
   * Trees implement a descendant to traverse through the tree.
  *}
  TX2BTCustomCursor   = class(TObject)
  private
    FRoot:        RX2BTNode;
  protected
    function GetCurrentNode(): RX2BTNode; virtual; abstract;
    function GetEof(): Boolean; virtual; abstract;
  public
    constructor Create(const ARoot: RX2BTNode); virtual;

    procedure First(); virtual; abstract;
    procedure Next(); virtual; abstract;

    property CurrentNode:     RX2BTNode read GetCurrentNode;
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
    FNode:        RX2BTNode;
  protected
    function GetCurrentNode(): RX2BTNode; override;
    function GetEof(): Boolean; override;
  public
    constructor Create(const ARoot: RX2BTNode); override;
    destructor Destroy(); override;

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
    FLastNode:    RX2BTNode;

    function GetRoot(): RX2BTNode;
    function GetCurrentKey(): Cardinal;
    function GetEof(): Boolean;
  protected
    procedure CursorNeeded();

    property Root:    RX2BTNode read GetRoot;
  protected
    // Methods which don't really need to be virtual
    // (if you have a good reason; share it with me so I can make it
    // virtual, until then it's kept normal for performance reasons)
    procedure ClearNodes();

    function FindLowestNode(const ANode: RX2BTNode): RX2BTNode;
    function FindHighestNode(const ANode: RX2BTNode): RX2BTNode;
    function FindNode(const AKey: Cardinal; out AParent: RX2BTNode): RX2BTNode;
    function FindNodeOnly(const AKey: Cardinal): RX2BTNode;

    // Virtual methods (commonly needed in descendants)
    function GetCursorClass(): TX2BTCursorClass; virtual;

    procedure AllocateNode(var ANode: PX2BTNode); virtual;
    procedure DeallocateNode(var ANode: PX2BTNode); virtual;

    procedure InsertNode(const AKey: Cardinal); virtual;
    procedure DeleteNode(const AKey: Cardinal); virtual;

    procedure DeleteLeafNode(const ANode: RX2BTNode); virtual;
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
constructor TX2BTDefaultCursor.Create;
begin
  inherited;
end;

destructor TX2BTDefaultCursor.Destroy;
begin
  inherited;
end;


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

  if Assigned(FNode^^.Left) then
    // Node has a left child
    FNode := @FNode^^.Left
  else if Assigned(FNode^^.Right) then
    // Node has a right child
    FNode := @FNode^^.Right
  else
  begin
    // Traverse up the path. If we encounter a left direction, it means we
    // can attempt to search the right part of that parent node.
    repeat
      pChild  := FNode^;
      FNode   := @FNode^^.Parent;

      if Assigned(FNode^) then
      begin
        if FNode^^.Left = pChild then
        begin
          FNode := @FNode^^.Right;
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
  Result  := (not Assigned(FNode)) or (not Assigned(FNode^));
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
  Result  := Assigned(FindNodeOnly(AKey)^);
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
  pNode := Root^;

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
        if pNode = pParent^.Left then
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
  Root^     := nil;
end;


function TX2BinaryTree.FindHighestNode;
begin
  Result  := ANode;

  while Assigned(Result^) and Assigned(Result^^.Right) do
    Result  := @Result^^.Right;
end;

function TX2BinaryTree.FindLowestNode;
begin
  Result  := ANode;

  while Assigned(Result^) and Assigned(Result^^.Left) do
    Result  := @Result^^.Left;
end;

function TX2BinaryTree.FindNode;
begin
  // Quick check; was this node found previously
  if Assigned(FLastNode) and Assigned(FLastNode^) and
     (FLastNode^^.Key = AKey) then
  begin
    Result  := FLastNode;
    exit;
  end;

  AParent   := nil;
  FLastNode := nil;

  Result    := Root;
  while Assigned(Result^) do
    if AKey = Result^^.Key then
      break
    else
    begin
      AParent := Result;

      if AKey < Result^^.Key then
        Result  := @Result^^.Left
      else
        Result  := @Result^^.Right;
    end;

  if Assigned(Result^) then
    FLastNode := Result;
end;

function TX2BinaryTree.FindNodeOnly;
var
  pDummy:       RX2BTNode;

begin
  Result  := FindNode(AKey, pDummy);
end;


procedure TX2BinaryTree.InsertNode;
var
  pNode:      RX2BTNode;
  pParent:    RX2BTNode;

begin
  pNode := FindNode(AKey, pParent);
  if Assigned(pNode^) then
    raise EBTKeyExists.CreateFmt(RSBTKeyExists, [AKey]);

  AllocateNode(pNode^);
  FLastNode       := pNode;
  pNode^^.Key     := AKey;

  if Assigned(pParent) then
    pNode^^.Parent  := pParent^;
end;

procedure TX2BinaryTree.DeleteNode;
var
  pNode:      RX2BTNode;

begin
  //! Implement DeleteNode
  pNode := FindNodeOnly(AKey);
  if not Assigned(pNode^) then
    raise EBTKeyNotFound.CreateFmt(RSBTKeyNotFound, [AKey]);

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
  if Assigned(pNode^^.Left) and Assigned(pNode^^.Right) then
  begin

  end;

  // At this point, the node is a leaf node or has only one branch
  DeleteLeafNode(pNode);
end;

procedure TX2BinaryTree.DeleteLeafNode;
begin
  //! Implement DeleteLeafNode
end;


procedure TX2BinaryTree.CursorNeeded;
begin
  if not Assigned(FCursor) then
    FCursor := GetCursorClass().Create(Root);
end;


function TX2BinaryTree.GetCursorClass;
begin
  Result  := TX2BTDefaultCursor;
end;


function TX2BinaryTree.GetRoot;
begin
  Result  := @FRoot;
end;

function TX2BinaryTree.GetCurrentKey;
begin
  if Eof then
    raise EBTCursorEof.Create(RSBTCursorEof);

  Result  := FCursor.CurrentNode^^.Key;
end;

function TX2BinaryTree.GetEof;
begin
  Result  := Assigned(FCursor) and (FCursor.Eof);
end;

end.
