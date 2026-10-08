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

### 3.1 Arquitectura RISC-V y conjunto de instrucciones RV32I

RISC-V es una arquitectura de conjunto de instrucciones que define las operaciones que puede ejecutar un procesador y su comportamiento desde la perspectiva del software. La arquitectura especifica las instrucciones y los registros disponibles, mientras que su implementación interna puede adoptar distintas organizaciones, como un procesador de ciclo único o uno segmentado.

RV32I corresponde al conjunto base de instrucciones enteras de 32 bits. Dispone de 32 registros enteros, identificados desde x0 hasta x31, y de un contador de programa que contiene la dirección de la instrucción. El registro x0 mantiene siempre el valor cero. Las instrucciones base tienen una longitud de 32 bits y permiten realizar operaciones aritméticas, lógicas, desplazamientos, accesos a memoria y cambios en el flujo de ejecución [1].

Las instrucciones se organizan mediante los formatos R, I, S y U, junto con las variantes B y J para saltos. Sus campos codifican la operación, los registros y los valores inmediatos [1].

| Formato | Uso general | Ejemplos |
|---|---|---|
| R | Operaciones entre registros | add, sub, and, or |
| I | Operaciones con inmediato, cargas y salto indirecto | addi, lw, jalr |
| S | Almacenamiento en memoria | sw |
| B | Saltos condicionales | beq, bne, blt |
| U | Construcción de valores con un inmediato superior | lui, auipc |
| J | Salto con almacenamiento de dirección de retorno | jal |

En este proyecto se reutiliza un procesador RISC-V previamente disponible. El trabajo se concentra en su integración con las memorias y los periféricos y en la ejecución del programa de Batalla Naval. Las instrucciones necesarias permiten consultar los tableros, modificar variables, evaluar condiciones y acceder a los dispositivos de entrada y salida.

### 3.2 Camino de datos, unidad de control y segmentación

El camino de datos, o datapath, reúne los componentes que almacenan, seleccionan y procesan la información dentro del procesador. Entre sus elementos se encuentran el contador de programa, el banco de registros, la unidad aritmético-lógica, el generador de inmediatos y los multiplexores.

La unidad de control interpreta los campos de cada instrucción y genera las señales que coordinan estos componentes. Por ejemplo, determina qué operación realiza la unidad aritmético-lógica, si debe escribirse un registro y si corresponde efectuar una escritura en memoria.

En una organización de ciclo único, cada instrucción completa su ejecución dentro de un periodo de reloj. Por ello, el periodo debe permitir que termine el recorrido combinacional de la instrucción más lenta.

En una organización segmentada, o pipeline, la ejecución se divide en etapas separadas por registros. Una organización habitual comprende las siguientes:

| Etapa | Función |
|---|---|
| IF: búsqueda | Obtener la instrucción desde la memoria de programa |
| ID: decodificación | Interpretar la instrucción y leer los registros fuente |
| EX: ejecución | Realizar operaciones aritméticas, lógicas o cálculos de direcciones |
| MEM: memoria | Acceder a la memoria de datos o a los periféricos |
| WB: escritura de resultado | Actualizar el registro destino cuando corresponde |

La segmentación permite que varias instrucciones se encuentren en distintas etapas simultáneamente. Sin embargo, introduce dependencias que deben manejarse para conservar el resultado correcto del programa.

Un riesgo de datos ocurre cuando una instrucción necesita un resultado que otra todavía está calculando. Puede resolverse mediante reenvío de resultados, denominado forwarding, o mediante ciclos de espera. Los cambios de flujo también pueden exigir descartar instrucciones que se habían obtenido antes de conocer el destino de un salto.

El procesador reutilizado contiene registros entre etapas y una unidad de manejo de riesgos. Estos mecanismos son relevantes para el juego porque el ensamblador ejecuta secuencias de lectura, modificación y almacenamiento de datos, además de saltos asociados con las reglas y los turnos.

### 3.3 Memorias y periféricos mapeados en memoria

La memoria de programa almacena las instrucciones que ejecuta el procesador. En este sistema se utiliza una ROM inicializada mediante un archivo de memoria. La RAM almacena información variable, como los tableros y las variables de la partida.

El esquema de entrada y salida mapeada en memoria, o memory-mapped I/O, asigna direcciones a los registros o memorias de los periféricos. De esta manera, el procesador puede acceder a ellos mediante instrucciones de carga y almacenamiento.

La interconexión analiza la dirección generada por el procesador y selecciona el destino de cada acceso. Durante una escritura, dirige el dato y la habilitación hacia el dispositivo seleccionado. Durante una lectura, selecciona la respuesta que debe regresar al procesador.

Los registros de los periféricos suelen organizarse según su función:

| Tipo de registro | Propósito |
|---|---|
| Control | Configurar una operación o solicitar una acción |
| Estado | Informar condiciones como disponibilidad de datos o transmisión en curso |
| Datos | Almacenar información que se desea transmitir, recibir o representar |

Para que la comunicación entre hardware y software sea consistente, deben documentarse las direcciones, el significado de cada bit, los permisos de lectura y escritura, los valores de reinicio y los posibles efectos de cada acceso. También deben evitarse rangos superpuestos y escrituras sobre dispositivos no seleccionados.

Con palabras de 32 bits, las posiciones consecutivas alineadas se separan por cuatro bytes. La dirección de una posición puede expresarse como:

**Dirección = dirección base + 4 × índice**

En Batalla Naval, este mecanismo permite que el ensamblador consulte las entradas del jugador, intercambie información mediante UART y actualice la memoria de video y los registros de indicadores.

## 13. Referencias

[1] RISC-V International. “RV32I Base Integer Instruction Set, Version 2.1”.
https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html

