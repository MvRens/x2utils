{
  :: X2UtBinaryTree contains an implementation of the binary tree algorithm,
  :: along with various descendants which implement support for a range of value
  :: types (such as pointers, integers and strings). This effectively makes it
  :: an associative array based on an integer key. For a hash implementation
  :: based on string keys use the X2UtHashes unit.
  ::
  :: P.S. I realise that a "B-Tree" is different from a binary tree. For
  :: convenience reasons I will however ignore your ranting and call my
  :: classes "TX2UtBTree". ;)
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtBinaryTree;

interface
uses
  SysUtils,
  VirtualTrees;
  
type
  //:$ Raised when the cursor is invalid.
  //:: Call Reset on the binary tree to create a valid cursor.
  EX2UtBTreeInvalidCursor = class(Exception);

  {
    :$ Internal representation of a node.
  }
  PX2UtBTreeNode  = ^TX2UtBTreeNode;
  TX2UtBTreeNode  = record
    Index:      Cardinal;
    Parent:     PX2UtBTreeNode;
    Left:       PX2UtBTreeNode;
    Right:      PX2UtBTreeNode;
    Data:       record end;
  end;

  {
    :$ Internal parent stack
  }
  TX2UtBTreeStack = class(TObject)
  private
    FItems:         array of PX2UtBTreeNode;
    FCount:         Integer;
    FPosition:      Integer;
  public
    constructor Create();

    procedure Clear();
    procedure Push(const ANode: PX2UtBTreeNode);
    function Pop(): PX2UtBTreeNode;

    procedure Reverse();
  end;

  {
    :$ Binary tree implementation

    :: This class implements a binary tree without knowing anything about
    :: the data it contains.
  }
  TX2UtCustomBTree  = class(TObject)
  private
    FRoot:          PX2UtBTreeNode;
    FCursor:        PX2UtBTreeNode;
    FIsReset:       Boolean;
    FParent:        TX2UtBTreeStack;

    FNodeSize:      Cardinal;
    FDataSize:      Cardinal;

    function GetTotalSize(): Cardinal;
  protected
    function GetCurrentIndex(): Cardinal;

    function GetNodeData(const ANode: PX2UtBTreeNode): Pointer; virtual;
    function LookupNode(const AIndex: Cardinal;
                        const ACanCreate: Boolean = False;
                        const ASetCursor: Boolean = False): PX2UtBTreeNode;

    procedure InitNode(var ANode: PX2UtBTreeNode); virtual;
    procedure FreeNode(var ANode: PX2UtBTreeNode); virtual;

    procedure ClearCursor(); virtual;
    function ValidCursor(const ARaiseError: Boolean = True): Boolean; virtual;

    property Cursor:          PX2UtBTreeNode  read FCursor    write FCursor;
    property Root:            PX2UtBTreeNode  read FRoot;
    property IsReset:         Boolean         read FIsReset   write FIsReset;
    property Parent:          TX2UtBTreeStack read FParent;

    property NodeSize:        Cardinal        read FNodeSize;
    property TotalSize:       Cardinal        read GetTotalSize;

    // Note: do NOT change DataSize after the first node has
    // been created! This will result in an Access Violation!
    property DataSize:        Cardinal        read FDataSize      write FDataSize;

    //:$ Returns the index at the current cursor location.
    property CurrentIndex:      Cardinal        read GetCurrentIndex;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;

    //:$ Clears the tree.
    procedure Clear();

    //:$ Deletes a node from the tree.
    procedure Delete(const AIndex: Cardinal);

    //:$ Checks if an index exists in the tree.
    //:: If the ASetCursor parameter is set to True, the cursor will be
    //:: positioned at the item if it is found.
    function Exists(const AIndex: Cardinal; const ASetCursor: Boolean = False): Boolean;

    //:$ Resets the node cursor.
    //:: The node cursor can be used to traverse through the binary tree.
    //:: Call Reset first, followed by Next to get the first item. You can
    //:: continue to call Next until it returns false. The CurrentIndex and
    //:: CurrentValue properties will only be valid within the traversal.
    //:! Adding or removing items will result in a loss of the current cursor
    //:! until the next Reset call.
    procedure Reset(); virtual;

    //:$ Moves the node cursor to the next node.
    //:! The order in which nodes are traversed is from top to bottom, left
    //:! to right. Do not depend on the binary tree to sort the output.
    function Next(): Boolean; virtual;
  end;

  {
    :$ Binary tree implementation for pointer values
  }
  TX2UtBTree        = class(TX2UtCustomBTree)
  private
    function GetItem(Index: Cardinal): Pointer;
    procedure SetItem(Index: Cardinal; const Value: Pointer);

    function GetCurrentValue(): Pointer;
  public
    constructor Create(); override;
    property CurrentIndex;

    //:$ Gets or sets an item.
    property Items[Index: Cardinal]:    Pointer read GetItem
                                                write SetItem; default;

    //:$ Returns the value at the current cursor location
    property CurrentValue:      Pointer         read GetCurrentValue;
  end;

  {
    :$ Binary tree implementation for integer values
  }
  TX2UtIntegerBTree = class(TX2UtBTree)
  protected
    function GetItem(Index: Cardinal): Integer;
    procedure SetItem(Index: Cardinal; const Value: Integer);
    function GetCurrentValue(): Integer;
  public
    //:$ Gets or sets an item.
    property Items[Index: Cardinal]:    Integer read GetItem
                                                write SetItem; default;

    //:$ Returns the value at the current cursor location
    property CurrentValue:      Integer         read GetCurrentValue;
  end;

  {
    :$ Binary tree implementation for string values
  }
  TX2UtStringBTree  = class(TX2UtCustomBTree)
  protected
    function GetItem(Index: Cardinal): String;
    procedure SetItem(Index: Cardinal; const Value: String);

    function GetCurrentValue(): String;
  protected
    procedure InitNode(var ANode: PX2UtBTreeNode); override;
    procedure FreeNode(var ANode: PX2UtBTreeNode); override;
  public
    constructor Create(); override;
    property CurrentIndex;

    //:$ Gets or sets an item.
    property Items[Index: Cardinal]:    String  read GetItem
                                                write SetItem; default;

    //:$ Returns the value at the current cursor location
    property CurrentValue:      String          read GetCurrentValue;
  end;

