{
  :: X2UtSettingsVirtualTree provides functions to read and write VirtualTree
  :: settings.
  ::
  :: Last changed:    $Date: 2004-07-22 16:52:09 +0200 (Thu, 22 Jul 2004) $
  :: Revision:        $Rev: 25 $
  :: Author:          $Author: psycho $
}
unit X2UtSettingsVirtualTree;

interface
uses
  VirtualTrees,
  X2UtSettings;

  procedure ReadVTHeader(const AFactory: TX2SettingsFactory;
                         const ASection: String; const AHeader: TVTHeader);
  procedure WriteVTHeader(const AFactory: TX2SettingsFactory;
                          const ASection: String; const AHeader: TVTHeader);

implementation
uses
  SysUtils;

procedure ReadVTHeader(const AFactory: TX2SettingsFactory;
                       const ASection: String; const AHeader: TVTHeader);
var
  iColumn:        Integer;
  sColumn:        String;

begin
  with AFactory[ASection] do
  try
    AHeader.SortColumn  := ReadInteger('SortColumn', AHeader.SortColumn);
    if ReadBool('SortAscending', AHeader.SortDirection = sdAscending) then
      AHeader.SortDirection := sdAscending
    else
      AHeader.SortDirection := sdDescending;

    for iColumn := 0 to Pred(AHeader.Columns.Count) do
      with AHeader.Columns[iColumn] do
      begin
        sColumn   := IntToStr(iColumn) + '.';
        Position  := ReadInteger(sColumn + 'Position', Position);
        Width     := ReadInteger(sColumn + 'Width', Width);
        if ReadBool(sColumn + 'Visible', coVisible in Options) then
          Options := Options + [coVisible]
        else
          Options := Options - [coVisible];
      end;
  finally
    Free();
  end;
end;

procedure WriteVTHeader(const AFactory: TX2SettingsFactory;
                        const ASection: String; const AHeader: TVTHeader);
var
  iColumn:        Integer;
  sColumn:        String;

begin
  with AFactory[ASection] do
  try
    WriteInteger('SortColumn', AHeader.SortColumn);
    WriteBool('SortAscending', AHeader.SortDirection = sdAscending);
    
    for iColumn := 0 to Pred(AHeader.Columns.Count) do
      with AHeader.Columns[iColumn] do
      begin
        sColumn   := IntToStr(iColumn) + '.';
        WriteInteger(sColumn + 'Position', Position);
        WriteInteger(sColumn + 'Width', Width);
        WriteBool(sColumn + 'Visible', coVisible in Options);
      end;
  finally
    Free();
  end;
end;

end.
