# Proyecto 3: Batalla Naval sobre un microprocesador RISC-V

## Informe técnico

**Institución:** Instituto Tecnológico de Costa Rica  
**Escuela:** Ingeniería Electrónica  
**Curso:** EL3313 — Taller de Diseño Digital  
**Semestre:** II Semestre 2026  
**Equipo:** 06  

## Integrantes

| Nombre | Carné |
|---|---|
| Yerlin Angelitte Gamboa Ortiz | 2022184205 |
| Anthony Fabián Chacón Montero | 2022117452 |

## Profesores

- Dr.-Ing. Jeferson González-Gómez

---

## 1. Introducción

El proyecto consiste en desarrollar un sistema de Batalla Naval para dos jugadores sobre una FPGA Basys 3, integrando un procesador RISC-V de 32 bits, memorias de programa y datos, periféricos de entrada y salida y una aplicación de PC. Su propósito es aplicar los conocimientos de diseño digital mediante la construcción de una plataforma capaz de ejecutar un programa en ensamblador e interactuar con dispositivos externos.

El Jugador 1 utiliza los botones y switches de la FPGA y observa la partida mediante un monitor VGA. El Jugador 2 interactúa mediante una aplicación gráfica desarrollada en Python, comunicada con la FPGA mediante UART. Cada jugador dispone de un tablero de 8 × 8 casillas y una flota de tres barcos de tamaños 4, 3 y 2. La visualización distingue el tablero propio del estado conocido del tablero rival, manteniendo ocultas las posiciones de los barcos enemigos que todavía no han sido descubiertos.

La arquitectura integra una ROM para las instrucciones, una RAM para los datos y una interconexión que permite acceder a los periféricos mediante memoria mapeada. El programa en ensamblador coordina las operaciones de la partida, mientras que los módulos de hardware proporcionan los recursos de comunicación, lectura de controles, generación de video e indicadores visuales y sonoros.

Este informe presenta los fundamentos teóricos, la arquitectura y las decisiones de implementación del sistema. También describe el programa en ensamblador, la aplicación de PC y el protocolo de comunicación UART, y analiza las pruebas realizadas, los resultados obtenidos y las limitaciones identificadas durante el desarrollo.

## 2. Objetivos

### 2.1 Objetivo general

Diseñar e implementar un sistema de Batalla Naval para dos jugadores sobre una FPGA Basys 3, utilizando un procesador RISC-V de 32 bits y periféricos mapeados en memoria, con una interfaz local mediante VGA y controles físicos y una interfaz remota en PC mediante UART.

### 2.2 Objetivos específicos

1. Integrar un procesador RISC-V previamente disponible con las memorias y los periféricos del sistema para ejecutar el programa de Batalla Naval en ensamblador.

2. Integrar las memorias de programa y datos con los periféricos mediante una interconexión con direccionamiento de memoria mapeada.

3. Desarrollar el programa en ensamblador para gestionar la colocación de barcos, la validación de disparos, la alternancia de turnos, la detección de hundimientos y la determinación del ganador.

4. Implementar una interfaz local que incluya generación de video VGA, lectura de botones y switches, displays de siete segmentos, LED y retroalimentación sonora.

5. Desarrollar una aplicación gráfica en Python y un protocolo UART que permitan al Jugador 2 introducir sus acciones y visualizar la información recibida desde la FPGA.

6. Evaluar el funcionamiento de los bloques y del sistema integrado mediante simulaciones y pruebas físicas, documentando los resultados, los problemas encontrados y las soluciones aplicadas.

---
## 3. Fundamentación teórica

### 3.1 Procesador RISC-V y lenguaje ensamblador

RISC-V es una arquitectura de conjunto de instrucciones que define las operaciones que puede ejecutar un procesador. Su conjunto base RV32I utiliza registros de 32 bits e incluye operaciones aritméticas, lógicas, de acceso a memoria y de control del flujo del programa [1]. El lenguaje ensamblador permite expresar estas instrucciones mediante nombres como `add`, `lw`, `sw` y `beq`.

En este proyecto se utiliza un procesador previamente disponible para ejecutar el programa de Batalla Naval. El trabajo comprende su integración con las memorias y los periféricos necesarios para el juego.

### 3.2 Memorias y acceso a periféricos

La memoria de instrucciones almacena el programa que ejecuta el procesador, mientras que la memoria de datos conserva información que cambia durante su ejecución, como los tableros, los disparos y el turno actual.

