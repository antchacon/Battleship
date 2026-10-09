
import time
import inspect
from collections import deque

from UART import UART, listar_puertos, ReinicioPartida
from tablero import TablerosJugador
from barcos import Barco
from disparos import Disparos
from interfaz import Interfaz

from protocolo import (
    codificar_colocacion,
    codificar_disparo
)

from recepcion_colocacion import recibir_colocacion
from recepcion_disparos import RecepcionDisparos


VERDE = "#00FF55"
ROJO = "#FF3030"
AMARILLO = "#FFD700"

BATTLE_START = 0x20
J1_WIN = 0x7C
J2_WIN = 0x7E

SHOT_MESSAGE_SECONDS = 8.0


# =========================================================
# UART CON BUFFER
# =========================================================

class UARTConBuffer:

    def __init__(self, uart):
        self._uart = uart
        self._pendientes = deque()

    def recibir(self):

        if self._pendientes:
            dato = self._pendientes.popleft()

            print(
                f"UART buffer -> byte recuperado: {dato:02X}"
            )

            return dato

        return self._uart.recibir()

    def devolver(self, dato):

        if dato is not None:
            self._pendientes.appendleft(dato)

    def limpiar_entrada(self):

        self._pendientes.clear()
        return self._uart.limpiar_entrada()

    def __getattr__(self, nombre):
        return getattr(self._uart, nombre)


# =========================================================
# ACTUALIZAR INTERFAZ
# =========================================================

def actualizar_interfaz(interfaz):

    if hasattr(interfaz, "root"):
        interfaz.root.update()


# =========================================================
# DURACION DE LOS MENSAJES
# =========================================================

def mantener_aviso(
    interfaz,
    segundos=SHOT_MESSAGE_SECONDS
):

    previo = getattr(
        interfaz,
        "_aviso_pendiente",
        None
    )

    if previo is not None:
        try:
            interfaz.root.after_cancel(previo)
        except Exception:
            pass

    interfaz._aviso_pendiente = None
    interfaz._aviso_hasta = (
        time.monotonic() + segundos
    )


def mostrar_indicacion_turno(
    interfaz,
    mensaje,
    color
):

    restante = (
        getattr(interfaz, "_aviso_hasta", 0)
        - time.monotonic()
    )

    if restante <= 0:

        interfaz.mostrar_mensaje(
            mensaje,
            color
        )

        return

    def finalizar():

        interfaz._aviso_pendiente = None

        if time.monotonic() >= getattr(
            interfaz,
            "_aviso_hasta",
            0
        ):

            interfaz.mostrar_mensaje(
                mensaje,
                color
            )

    previo = getattr(
        interfaz,
        "_aviso_pendiente",
        None
    )

    if previo is not None:
        try:
            interfaz.root.after_cancel(previo)
        except Exception:
            pass

    interfaz._aviso_pendiente = (
        interfaz.root.after(
            max(1, int(restante * 1000) + 1),
            finalizar
        )
    )


def cancelar_aviso_anterior(interfaz):

    previo = getattr(
        interfaz,
        "_aviso_pendiente",
        None
    )

    if previo is not None:
        try:
            interfaz.root.after_cancel(previo)
        except Exception:
            pass

    interfaz._aviso_pendiente = None
    interfaz._aviso_hasta = 0


# =========================================================
# CREAR BARCOS
# =========================================================

def crear_barcos():

    return [
        Barco("Barco 4", 4),
        Barco("Barco 3", 3),
        Barco("Barco 2", 2)
    ]


# =========================================================
# ESPERAR INICIO DE BATALLA
# =========================================================

def esperar_inicio_batalla(
    uart,
    interfaz
):

    interfaz.mostrar_mensaje(
        "FLOTA DEL JUGADOR 2 LISTA\n"
        "Esperando que el Jugador 1 termine su colocación...",
        VERDE
    )

    while True:

        dato = uart.recibir()

        if dato is None:

            actualizar_interfaz(interfaz)
            interfaz.comprobar_reset()

            time.sleep(0.01)
            continue

        print(
            f"FPGA -> PC evento: {dato:08b}"
        )

        if dato == BATTLE_START:

            interfaz.mostrar_mensaje(
                "AMBOS JUGADORES LISTOS\n"
                "INICIO DE BATALLA",
                VERDE
            )

            actualizar_interfaz(interfaz)

            return


# =========================================================
# SELECCIONAR DISPARO J2
# =========================================================

def seleccionar_disparo_j2(
    disparos,
    interfaz,
    tableros
):

    metodo = disparos.seleccionar_disparo

    cantidad_parametros = len(
        inspect.signature(metodo).parameters
    )

    if cantidad_parametros == 1:

        return metodo(
            tableros.rival
        )

    return metodo(
        interfaz,
        tableros
    )


# =========================================================
# VERIFICAR FIN DE PARTIDA
# =========================================================

