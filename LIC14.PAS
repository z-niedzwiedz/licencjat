
{$X+,F+,R+,N+,E+}
program Lic14;
{Praca licencjacka dla WSRP Siedlce}
{Zbigniew Niedzwiedz}
{promotor: dr Wojciech Penczek}

uses StdDlgPl, ValidPl, GSOBShel, GSOB_Str, Gadgets4, MsgBoxPl, Editors,
     Crt, Dos, Memory, Objects, Drivers, Views, Menus, Dialogs, App, TVPL,
     InpLong, Kalk, ScrSav, ViewText, Printer;

type
  PWord = ^Word;
  PInt = ^Integer;

  FunctionB = function: boolean;

  {Potomek TSortedCollection dla danych typu Word}
  TWordCollection = object(TSortedCollection)
    function Compare(Key1, Key2 : Pointer) : Integer; virtual;
  end;

  {Potomek TSortedCollection dla danych typu Int}
  TIntCollection = object(TSortedCollection)
    function Compare(Key1, Key2 : Pointer) : Integer; virtual;
  end;

  {slownik nazw element¢w sieci}
  PSlownik = ^TSlownik;
  TSlownik = object(TSortedCollection)
    function Compare(Key1, Key2 : Pointer) : Integer; virtual;
    function SwapParts(PS: PString): String;
  end;

  {pojedyncza konfiguracja}
  PKonf1 = ^TKonf1;
  TKonf1 = object(TIntCollection)
  end;

  {kolekcja konfiguracji}
  PKonfig = ^TKonfig;
  TKonfig = object(TCollection)
  end;

  {pojedyncze zdarzenie}
  PZdarz1 = ^TZdarz1; {Akcja}
  TZdarz1 = object(TObject)
    Opis: Integer; {pozycja w Slowniku}
    Pre, Post: PKonf1;
    constructor Init(IndOp: Integer);
  end;

  PZdarzenia = ^TZdarzenia; {Zbior akcji}
  TZdarzenia = object(TSortedCollection)
    function Compare(Key1, Key2 : Pointer) : Integer; virtual;
    constructor Init(ALimit, ADelta: Integer);
    function Niezalezne(Ind1, Ind2: Integer): Boolean;
    function InnyProces(Ind1, Ind2: Integer): Boolean;
    function WKonflikcie(Ind1, Ind2: Integer): Boolean;
    function Ostatnie(Ind: Integer): Boolean;
  end;

  {elementy procesu}
  PActions = ^TActions;
  TActions = object(TIntCollection)
  end;

  {pojedynczy proces}
  PProc1 = ^TProc1; {Akcja}
  TProc1 = object(TObject)
    Opis: Integer; {pozycja w Slowniku}
    Actions: PActions;
    constructor Init(IndOp: Integer);
  end;

  PProcesy = ^TProcesy; {Zbior akcji}
  TProcesy = object(TSortedCollection)
    function Compare(Key1, Key2 : Pointer) : Integer; virtual;
    constructor Init(ALimit, ADelta: Integer);
  end;

  {Zdarzenie umozliwione:
   pre <= konf
   post * konf = []

   Nastepna konfiguracja:
   konf ---> konf1
   konf1 = (konf - pre) + post     }

  {Lista wezl¢w}
  PWezly = ^TWezly;
  TWezly = object(TIntCollection)
  end;

  {Element grafu konfiguracji}
  PWezel = ^TWezel;
  TWezel = object(TObject)
    Przeszukany: Boolean;
    Konf: PKonf1;
    Umozliwione, Slad: PWezly;
    OstPierwotny, OstWezel: Integer;
    constructor Init;
    procedure WyliczZdarzUm(R: Boolean);
  end;

  {Graf konfiguracji}
  PGrafKonf = ^TGrafKonf;
  TGrafKonf = object(TCollection)
    Redukcja: Boolean;
    IleTran: Longint;
    constructor Init(ALimit, ADelta: Integer; R: Boolean);
    procedure Buduj(NumerWezla: Integer);
  end;

  TMyApp = object(TAppPl)
    {gadgety}
    Clock: PClockView;         {aktualna data/czas}
    Star: PStarView;           {bajerek w prawym dolnym rogu ekranu}
    Heap: PHeapView;           {wskaznik wielkosci sterty}
    ScreenSaver: PScreenSaver; {wygaszacz ekranu}
    Calculator: PCalculator;   {kalkulator}
    TextWindow : PTextWindow;  {przegladarka pliku tekstowego}
    procedure SSav;            {wygaszacz ekranu - konfiguracja}
    {system}
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure GetEvent(var E:TEvent); virtual;
    procedure Idle; virtual;
    procedure Idle2;
    constructor Init;
    procedure HandleEvent(var Event: TEvent); virtual;
    {meritum}
    procedure GBR;            {Generowanie bez redukcji}
    procedure GDESL;          {Generowanie z redukcja dla DESL}
    procedure GRId;           {Redukcja idealna}
    procedure Future;         {Komunikat, ze funkcja na razie niedostepna}
    procedure About;          {okno informacji}
    procedure OpenData(FileName: FNameStr); {wczytanie sieci}
    procedure EditData;       {edycja sieci}
    procedure PrData;         {drukowanie sieci do pliku nazwa_pliku.out}
    procedure PrSSpace;       {druk. grafu konf. do pliku nazwa_pliku.ssp}
    procedure Restart;        {Restart programu}
  end;

var
  MyApp: TMyApp;
  TheEnd: Boolean;
  {glowne obiekty}
  NetFileName: FNameStr;     {nazwa pliku sieci}
  NetName: String;           {nazwa sieci}
  NetTimes: Word;            {krotnosc sieci}
  Slownik: PSlownik;         {slownik nazw elementow sieci}
  Konfig: PKonfig;           {kolekcja konfiguracji}
  Zdarz: PZdarzenia;         {kolekcja zdarzen}
  Proc: PProcesy;            {kolekcja procesow}
  GrafK: PGrafKonf;          {graf konfiguracji}

