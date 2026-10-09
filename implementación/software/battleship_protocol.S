.section .text
.globl _start


# ============================================================
# INICIO
# ============================================================

_start:

    # --------------------------------------------------------
    # Direcciones base
    # --------------------------------------------------------

    lui  s0, 0x10
    # s0 = 0x00010000
    # Base de perifericos

    lui  s1, 0x2
    # s1 = 0x00002000
    # Tablero Jugador 1

    addi s2, s1, 0x100
    # s2 = 0x00002100
    # Tablero Jugador 2

    addi s3, s1, 0x200
    # s3 = 0x00002200
    # Variables auxiliares


    # ========================================================
    # LIMPIAR TABLERO J2
    #
    # 64 posiciones
    # Cada posicion ocupa 32 bits
    # ========================================================

    addi t0, s2, 0
    addi t1, zero, 64


clear_j2:

    sw   zero, 0(t0)

    addi t0, t0, 4
    addi t1, t1, -1

    bne  t1, zero, clear_j2



# ============================================================
# LOOP PRINCIPAL
# ============================================================

main_loop:

    # Esperar un byte proveniente de Python
    jal  ra, uart_receive

    addi t6, a0, 0
    # t6 = byte recibido


    # ========================================================
    # COMPROBAR TIPO DE MENSAJE
    #
    # bit7 = 1 -> disparo
    # bit7 = 0 -> posible colocacion
    # ========================================================

    srli t0, t6, 7

    bne  t0, zero, rx_shot


    # ========================================================
    # COLOCACION
    #
    # BYTE 0:
    #
    # 0001 00II
    # ========================================================

    srli t0, t6, 4
    andi t0, t0, 0x0F

    addi t1, zero, 1

    # Si el nibble alto no es 0001,
    # se descarta el byte.
    bne  t0, t1, main_loop


    # ========================================================
    # EXTRAER ID DEL BARCO
    #
    # 0 -> tamano 4
    # 1 -> tamano 3
    # 2 -> tamano 2
    # ========================================================

    andi s4, t6, 0x03


    # ID = 3 no existe
    addi t1, zero, 3

    beq  s4, t1, main_loop


    # ========================================================
    # RECIBIR SEGUNDO BYTE
    #
    # 0 O FFF CCC
    # ========================================================

    jal  ra, uart_receive


    # a1 = byte posicion
    addi a1, a0, 0

    # a0 = ID barco
    addi a0, s4, 0


    # ========================================================
    # VALIDAR Y COLOCAR BARCO
    # ========================================================

    jal  ra, procesar_colocacion


    # ========================================================
    # RESPUESTA
    #
    # a0 = 00000001 -> aceptado
    # a0 = 00000010 -> traslape
    # a0 = 00000100 -> fuera del tablero
    # ========================================================

    beq  a0, zero, main_loop

    jal  ra, uart_send

    jal  zero, main_loop



# ============================================================
# MENSAJE DE DISPARO RECIBIDO
#
# BYTE:
#
# 1 0 FFF CCC
#
# bit7 = 1
# bit6 = 0
# bits5:3 = fila
# bits2:0 = columna
# ============================================================

rx_shot:

    # Comprobar que bit6 sea 0

    srli t0, t6, 6
    andi t0, t0, 1

    bne  t0, zero, main_loop


    # --------------------------------------------------------
    # fila
    # --------------------------------------------------------

    srli t1, t6, 3
    andi t1, t1, 7


    # --------------------------------------------------------
    # columna
    # --------------------------------------------------------

    andi t2, t6, 7


    # --------------------------------------------------------
    # Por ahora guardar la coordenada recibida.
    #
    # 0x2204 = fila
    # 0x2208 = columna
    #
    # Despues aqui se conecta la logica real del disparo.
    # --------------------------------------------------------

    sw   t1, 4(s3)
    sw   t2, 8(s3)


    jal  zero, main_loop



