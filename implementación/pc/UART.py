
import serial
import serial.tools.list_ports

from collections import deque


RESET_EVENT = 0x30
J1_READY_EVENT = 0x31
BATTLE_START_EVENT = 0x20


class ReinicioPartida(Exception):
    pass


class UART:

    def __init__(
        self,
        puerto_com: str,
        baudrate: int = 115200,
        timeout: float = 0.1
    ) -> None:

        self.uart = serial.Serial(
            port=puerto_com,
            baudrate=baudrate,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=timeout,
            write_timeout=timeout
        )

        self._cola_rx = deque()

        self._reset_pendiente = False

        self._j1_ready_pendiente = False
        self._j1_ready_activo = False

        # False durante colocacion.
        # True cuando llega el evento 0x20.
        self._en_batalla = False

    # =====================================================
    # ENVIAR
    # =====================================================

    def enviar(self, dato: int) -> None:

        dato &= 0xFF

        self.uart.write(
            bytes([dato])
        )

        self.uart.flush()

    # =====================================================
    # PROCESAR BYTE RECIBIDO
    # =====================================================

    def _procesar_valor(
        self,
        valor: int
    ) -> None:

        valor &= 0xFF

        # =============================================
        # RESET DE PARTIDA
        # =============================================

        if valor == RESET_EVENT:

            self._reset_pendiente = True
            return

        # =============================================
        # INICIO DE BATALLA
        #
        # 0x20 indica que la colocacion termino.
        #
        # Desde este momento, 0x31 puede ser un disparo
        # valido del Jugador 1 y NO debe descartarse.
        # =============================================

        if (
            valor == BATTLE_START_EVENT
            and not self._en_batalla
        ):

            self._en_batalla = True

            self._cola_rx.append(valor)

            print(
                "UART: batalla iniciada. "
                "0x31 ahora se recibe como disparo."
            )

            return

        # =============================================
        # JUGADOR 1 TERMINO COLOCACION
        #
        # Este evento solo es especial ANTES
        # de que empiece la batalla.
        # =============================================

        if (
            valor == J1_READY_EVENT
            and not self._en_batalla
        ):

            self._j1_ready_pendiente = True
            self._j1_ready_activo = True

            print(
                "UART: Jugador 1 termino colocacion."
            )

            return

        # =============================================
        # BYTE NORMAL
        #
        # Durante la batalla, 0x31 tambien entra
        # aqui y queda disponible para Python.
        # =============================================

        self._cola_rx.append(valor)

    # =====================================================
    # CAPTURAR BYTES DISPONIBLES
    # =====================================================

    def _capturar_disponibles(self) -> None:

        cantidad = self.uart.in_waiting

        if cantidad <= 0:
            return

        datos = self.uart.read(cantidad)

        for valor in datos:
            self._procesar_valor(valor)

    # =====================================================
    # DETECTAR RESET
    # =====================================================

    def detectar_reset(self) -> bool:

        self._capturar_disponibles()

        if self._reset_pendiente:

            self._reset_pendiente = False

            return True

        return False

    # =====================================================
    # DETECTAR J1 LISTO
    # =====================================================

    def detectar_j1_ready(self) -> bool:

        self._capturar_disponibles()

        if self._j1_ready_pendiente:

            self._j1_ready_pendiente = False

            return True

        return False

    # =====================================================
    # SABER SI J1 TERMINO COLOCACION
    # =====================================================

    def jugador1_listo(self) -> bool:

        self._capturar_disponibles()

        return self._j1_ready_activo

    # =====================================================
    # RECIBIR BYTE
    #
    # Todos los bytes pasan por el mismo procesador
    # para evitar interpretaciones diferentes.
    # =====================================================

    def recibir(self) -> int | None:

        # =============================================
        # CAPTURAR DATOS QUE YA LLEGARON
        # =============================================

        self._capturar_disponibles()

        # =============================================
        # REINICIO PENDIENTE
        # =============================================

        if self._reset_pendiente:

            self._reset_pendiente = False

            raise ReinicioPartida()

        # =============================================
        # DATOS EN COLA
        # =============================================

        if self._cola_rx:

            return self._cola_rx.popleft()

        # =============================================
        # ESPERAR UN BYTE NUEVO
        # =============================================

        dato = self.uart.read(1)

        if not dato:
            return None

        # =============================================
        # PROCESAR CON LAS MISMAS REGLAS
        # =============================================

        self._procesar_valor(dato[0])

        # =============================================
        # COMPROBAR RESET NUEVO
        # =============================================

        if self._reset_pendiente:

            self._reset_pendiente = False

            raise ReinicioPartida()

        # =============================================
        # ENTREGAR BYTE NORMAL
        # =============================================

        if self._cola_rx:

            return self._cola_rx.popleft()

        # Era un evento de colocacion, no un disparo.
        return None

    # =====================================================
    # DISPONIBLES
    # =====================================================

    def datos_disponibles(self) -> int:

        return (
            len(self._cola_rx)
            + self.uart.in_waiting
        )

    # =====================================================
    # LIMPIAR ENTRADA
    # =====================================================

    def limpiar_entrada(self) -> None:

        self._cola_rx.clear()

        self._reset_pendiente = False

        self._j1_ready_pendiente = False
        self._j1_ready_activo = False

        # La nueva partida empieza en colocacion.
        self._en_batalla = False

        self.uart.reset_input_buffer()

    # =====================================================
    # LIMPIAR SALIDA
    # =====================================================

    def limpiar_salida(self) -> None:

        self.uart.reset_output_buffer()

    # =====================================================
    # ABIERTA
    # =====================================================

    def esta_abierto(self) -> bool:

        return self.uart.is_open

    # =====================================================
    # CERRAR
    # =====================================================

    def cerrar(self) -> None:

        if self.uart.is_open:
            self.uart.close()


# =========================================================
# LISTAR PUERTOS
# =========================================================

def listar_puertos() -> list[str]:

    puertos = (
        serial.tools.list_ports.comports()
    )

    dispositivos = []

    if not puertos:

        print(
            "No se encontraron puertos COM."
        )

        return dispositivos

    print()
    print("=== PUERTOS COM DISPONIBLES ===")
    print()

    for puerto in puertos:

        dispositivos.append(
            puerto.device
        )

        print(
            f"{puerto.device} - "
            f"{puerto.description}"
        )

    return dispositivos
