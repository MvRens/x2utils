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
  :: This unit contains code based on GNU libavl:
  ::    http://www.msu.edu/~pfaffben/avl/libavl.html/
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
  PPX2UtBTreeNode   = ^PX2UtBTreeNode;
  PX2UtBTreeNode    = ^TX2UtBTreeNode;
  TX2UtBTreeNode    = record
    Index:      Cardinal;
    Children:   array[0..1] of PX2UtBTreeNode;
    Balance:    Integer;
    Data:       record end;
  end;

  {
    :$ Internal node stack
  }
  TX2UtBTreeStackItem = record
    Node:           PX2UtBTreeNode;
    Direction:      Integer;
  end;

  TX2UtBTreeStack     = class(TObject)
  private
    FItems:         array of TX2UtBTreeStackItem;
    FCount:         Integer;
    FPosition:      Integer;

    function GetCount(): Integer;
    function GetNode(Index: Integer): PX2UtBTreeNode;
    function GetDirection(Index: Integer): Integer;
    procedure SetDirection(Index: Integer; const Value: Integer);
    procedure SetNode(Index: Integer; const Value: PX2UtBTreeNode);
  public
    constructor Create();

    procedure Clear();
    procedure Push(const ANode: PX2UtBTreeNode; const ADirection: Integer = 0);
    function Pop(): PX2UtBTreeNode; overload;
    function Pop(var ADirection: Integer): PX2UtBTreeNode; overload;

    property Node[Index: Integer]:        PX2UtBTreeNode  read GetNode
                                                          write SetNode; default;
    property Direction[Index: Integer]:   Integer         read GetDirection
                                                          write SetDirection;

    property Count:     Integer read GetCount;
  end;

  {
    :$ Binary tree implementation

    :: This class implements a binary tree without knowing anything about
    :: the data it contains.
  }
  TX2UtCustomBTree  = class(TObject)
  private
    FCount:         Integer;
    FRoot:          PX2UtBTreeNode;
    FCursor:        PX2UtBTreeNode;
    FIsReset:       Boolean;
    FParents:       TX2UtBTreeStack;

    FNodeSize:      Cardinal;
    FDataSize:      Cardinal;

    function GetTotalSize(): Cardinal;
  protected
    function GetCurrentIndex(): Cardinal;
    function GetNodeData(const ANode: PX2UtBTreeNode): Pointer; virtual;
    procedure CopyNodeData(const ASource, ADest: PX2UtBTreeNode);

    procedure BalanceInsert(var ANode: PX2UtBTreeNode);

    function LookupNode(const AIndex: Cardinal;
                        const ACanCreate: Boolean = False;
                        const ASetCursor: Boolean = False): PX2UtBTreeNode;

    procedure RotateLeft(var ANode: PX2UtBTreeNode);
    procedure RotateRight(var ANode: PX2UtBTreeNode);

    function DeleteLeftShrunk(var ANode: PX2UtBTreeNode): Integer;
    function DeleteRightShrunk(var ANode: PX2UtBTreeNode): Integer;
    function DeleteFindHighest(const ATarget: PX2UtBTreeNode;
                               var ANode: PX2UtBTreeNode;
                               out AResult: Integer): Boolean;
    function DeleteFindLowest(const ATarget: PX2UtBTreeNode;
                              var ANode: PX2UtBTreeNode;
                              out AResult: Integer): Boolean;

    function InternalDeleteNode(var ARoot: PX2UtBTreeNode;
                                const AIndex: Cardinal): Integer;
    procedure DeleteNode(const AIndex: Cardinal);

    procedure InitNode(var ANode: PX2UtBTreeNode); virtual;
    procedure FreeNode(var ANode: PX2UtBTreeNode); virtual;

    procedure ClearCursor(); virtual;
    function ValidCursor(const ARaiseError: Boolean = True): Boolean; virtual;

    property Cursor:          PX2UtBTreeNode  read FCursor    write FCursor;
    property Root:            PX2UtBTreeNode  read FRoot;
    property IsReset:         Boolean         read FIsReset   write FIsReset;
    property Parents:         TX2UtBTreeStack read FParents;

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

    //:$ Contains the number of nodes in the tree
    property Count:       Integer   read FCount;
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
  CLeft           = 0;
  CRight          = 1;

  CError          = 0;
  COK             = 1;
  CBalance        = 2;


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

  with FItems[FPosition] do
  begin
    Node      := ANode;
    Direction := ADirection;
  end;
