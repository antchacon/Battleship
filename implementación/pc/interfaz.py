import time
import tkinter as tk

from UART import ReinicioPartida

from tablero import (
    TAMANO_TABLERO,
    BARCO,
    IMPACTO,
    FALLO
)


class Interfaz:

    def __init__(self):

        self.root = tk.Tk()

        self.root.title(
            "Batalla Naval"
        )

        self.root.configure(
            bg="black"
        )


        self.celda = 50


        self.uart = None

        self.en_colocacion = (
            False
        )


        # =============================================
        # TURNO
        # =============================================

        self.turno_label = tk.Label(
            self.root,
            text="",
            fg="white",
            bg="black",
            font=(
                "Bahnschrift Condensed",
                20,
                "bold"
            )
        )


        self.turno_label.pack(
            pady=(15, 0)
        )


        # =============================================
        # MENSAJE
        # =============================================

        self.mensaje_label = tk.Label(
            self.root,
            text="",
            fg="#FF3030",
            bg="black",
            font=(
                "Bahnschrift Condensed",
                16,
                "bold"
            ),
            justify="center"
        )


        self.mensaje_label.pack(
            pady=(5, 0)
        )


        # =============================================
        # TABLEROS
        # =============================================

        frame = tk.Frame(
            self.root,
            bg="black"
        )


        frame.pack(
            padx=20,
            pady=20
        )


        self.canvas_propio = (
            self.crear_canvas(
                frame,
                "TU TABLERO",
                0
            )
        )


        self.canvas_rival = (
            self.crear_canvas(
                frame,
                "TABLERO RIVAL",
                1
            )
        )


        # =============================================
        # CURSOR
        # =============================================

        self.cursor_fila = 0
        self.cursor_columna = 0

        self.canvas_activo = None

        self.cursor = None

        self.parpadeo = False


    # =====================================================
    # UART
    # =====================================================

    def conectar_uart(
        self,
        uart
    ):

        self.uart = uart


    # =====================================================
    # MODO COLOCACION
    # =====================================================

    def set_modo_colocacion(
        self,
        activo: bool
    ):

        self.en_colocacion = (
            activo
        )


    # =====================================================
    # RESET
    # =====================================================

    def comprobar_reset(
        self
    ):

        if self.uart is None:

            return


        if self.uart.detectar_reset():

            raise ReinicioPartida()


    # =====================================================
    # EVENTOS DURANTE COLOCACION
    # =====================================================

    def comprobar_eventos_colocacion(
        self
    ):

        if self.uart is None:

            return


        self.comprobar_reset()


        if (
            self.en_colocacion
            and
            self.uart.detectar_j1_ready()
        ):

            self.mostrar_mensaje(
                "FLOTA DEL JUGADOR 1 LISTA\n"
                "Esperando la flota del Jugador 2...",
                "#FFD700"
            )


    # =====================================================
    # TURNO
    # =====================================================

    def mostrar_turno(
        self,
        jugador
    ):

        if jugador == 1:

            self.turno_label.config(
                text="Turno: Jugador 1",
                fg="#00FF55"
            )

        else:

            self.turno_label.config(
                text="Turno: Jugador 2",
                fg="#FF3030"
            )


        self.root.update()


    # =====================================================
    # MENSAJE
    # =====================================================

    def mostrar_mensaje(
        self,
        mensaje,
        color="#FF3030"
    ):

        self.mensaje_label.config(
            text=mensaje,
            fg=color
        )


        self.root.update()


    # =====================================================
    # LIMPIAR
    # =====================================================

    def limpiar_mensaje(
        self
    ):

        self.mensaje_label.config(
            text=""
        )


        self.root.update()


    # =====================================================
    # CANVAS
    # =====================================================

    def crear_canvas(
        self,
        frame,
        nombre,
        columna
    ):

        zona = tk.Frame(
            frame,
            bg="black"
        )


        zona.grid(
            row=0,
            column=columna,
            padx=35
        )


        tk.Label(
            zona,
            text=nombre,
            fg="white",
            bg="black",
            font=(
                "Bahnschrift Condensed",
                22,
                "bold"
            )
        ).pack(
            pady=10
        )


        canvas = tk.Canvas(
            zona,
            width=(
                self.celda
                *
                TAMANO_TABLERO
            ),
            height=(
                self.celda
                *
                TAMANO_TABLERO
            ),
            bg="black",
            highlightthickness=0
        )


        canvas.pack()


        return canvas


    # =====================================================
    # DIBUJAR
    # =====================================================

    def dibujar(
        self,
        canvas,
        tablero
    ):

        canvas.delete(
            "all"
        )


        for fila in range(
            TAMANO_TABLERO
        ):

            for columna in range(
                TAMANO_TABLERO
            ):

                x1 = (
                    columna
                    *
                    self.celda
                )

                y1 = (
                    fila
                    *
                    self.celda
                )

                x2 = (
                    x1
                    +
                    self.celda
                )

                y2 = (
                    y1
                    +
                    self.celda
                )


                valor = (
                    tablero.casillas[
                        fila
                    ][
                        columna
                    ]
                )


                color = (
                    "#163DDB"
                )


                if valor == BARCO:

                    color = (
                        "#AEB4BA"
                    )


                canvas.create_rectangle(
                    x1,
                    y1,
                    x2,
                    y2,
                    fill=color,
                    outline="#333333",
                    width=2
                )


                if valor == IMPACTO:

                    canvas.create_text(
                        x1 + self.celda // 2,
                        y1 + self.celda // 2,
                        text="O",
                        fill="#00FF55",
                        font=(
                            "Bahnschrift Condensed",
                            25,
                            "bold"
                        )
                    )


                elif valor == FALLO:

                    canvas.create_text(
                        x1 + self.celda // 2,
                        y1 + self.celda // 2,
                        text="X",
                        fill="#FF3030",
                        font=(
                            "Bahnschrift Condensed",
                            25,
                            "bold"
                        )
                    )


    # =====================================================
    # MOSTRAR
    # =====================================================

    def mostrar(
        self,
        tableros
    ):

        self.dibujar(
            self.canvas_propio,
            tableros.propio
        )


        self.dibujar(
            self.canvas_rival,
            tableros.rival
        )


        self.root.update()


    # =====================================================
    # ESPERA DE SELECCION
    # =====================================================

    def esperar_seleccion(
        self,
        terminado
    ):

        while not terminado.get():

            self.root.update()

            self.comprobar_eventos_colocacion()

            time.sleep(
                0.01
            )


    # =====================================================
    # SELECCION DISPARO
    # =====================================================

    def seleccionar(
        self,
        tableros,
        rival=True
    ):

        self.mostrar(
            tableros
        )


        if rival:

            self.canvas_activo = (
                self.canvas_rival
            )

        else:

            self.canvas_activo = (
                self.canvas_propio
            )


        self.cursor_fila = 0
        self.cursor_columna = 0

        self.parpadeo = True


        terminado = tk.BooleanVar(
            master=self.root,
            value=False
        )


        def tecla(event):

            if event.keysym == "Up":

                self.cursor_fila = max(
                    0,
                    self.cursor_fila - 1
                )


            elif event.keysym == "Down":

                self.cursor_fila = min(
                    TAMANO_TABLERO - 1,
                    self.cursor_fila + 1
                )


            elif event.keysym == "Left":

                self.cursor_columna = max(
                    0,
                    self.cursor_columna - 1
                )


            elif event.keysym == "Right":

                self.cursor_columna = min(
                    TAMANO_TABLERO - 1,
                    self.cursor_columna + 1
                )


            elif event.keysym == "Return":

                terminado.set(
                    True
                )

                return


            self.dibujar_cursor()


        self.root.bind(
            "<Key>",
            tecla
        )


        self.dibujar_cursor()

        self.parpadear()

        self.root.focus_force()


        try:

            while not terminado.get():

                self.root.update()

                self.comprobar_reset()

                time.sleep(
                    0.01
                )

        finally:

            self.parpadeo = (
                False
            )

            self.root.unbind(
                "<Key>"
            )


        fila = self.cursor_fila

        columna = self.cursor_columna


        self.cursor = None


        self.mostrar(
            tableros
        )


        return (
            fila,
            columna
        )


    # =====================================================
    # SELECCION BARCO
    # =====================================================

    def seleccionar_barco(
        self,
        tableros,
        tamano
    ):

        self.canvas_activo = (
            self.canvas_propio
        )


        self.cursor_fila = 0
        self.cursor_columna = 0


        orientacion = (
            "H"
        )


        self.parpadeo = (
            True
        )


        terminado = tk.BooleanVar(
            master=self.root,
            value=False
        )


        def actualizar():

            self.mostrar(
                tableros
            )


            for i in range(
                tamano
            ):

                if orientacion == "H":

                    fila = (
                        self.cursor_fila
                    )

                    columna = (
                        self.cursor_columna
                        +
                        i
                    )

                else:

                    fila = (
                        self.cursor_fila
                        +
                        i
                    )

                    columna = (
                        self.cursor_columna
                    )


                if (
                    0 <= fila < TAMANO_TABLERO
                    and
                    0 <= columna < TAMANO_TABLERO
                ):

                    x1 = (
                        columna
                        *
                        self.celda
                    )

                    y1 = (
                        fila
                        *
                        self.celda
                    )


                    self.canvas_propio.create_rectangle(
                        x1 + 3,
                        y1 + 3,
                        x1 + self.celda - 3,
                        y1 + self.celda - 3,
                        fill="#AEB4BA",
                        outline="#666666"
                    )


            self.dibujar_cursor()


        def tecla(event):

            nonlocal orientacion


            if event.keysym == "Up":

                self.cursor_fila = max(
                    0,
                    self.cursor_fila - 1
                )


            elif event.keysym == "Down":

                self.cursor_fila = min(
                    TAMANO_TABLERO - 1,
                    self.cursor_fila + 1
                )


            elif event.keysym == "Left":

                self.cursor_columna = max(
                    0,
                    self.cursor_columna - 1
                )


            elif event.keysym == "Right":

                self.cursor_columna = min(
                    TAMANO_TABLERO - 1,
                    self.cursor_columna + 1
                )


            elif (
                event.keysym.lower()
                ==
                "r"
            ):

                orientacion = (
                    "V"
                    if orientacion == "H"
                    else
                    "H"
                )


            elif event.keysym == "Return":

                terminado.set(
                    True
                )

                return


            actualizar()


        self.root.bind(
            "<Key>",
            tecla
        )


        actualizar()

        self.parpadear()

        self.root.focus_force()


        try:

            self.esperar_seleccion(
                terminado
            )

        finally:

            self.parpadeo = (
                False
            )

            self.root.unbind(
                "<Key>"
            )


        fila = self.cursor_fila

        columna = self.cursor_columna


        self.cursor = None


        self.mostrar(
            tableros
        )


        return (
            fila,
            columna,
            orientacion
        )


    # =====================================================
    # CURSOR
    # =====================================================

    def dibujar_cursor(
        self
    ):

        if self.canvas_activo is None:

            return


        if self.cursor is not None:

            self.canvas_activo.delete(
                self.cursor
            )


        x1 = (
            self.cursor_columna
            *
            self.celda
        )

        y1 = (
            self.cursor_fila
            *
            self.celda
        )


        self.cursor = (
            self.canvas_activo.create_rectangle(
                x1 + 2,
                y1 + 2,
                x1 + self.celda - 2,
                y1 + self.celda - 2,
                outline="#FFD700",
                width=4
            )
        )


    # =====================================================
    # PARPADEO
    # =====================================================

    def parpadear(
        self
    ):

        if not self.parpadeo:

            return


        if (
            self.canvas_activo is not None
            and
            self.cursor is not None
        ):

            estado = (
                self.canvas_activo.itemcget(
                    self.cursor,
                    "state"
                )
            )


            nuevo_estado = (

                "normal"

                if estado == "hidden"

                else

                "hidden"

            )


            self.canvas_activo.itemconfigure(
                self.cursor,
                state=nuevo_estado
            )


        self.root.after(
            300,
            self.parpadear
        )


    # =====================================================
    # CERRAR
    # =====================================================

    def cerrar(
        self
    ):

        self.root.destroy()