resourcestring
  RSInvalidCursor   = 'Cursor is invalid!';
  RSInvalidDataSize = 'Invalid data size!';

implementation
resourcestring
  RSOrphanNode      = 'BUG: Node does not seem to belong to it''s parent!';
  RSTooManyPops     = 'More Pops than Pushes!';

const
  CStackSize      = 32;


{======================== TX2UtBTreeStack
  Item Management
========================================}
constructor TX2UtBTreeStack.Create;
begin
  inherited;

  FCount    := CStackSize;
  FPosition := -1;
  SetLength(FItems, FCount);
end;


procedure TX2UtBTreeStack.Clear;
begin
  FCount    := CStackSize;
  FPosition := -1;
  SetLength(FItems, FCount);
end;

procedure TX2UtBTreeStack.Push;
begin
  Inc(FPosition);
  if FPosition >= FCount then
  begin
    Inc(FCount, FCount);
    SetLength(FItems, FCount);
  end;

  FItems[FPosition] := ANode;
end;

function TX2UtBTreeStack.Pop;
begin
  Result  := nil;
  if FPosition > -1 then
  begin
    Result  := FItems[FPosition];
    Dec(FPosition);
  end;
end;


procedure TX2UtBTreeStack.Reverse;
var
  iCount:       Integer;
  iIndex:       Integer;
  pSwap:        PX2UtBTreeNode;

begin
  if FPosition = -1 then
    exit;

  iCount  := (FPosition + 1) div 2;
  for iIndex  := 0 to iCount - 1 do
  begin
    pSwap                       := FItems[iIndex];
    FItems[iIndex]              := FItems[FPosition - iIndex];
    FItems[FPosition - iIndex]  := pSwap;
  end;
end;


{======================= TX2UtCustomBTree
  Initialization
========================================}
constructor TX2UtCustomBTree.Create;
begin
  inherited;

  FParent   := TX2UtBTreeStack.Create();
  FNodeSize := SizeOf(TX2UtBTreeNode);