# ============================================================
# UART RECEIVE
#
# CONTROL = 0x00010040
# RX      = 0x00010048
#
# CONTROL:
# bit0 = tx_busy
# bit1 = new_rx
#
# SALIDA:
# a0 = byte recibido
# ============================================================

uart_receive:


rx_wait:

    lw   t0, 0x40(s0)

    andi t1, t0, 0x02

    beq  t1, zero, rx_wait


    # Leer RX

    lw   a0, 0x48(s0)


    # Limpiar new_rx
    sw   zero, 0x40(s0)


    # Solo conservar 8 bits

    andi a0, a0, 0xFF


    jalr zero, 0(ra)



# ============================================================
# UART SEND
#
# ENTRADA:
# a0 = byte
#
# TX      = 0x00010044
# CONTROL = 0x00010040
# ============================================================

uart_send:


# ------------------------------------------------------------
# Esperar hasta que UART TX este libre
# ------------------------------------------------------------

tx_wait_idle:

    lw   t0, 0x40(s0)

    andi t1, t0, 0x01

    bne  t1, zero, tx_wait_idle


# ------------------------------------------------------------
# Escribir byte en TX
# ------------------------------------------------------------

    andi a0, a0, 0xFF

    sw   a0, 0x44(s0)


# ------------------------------------------------------------
# Iniciar transmision
#
# CONTROL = 00000011
# ------------------------------------------------------------

    addi t2, zero, 3

    sw   t2, 0x40(s0)



# ------------------------------------------------------------
# Esperar que tx_busy pase a 1
# ------------------------------------------------------------

tx_wait_start:

    lw   t0, 0x40(s0)

    andi t1, t0, 0x01

    beq  t1, zero, tx_wait_start



# ------------------------------------------------------------
# Esperar fin
# ------------------------------------------------------------

tx_wait_done:

    lw   t0, 0x40(s0)

    andi t1, t0, 0x01

    bne  t1, zero, tx_wait_done


    jalr zero, 0(ra)



# ============================================================
# PROCESAR COLOCACION
#
# ENTRADAS
#
# a0 = ID barco
#
#       0 -> tamano 4
#       1 -> tamano 3
#       2 -> tamano 2
#
#
# a1 =
#
#       bit6     orientacion
#       bits5:3  fila
#       bits2:0  columna
#
#
# SALIDA
#
# a0 = 1 -> aceptada
# a0 = 2 -> traslape
# a0 = 4 -> fuera del tablero
# a0 = 0 -> mensaje invalido
#
# ============================================================

procesar_colocacion:


# ============================================================
# OBTENER TAMANO
# ============================================================

    beq  a0, zero, ship_size_4


    addi t4, zero, 1

    beq  a0, t4, ship_size_3


    addi t4, zero, 2

    beq  a0, t4, ship_size_2


    # ID invalido

    addi a0, zero, 0

    jalr zero, 0(ra)



ship_size_4:

    addi t0, zero, 4

    jal  zero, decode_position



ship_size_3:

    addi t0, zero, 3

    jal  zero, decode_position



ship_size_2:

    addi t0, zero, 2



# ============================================================
# DECODIFICAR POSICION
# ============================================================

decode_position:


    # t1 = orientacion

    srli t1, a1, 6
    andi t1, t1, 1


    # t2 = fila

    srli t2, a1, 3
    andi t2, t2, 7


    # t3 = columna

    andi t3, a1, 7



# ============================================================
# VALIDAR LIMITES
# ============================================================

    # orientacion 0 = horizontal
    # orientacion 1 = vertical

    beq  t1, zero, check_horizontal_bounds



# ------------------------------------------------------------
# VERTICAL
#
# fila + tamano <= 8
# ------------------------------------------------------------

    add  t4, t2, t0

    addi t5, zero, 8

    blt  t5, t4, placement_out


    jal  zero, check_overlap_start



# ------------------------------------------------------------
# HORIZONTAL
#
# columna + tamano <= 8
# ------------------------------------------------------------

check_horizontal_bounds:

    add  t4, t3, t0

    addi t5, zero, 8

    blt  t5, t4, placement_out



