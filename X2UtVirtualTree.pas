{
  :: X2UtVirtualTree provides a set of functions commonly used with
  :: TVirtualTree (http://www.delphi-gems.com/).
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtVirtualTree;

interface
uses
  Graphics,
  VirtualTrees,
  Windows;

  //:$ Applies the sort order on the specified column.
  //:: When a column is already sorted, the sort order is reversed.
  //:: Specify a SortColor to provide the new column with that color
  //:: (similar to Explorer in Windows XP). If you choose to use SortColor,
  //:: the column's Tag property will be used to restore the color when calling
  //:: SortColumn for the second time, so be sure not to rely on that.
  procedure SortColumn(const AHeader: TVTHeader;
                       const AColumn: TColumnIndex;
                       const ASortColor: TColor = clNone;
                       const AApplySort: Boolean = True);

  //:$ Calculates the position of an image in a virtual string tree.
  function CalcImagePos(const ATree: TVirtualStringTree;
                        const ANode: PVirtualNode;
                        const ACellRect: TRect): TPoint;

implementation

procedure SortColumn(const AHeader: TVTHeader;
                     const AColumn: TColumnIndex;
                     const ASortColor: TColor;
                     const AApplySort: Boolean);
begin
  with AHeader do
  begin
    if (ASortColor <> clNone) and (SortColumn <> -1) then
      with Columns[SortColumn] do
        if Tag <> 0 then
        begin
          if Tag = clNone then
            Options := Options + [coParentColor]
          else
            Color := Tag;

          Tag   := 0;
        end;

    if AApplySort then
      if SortColumn = AColumn then
        SortDirection := TSortDirection(1 - Integer(SortDirection))
      else begin
        SortColumn    := AColumn;
        SortDirection := sdAscending;
      end;

    if ASortColor <> clNone then
      with Columns[SortColumn] do
      begin
        if coParentColor in Options then
          Tag   := clNone
        else
          Tag   := Color;

        Color := ASortColor;
      end;
  end;
end;

function CalcImagePos(const ATree: TVirtualStringTree;
                      const ANode: PVirtualNode;
                      const ACellRect: TRect): TPoint;
var
  pNode:      PVirtualNode;

begin
  Result  := ACellRect.TopLeft;

  with ATree do
  begin
    pNode := ANode;
    if Assigned(pNode) and not (toShowRoot in ATree.TreeOptions.PaintOptions) then
      pNode := pNode^.Parent;
      
    while Assigned(pNode) and (pNode <> ATree.RootNode) do
    begin
      Inc(Result.X, Indent);
      pNode := pNode^.Parent;
    end;

    Inc(Result.X, Margin);
    Inc(Result.Y, (Integer(NodeHeight[ANode]) - Images.Height) div 2);
  end;
end;

end.
 