﻿{
  Agar.io
  TODO:
    + basic map
    + score
    + control
    + map items
    + leaderboard
    + minimap
    + Player in basic array
    - bonuses
    - Кусты
    ~ исправить список лидеров
    ~ Прокачать интеллект ботов:
      + Идти за пищей в поле зрения
      + Идти за наибольшим ботом, меньше данного в поле его зрения
      - Убегать от большого бота в поле зрения
    - Разделение
    - экран поражения
    - экран логина
    - поделиться пищей
    + убрать беспредельное расширение
    - исправить баг при спавне на краю карты
    + отрисовка только тех агаров, что в поле зрения... давно надо было сообразить...
}
Uses GraphABC, Control;
var
  Radius := 2000;
type
  Agr = record
    OColor := clRandom;
    Name: string;
    X, Y: double;
    dX, dY: double;
    Score := 0;
    Aim := 0;
    AimID := 0;
    Selected := false;
    constructor Create;
    begin
      Name += CHR(97+Random(26));
      while Random(3)>0 do
        Name += CHR(97+Random(26));
      X := Random(-Radius+Score*2,Radius-Score*2);
      Y := Random(-Radius+Score*2,Radius-Score*2);
      Score := Random(32)*2;
    end;
  end;
var
  W := ScreenWidth div 2-16;W_ := W div 2;
  H := 500;H_ := H div 2;
  
  pW := W div (W div 16);
  pH := H div (H div 16);
  CamX, CamY: integer;
  Agar: array of Agr;
  Eat: array of Point;NE := 256;
  
  //Time := 15*60*1000;
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
  SetWindowTitle('Agar.io');
  CenterWindow;
  Window.Left := 0;
  LockDrawing;
  //Pen.Width := 2;
  SetLength(Agar,512);
  for i: integer := 0 to Agar.Length-1 do
    Agar[i] := Agr.Create;
    
  SetLength(Eat,NE);
  for i: integer := 0 to NE-1 do
    Eat[i] := new Point(Random(-Radius+2,Radius-2),Random(-Radius+2,Radius-2));
  Agar[0].Name := 'Agar';
  Agar[0].X := 0;
  Agar[0].Y := 0;
  Agar[0].Score := 0;
  Agar[0].OColor := RGB(64,255,64);
end;
///LenFromScore
function LFS(Scr: integer): integer;
var L := 1;
    tmp := 1.0;
begin
  while tmp < Scr do
  begin
    tmp *= 1.5;
    L += 1;
  end;
  Result := L;
  Result *= 2;
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
  Circle(W_+X_-CamX,H_+Y_-CamY,LFS(Scr)+4);
  Font.Size := 8;
  DrawTextCentered(W_+X_-CamX-(Scr+1)*16,H_+Y_-CamY-(Scr+1)*4,W_+X_-CamX+(Scr+1)*16,H_+Y_-CamY+(Scr+1)*4,Nme);
end;
procedure DrawMinimap;
begin
  Brush.Color := ARGB(128,255,255,255);
  Rectangle(W-128,H-128,W,H);
  Brush.Color := ARGB(128,64,255,64);
  Circle(W-64+Round(64/Radius*Agar[0].X),H-64+Round(64/Radius*Agar[0].Y),3);
  for i: integer := 0 to NE-1 do
    FillCircle(W-64+Round(64/Radius*Eat[i].X),H-64+Round(64/Radius*Eat[i].Y),1);
  for i: integer := 0 to Agar.Length-1 do
  begin
    Brush.Color := ARGB(128,Agar[i].OColor.R,Agar[i].OColor.G,Agar[i].OColor.B);
    FillCircle(W-64+Round(64/Radius*Agar[i].X),H-64+Round(64/Radius*Agar[i].Y),2);
  end;
end;
procedure LeaderBoard;
var TOP: array[0..9] of integer; //ID
begin
  Brush.Color := ARGB(128,255,255,255);
  Rectangle(W-128,0,W,256);
  for t: integer := 0 to 9 do TOP[t] := Agar.Length-1;
  for i: integer := 0 to Agar.Length-1 do
    if Agar[i].Score > Agar[TOP[0]].Score then TOP[0] := i;
  for t: integer := 1 to 9 do
  for i: integer := 0 to Agar.Length-1 do
  begin
    var Bool := true;
    for k: integer := 0 to t-1 do if i = TOP[k] then Bool := false;
    if Bool then 
    if Agar[i].Score <= Agar[TOP[t-1]].Score then
    if Agar[i].Score > Agar[TOP[t]].Score then TOP[t] := i;
  end;
  Font.Size := 16;
  for i: integer := 0 to 9 do
  begin
    DrawTextCentered(W-128,i*25,W-64,i*25+25,Agar[TOP[i]].Name);
    DrawTextCentered(W-64,i*25,W,i*25+25,IntToStr(Agar[TOP[i]].Score));
  end;
  var Avg: double;
  for i: integer := 0 to Agar.Length-1 do
    Avg += Agar[i].Score;
  Brush.Color := ARGB(128,255,255,255);
  Rectangle(W-128,256,W,310);
  DrawTextCentered(W-128,256,W,288,IntToStr(Avg.Round));
  DrawTextCentered(W-128,288,W,310,IntToStr(Round(Avg / Agar.Length)));
