{
  :: X2UtStrings provides various string-related functions.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
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
