{
  :: X2UtBits provides declarations and functions for easy bit manipulation
  :: based on Delphi sets.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtBits;

{$I X2UtCompilerVersion.inc}
{$IFDEF D7}
  {$WARN UNSAFE_CODE OFF}
{$ENDIF}

interface
type
  TBit          = (bit0,  bit1,  bit2,  bit3,  bit4,  bit5,  bit6,  bit7,
                   bit8,  bit9,  bit10, bit11, bit12, bit13, bit14, bit15,
                   bit16, bit17, bit18, bit19, bit20, bit21, bit22, bit23,
                   bit24, bit25, bit26, bit27, bit28, bit29, bit30, bit31,
                   bit32, bit33, bit34, bit35, bit36, bit37, bit38, bit39,
                   bit40, bit41, bit42, bit43, bit44, bit45, bit46, bit47,
                   bit48, bit49, bit50, bit51, bit52, bit53, bit54, bit55,
                   bit56, bit57, bit58, bit59, bit60, bit61, bit62, bit63);

  TBitSize      = (bs8, bs16, bs24, bs32, bs64);

  T8Bit         = bit0..bit7;
  T16Bit        = bit0..bit15;
  T24Bit        = bit0..bit23;
  T32Bit        = bit0..bit31;
  T64Bit        = bit0..bit63;

  T8Bits        = set of T8Bit;
  T16Bits       = set of T16Bit;
  T24Bits       = set of T24Bit;
  T32Bits       = set of T32Bit;
  T64Bits       = set of T64Bit;
  TMaxBits      = set of TBit;

  TByteBits     = T8Bits;
  TWordBits     = T16Bits;
  TIntegerBits  = T32Bits;
  TInt64Bits    = T64Bits;


  // Unfortunately we can't really overload this (or at least I haven't found
  // out how without an "Ambiguous overloaded call" error).
  function BitsToString(const ABits: TMaxBits; const ASize: TBitSize): String;

  function StringToBits(const ABits: String): TMaxBits;

implementation

{========================================
  Bits to String
========================================}
function BitsToString;
var
  bBit:       TBit;
  bMax:       TBit;
  iLength:    Integer;
  iPos:       Integer;

begin
  Result  := '';

  case ASize of
    bs8:
      begin
        bMax    := bit7;
        iLength := 8;
      end;
    bs16:
      begin
        bMax    := bit15;
        iLength := 16;
      end;
    bs24:
      begin
        bMax    := bit23;
        iLength := 24;
      end;
    bs32:
      begin
        bMax    := bit31;
        iLength := 32;
      end;
    bs64:
      begin
        bMax    := bit63;
        iLength := 64;
      end;
  else
    exit;
  end;

  SetLength(Result, iLength);
  iPos  := 1;

  for bBit  := bMax downto bit0 do
  begin
    if bBit in ABits then
      Result[iPos]  := '1'
    else
      Result[iPos]  := '0';

    Inc(iPos);
  end;
end;


{========================================
  String to Bits
========================================}
function StringToBits;
var
  bBit:       TBit;
  iPos:       Integer;
  iLength:    Integer;

begin
  Result  := [];
  bBit    := bit0;
  iLength := Length(ABits);
  if iLength > 64 then
    iLength := 64;

  for iPos  := iLength downto 1 do
  begin
    if ABits[iPos] = '1' then
      Include(Result, bBit);
      
    Inc(bBit);
  end;
end;

end.
