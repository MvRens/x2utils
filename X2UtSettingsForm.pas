{
  :: X2UtSettingsForm provides functions to read and write form settings.
  ::
  :: Subversion repository available at:
  ::   $URL$
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$

  :$
  :$
  :$ X2Utils is released under the zlib/libpng OSI-approved license.
  :$ For more information: http://www.opensource.org/
  :$ /n/n
  :$ /n/n
  :$ Copyright (c) 2003 X2Software
  :$ /n/n
  :$ This software is provided 'as-is', without any express or implied warranty.
  :$ In no event will the authors be held liable for any damages arising from
  :$ the use of this software.
  :$ /n/n
  :$ Permission is granted to anyone to use this software for any purpose,
  :$ including commercial applications, and to alter it and redistribute it
  :$ freely, subject to the following restrictions:
  :$ /n/n
  :$ 1. The origin of this software must not be misrepresented; you must not
  :$ claim that you wrote the original software. If you use this software in a
  :$ product, an acknowledgment in the product documentation would be
  :$ appreciated but is not required.
  :$ /n/n
  :$ 2. Altered source versions must be plainly marked as such, and must not be
  :$ misrepresented as being the original software.
  :$ /n/n
  :$ 3. This notice may not be removed or altered from any source distribution.
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
