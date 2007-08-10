{
  :: X2UtPersistVirtualTree provides functions to read and write VirtualTree
  :: settings.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtPersistVirtualTree;

interface
uses
  VirtualTrees,

  X2UtPersistIntf;


  procedure ReadVTHeader(const AReader: IX2PersistReader; const AHeader: TVTHeader);
  procedure WriteVTHeader(const AWriter: IX2PersistWriter; const AHeader: TVTHeader);


implementation
uses
  SysUtils;


procedure ReadVTHeader(const AReader: IX2PersistReader; const AHeader: TVTHeader);
var
  sortColumn:     Integer;
  sortAscending:  Boolean;
  columnIndex:    Integer;
  column:         TVirtualTreeColumn;
  keyPrefix:      String;
  position:       Integer;
  width:          Integer;
  visible:        Boolean;

begin
  if AReader.ReadInteger('SortColumn', sortColumn) then
    AHeader.SortColumn  := sortColumn;

  if AReader.ReadBoolean('SortAscending', sortAscending) then
  begin
    if sortAscending then
      AHeader.SortDirection := sdAscending
    else
      AHeader.SortDirection := sdDescending;
  end;

  for columnIndex := 0 to Pred(AHeader.Columns.Count) do
  begin
    column    := AHeader.Columns[columnIndex];
    keyPrefix := IntToStr(columnIndex) + '.';

    if AReader.ReadInteger(keyPrefix + 'Position', position) then
      column.Position := position;

    if AReader.ReadInteger(keyPrefix + 'Width', width) then
      column.Width    := width;

    if AReader.ReadBoolean(keyPrefix + 'Visible', visible) then
    begin
      if visible then
        column.Options  := column.Options + [coVisible]
      else
        column.Options  := column.Options - [coVisible];
    end;
  end;
end;


procedure WriteVTHeader(const AWriter: IX2PersistWriter; const AHeader: TVTHeader);
var
  columnIndex:      Integer;
  keyPrefix:        String;

begin
  AWriter.WriteInteger('SortColumn', AHeader.SortColumn);
  AWriter.WriteBoolean('SortAscending', (AHeader.SortDirection = sdAscending));

  for columnIndex := 0 to Pred(AHeader.Columns.Count) do
    with AHeader.Columns[columnIndex] do
    begin
      keyPrefix := IntToStr(columnIndex) + '.';

      AWriter.WriteInteger(keyPrefix + 'Position',  Position);
      AWriter.WriteInteger(keyPrefix + 'Width',     Width);
      AWriter.WriteBoolean(keyPrefix + 'Visible',   coVisible in Options);
    end;
end;

end.
