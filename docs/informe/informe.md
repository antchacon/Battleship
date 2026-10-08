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
