; Mateusz Biesiadowski mb406097

SYS_READ  equ 0
SYS_WRITE equ 1
SYS_EXIT  equ 60
STDIN     equ 0
STDOUT    equ 1
ERROR     equ 1                         ; kod wyjścia w przypadku błędu
OK_ARGC   equ 5                         ; poprawna liczba argumentów
PERM_LEN  equ 42                        ; długość poprawnej permutacji
KEY_LEN   equ 2                         ; długość poprawnego klucza
ASCII_1   equ '1'                       ; kod ASCII znaku '1'
ASCII_Z   equ 'Z'                       ; kod ASCII znaku 'Z'
END       equ 0                         ; znak końca napisu
KEY       equ 0                         ; napis jest kluczem
PERM      equ 1                         ; napis jest permutacją
PERM_T    equ 2                         ; napis jest permutacją składającą się z 21 rozłącznych cykli dwuelementowych
BUF_SIZE  equ 4096                      ; długość bufora na wejście
L_POS     equ 'L' - '1'                 ; pozycja obrotowa L, na znaku 'L'
R_POS     equ 'R' - '1'                 ; pozycja obrotowa L, na znaku 'R'
T_POS     equ 'T' - '1'                 ; pozycja obrotowa L, na znaku 'T'


; Wykonanie programu zaczyna się od etykiety _start.
global _start


; Wypisuje napis na standardowe wyjście, pierwszym argumentem jest wiadmość, a drugim jej długość.
; W rejestrze rax zwraca liczbę wypisanych bajtów.
%macro print 2
  mov     rsi, %1
  mov     rdx, %2
  mov     rax, SYS_WRITE
  mov     rdi, STDOUT
  syscall
%endmacro


; Wczytuje napis ze standardowego wejścia do bufora i zapisuje jego długość.
%macro read 0
  mov     rax, SYS_READ
  mov     rdi, STDIN
  mov     rsi, input
  mov     rdx, BUF_SIZE
  syscall

  mov     [input_l], rax                ; Przenosi do tablicy input_l długość wczytanego wejścia.
%endmacro


; Wykonuje na znaku przesunięcie cykliczne w prawo.
; Pierwszy argument to znak, drugi o ile ma zostać wykonane przesunięcie, a trzeci to 32-bitowy rejestr ze znakiem.
%macro Q_sh_r 3
  xor     r11d, r11d                    ; Zeruje zmienną.

  add     %1, %2                        ; Zwiększa znak o przekazaną wartość.
  mov     r11b, %1                      ; Przenosi nową wartość znaku do rejestru.
  sub     r11b, PERM_LEN                ; Odejmuje od rejestru wartość modulo, na wypadek gdyby znak wyszedł poza dozwolony zakres.
  
  cmp     %1, PERM_LEN                  ; Sprawdza czy nowa wartość znaku mieści się w poprawnym zakresie.
  cmovge  %3, r11d                      ; Jeżeli nie, przenosi do rejestru ze znakiem wartość pomniejszoną o modulo.
%endmacro


; Wykonuje na znaku przesunięcie cykliczne w prawo.
; Pierwszy argument to znak, drugi o ile ma zostać wykonane przesunięcie, a trzeci to 32-bitowy rejestr ze znakiem.
%macro Q_sh_l 3
  xor     r11d, r11d                    ; Zeruje zmienną.

  sub     %1, %2                        ; Zmniejsza znak o przekazaną wartość.
  mov     r11b, %1                      ; Przenosi nową wartość znaku do rejestru.
  add     r11b, PERM_LEN                ; Dodaje do rejestru wartość modulo, na wypadek gdyby znak wyszedł poza dozwolony zakres.
  
  cmp     %1, 0                         ; Sprawdza czy nowa wartość znaku mieści się w poprawnym zakresie.
  cmovl   %3, r11d                      ; Jeżeli nie, przenosi do rejestru ze znakiem wartość powiększoną o modulo.
%endmacro