end;

function TX2UtBTreeStack.Pop(): PX2UtBTreeNode;
begin
  Result  := nil;
  if FPosition >= 0 then
  begin
    Result      := FItems[FPosition].Node;
    Dec(FPosition);
  end;
end;

function TX2UtBTreeStack.Pop(var ADirection: Integer): PX2UtBTreeNode;
begin
  Result  := nil;
  if FPosition >= 0 then
  begin
    ADirection  := FItems[FPosition].Direction;
    Result      := FItems[FPosition].Node;
    Dec(FPosition);
  end;
end;

function TX2UtBTreeStack.GetNode;
begin
  Assert((Index >= 0) and (Index <= FPosition), '* BUG * Invalid stack index!');
  Result  := FItems[Index].Node;
end;

procedure TX2UtBTreeStack.SetNode;
begin
  Assert((Index >= 0) and (Index <= FPosition), '* BUG * Invalid stack index!');
  FItems[Index].Node  := Value;
end;

function TX2UtBTreeStack.GetDirection;
begin
  Assert((Index >= 0) and (Index <= FPosition), '* BUG * Invalid stack index!');
  Result  := FItems[Index].Direction;
end;

procedure TX2UtBTreeStack.SetDirection;
begin
  Assert((Index >= 0) and (Index <= FPosition), '* BUG * Invalid stack index!');
  FItems[Index].Direction := Value;
end;


function TX2UtBTreeStack.GetCount;
begin
  Result  := FPosition + 1;
end;


{======================= TX2UtCustomBTree
  Initialization
========================================}
constructor TX2UtCustomBTree.Create;
begin
  inherited;

  FParents  := TX2UtBTreeStack.Create();
  FNodeSize := SizeOf(TX2UtBTreeNode);
end;

destructor TX2UtCustomBTree.Destroy;
begin
  FreeAndNil(FParents);
  Clear();

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

procedure TX2UtCustomBTree.CopyNodeData;
begin
  ADest^.Index  := ASource^.Index;
  Move(GetNodeData(ASource)^,
       GetNodeData(ADest)^,
       DataSize);
end;


procedure TX2UtCustomBTree.BalanceInsert;
var
  pNode:        PX2UtBTreeNode;
  pSwap:        PX2UtBTreeNode;

begin
  if ANode^.Balance = -2 then
  begin
    // Left-heavy
    pNode := ANode^.Children[CLeft];

    if pNode^.Balance = -1 then
    begin
      pSwap                     := pNode;
      ANode^.Children[CLeft]    := pNode^.Children[CRight];
      pNode^.Children[CRight]   := ANode;
      pNode^.Balance            := 0;
      ANode^.Balance            := 0;
    end else
    begin
      Assert(pNode^.Balance = 1, '* BUG * Unexpected node balance');
      pSwap                     := pNode^.Children[CRight];
      pNode^.Children[CRight]   := pSwap^.Children[CLeft];
      pSwap^.Children[CLeft]    := pNode;
      ANode^.Children[CLeft]    := pSwap^.Children[CRight];
      pSwap^.Children[CRight]   := ANode;

      case pSwap^.Balance of
        -1:
          begin
            pNode^.Balance      := 0;
            ANode^.Balance      := 1;
          end;
        0:
          begin
            pNode^.Balance      := 0;
            ANode^.Balance      := 0;
          end;
      else
        pNode^.Balance          := -1;
        ANode^.Balance          := 0;
      end;

      pSwap^.Balance            := 0;
    end;

    ANode := pSwap;
  end else if ANode^.Balance = 2 then
  begin
    // Right-heavy
    pNode := ANode^.Children[CRight];

    if pNode^.Balance = 1 then
    begin
      pSwap                     := pNode;
      ANode^.Children[CRight]   := pNode^.Children[CLeft];
      pNode^.Children[CLeft]    := ANode;
      pNode^.Balance            := 0;
      ANode^.Balance            := 0;
    end else
    begin
      Assert(pNode^.Balance = -1, '* BUG * Unexpected node balance');
      pSwap                     := pNode^.Children[CLeft];
      pNode^.Children[CLeft]    := pSwap^.Children[CRight];
      pSwap^.Children[CRight]   := pNode;
      ANode^.Children[CRight]   := pSwap^.Children[CLeft];
      pSwap^.Children[CLeft]    := ANode;

      case pSwap^.Balance of
        1:
          begin
            pNode^.Balance      := 0;
            ANode^.Balance      := -1;
          end;
        0:
          begin
            pNode^.Balance      := 0;
            ANode^.Balance      := 0;
          end;
      else
        pNode^.Balance          := 1;
        ANode^.Balance          := 0;
      end;

      pSwap^.Balance  := 0;
    end;

    ANode := pSwap;
  end;
