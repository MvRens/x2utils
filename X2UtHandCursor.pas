{
  :: X2UtHandCursor replaces the default Delphi hand cursor with the system
  :: hand cursor if available, or a copy when running on Windows 95.
  ::
  :: Including this unit in your project will automatically replace the
  :: hand cursor, no further actions are necessary.
  ::
  :: Subversion repository available at:
  ::   $URL$
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $LastChangedBy$

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