const
  Wersja     = ' Wersja 0.14·';

  cmAbout    = 151; {Informacja o programie}
  cmFOpen    = 152; {Wyb¢r pliku danych}
  cmPrData   = 153; {Drukowanie danych}
  cmSSav     = 154; {Screen Saver}
  cmGBR      = 155; {Generowanie bez redukcji}
  cmPrSSpace = 156; {Drukowanie przestrzeni stan¢w}
  cmGDESL    = 157; {Generowanie z redukcja dla DESL}
  cmEditData = 158; {Edycja danych}
  cmRestart  = 159; {Restart programu}
  cmGRId     = 160; {Restart programu}
  cmFu       = 179; {Future version}
  cmFPrint   = 161; {Drukowanie pliku}

  HeapSize = 256 * (1024 div 16);

{$I L-SS.src} {okienko konfiguracji wygaszacza ekranu}
{$I L-AB.src} {okienko informacji}

{Implementacja funkcji Compare dla TWordCollection}
function TWordCollection.Compare(Key1, Key2 : Pointer) : Integer;
begin
  if PWord(Key1)^ < PWord(Key2)^ then Compare := -1
    else if PWord(Key1)^ > PWord(Key2)^ then Compare := 1
      else Compare := 0;
end;

function TSlownik.SwapParts(PS: PString): String;
var
  S: String;
  k: Byte;
begin
  S:=PS^;
  k:=Pos('.', S);
  if k>0 then S:=copy(S, k+1, Length(S)-k)+copy(S, 1, k-1);
  SwapParts:=S;
end;

{Implementacja funkcji Compare dla TSlownik}
function TSlownik.Compare(Key1, Key2 : Pointer) : Integer;
begin
  if SwapParts(Key1) < SwapParts(Key2) then Compare := -1
    else if SwapParts(Key1) > SwapParts(Key2) then Compare := 1
      else Compare := 0;
end;

{Implementacja funkcji Compare dla TIntCollection}
function TIntCollection.Compare(Key1, Key2 : Pointer) : Integer;
begin
  if PInt(Key1)^ < PInt(Key2)^ then Compare := -1
    else if PInt(Key1)^ > PInt(Key2)^ then Compare := 1
      else Compare := 0;
end;

{Implementacja funkcji Compare dla TZdarzenia}
function TZdarzenia.Compare(Key1, Key2 : Pointer) : Integer;
begin
  if PZdarz1(Key1)^.Opis < PZdarz1(Key2)^.Opis then Compare := -1
    else if PZdarz1(Key1)^.Opis > PZdarz1(Key2)^.Opis then Compare := 1
      else Compare := 0;
end;

{Implementacja funkcji Compare dla TProcesy}
function TProcesy.Compare(Key1, Key2 : Pointer) : Integer;
begin
  if PProc1(Key1)^.Opis < PProc1(Key2)^.Opis then Compare := -1
    else if PProc1(Key1)^.Opis > PProc1(Key2)^.Opis then Compare := 1
      else Compare := 0;
end;

{wyliczenie umozliwionych zdarzen/krawedzi w wezle}
procedure TWezel.WyliczZdarzUm(R: Boolean);
var
  n, m, k, l: Integer;
  Um, B: Boolean;
  PomPInt: PInt;
  Zd: PZdarz1;
  ZPre, ZPost: PKonf1;
  Act: PActions;
begin
  {Zdarzenie umozliwione:
   1) pre <= konf
   2) post * konf = []}
  for n:=0 to Zdarz^.Count-1 do
    begin
      Um:=true;
      Zd:=Zdarz^.At(n);
      ZPre:=Zd^.Pre;
      ZPost:=Zd^.Post;
      m:=ZPre^.Count-1;
      k:=0;
      while Um and (k<=m) do  { 1) }
        begin
          if PString(Slownik^.At(PInt(ZPre^.At(k))^))^<>'gen()' then
            if not Konf^.Search(ZPre^.At(k),l) then Um:=false;
          Inc(k);
        end;
      m:=ZPost^.Count-1;
      k:=0;
      while Um and (k<=m) do  { 2) }
        begin
          if Konf^.Search(ZPost^.At(k),l) then
            if PString(Slownik^.At(PInt(ZPost^.At(k))^))^<>'null' then
              Um:=false;
          Inc(k);
        end;
      if Um then {zdarzenie umozliwione}
        begin
          New(PomPInt);
          PomPInt^:=n;
          Umozliwione^.Insert(PomPInt);
        end;
    end;
  if R then
    begin
      Act:=New(PActions, Init(0, 1));

      {jesli jest zdarzenie umozliwione z tego samego procesu, co ostatni slad
      pierwotny, ma ono byc wybrane}
      if OstPierwotny>=0 then
        begin
          for n:=0 to Umozliwione^.Count-1 do
            for k:=0 to Proc^.Count-1 do
              if PProc1(Proc^.At(k))^.Actions^.Search(@OstPierwotny, l) then
                if PProc1(Proc^.At(k))^.Actions^.Search
                    (@PZdarz1(Zdarz^.At(PInt(Umozliwione^.At(n))^))^.Opis, l)
                then
                  begin
                    New(PomPInt);
                    PomPInt^:=n;
                    Act^.Insert(PomPInt);
                  end;
        end;

      if Act^.Count=0 then
        begin
          {jesli jest zdarzenie tylko czesciowo umozliwione, to jesli sa zdarzenia
          umozliwione zalezne od niego, to bierzemy je}
          for n:=0 to Zdarz^.Count-1 do
            if not Umozliwione^.Search(@n, l) then
              begin
                Zd:=Zdarz^.At(n);
                ZPre:=Zd^.Pre;
                B:=false;
                for k:=0 to ZPre^.Count-1 do
                  if Konf^.Search(ZPre^.At(k),l) then
                    B:=true;
                if B then
                  for k:=0 to Umozliwione^.Count-1 do
                    if n<>k then
                      if not Zdarz^.InnyProces(n, k) then
                        begin
                          New(PomPInt);
                          PomPInt^:=k;
                          Act^.Insert(PomPInt);
                        end;
              end;

          {jesli sa niezalezne, to bierzemy jedno}
          B:=true;
          k:=0;
          while B and (Act^.Count>1) do
            begin
              B:=false;
              for n:=Act^.Count-1 downto k+1 do
                if Zdarz^.InnyProces(PInt(Umozliwione^.At(PInt(Act^.At(k))^))^,
                      PInt(Umozliwione^.At(PInt(Act^.At(n))^))^) then
                  begin
                    Act^.AtDelete(n);
                    B:=true;
                  end;
              Inc(k);
            end;

          {jesli sa zdarzenia umozliwione w konflikcie, to bierzemy je}
          if Act^.Count>0 then for k:=Umozliwione^.Count-1 downto 1 do
            for n:=0 to k-1 do
              if Zdarz^.WKonflikcie(PInt(Umozliwione^.At(k))^,
                  PInt(Umozliwione^.At(n))^) then
                begin
                  New(PomPInt);
                  PomPInt^:=n;
                  Act^.Insert(PomPInt);
                  New(PomPInt);
                  PomPInt^:=k;
                  Act^.Insert(PomPInt);
                end;

      end;

      {usuwanie niepotrzebnych, jesli istnieja redukcje}
      if Act^.Count>0 then
        for k:=Umozliwione^.Count-1 downto 0 do
          if not Act^.Search(@k, l) then
            Umozliwione^.AtDelete(k);
      Act^.DeleteAll;
    end;

  GrafK^.IleTran:=GrafK^.IleTran+Umozliwione^.Count;
