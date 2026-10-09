HORIZONTAL = "H"
VERTICAL = "V"


class Barco:

    def __init__(
        self,
        nombre,
        tamano
    ):

        self.nombre = nombre
        self.tamano = tamano
        self.posiciones = []


    def calcular_posiciones(
        self,
        fila,
        columna,
        orientacion
    ):

        if orientacion == HORIZONTAL:

            return [
                (
                    fila,
                    columna + i
                )
                for i in range(
                    self.tamano
                )
            ]

        return [
            (
                fila + i,
                columna
            )
            for i in range(
                self.tamano
            )
        ]


    def colocar(
        self,
        tablero,
        fila,
        columna,
        orientacion
    ):

        self.posiciones = (
            self.calcular_posiciones(
                fila,
                columna,
                orientacion
            )
        )

        for f, c in self.posiciones:

            tablero.marcar_barco(
                f,
                c
            )