end;


function TX2UtCustomBTree.LookupNode;
var
  pCurrent:         PPX2UtBTreeNode;
  pBalance:         PPX2UtBTreeNode;
  pLast:            PX2UtBTreeNode;
  pNode:            PX2UtBTreeNode;
  pPath:            TX2UtBTreeStack;

begin
  Result    := nil;

  if ASetCursor then
    Parents.Clear();

  pPath     := TX2UtBTreeStack.Create();
  try
    pCurrent  := @FRoot;
    pBalance  := nil;

    repeat
      if Assigned(pCurrent^) then
      begin
        pPath.Push(pCurrent^);
        if pCurrent^^.Balance <> 0 then
          pBalance  := pCurrent;

        if AIndex > pCurrent^^.Index then
          // Continue on the right side
          pCurrent  := @pCurrent^^.Children[CRight]
        else if AIndex < pCurrent^^.Index then
          // Continue on the left side
          pCurrent  := @pCurrent^^.Children[CLeft]
        else
        begin
          // Found it!
          Result    := pCurrent^;
          break;
        end;
      end else if ACanCreate then
      begin
        // Create new node
        InitNode(pCurrent^);
        pCurrent^^.Index  := AIndex;

        // Update balance factors
        pLast := pCurrent^;
        pNode := pPath.Pop();

        while Assigned(pNode) do
        begin
          if pNode^.Children[CLeft] = pLast then
            Dec(pNode^.Balance)
          else
            Inc(pNode^.Balance);

          if Assigned(pBalance) and (pNode = pBalance^) then
            break;

          pLast := pNode;
          pNode := pPath.Pop();
        end;

        if Assigned(pBalance) then
          BalanceInsert(pBalance^);

        break;
      end else
        break;
    until False;
  finally
    FreeAndNil(pPath);
  end;
end;


procedure TX2UtCustomBTree.RotateLeft;
var
  pSwap:        PX2UtBTreeNode;

begin
  pSwap                   := ANode;
  ANode                   := ANode^.Children[CRight];
  pSwap^.Children[CRight] := ANode^.Children[CLeft];
  ANode^.Children[CLeft]  := pSwap;
end;

procedure TX2UtCustomBTree.RotateRight;
var
  pSwap:        PX2UtBTreeNode;

begin
  pSwap                   := ANode;
  ANode                   := ANode^.Children[CLeft];
  pSwap^.Children[CLeft]  := ANode^.Children[CRight];
  ANode^.Children[CRight] := pSwap;
end;