end;
procedure DrawAgars;
begin
  for i: integer := 0 to Agar.Length-1 do
  if (Agar[i].X > Agar[0].X-W) and (Agar[i].Y > Agar[0].Y-H) and (Agar[i].X < Agar[0].X+W) and (Agar[i].Y < Agar[0].Y+H) then
    DrawAgar(Agar[i].X.Round,Agar[i].Y.Round,Agar[i].Score,Agar[i].OColor,Agar[i].Name);
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
  DrawTextCentered(0,H-64,128,H,IntToStr(Agar[0].Score));
  Font.Size := 8;
end;
procedure Render;
begin
  ClearWindow(RGB(222,222,222));
  DrawField;
  DrawAgars;
  DrawScore;
  DrawEat;
  DrawMinimap;
  LeaderBoard;
  //DrawTextCentered(0,0,128,64,IntToStr(Time div 1000));
  Redraw;
end;
procedure MoveBot(i: integer);
begin
  Agar[i].X += Agar[i].dX;
  Agar[i].Y += Agar[i].dY;
  
  Agar[i].dX += Agar[i].dX;
  if ABS(Agar[i].dX) + ABS(Agar[i].dY) > 4 then
    Agar[i].dX -= Agar[i].dX;
  Agar[i].dY += Agar[i].dY;
  if ABS(Agar[i].dX) + ABS(Agar[i].dY) > 4 then
    Agar[i].dY -= Agar[i].dY;
  if (Agar[i].X < -Radius) or (Agar[i].X > Radius) then
  begin
    Agar[i].X -= Agar[i].dX;
    Agar[i].dX := 0;
  end;
  if (Agar[i].Y < -Radius) or (Agar[i].Y > Radius) then
  begin
    Agar[i].Y -= Agar[i].dY;
    Agar[i].dY := 0;
  end;
end;
procedure NewAim(i: integer);
begin
  {if not Agar[i].Selected then
  for j: integer := 0 to Agar.Length-1 do
  if i <> j then
  if (Len2D(Agar[i].X,Agar[i].Y,Agar[j].X,Agar[j].Y) < W) and (Agar[j].Score * 0.8 > Agar[i].Score) then
  begin
    Agar[i].Aim := 2;
    Agar[i].AimID := j;
    Agar[i].Selected := true;
  end;}
  if not Agar[i].Selected then
  for j: integer := 0 to NE-1 do
  if Len2D(Agar[i].X,Agar[i].Y,Eat[j].X,Eat[j].Y) < W then
  begin
    Agar[i].Aim := 0;
    Agar[i].AimID := j;
    Agar[i].Selected := true;
  end;
