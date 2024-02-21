{
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
    + исправить список лидеров
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
    - отрисовка только тех агаров, что в поле зрения... давно надо было сообразить...
    + отображать счёт больших агаров
    + отображать на карте ТОПов
    + отображать позицию игрока
    + эффект при получении очков
    + исправить интеллект ботов
    - убрать границы, зациклить пространство
    - если ник не влезает писать ...
    - писать ник с начала строки, а не по центру
    + увеличить скорость перемещения
    - добавить механики атаки/побега для ботов
    - добавить ускорение
    - добавить выделение в списке топов по цвету
    + добавить дополнительное выделение на миникарте для игрока
    - сделать поиск свободной позиции при спавне
    + Circle заменён на FillCircle
    - исключить серые цвета, чтобы агары не сливались с фоном
    - Сделать отдельную реализацию с генетическим алгоритмом
    - Сделать отдельную реализацию с нейросетью
    - Более умный генератор имени
    - Постоянное уменьшение здоровья
    - Более контрастные цвета
    - убрать дребезжания при попадании на указатель мыши
    - добавить обзор агарам, чтобы они не случайно выбирали цель
    - Стены и дома
    - оружие:
      - оружие можно подобрать на карте (в дальнейшем, на карте будут сундуки с оружием, аптечками, бронёй и т.д.)
      - оружие есть только у игрока, для теста
      - оружие может стрелять
      - патроны бесконечные, для теста
      - патроны валяются на карте
}
Uses GraphABC, Control;

var
  Radius := 2000;
  Agar_Count := 100; // Минимум - 10
  Agar_Speed := 3.0;
  Eat_Count := 1000;

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
    EffTime: integer;
    EffDir := 0;
    EffScore := 0;
    
    Weapon := false;
    
    Bullet := 10000;
    constructor Create;
    begin
      Name += CHR(97 + Random(26));
      while Random(3) > 0 do
        Name += CHR(97 + Random(26));
      X := Random(-Radius + Score * 2, Radius - Score * 2);
      Y := Random(-Radius + Score * 2, Radius - Score * 2);
      Score := 16;
    end;
  end;
  Bullt = record
    X, Y, dX, dY: double;
  end;

var
  W := ScreenWidth div 2 - 16;
  W_ := W div 2;
  H := 500;
  H_ := H div 2;
  
  pWH := 32;
  CamX, CamY: integer;
  Agar: array of Agr;
  Eat: array of Point;
  TOP: array of integer; //ID
  
  FPS := 0;
  tempFPS := 0;
  LastTime := 1000;
  
  FrameTime: integer;
  
  Bullets: array of Bullt;
  //Time := 15*60*1000;
function Len2D(x1, y1, x2, y2: double) := Sqrt(Sqr(x2 - x1) + Sqr(y2 - y1));

function Ang(x0, y0, x1, y1: double): double;
begin
  var r := sqrt(sqr(x1 - x0) + sqr(y1 - y0));
  if r <> 0 then result := Arccos((x1 - x0) / r) * 180 / pi else result := 0;
  if (y0 - y1) <= 0 then result := 360 - result; result := 360 - result;{инверсия}
end;

procedure SpawnEat(i: integer) :=
  Eat[i] := new Point(pWH * (Random(-Radius, Radius) div pWH),
                      pWH * (Random(-Radius, Radius) div pWH));

procedure Init;
begin
  SetWindowSize(W, H);
  SetWindowTitle('Agar.io');
  CenterWindow;
  //Window.Left := 0;
  LockDrawing;
  SetLength(Agar, Agar_Count);
  for i: integer := 0 to Agar.Length - 1 do
    Agar[i] := Agr.Create;
  
  SetLength(Eat, Eat_Count);
  for i: integer := 0 to Eat_Count - 1 do
    SpawnEat(i);
  Agar[0].Name := 'Agar';
  Agar[0].X := 0;
  Agar[0].Y := 0;
  Agar[0].Score := 16;
  Agar[0].OColor := RGB(64, 255, 64);
  
  SetLength(TOP, Agar.Length); for i: integer := 0 to Agar.Length - 1 do TOP[i] := i;
end;
///LenFromScore
function LFS(Scr: integer): integer;
var
  L := 4;
  tmp := 1.0;
