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

El segundo nivel divide el sistema en sus subsistemas principales y muestra
cómo se comunican con el procesador.

## 6.2 Diagrama

![Diagrama de segundo nivel](imagenes/diagrama_nivel_2.png)

**Figura 2. Arquitectura de segundo nivel del sistema.**

## 6.3 Subsistemas

| Subsistema | Función |
|---|---|
| Procesamiento RISC-V | Ejecutar el programa del juego |
| ROM | Almacenar las instrucciones |
| RAM | Almacenar datos variables |
| Interconexión | Realizar el mapeo de memoria |
| Entradas Jugador 1 | Leer botones y switches |
| UART | Comunicar FPGA y PC |
| VGA | Generar la imagen del juego |
| Indicadores | Controlar displays, LED y buzzer |

## 6.4 Justificación de la arquitectura

La arquitectura utiliza un bloque de interconexión entre el procesador y los
periféricos para implementar memoria mapeada.

Esta decisión permite que el RISC-V acceda a RAM y periféricos mediante
operaciones normales de lectura y escritura, simplificando el programa en
ensamblador y manteniendo una interfaz común entre subsistemas.

---

# 7. Diseño de tercer nivel

En esta sección se presenta la arquitectura interna propuesta para cada
subsistema.

---

## 7.1 Procesamiento RISC-V

### Objetivo

[Describir la función del procesador dentro del sistema.]

### Diagrama

![Procesamiento RISC-V](imagenes/riscv_nivel_3.png)

**Figura 3. Diagrama de tercer nivel del procesador RISC-V.**

### Bloques internos

| Bloque | Función |
|---|---|
| Program Counter | |
| Banco de registros | |
| ALU | |
| Unidad de control | |
| Generador de inmediatos | |
| Lógica de branch/jump | |
| MUX de operandos | |
| MUX de write-back | |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `clk_i` | Entrada | 1 | |
| `rst_i` | Entrada | 1 | |
| `prog_instr_i` | Entrada | 32 | |
| `data_in_i` | Entrada | 32 | |
| `prog_address_o` | Salida | 32 | |
| `data_address_o` | Salida | 32 | |
| `data_out_o` | Salida | 32 | |
| `data_we_o` | Salida | 1 | |

### Decisiones y justificación

[Explicar por qué se seleccionó esta arquitectura para el procesador.]

---

## 7.2 Memoria ROM

### Objetivo

La ROM almacena el programa en ensamblador que será ejecutado por el
procesador RISC-V.

### Diagrama

![ROM](imagenes/rom_nivel_3.png)

**Figura 4. Diagrama de tercer nivel de la memoria ROM.**

### Bloques internos

| Bloque | Función |
|---|---|
| Conversión de dirección a índice | |
| Memoria de programa | |
| Inicialización | |

### Entradas y salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---:|---|
| `prog_address_i` | Entrada | 32 | |
| `prog_instr_o` | Salida | 32 | |
| `clk_i` | Entrada | 1 | |
| `rst_i` | Entrada | 1 | |

### Organización de memoria

[Indicar profundidad, ancho de palabra y forma de inicialización.]

### Justificación

[Explicar por qué se utiliza una ROM independiente de la memoria de datos.]

---

## 7.3 Memoria RAM

### Objetivo

La RAM almacena los datos que cambian durante la partida.

### Diagrama

![RAM](imagenes/ram_nivel_3.png)

**Figura 5. Diagrama de tercer nivel de la RAM.**

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
| `wdata_i` | Entrada | 32 | |
| `write_enable_i` | Entrada | 1 | |
| `rdata_o` | Salida | 32 | |
| `clk_i` | Entrada | 1 | |
| `rst_i` | Entrada | 1 | |

### Organización de datos en RAM

| Región | Información almacenada | Tamaño |
|---|---|---:|
| Tablero Jugador 1 | | |
| Tablero Jugador 2 | | |
| Estado de barcos J1 | | |
| Estado de barcos J2 | | |
| Turno actual | | |
| Contadores | | |
| Variables auxiliares | | |

### Justificación

[Explicar la organización seleccionada para representar los tableros y
variables del juego.]

---

## 7.4 Interconexión y mapeo de memoria

### Objetivo

Permitir que el RISC-V acceda a RAM y periféricos utilizando un único espacio
de direcciones.

### Diagrama

![Mapeo de memoria](imagenes/mapeo_memoria_nivel_3.png)

**Figura 6. Diagrama de interconexión y mapeo de memoria.**

### Bloques internos

| Bloque | Función |
|---|---|
| Decodificador de direcciones | Selecciona el dispositivo correspondiente |
| Decodificador de escritura | Genera las señales `write_enable` |
| Multiplexor de lectura | Selecciona el dato que regresa al procesador |

### Señales de selección

| Señal | Dispositivo |
|---|---|
| `sel_ram` | RAM |
| `sel_uart` | UART |
| `sel_vga` | VGA |
| `sel_j1` | Entradas Jugador 1 |
| `sel_ind` | Indicadores |

### Mapa de memoria

| Dispositivo | Dirección inicial | Dirección final | Uso |
|---|---:|---:|---|
| RAM | TBD | TBD | Memoria de datos |
| UART | TBD | TBD | Comunicación con PC |
| VGA | TBD | TBD | Memoria de video |
| Entradas J1 | TBD | TBD | Botones y switches |
| Indicadores | TBD | TBD | Displays, LED, buzzer |

### Decodificación

Agregar aquí las ecuaciones o condiciones utilizadas para generar:

```text
sel_ram
sel_uart
sel_vga
sel_j1
sel_ind