end;

{budowanie grafu konfiguracji od wezla numer n}
procedure TGrafKonf.Buduj(NumerWezla: integer);
var
  Wezel, PoprzW: PWezel;
  PomPInt: PInt;
  Zd: PZdarz1;
  ZPre, ZPost, Knf, PomKnf: PKonf1;
  Sl, PomSl: PWezly;
  i, j, k, l, NUm, Pom, OP, NPost: Integer;
  NowaKonf, TakaSamaKnf, NowySlad, TakiSamSl, Ostatnie: Boolean;
begin
  MyApp.Idle2;
  PoprzW:=At(NumerWezla);
  Wezel:=At(NumerWezla);
  OP:=Wezel^.OstPierwotny;
  Ostatnie:=false;
  Wezel^.WyliczZdarzUm(Redukcja);
  for i:=0 to Wezel^.Umozliwione^.Count-1 do {dla wszystkich zdarz. um.}
    begin
      Wezel:=At(NumerWezla);
      {Wylicz nowa konfiguracje i slad dla zdarzenia um.}
      NUm:=PInt(Wezel^.Umozliwione^.At(i))^;
      Zd:=Zdarz^.At(NUm);
      {utworzenie sladu}
      New(Sl, Init(0, 1));
      New(PomPInt);
      PomPInt^:=NUm;
      Sl^.Insert(PomPInt);
      {wstaw. reszty sladu}
      for k:=0 to PoprzW^.Slad^.Count-1 do
        begin
          Pom:=PInt(PoprzW^.Slad^.At(k))^; {element sladu}
          if Zdarz^.Niezalezne(NUm, Pom) then
            begin
              New(PomPInt);
              PomPInt^:=Pom;
              Sl^.Insert(PomPInt);
            end;
        end;
      New(Knf, Init(0, 1));
      ZPre:=Zd^.Pre;
      ZPost:=Zd^.Post;
      for j:=0 to Wezel^.Konf^.Count-1 do
        begin {Konf-Pre}
          New(PomPInt);
          PomPInt^:=PInt(Wezel^.Konf^.At(j))^;
          if not ZPre^.Search(PomPInt, k) then Knf^.Insert(PomPInt)
            else Dispose(PomPInt);
        end;
      for j:=0 to ZPost^.Count-1 do
        begin {Konf+Post}
          New(PomPInt);
          PomPInt^:=PInt(ZPost^.At(j))^;
          Knf^.Insert(PomPInt);
        end;
      {Sprawdz czy jest nowa}
      NowySlad:=true;
      NowaKonf:=true;
      for j:=0 to Count-1 do
        begin
          PomKnf:=PWezel(At(j))^.Konf;
          if PomKnf^.Count=Knf^.Count then
            begin {r¢wna liczba element¢w}
              TakaSamaKnf:=true;
              for k:=0 to Knf^.Count-1 do
                if PInt(PomKnf^.At(k))^<>PInt(Knf^.At(k))^ then
                  TakaSamaKnf:=false;
              if TakaSamaKnf then
                begin
                  NowaKonf:=false;
                  PomSl:=PWezel(At(j))^.Slad;
                  if PomSl^.Count=Sl^.Count then
                    begin
                      TakiSamSl:=true;
                      for l:=0 to Sl^.Count-1 do
                        if PInt(PomSl^.At(l))^<>PInt(Sl^.At(l))^ then
                          TakiSamSl:=false;
                      if TakiSamSl then NowySlad:=false;
                    end;
                end;
            end;
        end;
      if NowaKonf then {jest nowa}
        Konfig^.Insert(Knf)
      else
        for k:=0 to Knf^.Count-1 do Dispose(Knf^.At(k));
      if NowaKonf or NowySlad then
        begin
          Wezel:=New(PWezel, Init);
          Dispose(Wezel^.Konf, Done);
          Wezel^.Konf:=Knf;
          Wezel^.Slad:=Sl;
          {jesli dlugosc sladu=1, to jest on pierwotny}
          if Sl^.Count=1 then
            begin
              Zd:=Zdarz^.At(PInt(Sl^.At(0))^);
              OP:=Zd^.Opis;
              Ostatnie:=Zdarz^.Ostatnie(PInt(Sl^.At(0))^);
            end;
          Wezel^.OstPierwotny:=OP;
          Wezel^.OstWezel:=NumerWezla+1;
          Insert(Wezel);
          if not Redukcja or (Sl^.Count<>1) or not Ostatnie then
            Buduj(Count-1);
        end
      else
        for k:=0 to Sl^.Count-1 do Dispose(Sl^.At(k));
    end;
end;

constructor TZdarz1.Init(IndOp: Integer);
begin
  inherited Init;
  Pre:=New(PKonf1, Init(0, 1));
  Post:=New(PKonf1, Init(0, 1));
  Opis:=IndOp;
end;

