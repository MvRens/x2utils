{
  :: X2UtBinaryTree contains an implementation of the binary tree algorithm,
  :: along with various descendants which implement support for a range of value
  :: types other than the default pointers (such as integers or strings). This
  :: effectively makes it an associative array based on an integer key.
  :: For a hash implementation based on string keys use the X2UtHashes unit.
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
  SysUtils;
  
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
    Value:      Pointer;
    Parent:     PX2UtBTreeNode;
    Left:       PX2UtBTreeNode;
    Right:      PX2UtBTreeNode;
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

    :: This class implements a binary tree of pointer values.
  }
  TX2UtCustomBTree  = class(TObject)
  private
    FRoot:          PX2UtBTreeNode;
    FCursor:        PX2UtBTreeNode;
    FIsReset:       Boolean;
    FParent:        TX2UtBTreeStack;
  protected
    function GetItem(Index: Cardinal): Pointer;
    procedure SetItem(Index: Cardinal; const Value: Pointer);
    function GetCurrentIndex(): Cardinal;
    function GetCurrentValue(): Pointer;

    function LookupNode(const AIndex: Cardinal;
                        const ACreate: Boolean = False;
                        const ACursor: Boolean = False): PX2UtBTreeNode; virtual;

    procedure NewNode(const AParent: PX2UtBTreeNode;
                      var ANode: PX2UtBTreeNode;
                      const AAutoInit: Boolean = True); virtual;
    procedure InitNode(var ANode: PX2UtBTreeNode); virtual;
    procedure DeleteNode(var ANode: PX2UtBTreeNode); virtual;

    procedure ClearCursor(); virtual;

    property Cursor:    PX2UtBTreeNode  read FCursor    write FCursor;
    property Root:      PX2UtBTreeNode  read FRoot;
    property IsReset:   Boolean         read FIsReset   write FIsReset;
    property Parent:    TX2UtBTreeStack read FParent;

    
    //:$ Gets or sets an item.
    property Items[Index: Cardinal]:    Pointer read GetItem
                                                write SetItem; default;

    //:$ Returns the index at the current cursor location.
    property CurrentIndex:      Cardinal        read GetCurrentIndex;

    //:$ Returns the value at the current cursor location.
    property CurrentValue:      Pointer         read GetCurrentValue;
  public
    constructor Create();
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
    procedure Reset();

    //:$ Moves the node cursor to the next node.
    //:! The order in which nodes are traversed is from top to bottom, left
    //:! to right. Do not depend on the binary tree to sort the output.
    function Next(): Boolean;
  end;

  {
    :$ Binary tree implementation

    :: This class exposes TX2UtCustomBTree's properties
  }
  TX2UtBTree        = class(TX2UtCustomBTree)
  public
    property Items;
    property CurrentIndex;
    property CurrentValue;
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
  TX2UtStringBTree  = class(TX2UtBTree)
  protected
    function GetItem(Index: Cardinal): String;
    procedure SetItem(Index: Cardinal; const Value: String);
    function GetCurrentValue(): String;
  protected
    procedure InitNode(var ANode: PX2UtBTreeNode); override;
    procedure DeleteNode(var ANode: PX2UtBTreeNode); override;
  public
    //:$ Gets or sets an item.
    property Items[Index: Cardinal]:    String  read GetItem
                                                write SetItem; default;

    //:$ Returns the value at the current cursor location
    property CurrentValue:      String          read GetCurrentValue;
  end;

implementation
resourcestring
  RSOrphanNode    = 'Node does not seem to belong to it''s parent!';
  RSInvalidCursor = 'Cursor is invalid!';
  RSTooManyPops   = 'More Pops than Pushes!';

const
  CStackSize      = 32;

type
  PString         = ^String;


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

  NewNode(nil, FRoot, False);
  FParent := TX2UtBTreeStack.Create();
end;

destructor TX2UtCustomBTree.Destroy;
begin
  FreeAndNil(FParent);
  DeleteNode(FRoot);

  inherited;
end;


{======================= TX2UtCustomBTree
  Tree Management
========================================}
function TX2UtCustomBTree.LookupNode;
var
  pNode:      PX2UtBTreeNode;

