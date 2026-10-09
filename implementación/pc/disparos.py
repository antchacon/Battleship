class Disparos:

    def seleccionar_disparo(
        self,
        interfaz,
        tableros
    ):

        return interfaz.seleccionar(
            tableros,
            rival=True
        )