La entrada y salida mapeada en memoria permite acceder a los periféricos mediante direcciones asignadas a sus registros. Así, el programa puede utilizar instrucciones de lectura y escritura para consultar las entradas del jugador, intercambiar datos por UART y controlar los indicadores y el contenido de la pantalla.

### 3.3 Generación de video VGA

La interfaz VGA utiliza señales de color y señales de sincronización horizontal y vertical para formar una imagen. El circuito de video recorre la pantalla de manera continua y establece el color correspondiente a cada píxel [2].

La representación mediante tiles divide la pantalla en bloques cuya apariencia se determina mediante códigos almacenados en memoria. Una memoria de doble puerto permite que el procesador actualice estos códigos y que el circuito VGA los consulte mediante un puerto independiente [3]. Esta organización resulta adecuada para representar los tableros y sus distintos estados.

### 3.4 Comunicación UART y entradas del usuario

UART permite transmitir y recibir datos de forma serial sin compartir una señal de reloj entre los dispositivos. Ambos extremos deben utilizar la misma velocidad y el mismo formato de transmisión. En Batalla Naval, esta comunicación conecta la FPGA con la aplicación de Python; el protocolo del proyecto define cómo interpretar los datos de colocación, disparos y resultados.

Los botones mecánicos pueden generar varias transiciones al presionarse, fenómeno conocido como rebote. El circuito antirrebote acepta el cambio cuando la señal permanece estable durante un intervalo. Además, la sincronización adapta las entradas al reloj del sistema y reduce el riesgo de que sus cambios afecten el funcionamiento de la lógica.

## 4. Diseño y arquitectura del sistema

### 4.1 Descripción general

El sistema implementa el juego Batalla Naval para dos jugadores. El jugador 1 interactúa mediante los controles de la FPGA y visualiza su información en un monitor VGA. El jugador 2 utiliza una aplicación de Python en la computadora, conectada con la FPGA mediante UART.

Cada jugador dispone de un tablero de 8 × 8 casillas y una flota de tres barcos de longitudes 4, 3 y 2. La partida comprende la colocación de los barcos, el intercambio de disparos por turnos y la identificación del ganador cuando se hunde toda la flota contraria.

La FPGA integra un procesador RISC-V previamente disponible, la memoria de instrucciones, la memoria de datos y los periféricos del juego. El procesador ejecuta el programa en ensamblador y accede a los periféricos mediante registros mapeados en memoria.

El sistema de video genera la imagen para el jugador 1, mientras que la aplicación de Python presenta la información del jugador 2 y permite introducir sus acciones. Como salidas adicionales, la FPGA utiliza indicadores LED, displays de siete segmentos y un buzzer para comunicar estados y eventos de la partida.


### 4.2 Diagrama de primer nivel

El diagrama de primer nivel presenta una visión general del sistema Batalla Naval implementado en la FPGA, identificando sus principales componentes y las señales que permiten la interacción con el exterior.

Como entradas, el sistema recibe un reloj de 100 MHz, utilizado para sincronizar su funcionamiento, los botones para controlar las acciones del jugador 1 y la comunicación con la computadora del jugador 2. Esta última permite intercambiar información entre la FPGA y la aplicación desarrollada en Python.

Las salidas comprenden la interfaz VGA para visualizar el juego, los displays de siete segmentos y los LED para indicar estados de la partida, y el buzzer para proporcionar retroalimentación sonora.

Dentro del sistema se representa el procesador RISC-V, encargado de ejecutar el programa del juego, junto con las memorias ROM y RAM, utilizadas para almacenar las instrucciones y los datos necesarios durante la ejecución.

<p align="center">
  <img src="../Imágenes/Primer%20Nivel.jpg" width="650"><br>
  <em>Figura 1. Diagrama de primer nivel del sistema Batalla Naval.</em>
</p>

### 4.3 Diagrama de segundo nivel

El diagrama de segundo nivel muestra la organización interna del sistema Batalla Naval y las conexiones entre el procesador RISC-V, las memorias y los periféricos. También identifica las principales señales de control y los buses utilizados para intercambiar información entre los diferentes bloques.

