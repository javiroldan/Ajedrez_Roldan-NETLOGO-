__includes ["MCTS-LT.nls"]

;---------------------------------------------------------------------------------------------
;VARIABLES:

breed [blancas blanca]  ;piezas blancas del juego
breed [negras negra]  ;piezas negras del juego

blancas-own[id] ;id`s blancas tienen un valor menor de 20
negras-own[id] ;id`s negras tienen un valor mayor de 20

patches-own [value] ; el id de la pieza

globals [turno]

; state: [content player]
;    - content: lista de id`s del tablero, con un total de 48 casillas: del 0 al 48
;         - 0 -> casilla vacia
;         - !0 -> id de la pieza

; rules: [id_pieza posIni posFin]
;     - id_pieza: id de la pieza en la posicion posIni
;     - posIni: posicion donde se encuentra la pieza
;     - posFin: posicion a la que se moverá la pieza


;=========================================================================================================================================================================================================================================================================
;=========================================================================================================================================================================================================================================================================
;=========================================================================================================================================================================================================================================================================

;STATE:

to-report MCTS:get-content [s] ;devuelve el tablero con las piezas
  report first s
end

to-report MCTS:get-playerJustMoved [s] ;devuelve el ultimo jugador que acaba de mover
  report last s
end

to-report MCTS:create-state [c p] ;siendo c una lista de listas y p el jugador
  report (list c p)
end

;=========================================================================================================================================================================================================================================================================
;=========================================================================================================================================================================================================================================================================
;=========================================================================================================================================================================================================================================================================

;RULES:

;MTCS:get-rules[s]: devuelve una lista con la posicion de la pieza y una lista de sus posibles movimientos, para todas las piezas de player
to-report MCTS:get-rules[s]
  let tablero MCTS:get-content s
  let jugador MCTS:get-playerJustMoved s

  let posiciones_piezas []
  ifelse(jugador = 1)[set posiciones_piezas filter [x -> (item x tablero) >= 20] (range 49)]
  [set posiciones_piezas filter [x -> (item x tablero) <= 20 and (item x tablero) > 0] (range 49)]

  let posibles_movimientos []
  foreach posiciones_piezas [
    pos ->
    if(pos >= 0 and pos <= 48)[
    let nuevos_movimientos quien_mueve pos tablero (3 - jugador)
    set posibles_movimientos sentence nuevos_movimientos posibles_movimientos
    ]
  ]
  report posibles_movimientos
end

;quien_mueve -> identifica el tipo de pieza para calcular sus posibles movimientos
to-report quien_mueve[pos tablero jugador]
  let pieza item pos tablero
  if(member? pieza (range 1 8) or member? pieza (range 21 28))[report mueve_peon pos tablero jugador]
  if(pieza = 11 or pieza = 12 or pieza = 31 or pieza = 32)[report mueve_alfil pos tablero jugador]
  if(pieza = 13 or pieza = 14 or pieza = 33 or pieza = 34)[report mueve_torre pos tablero jugador]
  if(pieza = 15 or pieza = 35)[report mueve_rey pos tablero jugador]

end

;=========================================================================================================================================================================================================================================================================
;=========================================================================================================================================================================================================================================================================

to-report mueve_peon[pos tablero jugador]
  let movs []
  let pieza item pos tablero

  ;si peon blanco
  if(member? pieza [1 2 3 4 5 6 7])[
    if(pieza_aqui? (pos - 7) tablero jugador = "null")[set movs fput (pos - 7) movs]
    if( (not member? pos [0 7 14 21 28 35 42]) and (pieza_aqui? (pos - 8) tablero jugador = "distinta") )[set movs fput (pos - 8) movs]
    if( (not member? pos [6 13 20 27 34 41 48]) and (pieza_aqui? (pos - 6) tablero jugador = "distinta") )[set movs fput (pos - 6) movs]
    ]

  ;si peon negro
  if(member? pieza [21 22 23 24 25 26 27])[
    if(pieza_aqui? (pos + 7) tablero jugador = "null")[set movs fput (pos + 7) movs]
    if( not member? pos [0 7 14 21 28 35 42] and pieza_aqui? (pos + 6) tablero jugador = "distinta" )[set movs fput (pos + 6) movs]
    if( not member? pos [6 13 20 27 34 41 48] and pieza_aqui? (pos + 8) tablero jugador = "distinta" )[set movs fput (pos + 8) movs]
    ]

  let id_pieza item pos tablero
  let res map[x -> (list id_pieza pos x)]movs
  report res
end

;=========================================================================================================================================================================================================================================================================
;=========================================================================================================================================================================================================================================================================

to-report mueve_rey[pos tablero jugador]
  let movs (list (pos - 8) (pos - 7) (pos - 6) (pos - 1) (pos + 1) (pos + 6) (pos + 7) (pos + 8)) ;los 8 movimientos posibles

  if(pos mod 7 = 0)[ ;si el rey esta en el lateral izquierdo del tablero
    set movs remove (pos - 1) movs
    set movs remove (pos + 6) movs
    set movs remove (pos - 8) movs
  ]
  if(pos mod 7 = 6)[ ;si el rey esta en el lateral derecho del tablero
    set movs remove (pos + 1) movs
    set movs remove (pos - 6) movs
    set movs remove (pos + 8) movs
  ]
  if(member? pos [0 1 2 3 4 5 6])[ ;si el rey esta en la parte inferior del tablero
    set movs remove (pos - 6) movs
    set movs remove (pos - 7) movs
    set movs remove (pos - 8) movs
  ]
  if(member? pos [42 43 44 45 46 47 48])[ ;si el rey esta en la parte superior del tablero
    set movs remove (pos + 6) movs
    set movs remove (pos + 7) movs
    set movs remove (pos + 8) movs
  ]

  ;filtro solo las posiciones en las que no hay ninguna pieza o hay una pieza enemiga
  let res1 filter [x -> pieza_aqui? x tablero jugador = "null"] movs;
  let res2 filter [x -> pieza_aqui? x tablero jugador = "distinta"] movs;


  let res sentence res1 res2
  ;-----------------------------------------------------------------------------------

  ;selecciono las posiciones a las que se pueden mover las piezas enemigas
  let warning get-rules_for_king tablero (jugador)

  let warning_aux []
  ;este get_rules devuelve (id_pieza posIni posFin), me quedo con el ultimo
  foreach warning [x ->
    let p last x
    set warning_aux fput p warning_aux
  ]

  let id_pieza item pos tablero

  set res filter[x -> not member? x warning_aux] res ;filtro de res las que no son miembro de warning_aux
  set res map[x -> (list id_pieza pos x)] res
  report res
end

;funcion get-rules-for-king, hace la misma funcion que MCTS:get-rules solo que llama a quien_mueve_aux
to-report get-rules_for_king[tablero jugador]

  let posiciones_piezas []
  ifelse(jugador = 1)[set posiciones_piezas filter [x -> (item x tablero) >= 20] (range 49)]
  [set posiciones_piezas filter [x -> (item x tablero) <= 20 and (item x tablero) > 0] (range 49)]

  let posibles_movimientos []
  foreach posiciones_piezas [
    pos ->
    if(pos >= 0 and pos <= 48)[
    let nuevos_movimientos quien_mueve_for_king pos tablero (jugador)
    set posibles_movimientos sentence nuevos_movimientos posibles_movimientos
    ]
  ]
  report posibles_movimientos
end
;----------------------------------------------------------------------------------------------------------------------------
;funcion quien_mueve para el rey, la diferencia esta en que llama a mueve_rey_aux y a mueve_peon_aux
to-report quien_mueve_for_king[pos tablero jugador]
  let pieza item pos tablero
  if(member? pieza (range 1 8) or member? pieza (range 21 28))[report mueve_peon_aux pos tablero jugador]
  if(pieza = 11 or pieza = 12 or pieza = 31 or pieza = 32)[report mueve_alfil pos tablero jugador]
  if(pieza = 13 or pieza = 14 or pieza = 33 or pieza = 34)[report mueve_torre pos tablero jugador]
  if(pieza = 15 or pieza = 35)[report mueve_rey_aux pos tablero jugador]

end
;-----------------------------------------------------------------------------------------------------------------------------
;funcion mueve_rey_aux, para que no entre en un bucle infinito
to-report mueve_rey_aux[pos tablero jugador]
 let movs (list (pos - 8) (pos - 7) (pos - 6) (pos - 1) (pos + 1) (pos + 6) (pos + 7) (pos + 8)) ;los 8 movimientos posibles

  if(pos mod 7 = 0)[ ;si el rey esta en el lateral izquierdo del tablero
    set movs remove (pos - 1) movs
    set movs remove (pos + 6) movs
    set movs remove (pos - 8) movs
  ]
  if(pos mod 7 = 6)[ ;si el rey esta en el lateral derecho del tablero
    set movs remove (pos + 1) movs
    set movs remove (pos - 6) movs
    set movs remove (pos + 8) movs
  ]
  if(member? pos (range 7))[ ;si el rey esta en la parte inferior del tablero
    set movs remove (pos - 6) movs
    set movs remove (pos - 7) movs
    set movs remove (pos - 8) movs
  ]
  if(member? pos (range 42 49))[ ;si el rey esta en la parte superior del tablero
    set movs remove (pos + 6) movs
    set movs remove (pos + 7) movs
    set movs remove (pos + 8) movs
  ]


  ;filtro solo las posiciones en las que no hay ninguna pieza o hay una pieza enemiga
  let res1 filter [x -> pieza_aqui? x tablero jugador = "null"] movs;
  let res2 filter [x -> pieza_aqui? x tablero jugador = "distinta"] movs;

  let res sentence res1 res2
  let id_pieza item pos tablero

  set res map[x -> (list id_pieza pos x)] res
  report res
end
;-----------------------------------------------------------------------------------------------------------------------------
;debido a que el peon solo puede comer en su diagonal, distinta a su movimiento me he visto forzado a crear esta funcion para el rey
to-report mueve_peon_aux[pos tablero jugador]
  let movs []
  let pieza item pos tablero

  ;si peon blanco
 if(member? pieza (range 1 8))[
    if(not member? pos [0 7 14 21 28 35 42])[set movs fput (pos - 8) movs]
    if(not member? pos [6 13 20 27 34 41 48])[set movs fput (pos - 6) movs]
    ]

  ;si peon negro
  if(member? pieza (range 11 18))[
    if(not member? pos [0 7 14 21 28 35 42])[set movs fput (pos + 6) movs]
    if(not member? pos [6 13 20 27 34 41 48])[set movs fput (pos + 8) movs]
    ]

  let id_pieza item pos tablero
  let res map[x -> (list id_pieza pos x)]movs
  report res
end

;====================================================================================================================================
;====================================================================================================================================

to-report mueve_torre[pos tablero jugador]

;====================================================================================================================================
; CALCULO PARA LAS FILAS:

  ;listas aux de ayuda
  let lista0 (range 7)
  let lista1 (range 7 14)
  let lista2 (range 14 21)
  let lista3 (range 21 28)
  let lista4 (range 28 35)
  let lista5 (range 35 42)
  let lista6 (range 42 49)

  ;en estos if calculo la fila por la que se puede mover la torre: (-3 -2 -1 0 +1 +2 +3)
  ;lista_fila_aux -> lista auxiliar para las filas, con el rango total de la fila
  let lista_fila_aux []
  if (member? pos lista0 = true) [set lista_fila_aux map [x -> (x - pos)] lista0]
  if (member? pos lista1 = true) [set lista_fila_aux map [x -> (x - pos)] lista1]
  if (member? pos lista2 = true) [set lista_fila_aux map [x -> (x - pos)] lista2]
  if (member? pos lista3 = true) [set lista_fila_aux map [x -> (x - pos)] lista3]
  if (member? pos lista4 = true) [set lista_fila_aux map [x -> (x - pos)] lista4]
  if (member? pos lista5 = true) [set lista_fila_aux map [x -> (x - pos)] lista5]
  if (member? pos lista6 = true) [set lista_fila_aux map [x -> (x - pos)] lista6]

  ;filtro de la lista hasta donde puede moverse la torre, dentro de su fila:

  let zero_fila position 0 lista_fila_aux ;posicion del 0 en lista_fila (donde esta la pieza)

  ;i,j -> las veces que recorro el bucle
  ;ii,jj -> variables aux para ir escalando en la lista_fila
  ;bool_i,bool_j -> booleanos parapoder salirme del bucle (condicion de parada)

  ;----------------------------------------------------------------------------------------------
  ;por la izquierda de zero
  let lista_fila1 [] ;lista de los movimientos posibles reales

  let i zero_fila
  let ii 1
  let bool_i true
  while[i > 0 and bool_i = true][
    if(pieza_aqui? (pos - ii) tablero jugador = "misma")[set bool_i false]
    if(pieza_aqui? (pos - ii) tablero jugador = "distinta")[
      set lista_fila1 fput (pos - ii) lista_fila1
      set bool_i false
    ]
    if(pieza_aqui? (pos - ii) tablero jugador = "null")[set lista_fila1 fput (pos - ii) lista_fila1]

    set ii (ii + 1)
    set i (i - 1)
  ]

  ;---------------------------------------------------------------------------------------------------
  ;por la derecha de zero
  let lista_fila2 []

  let j (6 - zero_fila)
  let jj 1
  let bool_j true
  while[j > 0 and bool_j = true][
    if(pieza_aqui? (pos + jj) tablero jugador = "misma")[set bool_j false]
    if(pieza_aqui? (pos + jj) tablero jugador = "distinta")[
      set lista_fila2 fput (pos + jj) lista_fila2
      set bool_j false
    ]
    if(pieza_aqui? (pos + jj) tablero jugador = "null")[set lista_fila2 fput (pos + jj) lista_fila2]

    set jj (jj + 1)
    set j (j - 1)
  ]
  let lista_fila sentence lista_fila1 lista_fila2
  ;====================================================================================================================================
  ; CALCULO PARA LAS COLUMNAS

  ;listas aux de ayuda
  let lista00 [0 7 14 21 28 35 42]
  let lista11 [1 8 15 22 29 36 43]
  let lista22 [2 9 16 23 30 37 44]
  let lista33 [3 10 17 24 31 38 45]
  let lista44 [4 11 18 25 32 39 46]
  let lista55 [5 12 19 26 33 40 47]
  let lista66 [6 13 20 27 34 41 48]

  ;en estos if calculo la columna por la que se puede mover la torre: (-15 -10 -5 0 +5)
  ;lista_columna_aux -> lista auxiliar para las columnas, con el rango total de la columna
  let lista_columna_aux []
  if (member? pos lista00 = true) [set lista_columna_aux map [x -> (x - pos)] lista00]
  if (member? pos lista11 = true) [set lista_columna_aux map [x -> (x - pos)] lista11]
  if (member? pos lista22 = true) [set lista_columna_aux map [x -> (x - pos)] lista22]
  if (member? pos lista33 = true) [set lista_columna_aux map [x -> (x - pos)] lista33]
  if (member? pos lista44 = true) [set lista_columna_aux map [x -> (x - pos)] lista44]
  if (member? pos lista55 = true) [set lista_columna_aux map [x -> (x - pos)] lista55]
  if (member? pos lista66 = true) [set lista_columna_aux map [x -> (x - pos)] lista66]

  let zero_columna position 0 lista_columna_aux ;posicion del 0 en lista_columna_aux (donde esta la pieza)

  ;k,l -> las veces que recorro el bucle
  ;kk,ll -> variables aux para ir escalando en la lista_columna
  ;bool_k,bool_l -> booleanos para poder salirme del bucle (condicion de parada)

  ;---------------------------------------------------------------------------------------------------
  ;por la izquierda de zero
  let lista_columna1 [] ;lista de los movimientos posibles reales

  let k (zero_columna - 0)
  let kk 7
  let bool_k true
  while[k > 0 and bool_k = true][
    if(pieza_aqui? (pos - kk) tablero jugador = "misma")[set bool_k false]
    if(pieza_aqui? (pos - kk) tablero jugador = "distinta")[
      set lista_columna1 fput (pos - kk) lista_columna1
      set bool_k false
    ]
    if(pieza_aqui? (pos - kk) tablero jugador = "null")[set lista_columna1 fput (pos - kk) lista_columna1]

    set kk (kk + 7)
    set k (k - 1)
  ]
  ;---------------------------------------------------------------------------------------------------
  ;por la derecha de zero
  let lista_columna2 []
  let l (6 - zero_columna)
  let ll 7
  let bool_l true
  while[l > 0 and bool_l = true][
    if(pieza_aqui? (pos + ll) tablero jugador = "misma")[set bool_l false]
    if(pieza_aqui? (pos + ll) tablero jugador = "distinta")[
      set lista_columna2 fput (pos + ll) lista_columna2
      set bool_l false
    ]
    if(pieza_aqui? (pos + ll) tablero jugador = "null")[set lista_columna2 fput (pos + ll) lista_columna2]

    set ll (ll + 7)
    set l (l - 1)
  ]
  let lista_columna sentence lista_columna1 lista_columna2

  let id_pieza item pos tablero
  let lista_total sentence lista_fila lista_columna
  let res map[x -> (list id_pieza pos x)] lista_total
  report res

end

to-report mueve_alfil[pos tablero jugador]

  ;estas funciones te dicen cuantas veces se va a mover la pieza para cada diagonal
  let aux_mas_ocho mueve_alfil_aux_1 pos tablero jugador ;diagonal arriba derecha
  let aux_mas_seis mueve_alfil_aux_2 pos tablero jugador ;diagonal arriba izquierda
  let aux_menos_ocho mueve_alfil_aux_3 pos tablero jugador ;diagonal abajo izquierda
  let aux_menos_seis mueve_alfil_aux_4 pos tablero jugador ;diagonal abajo derecha
  ;-------------------------------------------------------------
  let movs_1 []
  let bool_1 true
  let m_1 8
  while[aux_mas_ocho > 0 and bool_1 = true][
    if(pieza_aqui? (pos + m_1) tablero jugador = "misma")[set bool_1 false]
    if(pieza_aqui? (pos + m_1) tablero jugador = "distinta")[
      set movs_1 fput (pos + m_1) movs_1
      set bool_1 false
    ]
    if(pieza_aqui? (pos + m_1) tablero jugador = "null")[set movs_1 fput (pos + m_1) movs_1]

    set m_1 (m_1 + 8)
    set aux_mas_ocho (aux_mas_ocho - 1)
  ]
  ;-------------------------------------------------------------
  let movs_2 []
  let bool_2 true
  let m_2 6
  while[aux_mas_seis > 0 and bool_2 = true][
    if(pieza_aqui? (pos + m_2) tablero jugador = "misma")[set bool_2 false]
    if(pieza_aqui? (pos + m_2) tablero jugador = "distinta")[
      set movs_2 fput (pos + m_2) movs_2
      set bool_2 false
    ]
    if(pieza_aqui? (pos + m_2) tablero jugador = "null")[set movs_2 fput (pos + m_2) movs_2]

    set m_2 (m_2 + 6)
    set aux_mas_seis (aux_mas_seis - 1)
  ]
  ;-------------------------------------------------------------
  let movs_3 []
  let bool_3 true
  let m_3 8
  while[aux_menos_ocho > 0 and bool_3 = true][
    if(pieza_aqui? (pos - m_3) tablero jugador = "misma")[set bool_3 false]
    if(pieza_aqui? (pos - m_3) tablero jugador = "distinta")[
      set movs_3 fput (pos - m_3) movs_3
      set bool_3 false
    ]
    if(pieza_aqui? (pos - m_3) tablero jugador = "null")[set movs_3 fput (pos - m_3) movs_3]

    set m_3 (m_3 + 8)
    set aux_menos_ocho (aux_menos_ocho - 1)
  ]
  ;-------------------------------------------------------------
  let movs_4 []
  let bool_4 true
  let m_4 6
  while[aux_menos_seis > 0 and bool_4 = true][
   if(pieza_aqui? (pos - m_4) tablero jugador = "misma")[set bool_4 false]
    if(pieza_aqui? (pos - m_4) tablero jugador = "distinta")[
      set movs_4 fput (pos - m_4) movs_4
      set bool_4 false
    ]
    if(pieza_aqui? (pos - m_4) tablero jugador = "null")[set movs_4 fput (pos - m_4) movs_4]

    set m_4 (m_4 + 6)
    set aux_menos_seis (aux_menos_seis - 1)
  ]
  ;-------------------------------------------------------------

  let id_pieza item pos tablero
  let movs (sentence movs_1 movs_2 movs_3 movs_4)
  let res map[x -> (list id_pieza pos x)] movs
  report res
end

;====================================================================================================================================
;====================================================================================================================================
;====================================================================================================================================

;APPLY:

to-report MCTS:apply [r s]  ;[regla estado]

  let tablero MCTS:get-content s
  let jugador MCTS:get-playerJustMoved s

  let id_pieza first r
  let posiciones but-first r
  let posIni first posiciones
  let posFin last posiciones

  let res replace-item posFin tablero id_pieza
  set res replace-item posIni res 0

  report MCTS:create-state (res) (3 - jugador)

end
;====================================================================================================================================
;====================================================================================================================================
;====================================================================================================================================

;GET-RESULT:

to-report MCTS:get-result [s p] ; resultado para un jugador determinado

  let tablero MCTS:get-content s
  let jugador MCTS:get-playerJustMoved s

  ;si los reyes de p1 y p2 estan en el tablero, p1 y p2 = 1
  let p1 0
  let p2 0
  ;las posiciones de los reyes de p1 y p2
  let posp1 nobody
  let posp2 nobody
  ;cuenta_piezas cuenta el numero de piezas del tablero, si es igual a dos, entonces tenemos tablas
  let cuenta_piezas 0
  let cuenta_piezas_blancas 0
  let cuenta_piezas_negras 0

    foreach tablero[
    x ->
    if(x > 0 and x <= 20)[set cuenta_piezas_blancas (cuenta_piezas_blancas + 1)]
    if(x > 10)[set cuenta_piezas_negras (cuenta_piezas_negras + 1)]
    ;if(x > 0)[set cuenta_piezas (cuenta_piezas + 1)]

    if(x = 35)[
      set p2 1
      set posp2 x
    ]
    if(x = 15)[
      set p1 1
      set posp1 x
    ]
  ]
  ;report (list p1 p2 posp1 posp2 cuenta_piezas t1)
  ;compruebo si rey ahogado

 ; if(posp1 != nobody)[
   ; let movsp1 mueve_rey posp1 tablero 1
  ;  if(empty? movsp1) [report 0.5]
;  ]

 ; if(posp2 != nobody)[
  ;  let movsp2 mueve_rey posp2 tablero 2
  ;  if(empty? movsp2) [report 0.5]
 ; ]
  set cuenta_piezas (cuenta_piezas_blancas + cuenta_piezas_negras)

  if((p1 = p2) and (cuenta_piezas > 2) and (cuenta_piezas_blancas = cuenta_piezas_negras))[report 0.55]
  if((p1 = p2) and (cuenta_piezas > 2) and (cuenta_piezas_blancas > cuenta_piezas_negras))[report 0.3]
  if((p1 = p2) and (cuenta_piezas > 2) and (cuenta_piezas_blancas < cuenta_piezas_negras))[report 0.7]
  if((p1 = p2) and (cuenta_piezas <= 2))[report 0.5] ;devuelve tablas si solo quedan los dos reyes vivos

  ;si no estan los dos reyes vivos:
  if(p = 1 and p1 > p2)[report 1]
  if(p = 1 and p1 < p2)[report 0]
  if(p = 2 and p2 > p1)[report 1]
  if(p = 2 and p2 < p1)[report 0]

end




;---------------------------------------------------------------------------------------------
;INTERFAZ

to start

  ca
  ask patches with [pxcor < 7][
    set pcolor ifelse-value (pxcor + pycor) mod 2 = 0 [yellow][brown]
  ]


  ; SETUP PIECES

  let blancas-id [1 2 3 4 5 6 7 11 12 13 14 15]
  ;let blancas-valor [1 5 100]
  ;let blancas-player [1 2]

  let negras-id [21 22 23 24 25 26 27 31 32 33 34 35]
  ;let negras-valor [1 5 100]
  ;let negras-player [1 2]


  let i 0
  let val_id_blancas 1
  while[i < 7][
    create-blancas 1[
      set id val_id_blancas
      set color white
      set shape "chess pawn"
      move-to one-of patches with [not any? blancas-here and pxcor = i and pycor = 1]
      ask patches with[pxcor = i and pycor = 1] [set value val_id_blancas]
      set i (i + 1)
      set val_id_blancas (val_id_blancas + 1)
    ]
  ]

  let j 0
  let val_id_negras 21
  while[j < 7][
    create-negras 1[
      set id val_id_negras
      set color black
      set shape "chess pawn"
      move-to one-of patches with [not any? negras-here and pxcor = j and pycor = 5]
      ask patches with[pxcor = j and pycor = 3] [set value val_id_negras]
      set j (j + 1)
      set val_id_negras (val_id_negras + 1)
    ]
  ]

  create-blancas 1[
     set id 11
      set color white
      set shape "chess bishop"
      move-to one-of patches with [pxcor = 2 and pycor = 0]
      ask patches with[pxcor = 0 and pycor = 0] [set value 11]
    ]

  create-blancas 1[
      set id 12
      set color white
      set shape "chess bishop"
      move-to one-of patches with [pxcor = 5 and pycor = 0]
      ask patches with[pxcor = 4 and pycor = 0] [set value 12]
    ]

  create-blancas 1[
      set id 13
      set color white
      set shape "chess rook"
      move-to one-of patches with [pxcor = 0 and pycor = 0]
      ask patches with[pxcor = 0 and pycor = 0] [set value 13]
    ]

  create-blancas 1[
      set id 14
      set color white
      set shape "chess rook"
      move-to one-of patches with [pxcor = 6 and pycor = 0]
      ask patches with[pxcor = 4 and pycor = 0] [set value 14]

    ]


   create-negras 1[
      set id 31
      set color black
      set shape "chess bishop"
      move-to one-of patches with [pxcor = 1 and pycor = 6]
      ask patches with[pxcor = 0 and pycor = 4] [set value 31]
    ]
  create-negras 1[

      set id 32
      set color black
      set shape "chess bishop"
      move-to one-of patches with [pxcor = 4 and pycor = 6]
      ask patches with[pxcor = 4 and pycor = 4] [set value 32]
    ]

   create-negras 1[
      set id 33
      set color black
      set shape "chess rook"
      move-to one-of patches with [pxcor = 0 and pycor = 6]
      ask patches with[pxcor = 0 and pycor = 4] [set value 33]
    ]
  create-negras 1[

      set id 34
      set color black
      set shape "chess rook"
      move-to one-of patches with [pxcor = 6 and pycor = 6]
      ask patches with[pxcor = 4 and pycor = 4] [set value 34]
    ]


    create-blancas 1[
      set id 15
      set color white
      set shape "chess king"
      move-to one-of patches with [pxcor = 3 and pycor = 0]
    ask patches with[pxcor = 2 and pycor = 0] [set value 15]
    ]
  create-negras 1[
      set id 35
      set color black
      set shape "chess king"
      move-to one-of patches with [pxcor = 3 and pycor = 6]
    ask patches with[pxcor = 2 and pycor = 4] [set value 35]
  ]

actualizarTablero
end



to play

  let p nobody
  let oldPos nobody
  let newPos nobody

  actualizarTablero
  ;---------------------------------------------------------------------------------------
  ; Empieza jugando el humano

  set turno "blancas"
  if turno = "blancas"[

  if mouse-down?[
    if (any? blancas-on patch mouse-xcor mouse-ycor) [

      set p one-of blancas-on patch mouse-xcor mouse-ycor
      set oldPos patch mouse-xcor mouse-ycor

      while [mouse-down?][
        ask p [setxy mouse-xcor mouse-ycor]
        set newPos patch mouse-xcor mouse-ycor
      ]
      wait .3

      ask p [
        ;si no hay ninguna pieza en esa posicion:
          ifelse(any? other blancas-on newPos)[move-to oldPos]
          [
            ifelse(not any? other blancas-on newPos and not any? other negras-on newPos) [
              move-to newPos
              set value id
              actualizarTablero
              set turno "negras"
              show oldPos
              show newPos
              output-print "mueven negras"
            ]
            [
              ask negras-on newPos[die]
              move-to newPos
              set value id
              actualizarTablero
              set turno "negras"
              show oldPos
              show newPos
              output-print "mueven negras"
            ]
          ]
        ]
      ]

    ; espera
    wait .5
    ; jugador 1 acaba de mover
    ; comprobar si es estado final
      show (list (board-to-state))
    let result_for_1 MCTS:get-result (list (board-to-state) 1) 1
    ; 1 si jugador 1 ha ganado
    if result_for_1 = 1 [
      user-message "You win!!!"
      stop
    ]
     ;0.5 si tablas
    if result_for_1 = 0.5 [
      user-message "Draw!!!"
      stop
    ]
     ;si rey ahogado
    ;if result_for_1 = 0 [
    ;  user-message "Drowned!!!, I win"
   ;   stop
   ; ]
  ]
]
  ; turno de jugar a la IA
  if turno = "negras" [
    let tempo timer
    ;show (list (board-to-state))
    ;show Max_iterations
    let m MCTS:UCT (list (board-to-state) 1) Max_iterations
    show timer - tempo

    let id_pieza first m ;posicion de la lista del elemento a mover
    let posiciones but-first m

    let posIni convierte_aPatch first posiciones
    let posIniX first posIni
    let posIniY last posIni

    let posFin convierte_aPatch last posiciones
    let posFinX first posFin
    let posFinY last posFin

    ; Make the move and update the board
    ask one-of negras with [id = id_pieza]
    [
      move-to patch posFinX posFinY
      actualizarTablero
      set value id
      set turno "blancas"
      ask blancas with[xcor = posFinX and ycor = posFinY ][die]
      show posIni
      show posFin
      output-print "mueven blancas"
    ]
    ; Player 2 has just played
    ; check if the current content is winner for the machine
    let result_for_2 MCTS:get-result (list (board-to-state) 2) 2
    if result_for_2 = 1 [
      user-message "I win!!!"
      stop
    ]
    ; 0.5 si tablas
    if result_for_2 = 0.5 [
      user-message "Draw!!!"
      stop
    ]
    ; 0 si rey ahogado
  ;  if result_for_2 = 0 [
  ;    user-message "Drowned!!!, You Win"
   ;   stop
   ; ]
  ]
  ; The cycle starts again...

end
;--------------------------------------------------------------------
;FUNCIONES AUXILIARES

;funcion auxiliar para los posibles movimientos
to-report pieza_aqui?[pos tablero jugador]
  ifelse(member? pos (range 49))[
    let pieza item pos tablero
    if(((jugador = 1) and (pieza > 0) and (pieza < 20)) or ((jugador = 2) and (pieza >= 20))) [ report "misma" ]
    ifelse(((jugador = 2) and (pieza > 0) and (pieza < 20))) or (((jugador = 1) and (pieza >= 20))) [ report "distinta" ]
  [ report "null" ]
  ][report false]
end

to actualizarTablero
  ask patches with [any? blancas-on patch pxcor pycor] [
    let id_pieza [id] of blancas-on patch pxcor pycor
    set value first id_pieza
    set plabel value
  ]
   ask patches with [any? negras-on patch pxcor pycor] [
    let id_pieza [id] of negras-on patch pxcor pycor
    set value first id_pieza
    set plabel value
  ]
  ask patches with [not any? blancas-on patch pxcor pycor and not any? negras-on patch pxcor pycor] [
    set value 0
    set plabel value
  ]end

to-report convierte_aPatch[n]
  let x nobody
  let y nobody

  if(member? n (range 7))[set y 6]
  if(member? n (range 7 14))[set y 5]
  if(member? n (range 14 21))[set y 4]
  if(member? n (range 21 28))[set y 3]
  if(member? n (range 28 35))[set y 2]
  if(member? n (range 35 42))[set y 1]
  if(member? n (range 42 49))[set y 0]

  if(n mod 7 = 0)[set x 0]
  if(n mod 7 = 1)[set x 1]
  if(n mod 7 = 2)[set x 2]
  if(n mod 7 = 3)[set x 3]
  if(n mod 7 = 4)[set x 4]
  if(n mod 7 = 5)[set x 5]
  if(n mod 7 = 6)[set x 6]

  report (list x y)

end

to-report board-to-state
  let b map [x -> [value] of x ] (sort patches)
  report b

end

to-report mueve_alfil_aux_1 [pos tablero jugador]

  let i_mas_ocho nobody

   if(pos mod 7 = 0)[
    if(member? pos (range 7))[set i_mas_ocho 6]
    if(member? pos (range 7 14))[set i_mas_ocho 5]
    if(member? pos (range 14 21))[set i_mas_ocho 4]
    if(member? pos (range 21 28))[set i_mas_ocho 3]
    if(member? pos (range 28 35))[set i_mas_ocho 2]
    if(member? pos (range 35 42))[set i_mas_ocho 1]
    if(member? pos (range 42 49))[set i_mas_ocho 0]
    ]
  if(pos mod 7 = 1)[
    if(member? pos (range 7))[set i_mas_ocho 5]
    if(member? pos (range 7 14))[set i_mas_ocho 5]
    if(member? pos (range 14 21))[set i_mas_ocho 4]
    if(member? pos (range 21 28))[set i_mas_ocho 3]
    if(member? pos (range 28 35))[set i_mas_ocho 2]
    if(member? pos (range 35 42))[set i_mas_ocho 1]
    if(member? pos (range 42 49))[set i_mas_ocho 0]
  ]
  if(pos mod 7 = 2)[
     if(member? pos (range 7))[set i_mas_ocho 4]
    if(member? pos (range 7 14))[set i_mas_ocho 4]
    if(member? pos (range 14 21))[set i_mas_ocho 4]
    if(member? pos (range 21 28))[set i_mas_ocho 3]
    if(member? pos (range 28 35))[set i_mas_ocho 2]
    if(member? pos (range 35 42))[set i_mas_ocho 1]
    if(member? pos (range 42 49))[set i_mas_ocho 0]
  ]
  if(pos mod 7 = 3)[
     if(member? pos (range 7))[set i_mas_ocho 3]
    if(member? pos (range 7 14))[set i_mas_ocho 3]
    if(member? pos (range 14 21))[set i_mas_ocho 3]
    if(member? pos (range 21 28))[set i_mas_ocho 3]
    if(member? pos (range 28 35))[set i_mas_ocho 2]
    if(member? pos (range 35 42))[set i_mas_ocho 1]
    if(member? pos (range 42 49))[set i_mas_ocho 0]
  ]
  if(pos mod 7 = 4)[
    if(member? pos (range 7))[set i_mas_ocho 2]
    if(member? pos (range 7 14))[set i_mas_ocho 2]
    if(member? pos (range 14 21))[set i_mas_ocho 2]
    if(member? pos (range 21 28))[set i_mas_ocho 2]
    if(member? pos (range 28 35))[set i_mas_ocho 2]
    if(member? pos (range 35 42))[set i_mas_ocho 1]
    if(member? pos (range 42 49))[set i_mas_ocho 0]
  ]
  if(pos mod 7 = 5)[
    if(member? pos (range 7))[set i_mas_ocho 1]
    if(member? pos (range 7 14))[set i_mas_ocho 1]
    if(member? pos (range 14 21))[set i_mas_ocho 1]
    if(member? pos (range 21 28))[set i_mas_ocho 1]
    if(member? pos (range 28 35))[set i_mas_ocho 1]
    if(member? pos (range 35 42))[set i_mas_ocho 1]
    if(member? pos (range 42 49))[set i_mas_ocho 0]
  ]
  if(pos mod 7 = 6)[set i_mas_ocho 0]

  report i_mas_ocho
end

to-report mueve_alfil_aux_2 [pos tablero jugador]

  let i_mas_seis nobody

   if(pos mod 7 = 6)[
    if(member? pos (range 7))[set i_mas_seis 6]
    if(member? pos (range 7 14))[set i_mas_seis 5]
    if(member? pos (range 14 21))[set i_mas_seis 4]
    if(member? pos (range 21 28))[set i_mas_seis 3]
    if(member? pos (range 28 35))[set i_mas_seis 2]
    if(member? pos (range 35 42))[set i_mas_seis 1]
    if(member? pos (range 42 49))[set i_mas_seis 0]
    ]
  if(pos mod 7 = 5)[
    if(member? pos (range 7))[set i_mas_seis 5]
    if(member? pos (range 7 14))[set i_mas_seis 5]
    if(member? pos (range 14 21))[set i_mas_seis 4]
    if(member? pos (range 21 28))[set i_mas_seis 3]
    if(member? pos (range 28 35))[set i_mas_seis 2]
    if(member? pos (range 35 42))[set i_mas_seis 1]
    if(member? pos (range 42 49))[set i_mas_seis 0]
  ]
  if(pos mod 7 = 4)[
     if(member? pos (range 7))[set i_mas_seis 4]
    if(member? pos (range 7 14))[set i_mas_seis 4]
    if(member? pos (range 14 21))[set i_mas_seis 4]
    if(member? pos (range 21 28))[set i_mas_seis 3]
    if(member? pos (range 28 35))[set i_mas_seis 2]
    if(member? pos (range 35 42))[set i_mas_seis 1]
    if(member? pos (range 42 49))[set i_mas_seis 0]
  ]
  if(pos mod 7 = 3)[
     if(member? pos (range 7))[set i_mas_seis 3]
    if(member? pos (range 7 14))[set i_mas_seis 3]
    if(member? pos (range 14 21))[set i_mas_seis 3]
    if(member? pos (range 21 28))[set i_mas_seis 3]
    if(member? pos (range 28 35))[set i_mas_seis 2]
    if(member? pos (range 35 42))[set i_mas_seis 1]
    if(member? pos (range 42 49))[set i_mas_seis 0]
  ]
  if(pos mod 7 = 2)[
    if(member? pos (range 7))[set i_mas_seis 2]
    if(member? pos (range 7 14))[set i_mas_seis 2]
    if(member? pos (range 14 21))[set i_mas_seis 2]
    if(member? pos (range 21 28))[set i_mas_seis 2]
    if(member? pos (range 28 35))[set i_mas_seis 2]
    if(member? pos (range 35 42))[set i_mas_seis 1]
    if(member? pos (range 42 49))[set i_mas_seis 0]
  ]
  if(pos mod 7 = 1)[
    if(member? pos (range 7))[set i_mas_seis 1]
    if(member? pos (range 7 14))[set i_mas_seis 1]
    if(member? pos (range 14 21))[set i_mas_seis 1]
    if(member? pos (range 21 28))[set i_mas_seis 1]
    if(member? pos (range 28 35))[set i_mas_seis 1]
    if(member? pos (range 35 42))[set i_mas_seis 1]
    if(member? pos (range 42 49))[set i_mas_seis 0]
  ]
  if(pos mod 7 = 0)[set i_mas_seis 0]

  report i_mas_seis
end

to-report mueve_alfil_aux_3 [pos tablero jugador]

  let i_menos_ocho nobody

   if(pos mod 7 = 6)[
    if(member? pos (range 7))[set i_menos_ocho 0]
    if(member? pos (range 7 14))[set i_menos_ocho 1]
    if(member? pos (range 14 21))[set i_menos_ocho 2]
    if(member? pos (range 21 28))[set i_menos_ocho 3]
    if(member? pos (range 28 35))[set i_menos_ocho 4]
    if(member? pos (range 35 42))[set i_menos_ocho 5]
    if(member? pos (range 42 49))[set i_menos_ocho 6]
    ]
  if(pos mod 7 = 5)[
    if(member? pos (range 7))[set i_menos_ocho 0]
    if(member? pos (range 7 14))[set i_menos_ocho 1]
    if(member? pos (range 14 21))[set i_menos_ocho 2]
    if(member? pos (range 21 28))[set i_menos_ocho 3]
    if(member? pos (range 28 35))[set i_menos_ocho 4]
    if(member? pos (range 35 42))[set i_menos_ocho 5]
    if(member? pos (range 42 49))[set i_menos_ocho 5]
  ]
  if(pos mod 7 = 4)[
    if(member? pos (range 7))[set i_menos_ocho 0]
    if(member? pos (range 7 14))[set i_menos_ocho 1]
    if(member? pos (range 14 21))[set i_menos_ocho 2]
    if(member? pos (range 21 28))[set i_menos_ocho 3]
    if(member? pos (range 28 35))[set i_menos_ocho 4]
    if(member? pos (range 35 42))[set i_menos_ocho 4]
    if(member? pos (range 42 49))[set i_menos_ocho 4]
  ]
  if(pos mod 7 = 3)[
    if(member? pos (range 7))[set i_menos_ocho 0]
    if(member? pos (range 7 14))[set i_menos_ocho 1]
    if(member? pos (range 14 21))[set i_menos_ocho 2]
    if(member? pos (range 21 28))[set i_menos_ocho 3]
    if(member? pos (range 28 35))[set i_menos_ocho 3]
    if(member? pos (range 35 42))[set i_menos_ocho 3]
    if(member? pos (range 42 49))[set i_menos_ocho 3]
  ]
  if(pos mod 7 = 2)[
    if(member? pos (range 7))[set i_menos_ocho 0]
    if(member? pos (range 7 14))[set i_menos_ocho 1]
    if(member? pos (range 14 21))[set i_menos_ocho 2]
    if(member? pos (range 21 28))[set i_menos_ocho 2]
    if(member? pos (range 28 35))[set i_menos_ocho 2]
    if(member? pos (range 35 42))[set i_menos_ocho 2]
    if(member? pos (range 42 49))[set i_menos_ocho 2]
  ]
  if(pos mod 7 = 1)[
    if(member? pos (range 7))[set i_menos_ocho 0]
    if(member? pos (range 7 14))[set i_menos_ocho 1]
    if(member? pos (range 14 21))[set i_menos_ocho 1]
    if(member? pos (range 21 28))[set i_menos_ocho 1]
    if(member? pos (range 28 35))[set i_menos_ocho 1]
    if(member? pos (range 35 42))[set i_menos_ocho 1]
    if(member? pos (range 42 49))[set i_menos_ocho 1]
  ]
  if(pos mod 7 = 0)[set i_menos_ocho 0]

  report i_menos_ocho
end

to-report mueve_alfil_aux_4 [pos tablero jugador]

   let i_menos_seis nobody

   if(pos mod 7 = 0)[
    if(member? pos (range 7))[set i_menos_seis 0]
    if(member? pos (range 7 14))[set i_menos_seis 1]
    if(member? pos (range 14 21))[set i_menos_seis 2]
    if(member? pos (range 21 28))[set i_menos_seis 3]
    if(member? pos (range 28 35))[set i_menos_seis 4]
    if(member? pos (range 35 42))[set i_menos_seis 5]
    if(member? pos (range 42 49))[set i_menos_seis 6]
    ]
  if(pos mod 7 = 1)[
    if(member? pos (range 7))[set i_menos_seis 0]
    if(member? pos (range 7 14))[set i_menos_seis 1]
    if(member? pos (range 14 21))[set i_menos_seis 2]
    if(member? pos (range 21 28))[set i_menos_seis 3]
    if(member? pos (range 28 35))[set i_menos_seis 4]
    if(member? pos (range 35 42))[set i_menos_seis 5]
    if(member? pos (range 42 49))[set i_menos_seis 5]
  ]
  if(pos mod 7 = 2)[
    if(member? pos (range 7))[set i_menos_seis 0]
    if(member? pos (range 7 14))[set i_menos_seis 1]
    if(member? pos (range 14 21))[set i_menos_seis 2]
    if(member? pos (range 21 28))[set i_menos_seis 3]
    if(member? pos (range 28 35))[set i_menos_seis 4]
    if(member? pos (range 35 42))[set i_menos_seis 4]
    if(member? pos (range 42 49))[set i_menos_seis 4]
  ]
  if(pos mod 7 = 3)[
    if(member? pos (range 7))[set i_menos_seis 0]
    if(member? pos (range 7 14))[set i_menos_seis 1]
    if(member? pos (range 14 21))[set i_menos_seis 2]
    if(member? pos (range 21 28))[set i_menos_seis 3]
    if(member? pos (range 28 35))[set i_menos_seis 3]
    if(member? pos (range 35 42))[set i_menos_seis 3]
    if(member? pos (range 42 49))[set i_menos_seis 3]
  ]
  if(pos mod 7 = 4)[
    if(member? pos (range 7))[set i_menos_seis 0]
    if(member? pos (range 7 14))[set i_menos_seis 1]
    if(member? pos (range 14 21))[set i_menos_seis 2]
    if(member? pos (range 21 28))[set i_menos_seis 2]
    if(member? pos (range 28 35))[set i_menos_seis 2]
    if(member? pos (range 35 42))[set i_menos_seis 2]
    if(member? pos (range 42 49))[set i_menos_seis 2]
  ]
  if(pos mod 7 = 5)[
    if(member? pos (range 7))[set i_menos_seis 0]
    if(member? pos (range 7 14))[set i_menos_seis 1]
    if(member? pos (range 14 21))[set i_menos_seis 1]
    if(member? pos (range 21 28))[set i_menos_seis 1]
    if(member? pos (range 28 35))[set i_menos_seis 1]
    if(member? pos (range 35 42))[set i_menos_seis 1]
    if(member? pos (range 42 49))[set i_menos_seis 1]
  ]
  if(pos mod 7 = 6)[set i_menos_seis 0]

  report i_menos_seis

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
778
579
-1
-1
80.0
1
10
1
1
1
0
1
1
1
0
6
0
6
0
0
1
ticks
30.0

BUTTON
25
70
88
103
start
start
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
35
166
98
199
play
play
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
21
260
193
293
Max_iterations
Max_iterations
0
1000
2.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

chess bishop
false
0
Circle -7500403 true true 135 35 30
Circle -16777216 false false 135 35 30
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 105 255 120 165 180 165 195 255
Polygon -16777216 false false 105 255 120 165 180 165 195 255
Rectangle -7500403 true true 105 165 195 150
Rectangle -16777216 false false 105 150 195 165
Line -16777216 false 137 59 162 59
Polygon -7500403 true true 135 60 120 75 120 105 120 120 105 120 105 90 90 105 90 120 90 135 105 150 195 150 210 135 210 120 210 105 195 90 165 60
Polygon -16777216 false false 135 60 120 75 120 120 105 120 105 90 90 105 90 135 105 150 195 150 210 135 210 105 165 60

chess king
false
0
Polygon -7500403 true true 105 255 120 90 180 90 195 255
Polygon -16777216 false false 105 255 120 90 180 90 195 255
Polygon -7500403 true true 120 85 105 40 195 40 180 85
Polygon -16777216 false false 119 85 104 40 194 40 179 85
Rectangle -7500403 true true 105 105 195 75
Rectangle -16777216 false false 105 75 195 105
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Rectangle -7500403 true true 165 23 134 13
Rectangle -7500403 true true 144 0 154 44
Polygon -16777216 false false 153 0 144 0 144 13 133 13 133 22 144 22 144 41 154 41 154 22 165 22 165 12 153 12

chess pawn
false
0
Circle -7500403 true true 105 65 90
Circle -16777216 false false 105 65 90
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 105 255 120 165 180 165 195 255
Polygon -16777216 false false 105 255 120 165 180 165 195 255
Rectangle -7500403 true true 105 165 195 150
Rectangle -16777216 false false 105 150 195 165

chess rook
false
0
Rectangle -7500403 true true 90 255 210 300
Line -16777216 false 75 255 225 255
Rectangle -16777216 false false 90 255 210 300
Polygon -7500403 true true 90 255 105 105 195 105 210 255
Polygon -16777216 false false 90 255 105 105 195 105 210 255
Rectangle -7500403 true true 75 90 120 60
Rectangle -7500403 true true 75 84 225 105
Rectangle -7500403 true true 135 90 165 60
Rectangle -7500403 true true 180 90 225 60
Polygon -16777216 false false 90 105 75 105 75 60 120 60 120 84 135 84 135 60 165 60 165 84 179 84 180 60 225 60 225 105

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
