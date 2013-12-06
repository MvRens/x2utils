unit X2UtDelphiCompatibility;

interface
uses
  SysUtils;


  function CharInSet(C: Char; const CharSet: TSysCharSet): Boolean;
  function GetDefaultFormatSettings: TFormatSettings;


implementation
{$IF CompilerVersion < 20}
uses
  Windows;
{$ENDIF}


function CharInSet(C: Char; const CharSet: TSysCharSet): Boolean;
begin
  {$IF CompilerVersion < 20}
  Result := C in CharSet;
  {$ELSE}
  Result := SysUtils.CharInSet(C, CharSet);
  {$IFEND}
end;


function GetDefaultFormatSettings: TFormatSettings;
begin
  {$IF CompilerVersion < 20}
  GetLocaleFormatSettings(LOCALE_SYSTEM_DEFAULT, Result);
  {$ELSE}
  Result := TFormatSettings.Create;
  {$IFEND}
end;

end.