def revisar_fin_partida(
    uart,
    interfaz
):

    inicio = time.monotonic()

    while time.monotonic() - inicio < 0.15:

        dato = uart.recibir()

        if dato is None:

            actualizar_interfaz(interfaz)
            interfaz.comprobar_reset()

            time.sleep(0.005)
            continue

        print(
            f"FPGA -> PC evento: {dato:08b}"
        )

        # =============================================
        # GANA JUGADOR 1
        # =============================================

        if dato == J1_WIN:

            interfaz.mostrar_mensaje(
                "DERROTA\nFin del juego",
                ROJO
            )

            interfaz.root.title(
                "Battleship - Derrota"
            )

            return True

        # =============================================
        # GANA JUGADOR 2
        # =============================================

        if dato == J2_WIN:

            interfaz.mostrar_mensaje(
                "VICTORIA\nFin del juego",
                VERDE
            )

            interfaz.root.title(
                "Battleship - Victoria"
            )

            return True

        # =============================================
        # CONSERVAR OTROS BYTES
        # =============================================

        uart.devolver(dato)

        break

    return False


# =========================================================
# ESPERAR NUEVA PARTIDA
# =========================================================

def esperar_nueva_partida(
    uart,
    interfaz
):

    texto_actual = (
        interfaz.mensaje_label.cget("text")
    )

    color_actual = (
        interfaz.mensaje_label.cget("fg")
    )

    interfaz.mostrar_mensaje(
        texto_actual
        + "\n\nPresiona CENTER para otra partida "
        "o SW15 para reiniciar los contadores.",
        color_actual
    )

    while True:

        actualizar_interfaz(interfaz)

        # El reset se detecta mediante ReinicioPartida.
        dato = uart.recibir()

        if dato is not None:

            print(
                "Byte recibido después del fin: "
                f"{dato:02X}"
            )

        time.sleep(0.01)


# =========================================================
# UNA PARTIDA COMPLETA
# =========================================================

def jugar_partida(
    uart,
    interfaz
):

    # =====================================================
    # INICIALIZACION
    # =====================================================

    tableros = TablerosJugador()
    barcos = crear_barcos()
    disparos = Disparos()

    recepcion = RecepcionDisparos(barcos)

    cancelar_aviso_anterior(interfaz)

    interfaz.mostrar(tableros)

    # =====================================================
    # COLOCACION DEL JUGADOR 2
    # =====================================================

    interfaz.set_modo_colocacion(True)
    interfaz.mostrar_turno(2)

    interfaz.mostrar_mensaje(
        "JUGADOR 2 - COLOCACIÓN DE FLOTA",
        VERDE
    )

    for id_barco, barco in enumerate(barcos):

        colocado = False

        while not colocado:

            if uart.jugador1_listo():

                interfaz.mostrar_mensaje(
                    "FLOTA DEL JUGADOR 1 LISTA\n"
                    "Esperando la flota del Jugador 2...",
                    AMARILLO
                )

            interfaz.root.title(
                f"Jugador 2 - Colocación - {barco.nombre}"
            )

            # =========================================
            # SELECCIONAR POSICION
            # =========================================

            fila, columna, orientacion = (
                interfaz.seleccionar_barco(
                    tableros,
                    barco.tamano
                )
            )

            # =========================================
            # CODIFICAR COLOCACION
            # =========================================

            encabezado, posicion = (
                codificar_colocacion(
                    id_barco,
                    fila,
                    columna,
                    orientacion
                )
            )

            # =========================================
            # ENVIAR COLOCACION
            # =========================================

            uart.enviar(encabezado)
            uart.enviar(posicion)

            print(
                f"PC -> FPGA colocación {id_barco}: "
                f"{encabezado:08b} "
                f"{posicion:08b}"
            )

            # =========================================
            # RECIBIR RESULTADO
            # =========================================

            aceptado = recibir_colocacion(
                uart,
                interfaz
            )

            if aceptado:

                barco.colocar(
                    tableros.propio,
                    fila,
                    columna,
                    orientacion
                )

                interfaz.mostrar(tableros)

                colocado = True

    # =====================================================
    # FIN DE COLOCACION
    # =====================================================

    interfaz.set_modo_colocacion(False)

    esperar_inicio_batalla(
        uart,
        interfaz
    )

    # =====================================================
    # CONTROL DE TURNOS
    #
    # Cada disparo válido consume un turno.
    # Un disparo repetido no cambia el turno.
    # =====================================================

    turno_actual = 1

    while True:

        # =================================================
        # TURNO JUGADOR 1 - FPGA
        # =================================================

        if turno_actual == 1:

            interfaz.root.title(
                "Battleship - Turno Jugador 1"
            )

            interfaz.mostrar_turno(1)

            mostrar_indicacion_turno(
                interfaz,
                "¡Calibra tus tanques y ataca al enemigo!",
                VERDE
            )

            # =========================================
            # ESPERAR DISPARO DEL JUGADOR 1
            # =========================================

            respuesta_j1 = (
                recepcion.recibir_jugador_1(
                    uart,
                    interfaz,
                    tableros
                )
            )

            print(
                "FPGA -> PC disparo J1: "
                f"fila={respuesta_j1['fila']}, "
                f"columna={respuesta_j1['columna']}, "
                f"acierto={respuesta_j1['acierto']}"
            )

            # =========================================
            # VERIFICAR FIN DE PARTIDA
            # =========================================

            if revisar_fin_partida(
                uart,
                interfaz
            ):

                esperar_nueva_partida(
                    uart,
                    interfaz
                )

            # =========================================
            # MANTENER MENSAJE
            # =========================================

            if respuesta_j1["acierto"]:

                mantener_aviso(interfaz)

            # =========================================
            # PASAR AL JUGADOR 2
            # =========================================

            turno_actual = 2

            continue

        # =================================================
        # TURNO JUGADOR 2 - PC
        # =================================================

        interfaz.root.title(
            "Battleship - Turno Jugador 2"
        )

        interfaz.mostrar_turno(2)

        mostrar_indicacion_turno(
            interfaz,
            "Prepara tu estrategia, calibra tus tanques\n"
            "y ataca al enemigo",
            VERDE
        )

        disparo_valido = False

        while not disparo_valido:

            # =========================================
            # SELECCIONAR CASILLA
            # =========================================

            fila, columna = (
                seleccionar_disparo_j2(
                    disparos,
                    interfaz,
                    tableros
                )
            )

            # =========================================
            # CODIFICAR DISPARO
            # =========================================

            dato_tx = codificar_disparo(
                fila,
                columna
            )

            print()
            print("PC -> FPGA disparo J2:")
            print(f"fila={fila}")
            print(f"columna={columna}")
            print(f"byte={dato_tx:08b}")

            # =========================================
            # ENVIAR DISPARO
            # =========================================

            uart.enviar(dato_tx)

            # =========================================
            # RECIBIR RESPUESTA
            # =========================================

            disparo_valido = (
                recepcion.recibir_jugador_2(
                    uart,
                    interfaz,
                    tableros,
                    fila,
                    columna
                )
            )

            # =========================================
            # DISPARO REPETIDO
            #
            # Si no fue válido, seleccionar otra casilla.
            # No pasar al Jugador 1.
            # =========================================

            if not disparo_valido:

                print(
                    "Disparo no aceptado. "
                    "Selecciona otra casilla."
                )

                continue

            # =========================================
            # DISPARO ACEPTADO
            # =========================================

            print(
                "Disparo del Jugador 2 procesado."
            )

        # =================================================
        # VERIFICAR VICTORIA
        # =================================================

        if revisar_fin_partida(
            uart,
            interfaz
        ):

            esperar_nueva_partida(
                uart,
                interfaz
            )

        # =================================================
        # MANTENER EL MENSAJE
        # =================================================

        mantener_aviso(interfaz)

        # =================================================
        # TERMINAR TURNO J2
        #
        # IMPORTANTE:
        #
        # Tanto un impacto como un fallo terminan
        # el turno del Jugador 2.
        # =================================================

        print(
            "Finalizó el turno del Jugador 2."
        )

        turno_actual = 1


