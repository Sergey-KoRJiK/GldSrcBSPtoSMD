unit UnitTexture;

// Copyright (c) 2020 Sergey Smolovsky, Belarus

interface

uses
  SysUtils,
  Windows,
  Classes,
  UnitVec;

const MAX_TEXTURE_NAME = 16;


type tMipTex = record
    szName: array[0..MAX_TEXTURE_NAME - 1] of Char; // Null-Terminated String
    nWidth, nHeight: Integer;
    nOffsets: array[0..3] of Integer;
  end;
type AMipTex = array of tMipTex;

type tTextureLump = record
    nCountTextures: Integer;
    OffsetsToMipTex: AInt; // Size = nCountTextures
    MipTexInfos: AMipTex; // Size = nCountTextures
  end;

type tTexInfo = record
    vS: tVec3f;
    fSShift: Single;
    vT: tVec3f;
    fTShift: Single;
    iMipTex: Integer;
    nFlags: DWORD; // usually = 0
  end;
type PTexInfo = ^tTexInfo;
type ATexInfo = array of tTexInfo;


function GetCorrectTextureName(const MipTex: tMipTex): String;

function GetTexureCoordS(const lpPoint: PVec3f; const lpTexInfo: PTexInfo): Single;
function GetTexureCoordT(const lpPoint: PVec3f; const lpTexInfo: PTexInfo): Single;


implementation


function GetCorrectTextureName(const MipTex: tMipTex): String;
var
  i, len: Integer;
  tmp: String;
begin
  {$R-}
  len:=0;
  while (len < MAX_TEXTURE_NAME) do
    begin
      if (Byte(MipTex.szName[len]) = 0) then Break;
      Inc(len);
    end;

  SetLength(tmp, len);
  for i:=1 to len do
    begin
      tmp[i]:=MipTex.szName[i - 1];
    end;
    
  Result:=tmp;
  {$R+}
end;


function GetTexureCoordS(const lpPoint: PVec3f; const lpTexInfo: PTexInfo): Single;
asm
  {$R-}
  //Result:=DotVec(lpPoint, @lpTexInfo.vS) + lpTexInfo.fSShift;
  fld tTexInfo[EDX].vS.x
  fmul tVec3f[EAX].x
  fld tTexInfo[EDX].vS.y
  fmul tVec3f[EAX].y
  faddp
  fld tTexInfo[EDX].vS.z
  fmul tVec3f[EAX].z
  faddp
  fadd tTexInfo[EDX].fSShift
  {$R+}
end;

function GetTexureCoordT(const lpPoint: PVec3f; const lpTexInfo: PTexInfo): Single;
asm
  {$R-}
  //Result:=DotVec(lpPoint, @lpTexInfo.vT) + lpTexInfo.fTShift;
  fld tTexInfo[EDX].vT.x
  fmul tVec3f[EAX].x
  fld tTexInfo[EDX].vT.y
  fmul tVec3f[EAX].y
  faddp
  fld tTexInfo[EDX].vT.z
  fmul tVec3f[EAX].z
  faddp
  fadd tTexInfo[EDX].fTShift
  {$R+}
end;

end.
 