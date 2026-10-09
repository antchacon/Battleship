
.section .text
.globl _start

# ============================================================
# BATTLESHIP - INTEGRACION DE COLOCACION J1 + J2
# RV32I
#
# J1 = Basys3:
#   J1_STATUS = 0x00010120
#   bit0 UP
#   bit1 DOWN
#   bit2 LEFT
#   bit3 RIGHT
#   bit4 SW0 orientacion (0=H, 1=V)
#   bit5 CENTER/OK
#
# J2 = PC por UART:
#   BYTE0 = 0001 00II
#   BYTE1 = 0 O FFF CCC
#
# FPGA -> PC:
#   0x01 colocacion aceptada
#   0x02 traslape
#   0x04 fuera del tablero
#   0x20 ambos jugadores listos / inicio de batalla
#
# RAM:
#   J1 tablero  = 0x00002000
#   J2 tablero  = 0x00002100
#   variables   = 0x00002200
#   disparos J2 = 0x00002300
#
# VGA:
#   base = 0x00011000
# ============================================================

_start:
    lui  s0, 0x10              # perifericos 0x00010000
    lui  s1, 0x2               # tablero J1 0x00002000
    addi s2, s1, 0x100         # tablero J2 0x00002100
    addi s3, s1, 0x200         # variables  0x00002200
    addi s6, s1, 0x300         # disparos J2 sobre J1 0x00002300
    lui  s7, 0x11              # VGA 0x00011000

    addi s4, zero, 0           # mascara barcos J2 colocados
    addi s5, zero, 4           # longitud actual barco J1: 4 -> 3 -> 2
    addi s8, zero, 0           # fila J1
    addi s9, zero, 0           # columna J1
    addi s10, zero, 0          # orientacion J1
    addi s11, zero, 0          # botones anteriores J1

    # Limpiar J1, J2 y mapa de disparos
    addi t0, s1, 0
    addi t1, s2, 0
    addi t2, s6, 0
    addi t3, zero, 64

clear_tables:
    sw   zero, 0(t0)
    sw   zero, 0(t1)
    sw   zero, 0(t2)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, 4
    addi t3, t3, -1
    bne  t3, zero, clear_tables

    # Estado inicial de J1 para detector de flancos
    lw   t0, 0x120(s0)
    nop
    andi s11, t0, 0x2F
    andi s10, t0, 0x10
    srli s10, s10, 4

    jal  ra, render_j1_preview

# ============================================================
# FASE DE COLOCACION - AMBOS JUGADORES
# ============================================================

placement_loop:

    # --------------------------------------------------------
    # 1. Atender UART de J2 primero
    # --------------------------------------------------------
    jal  ra, uart_try_receive
    beq  a0, zero, poll_j1

    addi t6, a1, 0

    # Solo encabezados 0001 00II durante colocacion
    andi t0, t6, 0xFC
    addi t1, zero, 0x10
    bne  t0, t1, poll_j1

    andi t2, t6, 0x03          # ID
    addi t3, zero, 3
    beq  t2, t3, poll_j1

    # Si ya fue colocado, consumir BYTE1 y responder traslape
    addi t4, zero, 1
    sll  t4, t4, t2
    and  t5, s4, t4
    bne  t5, zero, j2_duplicate

    # Recibir BYTE1 = 0 O FFF CCC
    jal  ra, uart_receive
    addi a1, a0, 0

    # bit7 debe ser cero
    srli t0, a1, 7
    bne  t0, zero, j2_invalid_position

    addi a0, t2, 0
    jal  ra, process_j2_placement

    # Si aceptado, marcar ID
    addi t0, zero, 1
    bne  a0, t0, j2_send_response

    addi t4, zero, 1
    sll  t4, t4, t2
    or   s4, s4, t4

j2_send_response:
    jal  ra, uart_send
    jal  zero, poll_j1

j2_duplicate:
    # Consumir el segundo byte para no desincronizar la UART
    jal  ra, uart_receive
    addi a0, zero, 2
    jal  ra, uart_send
    jal  zero, poll_j1

j2_invalid_position:
    addi a0, zero, 4
    jal  ra, uart_send

# ------------------------------------------------------------
# 2. Atender controles fisicos J1
# ------------------------------------------------------------

poll_j1:
    # s5 < 2 => J1 ya coloco 4,3,2
    addi t0, zero, 2
    blt  s5, t0, check_placement_complete

    lw   t0, 0x120(s0)
    nop

    # Orientacion SW0
    andi t1, t0, 0x10
    srli t1, t1, 4

    beq  t1, s10, j1_orientation_done

    addi s10, t1, 0
    jal  ra, j1_clamp_position
    jal  ra, render_j1_preview