begin
  while tmp < Scr do
  begin
    tmp *= 2;
    L += 1;
  end;
  Result := L;
  Result *= 2;
end;

procedure DrawField;
begin
  Pen.Color := RGB(192, 192, 192);
  for i: integer := 0 to W div pWH+1 do
    Line(i * pWH - ((CamX-13) mod pWH), 0, i * pWH - ((CamX-13) mod pWH), H);
  for i: integer := 0 to H div pWH+1 do
    Line(0, i * pWH - ((CamY-26) mod pWH), W, i * pWH - ((CamY-26) mod pWH));
  Pen.Color := clBlack;
end;

procedure DrawAgar(i: integer);//X_,Y_,Scr: integer; Clr: Color; Nme: string);
begin
  Brush.Color := Agar[i].OColor;
  FillCircle(W_ + Agar[i].X.Round - CamX, H_ + Agar[i].Y.Round - CamY, LFS(Agar[i].Score) + 4);
  Font.Size := 8;
  DrawTextCentered(W_ + Agar[i].X.Round - CamX - (Agar[i].Score + 1) * 16, H_ + Agar[i].Y.Round - CamY - (Agar[i].Score + 1) * 4, W_ + Agar[i].X.Round - CamX + (Agar[i].Score + 1) * 16, H_ + Agar[i].Y.Round - CamY + (Agar[i].Score + 1) * 4, Agar[i].Name);
  if Agar[i].Score > 128 then DrawTextCentered(W_ + Agar[i].X.Round - CamX - (Agar[i].Score + 1) * 16, 16 + H_ + Agar[i].Y.Round - CamY - (Agar[i].Score + 1) * 4, W_ + Agar[i].X.Round - CamX + (Agar[i].Score + 1) * 16, 16 + H_ + Agar[i].Y.Round - CamY + (Agar[i].Score + 1) * 4, IntToStr(Agar[i].Score));
  if Agar[i].EffTime > 0 then
  begin
    Agar[i].EffTime -= FrameTime;
    if Agar[i].EffTime > 150 then
      Brush.Color := ARGB(255, 255, 255, 255) else
    if Agar[i].EffTime > 100 then
      Brush.Color := ARGB(192, 200, 200, 200) else
    if Agar[i].EffTime > 50 then
      Brush.Color := ARGB(192, 155, 155, 155) else
      Brush.Color := ARGB(192, 64, 64, 64);
    FillRoundRect(W_ + Round(Agar[i].X.Round - CamX + Cos(DegToRad(Agar[i].EffDir)) * (LFS(Agar[i].Score) + 4)) - TextWidth(IntToStr(Agar[i].EffScore)) div 2,
                  H_ + Round(Agar[i].Y.Round - CamY + Sin(DegToRad(Agar[i].EffDir)) * (LFS(Agar[i].Score) + 4)) - TextHeight(IntToStr(Agar[i].EffScore)) div 2,
                  W_ + Round(Agar[i].X.Round - CamX + Cos(DegToRad(Agar[i].EffDir)) * (LFS(Agar[i].Score) + 4)) + TextWidth(IntToStr(Agar[i].EffScore)) div 2,
                  H_ + Round(Agar[i].Y.Round - CamY + Sin(DegToRad(Agar[i].EffDir)) * (LFS(Agar[i].Score) + 4)) + TextHeight(IntToStr(Agar[i].EffScore)) div 2, 4, 4);
    DrawTextCentered(W_ + Round(Agar[i].X.Round - CamX + Cos(DegToRad(Agar[i].EffDir)) * (LFS(Agar[i].Score) + 4)) - 64,
                     H_ + Round(Agar[i].Y.Round - CamY + Sin(DegToRad(Agar[i].EffDir)) * (LFS(Agar[i].Score) + 4)) - 16,
                     W_ + Round(Agar[i].X.Round - CamX + Cos(DegToRad(Agar[i].EffDir)) * (LFS(Agar[i].Score) + 4)) + 64,
                     H_ + Round(Agar[i].Y.Round - CamY + Sin(DegToRad(Agar[i].EffDir)) * (LFS(Agar[i].Score) + 4)) + 16, IntToStr(Agar[i].EffScore));
  end;
end;

