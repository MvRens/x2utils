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
  EBTNoCursor         = class(Exception);

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
  protected
    function GetCurrentKey(): Cardinal; virtual; abstract;
    function GetEof(): Boolean; virtual; abstract;
  public
    procedure First(); virtual; abstract;
    procedure Next(); virtual; abstract;

    property Eof:             Boolean   read GetEof;
    property CurrentKey:      Cardinal  read GetCurrentKey;
  end;

  TX2BTCursorClass    = class of TX2BTCustomCursor;


  {** Default tree cursor.
   *
   * The default cursor traverses through the tree from top to bottom, left
   * to right.
  *}
  TX2BTDefaultCursor  = class(TX2BTCustomCursor)
  private
    FRoot:        PX2BTNode;
    FNode:        PX2BTNode;
  protected
    function GetCurrentNode(): PX2BTNode;
    function GetCurrentKey(): Cardinal; override;
    function GetEof(): Boolean; override;
  public
    constructor Create(const ARoot: PX2BTNode); virtual;

    procedure First(); override;
    procedure Next(); override;

    property CurrentNode:     PX2BTNode read GetCurrentNode;
  end;


  {** Abstract tree manager.
   *
   * Trees implement a descendant to manage the tree nodes. This is where the
   * actual tree is stored, and possibly optimized. All tree managers are
   * assumed to store a 32-bit unsigned integer key with optional data.
  *}
  TX2BTCustomManager  = class(TObject)
  private
    FCursor:      TX2BTCustomCursor;
    FDataSize:    Cardinal;
  protected
    function GetCurrentKey(): Cardinal; virtual;
    function GetEof(): Boolean; virtual;

    procedure CursorNeeded(); virtual; abstract;
    procedure InvalidateCursor(); virtual; abstract;

    property Cursor:      TX2BTCustomCursor read FCursor  write FCursor;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    procedure Clear(); virtual; abstract;
    function Insert(const AKey: Cardinal): Boolean; virtual; abstract;
    function Delete(const AKey: Cardinal): Boolean; virtual; abstract;

    function Exists(const AKey: Cardinal): Boolean; virtual; abstract;
    function GetData(const AKey: Cardinal): Pointer; virtual; abstract;

    procedure First(); virtual;
    procedure Next(); virtual;

    property CurrentKey:      Cardinal  read GetCurrentKey;
    property DataSize:        Cardinal  read FDataSize  write FDataSize;
    property Eof:             Boolean   read GetEof;
  end;

  TX2BTManagerClass   = class of TX2BTCustomManager;


  {** Default tree manager.
  *}
  TX2BTDefaultManager = class(TX2BTCustomManager)
  private
    FLastNode:    PX2BTNode;
    FRoot:        PX2BTNode;
  protected
    procedure CursorNeeded(); override;
    procedure InvalidateCursor(); override;

    function FindLowestNode(const ANode: PX2BTNode): PX2BTNode;
    function FindHighestNode(const ANode: PX2BTNode): PX2BTNode;
    function FindNode(const AKey: Cardinal; out AParent: PX2BTNode): PX2BTNode;
    function FindNodeOnly(const AKey: Cardinal): PX2BTNode;

    function LeftChild(const ANode: PX2BTNode): Boolean;
    function RightChild(const ANode: PX2BTNode): Boolean;

    procedure SwapNodes(const ANode1, ANode2: PX2BTNode);
    procedure DeleteCleanNode(var ANode: PX2BTNode); virtual;

    procedure AllocateNode(var ANode: PX2BTNode); virtual;
    procedure DeallocateNode(var ANode: PX2BTNode); virtual;

    function GetNodeSize(): Cardinal; virtual;
  public
    procedure Clear(); override;
    function Insert(const AKey: Cardinal): Boolean; override;
    function Delete(const AKey: Cardinal): Boolean; override;

    function Exists(const AKey: Cardinal): Boolean; override;
    function GetData(const AKey: Cardinal): Pointer; override;
  end;

  {** Binary Tree implementation.
   *
   * Exposes the tree manager and handles node data.
  *}
  TX2BinaryTree       = class(TObject)
  private
    FManager:       TX2BTCustomManager;

    function GetCurrentKey(): Cardinal;
    function GetEof(): Boolean;
  protected
    function GetManagerClass(): TX2BTManagerClass; virtual;
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

  {** Binary Tree with integer data.
   *
   * Extends the standard Binary Tree, allowing it to store an Integer value
   * for each node in the tree.
  *}
  TX2IntegerTree      = class(TX2BinaryTree)
  private
    function GetItem(const AKey: Cardinal): Integer;
    procedure SetItem(const AKey: Cardinal; const Value: Integer);
    function GetCurrentValue: Integer;
  public
    constructor Create(); override;

    property CurrentValue:                  Integer read GetCurrentValue;
    property Items[const AKey: Cardinal]:   Integer read GetItem
                                                    write SetItem; default;
  end;

implementation
resourcestring
  RSBTKeyExists   = 'The key "%d" already exists in the tree.';
  RSBTKeyNotFound = 'The key "%d" could not be found in the tree.';
  RSBTCursorEof   = 'Cursor is at Eof.';
  RSBTNoCursor    = 'Cursor not initialized, call First before Next.';



{===================== TX2BTDefaultCursor
  Traversal
========================================}
constructor TX2BTDefaultCursor.Create;
begin
  inherited Create();

  FRoot := ARoot;
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

function TX2BTDefaultCursor.GetCurrentKey;
begin
  Result  := CurrentNode^.Key;
end;

function TX2BTDefaultCursor.GetEof;
begin
  Result  := not Assigned(FNode);
end;


{===================== TX2BTCustomManager
  Initialization
========================================}
constructor TX2BTCustomManager.Create;
begin
  inherited;
