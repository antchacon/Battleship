
import time

from protocolo import decodificar_colocacion


def esperar_byte(
    uart,
    interfaz
) -> int:

    while True:

        dato = uart.recibir()

        if dato is not None:
            return dato

        # Puede llegar 0x31 mientras la PC
        # todavía está colocando barcos.
        interfaz.comprobar_eventos_colocacion()

        interfaz.root.update()

        time.sleep(0.01)


def recibir_colocacion(
    uart,
    interfaz
) -> bool:

    dato = esperar_byte(
        uart,
        interfaz
    )

    respuesta = decodificar_colocacion(dato)

    # =========================================
    # COLOCACION ACEPTADA
    # =========================================

    if respuesta["aceptado"]:

        interfaz.mostrar_mensaje(
            "Posición aceptada.",
            "#00FF55"
        )

        return True

    # =========================================
    # COLOCACION RECHAZADA
    # =========================================

    mensaje = "POSICIÓN RECHAZADA"

    # TRASLAPE
    if respuesta["error_traslape"]:

        mensaje += (
            "\n\n¡Ups! Tus barcos se hundirán, "
            "colócalos donde no choquen."
        )

    # FUERA DEL TABLERO
    if respuesta["error_fuera_tablero"]:

        mensaje += (
            "\n\nTu barco se está alejando, "
            "colócalo en el espacio de guerra."
        )

    interfaz.mostrar_mensaje(
        mensaje,
        "#FF3030"
    )

    return False
