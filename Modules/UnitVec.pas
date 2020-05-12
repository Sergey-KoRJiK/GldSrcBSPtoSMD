unit UnitVec;

// Copyright (c) 2020 Sergey Smolovsky, Belarus

interface

uses
  SysUtils,
  Windows,
  Classes;

type AInt = array of Integer;
type AString = array of String;

type tVec2f = record
    x, y: Single;
  end;
type PVec2f = ^tVec2f;
type AVec2f = array of tVec2f;

type tVec3f = record
    x, y, z: Single;
  end;
type PVec3f = ^tVec3f;
type AVec3f = array of tVec3f;

type tVertex = tVec3f;
type AVertex = array of tVertex;


const VEC_ZERO: tVec3f = (x: 0; y: 0; z: 0);

const CR = #13; // = "/r"
const LF = #10; // = "/n"
const SpaceChar: Char = ' ';


procedure SignInvertVec(const lpVec: PVec3f); // Vec:= Vec*(-1)

function FloatToStrFixed(const Value: Single): String;
function Vec2fToStrFixed(const Vec: tVec2f): String;
function Vec3fToStrFixed(const Vec: tVec3f): String;

function StrToVec(const Str: String; const Vec: PVec3f): Boolean;
procedure TranslateVertexArray(const Vertex, lpOffset: PVec3f; const Count: Integer);

function ExtractOrigFileName(const FileName: String): String;


implementation


procedure SignInvertVec(const lpVec: PVec3f);
asm
  {$R-}
  // lpVec.x
  fld dword ptr [lpVec + $00]
  fchs // sign invert
  fstp dword ptr [lpVec + $00]

  // lpVec.y
  fld dword ptr [lpVec + $04]
  fchs // sign invert
  fstp dword ptr [lpVec + $04]
  
  // lpVec.z
  fld dword ptr [lpVec + $08]
  fchs // sign invert
  fstp dword ptr [lpVec + $08]
  {$R+}
end;

function FloatToStrFixed(const Value: Single): String;
var
  tmp: Char;
begin
  {$R-}
  tmp:=DecimalSeparator;
  DecimalSeparator:='.';
  Result:=FloatToStrF(Value, ffGeneral, 12, 6);
  DecimalSeparator:=tmp;
  {$R+}
end;

function Vec2fToStrFixed(const Vec: tVec2f): String;
var
  tmp: Char;
begin
  {$R-}
  tmp:=DecimalSeparator;
  DecimalSeparator:='.';
  Result:=FloatToStrF(Vec.x, ffGeneral, 12, 6) + ' '
    + FloatToStrF(Vec.y, ffGeneral, 12, 6);
  DecimalSeparator:=tmp;
  {$R+}
end;

function Vec3fToStrFixed(const Vec: tVec3f): String;
var
  tmp: Char;
begin
  {$R-}
  tmp:=DecimalSeparator;
  DecimalSeparator:='.';
  Result:=FloatToStrF(Vec.x, ffGeneral, 12, 6) + ' '
    + FloatToStrF(Vec.y, ffGeneral, 12, 6) + ' '
    + FloatToStrF(Vec.z, ffGeneral, 12, 6);
  DecimalSeparator:=tmp;
  {$R+}
end;

function StrToVec(const Str: String; const Vec: PVec3f): Boolean;
var
  n: Integer;
  tmp: TStringList;
begin
  {$R-}
  StrToVec:=False;
  n:=Length(Str);
  if (n < 5) then Exit;

  tmp:=TStringList.Create;
  tmp.Delimiter:=' ';
  tmp.DelimitedText:=Str;
  if (tmp.Count <> 3) then
    begin
      tmp.Clear;
      tmp.Destroy;
      Exit;
    end;

  Vec.x:=StrToFloatDef(tmp.Strings[0], 1/0);
  Vec.y:=StrToFloatDef(tmp.Strings[1], 1/0);
  Vec.z:=StrToFloatDef(tmp.Strings[2], 1/0);

  tmp.Clear;
  tmp.Destroy;
  StrToVec:=True;
  {$R+}
end;

function ExtractOrigFileName(const FileName: String): String;
var
  dotPos, n: Integer;
begin
  {$R-}
  n:=Length(FileName);
  if (n = 0) then Exit;
  dotPos:=n + 1;
  while (dotPos > 2) do
    begin
      Dec(dotPos);
      if (FileName[dotPos] = '.') then Break;
    end;
  if (dotPos > n) then
    begin
      Result:=FileName;
      Exit;
    end
  else
    begin
      Result:=Copy(FileName, 1, dotPos - 1);
    end;
  {$R+}
end;

procedure TranslateVertexArray(const Vertex, lpOffset: PVec3f; const Count: Integer);
asm
  // EAX -> Pointer on Vertex[0] (tVec3f)
  // EDX -> Pointer on tVec3f
  // ECX -> Pointer on Count of Vertex
  {$R-}
  cmp ECX, $00000000
  jle @@BadLen // if array length <= 0 - Exit
  //
  fld tVec3f[EDX].z
  fld tVec3f[EDX].y
  fld tVec3f[EDX].x
  // st0..2 = lpOffset.xyz;
  // Now no need EDX
  xor EDX, EDX // zeros, use it for local offset for Vertex array
@@Looper:
    // Correct X Component
    fld tVec3f[EAX + EDX].x
    fadd st(0), st(1)
    fstp tVec3f[EAX + EDX].x
    // Correct Y Component
    fld tVec3f[EAX + EDX].y
    fadd st(0), st(2)
    fstp tVec3f[EAX + EDX].y
    // Correct Z Component
    fld tVec3f[EAX + EDX].z
    fadd st(0), st(3)
    fstp tVec3f[EAX + EDX].z
    //
    add EDX, 12 // inc EDX by SizeOf(tVec3f)
    dec ECX
    //
    cmp ECX, $00000000
    jg @@Looper
  ////
  // Clear Stack:
  fstp st
  fstp st
  fstp st
  //
@@BadLen:
  {$R+}
end;

end.
