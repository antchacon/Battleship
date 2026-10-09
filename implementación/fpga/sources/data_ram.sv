module data_ram (

    input  logic        clk_i,

    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    input  logic        write_enable_i,

    output logic [31:0] rdata_o
);

    localparam logic [31:0] RAM_START = 32'h0000_2000;
    localparam logic [31:0] RAM_END   = 32'h0000_2FFF;

    logic [31:0] memory [0:1023];

    logic [9:0] word_index;
    logic       valid_address;


    assign valid_address =
        (addr_i >= RAM_START) &&
        (addr_i <= RAM_END);

    // Cada palabra ocupa 4 bytes
    assign word_index = addr_i[11:2];


    // =====================================================
    // ESCRITURA
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (write_enable_i && valid_address)
            memory[word_index] <= wdata_i;

    end


    // =====================================================
    // LECTURA
    // =====================================================

    always_comb begin

        if (valid_address)
            rdata_o = memory[word_index];
        else
            rdata_o = 32'b0;

    end

endmodule
