{
  :: X2UtHandCursor replaces the default Delphi hand cursor with the system
  :: hand cursor if available, or a copy when running on Windows 95.
  ::
  :: Including this unit in your project will automatically replace the
  :: hand cursor, no further actions are necessary.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtHandCursor;

interface

implementation
uses
  Controls,
  Forms,
  Windows;

{$R X2UtHandCursor.RES}

var
  hCursor:          THandle;

initialization
  hCursor := LoadCursor(0, IDC_HAND);
  if hCursor = 0 then
    hCursor := LoadCursor(hInstance, 'X2UTHANDCURSOR');

  if hCursor <> 0 then
    Screen.Cursors[crHandpoint] := hCursor;

finalization

end.