El procesador RISC-V constituye la unidad central del sistema. Se conecta directamente con la memoria ROM mediante las señales de dirección e instrucción, permitiendo obtener el programa que debe ejecutar. Por otra parte, se comunica con la RAM y los periféricos a través del bloque de interconexión y mapeo de memoria, utilizando señales de dirección, datos y habilitación de escritura.

La memoria RAM almacena la información utilizada durante la ejecución del juego y recibe las señales necesarias para realizar operaciones de lectura y escritura. El bloque de interconexión determina el destino de cada acceso según la dirección proporcionada por el procesador, permitiendo compartir el espacio de direccionamiento entre la memoria de datos y los periféricos.

Los periféricos se organizan en cuatro bloques principales: Jugador 1, UART, VGA e Indicadores. El primero recibe los botones y switches de la FPGA, UART permite la transmisión y recepción de información con la computadora, VGA genera las señales de color y sincronización para el monitor, y el bloque de indicadores controla los displays de siete segmentos, LED y buzzer. Estos bloques se comunican con el procesador mediante la interconexión de memoria y sus respectivos buses de periféricos.

Finalmente, las señales de reloj y reinicio permiten sincronizar e inicializar los componentes del sistema, mientras que el módulo VGA dispone adicionalmente de un reloj de píxel para la generación de video.

<p align="center">
  <img src="../Imágenes/Segundo%20Nivel.jpg" width="800"><br>
  <em>Figura 2. Diagrama de segundo nivel de la arquitectura e interconexión del sistema Batalla Naval.</em>
</p>


### 4.4 Diagramas de tercer nivel

Los diagramas de tercer nivel presentan con mayor detalle la organización interna de los bloques funcionales del sistema Batalla Naval. Estos permiten identificar los módulos que conforman cada periférico, las señales utilizadas y las conexiones necesarias para su funcionamiento.

Para facilitar su interpretación, los diagramas se presentan de manera independiente, incluyendo las memorias ROM y RAM, la interconexión de memoria, las entradas del jugador 1, la comunicación UART, el sistema VGA y los indicadores.

#### 4.4.1 Memoria ROM

La memoria ROM almacena las instrucciones del programa de Batalla Naval que ejecuta el procesador RISC-V. Su estructura incluye un bloque de conversión que transforma la dirección de 32 bits (`prog_address_i`) en un índice de acceso (`addr_index`), utilizado para seleccionar la instrucción correspondiente.

La memoria recibe las señales de reloj (`clk_i`) y reinicio (`rst_i`), mientras que el bloque de inicialización proporciona el contenido del programa. Finalmente, la instrucción seleccionada se entrega al procesador mediante la salida `prog_instr`.

<p align="center">
  <img src="../Imágenes/ROM.jpeg" width="550"><br>
  <em>Figura 3. Diagrama de tercer nivel de la memoria ROM.</em>
</p>


#### 4.4.2 Memoria RAM

La memoria RAM permite almacenar y consultar los datos utilizados durante la ejecución del juego. Su estructura incluye un bloque de conversión que transforma la dirección de entrada (`addr_i`) en un índice para acceder a las posiciones de memoria.

La lógica de escritura controla el almacenamiento de datos mediante las señales `wdata_i` y `write_enable_i`. Por su parte, el buffer de lectura entrega el contenido seleccionado mediante `rdata_o[31:0]`. Las señales de reloj (`clk_i`) y reinicio (`rst_i`) permiten controlar el funcionamiento del bloque.

<p align="center">
  <img src="../Imágenes/RAM.jpeg" width="550"><br>
  <em>Figura 4. Diagrama de tercer nivel de la memoria RAM.</em>
</p>

#### 4.4.3 Interconexión y mapeo de memoria

El bloque de interconexión permite comunicar el procesador RISC-V con la memoria RAM y los periféricos mediante direcciones mapeadas en memoria. Su estructura está compuesta por un decodificador de direcciones, un decodificador de escritura y un multiplexor de lectura.

El decodificador de direcciones genera las señales de selección (`sel_ram`, `sel_uart`, `sel_vga`, `sel_j1` y `sel_ind`) para identificar el dispositivo correspondiente. El decodificador de escritura controla las habilitaciones de escritura de cada bloque, mientras que el multiplexor selecciona los datos de lectura que deben regresar al procesador. Esta organización permite gestionar los accesos a memoria y periféricos desde una misma interfaz.

<p align="center">
  <img src="../Imágenes/Interconexion.jpeg" width="750"><br>
  <em>Figura 5. Diagrama de tercer nivel de la interconexión y mapeo de memoria.</em>