j1_orientation_done:
    # Botones: UP/DOWN/LEFT/RIGHT/OK = bits 0,1,2,3,5
    andi t2, t0, 0x2F

    # rising = current & ~previous
    xori t3, s11, -1
    and  t3, t3, t2
    addi s11, t2, 0

    beq  t3, zero, check_placement_complete

    andi t4, t3, 0x01
    bne  t4, zero, j1_up

    andi t4, t3, 0x02
    bne  t4, zero, j1_down

    andi t4, t3, 0x04
    bne  t4, zero, j1_left

    andi t4, t3, 0x08
    bne  t4, zero, j1_right

    andi t4, t3, 0x20
    bne  t4, zero, j1_ok

    jal  zero, check_placement_complete

j1_up:
    beq  s8, zero, check_placement_complete
    addi s8, s8, -1
    jal  ra, render_j1_preview
    jal  zero, check_placement_complete

j1_down:
    # limite fila:
    # H => 7
    # V => 8-longitud
    beq  s10, zero, j1_down_horizontal
    addi t0, zero, 8
    sub  t0, t0, s5
    jal  zero, j1_down_limit_ready

j1_down_horizontal:
    addi t0, zero, 7

j1_down_limit_ready:
    bge  s8, t0, check_placement_complete
    addi s8, s8, 1
    jal  ra, render_j1_preview
    jal  zero, check_placement_complete

j1_left:
    beq  s9, zero, check_placement_complete
    addi s9, s9, -1
    jal  ra, render_j1_preview
    jal  zero, check_placement_complete

j1_right:
    # limite columna:
    # H => 8-longitud
    # V => 7
    bne  s10, zero, j1_right_vertical
    addi t0, zero, 8
    sub  t0, t0, s5
    jal  zero, j1_right_limit_ready

j1_right_vertical:
    addi t0, zero, 7

j1_right_limit_ready:
    bge  s9, t0, check_placement_complete
    addi s9, s9, 1
    jal  ra, render_j1_preview
    jal  zero, check_placement_complete

j1_ok:
    jal  ra, j1_validate_current
    beq  a0, zero, check_placement_complete

    jal  ra, j1_commit_current

    addi s5, s5, -1           # 4->3->2->1
    addi s8, zero, 0
    addi s9, zero, 0

    jal  ra, j1_clamp_position
    jal  ra, render_j1_preview

# ============================================================
# ¿AMBOS TERMINARON?
# ============================================================

check_placement_complete:
    addi t0, zero, 2
    bge  s5, t0, placement_loop

    addi t0, zero, 7
    bne  s4, t0, placement_loop

    # Ambos listos
    addi a0, zero, 0x20
    jal  ra, uart_send

    # LED estado = 2 (batalla)
    addi t0, zero, 2
    sw   t0, 0x138(s0)

    jal  zero, battle_loop

# ============================================================
# BATALLA TEMPORAL:
# conserva la prueba ya validada de disparos J2 -> J1.
# En el siguiente paso se agrega turno real de J1.
# ============================================================

battle_loop:
    jal  ra, uart_receive
    addi t6, a0, 0

    # Disparo J2 = 10 FFF CCC
    andi t0, t6, 0xC0
    addi t1, zero, 0x80
    bne  t0, t1, battle_loop

    # fila
    srli t1, t6, 3
    andi t1, t1, 7

    # columna
    andi t2, t6, 7

    # index = fila*8 + columna
    slli t3, t1, 3
    add  t3, t3, t2

    # mapa disparos repetidos
    slli t4, t3, 2
    add  t5, s6, t4
    lw   a2, 0(t5)
    nop

    bne  a2, zero, battle_shot_repeated

    addi a2, zero, 1
    sw   a2, 0(t5)

    # revisar tablero J1
    add  t5, s1, t4
    lw   a2, 0(t5)
    nop

    beq  a2, zero, battle_shot_miss

    # impacto
    addi a0, zero, 2
    jal  ra, uart_send
    jal  zero, battle_loop

battle_shot_miss:
    addi a0, zero, 0
    jal  ra, uart_send
    jal  zero, battle_loop

battle_shot_repeated:
    addi a0, zero, 4
    jal  ra, uart_send
    jal  zero, battle_loop

# ============================================================
# J1 - AJUSTAR POSICION A LOS LIMITES SEGUN ORIENTACION
# s8=fila, s9=col, s10=orientacion, s5=longitud
# ============================================================

