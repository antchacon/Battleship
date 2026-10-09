
import time

from protocolo import decodificar_disparo


ROJO = "#FF3030"
VERDE = "#00FF55"

MENSAJE_HUNDIMIENTO = (
    "¡Enhorabuena, has disminuido\n"
    "la flota del enemigo!"
)


class RecepcionDisparos:

    def __init__(self, barcos=None):

        self.barcos = (
            barcos if barcos is not None else []
        )

        self.impactos_recibidos = set()
        self.barcos_ya_hundidos = set()

        # Resultado del disparo más reciente de la PC.
        self.ultima_respuesta_j2 = None

    # =====================================================
    # HUNDIMIENTO DE UN BARCO DEL JUGADOR 2
    # =====================================================

    def hundimiento_jugador_1(
        self,
        fila,
        columna,
        acierto
    ):

        if not acierto:
            return False

        self.impactos_recibidos.add(
            (fila, columna)
        )

        for indice, barco in enumerate(self.barcos):

            posiciones = set(barco.posiciones)

            if (
                indice not in self.barcos_ya_hundidos
                and posiciones
                and (fila, columna) in posiciones
                and posiciones.issubset(
                    self.impactos_recibidos
                )
            ):

                self.barcos_ya_hundidos.add(indice)

                print(
                    f"Barco de J2 hundido: {indice}"
                )

                return True

        return False

    # =====================================================
    # RECEPCION UART
    # =====================================================

    def esperar_byte(
        self,
        uart,
        interfaz=None
    ) -> int:

        while True:

            dato = uart.recibir()

            if dato is not None:

                print(
                    f"FPGA -> PC byte recibido: {dato:08b}"
                )

                return dato

            if interfaz is not None:
                interfaz.root.update()

            time.sleep(0.01)

    # =====================================================
    # DISPARO DEL JUGADOR 2 (PC)
    # =====================================================

    def recibir_jugador_2(
        self,
        uart,
        interfaz,
        tableros,
        fila,
        columna
    ) -> bool:

        # Evitar utilizar el resultado anterior.
        self.ultima_respuesta_j2 = None

        dato = self.esperar_byte(
            uart,
            interfaz
        )

        respuesta = decodificar_disparo(dato)

        print(
            "Respuesta J2 decodificada:",
            respuesta
        )

        if respuesta["jugador"] != 2:

            print(
                "ERROR: se esperaba respuesta de J2, "
                f"pero llegó {dato:08b}"
            )

            return False

        # Guardar respuesta para el control de turnos.
        self.ultima_respuesta_j2 = respuesta

        # =============================================
        # DISPARO REPETIDO
        # =============================================

        if respuesta["error_disparo"]:

            interfaz.mostrar_mensaje(
                "¿Seguro que quieres repetir ese tiro?\n"
                "No parece una estrategia muy conveniente.",
                ROJO
            )

            return False

        acierto = respuesta["acierto"]
        hundido = respuesta.get(
            "barco_hundido",
            False
        )

        # =============================================
        # REGISTRAR DISPARO
        # =============================================

        tableros.registrar_disparo_propio(
            fila,
            columna,
            acierto
        )

        # =============================================
        # BARCO HUNDIDO
        # =============================================

        if hundido:

            mensaje = MENSAJE_HUNDIMIENTO
            color = VERDE

            print(
                "JUGADOR 2: BARCO ENEMIGO HUNDIDO"
            )

        # =============================================
        # IMPACTO NORMAL
        # =============================================

        elif acierto:

            mensaje = (
                "Excelente puntería, recarga tus cañones"
            )

            color = VERDE

        # =============================================
        # FALLO
        # =============================================

        else:

            mensaje = (
                "¡Ups! Tu disparo fue algo impreciso,\n"
                "piensa mejor tu estrategia"
            )

            color = ROJO

        # =============================================
        # ACTUALIZAR INTERFAZ
        # =============================================

        interfaz.mostrar(tableros)

        interfaz.mostrar_mensaje(
            mensaje,
            color
        )

        return True

    # =====================================================
    # DISPARO DEL JUGADOR 1 (FPGA)
    # =====================================================

    def recibir_jugador_1(
        self,
        uart,
        interfaz,
        tableros
    ) -> dict:

        dato = self.esperar_byte(
            uart,
            interfaz
        )

        respuesta = decodificar_disparo(dato)

        if respuesta["jugador"] != 1:

            raise ValueError(
                "Se esperaba un disparo del Jugador 1"
            )

        fila = respuesta["fila"]
        columna = respuesta["columna"]
        acierto = respuesta["acierto"]

        # =============================================
        # REGISTRAR DISPARO RECIBIDO
        # =============================================

        tableros.registrar_disparo_recibido(
            fila,
            columna,
            acierto
        )

        # =============================================
        # HUNDIMIENTO DE UNO DE NUESTROS BARCOS
        # =============================================

        hundido = self.hundimiento_jugador_1(
            fila,
            columna,
            acierto
        )

        respuesta["barco_hundido"] = hundido

        # =============================================
        # BARCO PROPIO HUNDIDO
        # =============================================

        if hundido:

            mensaje = (
                "¡Rayos! El enemigo ha hundido\n"
                "uno de tus barcos."
            )

            color = ROJO

        # =============================================
        # IMPACTO EN NUESTRA FLOTA
        # =============================================

        elif acierto:

            mensaje = (
                "¡Rayos! El contrincante descubrió tu estrategia,\n"
                "no dejes que tome ventaja."
            )

            color = ROJO

        # =============================================
        # FALLO ENEMIGO
        # =============================================

        else:

            mensaje = None
            color = None

        interfaz.mostrar(tableros)

        if mensaje is not None:

            interfaz.mostrar_mensaje(
                mensaje,
                color
            )

        return respuesta
