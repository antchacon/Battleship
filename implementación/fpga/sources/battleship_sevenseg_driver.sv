module battleship_sevenseg_driver #(
    parameter integer REFRESH_DIV = 50_000
)(
    input  logic        clk_i,
    input  logic        rst_i,

    input  logic [31:0] display_data_i,

    output logic [6:0]  seg_o,
    output logic [3:0]  an_o
);

    integer refresh_count;

    logic [1:0] digit_sel;

    logic [7:0] j1_value;
    logic [7:0] j2_value;

    logic [3:0] j1_tens;
    logic [3:0] j1_ones;

    logic [3:0] j2_tens;
    logic [3:0] j2_ones;

    logic [3:0] current_digit;


    // =====================================================
    // OBTENER CONTADORES
    // =====================================================

    always_comb begin

        // Limitar a 99
        if (display_data_i[7:0] > 8'd99)
            j1_value = 8'd99;
        else
            j1_value = display_data_i[7:0];


        if (display_data_i[15:8] > 8'd99)
            j2_value = 8'd99;
        else
            j2_value = display_data_i[15:8];


        // Separar decenas y unidades
        j1_tens = j1_value / 10;
        j1_ones = j1_value % 10;

        j2_tens = j2_value / 10;
        j2_ones = j2_value % 10;

    end


    // =====================================================
    // CONTADOR DE REFRESCO
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            refresh_count <= 0;
            digit_sel     <= 2'b00;

        end

        else begin

            if (refresh_count == REFRESH_DIV - 1) begin

                refresh_count <= 0;
                digit_sel     <= digit_sel + 1'b1;

            end

            else begin

                refresh_count <= refresh_count + 1;

            end

        end

    end


    // =====================================================
    // MULTIPLEXOR DE DIGITOS
    // =====================================================

    always_comb begin

        current_digit = 4'd0;
        an_o          = 4'b1111;

        case (digit_sel)

            // Dígito derecho: unidades J2
            2'b00: begin

                current_digit = j2_ones;
                an_o          = 4'b1110;

            end


            // Decenas J2
            2'b01: begin

                current_digit = j2_tens;
                an_o          = 4'b1101;

            end


            // Unidades J1
            2'b10: begin

                current_digit = j1_ones;
                an_o          = 4'b1011;

            end


            // Dígito izquierdo: decenas J1
            2'b11: begin

                current_digit = j1_tens;
                an_o          = 4'b0111;

            end

        endcase

    end


    // =====================================================
    // DECODIFICADOR 7 SEGMENTOS
    //
    // Salidas activas en bajo
    // seg_o = {g,f,e,d,c,b,a}
    // =====================================================

    always_comb begin

        case (current_digit)

            4'd0: seg_o = 7'b1000000;
            4'd1: seg_o = 7'b1111001;
            4'd2: seg_o = 7'b0100100;
            4'd3: seg_o = 7'b0110000;
            4'd4: seg_o = 7'b0011001;
            4'd5: seg_o = 7'b0010010;
            4'd6: seg_o = 7'b0000010;
            4'd7: seg_o = 7'b1111000;
            4'd8: seg_o = 7'b0000000;
            4'd9: seg_o = 7'b0010000;

            default:
                seg_o = 7'b1111111;

        endcase

    end


endmodule
