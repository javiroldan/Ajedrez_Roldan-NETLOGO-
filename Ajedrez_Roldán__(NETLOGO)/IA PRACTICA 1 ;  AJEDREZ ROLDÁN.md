# IA: PRACTICA 1 ;  AJEDREZ ROLDÁN

##### -  <u>Introducción</u>:  

Durante este tiempo he estado trabajando en un miniajedrez con 25 casillas (5x5) enumeradas en una lista del 0 al 24 con 5 peones, 2 torres y el rey por cada jugador

Mi intención era aumentar el tamaño del tablero y las piezas a medida que consiguiera hacer funcionar el miniajedrez, cosas que no ha ido particularmente bien.

El segundo proyecto llamado chess_expanded es un tablero de 7x7 (49 casillas)  con las mismas piezas que el miniajedrez pero añadiendo dos alfiles para cada jugador



- ### JUEGO:

###### - Voy a comenzar explicando las piezas: 

​	Las piezas se identifican por un id (de tipo numérico) .

​	Tenemos dos tipos de razas de piezas, blancas y negras; Las piezas blancas tienen ids menores a 10 y las 	negras tienen ids con un valor mayor a 10:

​	PIEZAS BLANCAS: [peones:  -1 2 3 4 5-]  [torres:-6 7-] [rey:-9-]

​	PIEZAS BLANCAS: [peones:  -11 12 13 14 15-]  [torres:-16 17-] [rey:-19-]

<!--para el chess_expanded las piezas blancas tienen id´s menores a 20 y las negras id´s mayores a 20  (mismo estilo al minichess) -->

​	Los patches reflejan el id de la pieza que tienen encima.

### - ALGORITMO: MONTECARLOS:

​	Para poder usar el algoritmo de montecarlos ( dado por el profesor Fernando Sancho Caparrini) como 	   	mínimo es necesario disponer de 3 funciones: MCTS:get-rules, MCTS:apply y MCTS:get-result, a parte de 	tener una función para crear un nuevo estado: MCTS:create-state