procedure DrawMinimap;
begin
  Brush.Color := ARGB(32, 255, 255, 255);
  Rectangle(W - 128, H - 128, W, H);
  Brush.Color := ARGB(200, 0, 0, 0);
  FillCircle(W - 64 + Round(64 / Radius * Agar[0].X),
            H - 64 + Round(64 / Radius * Agar[0].Y), 4);
  for i: integer := 1 to Agar.Length - 1 do
  begin
    Brush.Color := ARGB(128, Agar[i].OColor.R, Agar[i].OColor.G, Agar[i].OColor.B);
    FillCircle(W - 64 + Round(64 / Radius * Agar[i].X), H - 64 + Round(64 / Radius * Agar[i].Y), 2);
  end;
  for i: integer := 0 to 9 do
    DrawCircle(W - 64 + Round(64 / Radius * Agar[TOP[i]].X), H - 64 + Round(64 / Radius * Agar[TOP[i]].Y), 3);
end;

procedure DrawLeaderBoard;
begin
  Brush.Color := ARGB(32, 255, 255, 255);
  Rectangle(W - 128, 0, W, 256);
  //sort
  for i: integer := 0 to Agar.Length - 1 do
    for j: integer := i to Agar.Length - 1 do
      if Agar[TOP[j]].Score > Agar[TOP[i]].Score then Swap(TOP[i], TOP[j]);
  Font.Size := 12;
  for i: integer := 0 to 9 do
  begin
    DrawTextCentered(W - 128, i * 25, W - 64, i * 25 + 25, Agar[TOP[i]].Name);
    DrawTextCentered(W - 64, i * 25, W, i * 25 + 25, IntToStr(Agar[TOP[i]].Score));
  end;
  var Avg: double;
  for i: integer := 0 to Agar.Length - 1 do
    Avg += Agar[i].Score;
  Brush.Color := ARGB(128, 255, 255, 255);
  Rectangle(W - 128, 256, W, 288);
  DrawTextCentered(W - 128, 256, W, 288, IntToStr(Avg.Round));
end;

// FIX IT!!!
function inScene(x, y: real): boolean;
begin
  if (x > CamX)
  and (x < CamX + WindowWidth)
  and (y > CamY)
  and (y > CamY + WindowHeight) then
    result := true
  else
    result := false;
end;

procedure DrawAgars;
begin
  for i: integer := 0 to Agar.Length - 1 do
    DrawAgar(i);
end;

procedure DrawEat;
begin
  Brush.Color := clGreen;
  for i: integer := 0 to Eat_Count - 1 do
    FillCircle(W_ + Eat[i].X - CamX, H_ + Eat[i].Y - CamY, 4);
end;

procedure DrawScore;
begin
  Brush.Color := ARGB(32, 128, 128, 128);
  Rectangle(0, H - 64, 128, H);
  Font.Size := 24;
  DrawTextCentered(0, H - 64, 128, H, IntToStr(Agar[0].Score));
  Font.Size := 10;
  var i: integer;
  while TOP[i] <> 0 do i += 1;
  DrawTextCentered(0, H - 32, 128, H, 'Позиция: ' + IntToStr(i + 1));
  Font.Size := 8;
end;

procedure Render;
begin
  ClearWindow(RGB(222, 222, 222));
  //DrawField;
  DrawAgars;
  DrawScore;
  DrawEat;
  DrawMinimap;
  DrawLeaderBoard;
  DrawTextCentered(-20, 0, 180, 40, 'FPS: ' + IntToStr(FPS) + newline +
                                  'X: ' + IntToStr(Agar[0].X.Floor) + ', Y: ' +
                                  IntToStr(Agar[0].Y.Floor)); tempFPS += 1;
  Redraw;
end;

