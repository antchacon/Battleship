module battleship_vga_ram (

    // Puerto CPU - 100 MHz
    input  logic        clk_i,
    input  logic [8:0]  cpu_addr_i,
    input  logic [31:0] cpu_wdata_i,
    input  logic        cpu_we_i,
    output logic [31:0] cpu_rdata_o,

    // Puerto VGA - 25 MHz
    input  logic        clk_pixel_i,
    input  logic [8:0]  video_addr_i,
    output logic [31:0] video_rdata_o
);

    (* ram_style = "block" *)
    logic [31:0] memory [0:511];


    // =====================================================
    // PUERTO CPU
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (cpu_we_i)
            memory[cpu_addr_i] <= cpu_wdata_i;

        cpu_rdata_o <= memory[cpu_addr_i];

    end


    // =====================================================
    // PUERTO VGA
    // =====================================================

    always_ff @(posedge clk_pixel_i) begin

        video_rdata_o <= memory[video_addr_i];

    end

endmodule