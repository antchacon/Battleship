# Proyecto 3 – Battleship sobre RISC-V

## Planteamiento del diseño

**Curso:** EL3313 – Taller de Diseño Digital  
**Proyecto:** Batalla Naval sobre microprocesador RISC-V  
**Semestre:** II Semestre 2026  
**Equipo:** 06  

### Integrantes
Yerlin Angelitte Gamboa Ortiz 2022184205

Anthony Fabián Chacón Montero 2022117452


---

# 1. Objetivo del diseño
El objetivo de este documento es definir una arquitectura preliminar para implementar el juego de Batalla Naval sobre una FPGA (Basys 3) 
utilizando un procesador RISC-V de 32 bits.

El diseño se establece siguiendo una metodología modular y jerárquica, partiendo de una representación general del sistema y diviendo en
subsistemas hasta obtener bloques funcionales definidos para su posterior implementación en SystemVerilog.



La lógica completa del juego será ejecutada mediante un programa en lenguaje
ensamblador sobre el procesador RISC-V. Los periféricos se encargarán
únicamente de las funciones de entrada/salida y del procesamiento de bajo
nivel requerido para operar cada dispositivo.

---

# 2. Descripción general del sistema

El sistema implementa una versión de Batalla Naval para dos jugadores.

- El **Jugador 1** interactúa directamente con la FPGA mediante botones y
  observa el juego mediante una salida VGA.
- El **Jugador 2** utiliza una aplicación de PC comunicada con la FPGA mediante
  UART.
- El procesador RISC-V ejecuta la lógica completa de la partida.
- La ROM almacena el programa.
- La RAM almacena los datos variables del juego.
- Los periféricos son accedidos mediante un esquema de memoria mapeada.

Cada jugador dispone de un tablero de 8 × 8 posiciones y una flota de tres
barcos.

---

# 3. Requerimientos principales del diseño

| Requerimiento | Solución propuesta |
|---|---|
| Ejecución de la lógica del juego | Procesador RISC-V RV32I |
| Almacenamiento del programa | Memoria ROM |
| Almacenamiento de tableros y variables | Memoria RAM |
| Jugador 1 | Botones y switches de la FPGA |
| Jugador 2 | Comunicación UART con aplicación de PC |
| Visualización local | VGA |
| Indicadores | Displays de 7 segmentos, LED y buzzer |
| Comunicación entre CPU y periféricos | Memory-mapped I/O |
| Reloj principal | 100 MHz |


---

# 4. Metodología de diseño

Se utiliza una metodología de diseño **top-down**.

El sistema se desarrolla mediante los siguientes niveles:

1. **Primer nivel:** arquitectura general y entradas/salidas externas.
2. **Segundo nivel:** división del sistema en subsistemas principales.
3. **Tercer nivel:** descomposición funcional interna de cada subsistema.
4. **Implementación:** traducción de los bloques funcionales a módulos
   sintetizables en SystemVerilog.

---

# 5. Diagrama de primer nivel

## 5.1 Objetivo

El diagrama de primer nivel representa el sistema Battleship como una única
unidad e identifica las principales interfaces externas y los elementos
fundamentales de procesamiento y memoria.

## 5.2 Diagrama