begin
  Result  := nil;
  pNode   := Root;

  if not Assigned(pNode^.Value) then
  begin
    InitNode(pNode);
    pNode^.Index  := AIndex;
    Result        := pNode;

    if ACursor then
    begin
      Parent.Clear();
      IsReset := False;
      Cursor  := pNode;
    end;

    exit;
  end;

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
        if ACreate then
        begin
          NewNode(pNode, pNode^.Left);
          Result        := pNode^.Left;
          Result^.Index := AIndex;
        end;

        break;
      end;
    end else
    begin
      if Assigned(pNode^.Right) then
        pNode := pNode^.Right
      else
      begin
        if ACreate then
        begin
          NewNode(pNode, pNode^.Right);
          Result        := pNode^.Right;
          Result^.Index := AIndex;
        end;

        break;
      end;
    end;
  end;

  if ACursor and Assigned(Result) then
  begin
    // Trace parents
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


procedure TX2UtCustomBTree.NewNode;
begin
  New(ANode);
  FillChar(ANode^, SizeOf(TX2UtBTreeNode), #0);
  ANode^.Parent := AParent;
  ClearCursor();

  if AAutoInit then
    InitNode(ANode);
end;

procedure TX2UtCustomBTree.InitNode;
begin
  // Reserved for descendants
end;

procedure TX2UtCustomBTree.DeleteNode;
begin
  if Assigned(ANode^.Left) then
    DeleteNode(ANode^.Left);

  if Assigned(ANode^.Right) then
    DeleteNode(ANode^.Right);

  if Assigned(ANode^.Parent) then
    if ANode^.Parent^.Left = ANode then
      ANode^.Parent^.Left   := nil
    else if ANode^.Parent^.Right = ANode then
      ANode^.Parent^.Right  := nil
    else
      Assert(False, RSOrphanNode);

  Dispose(ANode);
  ClearCursor();
end;


procedure TX2UtCustomBTree.Clear;
begin
  DeleteNode(FRoot);
  NewNode(nil, FRoot, False);
end;

procedure TX2UtCustomBTree.Delete;
var
  pItem:      PX2UtBTreeNode;

begin
  pItem := LookupNode(AIndex);
  if Assigned(pItem) then
    DeleteNode(pItem);
end;

function TX2UtCustomBTree.Exists;
begin
  Result  := Assigned(LookupNode(AIndex, False, True));
end;



{======================= TX2UtCustomBTree
  Tree Traversing
========================================}
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
  if not Assigned(Cursor) then
    raise EX2UtBTreeInvalidCursor.Create(RSInvalidCursor);

  Result  := False;
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
  if Assigned(Cursor) and (not IsReset) then
    Result  := Cursor^.Index
  else
    raise EX2UtBTreeInvalidCursor.Create(RSInvalidCursor);
end;

function TX2UtCustomBTree.GetCurrentValue;
begin
  if Assigned(Cursor) and (not IsReset) then
    Result  := Cursor^.Value
  else
    raise EX2UtBTreeInvalidCursor.Create(RSInvalidCursor);
end;


{======================= TX2UtCustomBTree
  Items
========================================}
function TX2UtCustomBTree.GetItem;
var
  pItem:      PX2UtBTreeNode;

begin
  Result  := nil;
  pItem   := LookupNode(Index);
  if Assigned(pItem) then
    Result  := pItem^.Value;
end;

procedure TX2UtCustomBTree.SetItem;
var
  pItem:      PX2UtBTreeNode;

begin
  pItem := LookupNode(Index, True);
  if Assigned(pItem) then
    pItem^.Value  := Value;
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
function TX2UtStringBTree.GetItem;
var
  pItem:      PX2UtBTreeNode;

begin
  Result  := '';
  pItem   := LookupNode(Index);
  if Assigned(pItem) then
    Result  := PString(pItem^.Value)^;
end;

procedure TX2UtStringBTree.SetItem;
var
  pItem:      PX2UtBTreeNode;

begin
  pItem := LookupNode(Index, True);
  if Assigned(pItem) then
    PString(pItem^.Value)^  := Value;
end;

function TX2UtStringBTree.GetCurrentValue;
var
  pValue:       PString;

begin
  Result  := '';
  pValue  := inherited GetCurrentValue();
  if Assigned(pValue) then
    Result  := pValue^;
end;


procedure TX2UtStringBTree.InitNode;
begin
  inherited;

  New(PString(ANode^.Value));
end;

procedure TX2UtStringBTree.DeleteNode;
begin
  Dispose(PString(ANode^.Value));

  inherited;
end;

end.