; Obraca bębenek R o jedną pozycję, a jeśli bębenek R osiągnie pozycję obrotową,
; to również bębenek L obraca się o jedną pozycję, gdzie pozycje obrotowe to L_POS, R_POS, T_POS.
; Pierwszym argumentem jest rejestr zawierający wartość bębenka L, a drugim rejestr zawierający wartość bębenka R.
%macro key_sh 0
  mov     r11d, r14d                    ; Kopiuje pozycje bębenka L.
  inc     r11d                          ; Symuluje obrót bębenka L o 1.

  inc     r15d                          ; Obraca bębenek R o 1.
  cmp     r15b, L_POS                   ; Sprawdza czy wystąpiła pozycja obrotowa 'L' dla bębenka L.
  cmove   r14d, r11d                    ; Jeśli tak, przenosi na zmienną z bębenkiem L wartość bębenka L obróconego o 1.
  cmp     r15b, R_POS                   ; Sprawdza czy wystąpiła pozycja obrotowa 'R' dla bębenka L.
  cmove   r14d, r11d                    ; Jeśli tak, przenosi na zmienną z bębenkiem L wartość bębenka L obróconego o 1.
  cmp     r15b, T_POS                   ; Sprawdza czy wystąpiła pozycja obrotowa 'T' dla bębenka L.
  cmove   r14d, r11d                    ; Jeśli tak, przenosi na zmienną z bębenkiem L wartość bębenka L obróconego o 1.

  xor     r11d, r11d

  cmp     r15b, PERM_LEN                ; Sprawdza czy wartość bębenka R przekroczyła dozwolony zakres.
  cmove   r15d, r11d                    ; Jeśli tak, wykonuje zmienna z bębenkiem R = 0 (wykonuje R mod PERM_LEN)
  cmp     r14b, PERM_LEN                ; Sprawdza czy wartość bębenka L przekroczyła dozwolony zakres.
  cmove   r14d, r11d                    ; Jeśli tak, wykonuje zmienna z bębenkiem L = 0 (wykonuje L mod PERM_LEN)
%endmacro


; Wykonuje na znaku permutację.
; Pierwszy argument to znak, drugi to wskaźnik na tablicę z permutacją, a trzeci to 32-bitowy rejestr ze znakiem.
%macro do_perm 3
  mov     %1, [%2 + %3]
%endmacro


; Sprawdza czy wejście jest poprawne i zmniejsza wartość znaków z wejścia o ASCII_1.
; W rejestrze rax znajduje się długość wczytanych znaków.
; W rejestrze r8 znajduje się długość wejścia.
%macro validate_sub 0
  xor     ecx, ecx                      ; Zeruje iterator.
  mov     rdi, input                    ; adres początku wejścia

%%loop:
  cmp     rcx, r8
  je      %%finished

  val_chr byte [rdi]                    ; Sprawdza czy znak jest z poprawnego zakresu.
  sub     byte [rdi], ASCII_1           ; Przesuwa numerowanie znaku.
  inc     rcx                           ; Zwiększa iterator.
  inc     rdi                           ; Przechodzi do kolejnego znaku.
  jmp     %%loop

%%finished:
%endmacro


;Sprawdza czy znak jest poprawny.
; W pierwszym argumencie znajduje się znak do sprawdzenia.
%macro val_chr 1
  cmp     %1, ASCII_1                   ; Sprawdza czy znak nie jest mniejszy od '1',
  jb      exit_error

  cmp     %1, ASCII_Z                   ; Sprawdza czy znak nie jest większy od 'Z'.
  ja      exit_error
%endmacro


; Dodaje do każdego znaku z wejścia ASCII_1.
; W rejestrze r8 znajduje się długość wejścia.
%macro inc_input 0
  xor     ecx, ecx                      ; Zeruje iterator.
  mov     rdi, input                    ; Ustawia adres początku wejścia.

%%loop:
  cmp     rcx, r8                       ; Sprawdza czy cały napis został powiększony.
  je      %%finished
  add     byte [rdi], ASCII_1           ; Dodaje do znaku kod ASCII 1
  inc     rcx                           ; Zwiększa iterator.
  inc     rdi                           ; Przechodzi do kolejnego znaku.
  jmp     %%loop

%%finished:
%endmacro


; Zapisuje permutację odwrotną do wskazanej.
; W pierwszym argumencie przyjmuje wskaźnik na tablicę do której ma zapisać odwrotność permutacji,
; a w drugim tablicę z permutacją.
%macro invert 2
  xor     ecx, ecx                      ; Zeruje iterator.
  mov     rdi, %2                       ; Ustawia adres początku tablicy.
  xor     r10d, r10d