end;

destructor TX2UtCustomBTree.Destroy;
begin
  FreeAndNil(FParent);

  if Assigned(FRoot) then
    FreeNode(FRoot);

  inherited;
end;


{======================= TX2UtCustomBTree
  Tree Management
========================================}
function TX2UtCustomBTree.GetNodeData;
begin
  Assert(DataSize > 0, RSInvalidDataSize);
  Result  := Pointer(Cardinal(ANode) + NodeSize);
end;

function TX2UtCustomBTree.LookupNode;
var
  pNode:        PX2UtBTreeNode;

begin
  Result  := nil;

  if not Assigned(FRoot) then
  begin
    if ACanCreate then
    begin
      InitNode(FRoot);
      Result      := FRoot;

      if ASetCursor then
      begin
        Parent.Clear();
        Cursor  := FRoot;
      end;
    end;

    exit;
  end;

  pNode   := Root;
  while Assigned(pNode) do
  begin
    if AIndex = pNode^.Index then
    begin
      Result  := pNode;
      break;
    end else if AIndex < pNode^.Index then
    begin
      if Assigned(pNode^.Left) then
        pNode := pNode^.Left
      else
      begin
        if ACanCreate then
        begin
          InitNode(pNode^.Left);
          Result          := pNode^.Left;
          Result^.Index   := AIndex;
          Result^.Parent  := pNode;
        end;

        break;
      end;
    end else
    begin
      if Assigned(pNode^.Right) then
        pNode := pNode^.Right
      else
      begin
        if ACanCreate then
        begin
          InitNode(pNode^.Right);
          Result          := pNode^.Right;
          Result^.Index   := AIndex;
          Result^.Parent  := pNode;
        end;

        break;
      end;
    end;
  end;

  if ASetCursor and Assigned(Result) then
  begin
    // Trace parents
    Parent.Clear();    
    pNode := Result^.Parent;
    while Assigned(pNode) do
    begin
      Parent.Push(pNode);
      pNode := pNode^.Parent;
    end;

    // Parents are now in reverse order
    Parent.Reverse();
  end;
end;