constructor TProc1.Init(IndOp: Integer);
begin
  inherited Init;
  Actions:=New(PActions, Init(0, 1));
  Opis:=IndOp;
end;

constructor TZdarzenia.Init(ALimit, ADelta: Integer);
begin
  inherited Init(ALimit, ADelta);
end;

constructor TProcesy.Init(ALimit, ADelta: Integer);
begin
  inherited Init(ALimit, ADelta);
end;

{zdarzenia sa w konflikcie, gdy przeciecie ich prekondycji jest niepuste}
function TZdarzenia.WKonflikcie(Ind1, Ind2: Integer): Boolean;
var
  B: Boolean;
  n, k: Integer;
  Z1, Z2: PZdarz1;
  Pr1: PProc1;
begin
  B:=false;
  Z1:=At(Ind1);
  Z2:=At(Ind2);
  for n:=0 to Z1^.Pre^.Count-1 do
    if Z2^.Pre^.Search(@PInt(Z1^.Pre^.At(n))^, k) then B:=true;
  WKonflikcie:=B;
end;

function TZdarzenia.InnyProces(Ind1, Ind2: Integer): Boolean;
var
  B: Boolean;
  n, k: Integer;
  Z1, Z2: PZdarz1;
  Pr1: PProc1;
begin
  B:=true;
  Z1:=At(Ind1);
  Z2:=At(Ind2);
  for n:=0 to Proc^.Count-1 do
    begin
      Pr1:=Proc^.At(n);
      if Pr1^.Actions^.Search(@Z1^.opis, k) then
        if Pr1^.Actions^.Search(@Z2^.opis, k) then
          B:=false; {zalezne, gdy naleza do tego samego procesu}
    end;
  InnyProces:=B;
end;

function TZdarzenia.Niezalezne(Ind1, Ind2: Integer): Boolean;
var
  B: Boolean;
  n, k: Integer;
  Z1, Z2: PZdarz1;
begin
  B:=true;
  Z1:=At(Ind1);
  Z2:=At(Ind2);
  for n:=0 to Z1^.Pre^.Count-1 do
    if Z2^.Pre^.Search(Z1^.Pre^.At(n), k) then B:=false;
  if B then for n:=0 to Z1^.Pre^.Count-1 do
    if Z2^.Post^.Search(Z1^.Pre^.At(n), k) then B:=false;
  if B then for n:=0 to Z1^.Post^.Count-1 do
    if Z2^.Pre^.Search(Z1^.Post^.At(n), k) then B:=false;
  if B then for n:=0 to Z1^.Post^.Count-1 do
    if Z2^.Post^.Search(Z1^.Post^.At(n), k) then B:=false;
  Niezalezne:=B;
end;

{sprawdzenie, czy zdarzenie ma swoje nastepniki}
function TZdarzenia.Ostatnie(Ind: Integer): Boolean;
var
  B: Boolean;
  n, k, l: Integer;
  Z1, Z2: PZdarz1;
begin
  B:=true;
  Z1:=At(Ind);
  for n:=0 to Z1^.Post^.Count-1 do
    for k:=0 to Count-1 do
      begin
        Z2:=At(k);
        if Z2^.Pre^.Search(Z1^.Post^.At(n), l) then B:=false;
      end;
  Ostatnie:=B;
end;

constructor TWezel.Init;
begin
  inherited Init;
  Umozliwione:=New(PWezly, Init(0, 1));
  Slad:=New(PWezly, Init(0, 1));
  Konf:=New(PKonf1, Init(0, 1));
  Przeszukany:=false;
  OstPierwotny:=-1;
  OstWezel:=0;
end;

constructor TGrafKonf.Init(ALimit, ADelta: Integer; R: Boolean);
var
  W: PWezel;
begin
  inherited Init(ALimit, ADelta);
  Redukcja:=R;
  IleTran:=0;
  W:=New(PWezel, Init);
  W^.Konf:=Konfig^.At(0);
  Insert(W);
end;

{jezeli El zawiera '.n' to n:=((n-2+numer_procesu) mod NetTimes)+1}
procedure IncNum(var El: String; Num, NetTimes: Word);
var
  i, k, l: Integer;
  S: String;
begin
  k:=Pos('.', El);
  if k>0 then {El zawiera kropke}
    begin
      S:=SubStr(El, k+1, Length(El)-k);
      Val(S, l, i);
      l:=((l-2+Num) mod NetTimes)+1;
      Str(NetTimes, S);
      i:=Length(S);
      Str(l:i, S);
      for i:=1 to Length(S) do if S[i]=' ' then S[i]:='0';
      El:=SubStr(El, 1, k)+S;
    end;
end;

procedure TMyApp.EditData;
var
  P: PWindow;
  R: TRect;
  FileName: FNameStr;
begin
  FileName := '*.dat';
  if ExecuteDialog(New(PFileDialog, Init('*.*', 'Edycja pliku danych',
    '~N~azwa', fdOpenButton, 100)), @FileName) <> cmCancel then
    begin
      EnableCommands([cmFOpen]);
      DeskTop^.GetExtent(R);
      P := New(PEditWindow, Init(R, FileName, wnNoNumber));
      InsertWindow(P);
    end;
end;

{wczytanie pliku danych z siecia}
procedure TMyApp.OpenData(FileName: FNameStr);
var
  F: Text;
  El, S, S1: String;
  k, n, Num: Integer;
  Ind, IndSl: Integer;
  PStr: PString;
  PomPInt: PInt;
  Konf1: PKonf1;
  Zdarz1: PZdarz1;
  Proc1: PProc1;
