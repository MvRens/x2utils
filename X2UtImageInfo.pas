unit X2UtImageInfo;

interface
uses
  Windows,
  SysUtils,
  Classes,
  Graphics;

type
  TX2ImageType  = (itUnknown, itBMP, itGIF, itJPG, itPNG);
  TX2ImageInfo  = record
    ImgType:      TX2ImageType;
    Width:        Cardinal;
    Height:       Cardinal;
  end;

  function GetImageInfo(const AFilename: String): TX2ImageInfo; overload;
  function GetImageInfo(const AStream: TStream): TX2ImageInfo; overload;

  function GetImageSize(const AFilename: String): TSize; overload;
  function GetImageSize(const AStream: TStream): TSize; overload;

  function GetImageType(const AFilename: String): TX2ImageType; overload;
  function GetImageType(const AStream: TStream): TX2ImageType; overload;


implementation
uses
  Math,
  Types;


type
  TGetDimensionsProc  = procedure(const ASource: TStream; var AImageInfo: TX2ImageInfo);

  TCardinal     = record
    case Byte of
      0: (Value: Cardinal);
      1: (Byte1, Byte2, Byte3, Byte4: Byte);
  end;

  TWord         = record
    case Byte of
      0: (Value: Word);
      1: (Byte1, Byte2: Byte);
  end;

  TPNGIHDRChunk = packed record
    Width:          Cardinal;
    Height:         Cardinal;
    Bitdepth:       Byte;
    Colortype:      Byte;
    Compression:    Byte;
    Filter:         Byte;
    Interlace:      Byte;
  end;

  TGIFHeader    = packed record
    Signature:      array[0..2] of Char;
    Version:        array[0..2] of Char;
    Width:          Word;
    Height:         Word;
  end;

  TJPGChunk     = record
    ID:             Word;
    Length:         Word;
  end;

  TJPGHeader    = packed record
    Reserved:       Byte;
    Height:         Word;
    Width:          Word;
  end;