procedure TX2UtCustomBTree.InitNode;
begin
  Assert(DataSize > 0, RSInvalidDataSize);
  GetMem(ANode, TotalSize);
  FillChar(ANode^, TotalSize, #0);
end;

procedure TX2UtCustomBTree.FreeNode;
begin
  if Assigned(ANode^.Left) then
    FreeNode(ANode^.Left);

  if Assigned(ANode^.Right) then
    FreeNode(ANode^.Right);

  if Assigned(ANode^.Parent) then
    if ANode^.Parent^.Left = ANode then
      ANode^.Parent^.Left   := nil
    else if ANode^.Parent^.Right = ANode then
      ANode^.Parent^.Right  := nil
    else
      Assert(False, RSOrphanNode);

  FreeMem(ANode, TotalSize);
  ClearCursor();

  ANode := nil;
end;


procedure TX2UtCustomBTree.Clear;
begin
  if Assigned(FRoot) then
    FreeNode(FRoot);
end;

procedure TX2UtCustomBTree.Delete;
var
  pItem:      PX2UtBTreeNode;

begin
  pItem := LookupNode(AIndex);
  if Assigned(pItem) then
    FreeNode(pItem);
end;

function TX2UtCustomBTree.Exists;
begin
  Result  := Assigned(LookupNode(AIndex, False, True));
end;



{======================= TX2UtCustomBTree
  Tree Traversing
========================================}
function TX2UtCustomBTree.ValidCursor;
begin
  Result  := (Assigned(Cursor) and (not IsReset));
  
  if (not Result) and (ARaiseError) then
    raise EX2UtBTreeInvalidCursor.Create(RSInvalidCursor);
end;

procedure TX2UtCustomBTree.ClearCursor;
begin
  Cursor    := nil;
end;


procedure TX2UtCustomBTree.Reset;
begin
  Cursor    := Root;
  IsReset   := True;
end;

function TX2UtCustomBTree.Next;
var
  pParent:        PX2UtBTreeNode;
  pCurrent:       PX2UtBTreeNode;

begin
  Result  := False;

  if not Assigned(Cursor) then
  begin
    IsReset := False;
    exit;
  end;

  if not IsReset then
  begin
    if Assigned(Cursor^.Left) then
    begin
      // Valid left path, follow it
      Parent.Push(Cursor);
      Cursor  := Cursor^.Left;
      Result  := True;
    end else if Assigned(Cursor^.Right) then
    begin
      // Valid right path, follow it
      Parent.Push(Cursor);
      Cursor  := Cursor^.Right;
      Result  := True;
    end else
    begin
      // Neither is valid, traverse back up the parent stack until
      // a node if found with a sibling
      pCurrent  := Cursor;
      pParent   := Parent.Pop();
      ClearCursor();

      while Assigned(pParent) do
      begin
        if Assigned(pParent^.Right) and (pParent^.Right <> pCurrent) then
        begin
          // Parent has a sibling, follow it
          Parent.Push(pParent);
          Cursor  := pParent^.Right;
          Result  := True;
          break;
        end;

        pCurrent  := pParent;
        pParent   := Parent.Pop();
      end;
    end;
  end else
  begin
    IsReset := False;
    Result  := True;
  end;
end;

function TX2UtCustomBTree.GetCurrentIndex;
begin
  Result  := 0;
  if ValidCursor(True) then
    Result  := Cursor^.Index;
end;

function TX2UtCustomBTree.GetTotalSize;
begin
  Result  := FNodeSize + FDataSize;
end;


{============================= TX2UtBTree
  Item Management
========================================}
constructor TX2UtBTree.Create;
begin
  inherited;

  DataSize  := SizeOf(Pointer);
end;

function TX2UtBTree.GetItem;
var
  pNode:        PX2UtBTreeNode;

begin
  Result  := nil;
  pNode   := LookupNode(Index);
  if Assigned(pNode) then
    Result  := PPointer(GetNodeData(pNode))^;
end;

procedure TX2UtBTree.SetItem;
var
  pNode:        PX2UtBTreeNode;

begin
  pNode := LookupNode(Index, True);
  if Assigned(pNode) then
    PPointer(GetNodeData(pNode))^ := Value;
end;

function TX2UtBTree.GetCurrentValue;
begin
  Result  := nil;
  if ValidCursor(True) then
    Result  := PPointer(GetNodeData(Cursor))^;
end;


{====================== TX2UtIntegerBTree
  Item Management
========================================}
function TX2UtIntegerBTree.GetItem;
begin
  Result  := Integer(inherited GetItem(Index));
end;

procedure TX2UtIntegerBTree.SetItem;
begin
  inherited SetItem(Index, Pointer(Value));
end;

function TX2UtIntegerBTree.GetCurrentValue;
begin
  Result  := Integer(inherited GetCurrentValue());
end;


{======================= TX2UtStringBTree
  Item Management
========================================}
constructor TX2UtStringBTree.Create;
begin
  inherited;

  DataSize  := SizeOf(PString);
end;


procedure TX2UtStringBTree.InitNode;
var
  pData:        PString;

begin
  inherited;

  pData := GetNodeData(ANode);
  Initialize(pData^);
end;

procedure TX2UtStringBTree.FreeNode;
var
  pData:        PString;

begin
  pData := GetNodeData(ANode);
  Finalize(pData^);
  
  inherited;
end;


function TX2UtStringBTree.GetItem;
var
  pNode:        PX2UtBTreeNode;

begin
  pNode := LookupNode(Index);
  if Assigned(pNode) then
    Result  := PString(GetNodeData(pNode))^;
end;

procedure TX2UtStringBTree.SetItem;
var
  pNode:        PX2UtBTreeNode;

begin
  pNode := LookupNode(Index, True);
  if Assigned(pNode) then
    PString(GetNodeData(pNode))^  := Value;
end;

function TX2UtStringBTree.GetCurrentValue;
begin
  if ValidCursor(True) then
    Result  := PString(GetNodeData(Cursor))^;
end;

end.