begin
  {sciezka dostepu + nazwa pliku (bez rozszerzenia)}
  NetFileName:=SubStr(FileName, 1, Length(FileName)-4);

  {odblokowanie drukowania sieci itd.}
  EnableCommands([cmPrData, cmGBR, cmGDESL]);
  {zablokowanie nastepnego otwarcia pliku danych}
  DisableCommands([cmFOpen]);

  Konf1:=New(PKonf1, Init(5, 5));
  Konfig^.Insert(Konf1);
  Num:=0; {aktualny numer procesu}

  Assign(F, FileName);

  Reset(F);
  Readln(F, S); {opis sieci}
  NetName:=SubStr(S, 3, Length(S)-2);
  Readln(F, S); {ilosc procesow przy skalowaniu}
  {Skopiowanie cyfr z S do S1}
  S1:=''; for n:=1 to Length(S) do if S[n] in ['0'..'9'] then S1:=S1+S[n];
  Val(S1, NetTimes, k);

  repeat {dla kazdego procesu}
    Inc(Num);
    Reset(F);

    {tworzenie slownika - przejrzenie pliku}
    repeat
      {$I-}
      Readln(F, S);
      if Length(S)>0 then {niepusta linia}
        if S[1]<>'*' then {nie komentarz}
          repeat
            k:=Pos(' ', S)-1;
            if k<1 then k:=Length(S);
            El:=SubStr(S, 1, k);
            {jezeli zawiera '.n' to n:=((n-2+numer_procesu) mod NetTimes)+1}
            IncNum(El, Num, NetTimes);
            S:=SubStr(S, k+1, Length(S)-k);
            S:=TrimL(S);
            Slownik^.Insert(NewStr(El))
          until Length(S)=0;
      {$I+}
    until EOF(F) or (IOResult<>0);
    {koniec tworzenia slownika dla tego procesu}
  until Num>=NetTimes;

  Num:=0;
  repeat {dla kazdego procesu}
    Inc(Num);
    Reset(F);

    {Wczytywanie sieci}
    Readln(F, S); {opis sieci}
    Readln(F, S); {ilosc procesow przy skalowaniu}
    Readln(F, S); {opis linijki konfiguracji poczatkowej}

    Readln(F, S); {konfiguracja 0}

    repeat
      k:=Pos(' ', S)-1;
      if k<1 then k:=Length(S);
      El:=SubStr(S, 1, k);
      IncNum(El, Num, NetTimes);
      S:=SubStr(S, k+1, Length(S)-k);
      S:=TrimL(S);
      PStr:=NewStr(El);
      Ind:=Slownik^.IndexOf(PStr);
      New(PomPInt);
      PomPInt^:=Ind;
      Konf1^.Insert(PomPInt);
      DisposeStr(PStr);
    until Length(S)=0;

    {wczytanie procesow}
    {$I-}
    Readln(F, S); {odstep lub koniec procesow}
    {$I+}
    while (SubStr(S,1,8)<>'* Action') and (IOResult=0) and not EOF(F) do
      begin
        {$I-}
        Readln(F, S); {nazwa procesu}
        {jezeli zawiera '.n' to n:=((n-2+numer_procesu) mod NetTimes)+1}
        IncNum(S, Num, NetTimes);
        PStr:=NewStr(S);
        IndSl:=Slownik^.IndexOf(PStr);
        Proc1:=New(PProc1, Init(IndSl));
        Ind:=Proc^.IndexOf(Proc1); {czy jest juz proces o tym opisie?}
        if Ind=-1 then {na razie nie ma}
          begin
            Proc^.Insert(Proc1);
            Ind:=Proc^.IndexOf(Proc1);
          end
        else
          begin
            Dispose(Proc1);
          end;
        Proc1:=Proc^.At(Ind);

        Readln(F, S); {Actions}
        repeat
          k:=Pos(' ', S)-1;
          if k<1 then k:=Length(S);
          El:=SubStr(S, 1, k);
          {jezeli zawiera '.n' to n:=((n-2+numer_procesu) mod NetTimes)+1}
          IncNum(El, Num, NetTimes);
          S:=SubStr(S, k+1, Length(S)-k);
          S:=TrimL(S);
          PStr:=NewStr(El);
          Ind:=Slownik^.IndexOf(PStr);
          New(PomPInt);
          PomPInt^:=Ind;
          Proc1^.Actions^.Insert(PomPInt);
          DisposeStr(PStr);
        until Length(S)=0;
        Readln(F, S); {odstep lub koniec pliku}
        {$I+}
      end;

    {wczytanie zdarzen}
    while (S<>'* end') and (IOResult=0) and not EOF(F) do
      begin
        {$I-}
        Readln(F, S); {nazwa wezla}
        {jezeli zawiera '.n' to n:=((n-2+numer_procesu) mod NetTimes)+1}
        IncNum(S, Num, NetTimes);
        PStr:=NewStr(S);
        IndSl:=Slownik^.IndexOf(PStr);
        Zdarz1:=New(PZdarz1, Init(IndSl));
        Ind:=Zdarz^.IndexOf(Zdarz1); {czy jest juz zdarzenie o tym opisie?}
        if Ind=-1 then {na razie nie ma}
          begin
            Zdarz^.Insert(Zdarz1);
            Ind:=Zdarz^.IndexOf(Zdarz1);
          end
        else
          begin
            Dispose(Zdarz1);
          end;
        Zdarz1:=Zdarz^.At(Ind);

        Readln(F, S); {pre}
        repeat
          k:=Pos(' ', S)-1;
          if k<1 then k:=Length(S);
          El:=SubStr(S, 1, k);
          {jezeli zawiera '.n' to n:=((n-2+numer_procesu) mod NetTimes)+1}
          IncNum(El, Num, NetTimes);
          S:=SubStr(S, k+1, Length(S)-k);
          S:=TrimL(S);
          PStr:=NewStr(El);
          Ind:=Slownik^.IndexOf(PStr);
          New(PomPInt);
          PomPInt^:=Ind;
          Zdarz1^.Pre^.Insert(PomPInt);
          DisposeStr(PStr);
        until Length(S)=0;

        Readln(F, S); {post}
        repeat
          k:=Pos(' ', S)-1;
          if k<1 then k:=Length(S);
          El:=SubStr(S, 1, k);
          {jezeli zawiera '.n' to n:=((n-2+numer_procesu) mod NetTimes)+1}
          IncNum(El, Num, NetTimes);
          S:=SubStr(S, k+1, Length(S)-k);
          S:=TrimL(S);
          PStr:=NewStr(El);
          Ind:=Slownik^.IndexOf(PStr);
          New(PomPInt);
          PomPInt^:=Ind;
          Zdarz1^.Post^.Insert(PomPInt);
          DisposeStr(PStr);
        until Length(S)=0;
        Readln(F, S); {odstep lub koniec pliku}
        {$I+}
      end;
  until Num>=NetTimes;
  Close(F);
  Str(Slownik^.Count, S);
  Str(Zdarz^.Count, S1);
  MessageBox(^C'Iloûç pozycji síownika: '+S+'.'^M^C+
             'Iloûç zdarze§: '+S1+'.',
             nil, mfInformation + mfOkButton);
