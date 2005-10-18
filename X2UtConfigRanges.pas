{
  :: X2UtConfigRanges provides various definition observers to ensure
  :: a value is within the specified range. To enforce a range on a defined
  :: value, call:
  ::
  :: IX2ConfigSource.Register(...).Attach(<RangeClass>.Create(...))
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtConfigRanges;

interface
uses
  X2UtConfig;

type
  TX2BaseConfigRange          = class(TInterfacedObject, IX2ConfigDefinitionObserver)
  protected
    // IX2ConfigDefinitionObserver
    procedure Read(const AConfig, AName: String; var AValue: Variant); virtual;
    procedure Write(const AConfig, AName: String; var AValue: Variant); virtual;

    procedure CheckRange(var AValue: Variant); virtual; abstract;
  end;

  TX2ConfigStringPosition     = (spLeft, spRight);
  TX2ConfigStringLengthRange  = class(TX2BaseConfigRange)
  private
    FCutOffPosition:  TX2ConfigStringPosition;
    FFillChar:        Char;
    FFillPosition:    TX2ConfigStringPosition;
    FMinLength:       Integer;
    FMaxLength:       Integer;
  protected
    procedure CheckRange(var AValue: Variant);
  public
    constructor Create(const AMinLength: Integer = 0;
                       const AMaxLength: Integer = 0;
                       const AFillChar: Char = #20;
                       const AFillPosition: TX2ConfigStringPosition = spRight;
                       const ACutOffPosition: TX2ConfigStringPosition = spRight);
  end;

  TX2ConfigIntegerRange = class(TX2BaseConfigRange)
  private
    FDefault:   Integer;
    FMax:       Integer;
    FMin:       Integer;
  protected
    procedure CheckRange(var AValue: Variant);
  public
    constructor Create(const AMin: Integer = Low(Integer);
                       const AMax: Integer = High(Integer);
                       const ADefault: Integer = 0);
  end;

implementation
uses
  Variants,

  X2UtMisc;


{========================================
  TX2BaseConfigRange
========================================}
procedure TX2BaseConfigRange.Read(const AConfig, AName: String;
                                  var AValue: Variant);
begin
  CheckRange(AValue);
end;

procedure TX2BaseConfigRange.Write(const AConfig, AName: String;
                                   var AValue: Variant);
begin
  CheckRange(AValue);
end;


{========================================
  TX2ConfigStringRange
========================================}
constructor TX2ConfigStringLengthRange.Create(const AMinLength,
                                              AMaxLength: Integer;
                                              const AFillChar: Char;
                                              const AFillPosition: TX2ConfigStringPosition;
                                              const ACutOffPosition: TX2ConfigStringPosition);
begin
  inherited Create();

  Assert((AMaxLength = 0) or
         (AMaxLength >= AMinLength),
         'MaxLength must be 0, equal to or larger than MinLength!');
          
  FMinLength      := AMinLength;
  FMaxLength      := AMaxLength;
  FFillChar       := AFillChar;
  FFillPosition   := AFillPosition;
  FCutOffPosition := ACutOffPosition;
end;

procedure TX2ConfigStringLengthRange.CheckRange(var AValue: Variant);
var
  sFill:      String;
  sValue:     String;

begin
  if VarIsType(AValue, varString) then
  begin
    sValue  := AValue;
    if Length(sValue) < FMinLength then
    begin
      sFill := StringOfChar(FFillChar, FMinLength - Length(sValue));

      case FFillPosition of
        spLeft:   sValue  := sFill + sValue;
        spRight:  sValue  := sValue + sFill;
      end;
    end;

    if (FMaxLength > 0) and (Length(sValue) > FMaxLength) then
      case FCutOffPosition of
        spLeft:   Delete(sValue, 1, Length(sValue) - FMaxLength);
        spRight:  SetLength(sValue, FMaxLength);
      end;

    AValue  := sValue;
  end else
    AValue  := StringOfChar(FFillChar, FMinLength);
end;


{========================================
  TX2ConfigIntegerRange
========================================}
constructor TX2ConfigIntegerRange.Create(const AMin, AMax, ADefault: Integer);
begin
  inherited Create();

  FMin      := AMin;
  FMax      := AMax;
  FDefault  := ADefault;
end;

procedure TX2ConfigIntegerRange.CheckRange(var AValue: Variant);
begin
  AValue  := InRange(AValue, FMin, FMax, FDefault);
end;

end.
