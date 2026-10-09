module indicators_mmio (
    input  logic        clk_i,
    input  logic        rst_i,

    input  logic        write_enable_i,
    input  logic [1:0]  addr_i,
    input  logic [31:0] wdata_i,

    output logic [31:0] rdata_o,

    output logic [31:0] display_data_o,
    output logic [31:0] led_data_o,
    output logic [31:0] buzzer_data_o
);

    localparam logic [1:0] DISPLAY = 2'b00;
    localparam logic [1:0] LED     = 2'b01;
    localparam logic [1:0] BUZZER  = 2'b10;


    // =====================================================
    // ESCRITURA DE REGISTROS
    // =====================================================

    always_ff @(posedge clk_i) begin

        if (rst_i) begin

            display_data_o <= 32'b0;
            led_data_o     <= 32'b0;
            buzzer_data_o  <= 32'b0;

        end

        else if (write_enable_i) begin

            case (addr_i)

                DISPLAY:
                    display_data_o <= wdata_i;

                LED:
                    led_data_o <= wdata_i;

                BUZZER:
                    buzzer_data_o <= wdata_i;

                default: begin
                    display_data_o <= display_data_o;
                    led_data_o     <= led_data_o;
                    buzzer_data_o  <= buzzer_data_o;
                end

            endcase

        end

    end


    // =====================================================
    // LECTURA DE REGISTROS
    // =====================================================

    always_comb begin

        case (addr_i)

            DISPLAY:
                rdata_o = display_data_o;

            LED:
                rdata_o = led_data_o;

            BUZZER:
                rdata_o = buzzer_data_o;

            default:
                rdata_o = 32'b0;

        endcase

    end

endmodule