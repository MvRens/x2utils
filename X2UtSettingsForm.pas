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
type
  THackCustomForm = class(TCustomForm);

procedure ReadFormPos;
begin
  with AFactory[ASection] do
    try
      if ReadBool('Maximized', (AForm.WindowState = wsMaximized)) then
        AForm.WindowState := wsMaximized
      else with THackCustomForm(AForm) do begin
        WindowState       := wsNormal;
        Position          := poDesigned;
        Left              := ReadInteger('Left', Left);
        Top               := ReadInteger('Top', Top);
        Width             := ReadInteger('Width', Width);
        Height            := ReadInteger('Height', Height);
      end;
    finally
      Free();
    end;
end;

procedure WriteFormPos;
begin
  with AFactory[ASection] do
    try
      WriteBool('Maximized', (AForm.WindowState = wsMaximized));
      if AForm.WindowState <> wsMaximized then
        with THackCustomForm(AForm) do begin
          WriteInteger('Left', Left);
          WriteInteger('Top', Top);
          WriteInteger('Width', Width);
          WriteInteger('Height', Height);
        end;
    finally
      Free();
    end;
end;

end.