end;
procedure MoveBots;
begin
  for i: integer := 1 to Agar.Length-1 do
  begin
    NewAim(i);
    //check aim
    case Agar[i].Aim of
      0: if Len2D(Agar[i].X,Agar[i].X, Eat[Agar[i].AimID].X, Eat[Agar[i].AimID].Y) > W then begin Agar[i].Selected := false; NewAim(i); end;
      1: if Len2D(Agar[i].X,Agar[i].X,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y) > W then begin Agar[i].Selected := false; NewAim(i); end;
      2: if Len2D(Agar[i].X,Agar[i].X,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y) > W then begin Agar[i].Selected := false; NewAim(i); end;
    end;
    //moving for aim
    if Agar[i].Selected then
    case Agar[i].Aim of
      0:
      begin
        Agar[i].dX := Cos(DegToRad(Ang(Agar[i].X,Agar[i].Y,Eat[Agar[i].AimID].X,Eat[Agar[i].AimID].Y)))*4;
        Agar[i].dY := Sin(DegToRad(Ang(Agar[i].X,Agar[i].Y,Eat[Agar[i].AimID].X,Eat[Agar[i].AimID].Y)))*4;
        if Len2D(Agar[i].X,Agar[i].Y,Eat[Agar[i].AimID].X,Eat[Agar[i].AimID].Y) < LFS(Agar[i].Score) + 4 then
        begin
          Agar[i].Score += 2;
          Eat[Agar[i].AimID] := new Point(Random(-Radius+2,Radius-2),Random(-Radius+2,Radius-2));
          Agar[i].Selected := false;
          NewAim(i);
        end;
      end;
      1:
      begin
        Agar[i].dX := Cos(DegToRad(Ang(Agar[i].X,Agar[i].Y,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y)))*4;
        Agar[i].dY := Sin(DegToRad(Ang(Agar[i].X,Agar[i].Y,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y)))*4;
        if Len2D(Agar[i].X,Agar[i].Y,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y) < LFS(Agar[i].Score) + LFS(Agar[Agar[i].AimID].Score) then
        if Agar[i].Score * 0.8 > Agar[Agar[i].AimID].Score then
        begin
          Agar[i].Score += Round(Agar[Agar[i].AimID].Score * 0.8);
          Agar[Agar[i].AimID] := Agr.Create;
          Agar[i].Selected := false;
          NewAim(i);
        end;
      end;
      {2:
      begin
        Agar[i].dX := -Cos(DegToRad(Ang(Agar[i].X,Agar[i].Y,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y)))*4;
        Agar[i].dY := -Sin(DegToRad(Ang(Agar[i].X,Agar[i].Y,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y)))*4;
        if Len2D(Agar[i].X,Agar[i].Y,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y) > W then
        if Agar[i].Score * 0.8 > Agar[Agar[i].AimID].Score then
        begin
          Agar[i].Selected := false;
          NewAim(i);
        end;
      end;}
    end;
    if not Agar[i].Selected then
    begin
      Agar[i].dX := 0;
      Agar[i].dY := 0;
    end;
    MoveBot(i);
    //Eat
    for j: integer := 0 to NE-1 do
    begin
      if Len2D(Agar[i].X,Agar[i].Y,Eat[j].X,Eat[j].Y) < LFS(Agar[i].Score)+4 then
      begin
        Agar[i].Score += 2;
        Eat[j] := new Point(Random(-Radius+2,Radius-2),Random(-Radius+2,Radius-2));
      end else
      if Len2D(Agar[i].X,Agar[i].Y,Eat[j].X,Eat[j].Y) < LFS(Agar[i].Score)+16 then
      begin
        var dir := Ang(Agar[i].X,Agar[i].Y,Eat[j].X,Eat[j].Y);
        Eat[j] := new Point(Eat[j].X-Round(Cos(DegToRad(dir)))*5,Eat[j].Y-Round(Sin(DegToRad(dir)))*5);
      end;
    end;
  end;
end;
procedure Collision;
begin
  for i: integer := 0 to Agar.Length-1 do
  for j: integer := 0 to Agar.Length-1 do
  if i <> j then
  if Len2D(Agar[i].X,Agar[i].Y,Agar[j].X,Agar[j].Y) < LFS(Agar[i].Score) + LFS(Agar[j].Score) + 8 then
  begin
    if Agar[i].Score * 0.8 > Agar[j].Score then
    begin
      Agar[i].Score += Round(Agar[j].Score * 0.8);
      Agar[j] := Agr.Create;
    end;
  end;
end;
procedure Update;
begin
  if KeyCode = VK_R then Init;
  MoveBots;
  Collision;
  if MousePressed then
  begin
    var dir := Ang(W_+Agar[0].X-CamX,H_+Agar[0].Y-CamY,MouseX,MouseY);
    Agar[0].X += Cos(DegToRad(dir))*4;
    Agar[0].Y += Sin(DegToRad(dir))*4;
  end;
  if Agar[0].X < -Radius then Agar[0].X := -Radius;
  if Agar[0].X > Radius then Agar[0].X := Radius;
  if Agar[0].Y < -Radius then Agar[0].Y := -Radius;
  if Agar[0].Y > Radius then Agar[0].Y := Radius;
  if (Agar[0].X-W_ > -Radius) and (Agar[0].X+W_ < Radius) then CamX := Agar[0].X.Round;
  if (Agar[0].Y-H_ > -Radius) and (Agar[0].Y+H_ < Radius) then CamY := Agar[0].Y.Round;
  //Eat
  for i: integer := 0 to NE-1 do
  begin
    if Len2D(Agar[0].X,Agar[0].Y,Eat[i].X,Eat[i].Y) < LFS(Agar[0].Score)+4 then
    begin
      Agar[0].Score += 2;
      Eat[i] := new Point(Random(-Radius+2,Radius-2),Random(-Radius+2,Radius-2));
    end else
    if Len2D(Agar[0].X,Agar[0].Y,Eat[i].X,Eat[i].Y) < LFS(Agar[0].Score)+16 then
    begin
      var dir := Ang(Agar[0].X,Agar[0].Y,Eat[i].X,Eat[i].Y);
      Eat[i] := new Point(Eat[i].X-Round(Cos(DegToRad(dir)))*5,Eat[i].Y-Round(Sin(DegToRad(dir)))*5);
    end;
  end;
  //Agar[Random(Agar.Length)].Score := Random(320);
end;
begin
  Init;
  while true do//(Time > 0) and (Agar[0].Score < 5000) do
  begin
    Render;
    Update;
    Time -= MillisecondsDelta;
  end;
  Halt;
end.