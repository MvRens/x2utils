{
  :: X2UtGraphics contains various graphics-related functions.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2UtGraphics;

interface
uses
  Classes,
  Controls,
  Graphics;

  {
    :$ Applies anti-aliasing to a font.

    :: Sets the font quality to it's maximum value, causing Windows 2000 and
    :: above to draw the font anti-aliased.
  }
  procedure AAFont(const AFont: TFont);

  {
    :$ Applies anti-aliasing to a control's font.

    :: Sets the font quality to it's maximum value, causing Windows 2000 and
    :: above to draw the font anti-aliased.
  }
  procedure AAControl(const AControl: TControl);

  {
    :$ Applies anti-aliasing to all child controls.

    :: Sets the font quality to it's maximum value, causing Windows 2000 and
    :: above to draw the font anti-aliased. If ARecursive is set to True,
    :: all children's children will be processed as well.
  }
  procedure AAChildren(const AParent: TWinControl;
                       const ARecursive: Boolean = False);

  {
    :$ Applies anti-aliasing to all owned controls.

    :: Sets the font quality to it's maximum value, causing Windows 2000 and
    :: above to draw the font anti-aliased.
  }
  procedure AAOwned(const AOwner: TComponent);

  {
    :$ Blends the two colors using the specified alpha value

    :: The alpha determines how much of the foreground color is applied to the
    :: background color. The alpha value must be between 0 and 255 (where 0
    :: indicates full transparency and 255 an opaque foreground).
  }
  function BlendColors(const ABackground, AForeground: TColor;
                       const AAlpha: Byte): TColor;

  {
    :$ Darkens a color with the specified value
  }
  function DarkenColor(const AColor: TColor; const AValue: Byte): TColor;

  {
    :$ Lightens a color with the specified value
  }
  function LightenColor(const AColor: TColor; const AValue: Byte): TColor;


implementation
uses
  SysUtils,
  Windows;

type
  { Explanation of sneaky hack:

      Normally, protected members are available only in either the unit in which
      the class is declared, or any descendants. Using this fact, we create a
      descendant of the class and use the descendant in the same class, thus
      we are able to access the protected properties...
  }
  THackControl  = class(TControl);


procedure AAFont(const AFont: TFont);
var
  pFont:      TLogFont;
  hAAFont:    HFONT;

begin
  // Use AFont as a starting point...
  with pFont do begin
    lfHeight          := AFont.Height;
    lfWidth           := 0;
    lfEscapement      := 0;
    lfOrientation     := 0;

    if fsBold in AFont.Style then
      lfWeight        := FW_BOLD
    else
      lfWeight        := 0;

    // These are actually booleans, but implemented as bytes for some reason
    lfItalic          := Byte(fsItalic in AFont.Style);
    lfUnderline       := Byte(fsUnderline in AFont.Style);
    lfStrikeOut       := 0;
    lfCharSet         := DEFAULT_CHARSET;
    lfOutPrecision    := OUT_DEFAULT_PRECIS;
    lfClipPrecision   := CLIP_DEFAULT_PRECIS;

    // This is what causes the anti-aliasing
    lfQuality         := ANTIALIASED_QUALITY;

    lfPitchAndFamily  := DEFAULT_PITCH;
    StrPCopy(lfFaceName, AFont.Name);
  end;

  // Create the font
  hAAFont := CreateFontIndirect(pFont);

  // Assign it to the control
  AFont.Handle  := hAAFont;
end;

procedure AAControl(const AControl: TControl);
var
  pControl:     THackControl;

begin
  pControl              := THackControl(AControl);
  AAFont(pControl.Font);
end;

procedure AAChildren(const AParent: TWinControl;
                     const ARecursive: Boolean = False);
var
  iControl:       Integer;

begin
  for iControl  := 0 to AParent.ControlCount - 1 do
  begin
    AAControl(AParent.Controls[iControl]);

    if ARecursive and (AParent.Controls[iControl] is TWinControl) then
      AAChildren(TWinControl(AParent.Controls[iControl]), True);
  end;
end;

procedure AAOwned(const AOwner: TComponent);
var
  iControl:       Integer;

begin
  for iControl  := 0 to AOwner.ComponentCount - 1 do
    if AOwner.Components[iControl] is TControl then
      AAControl(TControl(AOwner.Components[iControl]));
end;


function BlendColors(const ABackground, AForeground: TColor;
                     const AAlpha: Byte): TColor;
var
  cBack:        Cardinal;
  cFore:        Cardinal;
  iBack:        Integer;
  iFore:        Integer;

begin
  if AAlpha = 0 then
    Result  := ABackground
  else if AAlpha = 255 then
    Result  := AForeground
  else
  begin
    cBack   := ColorToRGB(ABackground);
    cFore   := ColorToRGB(AForeground);
    iBack   := 256 - AAlpha;
    iFore   := Succ(AAlpha);

    Result  := RGB(((GetRValue(cBack) * iBack) +
                    (GetRValue(cFore) * iFore)) shr 8,
                   ((GetGValue(cBack) * iBack) +
                    (GetGValue(cFore) * iFore)) shr 8,
                   ((GetBValue(cBack) * iBack) +
                    (GetBValue(cFore) * iFore)) shr 8);
  end;
end;


function DarkenColor(const AColor: TColor; const AValue: Byte): TColor;
var
  cColor:     Cardinal;
  iRed:       Integer;
  iGreen:     Integer;
  iBlue:      Integer;

begin
  cColor  := ColorToRGB(AColor);
  iRed    := (cColor and $FF0000) shr 16;;
  iGreen  := (cColor and $00FF00) shr 8;
  iBlue   := cColor and $0000FF;

  Dec(iRed, AValue);
  Dec(iGreen, AValue);
  Dec(iBlue, AValue);

  if iRed   < 0 then iRed   := 0;
  if iGreen < 0 then iGreen := 0;
  if iBlue  < 0 then iBlue  := 0;

  Result  := (iRed shl 16) + (iGreen shl 8) + iBlue;
end;

function LightenColor(const AColor: TColor; const AValue: Byte): TColor;
var
  cColor:     Cardinal;
  iRed:       Integer;
  iGreen:     Integer;
  iBlue:      Integer;

begin
  cColor  := ColorToRGB(AColor);
  iRed    := (cColor and $FF0000) shr 16;;
  iGreen  := (cColor and $00FF00) shr 8;
  iBlue   := cColor and $0000FF;

  Inc(iRed, AValue);
  Inc(iGreen, AValue);
  Inc(iBlue, AValue);

  if iRed   > 255 then iRed   := 255;
  if iGreen > 255 then iGreen := 255;
  if iBlue  > 255 then iBlue  := 255;

  Result  := (iRed shl 16) + (iGreen shl 8) + iBlue;
end;

end.
