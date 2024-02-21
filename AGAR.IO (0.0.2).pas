﻿{
  Block.io
  TODO:
    - basic map
    - score
    - control
    - map items
    - leaderboard
    - minimap
    - bonuses
}
Uses GraphABC, Control;
var
  Radius := 1000;
type
  Other = record
    OColor := clRandom;
    Name: string;
    X, Y: integer;
    Score := 0;
    Len := 1;
    constructor Create;
    begin
      Name += CHR(97+Random(26));
      while Random(3)>0 do
        Name += CHR(97+Random(26));
      X := Random(-Radius+Score*2,Radius-Score*2);
      Y := Random(-Radius+Score*2,Radius-Score*2);
    end;
  end;
var
  W := 1000;W_ := W div 2;
  H := 500;H_ := H div 2;
  
  pW := W div (W div 16);
  pH := H div (H div 16);
  PlayerColor := RGB(64,255,64);
  X, Y: integer;
  CamX, CamY: integer;
  Name: string;
  Score := 0;
  Enemy: array of Other;
  Eat: array of Point;NE := 64;
function Len2D(x1,y1,x2,y2: double) := Sqrt(Sqr(x2-x1)+Sqr(y2-y1));
function Ang(x0,y0,x1,y1: double): double;
begin
  var r:=sqrt(sqr(x1 - x0) + sqr(y1 - y0));
  if r <> 0 then result:=Arccos((x1 - x0)/r)*180/pi else result:= 0;
  if (y0-y1)<=0 then result:= 360-result;result:=360-result;{инверсия}
end;
procedure Init;
begin
  SetWindowSize(W,H);
  SetWindowTitle('BLOCK.IO');
  CenterWindow;
  LockDrawing;
  //Pen.Width := 2;
  Name := 'Алек';
  
  X := 0;
  Y := 0;
  SetLength(Enemy,32);
  for i: integer := 0 to Enemy.Length-1 do
    Enemy[i] := Other.Create;
    
  SetLength(Eat,NE);
  for i: integer := 0 to NE-1 do
    Eat[i] := new Point(Random(-Radius+2,Radius-2),Random(-Radius+2,Radius-2));
end;
procedure DrawField;
begin
  Pen.Color := RGB(192,192,192);
  for i: integer := 0 to W div pW do
    Line(i*pW-(CamX mod pW),0,i*pW-(CamX mod pW),H);
  for i: integer := 0 to H div pH do
    Line(0,i*pH-(CamY mod pH),W,i*pH-(CamY mod pH));
  Pen.Color := clBlack;
end;
procedure DrawAgar(X_,Y_,Scr: integer; Clr: Color; Nme: string);
begin
  Brush.Color := Clr;
  FillRect(W_+X_-CamX-(Scr+1)*4,H_+Y_-CamY-(Scr+1)*4,W_+X_-CamX+(Scr+1)*4,H_+Y_-CamY+(Scr+1)*4);
  Font.Size := 8;
  DrawTextCentered(W_+X_-CamX-(Scr+1)*16,H_+Y_-CamY-(Scr+1)*4,W_+X_-CamX+(Scr+1)*16,H_+Y_-CamY+(Scr+1)*4,Nme);
end;
procedure DrawMinimap;
begin
  Brush.Color := ARGB(128,128,128,128);
  Rectangle(W-128,H-128,W,H);
  Brush.Color := ARGB(128,64,255,64);
  Circle(W-64+Round(64/Radius*X),H-64+Round(64/Radius*Y),3);
  for i: integer := 0 to NE-1 do
    FillCircle(W-64+Round(64/Radius*Eat[i].X),H-64+Round(64/Radius*Eat[i].Y),1);
  for i: integer := 0 to Enemy.Length-1 do
  begin
    Brush.Color := ARGB(128,Enemy[i].OColor.R,Enemy[i].OColor.G,Enemy[i].OColor.B);
    FillCircle(W-64+Round(64/Radius*Enemy[i].X),H-64+Round(64/Radius*Enemy[i].Y),2);
  end;
end;
procedure LeaderBoard;
var TOP: array[0..9] of integer; //ID
begin
  Brush.Color := ARGB(128,128,128,128);
  Rectangle(W-128,0,W,256);
  for t: integer := 0 to 9 do TOP[t] := 0;
  for i: integer := 0 to Enemy.Length-1 do
    if Enemy[i].Score > Enemy[TOP[0]].Score then TOP[0] := i;
  for t: integer := 1 to 9 do
  for i: integer := 0 to Enemy.Length-1 do
    if (Enemy[i].Score < Enemy[TOP[t-1]].Score) and (Enemy[i].Score >= Enemy[TOP[t]].Score) and (i <> TOP[t]) then TOP[t] := i;
  Font.Size := 16;
  for i: integer := 0 to 9 do
  begin
    DrawTextCentered(W-128,i*25,W-64,i*25+25,Enemy[TOP[i]].Name);
    DrawTextCentered(W-64,i*25,W,i*25+25,IntToStr(Enemy[TOP[i]].Score));
  end;
end;
procedure DrawOther;
begin
  for i: integer := 0 to Enemy.Length-1 do
    DrawAgar(Enemy[i].X,Enemy[i].Y,Enemy[i].Score,Enemy[i].OColor,Enemy[i].Name);
end;
procedure DrawEat;
begin
  Brush.Color := clGreen;
  for i: integer := 0 to NE-1 do
    Circle(W_+Eat[i].X-CamX,H_+Eat[i].Y-CamY,4);
end;
procedure DrawScore;
begin
  Brush.Color := ARGB(128,128,128,128);
  Rectangle(0,H-64,128,H);
  Font.Size := 24;
  DrawTextCentered(0,H-64,128,H,IntToStr(Score));
  Font.Size := 8;
end;
procedure Render;
begin
  ClearWindow(RGB(222,222,222));
  DrawField;
  DrawOther;
  DrawAgar(X,Y,Score,PlayerColor,Name);DrawScore;
  DrawEat;
  DrawMinimap;
  LeaderBoard;
  Redraw;
end;
procedure Update;
begin
  //if UP then Y -= 1;
  //if DOWN then Y += 1;
  //if LEFT then X -= 1;
  //if RIGHT then X += 1;
  if MousePressed then
  begin
    var dir := Ang(W_,H_,MouseX,MouseY);
    X += Round(Cos(DegToRad(dir))*2);
    Y += Round(Sin(DegToRad(dir))*2);
  end;
  if X < -Radius then X := -Radius;
  if X > Radius then X := Radius;
  if Y < -Radius then Y := -Radius;
  if Y > Radius then Y := Radius;
  if (X-W_ > -Radius) and (X+W_ < Radius) then CamX := X;
  if (Y-H_ > -Radius) and (Y+H_ < Radius) then CamY := Y;
  
  for i: integer := 0 to NE-1 do
  begin
    if Len2D(X,Y,Eat[i].X,Eat[i].Y) < Score*4+4 then
    begin
      Score += 2;
      Eat[i] := new Point(Random(-Radius+2,Radius-2),Random(-Radius+2,Radius-2));
    end else
    if Len2D(X,Y,Eat[i].X,Eat[i].Y) < Score*4+16 then
    begin
      var dir := Ang(X,Y,Eat[i].X,Eat[i].Y);
      Eat[i] := new Point(Eat[i].X-Round(Cos(DegToRad(dir))),Eat[i].Y-Round(Sin(DegToRad(dir))));
      
    end;
  end;
  //Enemy[Random(Enemy.Length)].Score := Random(320);
end;
begin
  Init;
  while true do
  begin
    Render;
    Update;
  end;
end.