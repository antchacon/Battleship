HORIZONTAL = "H"
VERTICAL = "V"


# =========================================================
# PC (JUGADOR 2) -> FPGA
# COLOCACION
#
# BYTE 0 = 0001 00II
#
# II:
# 00 = barco 4
# 01 = barco 3
# 10 = barco 2
#
# BYTE 1 = 0 O FFF CCC
#
# O   = orientacion
# FFF = fila
# CCC = columna
# =========================================================

def codificar_colocacion(
    id_barco: int,
    fila: int,
    columna: int,
    orientacion: str
) -> tuple[int, int]:

    if id_barco not in (
        0,
        1,
        2
    ):

        raise ValueError(
            "ID de barco no valido"
        )


    if not (
        0 <= fila <= 7
        and
        0 <= columna <= 7
    ):

        raise ValueError(
            "Fila o columna fuera de rango"
        )


    if orientacion == HORIZONTAL:

        bit_orientacion = 0


    elif orientacion == VERTICAL:

        bit_orientacion = 1


    else:

        raise ValueError(
            "Orientacion no valida"
        )


    encabezado = (
        0b00010000
        | id_barco
    )


    posicion = (

        (bit_orientacion << 6)

        | (fila << 3)

        | columna

    )


    return (
        encabezado,
        posicion
    )


# =========================================================
# PC (JUGADOR 2) -> FPGA
# DISPARO
#
# 1 0 FFF CCC
# =========================================================

def codificar_disparo(
    fila: int,
    columna: int
) -> int:


    if not (
        0 <= fila <= 7
        and
        0 <= columna <= 7
    ):

        raise ValueError(
            "Fila o columna fuera de rango"
        )


    dato = (

        (1 << 7)

        | (fila << 3)

        | columna

    )


    return dato


# =========================================================
# FPGA -> PC
# RESPUESTA DE COLOCACION
#
# bit0 = aceptado
# bit1 = traslape
# bit2 = fuera del tablero
# =========================================================

def decodificar_colocacion(
    dato: int
) -> dict:


    return {

        "aceptado":
            bool(
                dato
                & 0b00000001
            ),

        "error_traslape":
            bool(
                (dato >> 1)
                & 1
            ),

        "error_fuera_tablero":
            bool(
                (dato >> 2)
                & 1
            )

    }


# =========================================================
# FPGA -> PC
# DISPAROS
#
# bit0 = 0
# -----------------------------------------
# Respuesta al disparo realizado por J2/PC
#
# bit1 = acierto
# bit2 = disparo repetido
# bit3 = barco hundido
#
#
# bit0 = 1
# -----------------------------------------
# Disparo realizado por J1/FPGA
#
# bits[3:1] = columna
# bits[6:4] = fila
# bit7      = acierto
# =========================================================

def decodificar_disparo(
    dato: int
) -> dict:


    tipo = (
        dato
        & 1
    )


    if tipo == 0:

        acierto = bool(
            (dato >> 1)
            & 1
        )


        error_disparo = bool(
            (dato >> 2)
            & 1
        )


        barco_hundido = bool(
            (dato >> 3)
            & 1
        )


        return {

            "jugador": 2,

            "acierto":
                acierto,

            "error_disparo":
                error_disparo,

            "barco_hundido":
                barco_hundido

        }


    columna = (
        (dato >> 1)
        & 0b111
    )


    fila = (
        (dato >> 4)
        & 0b111
    )


    acierto = bool(
        (dato >> 7)
        & 1
    )


    return {

        "jugador": 1,

        "fila":
            fila,

        "columna":
            columna,

        "acierto":
            acierto,

        "error_disparo":
            False,

        "barco_hundido":
            False

    }