function TX2UtCustomBTree.DeleteLeftShrunk;
begin
  Result  := CError;
  
  case ANode^.Balance of
    -1:
      begin
        ANode^.Balance  := 0;
        Result          := CBalance;
      end;
    0:
      begin
        ANode^.Balance  := 1;
        Result          := COK;
      end;
    1:
      begin
        case ANode^.Children[CRight]^.Balance of
          1:
            begin
              if ANode^.Children[CRight]^.Balance = 0 then
                ANode^.Balance  := 1
              else
                ANode^.Balance  := 0;

              RotateLeft(ANode);
              Result  := CBalance;
            end;
          0:
            begin
              ANode^.Balance                    := 1;
              ANode^.Children[CRight]^.Balance  := -1;
              RotateLeft(ANode);
              Result  := COK;
            end;
          -1:
            begin
              case ANode^.Children[CRight]^.Children[CLeft]^.Balance of
                -1:
                  begin
                    ANode^.Balance                    := 0;
                    ANode^.Children[CRight]^.Balance  := 1;
                  end;
                0:
                  begin
                    ANode^.Balance                    := 0;
                    ANode^.Children[CRight]^.Balance  := 0;
                  end;
                1:
                  begin
                    ANode^.Balance                    := -1;
                    ANode^.Children[CRight]^.Balance  := 0;
                  end;
              end;

              ANode^.Children[CRight]^.Children[CLeft]^.Balance := 0;
              RotateRight(ANode^.Children[CRight]);
              RotateLeft(ANode);
              Result  := CBalance;
            end;
        end;
      end;
  end;
end;

function TX2UtCustomBTree.DeleteRightShrunk;
begin
  Result  := CError;
  
  case ANode^.Balance of
    1:
      begin
        ANode^.Balance  := 0;
        Result          := CBalance;
      end;
    0:
      begin
        ANode^.Balance  := -1;
        Result          := COK;
      end;
    -1:
      begin
        case ANode^.Children[CLeft]^.Balance of
          -1:
            begin
              if ANode^.Children[CLeft]^.Balance = 0 then
                ANode^.Balance  := 1
              else
                ANode^.Balance  := 0;

              RotateRight(ANode);
              Result  := CBalance;
            end;
          0:
            begin
              ANode^.Balance                  := -1;
              ANode^.Children[CLeft]^.Balance := 1;
              RotateRight(ANode);
              Result  := COK;
            end;
          1:
            begin
              case ANode^.Children[CLeft]^.Children[CRight]^.Balance of
                -1:
                  begin
                    ANode^.Balance                  := 1;
                    ANode^.Children[CLeft]^.Balance := 0;
                  end;
                0:
                  begin
                    ANode^.Balance                  := 0;
                    ANode^.Children[CLeft]^.Balance := 0;
                  end;
                1:
                  begin
                    ANode^.Balance                  := 1;
                    ANode^.Children[CLeft]^.Balance := 0;
                  end;
              end;

              ANode^.Children[CLeft]^.Children[CRight]^.Balance := 0;
              RotateLeft(ANode^.Children[CLeft]);
              RotateRight(ANode);
              Result  := CBalance;
            end;
        end;
      end;
  end;
end;

function TX2UtCustomBTree.DeleteFindHighest;
var
  pSwap:        PX2UtBTreeNode;

begin
  AResult := CBalance;
  Result  := False;

  if not Assigned(ANode) then
    exit;

  if Assigned(ANode^.Children[CRight]) then
  begin
    if not DeleteFindHighest(ATarget, ANode^.Children[CRight], AResult) then
    begin
      Result  := False;
      exit;
    end;

    if AResult = CBalance then
      AResult := DeleteRightShrunk(ANode);

    Result  := True;
    exit;
  end;

  pSwap   := ANode;
  CopyNodeData(ANode, ATarget);
  
  ANode   := ANode^.Children[CLeft];
  FreeNode(pSwap);
  Result  := True;
end;

function TX2UtCustomBTree.DeleteFindLowest;
var
  pSwap:        PX2UtBTreeNode;