end;

procedure TMyApp.PrData;
var
  T: Text;
  k, l: Integer;
  R: TRect;
  KP: PKonf1;
  Zd: PZdarz1;
  Pr: PProc1;
  Act: PActions;
begin
  Assign(T, NetFileName+'.out');
  Rewrite(T);
  Writeln(T, 'Sieç:');
  Writeln(T, NetName);
  Writeln(T);
  Writeln(T, 'Krotnoûç proces¢w: ', NetTimes);
  Writeln(T);
  KP:=Konfig^.At(0);
  l:=KP^.Count;
  Writeln(T, 'Konfiguracja poczÜtkowa (', l, '):');
  for k:=0 to l-1 do
    Writeln(T, PString(Slownik^.At(PInt(KP^.At(k))^))^);

  Writeln(T);
  Writeln(T, 'Zdarzenia (', Zdarz^.Count, '):');
  for k:=0 to Zdarz^.Count-1 do
    begin
      Writeln(T);
      Zd:=Zdarz^.At(K);
      Writeln(T, k+1:3,'. Zdarzenie: ',
        PString(Slownik^.At(PZdarz1(Zd)^.Opis))^);
      KP:=PZdarz1(Zd)^.Pre;
      Write(T, '     Prekondycja  (', KP^.Count, '): ');
      for l:=0 to KP^.Count-1 do
        Write(T, PString(Slownik^.At(PInt(KP^.At(l))^))^, ' ');
      Writeln(T);
      KP:=PZdarz1(Zd)^.Post;
      Write(T, '     Postkondycja (', KP^.Count, '): ');
      for l:=0 to KP^.Count-1 do
        Write(T, PString(Slownik^.At(PInt(KP^.At(l))^))^, ' ');
      Writeln(T);
    end;

  Writeln(T);
  Writeln(T, 'Procesy (', Proc^.Count, '):');
  for k:=0 to Proc^.Count-1 do
    begin
      Writeln(T);
      Pr:=Proc^.At(K);
      Writeln(T, k+1:3,'. Proces: ',
        PString(Slownik^.At(PProc1(Pr)^.Opis))^);
      Act:=PProc1(Pr)^.Actions;
      Write(T, '     Akcje (', Act^.Count, '): ');
      for l:=0 to Act^.Count-1 do
        Write(T, PString(Slownik^.At(PInt(Act^.At(l))^))^, ' ');
      Writeln(T);
    end;

  Writeln(T);
  Writeln(T, 'Síownik (', Slownik^.Count, '):');
  for k:=0 to Slownik^.Count-1 do
    Writeln(T, k:3, ' - ', PString(Slownik^.At(k))^);

  Writeln(T);
  Close(T);
  GetExtent(R);
  R.B.Y:=R.B.Y-2;
  TextWindow:=New(PTextWindow, Init(R, NetFileName+'.OUT'));
  InsertWindow(TextWindow);

end;

procedure TMyApp.PrSSpace;
var
  T: Text;
  k, l, m, n: Integer;
  R: TRect;
  KP: PKonf1;
  Um, Tr: PWezly;
  Zd: PZdarz1;
  W: PWezel;
begin
  Assign(T, NetFileName+'.ssp');
  Rewrite(T);
  Writeln(T, 'Graf konfiguracji. Sieç:');
  Writeln(T, NetName);
  Writeln(T, 'Krotnoûç proces¢w: ', NetTimes);
  Writeln(T);
  Writeln(T, 'Iloûç tranzycji: ', GrafK^.IleTran);
  Writeln(T);
  m:=GrafK^.Count;
  Writeln(T, 'Iloûç wëzí¢w: ', m);
  Writeln(T);
  for n:=0 to m-1 do
    begin
      W:=GrafK^.At(n);
      KP:=W^.Konf;
      Um:=W^.Umozliwione;
      Tr:=W^.Slad;
      l:=KP^.Count;
      Write(T, n+1:4, '. Konfiguracja (', l, '):');
      for k:=0 to l-1 do
        Write(T, ' ', PString(Slownik^.At(PInt(KP^.At(k))^))^);
      Writeln(T);
      l:=Um^.Count;
      Write(T, '      Zdarzenia umoßliwone (', l, '):');
      for k:=0 to l-1 do
        begin
          Zd:=Zdarz^.At(PInt(Um^.At(k))^);
          Write(T, ' ', PString(Slownik^.At(Zd^.Opis))^);
        end;
      Writeln(T);
      l:=Tr^.Count;
      Write(T, '      òlad z konfiguracji ', W^.OstWezel, ' (', l, '): [');
      for k:=0 to l-1 do
        begin
          Zd:=Zdarz^.At(PInt(Tr^.At(k))^);
          if k>0 then Write(T, ';');
          Write(T, PString(Slownik^.At(Zd^.Opis))^);
        end;
      if l=0 then Write(T, 't0');
      Writeln(T, ']');
      Write(T, '      Ostatni ûlad pierwotny: [');
      if W^.OstPierwotny>0 then
        Writeln(T, PString(Slownik^.At(W^.OstPierwotny))^, ']')
      else
        Writeln(T, 't0]');
      Writeln(T);
    end;
  Writeln(T);
  Close(T);
  GetExtent(R);
  R.B.Y:=R.B.Y-2;
  TextWindow:=New(PTextWindow, Init(R, NetFileName+'.SSP'));
  InsertWindow(TextWindow);
end;

procedure TMyApp.Idle2;
var
  E: TEvent;
begin
  GetEvent(E);
  Idle;
end;

procedure TMyApp.Idle;
begin
  inherited Idle;
  if ScreenSaver<>nil then
    ScreenSaver^.CountDown;
  Clock^.Update;
  Star^.Update;
  Heap^.Update;