%%loop:
  cmp     cl, PERM_LEN                  ; Sprawdza czy cała permutacja została odwrócona.
  je      %%finished

  mov     r10b, [rdi]                   ; Przenosi znak do rejestru.
  mov     [%1 + r10], cl                ; Na podstawie pozycji znaku, zapisuje w tablicy z odwrotną permutacją jego pozycję.
  inc     cl                            ; Zwiększa iterator.
  inc     rdi                           ; Przechodzi do następnego znaku.
  jmp     %%loop

%%finished:
%endmacro


; Kopiuje znak do tablicy.
; Pierwszy argument to wskaźnik na tablicę, a drugi to znak
%macro mov_arr 2
  sub     %2, ASCII_1                   ; pozycja elementu w tablicy, gdzie '1' jest na pozycji 0, a 'Z' na pozycji 41.
  mov     [%1], %2                      ; Zapisuje kod ASCII znaku pomniejszony o 42 w tablicy.
  inc     %1                            ; Przesuwa wskaźnik na tablicę na następną komórkę.
%endmacro


; Zaznacza w tablicy, że dany znak wystąpił w napisie i przechodzi do kolejnego znaku napisu.
; Pierwszy argument to wskaźnik na tablicę do zaznaczania wystąpień,
; drugi to 64-bitowy rejestr ze znakiem pomniejszonym o ASCII_1, a trzeci to wskaźnik na napis.
%macro mrk_arr 3
  mov     byte [%1 + %2], 1             ; Zaznacza, że dany znak wystąpił w permutacji.
  inc     %3                            ; Przechodzi do następnego znaku w napisie.
%endmacro

; Kończy program z kodem 0.
%macro exit_success 0
  mov     rax, SYS_EXIT
  xor     edi, edi                      ; kod powrotu 0
  syscall
%endmacro


section .bss

input:    resb BUF_SIZE                 ; bufor na wejście od użytkownika
input_l:  resq 1                        ; długość otrzymanego wejścia
perm_arr: resb PERM_LEN                 ; tablica do sprawdzania czy napis jest permutacją
L_perm:   resb PERM_LEN                 ; tablica zawierająca permutacje L
R_perm:   resb PERM_LEN                 ; tablica zawierająca permutacje R
T_perm:   resb PERM_LEN                 ; tablica zawierająca permutacje T
perm_key: resb KEY_LEN                  ; tablica zawierająca klucz szyfrowania

L_inv:    resb PERM_LEN                 ; tablica zawierająca permutację odwrotną do permutacji L
R_inv:    resb PERM_LEN                 ; tablica zawierająca permutację odwrotną do permutacji R

section .text

_start:

  call    _check_args                   ; Sprawdza poprawność argumentów programu.

  invert  L_inv, L_perm                 ; Zapisuje w tablicy L_inv odwrotność permutacji L_perm.
  invert  R_inv, R_perm                 ; Zapisuje w tablicy R_inv odwrotność permutacji R_perm.

  xor     r14d, r14d
  xor     r15d, r15d
  xor     r8d, r8d                      ; Zeruje zmienne.

  mov     r14d, [perm_key]              ; pozycja bębenka L
  mov     r15d, [perm_key + 1]          ; pozycja bębenka R

process_input:
  read                                  ; Wczytuje ze standardowego wejścia do bufora tekst do zaszfrowania/zdeszyfrowania.
  mov     r8, [input_l]                 ; Przenosi do rejestru długość wejścia od użytkownika.

  validate_sub                          ; Sprawdza poprawność wejścia i zmniejsza wartości znaków o ASCII_1.

  xor     r13d, r13d                    ; Zeruje iterator.
  mov     r12, input                    ; Ustawia adres, od którego rozpocznie szyfrowanie.