​	En el ajedrez roldan, un estado esta formado por una lista en el rango de las casillas con sus id`s y el 	     	jugador que ha formado ese estado.

<!--para traducir la práctica iré explicando estas funciones a la vez que sus respectivas funciones auxiliares según el orden en el que se vayan llamando-->

#### - FUNCIÓN **<u>MCTS:GET-RULES</u>** :

Inicialmente recorro la lista de las id´s para quedarme con las posiciones de las piezas contrarias al ultimo jugador que ha movido. Hay que tener en cuenta que me quedo con la posición respecto a la lista, no con la id de la pieza en sí

Por cada una de esas piezas, hago una llamada a la función **<u>quien_mueve</u>** con 3 parámetros: posición en la que se encuentra de la lista, la lista y el jugador de la pieza. Esta función hace una llamada a 3 posibles funciones diferentes, dependiendo de la id de la pieza: <u>**mueve_peon, mueve_torre y mueve_rey **</u>

<!-- para chess_expanded tengo incluido la funcion mueve_alfil -->

Antes de comenzar a explicar estas funciones, añado que he creado una función auxiliar llamada **pieza_aqui?** que dándole una posición del tablero te devuelve:

- "misma" si la pieza pertenece a la misma raza

- "distinta" si la pieza es del otro player

- "null" si la casilla esta vacía

- "false" si esta buscando fuera del tablero

###### FUNCION MUEVE_PEON: 

He tenido que tener en cuenta cuatro cosas: 

​	Dado que solo pueden avanzar, tener en cuenta de que player era el peón para el movimiento, si +5 o -5

​	Para el movimiento frontal, solo si en la casilla de enfrente esta a "null" según la función pieza_aqui?

​	Para las diagonales (+6 +4 o -6 -4) dependiendo de si en la posición (+6 , +4 o -6 , -4) de la lista equivale a 	"distinta"

​	Si el peón esta en un lateral del tablero, solo dispone de una diagonal para mover

###### FUNCION MUEVE_TORRE:

La función de la torre la he dividido en dos partes, (para las filas y para las columnas) cada una con 2 bucles while, uno para cada dirección a la que puede avanzar (izquierda o derecha) o (arriba o abajo)

Cada parte se basa en el mismo razonamiento: 

- Detecto a que fila o a que columna pertenece la pieza.

- Dado que tengo la posición de la pieza en la lista, hago un foreach para su propia fila o columna restándole el propio valor de la posición en la que se encuentra:  EJEMPLO;

  <!-- pos pieza = 11 || pertenece a la fila [10 11 12 13 14] || aplicando el foreach: [-1 0 +1 +2 +3] -->

  Ya tengo el número de iteraciones tanto para la izquierda: [1]como para la derecha: [3], de aquí los dos bucles. Esto hay que hacerlo tanto para las filas, visto en el ejemplo como para las columnas.

- Para decidir el movimiento que puede hacer en la torre en cada bucle, he optado por un booleano para avisar de cuando salir del bucle, ya que dependiendo de si en las posiciones posteriores nos encontramos con:

  ​				 "null" : añadimos la posición y continuamos el bucle

  ​				 "misma" : no añadimos la posición y salimos del bucle

  ​				  "distinta" : añadimos la posición y salimos del bucle

  

  ###### FUNCION MUEVE_REY:

  <!--Probablemente la función que hace que me pete el programa -->

  - En esta función he optado por quedarme inicialmente con las 8 posibles posiciones a las que puede mover el rey.

  - De estas posiciones limpio si me encuentro en los bordes del tablero, además de limpiar si se encuentra una pieza aliada.

  - Para evitar que el rey mueva a una posición en la que hay jaque, me he visto obligado a crear 4 funciones nuevas
  - **<u>get-rules_for_king:</u>** que hace exactamente lo mismo que la función **<u>MCTS:get-rules</u>** solo que en lugar de llamar a la función quien_mueve, llama a la función **<u>quien_mueve_for_king</u>** para detectar todos los posibles movimientos del enemigo. Una vez hecho  esto, miro si coincide alguna de estas posiciones con los movimientos posibles de mi rey para así eliminar el movimiento
  - Al hacer esto me he dado cuenta de que tenía que crear otra función del movimiento del rey, llamada **<u>mueve_rey_aux</u>** para no entrar en un bucle infinito además de una función nueva del peón llamada **<u>mueve_peon_aux</u>** , ya que el peón mueve hacia delante, pero no come hacia delante



###### FUNCIÓN MUEVE_ALFIL: 

Para el alfil he tenido que crearme 4 funciones auxiliares, cada una para calcular el número de movimientos posibles para cada diagonal en el tablero

<!-- las funciones son un poco costosas -->

Después, usando estas 4 variables y con bucles al igual que con la torre, obtengo el rango de movimientos posibles





### - **<u>FUNCIÓN MCTS:APPLY</u>** :

Dado que el get-rules me devuelve una lista de posibles movimientos con [id_pieza posFinal]

El apply simplemente mueve la pieza con id_pieza a la posición posFinal y pone un 0 en la posición inicial de id_pieza





### **<u>- FUNCION GET-RESULT</u>** : 

<!--La función que mas fallos me ha saltado -->

En esta función itero sobre el tablero y busco los reyes, si los encuentro, uso dos variables (p1 y p2) que se ponen en 1 

Uso otras tres variables que cuentan el numero de piezas blancas, de piezas negras y total de piezas

- Si p1 = p2 y cuenta_piezas es mayor que dos, la partida sigue

- -  si cuenta_piezas es menor o igual a dos, tenemos tablas
  - si cuenta_piezas es mayor que dos, dependiendo de si hay mas, menos, o igual devuelvo 0.7, 0.3 y 0.55 respectivamente

- Si p1 > p2,  gana jugador uno 
- Si p1 < p2,  gana jugador 2

<!-- He intentado llamar a mueve_rey con la posicion de los reyes para saber si alguno estaba ahogado, pero me daba problemas y decidí quitarlo -->

**Mas funciones auxiliares:** actualizarTablero,  convierte_aPatch  , board-to-state



### --Conclusiones, opinión:

- He probado todas las funciones del get-rules en el observador y funcionan perfectamente hasta donde he visto

- El minichess funciona medio bien, con 2000 iteraciones tarda unos 30 segundos en responder, con menos iteraciones es bastante tonto, pero funciona
- El chess_expanded 100% recomendado jugar con 1 sola iteración o probablemente pete ( a veces peta igualmente, pero he llegado a jugar partidas completas)

- Tengo comentado la parte del rey de get-rules_for_king, porque peta muchísimo, pero funciona correctamente (al menos en el observador) excepto dos excepciones:
  		-  Si la torre o el alfil hacen jaque al rey, este se puede mover en el mismo rango de la fila de la 			torre o el alfil aunque siga haciendo jaque
- En el to play, a la parte de mover para el jugador blanco, no le tengo puesto restricciones, (no hay que ser tramposos) no me ha dado tiempo.
- Tampoco me ha dado tiempo a hacerle una interfaz bonita, pero bueno con esto concluye la entrega





