unit UnitMapHeader;

interface

uses
  SysUtils,
  Windows;

const MAP_VERSION =       $0000001E; // 30
const MAP_HEADER_SIZE =   124; // Bytes

const HEADER_LUMPS =      15;

const LUMP_ENTITIES	= 	  0;
const LUMP_PLANES	= 		  1;
const LUMP_TEXTURES =		  2;
const LUMP_VERTICES	= 	  3;
const LUMP_VISIBILITY	=	  4;  // Unused in porgramm
const LUMP_NODES =  			5;  // Unused in porgramm
const LUMP_TEXINFO =  		6;
const LUMP_FACES =  			7;
const LUMP_LIGHTING	=   	8;  // Unused in porgramm
const LUMP_CLIPNODES =  	9;  // Unused in porgramm
const LUMP_LEAVES	=   		10; // Unused in porgramm
const LUMP_MARKSURFACES	= 11; // Unused in porgramm
const LUMP_EDGES =  			12;
const LUMP_SURFEDGES =  	13;
const LUMP_BRUSHES	=   	14;


type tInfoLump = record
    nOffset: Integer;
    nLength: Integer;
  end;

type tMapHeader = record
    nVersion: Integer;
    LumpsInfo: array[0..HEADER_LUMPS - 1] of tInfoLump;
  end;

function GetEOFbyHeader(const Header: tMapHeader): Integer;


implementation


function GetEOFbyHeader(const Header: tMapHeader): Integer;
var
  tmp: Integer;
begin
  {$R-}
  Result:=0;

  tmp:=Header.LumpsInfo[LUMP_ENTITIES].nOffset + Header.LumpsInfo[LUMP_ENTITIES].nLength;
  if (tmp > Result) then Result:=tmp;

  tmp:=Header.LumpsInfo[LUMP_PLANES].nOffset + Header.LumpsInfo[LUMP_PLANES].nLength;
  if (tmp > Result) then Result:=tmp;

  tmp:=Header.LumpsInfo[LUMP_TEXTURES].nOffset + Header.LumpsInfo[LUMP_TEXTURES].nLength;
  if (tmp > Result) then Result:=tmp;

  tmp:=Header.LumpsInfo[LUMP_VERTICES].nOffset + Header.LumpsInfo[LUMP_VERTICES].nLength;
  if (tmp > Result) then Result:=tmp;

  tmp:=Header.LumpsInfo[LUMP_TEXINFO].nOffset + Header.LumpsInfo[LUMP_TEXINFO].nLength;
  if (tmp > Result) then Result:=tmp;

  tmp:=Header.LumpsInfo[LUMP_FACES].nOffset + Header.LumpsInfo[LUMP_FACES].nLength;
  if (tmp > Result) then Result:=tmp;

  tmp:=Header.LumpsInfo[LUMP_EDGES].nOffset + Header.LumpsInfo[LUMP_EDGES].nLength;
  if (tmp > Result) then Result:=tmp;

  tmp:=Header.LumpsInfo[LUMP_SURFEDGES].nOffset + Header.LumpsInfo[LUMP_SURFEDGES].nLength;
  if (tmp > Result) then Result:=tmp;

  tmp:=Header.LumpsInfo[LUMP_BRUSHES].nOffset + Header.LumpsInfo[LUMP_BRUSHES].nLength;
  if (tmp > Result) then Result:=tmp;
  {$R+}
end;

end.
 