encript_buffer:
  cmp     r13, r8                       ; Sprawdza czy zaszyfrowano już cały napis.
  je      print_buffer
                    
  key_sh                                ; Przed zaszyfrowaniem każdego znaku obraca bębenek R (i ewentualnie bębenek L).
  
  xor     edi, edi
  mov     dil, [r12]                    ; Kopiuje znak z aktualnej pozycji z wejścia
             
  Q_sh_r  dil, r15b, edi                ; Wykonuje na znaku przekształcenie Q_r

  do_perm dil, R_perm, rdi              ; Wykonuje na znaku przekształcenie R

  Q_sh_l  dil, r15b, edi                ; Wykonuje na znaku przekształcenie (Q_r)^-1

  Q_sh_r  dil, r14b, edi                ; Wykonuje na znaku przekształcenie Q_l

  do_perm dil, L_perm, rdi              ; Wykonuje na znaku przekształcenie L

  Q_sh_l  dil, r14b, edi                ; Wykonuje na znaku przekształcenie (Q_l)^-1

  do_perm dil, T_perm, rdi              ; Wykonuje na znaku przekształcenie T

  Q_sh_r  dil, r14b, edi                ; Wykonuje na znaku przekształcenie Q_l

  do_perm dil, L_inv, rdi               ; Wykonuje na znaku przekształcenie L^-1

  Q_sh_l  dil, r14b, edi                ; Wykonuje na znaku przekształcenie (Q_l)^-1
  
  Q_sh_r  dil, r15b, edi                ; Wykonuje na znaku przekształcenie Q_r

  do_perm dil, R_inv, rdi               ; Wykonuje na znaku przekształcenie R^-1

  Q_sh_l  dil, r15b, edi                ; Wykonuje na znaku przekształcenie (Q_r)^-1

  mov     [r12], dil                    ; Przenosi zmieniony znak spowrotem do tablicy.

  inc     r13                           ; Zwiększa licznik zmienionych znaków.
  inc     r12                           ; Przesuwa pozycję w tablicy z wejściem.
  jmp     encript_buffer

print_buffer:
  inc_input                             ; Dodaje wartość elementom w tablicy, aby spowrotem były znakami.
  print   input, [input_l]              ; Wypisuje zaszyfrowane elementy.
  cmp     rax, BUF_SIZE                 ; Sprawdza czy na wejściu znajdują się jeszcze jakieś znaki do przetworzenia.
  je      process_input

  exit_success                          ; Kończy program z kodem 0.


_check_args:
  lea     rbp, [rsp + 8]                ; adres argc

  cmp     dword [rbp], OK_ARGC          ; Sprawdza czy liczba argumentów jest poprawna.
  jne     exit_error                    ; Jeśli nie jest kończy program kodem błędu.

  mov     r8, PERM_LEN                  ; Przekazuje poprawną napisu jako pierwszy argument funkcji _check_string.
  mov     r9, PERM                      ; Przekazuje kod oznaczający, że napis jest permutacją jako drugi argument funkcji _check_string.

  add     rbp, 8*2                      ; adres args[1]; permutacja L
  mov     rax, L_perm                   ; Przekazuje w argumencie, że permutacja ma zostać zapisana w tablicy L_perm.
  call    _check_string
  
  add     rbp, 8                        ; adres args[2]; permutacja R
  mov     rax, R_perm                   ; Przekazuje w argumencie, że permutacja ma zostać zapisana w tablicy R_perm.
  call    _check_string

  add     rbp, 8                        ; adres args[3]; permutacja T
  mov     rax, T_perm                   ; Przekazuje w argumencie, że permutacja ma zostać zapisana w tablicy T_perm.
  mov     r9, PERM_T                    ; Przekazuje kod oznaczający, że napisa jest permutacją składającą się z 21 rozłącznych cykli dwuelementowych jako drugi argument programu.
  call    _check_string

  add     rbp, 8                        ; adres args[4]; klucz
  mov     rax, perm_key                 ; Przekazuje w argumencie, że klucz ma zostać zapisany w tablicy perm_key.
  mov     r8, KEY_LEN                   ; Przekazuje poprawną napisu jako pierwszy argument funkcji _check_string.
  mov     r9, KEY                       ; Przekazuje kod oznaczający, że napis nie jest permutacją jako drugi argument funkcji _check_string.
  call    _check_string

  ret


; Sprawdza poprawność argumentów, w rejestrze rbp otrzymuje wskaźnik na napis,
; w r8 przyjmuje poprawną długość argumentu, w r9 wartość KEY jeśli napis nie jest permutacją, PERM jeśli jest,
; a PERM_T jeśli jest permutacją składającą się z 21 rozłącznych cykli dwuelementowych, a w rejestrze rax wskaźnik na tablicę,
; do której należy skopiować napis. 
_check_string:
  mov     rsi, [rbp]                    ; adres napisu
  mov     rdi, rsi                      ; Ustaw adres, od którego rozpocząć szukanie.
  xor     ecx, ecx
  cmp     r9, KEY                       ; Sprawdza, czy napis jest permutacją.
  je      next_char                     ; Jeżeli nie, sprawdza tylko czy napis ma poprawną długość i czy składa się z dozwolonych znaków.
 
  mov     rdx, perm_arr                 ; Ustaw adres początku tablicy.
  