j1_clamp_position:
    bne  s10, zero, j1_clamp_vertical

    # horizontal: col <= 8-longitud
    addi t0, zero, 8
    sub  t0, t0, s5
    bge  t0, s9, j1_clamp_return
    addi s9, t0, 0
    jalr zero, 0(ra)

j1_clamp_vertical:
    # vertical: fila <= 8-longitud
    addi t0, zero, 8
    sub  t0, t0, s5
    bge  t0, s8, j1_clamp_return
    addi s8, t0, 0

j1_clamp_return:
    jalr zero, 0(ra)

# ============================================================
# J1 - VALIDAR TRASLAPE
# retorno a0=1 valido, 0 invalido
# ============================================================

j1_validate_current:
    addi a0, zero, 0           # i
    addi a7, zero, 1           # valido inicialmente

j1_validate_loop:
    addi a1, s8, 0
    addi a2, s9, 0

    beq  s10, zero, j1_validate_horizontal
    add  a1, a1, a0
    jal  zero, j1_validate_index

j1_validate_horizontal:
    add  a2, a2, a0

j1_validate_index:
    slli a3, a1, 3
    add  a3, a3, a2
    slli a4, a3, 2
    add  a4, s1, a4

    lw   a5, 0(a4)
    nop
    bne  a5, zero, j1_validate_fail

    addi a0, a0, 1
    blt  a0, s5, j1_validate_loop

    addi a0, zero, 1
    jalr zero, 0(ra)

j1_validate_fail:
    addi a0, zero, 0
    jalr zero, 0(ra)

# ============================================================
# J1 - GUARDAR BARCO ACTUAL EN RAM
# valor guardado = longitud 4,3,2
# ============================================================

j1_commit_current:
    addi a0, zero, 0

j1_commit_loop:
    addi a1, s8, 0
    addi a2, s9, 0

    beq  s10, zero, j1_commit_horizontal
    add  a1, a1, a0
    jal  zero, j1_commit_index

j1_commit_horizontal:
    add  a2, a2, a0

j1_commit_index:
    slli a3, a1, 3
    add  a3, a3, a2
    slli a4, a3, 2
    add  a4, s1, a4

    sw   s5, 0(a4)

    addi a0, a0, 1
    blt  a0, s5, j1_commit_loop

    jalr zero, 0(ra)

# ============================================================
# VGA J1
# Limpia 20x15 = 300 tiles.
# Dibuja barcos J1 y preview del barco actual.
# J2 NO se revela en VGA.
# ============================================================

render_j1_preview:
    addi t0, s7, 0
    addi t1, zero, 300

render_clear_loop:
    sw   zero, 0(t0)
    addi t0, t0, 4
    addi t1, t1, -1
    bne  t1, zero, render_clear_loop

    # Barcos ya confirmados
    addi t0, zero, 0
    addi t1, s1, 0

render_board_loop:
    lw   t2, 0(t1)
    nop
    beq  t2, zero, render_board_next

    # row = index >> 3
    srli t3, t0, 3
    andi t4, t0, 7

    # tile = row*20 + col + 61
    slli t5, t3, 4
    slli t6, t3, 2
    add  t5, t5, t6
    add  t5, t5, t4
    addi t5, t5, 61
    slli t5, t5, 2
    add  t5, s7, t5

    addi t6, zero, 1
    sw   t6, 0(t5)

render_board_next:
    addi t0, t0, 1
    addi t1, t1, 4
    addi t2, zero, 64
    blt  t0, t2, render_board_loop

    # Si J1 termino, no dibujar preview
    addi t0, zero, 2
    blt  s5, t0, render_return

    # Preview
    addi t0, zero, 0

render_preview_loop:
    addi t1, s8, 0
    addi t2, s9, 0

    beq  s10, zero, render_preview_horizontal
    add  t1, t1, t0
    jal  zero, render_preview_index

render_preview_horizontal:
    add  t2, t2, t0

render_preview_index:
    # tile = row*20 + col + 61
    slli t3, t1, 4
    slli t4, t1, 2
    add  t3, t3, t4
    add  t3, t3, t2
    addi t3, t3, 61
    slli t3, t3, 2
    add  t3, s7, t3

    addi t4, zero, 1
    bne  t0, zero, render_preview_write
    addi t4, zero, 5           # primer tile = cursor/preview

render_preview_write:
    sw   t4, 0(t3)

    addi t0, t0, 1
    blt  t0, s5, render_preview_loop

render_return:
    jalr zero, 0(ra)

# ============================================================
# UART NO BLOQUEANTE
# a0=1 si hay byte, a1=byte
# a0=0 si no hay byte
# ============================================================

