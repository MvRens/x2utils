{
  :: X2UtSettingsForm provides functions to read and write form settings.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtSettingsForm;

interface
uses
  Forms,
  X2UtSettings;

  procedure ReadFormPos(const AFactory: TX2SettingsFactory;
                        const ASection: String; const AForm: TCustomForm);
  procedure WriteFormPos(const AFactory: TX2SettingsFactory;
                         const ASection: String; const AForm: TCustomForm);

implementation
uses
  MultiMon,
  Windows;

type
  THackCustomForm = class(TCustomForm);

procedure ReadFormPos(const AFactory: TX2SettingsFactory;
                      const ASection: String; const AForm: TCustomForm);
var
  rBounds:      TRect;

begin
  with AFactory[ASection] do
  try
    if ValueExists('Left') then
    begin
      if ReadBool('Maximized', (AForm.WindowState = wsMaximized)) then
        AForm.WindowState := wsMaximized
      else with THackCustomForm(AForm) do
      begin
        rBounds.Left      := ReadInteger('Left', Left);
        rBounds.Top       := ReadInteger('Top', Top);
        rBounds.Right     := rBounds.Left + ReadInteger('Width', Width);
        rBounds.Bottom    := rBounds.Top + ReadInteger('Height', Height);

        // Make sure the window is at least partially visible
        if MonitorFromRect(@rBounds, MONITOR_DEFAULTTONULL) <> 0 then
        begin
          WindowState       := wsNormal;
          Position          := poDesigned;
          BoundsRect        := rBounds;
        end;
      end;
    end;
  finally
    Free();
  end;
end;

procedure WriteFormPos(const AFactory: TX2SettingsFactory;
                       const ASection: String; const AForm: TCustomForm);
var
  pPlacement:     TWindowPlacement;

begin
  with AFactory[ASection] do
  try
    WriteBool('Maximized', (AForm.WindowState = wsMaximized));

    pPlacement.length := SizeOf(TWindowPlacement);
    if GetWindowPlacement(AForm.Handle, @pPlacement) <> 0 then
      with pPlacement.rcNormalPosition do
      begin
        WriteInteger('Left', Left);
        WriteInteger('Top', Top);
        WriteInteger('Width', Right - Left);
        WriteInteger('Height', Bottom - Top);
      end;
  finally
    Free();
  end;
end;

end.
