module j1_inputs_mmio #(
    parameter int DEBOUNCE_CYCLES = 500_000
)(
    input  logic clk_i,
    input  logic rst_i,

    input  logic btn_up_i,
    input  logic btn_down_i,
    input  logic btn_left_i,
    input  logic btn_right_i,

    input  logic btn_sel_i,
    input  logic btn_ok_i,
    input  logic btn_rst_i,

    output logic [31:0] rdata_o
);


    // =====================================================
    // SEÑALES INTERNAS YA FILTRADAS
    // =====================================================

    logic up;
    logic down;
    logic left;
    logic right;

    logic sel;
    logic ok;
    logic game_rst;


    // =====================================================
    // DEBOUNCE UP
    // =====================================================

    debounce_j1 #(
        .COUNT_MAX(DEBOUNCE_CYCLES)
    ) db_up (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .signal_i (btn_up_i),
        .signal_o (up)
    );


    // =====================================================
    // DEBOUNCE DOWN
    // =====================================================

    debounce_j1 #(
        .COUNT_MAX(DEBOUNCE_CYCLES)
    ) db_down (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .signal_i (btn_down_i),
        .signal_o (down)
    );


    // =====================================================
    // DEBOUNCE LEFT
    // =====================================================

    debounce_j1 #(
        .COUNT_MAX(DEBOUNCE_CYCLES)
    ) db_left (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .signal_i (btn_left_i),
        .signal_o (left)
    );


    // =====================================================
    // DEBOUNCE RIGHT
    // =====================================================

    debounce_j1 #(
        .COUNT_MAX(DEBOUNCE_CYCLES)
    ) db_right (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .signal_i (btn_right_i),
        .signal_o (right)
    );


    // =====================================================
    // DEBOUNCE SELECT
    // =====================================================

    debounce_j1 #(
        .COUNT_MAX(DEBOUNCE_CYCLES)
    ) db_sel (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .signal_i (btn_sel_i),
        .signal_o (sel)
    );


    // =====================================================
    // DEBOUNCE OK
    // =====================================================

    debounce_j1 #(
        .COUNT_MAX(DEBOUNCE_CYCLES)
    ) db_ok (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .signal_i (btn_ok_i),
        .signal_o (ok)
    );


    // =====================================================
    // DEBOUNCE RESET DEL JUEGO
    // =====================================================

    debounce_j1 #(
        .COUNT_MAX(DEBOUNCE_CYCLES)
    ) db_rst (
        .clk_i    (clk_i),
        .rst_i    (rst_i),
        .signal_i (btn_rst_i),
        .signal_o (game_rst)
    );


    // =====================================================
    // REGISTRO DE ESTADO PARA EL RISC-V
    // =====================================================

    always_comb begin

        rdata_o = 32'b0;

        rdata_o[0] = up;
        rdata_o[1] = down;
        rdata_o[2] = left;
        rdata_o[3] = right;

        rdata_o[4] = sel;
        rdata_o[5] = ok;
        rdata_o[6] = game_rst;

    end

endmodule