unit UnitFace;

// Copyright (c) 2020 Sergey Smolovsky, Belarus

interface

uses
  SysUtils,
  Windows,
  UnitVec;

type tEdge = record
    v0, v1: Word;
  end;
type AEdge = array of tEdge;

type tSurfEdge = Integer;
type ASurfEdge = array of tSurfEdge;

type tFace = record
    iPlane: Word;
    nPlaneSides: Word;
    iFirstSurfEdge: Integer;
    nSurfEdges: Word;
    iTextureInfo: Word;
    nStyles: array[0..3] of Byte;
    nLightmapOffset: Integer;
  end;
type PFace = ^tFace;
type AFace = array of tFace;

type tFaceInfo = record
    Normal: tVec3f;
    CountVertex: Integer;
    TexNameId: Integer;
    Vertex: AVec3f;
    TexCoords: AVec2f;
  end;
type PFaceInfo = ^tFaceInfo;
type AFaceInfo = array of tFaceInfo;


implementation


end.
