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
  VirtualTrees;

  //:$ Applies the sort order on the specified column
  //:: When a column is already sorted, the sort order is reversed.
  //:: Specify a SortColor to provide the new column with that color
  //:: (similar to Explorer in Windows XP). If you choose to use SortColor,
  //:: the column's Tag property will be used to restore the color when calling
  //:: SortColumn for the second time, so be sure not to rely on that.
  procedure SortColumn(const AHeader: TVTHeader;
                       const AColumn: TColumnIndex;
                       const ASortColor: TColor = clNone);

implementation

procedure SortColumn;
begin
  with AHeader do
  begin
    if (ASortColor <> clNone) and (SortColumn <> -1) then
      with Columns[SortColumn] do
        if Tag <> 0 then
        begin
          Color := TColor(Tag);
          Tag   := 0;
        end;

    if SortColumn = AColumn then
      SortDirection := TSortDirection(1 - Integer(SortDirection))
    else begin
      SortColumn    := AColumn;
      SortDirection := sdAscending;
    end;

    if ASortColor <> clNone then
      with Columns[SortColumn] do
      begin
        Tag   := Color;
        Color := ASortColor;
      end;
  end;
end;

end.
 