uart_try_receive:
    lw   t0, 0x40(s0)
    nop
    andi t1, t0, 0x02
    beq  t1, zero, uart_try_none

    lw   a1, 0x48(s0)
    nop
    addi t2, zero, 2
    sw   t2, 0x40(s0)
    andi a1, a1, 0xFF

    addi a0, zero, 1
    jalr zero, 0(ra)

uart_try_none:
    addi a0, zero, 0
    jalr zero, 0(ra)

# ============================================================
# UART RECEIVE BLOQUEANTE
# a0=byte
# ============================================================

uart_receive:
uart_rx_wait:
    lw   t0, 0x40(s0)
    nop
    andi t1, t0, 0x02
    beq  t1, zero, uart_rx_wait

    lw   a0, 0x48(s0)
    nop

    addi t2, zero, 2
    sw   t2, 0x40(s0)

    andi a0, a0, 0xFF
    jalr zero, 0(ra)

# ============================================================
# UART SEND BLOQUEANTE
# a0=byte
# ============================================================

uart_send:
uart_tx_wait_idle:
    lw   t0, 0x40(s0)
    nop
    andi t1, t0, 0x01
    bne  t1, zero, uart_tx_wait_idle

    andi a0, a0, 0xFF
    sw   a0, 0x44(s0)

    # NOPs para separar DATA_TX de CONTROL
    nop
    nop

    addi t2, zero, 1
    sw   t2, 0x40(s0)

uart_tx_wait_start:
    lw   t0, 0x40(s0)
    nop
    andi t1, t0, 0x01
    beq  t1, zero, uart_tx_wait_start

uart_tx_wait_done:
    lw   t0, 0x40(s0)
    nop
    andi t1, t0, 0x01
    bne  t1, zero, uart_tx_wait_done

    jalr zero, 0(ra)

# ============================================================
# J2 - PROCESAR COLOCACION
# a0 = ID 0,1,2
# a1 = 0 O FFF CCC
# retorna a0 = 1 aceptado, 2 traslape, 4 fuera
# ============================================================

process_j2_placement:
    beq  a0, zero, j2_size_4

    addi t4, zero, 1
    beq  a0, t4, j2_size_3

    addi t0, zero, 2
    jal  zero, j2_decode_position

j2_size_4:
    addi t0, zero, 4
    jal  zero, j2_decode_position

j2_size_3:
    addi t0, zero, 3

j2_decode_position:
    # t0 tamano
    srli t1, a1, 6
    andi t1, t1, 1            # orientacion
    srli t2, a1, 3
    andi t2, t2, 7            # fila
    andi t3, a1, 7            # columna

    beq  t1, zero, j2_check_horizontal_bounds

    # vertical
    add  t4, t2, t0
    addi t5, zero, 8
    blt  t5, t4, j2_placement_out
    jal  zero, j2_check_overlap_start

j2_check_horizontal_bounds:
    add  t4, t3, t0
    addi t5, zero, 8
    blt  t5, t4, j2_placement_out

j2_check_overlap_start:
    addi t4, zero, 0

j2_check_overlap_loop:
    beq  t4, t0, j2_save_ship_start
    beq  t1, zero, j2_overlap_horizontal

    add  t5, t2, t4
    slli t5, t5, 3
    add  t5, t5, t3
    jal  zero, j2_overlap_address

j2_overlap_horizontal:
    slli t5, t2, 3
    add  t5, t5, t3
    add  t5, t5, t4

j2_overlap_address:
    slli t6, t5, 2
    add  t6, s2, t6
    lw   a2, 0(t6)
    nop
    bne  a2, zero, j2_placement_overlap

    addi t4, t4, 1
    jal  zero, j2_check_overlap_loop

j2_save_ship_start:
    addi t4, zero, 0

j2_save_ship_loop:
    beq  t4, t0, j2_placement_ok
    beq  t1, zero, j2_save_horizontal

    add  t5, t2, t4
    slli t5, t5, 3
    add  t5, t5, t3
    jal  zero, j2_save_address

j2_save_horizontal:
    slli t5, t2, 3
    add  t5, t5, t3
    add  t5, t5, t4

j2_save_address:
    slli t6, t5, 2
    add  t6, s2, t6
    sw   t0, 0(t6)

    addi t4, t4, 1
    jal  zero, j2_save_ship_loop

j2_placement_ok:
    addi a0, zero, 1
    jalr zero, 0(ra)

j2_placement_overlap:
    addi a0, zero, 2
    jalr zero, 0(ra)

j2_placement_out:
    addi a0, zero, 4
    jalr zero, 0(ra)