end;

procedure TMyApp.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y+1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~P~lik', hcNoContext, NewMenu(
      NewItem('~O~tw¢rz plik danych', 'F3', kbF3, cmFOpen, hcNoContext,
      NewItem('~E~dycja pliku danych', 'Ctrl-F3', kbCtrlF3, cmEditData,
              hcNoContext,
      NewItem('~Z~apis pliku danych', 'F2', kbF2, cmSave, hcNoContext,
      NewItem('~P~okaß dane', 'F4', kbF4, cmPrData, hcNoContext,
      NewLine(
      NewItem('~D~rukuj plik', 'Ctrl-F4', kbCtrlF4, cmFPrint, hcNoContext,
      NewItem('~W~yjûcie', 'Esc', kbEsc, cmQuit, hcNoContext,
{      NewItem('~R~estart', 'Alt-F10', kbAltF10, cmRestart, hcNoContext,}
      nil)))))))){)},
    NewSubMenu('~G~enerowanie', hcNoContext, NewMenu(
      NewItem('~B~ez redukcji', 'F7', kbF7, cmGBR, hcNoContext,
      NewItem('~R~edukcja dla DESL', 'F8', kbF8, cmGDESL, hcNoContext,
      NewItem('Redukcja ~i~dealna', 'Ctrl+F8', kbCtrlF8, cmGRId, hcNoContext,
      NewItem('~D~rukuj przestrze§ stan¢w', 'F9', kbF9, cmPrSSpace,
              hcNoContext,
      nil))))),
    NewSubMenu('~I~nne', hcNoContext, NewMenu(
      NewItem('~I~nformacje', 'F1', kbF1, cmAbout, hcNoContext,
      NewItem('~N~astëpne okno', 'F6', kbF6, cmNext, hcNoContext,
      NewItem('~P~oprzednie okno', 'Shift-F6', kbShiftF6, cmPrev, hcNoContext,
      NewItem('~Z~amknij okno', 'Alt-F3', kbAltF3, cmClose, hcNoContext,
      NewItem('Wygaszacz ~e~kranu', 'Ctrl-BackSpace', kbCtrlBack, cmSSav,
              hcNoContext,
      nil)))))),
      nil))))));
end;

procedure TMyApp.InitStatusLine;
var R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Esc~ Wyjûcie', kbNoKey, cmQuit,
      NewStatusKey('~Alt-F3~ Zamknij', kbAltF3, cmClose,
      NewStatusKey('~F10~ Menu', kbF10, cmMenu,
      nil))),
    nil)
  ));
end;

procedure TMyApp.Future;
var
  C: Word;
begin
  MessageBox(^C'Funkcja nie jest dostëpna'^M^C'w tej wersji programu.',
             nil, mfInformation + mfOkButton);
end;

function LeadingZero(w : Word) : String;
var
  s : String;
begin
  Str(w:0,s);
  if Length(s) = 1 then
    s := '0' + s;
  LeadingZero := s;
end;

{generowanie przestrzeni stan¢w bez redukcji}
procedure TMyApp.GBR;
var
  S, S1, S2: String;
  h, m, sec, hund : Word;
begin
  Star^.StarSelect(2);
  GetTime(h,m,sec,hund);
  S1:=StrNumber(h,1,0)+':'+LeadingZero(m)+':'+LeadingZero(sec)+
      '.'+LeadingZero(hund);
  {odblokowanie drukowania przestrzeni stan¢w}
  EnableCommands([cmPrSSpace, cmGRId]);
  {zablokowanie nastepnego generowania}
  DisableCommands([cmGBR, cmGDESL]);

  New(GrafK, Init(10, 10, false));
  GrafK^.Buduj(0);

  GetTime(h,m,sec,hund);
  S1:=S1+'-'+StrNumber(h,1,0)+':'+LeadingZero(m)+':'+LeadingZero(sec)+
      '.'+LeadingZero(hund);
  Str(GrafK^.Count, S);
  Str(GrafK^.IleTran, S2);
  S:=S+'/'+S2;
  MessageBox(^C'Generowanie bez redukcji zostaío zako§czone.'+
             ^M^C'Iloûç konfig./tranzycji: '+S+'.'^M^C'('+S1+')',
             nil, mfInformation + mfOkButton);
  Star^.StarSelect(4);
end;

{generowanie przestrzeni stan¢w z redukcjÜ dla DESL}
procedure TMyApp.GDESL;
var
  S, S1, S2: String;
  h, m, sec, hund : Word;
begin
  Star^.StarSelect(2);
  GetTime(h,m,sec,hund);
  S1:=StrNumber(h,1,0)+':'+LeadingZero(m)+':'+LeadingZero(sec)+
      '.'+LeadingZero(hund);
  {odblokowanie drukowania przestrzeni stan¢w}
  EnableCommands([cmPrSSpace, cmGRId]);
  {zablokowanie nastepnego generowania}
  DisableCommands([cmGBR, cmGDESL]);

  New(GrafK, Init(10, 10, true));
  GrafK^.Buduj(0);

  GetTime(h,m,sec,hund);
  S1:=S1+'-'+StrNumber(h,1,0)+':'+LeadingZero(m)+':'+LeadingZero(sec)+
      '.'+LeadingZero(hund);
  Str(GrafK^.Count, S);
  Str(GrafK^.IleTran, S2);
  S:=S+'/'+S2;
  MessageBox(^C'Generowanie z redukcjÜ dla DESL zostaío zako§czone.'+
             ^M^C'Iloûç konfig./tranzycji: '+S+'.'^M^C'('+S1+')',
             nil, mfInformation + mfOkButton);
  Star^.StarSelect(4);
end;

{redukcja idealna przestrzeni}
procedure TMyApp.GRId;
var
  S, S1, S2: String;
  h, m, sec, hund : Word;
  n: Integer;
  W: PWezel;
