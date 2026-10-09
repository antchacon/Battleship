TAMANO_TABLERO = 8

AGUA = " "
BARCO = "*"
FALLO = "x"
IMPACTO = "O"


class Tablero:

    def __init__(self):

        self.casillas = [
            [
                AGUA
                for _ in range(TAMANO_TABLERO)
            ]
            for _ in range(TAMANO_TABLERO)
        ]


    def marcar_barco(
        self,
        fila: int,
        columna: int
    ) -> None:

        self.casillas[
            fila
        ][columna] = BARCO


    def marcar_impacto(
        self,
        fila: int,
        columna: int
    ) -> None:

        self.casillas[
            fila
        ][columna] = IMPACTO


    def marcar_fallo(
        self,
        fila: int,
        columna: int
    ) -> None:

        self.casillas[
            fila
        ][columna] = FALLO


    def obtener_casilla(
        self,
        fila: int,
        columna: int
    ) -> str:

        return self.casillas[
            fila
        ][columna]


    def limpiar(self) -> None:

        self.casillas = [
            [
                AGUA
                for _ in range(TAMANO_TABLERO)
            ]
            for _ in range(TAMANO_TABLERO)
        ]


class TablerosJugador:

    def __init__(self):

        self.propio = Tablero()
        self.rival = Tablero()


    # =================================================
    # BARCOS PROPIOS
    # =================================================

    def registrar_barco(
        self,
        fila: int,
        columna: int
    ) -> None:

        self.propio.marcar_barco(
            fila,
            columna
        )


    # =================================================
    # DISPARO DEL JUGADOR 1
    # SOBRE EL TABLERO RIVAL
    # =================================================

    def registrar_disparo_propio(
        self,
        fila: int,
        columna: int,
        acierto: bool
    ) -> None:

        if acierto:

            self.rival.marcar_impacto(
                fila,
                columna
            )

        else:

            self.rival.marcar_fallo(
                fila,
                columna
            )


    # =================================================
    # DISPARO RECIBIDO DEL JUGADOR 2
    # SOBRE NUESTRO TABLERO
    # =================================================

    def registrar_disparo_recibido(
        self,
        fila: int,
        columna: int,
        acierto: bool
    ) -> None:

        if acierto:

            self.propio.marcar_impacto(
                fila,
                columna
            )

        else:

            self.propio.marcar_fallo(
                fila,
                columna
            )


    # =================================================
    # MÉTODO ANTERIOR
    # SE MANTIENE POR COMPATIBILIDAD
    # =================================================

    def procesar_disparo_recibido(
        self,
        fila: int,
        columna: int
    ) -> bool:

        acierto = (
            self.propio.obtener_casilla(
                fila,
                columna
            )
            == BARCO
        )

        self.registrar_disparo_recibido(
            fila,
            columna,
            acierto
        )

        return acierto


    def reiniciar(self) -> None:

        self.propio.limpiar()
        self.rival.limpiar()