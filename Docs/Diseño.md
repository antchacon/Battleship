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

![Diagrama de primer nivel](imagenes/diagrama_nivel_1.png)

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

![Diagrama de segundo nivel](imagenes/diagrama_nivel_2.png)

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

[Describir el objetivo de la memoria ROM dentro del sistema.]

### Diagrama

![ROM](imagenes/rom_nivel_3.png)

**Figura X. Diagrama de tercer nivel de la memoria ROM.**

### Descripción del funcionamiento

[Explicar el flujo de información dentro del módulo ROM.]

### Bloques internos

| Bloque | Función |
|---|---|
| Conversión de dirección a índice | |
| Memoria de programa | |
| Inicialización | |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `prog_address_i` | Entrada | | |
| `prog_instr_o` | Salida | | |
| `clk_i` | Entrada | | |
| `rst_i` | Entrada | | |

### Señales internas relevantes

| Señal | Ancho | Descripción |
|---|---:|---|
| | | |

### Organización de memoria

[Indicar rango de direcciones, ancho de palabra, profundidad y forma de inicialización.]

### Decisiones y justificación

[Explicar las decisiones tomadas para la arquitectura de la ROM.]

---

## 7.2 Memoria RAM

### Objetivo

[Describir el objetivo de la RAM dentro del sistema.]

### Diagrama

![RAM](imagenes/ram_nivel_3.png)

**Figura X. Diagrama de tercer nivel de la memoria RAM.**

### Descripción del funcionamiento

[Explicar los caminos de lectura y escritura de la RAM.]

### Bloques internos

| Bloque | Función |
|---|---|
| Conversión de dirección a índice | |
| Lógica de escritura | |
| Memoria RAM | |
| Buffer de lectura | |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `addr_i` | Entrada | | |
| `wdata_i` | Entrada | | |
| `write_enable_i` | Entrada | | |
| `rdata_o` | Salida | | |
| `clk_i` | Entrada | | |
| `rst_i` | Entrada | | |

### Señales internas relevantes

| Señal | Ancho | Descripción |
|---|---:|---|
| | | |

### Organización de datos en RAM

| Región | Información almacenada | Tamaño | Dirección / índice |
|---|---|---:|---|
| Tablero Jugador 1 | | | |
| Tablero Jugador 2 | | | |
| Estado de barcos J1 | | | |
| Estado de barcos J2 | | | |
| Turno actual | | | |
| Contadores | | | |
| Variables auxiliares | | | |

### Decisiones y justificación

[Explicar la organización elegida para la RAM y los datos del juego.]

---

## 7.3 Interconexión y mapeo de memoria

### Objetivo

[Describir el objetivo del bloque de interconexión.]

### Diagrama

![Mapeo de memoria](imagenes/mapeo_memoria_nivel_3.png)

**Figura X. Diagrama de tercer nivel de la interconexión y mapeo de memoria.**

### Descripción del funcionamiento

[Explicar cómo se realizan las operaciones de lectura y escritura entre CPU,
RAM y periféricos.]

### Bloques internos

| Bloque | Función |
|---|---|
| Decodificador de direcciones | |
| Decodificador de escritura | |
| Multiplexor de lectura | |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `data_address_i` | Entrada | | |
| `data_out_i` | Entrada | | |
| `data_we_i` | Entrada | | |
| `data_in_o` | Salida | | |
| | | | |

### Señales de selección

| Señal | Dispositivo |
|---|---|
| `sel_ram` | |
| `sel_uart` | |
| `sel_vga` | |
| `sel_j1` | |
| `sel_ind` | |

### Señales de escritura

| Señal | Dispositivo |
|---|---|
| `we_ram` | |
| `we_uart` | |
| `we_vga` | |
| `we_j1` | |
| `we_ind` | |

### Mapa de memoria

| Dispositivo / región | Dirección inicial | Dirección final | Uso |
|---|---:|---:|---|
| ROM | | | |
| RAM | | | |
| UART | | | |
| VGA | | | |
| Entradas Jugador 1 | | | |
| Indicadores | | | |

### Decodificación

[Agregar las condiciones o ecuaciones utilizadas para generar las señales de
selección y escritura.]

### Decisiones y justificación

[Explicar por qué se utiliza memoria mapeada y cómo se organiza la interconexión.]

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

[Describir el objetivo del periférico de entradas.]

### Diagrama

![Entradas Jugador 1](imagenes/jugador1_nivel_3.png)

**Figura X. Diagrama de tercer nivel de las entradas del Jugador 1.**

### Descripción del funcionamiento