![Diagrama de primer nivel](https://github.com/antchacon/Battleship/blob/main/Docs/Im%C3%A1genes/Primer%20Nivel.jpg)

**Figura 1. Diagrama de primer nivel del sistema Battleship.**

## 5.3 Descripción

El sistema recibe un reloj principal de 100 MHz.

El Jugador 1 introduce comandos mediante botones físicos, mientras que el
Jugador 2 se comunica mediante una aplicación de PC.

Las principales salidas físicas son:

- VGA.
- Displays de 7 segmentos.
- LED.
- Buzzer.

Internamente se tienen como bloques principales el procesador RISC-V,
la ROM y la RAM.

## 5.4 Justificación

La lógica del juego se encuentra centada en el procesador RISC-V, de modo que las condiciones
del juego como la colocación de barcos, validación de disparos, control de turnos, detección 
de impactos, barcos hundidos y estado de victoria o derrota, se implementan mediante software 
en ensamblador. 

Los módulos de entrada y salida se mantienen separados del procesamiento principal y se 
encargan de funciones específicas de bajo nivel, como la lectura de los botones, comunicación
UART, generación de imagen por VGA, control de displays, leds de estado y buzzer. Esto facilita la 
verificación de cada bloque y simplifica la integración mediante el esquema de memoria mapeada.

Además, el uso de la ROM independiente para instrucciones y una RAM para datos permite separar claramente 
el almacenamiento del programa de las variables de la partida y la utilización de la memoria mapeada 
proporciona una interfaz uniforme para que el procesador acceda a memorias y periféricos.

---

# 6. Diagrama de segundo nivel

## 6.1 Objetivo

Representar la arquitectura funcional del sistema mediante la división del diseño en sus principales subsistemas,
mostrando las conexiones entre el procesador RISC-V, las memorias y los periféricos.

## 6.2 Diagrama

![Diagrama de segundo nivel](https://github.com/antchacon/Battleship/blob/main/Docs/Im%C3%A1genes/Segundo%20Nivel.jpg)

**Figura 2. Arquitectura de segundo nivel del sistema.**

## 6.3 Subsistemas

| Subsistema | Función | Descripción |
|---|---|---|
| Procesamiento RISC-V | Ejecutar el programa del juego | Ejecuta las instrucciones almacenadas en la ROM y controla la lógica del juego, incluyendo colocación de barcos, validación de posiciones, manejo de turnos, procesamiento de disparos, detección de impactos, barcos hundidos y condición de victoria. Realiza operaciones de lectura y escritura sobre RAM y periféricos. |
| ROM | Almacenar las instrucciones | Contiene las instrucciones de 32 bits que forman el programa en ensamblador ejecutado por el procesador RISC-V. El CPU proporciona una dirección de programa y la ROM devuelve la instrucción correspondiente. |
| RAM | Almacenar datos variables | Guarda la información que cambia durante la ejecución, como los tableros de ambos jugadores, posiciones de barcos, estado de casillas, turno actual, barcos hundidos, contadores y otras variables utilizadas por el programa. |
| Interconexión y mapeo de memoria | Comunicar el procesador con RAM y periféricos | Analiza la dirección generada por el procesador para determinar que dispositivo debe ser accedido. Genera las señales de selección y escritura correspondientes y selecciona el dato que debe regresar al CPU durante una operacion de lectura. |
| Entradas Jugador 1 | Leer los controles físicos del jugador local | Recibe los 5 botones y switches utilizados por el jugador 1. Las señales son sincronizadas y los botones pasan por un proceso de eliminacion de rebotes.|
| UART | Comunicar FPGA y PC | Canal de comunicación con el jugador 2. Recibe desde la PC información de colocación de barcos y disparos, y transmite hacia la aplicación información sobre aceptación de posiciones, resultados de disparos, cambios de turno y el resultado de la partida. |
| VGA | Generar la interfaz visual del Jugador 1 | Produce las señales necesarias para mostrar en el monitor el tablero propio, el estado conocido del tablero rival, el cursor y la informacion relevante de la partida.|
| Indicadores | Controlar displays, LED y buzzer | Agrupa los displays de siete segmentos, LED y buzzer. Los displays muestran información como las victorias acumuladas, el LED indica estados o fases de la partida y el buzzer genera sonidos diferentes de impacto, fallo, barco hundido, colocación invalida y fin de partida. |

## 6.4 Justificación

Esta arquitectura separa el sistema en subsistemas independientes conectados alrededor del procesador RISC-V. La ROM brinda las instrucciones, mientras que la RAM y los periféricos
se integran mediante memoria mapeada, permitiendo al procesador acceder a todos ellos mediante una interfaz uniforme. De esta forma se facilita las pruebas por bloque y se
simplifica la integración del sistema completo.

---

# 7. Diseño de tercer nivel

## 7.1 Objetivo



- diagrama,
- descripción del funcionamiento,
- bloques internos,
- entradas y salidas,
- señales internas relevantes,
- decisiones de diseño,
- justificación.

---

## 7.1 Memoria ROM

### Objetivo

La ROM se encarga de almacenar las instrucciones del programa que es ejecutado por el RISC-V y de brindarle por medio de señales de 32 bits las instrucciones correspondientes a la dirección solicitada.

### Diagrama

<img width="1113" height="796" alt="image" src="https://github.com/user-attachments/assets/811ee9a5-45eb-4d30-a078-bcdac1f13e1d" />


**Figura 3. Diagrama de tercer nivel de la memoria ROM.**

### Descripción del funcionamiento

El módulo ROM recibe una dirección proveniente del procesador RISC-V, la cual indica la posición de memoria que debe ser consultada y la ROM solicita la información almacenada en dicha posición. Cada salida tiene un ancho de 32 bits y estas instrucciones son enviadas al RISC-V el cuál las utiliza para la decodificación y ejecución del programa.

### Bloques internos

| Bloque | Función |
|---|---|
| Conversión de dirección a índice | Utiliza la señal recibida  del procesador y la utiliza para convertir y acceder a una posición especifica de la ROM|
| Memoria de programa | Almacena las instrucciones de 32 bits que le dan sentido al programa y que después deberá enviar al procesador RISC-V|
| Inicialización | Carga las instrucciones que estarán almacenadas en la ROM antes de la ejecución del programa|

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `prog_address_i` | Entrada |32 bits |Posición de la instrucción que se desea consultar |
| `prog_instr_o` | Salida |32 bits| Devuelve la instrucción almacenada en la posición consultada |
| `clk_i` | Entrada |1 bit |Sincroniza el modulo con el resto del sistema |
| `rst_i` | Entrada |1 biot |Señal de reinicio del sistema |

### Señales internas relevantes

| Señal | Descripción |
|---|---|
| Indice de memmoria|Posición interna de la ROM que corresponde a la dirección recibida mediante prog_address_i. |

### Organización de memoria

Las direcciones tienen un rango de 32 bits  ya que almacena una dirección completa del procesador. La dirección recibida mediante prog_address_i se convierte en un índice que permite seleccionar la posición correspondiente dentro de la memoria.
Debido a que las instrucciones del procesador tienen un tamaño de 32 bits, estas se encuentran alineadas en memoria. Por esta razón, la dirección proporcionada por el procesador debe ser adaptada antes de utilizarse como índice interno de la ROM.
El contenido de la memoria se define durante la inicialización del sistema y permanece sin modificaciones durante la ejecución del programa, ya que el procesador únicamente realiza operaciones de lectura sobre esta memoria.
### Decisiones y justificación

Las ROM almacena palabras de 32 bits ya que corresponde al ancho de las instrucciones que se utilizan en RISC_V. Y se utiliza una memoria que solo tenga acceso de lectura para evitar modificaciones indeseadas durante la ejecución del programa.
## 7.2 Memoria RAM

### Objetivo

La memoria RAM se encarga de almacenar temporalmente los datos correspondientes a cada partida durante la ejecución del juego. Estos datos pueden ser leídos o modificados por el procesador RISC-V-

### Diagrama

<img width="1335" height="808" alt="image" src="https://github.com/user-attachments/assets/2bfac7df-2884-4a6f-b193-b63cd6c508c4" />


**Figura 4. Diagrama de tercer nivel de la memoria RAM.**

### Descripción del funcionamiento

Recibe desde el RISC_V una dirección de la memoria que no solamente se puede consultar sino también modificar si se solicita. Durante una escritura, el dato recibido mediante wdata_i se almacena en la posición indicada por addr_i. Para una lectura, la RAM obtiene el contenido almacenado en la dirección seleccionada y lo entrega al procesador mediante rdata_o.

### Bloques internos

| Bloque | Función |
|---|---|
| Conversión de dirección a índice | Convierte la dirección addr_i en el indice que se utiliza para acceder a una posición de la memoria RAM|
| Lógica de escritura | Controla cuando almacenar un dato seg+un lo indique la señal write_enable_i|
| Memoria RAM | Almacena temporalmente los datos correspondientes a cada partida|
| Buffer de lectura | Entrega por medio de rdata_o el dato almacenado en la posición de memoria solicitada|

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `addr_i` | Entrada | 32 bits| Posición de la memoria por consultar o modificar|
| `wdata_i` | Entrada | 32 bits| Dato a almacenar durante la operación de escritura|
| `write_enable_i` | Entrada | 1 bit| Habilita la escritura de wdata_i en la posición indicada por addr_i.|
| `rdata_o` | Salida | 32 bits | Dato leído en la posición de memoria solicitada|
| `clk_i` | Entrada | 1 bit| Sincroniza las operaciones de la memoria|
| `rst_i` | Entrada | 1 bit| Señal de inicio para llevar el modulo a su condición inicial|

### Señales internas relevantes

| Señal  | Descripción |
|---|---|
|Indice de memkoria | Posicion interna de la RAM solicitada por addr_i |
| Memoria interna| Contiene los datos almacenados durante la partida|

### Organización de datos en RAM

| Región | Información almacenada |
|---|---|
| Tablero Jugador 1 | Posiciones de los barcos del jugador 1| 
| Tablero Jugador 2 | Posiciones de los barcos del jugador 1| 
| Estado de barcos J1 | Estado de los barcos pertenecientes al jugador 1| 
| Estado de barcos J2 | Estado de los barcos pertenecientes al jugador 2| 
| Turno actual |Determina el turno del jugador | 
| Contadores |Llevar el control de distintos eventos, como la cantidad de barcos o aciertos y desaciertos | 
| Variables auxiliares | Información temporal necesaria para la ejecución de la lógica del juego| 

### Decisiones y justificación

Se utiliza una memoria sobre la cuál se pueda modificar la información debido a que contiene información variable necesaria para el funcionamiento de cada partida. Se utilizan diferentes regiones de memoria para separar distintas funciones del juego de manera que se facilite mantener de forma ordenada el estado actual de la partida

---

## 7.3 Interconexión y mapeo de memoria

### Objetivo

Su funcion es dirigir las operaciones de lectura y escritura del procesador RISC-V hacia el módulo correspondiente del sistema según la dirección utilizada.A partir de la dirección generada por el procesador, este bloque determina si el acceso corresponde a la memoria RAM, a algún periférico o a otra región del sistema.
### Diagrama

<img width="1489" height="753" alt="image" src="https://github.com/user-attachments/assets/4cba836a-c651-45c8-b58b-c367c3521b6a" />


**Figura 5. Diagrama de tercer nivel de la interconexión y mapeo de memoria.**

### Descripción del funcionamiento

El bloque de interconexión recibe desde el procesador RISC-V la dirección de acceso, el dato que se desea escribir y la señal que indica si la operación corresponde a una escritura.
A partir de data_address_i, el decodificador de direcciones determina qué dispositivo o región del sistema debe ser seleccionado. Para una operación de escritura, el bloque genera la señal de habilitación correspondiente al dispositivo seleccionado y envía el dato recibido mediante data_out_i.
En una operación de lectura, el periférico o memoria seleccionada entrega su dato al bloque de interconexión. Posteriormente, el multiplexor de lectura selecciona la información proveniente del dispositivo correspondiente y la envía nuevamente al procesador mediante data_in_o.

### Bloques internos

| Bloque | Función |
|---|---|
| Decodificador de direcciones |Analiza data_address_i y determina qué memoria o periférico debe ser seleccionado según el rango de direcciones asignado.|
| Decodificador de escritura |Genera la señal de habilitación de escritura correspondiente.|
| Multiplexor de lectura |Selecciona el dato proveniente del dispositivo activo y lo envía al procesador mediante data_in_o. |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `data_address_i` | Entrada |32 bits |Dirección generada por el procesador para seleccionar una región de memoria o un periférico. |
| `data_out_i` | Entrada | 32 bits| Dato a escribir|
| `data_we_i` | Entrada | 1 bit| Indica una operación de escritura|
| `data_in_o` | Salida | 1 bit|Dato obtenido del dispositivo seleccionado y enviado nuevamente al procesador. |
| | | | |

### Señales de selección

| Señal | Dispositivo |
|---|---|
| `sel_ram` | Selecciona la RAM|
| `sel_uart` |Selecciona la UART |
| `sel_vga` | Selecciona el modulo VGA|
| `sel_j1` | Selecciona las entradas del jugador 1|
| `sel_ind` | Selecciona las entradas del jugador 2|

### Señales de escritura

| Señal | Dispositivo |
|---|---|
| `we_ram` |Habilita escritura en la RAM |
| `we_uart` | Habilita escritura en la UART |
| `we_vga` | |Habilita escritura en el modulo VGA |
| `we_j1` | Habilita la escritura asociada al bloque del jugador 1|
| `we_ind` | Habilita escritura en el modulo0 de indicadores |

### Mapa de memoria

| Dispositivo / región |  Uso |
|---|---:|
| ROM | Almacenamiento de las instrucciones ejecutadas por el procesador.| 
| RAM | Almacenamiento temporal durante cada partida | 
| UART | Comunicación entre FPGA y otros dispositivos| 
| VGA | Control de información enviada al sistema de visualización VGA| 
| Entradas Jugador 1 | Lectura del estado de las entradas utilizadas por el jugador 1.|
| Indicadores | Control de señales de salida para mostrar estados o información del juego| 

### Decodificación

La decodificación de direcciones se realiza comparando data_address_i con los rangos asignados a cada dispositivo del sistema. Cuando la dirección se encuentra dentro del rango correspondiente a un módulo, se activa su señal de selección. Para las operaciones de escritura, la señal de selección se combina con data_we_i

### Decisiones y justificación

Se utiliza un esquema de memoria mapeada debido a que permite que el procesador RISC-V acceda tanto a la memoria RAM como a los diferentes periféricos utilizando las mismas operaciones de lectura y escritura empleadas para acceder a memoria. Cada dispositivo posee un rango de direcciones específico dentro del espacio de memoria del sistema. De esta manera, el procesador únicamente necesita generar una dirección para indicar con qué componente desea comunicarse. Esta organización simplifica la comunicación entre el procesador, la memoria y los periféricos.
---

## 7.4 UART

### Objetivo

[Describir el objetivo del periférico UART.]

### Diagrama

![UART](imagenes/uart_nivel_3.png)

**Figura X. Diagrama de tercer nivel del periférico UART.**

### Descripción del funcionamiento

[Explicar por separado el camino RX, el camino TX y el acceso desde el CPU.]

### Bloques internos

| Bloque | Función |
|---|---|
| Generador de baudrate | |
| UART RX | |
| Registro RX | |
| Registro de estado | |
| Lógica de decodificación de escritura | |
| Registro TX | |
| UART TX | |
| MUX de lectura | |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `uart_rx_i` | Entrada | | |
| `uart_tx_o` | Salida | | |
| `addr_i` | Entrada | | |
| `wdata_i` | Entrada | | |
| `write_enable_i` | Entrada | | |
| `rdata_o` | Salida | | |
| `clk_i` | Entrada | | |
| `rst_i` | Entrada | | |

### Señales internas relevantes

| Señal | Ancho | Descripción |
|---|---:|---|
| `baud_tick` | | |
| `rx_data` | | |
| `rx_ready` | | |
| `tx_data` | | |
| `tx_busy` | | |
| `tx_done` | | |
| `tx_we` | | |

### Registros internos

| Dirección / `addr_i` | Registro | Función |
|---|---|---|
| | Control / Estado | |
| | Datos TX | |
| | Datos RX | |

### Temporización UART

[Indicar baudrate, relación con el reloj principal y cálculo del generador de baudrate.]

### Decisiones y justificación

[Explicar la división RX/TX, registros y temporización.]

---

## 7.5 Entradas del Jugador 1

### Objetivo

Recibir las señales provenientes de los botones y switches utilizados por el jugador 1, acondicionarlas para su uso y proporcionar su estado al procesador RISC-V mediante una interfaz mapeada en memoria. El bloque debe sincronizar las entradas con el reloj del sistema y eliminar los rebotes producidos por los pulsadores antes de que sean procesadas por el programa.

### Diagrama

![Entradas Jugador 1](https://github.com/antchacon/Battleship/blob/main/Docs/Im%C3%A1genes/Entradas%20Jugador%201.jpeg)

**Figura 7. Diagrama de tercer nivel de las entradas del Jugador 1.**

### Funcionamiento

Las señales provenientes de los botones y switches de la FPGA ingresan al subsistema de entradas del Jugador 1. Debido a que estas señales provienen de elementos físicos externos, primero se sincronizan con el reloj del sistema. En el caso de los botones, pasan por una etapa de eliminación de rebotes para evitar que una sola pulsación sea interpretada como múltiples eventos. 

Una vez acondicionadas, las señales de los botones y switches se agrupan en un registro de 32 bits. El procesador RISC-V puede consultar este registro mediante una operación de lectura a través de la interfaz de memoria mapeada. De esta manera, el programa puede determinar qué control está activo y utilizarlo para realizar acciones como mover el cursor, confirmar una selección, cambiar la orientación de un barco o reiniciar la partida.

### Bloques internos

| Bloque | Función |
|---|---|
| Sincronizadores de botones | Sincronizan las señales de los pulsadores con el reloj del sistema para que puedan ser utilizadas de forma segura. |
| Debouncers | Eliminan los rebotes mecánicos de los botones y generan una señal estable por cada pulsación. |
| Sincronizadores de switches | Sincronizan las señales provenientes de los switches con el reloj del sistema. |
| Registro de estado | Agrupa el estado acondicionado de botones y switches dentro de una palabra que puede ser consultada por el procesador. |
| Multiplexor de lectura | Selecciona el registro que debe enviarse al procesador de acuerdo con la dirección recibida en la interfaz del periférico. |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `btn_up_i` | Entrada | 1 bit | Botón utilizado para mover el cursor hacia arriba. |
| `btn_down_i` | Entrada | 1 bit | Botón utilizado para mover el cursor hacia abajo. |
| `btn_left_i` | Entrada | 1 bit | Botón utilizado para mover el cursor hacia la izquierda. |
| `btn_right_i` | Entrada | 1 bit | Botón utilizado para mover el cursor hacia la derecha. |
| `btn_center_i` | Entrada | 1 bit | Botón central utilizado para confirmar una selección o acción. |
| `sw_sel_i` | Entrada | 1 bit | Switch utilizado como señal de selección, por ejemplo para cambiar la orientación de un barco. |
| `sw_rst_i` | Entrada | 1 bit | Switch utilizado para solicitar el reinicio de la partida. |
| `addr_i` | Entrada | 2 bits | Dirección interna utilizada para seleccionar el registro que será leído por el procesador. |
| `rdata_o` | Salida | 32 bits | Palabra que contiene el estado de los botones y switches y que es enviada al procesador durante una operación de lectura. |
| `clk_i` | Entrada | 1 bit | Reloj principal utilizado para sincronizar el funcionamiento del periférico. |
| `rst_i` | Entrada | 1 bit | Señal de reinicio del módulo de entradas. |

### Mapeo del registro Status

| Bit | Señal | Descripción |
|---:|---|---|
| 0 | btn_up_db | Arriba |
| 1 | btn_down_db | Abajo |
| 2 | btn_left_db | Izquierda |
| 3 | btn_right_db | Derecha |
| 4 | btn_center_db | Confirmar |
| 5 | sw_sel_sync | Selección/Orientación |
| 6 | sw_rst_sync | Reinicio de partida |
| 31:7 | Reservado | Uso futuro |

### Decisiones y justificación

El periférico se diseñó separando el acondicionamiento de las señales físicas de la lógica del juego. Los botones pasan primero por bloques de sincronización y debouncing, debido a que son señales externas al reloj del sistema y pueden presentar rebotes mecánicos durante una pulsación. De esta manera, el procesador recibe señales confiables. Los switches únicamente requieren sincronización, ya que no presentan el mismo comportamiento de rebote asociado a los pulsadores durante su uso normal. Todas las entradas acondicionadas se agrupan en un único registro de 32 bits. Esta organización permite que el procesador RISC-V consulte el estado de los controles del Jugador 1 mediante una sola operación de lectura.

---

## 7.6 Indicadores

### Objetivo

El subsistema de indicadores tiene como objetivo proporcionar retroalimentación visual y sonora sobre el estado de la partida mediante los displays de 7 segmentos, los leds y el buzzer. El procesador RISC-V controla estos dispositivos mediante registros mapeados en memoria, permitiendo mostrar información como los contadores de victorias, indicar estados del juego y generar sonidos asociados a los eventos de la partida.

### Diagrama

![Indicadores](https://github.com/antchacon/Battleship/blob/main/Docs/Im%C3%A1genes/Indicadores.jpg)

**Figura 8. Diagrama de tercer nivel del subsistema de indicadores.**

### Funcionamiento

El subsistema de indicadores recibe desde el procesador RISC-V datos y señales de escritura mediante la interfaz de memoria mapeada. De acuerdo con la dirección seleccionada, la lógica de decodificación determina cuál de los registros internos debe actualizarse, display, LED o buzzer.

El registro de display almacena la información que debe mostrarse en los displays de 7 segmentos. 

El registro del LED almacena directamente el estado que debe reflejarse en la salida led_o, permitiendo indicar condiciones o fases relevantes de la partida.

El registro del buzzer almacena el código asociado al evento que se desea representar mediante sonido. Este valor es interpretado por el selector de sonido, el cual determina el tono correspondiente y lo entrega al generador de frecuencia para producir la señal buzzer_o.

Durante una operación de lectura, el multiplexor interno selecciona el contenido del registro solicitado y lo entrega al procesador mediante rdata_o[31:0].

### Bloques internos

| Bloque | Función |
|---|---|
| Decodificador de dirección/escritura | Determina cuál de los registros internos debe actualizarse a partir de addr_i y write_enable_i. |
| Registro Display | Almacena el valor que debe mostrarse en los displays de siete segmentos. |
| Conversión/separación de dígitos | Divide o adapta el valor almacenado para obtener los dígitos que serán mostrados. |
| Decodificador 7 segmentos | Convierte cada dígito en el patrón de segmentos necesario para representarlo físicamente. |
| Multiplexor de display | Selecciona el dígito activo y coordina las señales seg_o y an_o. |
| Registro LED | Almacena el estado que debe reflejarse en la salida led_o. |
| Registro Buzzer | Almacena el código correspondiente al evento sonoro solicitado por el procesador. |
| Selector de sonido | Interpreta el valor del registro del buzzer y selecciona el tono asociado al evento correspondiente. |
| Generador de frecuencia | Genera la señal periódica que controla físicamente el buzzer. |
| MUX de lectura | Selecciona el contenido del registro que debe regresar al procesador mediante rdata_o. |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk_i` | Entrada | 1 bit | Reloj principal utilizado para sincronizar los registros y la lógica interna del periférico. |
| `rst_i` | Entrada | 1 bit | Reinicia los registros y coloca las salidas del subsistema en su estado inicial. |
| `write_enable_i` | Entrada | 1 bit | Indica que el procesador desea realizar una operación de escritura. |
| `addr_i[1:0]` | Entrada | 2 bits | Selecciona el registro interno que será leído o escrito. |
| `wdata_i[31:0]` | Entrada | 32 bits | Dato enviado por el procesador hacia el registro seleccionado. |
| `rdata_o[31:0]` | Salida | 32 bits | Dato leído desde el registro interno seleccionado. |
| `seg_o[6:0]` | Salida | 7 bits | Señales de control de los siete segmentos del display. |
| `an_o[3:0]` | Salida | 4 bits | Selecciona cuál de los cuatro dígitos del display está activo. |
| `led_o` | Salida | 1 bit | Señal de control del LED utilizado para indicar estados de la partida. |
| `buzzer_o` | Salida | 1 bit | Señal digital utilizada para controlar el buzzer y generar la retroalimentación sonora. |

### Registros internos

El subsistema de indicadores utiliza registros independientes para controlar
los displays de siete segmentos, el LED de estado y el buzzer. Cada registro
mantiene el valor escrito por el procesador hasta que se realiza una nueva
operación de escritura.

| Registro | Dirección global | Función |
|---|---:|---|
| Display | `0x0001_0130` | Almacena la información que debe mostrarse en los cuatro dígitos de siete segmentos. |
| LED | `0x0001_0138` | Almacena el estado utilizado para controlar el LED de indicación del sistema. |
| Buzzer | `0x0001_0140` | Almacena el código de control utilizado para seleccionar el sonido que debe generar el buzzer. |

### Eventos del buzzer

El buzzer proporciona retroalimentación sonora para diferentes eventos de la
partida. Cada evento debe generar una señal distinta de las demás.

| Evento | Código / tono | Descripción |
|---|---|---|
| Impacto | TBD | Se genera cuando un disparo alcanza una casilla ocupada por un barco rival. |
| Fallo | TBD | Se genera cuando un disparo alcanza una casilla de agua. |
| Barco hundido | TBD | Se genera cuando todas las posiciones correspondientes a un barco han sido impactadas. |
| Colocación inválida | TBD | Se genera cuando se intenta colocar un barco en una posición no permitida. |
| Fin de partida / victoria | TBD | Se genera cuando todos los barcos de uno de los jugadores han sido hundidos y finaliza la partida. |

### Decisiones y justificación

El subsistema de indicadores se organiza utilizando registros independientes
para los displays de siete segmentos, el LED de estado y el buzzer. Esta
separación permite controlar cada salida de manera individual mediante
operaciones de escritura realizadas por el procesador RISC-V.

El uso de registros de 32 bits mantiene compatibilidad con la interfaz estándar
de periféricos definida para el sistema y permite que el procesador acceda a
los indicadores.

Para los displays de siete segmentos se utiliza una etapa de conversión y
decodificación que transforma el valor almacenado en el registro en las señales
necesarias para controlar los segmentos y los dígitos físicos.

El LED se controla mediante un registro propio, permitiendo representar de
forma sencilla diferentes estados o fases de la partida.

En el caso del buzzer, se utiliza un registro de control separado de la lógica
de generación de sonido. De esta manera, el procesador únicamente selecciona
el evento que desea indicar, mientras que el hardware se encarga de generar la
frecuencia correspondiente.

---

## 7.7 VGA

### Objetivo

Este tiene como objetivo generar la interfaz visual del Jugador 1, mostrando la información necesaria para el desarrollo de la partida, como los tableros, el cursor, el estado de las casillas y la información general del juego.

El módulo recibe desde el procesador RISC-V la información que debe representarse en pantalla mediante una memoria de video mapeada en memoria y se encarga de transformarla en las señales de sincronización y video necesarias para producir una salida VGA de 640x480 píxeles.

### Diagrama

![VGA](imagenes/vga_nivel_3.png)

**Figura 9. Diagrama de tercer nivel del periférico VGA.**

### Funcionamiento
El periférico VGA utiliza una memoria de video organizada por bloques para almacenar la información que debe mostrarse en pantalla. El procesador RISC-V puede modificar directamente el contenido de esta memoria mediante operaciones de lectura y escritura dentro del rango de direcciones asignado al periférico VGA.

De forma paralela, el bloque de temporización VGA utiliza el reloj de píxel para generar los contadores horizontal y vertical, a partir de los cuales se obtienen la posición actual del píxel y las señales de sincronización vga_hsync_o y
vga_vsync_o.

Con base en la posición actual del píxel, el módulo calcula qué bloque de la memoria de video corresponde mostrar y obtiene el dato almacenado para esa posición. Este dato es interpretado por la lógica de generación de imagen para determinar si el píxel debe mostrarse activo o inactivo.

Finalmente, la información del píxel se convierte en las señales RGB que se envían al monitor mediante vga_red_o, vga_green_o y vga_blue_o. En este diseño la salida visual se plantea de forma monocromática, por lo que las tres componentes RGB se controlan de manera equivalente para representar los diferentes elementos del juego.

La operación del acceso del procesador a la memoria de video y la generación continua de la señal VGA se mantienen separadas, permitiendo actualizar el contenido de la pantalla sin interrumpir la temporización requerida por el monitor.

### Bloques internos

| Bloque | Función |
|---|---|
| Interfaz de memoria mapeada | Permite que el procesador RISC-V lea y escriba el contenido de la memoria de video mediante el rango de direcciones asignado al periférico VGA. |
| Memoria de video | Almacena la información correspondiente a los bloques que deben mostrarse en pantalla. Cada posición representa el contenido visual de una región de la imagen. |
| Generador de temporización VGA | Genera la temporización necesaria para una salida VGA de 640 × 480 píxeles a 60 Hz. |
| Contador horizontal | Lleva el conteo de la posición horizontal actual dentro de la trama VGA. |
| Contador vertical | Lleva el conteo de la posición vertical actual dentro de la trama VGA. |
| Cálculo de bloque y posición | Convierte la posición actual del píxel en la dirección correspondiente dentro de la memoria de video. |
| Generador de píxel | Interpreta el dato leído desde la memoria de video y determina el valor visual que debe mostrarse para el píxel actual. |
| Generador RGB | Convierte el valor generado para el píxel en las señales vga_red_o, vga_green_o y vga_blue_o. |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk_i` | Entrada | 1 bit | Reloj principal del sistema utilizado por la interfaz de acceso a la memoria de video. |
| `clk_pixel_i` | Entrada | 1 bit | Reloj de píxel de 25 MHz utilizado para generar la temporización de la señal VGA. |
| `rst_i` | Entrada | 1 bit | Reinicia los contadores y la lógica interna del periférico VGA. |
| `addr_i[8:0]` | Entrada | 9 bits | Dirección utilizada para seleccionar una posición dentro de la memoria de video. |
| `wdata_i[31:0]` | Entrada | 32 bits | Dato escrito por el procesador en la posición seleccionada de la memoria de video. |
| `write_enable_i` | Entrada | 1 bit | Habilita una operación de escritura sobre la memoria de video. |
| `rdata_o[31:0]` | Salida | 32 bits | Dato leído desde la posición seleccionada de la memoria de video. |
| `vga_red_o[3:0]` | Salida | 4 bits | Componente roja de la señal de video VGA. |
| `vga_green_o[3:0]` | Salida | 4 bits | Componente verde de la señal de video VGA. |
| `vga_blue_o[3:0]` | Salida | 4 bits | Componente azul de la señal de video VGA. |
| `vga_hsync_o` | Salida | 1 bit | Señal de sincronización horizontal del monitor VGA. |
| `vga_vsync_o` | Salida | 1 bit | Señal de sincronización vertical del monitor VGA. |

### Organización de la memoria de video
| Parámetro | Valor |
|---|---|
| Resolución VGA | 640 × 480 píxeles |
| Frecuencia de refresco | 60 Hz |
| Organización propuesta | 20 × 15 bloques |
| Tamaño de cada tile | 32 × 32 píxeles |
| Tamaño de palabra | 32 bits |
| Dirección inicial | `0x0001_1000` |
| Dirección final | `0x0001_17FF` |

### Decisiones y justificación

Se seleccionó una arquitectura basada en bloques. Esta decisión reduce la cantidad de memoria necesaria y disminuye el número de accesos que debe realizar el procesador para actualizar la imagen, ya que cada palabra de memoria representa una región completa de la pantalla y no un único píxel.

La memoria de video se mantiene mapeada dentro del espacio de direcciones del procesador, lo que permite que el RISC-V modifique directamente el contenido visual mediante operaciones de lectura y escritura. De esta forma, el software puede actualizar únicamente las posiciones que cambian durante la partida.

La generación de la señal VGA se mantiene separada del acceso realizado por el procesador. Mientras el CPU modifica el contenido de la memoria de video, la lógica VGA utiliza el reloj de píxel para leer continuamente dicha memoria ygenerar las señales de sincronización e imagen requeridas por el monitor.

También se utiliza un reloj de píxel independiente de 25 MHz, derivado del reloj principal de 100 MHz, con el objetivo de cumplir con la temporización requerida para una resolución de 640 × 480 píxeles a 60 Hz.

Finalmente, la representación visual se plantea de forma monocromática para simplificar la lógica de generación de imagen. Los diferentes estados del juego pueden distinguirse mediante patrones, símbolos o combinaciones visuales sin necesidad de implementar una lógica compleja de color.

Esta organización mantiene separadas las funciones de almacenamiento de la imagen, generación de temporización y generación de píxeles, facilitando la implementación, simulación y verificación individual de cada bloque.