begin
  GetTime(h,m,sec,hund);
  S1:=StrNumber(h,1,0)+':'+LeadingZero(m)+':'+LeadingZero(sec)+
      '.'+LeadingZero(hund);
  {zablokowanie nastepnego generowania}
  DisableCommands([cmGRId]);

  for n:=GrafK^.Count-1 downto 0 do
    PWezel(GrafK^.At(n))^.Umozliwione^.DeleteAll;
  for n:=GrafK^.Count-1 downto 0 do
    begin
      W:=GrafK^.At(n);
      if W^.Slad^.Count>1 then
        GrafK^.AtDelete(n);
    end;

  GetTime(h,m,sec,hund);
  S1:=S1+'-'+StrNumber(h,1,0)+':'+LeadingZero(m)+':'+LeadingZero(sec)+
      '.'+LeadingZero(hund);
  Str(GrafK^.Count, S);
  Str(GrafK^.IleTran, S2);
  S:=S+'/'+S2;
  MessageBox(^C'Redukcja idealna zostaía zako§czona.'+
             ^M^C'Iloûç konfiguracji: '+S+'.'^M^C'('+S1+')',
             nil, mfInformation + mfOkButton);
end;

procedure TMyApp.About;
begin
  Application^.ExecuteDialog(MakeDialogAbout, nil);
end;

procedure TMyApp.GetEvent(var E:TEvent);
begin
  Inherited GetEvent(E);
  if E.What<>evNothing then
    if ScreenSaver<>nil then
      if E.What=evKeyDown then
      begin
        if ScreenSaver^.Saving then
          E.What:=evNothing;
        ScreenSaver^.HeartBeat;
      end else
        if E.What and evMouse<>0 then
          ScreenSaver^.HeartBeat;
end;

procedure TMyApp.Restart;
var
  Event: TEvent;
begin
  TheEnd:=false;
  Event.What:=evCommand;
  Event.Command:=cmQuit;
  PutEvent(Event);
end;

constructor TMyApp.Init;
var
  Event: TEvent;
  R: TRect;
begin
  TheEnd:=true;
  MaxHeapSize := HeapSize;
  inherited Init;

  {utworzenie kolekcji}
  Slownik:=New(PSlownik, Init(20, 10));
  Konfig:=New(PKonfig, Init(20, 10));
  Zdarz:=New(PZdarzenia, Init(20, 10));
  Proc:=New(PProcesy, Init(2, 2));
  NetTimes:=1;

  {wygaszacz nr 4 po 5 minutach}
  ScreenSaver:=New(PScreenSaver, Init(4, 5));

  GetExtent(R);
  R.A.X := R.B.X - 1; R.A.Y := R.B.Y - 1;
  Star := New(PStarView, Init(R));
  Insert(Star);
  Star^.Update;
  GetExtent(R);
  R.A.X := R.B.X - 33; R.B.Y := R.A.Y + 1;
  Clock := New(PClockView, Init(R));
  Insert(Clock);
  GetExtent(R);
  R.A.X := R.B.X - 12; R.B.X:=R.B.X-2; R.A.Y := R.B.Y - 1;
  Heap:= New(PHeapView, Init(R));
  Insert(Heap);

  Calculator := New(PCalculator, Init);
  InsertWindow(Calculator);

  Star^.StarSelect(4);

  About;

  Event.What:=evCommand;
  Event.Command:=cmFOpen;
  PutEvent(Event);

  DisableCommands([cmPrData, cmGBR, cmGDESL, cmGRId, cmPrSSpace, cmSave]);
end;

procedure TMyApp.HandleEvent(var Event: TEvent);

procedure FileOpen;
var
  FileName: FNameStr;
begin
  Star^.StarSelect(2);
  FileName := '*.dat';
  if ExecuteDialog(New(PFileDialog, Init('*.*', 'Otw¢rz plik danych',
    '~N~azwa', fdOpenButton, 100)), @FileName) <> cmCancel then
    OpenData(FileName);
  Star^.StarSelect(4);
end;

procedure FilePrint;
var
  FileName: FNameStr;
  F: File of Char;
  C: Char;
  A: array[Char] of Char;
  S1, S2: String;
  n: Integer;
begin
  S1:='Üçëí§¢û¶ßèïêú•£ò†°';
  S2:='acelnoszzACELNOSZZ';
  for n:=0 to 255 do A[chr(n)]:=chr(n);
  for n:=1 to Length(S1) do A[S1[n]]:=S2[n];
  Star^.StarSelect(2);
  FileName := '*.*';
  if ExecuteDialog(New(PFileDialog, Init('*.*', 'Drukuj plik',
    '~N~azwa', fdOpenButton, 100)), @FileName) <> cmCancel then
    begin
      Assign(F, FileName);
      Reset(F);
      while not EOF(F) do
        begin
          Read(F, C);
          Write(Lst, A[C]);
        end;
      Close(F);
      Write(Lst,#12);
    end;
  Star^.StarSelect(4);
end;

begin
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
      begin
        case Event.Command of
          cmAbout:   About;
          cmFOpen:   FileOpen;
          cmFPrint:  FilePrint;
          cmSSav:    SSav;
          cmGBR:     GBR;
          cmGRId:    GRId;
          cmGDESL:   GDESL;
          cmPrData:  PrData;
          cmEditData:EditData;
          cmPrSSpace:PrSSpace;
          cmRestart: Restart;
        else
          Future; {funkcja nie jest na razie dostepna}
        end;
        ClearEvent(Event);
      end;
  end;
end;

procedure TMyApp.SSav;
var
  C: Word;
begin
  DataRecSS.On:=ord(ScreenSaver^.Enabled);
  DataRecSS.Time:=round(ScreenSaver^.SavingTime/(60*18.2));
  DataRecSS.Typ:=ScreenSaver^.SaverNo;
  C:=Application^.ExecuteDialog(MakeDialogSS, @DataRecSS);
  if C=cmOK then
    begin
      ScreenSaver^.Init(DataRecSS.Typ, round(DataRecSS.Time));
      ScreenSaver^.Enable(DataRecSS.On<>0);
    end;
end;

var
  ToS: TStandardyPL;
begin
  ToS:=Latin2; {docelowy standard polskich liter}
  MyApp.SetStandards(Mazovia, ToS);
  repeat
    MyApp.Init;
    MyApp.Run;
    MyApp.Done;
  until TheEnd;
end.
