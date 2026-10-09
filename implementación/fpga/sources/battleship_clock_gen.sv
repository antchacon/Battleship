module battleship_clock_gen (
    input  logic clk_100mhz_i,
    input  logic rst_i,

    output logic clk_system_o,
    output logic clk_pixel_o,
    output logic locked_o
);

    clk_wiz_25mhz clock_wizard (
        .clk_in1  (clk_100mhz_i),
        .reset    (rst_i),

        .clk_out1 (clk_system_o),
        .clk_out2 (clk_pixel_o),

        .locked   (locked_o)
    );

endmodule