const
  SIG_BMP:      array[0..1] of Char = ('B', 'M');
  SIG_GIF:      array[0..2] of Char = ('G', 'I', 'F');
  SIG_JPG:      array[0..2] of Char = (#255, #216, #255);
  SIG_PNG:      array[0..7] of Char = (#137, #80, #78, #71, #13, #10, #26, #10);



function SwapBytes(const ASource: Cardinal): Cardinal; overload;
var
  mwSource:     TCardinal;
  mwDest:       TCardinal;

begin
  mwSource.Value  := ASource;
  mwDest.Byte1    := mwSource.Byte4;
  mwDest.Byte2    := mwSource.Byte3;
  mwDest.Byte3    := mwSource.Byte2;
  mwDest.Byte4    := mwSource.Byte1;
  Result          := mwDest.Value;
end;

function SwapBytes(const ASource: Word): Word; overload;
var
  mwSource:     TWord;
  mwDest:       TWord;

begin
  mwSource.Value  := ASource;
  mwDest.Byte1    := mwSource.Byte2;
  mwDest.Byte2    := mwSource.Byte1;
  Result          := mwDest.Value;
end;


procedure GetBMPDimensions(const ASource: TStream; var AImageInfo: TX2ImageInfo);
var
  bmpFileHeader:      TBitmapFileHeader;
  bmpInfoHeader:      TBitmapInfoHeader;

begin
  FillChar(bmpFileHeader, SizeOf(TBitmapFileHeader), #0);
  FillChar(bmpInfoHeader, SizeOf(TBitmapInfoHeader), #0);

  ASource.Read(bmpFileHeader, SizeOf(TBitmapFileHeader));
  ASource.Read(bmpInfoHeader, SizeOf(TBitmapInfoHeader));

  AImageInfo.Width  := bmpInfoHeader.biWidth;
  AImageInfo.Height := bmpInfoHeader.biHeight;
end;

procedure GetGIFDimensions(const ASource: TStream; var AImageInfo: TX2ImageInfo);
var
  gifHeader:        TGIFHeader;

begin
  FillChar(gifHeader, SizeOf(TGIFHeader), #0);
  ASource.Read(gifHeader, SizeOf(TGIFHeader));

  AImageInfo.Width  := gifHeader.Width;
  AImageInfo.Height := gifHeader.Height;
end;

procedure GetJPGDimensions(const ASource: TStream; var AImageInfo: TX2ImageInfo);
var
  cSig:         array[0..1] of Char;
  jpgChunk:     TJPGChunk;
  jpgHeader:    TJPGHeader;
  iSize:        Integer;
  iRead:        Integer;

begin
  FillChar(cSig, SizeOf(cSig), #0);

  // Read signature
  ASource.Read(cSig, SizeOf(cSig));
  iSize := SizeOf(TJPGChunk);

  repeat
    // Read chunk header
    FillChar(jpgChunk, iSize, #0);
    iRead := ASource.Read(jpgChunk, iSize);

    if iRead <> iSize then
      break;

    if jpgChunk.ID = $C0FF then begin
      ASource.Read(jpgHeader, SizeOf(TJPGHeader));
      AImageInfo.Width  := SwapBytes(jpgHeader.Width);
      AImageInfo.Height := SwapBytes(jpgHeader.Height);
      break;
    end else
      ASource.Position  := ASource.Position + (SwapBytes(jpgChunk.Length) - 2);
  until False;
end;

procedure GetPNGDimensions(const ASource: TStream; var AImageInfo: TX2ImageInfo);
var
  cSig:         array[0..7] of Char;
  cChunkLen:    Cardinal;
  cChunkType:   array[0..3] of Char;
  ihdrData:     TPNGIHDRChunk;

begin
  FillChar(cSig, SizeOf(cSig), #0);
  FillChar(cChunkType, SizeOf(cChunkType), #0);

  // Read signature
  ASource.Read(cSig, SizeOf(cSig));

  // Read IHDR chunk length
  cChunkLen := 0;
  ASource.Read(cChunkLen, SizeOf(Cardinal));
  cChunkLen := SwapBytes(cChunkLen);

  if cChunkLen = SizeOf(TPNGIHDRChunk) then begin
    // Verify IHDR chunk type
    ASource.Read(cChunkType, SizeOf(cChunkType));

    if AnsiUpperCase(cChunkType) = 'IHDR' then begin
      // Read IHDR data
      FillChar(ihdrData, SizeOf(TPNGIHDRChunk), #0);
      ASource.Read(ihdrData, SizeOf(TPNGIHDRChunk));

      AImageInfo.Width  := SwapBytes(ihdrData.Width);
      AImageInfo.Height := SwapBytes(ihdrData.Height);
    end;
  end;
end;


function GetImageInfo(const AFilename: String): TX2ImageInfo;
var
  fsImage:      TFileStream;

begin
  fsImage := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    Result  := GetImageInfo(fsImage);
  finally
    FreeAndNil(fsImage);
  end;
end;


function GetImageInfo(const AStream: TStream): TX2ImageInfo;
var
  iPos:               Integer;
  cBuffer:            array[0..2] of Char;
  cPNGBuffer:         array[0..4] of Char;
  GetDimensionsProc:  TGetDimensionsProc;

begin
  GetDimensionsProc := nil;
  Result.ImgType    := itUnknown;
  Result.Width      := 0;
  Result.Height     := 0;

  FillChar(cBuffer, SizeOf(cBuffer), #0);
  FillChar(cPNGBuffer, SizeOf(cPNGBuffer), #0);

  iPos            := AStream.Position;
  AStream.Read(cBuffer, SizeOf(cBuffer));

  if cBuffer = SIG_GIF then begin
    { GIF }
    Result.ImgType    := itGIF;
    GetDimensionsProc := GetGIFDimensions;
  end else if cBuffer = SIG_JPG then begin
    { JPG }
    Result.ImgType    := itJPG;
    GetDimensionsProc := GetJPGDimensions;
  end else if cBuffer = Copy(SIG_PNG, 1, 3) then begin
    { PNG }
    AStream.Read(cPNGBuffer, SizeOf(cPNGBuffer));

    if cPNGBuffer = Copy(SIG_PNG, 4, 5) then begin
      Result.ImgType    := itPNG;
      GetDimensionsProc := GetPNGDimensions;
    end;
  end else if Copy(cBuffer, 1, 2) = SIG_BMP then begin
    { Bitmap }
    Result.ImgType    := itBMP;
    GetDimensionsProc := GetBMPDimensions;
  end;

  AStream.Position  := iPos;

  if Assigned(GetDimensionsProc) then begin
    GetDimensionsProc(AStream, Result);
    AStream.Position  := iPos;
  end;
end;


function GetImageSize(const AFilename: String): TSize;
begin
  with GetImageInfo(AFilename) do
  begin
    Result.cx := Width;
    Result.cy := Height;
  end;
end;


function GetImageSize(const AStream: TStream): TSize;
begin
  with GetImageInfo(AStream) do
  begin
    Result.cx := Width;
    Result.cy := Height;
  end;
end;


function GetImageType(const AFilename: String): TX2ImageType;
begin
  Result := GetImageInfo(AFilename).ImgType;
end;


function GetImageType(const AStream: TStream): TX2ImageType;
begin
  Result := GetImageInfo(AStream).ImgType;
end;

end.
