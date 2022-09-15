# licencjat
Generowanie zredukowanych przestrzeni stanów zachowujących własności wyrażalne w DESL, 1998

KROTKI OPIS PROGRAMU (bez polskich liter - jak widac)

1. Wymagania
Minimum 286, minimum 2 MB RAM (1 MB Extended) - im wiecej tym lepiej (tryb
Protected). Dla komputerow z 640 KB RAM jest program w trybie Real 
- mozna obrabiac wtedy male sieci. Zalecana myszka.

2. Polskie litery
Wewnetrznie (zrodlo) - Mazovia; ekran - Latin2
(jesli w systemie nie ma polskich liter w standardzie Latin2, nalezy
przed uruchomieniem lic08.exe uruchomic vgapllat.com).

3. Format danych wejsciowych (pliki *.dat)
W zasadzie wewnatrz pliku danych jest zawarty opis jego zawartosci.
Jedynym hakiem jest skalowalnosc. Jezeli dany element sieci ma rozszerzenie
(np. "a.1"), to przy generowaniu drugiego procesu przyjmie rozszerzenie
zwiekszone o numer_procesu-1 modulo liczba_procesow (tzn. np "a.2"). Jezeli
element nie ma rozszerzenia, to albo jest to element wspolny dla wszystkich
procesow, albo caly proces jest jedynym i wtedy nie ma to znaczenia.
Dlugosc rozszerzenia (np. "a.1" lub "a.01") jest dobierana automatycznie
w zaleznosci od ilosci procesow. Dwa symbole specjalne "gen()" i "null"
to odpowiednio zrodlo znacznikow i "czarna dziura".

4. Ograniczenia
Ilosc elementow slownika nazw, zdarzen i elementow w konfiguracji jest
ograniczona do ok. 16000 kazdy. Wielkosc przestrzeni stanow jest ograniczona
jedynie wielkoscia pamieci operacyjnej (a dokladnie Extended, gdyz program
jest skompilowany do trybu Protected - ilosc wolnej pamieci w bajtach
jest podawana w prawym dolnym rogu ekranu).

5. Co nie dziala:
-zaladowanie nowej sieci wymaga ponownego uruchomienia programu

6. Program
Napisany w Pascalu (kompilator Borland 7.0) z wieloma bibliotekami,
m. in. Turbo Vision 2.0. Glowny pakiet zalaczony. Pozostale moduly
licza ok 30000 linii kodu (glownie Turbo Vision, czesciowo modyfikowane).
