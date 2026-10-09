module program_rom #(
    parameter string INIT_FILE = ""
)(
    input  logic        clk_i,
    input  logic        rst_i,

    input  logic [31:0] prog_address_i,
    output logic [31:0] prog_instr_o
);

    // =====================================================
    // PARAMETROS
    // =====================================================

    localparam logic [31:0] ROM_END = 32'h0000_1FFF;
    localparam logic [31:0] NOP     = 32'h0000_0013;


    // =====================================================
    // MEMORIA
    // =====================================================

    (* rom_style = "block" *)
    logic [31:0] memory [0:2047];

    logic [10:0] word_index;

    integer i;


    // =====================================================
    // CONVERSION DE DIRECCION
    // =====================================================

    // Cada instruccion ocupa 4 bytes.
    // Se descartan los bits [1:0].
    assign word_index = prog_address_i[12:2];


    // =====================================================
    // INICIALIZACION
    // =====================================================

    initial begin

        // Rellenar toda la ROM con NOP
        for (i = 0; i < 2048; i = i + 1)
            memory[i] = NOP;


        // Cargar programa si se proporciona archivo
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, memory);

    end


    // =====================================================
    // LECTURA COMBINACIONAL
    // =====================================================

    always_comb begin

        if (prog_address_i <= ROM_END)
            prog_instr_o = memory[word_index];

        else
            prog_instr_o = NOP;

    end


endmodule