begin
  AResult := CBalance;
  Result  := False;

  if not Assigned(ANode) then
    exit;

  if Assigned(ANode^.Children[CLeft]) then
  begin
    if not DeleteFindLowest(ATarget, ANode^.Children[CLeft], AResult) then
    begin
      Result  := False;
      exit;
    end;

    if AResult = CBalance then
      AResult := DeleteLeftShrunk(ANode);

    Result  := True;
    exit;
  end;

  pSwap   := ANode;
  CopyNodeData(ANode, ATarget);

  ANode   := ANode^.Children[CRight];
  FreeNode(pSwap);
  Result  := True;
end;


function TX2UtCustomBTree.InternalDeleteNode;
var
  iResult:      Integer;

begin
  if AIndex < ARoot^.Index then
  begin
    // Continue on the left side
    iResult := InternalDeleteNode(ARoot^.Children[CLeft], AIndex);
    if iResult = CBalance then
    begin
      Result  := DeleteLeftShrunk(ARoot);
      exit;
    end;

    Result  := iResult;
    exit;
  end;

  if AIndex > ARoot^.Index then
  begin
    // Continue on the right side
    iResult := InternalDeleteNode(ARoot^.Children[CRight], AIndex);
    if iResult = CBalance then
    begin
      Result  := DeleteRightShrunk(ARoot);
      exit;
    end;

    Result  := iResult;
    exit;
  end;

  if Assigned(ARoot^.Children[CLeft]) then
    if DeleteFindHighest(ARoot, ARoot^.Children[CLeft], iResult) then
    begin
      if iResult = CBalance then
        iResult := DeleteLeftShrunk(ARoot);

      Result  := iResult;
      exit;
    end;

  if Assigned(ARoot^.Children[CRight]) then
    if DeleteFindLowest(ARoot, ARoot^.Children[CRight], iResult) then
    begin
      if iResult = CBalance then
        iResult := DeleteRightShrunk(ARoot);

      Result  := iResult;
      exit;
    end;

  FreeNode(ARoot);
  Result  := CBalance;
end;

procedure TX2UtCustomBTree.DeleteNode;
begin
  if not Assigned(FRoot) then
    exit;

  InternalDeleteNode(FRoot, AIndex);
end;


procedure TX2UtCustomBTree.InitNode;
begin
  Assert(DataSize > 0, RSInvalidDataSize);
  GetMem(ANode, TotalSize);
  FillChar(ANode^, TotalSize, #0);

  Inc(FCount);
  ClearCursor();
end;

procedure TX2UtCustomBTree.FreeNode;
begin
  FreeMem(ANode, TotalSize);
  ANode := nil;

  Dec(FCount);
  ClearCursor();
end;


procedure TX2UtCustomBTree.Clear;
  procedure ClearNode(var ANode: PX2UtBTreeNode);
  begin
    if Assigned(ANode^.Children[CLeft]) then
      ClearNode(ANode^.Children[CLeft]);

    if Assigned(ANode^.Children[CRight]) then
      ClearNode(ANode^.Children[CRight]);

    FreeNode(ANode);
  end;

begin
  if Assigned(FRoot) then
    ClearNode(FRoot);
    
  FRoot := nil;
end;

procedure TX2UtCustomBTree.Delete;
begin
  DeleteNode(AIndex);
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
    if Assigned(Cursor^.Children[CLeft]) then
    begin
      // Valid left path, follow it
      Parents.Push(Cursor);
      Cursor  := Cursor^.Children[CLeft];
      Result  := True;
    end else if Assigned(Cursor^.Children[CRight]) then
    begin
      // Valid right path, follow it
      Parents.Push(Cursor);
      Cursor  := Cursor^.Children[CRight];
      Result  := True;
    end else
    begin
      // Neither is valid, traverse back up the parent stack until
      // a node if found with a sibling
      pCurrent  := Cursor;
      pParent   := Parents.Pop();
      ClearCursor();

      while Assigned(pParent) do
      begin
        if Assigned(pParent^.Children[CRight]) and
           (pParent^.Children[CRight] <> pCurrent) then
        begin
          // Parent has a sibling, follow it
          Parents.Push(pParent);
          Cursor  := pParent^.Children[CRight];
          Result  := True;
          break;
        end;

        pCurrent  := pParent;
        pParent   := Parents.Pop();
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