# =========================================================
# MAIN
# =========================================================

def main(uart=None):

    # =====================================================
    # CONEXION UART
    # =====================================================

    if uart is None:

        listar_puertos()

        puerto = input(
            "\nPuerto COM de la FPGA: "
        ).strip()

        uart = UART(
            puerto_com=puerto,
            baudrate=115200,
            timeout=0.1
        )

    # =====================================================
    # ACTIVAR BUFFER
    # =====================================================

    if not isinstance(
        uart,
        UARTConBuffer
    ):

        uart = UARTConBuffer(uart)

    # =====================================================
    # CREAR INTERFAZ
    # =====================================================

    interfaz = Interfaz()

    interfaz.conectar_uart(uart)

    try:

        while True:

            try:

                jugar_partida(
                    uart,
                    interfaz
                )

            # =============================================
            # NUEVA PARTIDA DESDE FPGA
            # =============================================

            except ReinicioPartida:

                print()
                print(
                    "====================================="
                )
                print(
                    "RESET RECIBIDO DESDE FPGA"
                )
                print(
                    "Iniciando nueva partida..."
                )
                print(
                    "====================================="
                )

                cancelar_aviso_anterior(interfaz)

                time.sleep(0.05)

                # Eliminar datos de la partida anterior.
                uart.limpiar_entrada()

                interfaz.set_modo_colocacion(False)

                interfaz.mostrar(
                    TablerosJugador()
                )

                interfaz.mostrar_mensaje(
                    "NUEVA PARTIDA\n"
                    "Coloca nuevamente tu flota.",
                    AMARILLO
                )

                interfaz.root.title(
                    "Battleship - Nueva partida"
                )

                actualizar_interfaz(interfaz)

                time.sleep(0.15)

                continue

    except KeyboardInterrupt:

        print(
            "\nPrograma finalizado."
        )

    finally:

        if uart is not None:
            uart.cerrar()


if __name__ == "__main__":
    main()