</p>

#### 4.4.4 Entradas del jugador 1

El bloque de entradas del jugador 1 permite procesar las señales provenientes de los botones y switches de la FPGA. Los sincronizadores adaptan estas señales al reloj del sistema, mientras que los circuitos antirrebote (*debouncers*) eliminan las transiciones no deseadas producidas por los botones mecánicos.

Las señales procesadas se almacenan en un registro de estado de 32 bits (`status_reg`), que reúne la información de los controles. Finalmente, un multiplexor de lectura utiliza la dirección `addr_i[1:0]` para seleccionar los datos que se entregan al procesador mediante `rdata_o[31:0]`.

<p align="center">
  <img src="../Imágenes/Entradas%20Jugador%201.jpeg" width="750"><br>
  <em>Figura 6. Diagrama de tercer nivel del bloque de entradas del jugador 1.</em>
</p>


#### 4.4.5 Comunicación UART

El bloque UART permite la comunicación bidireccional entre la FPGA y la computadora. Su estructura incluye los módulos UART RX y UART TX, encargados de recibir y transmitir datos seriales, respectivamente. Ambos utilizan un generador de baudios que proporciona la señal de temporización (`baud_tick`).

Los registros RX y TX almacenan los datos recibidos y los que serán transmitidos. La lógica de decodificación controla las operaciones de escritura, mientras que el registro de estado conserva señales como `rx_ready`, `tx_busy` y `tx_done`. Finalmente, un multiplexor de lectura permite al procesador consultar los datos recibidos y el estado de la comunicación mediante `rdata_o[31:0]`.

<p align="center">
  <img src="../Imágenes/UART.jpeg" width="650"><br>
  <em>Figura 7. Diagrama de tercer nivel del módulo de comunicación UART.</em>
</p>

#### 4.4.6 Sistema VGA

El sistema VGA se encarga de generar la imagen del juego en el monitor. Su arquitectura incluye un bloque de memoria mapeada que permite al procesador acceder a la memoria de video para actualizar la información visual. El generador de temporización utiliza el reloj de píxel (`clk_pixel_i`) para producir las coordenadas de pantalla (`pixel_x`, `pixel_y`) y las señales de sincronización horizontal y vertical.

El bloque de cálculo de posición determina las coordenadas del tile y la dirección de memoria correspondiente. El generador de píxel utiliza esta información y los datos almacenados en la memoria de video para determinar qué píxeles deben activarse. Finalmente, el generador RGB convierte esta información en las señales de color `vga_red_o`, `vga_green_o` y `vga_blue_o`, necesarias para representar la imagen.

<p align="center">
  <img src="../Imágenes/VGA.png" width="700"><br>
  <em>Figura 8. Diagrama de tercer nivel del sistema VGA.</em>
</p>

#### 4.4.7 Indicadores

El bloque de indicadores permite comunicar visual y auditivamente los estados del juego mediante los displays de siete segmentos, LED y buzzer. Su estructura incluye un decodificador de dirección y escritura que genera las señales de habilitación para los registros de cada dispositivo.

El registro del display almacena la información que posteriormente se separa en dígitos, se convierte a siete segmentos y se multiplexa para su visualización. El registro LED controla los indicadores luminosos, mientras que el registro del buzzer proporciona la información al selector de sonido y al generador de frecuencia. Finalmente, un multiplexor de lectura permite al procesador consultar el contenido de los registros mediante `rdata_o[31:0]`.

<p align="center">
  <img src="../Imágenes/Indicadores.jpg" width="750"><br>
  <em>Figura 9. Diagrama de tercer nivel del bloque de indicadores.</em>
</p>

## 13. Referencias

[1] RISC-V International. *RV32I Base Integer Instruction Set, Version 2.1*. [En línea]. Disponible en: https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html. Consultado: 8 de octubre de 2026.

[2] Digilent. *Basys 3 FPGA Board Reference Manual*. [En línea]. Disponible en: https://digilent.com/reference/_media/basys3:basys3_rm.pdf. Consultado: 8 de octubre de 2026.

[3] AMD/Xilinx. *7 Series FPGAs Memory Resources User Guide (UG473)*. [En línea]. Disponible en: https://docs.amd.com/v/u/en-US/ug473_7Series_Memory_Resources. Consultado: 8 de octubre de 2026.