[Explicar el recorrido desde las entradas físicas hasta el registro leído por el CPU.]

### Bloques internos

| Bloque | Función |
|---|---|
| Sincronizadores de botones | |
| Debouncers | |
| Sincronizadores de switches | |
| Registro Status | |
| MUX de lectura | |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `btn_up_i` | Entrada | | |
| `btn_down_i` | Entrada | | |
| `btn_left_i` | Entrada | | |
| `btn_right_i` | Entrada | | |
| `btn_center_i` | Entrada | | |
| `sw_sel_i` | Entrada | | |
| `sw_rst_i` | Entrada | | |
| `addr_i` | Entrada | | |
| `rdata_o` | Salida | | |
| `clk_i` | Entrada | | |
| `rst_i` | Entrada | | |

### Mapeo del registro Status

| Bit | Señal | Descripción |
|---:|---|---|
| | | |

### Señales internas relevantes

| Señal | Descripción |
|---|---|
| | |

### Decisiones y justificación

[Explicar la necesidad de sincronización, debouncing y agrupación en un registro.]

---

## 7.6 Indicadores

### Objetivo

[Describir el objetivo del subsistema de indicadores.]

### Diagrama

![Indicadores](imagenes/indicadores_nivel_3.png)

**Figura X. Diagrama de tercer nivel del subsistema de indicadores.**

### Descripción del funcionamiento

[Explicar por separado el funcionamiento del display, LED y buzzer.]

### Bloques internos

| Bloque | Función |
|---|---|
| Decodificador de dirección/escritura | |
| Registro Display | |
| Conversión/separación de dígitos | |
| Decodificador 7 segmentos | |
| Multiplexor de display | |
| Registro LED | |
| Registro Buzzer | |
| Selector de sonido | |
| Generador de frecuencia | |
| MUX de lectura | |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `addr_i` | Entrada | | |
| `wdata_i` | Entrada | | |
| `write_enable_i` | Entrada | | |
| `rdata_o` | Salida | | |
| `seg_o` | Salida | | |
| `an_o` | Salida | | |
| `led_o` | Salida | | |
| `buzzer_o` | Salida | | |
| `clk_i` | Entrada | | |
| `rst_i` | Entrada | | |

### Registros internos

| Registro | Función | Dirección / `addr_i` |
|---|---|---|
| Display | | |
| LED | | |
| Buzzer | | |

### Eventos del buzzer

| Evento | Código / tono | Descripción |
|---|---|---|
| Impacto | | |
| Fallo | | |
| Barco hundido | | |
| Colocación inválida | | |
| Victoria | | |

### Decisiones y justificación

[Explicar la separación en registros y la lógica de control de cada salida.]

---

## 7.7 VGA

### Objetivo

[Describir el objetivo del periférico VGA.]

### Diagrama

![VGA](imagenes/vga_nivel_3.png)

**Figura X. Diagrama de tercer nivel del periférico VGA.**

### Descripción del funcionamiento

[Explicar el flujo desde la memoria de video hasta la generación de las señales VGA.]

### Bloques internos

| Bloque | Función |
|---|---|
| Interfaz memory-mapped | |
| Video RAM | |
| Generador de timing VGA | |
| Contador horizontal | |
| Contador vertical | |
| Cálculo de tile / posición | |
| Generador de píxel | |
| Generador RGB monocromático | |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk_i` | Entrada | | |
| `clk_pixel_i` | Entrada | | |
| `rst_i` | Entrada | | |
| `addr_i` | Entrada | | |
| `wdata_i` | Entrada | | |
| `write_enable_i` | Entrada | | |
| `rdata_o` | Salida | | |
| `vga_red_o` | Salida | | |
| `vga_green_o` | Salida | | |
| `vga_blue_o` | Salida | | |
| `vga_hsync_o` | Salida | | |
| `vga_vsync_o` | Salida | | |

### Señales internas relevantes

| Señal | Ancho | Descripción |
|---|---:|---|
| `h_count` | | |
| `v_count` | | |
| `pixel_x` | | |
| `pixel_y` | | |
| `video_active` | | |
| `video_addr` | | |
| `tile_data` | | |
| `pixel_on` | | |

### Organización de memoria de video

| Parámetro | Valor |
|---|---|
| Resolución VGA | |
| Frecuencia de refresco | |
| Reloj de píxel | |
| Número de tiles | |
| Tamaño de tile | |
| Rango de memoria | |

### Temporización VGA

[Agregar parámetros y ecuaciones de sincronización horizontal y vertical.]

### Decisiones y justificación

[Explicar el uso de tiles, salida monocromática y organización de la memoria de video.]

---