clear_arr:
  mov     byte [rdx + rcx], 0           ; Zeruje komórkę tablicy.
  inc     rcx                           ; Zwiększa iterator.
  cmp     rcx, PERM_LEN                 ; Sprawdza czy cała tablica została wyzerowana.
  jne     clear_arr                     ; Jeśli nie, przechodzi do kolejnej komórki.
  
  cmp     r9, PERM                      ; Sprawdza czy napis jest permutacją składającą się z 21 rozłącznych cykli dwuelementowych.
  je      next_char_perm                ; Jeżeli nie, sprawdza czy napis jest poprawną permutacją, bez warunku z cyklami.
  xor     r10d, r10d                    ; Zeruje iterator.
  xor     ecx, ecx
  xor     r12d, r12d                    ; Zeruje zmienne.

next_char_perm_T:
  mov     cl, [rdi]                     ; Przenosi znak z tablicy do rejestru.

  cmp     cl, END                       ; Sprawdza czy napotkano koniec napisu.
  jz      finished_perm

  val_chr cl                            ; Sprawdza czy znak jest poprawny.
  mov_arr rax, cl                       ; Zapisuje kod znaku pomniejszony o ASCII_1 w tablicy.
  mrk_arr rdx, rcx, rdi                 ; Zaznacza, że dany znak wystąpił w permutacji i przechodzi do następnego znaku napisu.

  mov     r12b, [rsi + rcx]             ; Przenosi znak z napis[napis[r10]] do rejestru. (r10 to aktualna pozycja w tablicy napis)
  sub     r12b, ASCII_1                 ; Zmniejsza wartość znaku o ASCII_1.

  cmp     cl, r12b                      ; Sprawdza czy dany fragment permutacji nie jest identycznością.
  je      exit_error

  cmp     r12b, r10b                    ; Sprawdzam czy powstał cykl dwuelementowy.
  jne     exit_error

  inc     r10                           ; Zwiększa iterator pozycji w tablicy.
  jmp     next_char_perm_T

next_char_perm:
  mov     cl, [rdi]                     ; Przenosi znak z tablicy do rejestru.

  cmp     cl, END                       ; Sprawdza czy napotkano koniec napisu.
  jz      finished_perm
  
  val_chr cl                            ; Sprawdza czy znak jest poprawny.
  mov_arr rax, cl                       ; Zapisuje kod znaku pomniejszony o ASCII_1 w tablicy.
  mrk_arr rdx, rcx, rdi                 ; Zaznacza, że dany znak wystąpił w permutacji i przechodzi do następnego znaku napisu.
  jmp     next_char_perm

next_char:
  mov     cl, [rdi]                     ; Przenosi znak z tablicy do rejestru.

  cmp     cl, END                       ; Sprawdza czy napotkano koniec napisu.
  jz      finished

  val_chr cl                            ; Sprawdza czy znak jest poprawny.
  mov_arr rax, cl                       ; Zapisuje kod znaku pomniejszony o ASCII_1 w tablicy.

  inc     rdi                           ; Przechodzi do następnego znaku w napisie.
  jmp     next_char 

finished:                               ; Koniec funkcji, jeżeli sprawdza czy napis jest poprawny. 
  sub     rdi, rsi
  cmp     rdi, r8                       ; Sprawdza czy długość napisu jest poprawna.
  jne     exit_error

  ret

finished_perm:                          ; Koniec funkcji, jeżeli sprawdza czy permutacja jest poprawna.
  sub     rdi, rsi
  cmp     rdi, r8                       ; Sprawdza czy długość napisu jest poprawna.
  jne     exit_error
  xor     ecx, ecx                      ; Zeruje iterator

check_arr:
  cmp     byte [rdx + rcx], 1           ; Sprawdza czy komórka tablicy symbolizująca znak wystąpiła w permutacji
  jne     exit_error                    ; Jeżeli nie, program kończy się kodem błędu.

  inc     rcx                           ; Zwiększa iterator.
  cmp     rcx, PERM_LEN                 ; Sprawdza czy cała tablica została sprawdzona.
  jne     check_arr                     ; Jeżeli nie, przechodzi do kolejnej komórki

  ret


exit_error:
  mov     rax, SYS_EXIT
  mov     rdi, ERROR                    ; kod powrotu 1
  syscall