procedure MoveBot(i: integer);
begin
  Agar[i].X += Agar[i].dX * Agar_Speed;
  Agar[i].Y += Agar[i].dY * Agar_Speed;
  
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
  if not Agar[i].Selected then
  begin
    Agar[i].AimID := 0;
    case Random(2) of
      0:
        for j: integer := 0 to Eat_Count - 1 do
          if Len2D(Agar[i].X, Agar[i].Y, Eat[j].X, Eat[j].Y) < Len2D(Agar[i].X, Agar[i].Y, Eat[Agar[i].AimID].X, Eat[Agar[i].AimID].Y) then
          begin
            Agar[i].Aim := 0;
            Agar[i].AimID := j;
            Agar[i].Selected := true;
          end;
      1:
        for j: integer := 0 to Agar.Length - 1 do
          if i <> j then
            if (Len2D(Agar[i].X, Agar[i].Y, Agar[j].X, Agar[j].Y) < Len2D(Agar[i].X, Agar[i].Y, Agar[Agar[i].AimID].X, Agar[Agar[i].AimID].Y)) and
                           (Agar[i].Score * 0.8 > Agar[j].Score) and
               (Agar[j].Score > 0) then
            begin
              Agar[i].Aim := 1;
              Agar[i].AimID := j;
              Agar[i].Selected := true;
            end;
    {if not Agar[i].Selected then
    for j: integer := 0 to Agar.Length-1 do
    if i <> j then
    if (Len2D(Agar[i].X,Agar[i].Y,Agar[j].X,Agar[j].Y) < W) and (Agar[j].Score * 0.8 > Agar[i].Score) then
    begin
      Agar[i].Aim := 2;
      Agar[i].AimID := j;
      Agar[i].Selected := true;
    end;}
    end;
  end;
end;

procedure MoveBots;
begin
  for i: integer := 1 to Agar.Length - 1 do
  begin
    NewAim(i);
    //check aim
    case Agar[i].Aim of
      //  0: if Len2D(Agar[i].X,Agar[i].X, Eat[Agar[i].AimID].X, Eat[Agar[i].AimID].Y) > W then Agar[i].Selected := false;
      1: if Agar[i].Score * 0.8 < Agar[Agar[i].AimID].Score then Agar[i].Selected := false;//if Len2D(Agar[i].X,Agar[i].X,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y) > W then Agar[i].Selected := false;
    //  2: if Len2D(Agar[i].X,Agar[i].X,Agar[Agar[i].AimID].X,Agar[Agar[i].AimID].Y) > W then Agar[i].Selected := false;
    end;
    NewAim(i);
    //moving for aim
    if Agar[i].Selected then
      case Agar[i].Aim of
        0:
          begin
            Agar[i].dX := Cos(DegToRad(Ang(Agar[i].X, Agar[i].Y, Eat[Agar[i].AimID].X, Eat[Agar[i].AimID].Y))) * 4;
            Agar[i].dY := Sin(DegToRad(Ang(Agar[i].X, Agar[i].Y, Eat[Agar[i].AimID].X, Eat[Agar[i].AimID].Y))) * 4;
            if Len2D(Agar[i].X, Agar[i].Y, Eat[Agar[i].AimID].X, Eat[Agar[i].AimID].Y) < LFS(Agar[i].Score) + 4 then
            begin
              Agar[i].Score += 2;
              SpawnEat(i);
              Agar[i].Selected := false;
              NewAim(i);
            end;
          end;
        1:
          begin
            Agar[i].dX := Cos(DegToRad(Ang(Agar[i].X, Agar[i].Y, Agar[Agar[i].AimID].X, Agar[Agar[i].AimID].Y))) * 4;
            Agar[i].dY := Sin(DegToRad(Ang(Agar[i].X, Agar[i].Y, Agar[Agar[i].AimID].X, Agar[Agar[i].AimID].Y))) * 4;
            if Len2D(Agar[i].X, Agar[i].Y, Agar[Agar[i].AimID].X, Agar[Agar[i].AimID].Y) < LFS(Agar[i].Score) + LFS(Agar[Agar[i].AimID].Score) then
              if Agar[i].Score * 0.8 > Agar[Agar[i].AimID].Score then
              begin
                Agar[i].Score += Round(Agar[Agar[i].AimID].Score * 0.8);
                Agar[i].EffScore := Round(Agar[Agar[i].AimID].Score * 0.8);
                Agar[i].EffTime := 200;
                Agar[i].EffDir := Round(Ang(Agar[i].X, Agar[i].Y, Agar[Agar[i].AimID].X, Agar[Agar[i].AimID].Y));
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
    for j: integer := 0 to Eat_Count - 1 do
    begin
      if Len2D(Agar[i].X, Agar[i].Y, Eat[j].X, Eat[j].Y) < LFS(Agar[i].Score) + 4 then
      begin
        Agar[i].Score += 2;
        Agar[i].EffTime := 200;
        Agar[i].EffDir := Round(Ang(Agar[i].X, Agar[i].Y, Eat[j].X, Eat[j].Y));
        Agar[i].EffScore := 2;
        SpawnEat(j);
      end else
      if Len2D(Agar[i].X, Agar[i].Y, Eat[j].X, Eat[j].Y) < LFS(Agar[i].Score) + 16 then
      begin
        var dir := Ang(Agar[i].X, Agar[i].Y, Eat[j].X, Eat[j].Y);
        SpawnEat(j);
      end;
    end;
  end;
