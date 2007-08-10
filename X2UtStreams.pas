{
  :: X2UtStreams provides a helper class for reading and writing standard
  :: data types to and from streams.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtStreams;

interface
uses
  Classes;

  
type
  TX2StreamHelper = class(TObject)
  private
    FOwnership:     TStreamOwnership;
    FStream:        TStream;

    function GetBof(): Boolean;
    function GetEof(): Boolean;
  public
    constructor Create(const AStream: TStream; const AOwnership: TStreamOwnership = soReference);
    destructor Destroy(); override;

    function ReadBool(): Boolean;
    function ReadByte(): Byte;
    function ReadDateTime(): TDateTime;
    function ReadFloat(): Double;
    function ReadInteger(): Integer;
    function ReadString(const ALength: Integer = -1): String;

    procedure WriteBool(const AValue: Boolean);
    procedure WriteByte(const AValue: Byte);
    procedure WriteDateTime(const AValue: TDateTime);
    procedure WriteFloat(const AValue: Double);
    procedure WriteInteger(const AValue: Integer);
    procedure WriteString(const AValue: String; const AWriteLength: Boolean = True);

    procedure Skip(const ACount: Integer);

    property Bof:         Boolean           read GetBof;
    property Eof:         Boolean           read GetEof;
    property Ownership:   TStreamOwnership  read FOwnership write FOwnership;
    property Stream:      TStream           read FStream;
  end;


implementation
uses
  SysUtils;


{ TX2UtStreamHelper }
constructor TX2StreamHelper.Create(const AStream: TStream; const AOwnership: TStreamOwnership);
begin
  inherited Create();

  FStream     := AStream;
  FOwnership  := AOwnership;
end;


destructor TX2StreamHelper.Destroy();
begin
  if FOwnership = soOwned then
    FreeAndNil(FStream);  

  inherited;
end;


function TX2StreamHelper.ReadBool(): Boolean;
begin
  Stream.ReadBuffer(Result, SizeOf(Boolean));
end;


function TX2StreamHelper.ReadByte(): Byte;
begin
  Stream.ReadBuffer(Result, SizeOf(Byte));
end;


function TX2StreamHelper.ReadDateTime(): TDateTime;
begin
  Result  := ReadFloat();
end;


function TX2StreamHelper.ReadFloat(): Double;
begin
  Stream.ReadBuffer(Result, SizeOf(Double));
end;


function TX2StreamHelper.ReadInteger(): Integer;
begin
  Stream.ReadBuffer(Result, SizeOf(Integer));
end;


function TX2StreamHelper.ReadString(const ALength: Integer): String;
var
  valueLength:    Integer;

begin
  valueLength := ALength;
  if valueLength = -1 then
    valueLength := ReadInteger();

  if valueLength > 0 then
  begin
    SetLength(Result, valueLength);
    Stream.ReadBuffer(PChar(Result)^, valueLength);
  end else
    Result  := '';
end;


procedure TX2StreamHelper.WriteBool(const AValue: Boolean);
begin
  Stream.Write(AValue, SizeOf(Boolean));
end;


procedure TX2StreamHelper.WriteByte(const AValue: Byte);
begin
  Stream.WriteBuffer(AValue, SizeOf(Byte));
end;


procedure TX2StreamHelper.WriteDateTime(const AValue: TDateTime);
begin
  WriteFloat(AValue);
end;


procedure TX2StreamHelper.WriteFloat(const AValue: Double);
begin
  Stream.Write(AValue, SizeOf(Double));
end;


procedure TX2StreamHelper.WriteInteger(const AValue: Integer);
begin
  Stream.Write(AValue, SizeOf(Integer));
end;


procedure TX2StreamHelper.WriteString(const AValue: String; const AWriteLength: Boolean);
var
  valueLength:    Integer;

begin
  valueLength := Length(AValue);

  if AWriteLength then
    WriteInteger(valueLength);

  Stream.Write(PChar(AValue)^, valueLength);
end;


procedure TX2StreamHelper.Skip(const ACount: Integer);
begin
  Stream.Seek(ACount, soFromCurrent);
end;


function TX2StreamHelper.GetBof(): Boolean;
begin
  Result  := (Stream.Position = 0);
end;


function TX2StreamHelper.GetEof(): Boolean;
begin
  Result  := (Stream.Position = Stream.Size);
end;

end.