end;

destructor TX2BTCustomManager.Destroy;
begin
  Clear();
  FreeAndNil(FCursor);

  inherited;
end;


procedure TX2BTCustomManager.First;
begin
  CursorNeeded();
  FCursor.First();
end;

procedure TX2BTCustomManager.Next;
begin
  CursorNeeded();
  FCursor.Next();
end;


function TX2BTCustomManager.GetCurrentKey;
begin
  if FCursor.Eof then
    raise EBTCursorEof.Create(RSBTCursorEof);

  Result  := FCursor.CurrentKey;
end;

function TX2BTCustomManager.GetEof;
begin
  Result  := Assigned(FCursor) and (FCursor.Eof);
end;



{==================== TX2BTDefaultManager
  Node Management
========================================}
procedure TX2BTDefaultManager.AllocateNode;
var
  iSize:      Cardinal;

begin
  iSize := GetNodeSize() + FDataSize;
  GetMem(ANode, iSize);
  FillChar(ANode^, iSize, #0);
end;

procedure TX2BTDefaultManager.DeallocateNode;
begin
  FreeMem(ANode, GetNodeSize() + FDataSize);
  ANode := nil;
end;

function TX2BTDefaultManager.GetNodeSize;
begin
  Result  := SizeOf(TX2BTNode);
end;


procedure TX2BTDefaultManager.Clear;
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


function TX2BTDefaultManager.FindHighestNode;
begin
  Result  := ANode;

  while Assigned(Result) and Assigned(Result^.Right) do
    Result  := Result^.Right;
end;

function TX2BTDefaultManager.FindLowestNode;
begin
  Result  := ANode;

  while Assigned(Result) and Assigned(Result^.Left) do
    Result  := Result^.Left;
end;

function TX2BTDefaultManager.FindNode;
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

function TX2BTDefaultManager.FindNodeOnly;
var
  pDummy:       PX2BTNode;

begin
  Result  := FindNode(AKey, pDummy);
end;


function TX2BTDefaultManager.LeftChild;
begin
  Assert(Assigned(ANode^.Parent), 'Node has no parent!');
  Result  := (ANode^.Parent^.Left = ANode);
end;

function TX2BTDefaultManager.RightChild;
begin
  Result  := not LeftChild(ANode);
end;


procedure TX2BTDefaultManager.SwapNodes;
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


function TX2BTDefaultManager.Insert;
var
  pNode:      PX2BTNode;
  pParent:    PX2BTNode;

begin
  Result  := False;
  pNode   := FindNode(AKey, pParent);
  if Assigned(pNode) then
    exit;

  Result  := True;
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

function TX2BTDefaultManager.Delete;
var
  pNode:      PX2BTNode;
  pLowest:    PX2BTNode;

begin
  Result  := False;
  pNode   := FindNodeOnly(AKey);
  if not Assigned(pNode) then
    exit;

  Result  := True;
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

procedure TX2BTDefaultManager.DeleteCleanNode;
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


function TX2BTDefaultManager.Exists;
begin
  Result  := Assigned(FindNodeOnly(AKey));
end;

function TX2BTDefaultManager.GetData;
var
  pNode:      PX2BTNode;

begin
  pNode   := FindNodeOnly(AKey);
  if not Assigned(pNode) then
    raise EBTKeyNotFound.CreateFmt(RSBTKeyNotFound, [AKey]);

  Result  := Pointer(Cardinal(pNode) + GetNodeSize());
end;



procedure TX2BTDefaultManager.CursorNeeded;
begin
  if not Assigned(FCursor) then
    FCursor := TX2BTDefaultCursor.Create(FRoot);
end;

procedure TX2BTDefaultManager.InvalidateCursor;
begin
  FreeAndNil(FCursor);
end;


{========================== TX2BinaryTree
  Initialization
========================================}
constructor TX2BinaryTree.Create;
begin
  inherited;

  FManager  := GetManagerClass().Create();
end;

destructor TX2BinaryTree.Destroy;
begin
  FreeAndNil(FManager);

  inherited;
end;


{========================== TX2BinaryTree
  Interface
========================================}
procedure TX2BinaryTree.Clear;
begin
  FManager.Clear();
end;

function TX2BinaryTree.Exists;
begin
  Result  := FManager.Exists(AKey);
end;

procedure TX2BinaryTree.Insert;
begin
  if not FManager.Insert(AKey) then
    raise EBTKeyExists.CreateFmt(RSBTKeyExists, [AKey]);
end;

procedure TX2BinaryTree.Delete;
begin
  if not FManager.Delete(AKey) then
    raise EBTKeyNotFound.CreateFmt(RSBTKeyNotFound, [AKey]);
end;


procedure TX2BinaryTree.First;
begin
  FManager.First();
end;

procedure TX2BinaryTree.Next;
begin
  FManager.Next();
end;


function TX2BinaryTree.GetManagerClass;
begin
  Result  := TX2BTDefaultManager;
end;


function TX2BinaryTree.GetCurrentKey;
begin
  Result  := FManager.CurrentKey;
end;

function TX2BinaryTree.GetEof;
begin
  Result  := FManager.Eof;
end;


{========================= TX2IntegerTree
  Initialization
========================================}
constructor TX2IntegerTree.Create;
begin
  inherited;

  FManager.DataSize := SizeOf(Integer);
end;


function TX2IntegerTree.GetCurrentValue;
begin
  Result  := GetItem(FManager.CurrentKey);
end;


function TX2IntegerTree.GetItem;
begin
  Result  := PInteger(FManager.GetData(AKey))^;
end;

procedure TX2IntegerTree.SetItem;
begin
  FManager.Insert(AKey);
  PInteger(FManager.GetData(AKey))^ := Value;
end;

end.