# ============================================================
# COMPROBAR TRASLAPE
# ============================================================

check_overlap_start:

    addi t4, zero, 0
    # i = 0



check_overlap_loop:

    beq  t4, t0, save_ship_start


    # Horizontal

    beq  t1, zero, overlap_horizontal



# ------------------------------------------------------------
# VERTICAL
#
# index = (fila+i)*8 + columna
# ------------------------------------------------------------

    add  t5, t2, t4

    slli t5, t5, 3

    add  t5, t5, t3


    jal  zero, overlap_address



# ------------------------------------------------------------
# HORIZONTAL
#
# index = fila*8 + columna+i
# ------------------------------------------------------------

overlap_horizontal:

    slli t5, t2, 3

    add  t5, t5, t3

    add  t5, t5, t4



# ------------------------------------------------------------
# Convertir indice a direccion
#
# direccion = 0x2100 + index*4
# ------------------------------------------------------------

overlap_address:

    slli t6, t5, 2

    add  t6, s2, t6


    lw   a2, 0(t6)


    # Si != 0 ya existe barco

    bne  a2, zero, placement_overlap


    addi t4, t4, 1

    jal  zero, check_overlap_loop



# ============================================================
# GUARDAR BARCO
#
# En cada casilla se guarda:
#
# 4 -> barco tamano 4
# 3 -> barco tamano 3
# 2 -> barco tamano 2
# ============================================================

save_ship_start:

    addi t4, zero, 0



save_ship_loop:

    beq  t4, t0, placement_ok


    beq  t1, zero, save_horizontal



# ------------------------------------------------------------
# VERTICAL
# ------------------------------------------------------------

    add  t5, t2, t4

    slli t5, t5, 3

    add  t5, t5, t3


    jal  zero, save_address



# ------------------------------------------------------------
# HORIZONTAL
# ------------------------------------------------------------

save_horizontal:

    slli t5, t2, 3

    add  t5, t5, t3

    add  t5, t5, t4



# ------------------------------------------------------------
# Guardar en RAM
# ------------------------------------------------------------

save_address:

    slli t6, t5, 2

    add  t6, s2, t6


    sw   t0, 0(t6)


    addi t4, t4, 1

    jal  zero, save_ship_loop



# ============================================================
# RESPUESTAS DE COLOCACION
# ============================================================

placement_ok:

    # bit0 = 1

    addi a0, zero, 1

    jalr zero, 0(ra)



placement_overlap:

    # bit1 = 1

    addi a0, zero, 2

    jalr zero, 0(ra)



placement_out:

    # bit2 = 1

    addi a0, zero, 4

    jalr zero, 0(ra)



# ============================================================
# CODIFICAR RESULTADO DE DISPARO JUGADOR 1
#
# bit0 = 0
# bit1 = acierto
# bit2 = error
#
# ENTRADA
# a0 = acierto
# a1 = error
#
# SALIDA
# a0 = byte UART
# ============================================================

encode_shot_result_j1:

    andi a0, a0, 1

    slli a0, a0, 1


    andi a1, a1, 1

    slli a1, a1, 2


    or   a0, a0, a1


    jalr zero, 0(ra)



# ============================================================
# CODIFICAR EVENTO PARA JUGADOR 2
#
# bit0      = 1
# bits3:1   = columna
# bits6:4   = fila
# bit7      = barco hundido
#
# ENTRADAS
# a0 = fila
# a1 = columna
# a2 = barco_hundido
#
# SALIDA
# a0 = byte UART
# ============================================================

encode_shot_event_j2:


    # fila

    andi t0, a0, 7

    slli t0, t0, 4


    # columna

    andi t1, a1, 7

    slli t1, t1, 1


    # barco hundido

    andi t2, a2, 1

    slli t2, t2, 7


    # unir

    or   a0, t0, t1

    or   a0, a0, t2


    # bit0 = jugador 2

    ori  a0, a0, 1


    jalr zero, 0(ra)