end;

procedure Collision;
begin
  for i: integer := 0 to Agar.Length - 1 do
    for j: integer := 0 to Agar.Length - 1 do
      if i <> j then
        if Len2D(Agar[i].X, Agar[i].Y, Agar[j].X, Agar[j].Y) < LFS(Agar[i].Score) + LFS(Agar[j].Score) + 8 then
        begin
          if Agar[i].Score * 0.8 > Agar[j].Score then
          begin
            Agar[i].Score += Round(Agar[j].Score * 0.8);
            Agar[i].EffScore := Round(Agar[j].Score * 0.8);
            Agar[i].EffTime := 200;
            Agar[i].EffDir := Round(Ang(Agar[i].X, Agar[i].Y, Agar[j].X, Agar[j].Y));
            Agar[j] := Agr.Create;
            if j = 0 then
            begin
              Agar[0].Name := 'Agar';
              Agar[0].OColor := clGreen;
              if Agar[0].X < -Radius + W_ then CamX := -Radius + W_;
              if Agar[0].X > Radius - W_ then CamX := Radius - W_;
              if Agar[0].Y < -Radius + H_ then CamY := -Radius + H_;
              if Agar[0].Y > Radius - H_ then CamY := Radius - H_;
            end;
          end;
        end;
end;

procedure Update;
begin
  FrameTime := MillisecondsDelta;
  if LastTime > 0 then LastTime -= FrameTime else
  begin
    FPS := tempFPS;
    tempFPS := 0;
    LastTime := 1000;
  end;
  if KeyCode = VK_R then Init;
  MoveBots;
  Collision;
  if MousePressed then
  begin
    //if inScene(MouseX + CamX, MouseY + CamY) then
    //  Halt;
    var dir := Ang(W_ + Agar[0].X - CamX, H_ + Agar[0].Y - CamY, MouseX, MouseY);
    Agar[0].X += Cos(DegToRad(dir)) * 4 * Agar_Speed;
    Agar[0].Y += Sin(DegToRad(dir)) * 4 * Agar_Speed;
  end;
  if Agar[0].X < -Radius then Agar[0].X := -Radius;
  if Agar[0].X > Radius then Agar[0].X := Radius;
  if Agar[0].Y < -Radius then Agar[0].Y := -Radius;
  if Agar[0].Y > Radius then Agar[0].Y := Radius;
  if (Agar[0].X - W_ > -Radius) and (Agar[0].X + W_ < Radius) then CamX := Agar[0].X.Round;
  if (Agar[0].Y - H_ > -Radius) and (Agar[0].Y + H_ < Radius) then CamY := Agar[0].Y.Round;
  //Eat
  for i: integer := 0 to Eat_Count - 1 do
  begin
    if Len2D(Agar[0].X, Agar[0].Y, Eat[i].X, Eat[i].Y) < LFS(Agar[0].Score) + 4 then
    begin
      Agar[0].Score += 2;
      Agar[0].EffTime := 200;
      Agar[0].EffDir := Round(Ang(Agar[0].X, Agar[0].Y, Eat[i].X, Eat[i].Y));
      Agar[0].EffScore := 2;
      SpawnEat(i);
    end else
    if Len2D(Agar[0].X, Agar[0].Y, Eat[i].X, Eat[i].Y) < LFS(Agar[0].Score) + 16 then
    begin
      var dir := Ang(Agar[0].X, Agar[0].Y, Eat[i].X, Eat[i].Y);
      Eat[i] := new Point(Eat[i].X-Round(Cos(DegToRad(dir)))*5,Eat[i].Y-Round(Sin(DegToRad(dir)))*5);
    end;
  end;
end;

begin
  Init;
  while true do
  begin
    Render;
    Update;
  end;
end.