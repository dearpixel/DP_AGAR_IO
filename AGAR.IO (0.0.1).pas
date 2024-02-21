{
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
Uses GraphABC;
var
  Radius := 1000;
type
  Other = record
    OColor := clRandom;
    Name: string;
    X, Y: integer;
    Score := 2;
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
  W := 800;W_ := W div 2;
  H := 600;H_ := H div 2;
  
  pW := W div 10;
  pH := H div 10;
  PlayerColor := RGB(64,255,64);
  X, Y: integer;
  Name: string;
  Score := 0;
  Enemy: array of Other;
  Eat: array of Point;NE := 64;
procedure Init;
begin
  SetWindowSize(W,H);
  SetWindowTitle('BLOCK.IO');
  CenterWindow;
  LockDrawing;
  Pen.Width := 2;
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
  for i: integer := 0 to 19 do
  begin
    Line(0,-(H div 2) + i*pH+(Y mod pH),W,i*pH+(Y mod pH));
    Line(-(H div 2) + i*pH+(X mod pH),0,i*pH+(X mod pH),H);
  end;
end;
procedure DrawAgar(X_,Y_,Scr: integer; Clr: Color; Nme: string);
begin
  Brush.Color := Clr;
  FillRect(W_+X_-X-Scr*4,H_+Y_-Y-Scr*4,W_+X_-X+Scr*4,H_+Y_-Y+Scr*4);
  Font.Size := 8;
  DrawTextCentered(W_+X_-X-Scr*16,H_+Y_-Y-Scr*4,W_+X_-X+Scr*16,H_+Y_-Y+Scr*4,Nme);
end;
procedure DrawMinimap;
begin
  Brush.Color := RGB(128,128,128);
  Rectangle(W-128,H-128,W,H);
  
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
    Circle(Eat[i].X,Eat[i].Y,4);
end;
procedure Render;
begin
  ClearWindow(RGB(222,222,222));
  //DrawField;
  DrawOther;
  DrawAgar(X,Y,Score,PlayerColor,Name);
  DrawEat;
  DrawMinimap;
  LeaderBoard;
  Redraw;
end;
procedure Update;
begin
  X += 1;
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