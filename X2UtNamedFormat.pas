{
  :: X2UtNamedFormat implements Format-style functionality using named
  :: instead of indexed parameters.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtNamedFormat;

interface
  {
    AFormat uses the same format strings as SysUtils.Format, where each
    format specifier may use a named instead of a numeric index.

    AParams contains alternating the parameter name and it's value.

    Note: NamedFormat works by mapping names to indices and passing the result
    to SysUtils.Format. Unnamed specifiers will therefore be affected by
    named specifiers! It is recommended to name all specifiers.
  }
  function NamedFormat(const AFormat: String; AParams: array of const): String;

  
implementation
uses
  Classes,
  SysUtils;


type
  TProtectedMemoryStream  = class(TMemoryStream);


const
  SpecifierChar   = '%';
  ValidNameChars  = ['A'..'Z', 'a'..'z', '0'..'9'];


procedure StreamWriteChar(const AStream: TStream; const AValue: Char);
begin
  AStream.WriteBuffer(AValue, SizeOf(Char));
end;


procedure StreamWriteString(const AStream: TStream; const AValue: String);
begin
  AStream.WriteBuffer(PChar(AValue)^, Length(AValue));
end;


function FindNameEnd(const APosition: PChar; const AEnd: PChar): PChar;
var
  position:   PChar;

begin
  Result    := nil;
  position  := APosition;

  while position < AEnd do
  begin
    if position^ = ':' then
    begin
      Result  := position;
      break;
    end;

    if not (position^ in ValidNameChars) then
      break;

    Inc(position);
  end;
end;


function NamedFormat(const AFormat: String; AParams: array of const): String;
var
  currentPos:     PChar;
  formatEnd:      PChar;
  formatStream:   TMemoryStream;
  formatString:   String;
  name:           String;
  nameEnd:        PChar;
  nameStart:      PChar;
  param:          TVarRec;
  paramIndex:     Integer;
  paramNames:     TStringList;
  paramValues:    array of TVarRec;
  specifierIndex: Integer;

begin
  if Length(AParams) mod 2 = 1 then
    raise Exception.Create('AParams must contains a multiple of 2 number of items');

  currentPos    := PChar(AFormat);
  SetLength(paramValues, 0);

  formatEnd   := currentPos;
  Inc(formatEnd, Length(AFormat));

  paramNames    := TStringList.Create();
  try
    paramNames.CaseSensitive  := False;

    formatStream  := TMemoryStream.Create();
    try
      { Most likely scenario; the names are longer than the replacement
        indexes. }
      TProtectedMemoryStream(formatStream).Capacity := Length(AFormat);

      while currentPos < formatEnd do
      begin
        { Search for % }
        if currentPos^ = SpecifierChar then
        begin
          StreamWriteChar(formatStream, currentPos^);
          Inc(currentPos);

          { Check if this is not an escape character }
          if (currentPos < formatEnd) and (currentPos^ <> SpecifierChar) then
          begin
            nameStart := currentPos;
            nameEnd   := FindNameEnd(currentPos, formatEnd);

            if Assigned(nameEnd) then
            begin
              SetString(name, nameStart, nameEnd - nameStart);

              specifierIndex  := paramNames.IndexOf(name);
              if specifierIndex = -1 then
                specifierIndex  := paramNames.Add(name);

              StreamWriteString(formatStream, IntToStr(specifierIndex));
              currentPos  := nameEnd;
            end;
          end;
        end;

        StreamWriteChar(formatStream, currentPos^);
        Inc(currentPos);
      end;

      SetString(formatString, PChar(formatStream.Memory), formatStream.Size);
    finally
      FreeAndNil(formatStream);
    end;

    SetLength(paramValues, paramNames.Count);
    paramIndex  := 0;

    while paramIndex < High(AParams) do
    begin
      param := AParams[paramIndex];
      
      case param.VType of
        vtChar:       name  := param.VChar;
        vtString:     name  := param.VString^;
        vtPChar:      name  := param.VPChar;
        vtAnsiString: name  := PChar(param.VAnsiString);
      else
        raise Exception.CreateFmt('Parameter name at index %d is not a string value',
                                  [paramIndex div 2]);
      end;

      Inc(paramIndex);

      specifierIndex  := paramNames.IndexOf(name);
      if specifierIndex = -1 then
        raise Exception.CreateFmt('Parameter "%s" could not be found in the format string',
                                  [name]);

      paramValues[specifierIndex] := AParams[paramIndex];
      Inc(paramIndex);
    end;
  finally
    FreeAndNil(paramNames);
  end;

  Result  := Format(formatString, paramValues);
end;


end.
