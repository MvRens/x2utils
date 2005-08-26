{
  :: Implements a lineair INI parser, used by X2UtConfigIni.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtIniParser;

interface
uses
  Classes;

type
  TX2CustomIniParser  = class(TObject)
  protected
    procedure DoComment(const AComment: String); virtual;
    procedure DoSection(const ASection: String); virtual;
    procedure DoValue(const AName, AValue: String); virtual;
  public
    procedure Execute(const AStrings: TStrings); overload; virtual;
    procedure Execute(const AStream: TStream); overload;
    procedure Execute(const AFileName: String); overload;
  end;

  TX2IniCommentEvent  = procedure(Sender: TObject; Comment: String) of object;
  TX2IniSectionEvent  = procedure(Sender: TObject; Section: String) of object;
  TX2IniValueEvent    = procedure(Sender: TObject; Name, Value: String) of object;

  TX2IniParser        = class(TX2CustomIniParser)
  private
    FOnComment:     TX2IniCommentEvent;
    FOnSection:     TX2IniSectionEvent;
    FOnValue:       TX2IniValueEvent;
  protected
    procedure DoComment(const AComment: String); override;
    procedure DoSection(const ASection: String); override;
    procedure DoValue(const AName, AValue: String); override;
  public
    property OnComment:     TX2IniCommentEvent  read FOnComment write FOnComment;
    property OnSection:     TX2IniSectionEvent  read FOnSection write FOnSection;
    property OnValue:       TX2IniValueEvent    read FOnValue   write FOnValue;
  end;

implementation
uses
  SysUtils;

const
  Comment       = ';';
  SectionStart  = '[';
  SectionEnd    = ']';
  NameValueSep  = '=';


{===================== TX2CustomIniParser
  Notifications
========================================}
procedure TX2CustomIniParser.DoComment(const AComment: String);
begin
end;

procedure TX2CustomIniParser.DoSection(const ASection: String);
begin
end;

procedure TX2CustomIniParser.DoValue(const AName, AValue: String);
begin
end;


{===================== TX2CustomIniParser
  Parser
========================================}
procedure TX2CustomIniParser.Execute(const AStrings: TStrings);
var
  iEnd:         Integer;
  iLine:        Integer;
  sLine:        String;
  sName:        String;
  sSection:     String;
  sValue:       String;

begin
  for iLine := 0 to Pred(AStrings.Count) do
  begin
    sLine := Trim(AStrings[iLine]);
    if Length(sLine) = 0 then
      continue;

    case sLine[1] of
      Comment:
        begin
          // Comment line
          Delete(sLine, 1, 1);
          DoComment(sLine);
          sLine := '';
        end;
      SectionStart:
        begin
          // Section line
          Delete(sLine, 1, 1);
          iEnd  := AnsiPos(SectionEnd, sLine);

          if iEnd > 0 then
          begin
            sSection  := sLine;
            SetLength(sSection, iEnd - 1);
            Delete(sLine, 1, iEnd);

            DoSection(Trim(sSection));
          end;
        end;
    else
      // Name-Value line
      iEnd  := AnsiPos(NameValueSep, sLine);
      if iEnd > 0 then
      begin
        sName   := sLine;
        SetLength(sName, iEnd - 1);
        Delete(sLine, 1, iEnd);

        sValue  := sLine;
        iEnd    := AnsiPos(Comment, sValue);
        if iEnd > 0 then
          SetLength(sValue, iEnd - 1);

        DoValue(TrimRight(sName), Trim(sValue));
      end;
    end;

    // Check for possible comment in the rest of the line
    iEnd  := AnsiPos(Comment, sLine);
    if iEnd > 0 then
    begin
      Delete(sLine, 1, iEnd);
      DoComment(TrimLeft(sLine));
    end;
  end;
end;

procedure TX2CustomIniParser.Execute(const AStream: TStream);
var
  slData:     TStringList;

begin
  slData  := TStringList.Create();
  try
    slData.LoadFromStream(AStream);
    Execute(slData);
  finally
    FreeAndNil(slData);
  end;
end;

procedure TX2CustomIniParser.Execute(const AFileName: String);
var
  fsData:     TFileStream;

begin
  fsData  := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Execute(fsData);
  finally
    FreeAndNil(fsData);
  end;
end;


{=========================== TX2IniParser
  Events
========================================}
procedure TX2IniParser.DoComment(const AComment: String);
begin
  if Assigned(FOnComment) then
    FOnComment(Self, AComment);
end;

procedure TX2IniParser.DoSection(const ASection: String);
begin
  if Assigned(FOnSection) then
    FOnSection(Self, ASection);
end;

procedure TX2IniParser.DoValue(const AName, AValue: String);
begin
  if Assigned(FOnValue) then
    FOnValue(Self, AName, AValue);
end;

end.
 