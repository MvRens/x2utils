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
  VirtualTrees;

  //:$ Applies the sort order on the specified column
  //:: When a column is already sorted, the sort order is reversed.
  procedure SortColumn(const AHeader: TVTHeader;
                       const AColumn: TColumnIndex);

implementation

procedure SortColumn;
begin
  with AHeader do
    if SortColumn = AColumn then
      SortDirection := TSortDirection(1 - Integer(SortDirection))
    else begin
      SortColumn    := AColumn;
      SortDirection := sdAscending;
    end;
end;

end.
 