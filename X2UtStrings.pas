{
  :: X2UtStrings provides various string-related functions.
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
unit X2UtStrings;

interface
  //:$ Formats the specified size
  //:: If KeepBytes is true, the size will be formatted for decimal separators
  //:: and 'bytes' will be appended. If KeepBytes is false the best suitable
  //:: unit will be chosen (KB, MB, GB).
  function FormatSize(const Bytes: Int64; KeepBytes: Boolean = False): String;

implementation
uses
  SysUtils;

function FormatSize;
const
  KB  = 1024;
  MB  = KB * 1024;
  GB  = MB * 1024;

var
  dSize:      Double;
  sExt:       String;

begin
  sExt  := ' bytes';
  dSize := Bytes;

  if (not KeepBytes) and (Bytes >= KB) then
    if (Bytes >= KB) and (Bytes < MB) then begin
      // 1 kB ~ 1 MB
      dSize := Bytes / KB;
      sExt  := ' KB';
    end else if (Bytes >= MB) and (Bytes < GB) then begin
      // 1 MB ~ 1 GB
      dSize := Bytes / MB;
      sExt  := ' MB';
    end else begin
      // 1 GB ~ x
      dSize := Bytes / GB;
      sExt  := ' GB';
    end;

  Result  := FormatFloat(',0.##', dSize) + sExt;
end;

end.
