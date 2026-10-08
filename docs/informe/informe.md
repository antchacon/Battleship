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

El diagrama de primer nivel representa el sistema completo y sus conexiones con el exterior. Incluye los controles del jugador 1, la comunicación con la computadora del jugador 2 y las salidas hacia el monitor VGA, los indicadores y el buzzer. Su propósito es identificar las entradas y salidas sin detallar todavía los módulos internos.

## 13. Referencias

[1] RISC-V International. *RV32I Base Integer Instruction Set, Version 2.1*. [En línea]. Disponible en: https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html. Consultado: 8 de octubre de 2026.

[2] Digilent. *Basys 3 FPGA Board Reference Manual*. [En línea]. Disponible en: https://digilent.com/reference/_media/basys3:basys3_rm.pdf. Consultado: 8 de octubre de 2026.

[3] AMD/Xilinx. *7 Series FPGAs Memory Resources User Guide (UG473)*. [En línea]. Disponible en: https://docs.amd.com/v/u/en-US/ug473_7Series_Memory_Resources. Consultado: 8 de octubre de 2026.

