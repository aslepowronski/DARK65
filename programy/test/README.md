## Przykładowy program testowy

### Ustawienia wstępne

- Szybkość transmisji: 9600 baud
- Liczba bitów danych: 8
- Liczba bitów stopu: 1
- Brak parzystości

### Składnia

Odczytywanie komórki pod adresem `0xAAAA`
```c
r<AAAA>                 // np. r0FFF
```
Zapisywanie wartości `0xVV` do komórki pod adresem `0xAAAA`
```c
w<AAAA>:<VV>            // np. w1000:CD
```
Zapętlone wypisywanie tekstu `Hello 6502`.
```c
p
```
-----------------------------------------
