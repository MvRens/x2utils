{
  :: X2UtCursors implements utility functions for cursor operations.
  ::
  :: Including this unit in your project will automatically include
  :: the X2UtHandCursor unit.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtCursors;

interface

  {**
   * Changes the screen cursor temporarily to an hourglass.
   *
   * The result does not need to be stored in a variable unless early
   * restoration of the cursor is desired.
   *
   * @param ACursor the cursor type to show
   * @result        the interface which, when freed, will restore the cursor
  *}
  function TempWaitCursor: IInterface;

  
implementation
uses
  Controls,
  Forms;

  
var
  WaitCursorRefCount: Integer;

  
type
  TWaitCursor = class(TInterfacedObject)
  public
    constructor Create;
    destructor Destroy; override;
  end;



function TempWaitCursor: IInterface;
begin
  Result := TWaitCursor.Create;
end;


{ TWaitCursor }
constructor TWaitCursor.Create;
begin
  inherited;

  Inc(WaitCursorRefCount);
  Screen.Cursor := crHourGlass;
end;


destructor TWaitCursor.Destroy;
begin
  Dec(WaitCursorRefCount);
  if WaitCursorRefCount = 0 then
    Screen.Cursor := crDefault;

  inherited;
end;


end.
