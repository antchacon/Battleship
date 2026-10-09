`timescale 1ns/1ps

// ============================================================================
// RISC-V RV32I - Nucleo integrado en un unico archivo para Proyecto Battleship
//
// Basado en los modulos del procesador entregados por el equipo en el proyecto
// anterior. Las memorias internas de instrucciones y datos fueron retiradas:
//   - ProgAddress_o / ProgIn_i conectan con la ROM externa.
//   - DataAddress_o / DataOut_o / DataIn_i / we_o conectan con el interconnect.
//
// Los modulos auxiliares llevan prefijo rv32_ para evitar conflictos de nombres
// con otros modulos del proyecto Vivado.
// ============================================================================
module rv32_adder #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A,
  input  logic [WIDTH-1:0] B,
  output logic [WIDTH-1:0] out
);
  assign out = A + B;
endmodule

module rv32_register #(parameter WIDTH=32) (
  input  logic              clk,
  input  logic              rst,
  input  logic [WIDTH-1:0]  data_in,
  input  logic              wr,
  output logic [WIDTH-1:0]  data_out
);
  always_ff @(posedge clk) begin
    if      (rst) data_out <= '0;
    else if (wr)  data_out <= data_in;
    else          data_out <= data_out;
  end
endmodule

module rv32_reg_file #(parameter WIDTH=32, parameter DEPTH=5) (
  input  logic               clk,
  input  logic               rst,
  input  logic [WIDTH-1:0]   write_data,
  input  logic [DEPTH-1:0]   write_register,
  input  logic               wr,
  input  logic [DEPTH-1:0]   read_register_1,
  input  logic [DEPTH-1:0]   read_register_2,
  input  logic               rd, // ignorado
  output logic [WIDTH-1:0]   read_data_1,
  output logic [WIDTH-1:0]   read_data_2
);
  logic [WIDTH-1:0] registers [0:(1<<DEPTH)-1];
  integer i;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      for (i=0;i<(1<<DEPTH);i++) registers[i] <= '0;
    end else begin
      registers[0] <= '0;
      if (wr && (write_register!='0)) begin
        registers[write_register] <= write_data;
      end
    end
  end

  // Bypass WB -> ID: si en este mismo flanco se escribe un registro
  // que tambien se esta leyendo, entregar directamente write_data.
  // Esto evita capturar el valor viejo del banco de registros.
  always_comb begin
    if (read_register_1 == '0)
      read_data_1 = '0;
    else if (wr && (write_register != '0) &&
             (write_register == read_register_1))
      read_data_1 = write_data;
    else
      read_data_1 = registers[read_register_1];

    if (read_register_2 == '0)
      read_data_2 = '0;
    else if (wr && (write_register != '0) &&
             (write_register == read_register_2))
      read_data_2 = write_data;
    else
      read_data_2 = registers[read_register_2];
  end
endmodule

module rv32_alu #(parameter WIDTH=32) (
  input  logic  [WIDTH-1:0] data_in_1,
  input  logic  [WIDTH-1:0] data_in_2,
  input  logic  [2:0]       func3,
  input  logic  [6:0]       func7,
  input  logic  [6:0]       opcode,
  output logic [WIDTH-1:0]  data_out,
  output logic              zero,
  output logic              comparison
);
  localparam ALI_OP    = 7'b0010011;
  localparam AL_OP     = 7'b0110011;
  localparam MEM_WR_OP = 7'b0100011;
  localparam MEM_RD_OP = 7'b0000011;
  localparam BR_OP     = 7'b1100011;
  localparam JALR_OP   = 7'b1100111;
  localparam LUI_OP    = 7'b0110111;
  localparam AUIPC_OP  = 7'b0010111;

  logic [4:0] shamt;
  assign shamt = data_in_2[4:0];

  always_comb begin
    data_out   = '0;
    comparison = 1'b0;

    case (opcode)
      ALI_OP: begin
        case (func3)
          3'b000: data_out = $signed(data_in_1) + $signed(data_in_2);             // addi
          3'b001: data_out = data_in_1 << shamt;                                  // slli
          3'b010: data_out = ($signed(data_in_1) <  $signed(data_in_2)) ? 32'd1 : 32'd0; // slti
          3'b011: data_out = ( data_in_1       <   data_in_2      ) ? 32'd1 : 32'd0;     // sltiu
          3'b100: data_out = data_in_1 ^ data_in_2;                               // xori
          3'b101: data_out = (func7 == 7'b0100000) ?
                              ($signed(data_in_1) >>> shamt) :                    // srai
                              (data_in_1 >> shamt);                               // srli
          3'b110: data_out = data_in_1 | data_in_2;                               // ori
          3'b111: data_out = data_in_1 & data_in_2;                               // andi
        endcase
      end

      AL_OP: begin
        case (func3)
          3'b000: data_out = (func7 == 7'b0100000) ?
                              ($signed(data_in_1) - $signed(data_in_2)) :         // sub
                              ($signed(data_in_1) + $signed(data_in_2));          // add
          3'b001: data_out = data_in_1 << shamt;                                  // sll
          3'b010: data_out = ($signed(data_in_1) <  $signed(data_in_2)) ? 32'd1 : 32'd0; // slt
          3'b011: data_out = ( data_in_1       <   data_in_2      ) ? 32'd1 : 32'd0;     // sltu
          3'b100: data_out = data_in_1 ^ data_in_2;                               // xor
          3'b101: data_out = (func7 == 7'b0100000) ?
                              ($signed(data_in_1) >>> shamt) :                    // sra
                              (data_in_1 >> shamt);                               // srl
          3'b110: data_out = data_in_1 | data_in_2;                               // or
          3'b111: data_out = data_in_1 & data_in_2;                               // and
        endcase
      end

      MEM_WR_OP,
      MEM_RD_OP,
      JALR_OP,
      AUIPC_OP: data_out = $signed(data_in_1) + $signed(data_in_2); // base+offset

      LUI_OP:   data_out = data_in_2; // lui

      BR_OP: begin
        case (func3)
          3'b000: comparison = ($signed(data_in_1) == $signed(data_in_2)); // beq
          3'b001: comparison = ($signed(data_in_1) != $signed(data_in_2)); // bne
          3'b100: comparison = ($signed(data_in_1) <  $signed(data_in_2)); // blt
          3'b101: comparison = ($signed(data_in_1) >= $signed(data_in_2)); // bge
          3'b110: comparison = ( data_in_1        <   data_in_2       );   // bltu
          3'b111: comparison = ( data_in_1        >=  data_in_2       );   // bgeu
          default: comparison = 1'b0;
        endcase
      end

      default: begin
        data_out   = '0;
        comparison = 1'b0;
      end
    endcase
  end

  assign zero = (data_out == '0);

endmodule

module rv32_imm_gen #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] instr,
  output logic [WIDTH-1:0] data_out
);
  localparam ALI_OP    = 7'b0010011;
  localparam MEM_WR_OP = 7'b0100011;
  localparam MEM_RD_OP = 7'b0000011;
  localparam BR_OP     = 7'b1100011;
  localparam JALR      = 7'b1100111;
  localparam JAL       = 7'b1101111;
  localparam LUI       = 7'b0110111;
  localparam AUIPC     = 7'b0010111;

  logic [6:0] opcode;
  logic [2:0] func3;
  assign opcode = instr[6:0];
  assign func3  = instr[14:12];

  // <<< IMPORTANTE: usar always @* y case normal >>>
  always @* begin
    case (opcode)
      ALI_OP: begin
        // slli/srli/srai usan shamt (5 bits) sin sign-extend
        if (func3 == 3'b001 || func3 == 3'b101)
          data_out = {27'b0, instr[24:20]};
        else
          data_out = {{20{instr[31]}}, instr[31:20]};
      end

      MEM_WR_OP: data_out = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S
      MEM_RD_OP: data_out = {{20{instr[31]}}, instr[31:20]};              // I
      BR_OP:     data_out = {{19{instr[31]}}, instr[31], instr[7],
                             instr[30:25], instr[11:8], 1'b0};            // B
      JALR:      data_out = {{20{instr[31]}}, instr[31:20]};              // I
      JAL:       data_out = {{11{instr[31]}}, instr[31], instr[19:12],
                             instr[20], instr[30:21], 1'b0};              // J
      LUI:       data_out = {instr[31:12], 12'b0};                        // U
      AUIPC:     data_out = {instr[31:12], 12'b0};                        // U

      default:   data_out = '0;
    endcase
  end
endmodule

module rv32_control_deco #(parameter WIDTH=32, parameter INST_SIZE = 32) (
  input  logic  [WIDTH-1:0] instr,
  input  logic              comparison,
  output logic [1:0]        if_mux_sel,   // 0: pc+4, 1: PC+IMM, 2: JALR
  output logic              ex_mux_sel,   // 0: rs2, 1: imm (NO lo usamos en top)
  output logic [1:0]        wb_mux_sel,   // 0: ALU, 1: MEM, 2: PC+4, 3: PC+IMM
  output logic              reg_file_rd,  // no usado
  output logic              reg_file_wr,
  output logic              mem_read,
  output logic              mem_write,
  output logic              one_byte,
  output logic              two_bytes,
  output logic              four_bytes
);
  localparam ALI_OP    = 7'b0010011;
  localparam AL_OP     = 7'b0110011;
  localparam MEM_WR_OP = 7'b0100011;
  localparam MEM_RD_OP = 7'b0000011;
  localparam BR_OP     = 7'b1100011;
  localparam JALR      = 7'b1100111;
  localparam JAL       = 7'b1101111;
  localparam LUI       = 7'b0110111;
  localparam AUIPC     = 7'b0010111;

  logic [6:0] opcode;  logic [2:0] func3;
  assign opcode = instr[6:0];
  assign func3  = instr[14:12];

  always_comb begin
    if_mux_sel   = 2'd0;  ex_mux_sel = 1'b0;  wb_mux_sel = 2'd0;
    reg_file_rd  = 1'b0;  reg_file_wr = 1'b0;
    mem_read     = 1'b0;  mem_write   = 1'b0;
    one_byte     = 1'b0;  two_bytes   = 1'b0;  four_bytes = 1'b0;

    case (opcode)
      AL_OP:    begin ex_mux_sel=1'b0; reg_file_wr=1'b1; wb_mux_sel=2'd0; end
      ALI_OP:   begin ex_mux_sel=1'b1; reg_file_wr=1'b1; wb_mux_sel=2'd0; end
      MEM_RD_OP:begin ex_mux_sel=1'b1; reg_file_wr=1'b1; mem_read=1'b1; wb_mux_sel=2'd1;
                       case(func3)
                         3'b000,3'b100: one_byte=1'b1;
                         3'b001,3'b101: two_bytes=1'b1;
                         default:       four_bytes=1'b1;
                       endcase
                 end
      MEM_WR_OP:begin ex_mux_sel=1'b1; mem_write=1'b1;
                       case(func3)
                         3'b000: one_byte=1'b1;
                         3'b001: two_bytes=1'b1;
                         default: four_bytes=1'b1;
                       endcase
                 end
      BR_OP:    begin if_mux_sel = (comparison) ? 2'd1 : 2'd0; end
      JAL:      begin if_mux_sel=2'd1; reg_file_wr=1'b1; wb_mux_sel=2'd2; end
      JALR:     begin if_mux_sel=2'd2; reg_file_wr=1'b1; wb_mux_sel=2'd2; ex_mux_sel=1'b1; end
      LUI:      begin ex_mux_sel=1'b1; reg_file_wr=1'b1; wb_mux_sel=2'd0; end   // ALU (inmediato)
      AUIPC:    begin ex_mux_sel=1'b1; reg_file_wr=1'b1; wb_mux_sel=2'd3; end   // PC+IMM
      default:  ;
    endcase
  end
endmodule

module rv32_if_id_reg #(parameter WIDTH = 32) (
    input  logic              clk,
    input  logic              rst,
    input  logic              en,
    input  logic              flush,
    input  logic [WIDTH-1:0]  pc_if,
    input  logic [WIDTH-1:0]  instr_if,
    output logic [WIDTH-1:0]  pc_id,
    output logic [WIDTH-1:0]  instr_id
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      pc_id    <= '0;
      instr_id <= 32'h00000013; // NOP
    end else if (flush) begin
      pc_id    <= '0;
      instr_id <= 32'h00000013;
    end else if (en) begin
      pc_id    <= pc_if;
      instr_id <= instr_if;
    end
  end
endmodule

module rv32_id_ex_reg #(parameter WIDTH = 32) (
    input  logic              clk,
    input  logic              rst,
    input  logic              en,
    input  logic              flush,
    input  logic [WIDTH-1:0]  pc_id,
    input  logic [WIDTH-1:0]  rs1_data_id,
    input  logic [WIDTH-1:0]  rs2_data_id,
    input  logic [WIDTH-1:0]  imm_id,
    input  logic [WIDTH-1:0]  instr_id,
    output logic [WIDTH-1:0]  pc_ex,
    output logic [WIDTH-1:0]  rs1_data_ex,
    output logic [WIDTH-1:0]  rs2_data_ex,
    output logic [WIDTH-1:0]  imm_ex,
    output logic [WIDTH-1:0]  instr_ex
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      pc_ex       <= '0;
      rs1_data_ex <= '0;
      rs2_data_ex <= '0;
      imm_ex      <= '0;
      instr_ex    <= 32'h00000013;
    end else if (en) begin
      pc_ex       <= pc_id;
      rs1_data_ex <= rs1_data_id;
      rs2_data_ex <= rs2_data_id;
      imm_ex      <= imm_id;
      instr_ex    <= instr_id;
    end
  end
endmodule

module rv32_hazard_unit (
    // --- ID stage ---
    input  logic [4:0] rs1_id,
    input  logic [4:0] rs2_id,

    // --- EX stage ---
    input  logic        mem_read_ex,
    input  logic [4:0]  rd_ex,

    // --- Branch/JAL/JALR decision (desde EX) ---
    input  logic [1:0]  if_mux_sel_ex,

    // --- Salidas ---
    output logic pc_en,
    output logic if_id_en,
    output logic if_id_flush,
    output logic id_ex_flush
);

  // 1) LOAD-USE HAZARD → stall 1 ciclo
  logic load_use_hazard;
  assign load_use_hazard =
      mem_read_ex &&
      (rd_ex != 5'd0) &&
      ( (rd_ex == rs1_id) || (rd_ex == rs2_id) );

  // 2) FLUSH por salto/branch tomado
  logic flush_branch;
  assign flush_branch = (if_mux_sel_ex == 2'd1) || (if_mux_sel_ex == 2'd2);

  // Señales finales
  assign pc_en       = !load_use_hazard;
  assign if_id_en    = !load_use_hazard;
  // En un salto/branch tomado también debe limpiarse la instrucción más joven
  // que ya estaba en ID. Si no, esa instrucción de camino incorrecto entra a EX.
  assign id_ex_flush = load_use_hazard || flush_branch;

  // El flush de branch SOLO limpia IF/ID (no ID/EX)
  assign if_id_flush = flush_branch;

endmodule

module rv32_ex_mem_reg #(parameter WIDTH = 32) (
    input  logic              clk,
    input  logic              rst,
    input  logic              en,
    input  logic              flush,
    input  logic [WIDTH-1:0]  pc4_ex,
    input  logic [WIDTH-1:0]  pcimm_ex,
    input  logic [WIDTH-1:0]  alu_out_ex,
    input  logic [WIDTH-1:0]  rs2_data_ex,
    input  logic [4:0]        rd_ex,
    input  logic [1:0]        wb_mux_sel_ex,
    input  logic              reg_file_wr_ex,
    input  logic              mem_read_ex,
    input  logic              mem_write_ex,
    input  logic              one_byte_ex,
    input  logic              two_bytes_ex,
    input  logic              four_bytes_ex,
    output logic [WIDTH-1:0]  pc4_mem,
    output logic [WIDTH-1:0]  pcimm_mem,
    output logic [WIDTH-1:0]  alu_out_mem,
    output logic [WIDTH-1:0]  rs2_data_mem,
    output logic [4:0]        rd_mem,
    output logic [1:0]        wb_mux_sel_mem,
    output logic              reg_file_wr_mem,
    output logic              mem_read_mem,
    output logic              mem_write_mem,
    output logic              one_byte_mem,
    output logic              two_bytes_mem,
    output logic              four_bytes_mem
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      pc4_mem         <= '0;
      pcimm_mem       <= '0;
      alu_out_mem     <= '0;
      rs2_data_mem    <= '0;
      rd_mem          <= '0;
      wb_mux_sel_mem  <= 2'd0;
      reg_file_wr_mem <= 1'b0;
      mem_read_mem    <= 1'b0;
      mem_write_mem   <= 1'b0;
      one_byte_mem    <= 1'b0;
      two_bytes_mem   <= 1'b0;
      four_bytes_mem  <= 1'b0;
    end else if (en) begin
      pc4_mem         <= pc4_ex;
      pcimm_mem       <= pcimm_ex;
      alu_out_mem     <= alu_out_ex;
      rs2_data_mem    <= rs2_data_ex;
      rd_mem          <= rd_ex;
      wb_mux_sel_mem  <= wb_mux_sel_ex;
      reg_file_wr_mem <= reg_file_wr_ex;
      mem_read_mem    <= mem_read_ex;
      mem_write_mem   <= mem_write_ex;
      one_byte_mem    <= one_byte_ex;
      two_bytes_mem   <= two_bytes_ex;
      four_bytes_mem  <= four_bytes_ex;
    end
  end
endmodule

module rv32_mem_wb_reg #(parameter WIDTH = 32) (
    input  logic              clk,
    input  logic              rst,
    input  logic              en,
    input  logic              flush,
    input  logic [WIDTH-1:0]  mem_data_mem,
    input  logic [WIDTH-1:0]  alu_out_mem,
    input  logic [WIDTH-1:0]  pc4_mem,
    input  logic [WIDTH-1:0]  pcimm_mem,
    input  logic [4:0]        rd_mem,
    input  logic [1:0]        wb_mux_sel_mem,
    input  logic              reg_file_wr_mem,
    output logic [WIDTH-1:0]  mem_data_wb,
    output logic [WIDTH-1:0]  alu_out_wb,
    output logic [WIDTH-1:0]  pc4_wb,
    output logic [WIDTH-1:0]  pcimm_wb,
    output logic [4:0]        rd_wb,
    output logic [1:0]        wb_mux_sel_wb,
    output logic              reg_file_wr_wb
);
  always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
      mem_data_wb     <= '0;
      alu_out_wb      <= '0;
      pc4_wb          <= '0;
      pcimm_wb        <= '0;
      rd_wb           <= '0;
      wb_mux_sel_wb   <= 2'd0;
      reg_file_wr_wb  <= 1'b0;
    end else if (en) begin
      mem_data_wb     <= mem_data_mem;
      alu_out_wb      <= alu_out_mem;
      pc4_wb          <= pc4_mem;
      pcimm_wb        <= pcimm_mem;
      rd_wb           <= rd_mem;
      wb_mux_sel_wb   <= wb_mux_sel_mem;
      reg_file_wr_wb  <= reg_file_wr_mem;
    end
  end
endmodule

module rv32_mux_4_1 #(parameter WIDTH=32) (
  input  logic [WIDTH-1:0] A, B, C, D,
  input  logic [1:0]       sel,
  output logic [WIDTH-1:0] out
);
  always_comb begin
    case (sel)
      2'h0: out = A;
      2'h1: out = B;
      2'h2: out = C;
      2'h3: out = D;
      default: out = A; // corta X
    endcase
  end
endmodule

// ============================================================================
// NUCLEO PRINCIPAL
// ============================================================================

module riscv_core #(
  parameter WIDTH           = 32,
  parameter INST_MEM_DEPTH  = 8,   // conservado por compatibilidad; ROM es externa
  parameter REG_FILE_DEPTH  = 5,
  parameter DATA_MEM_DEPTH  = 16,  // conservado por compatibilidad; RAM es externa
  parameter INST_SIZE       = 32
)(
  input  logic              clk_i,
  input  logic              rst_i,

  output logic [31:0]       ProgAddress_o,
  input  logic [31:0]       ProgIn_i,        // instruccion desde ROM externa

  output logic [31:0]       DataAddress_o,
  output logic [31:0]       DataOut_o,
  input  logic [31:0]       DataIn_i,        // dato desde RAM/perifericos externos

  output logic              we_o,
  output logic [WIDTH-1:0]  pc_out
);

  // ========= Constantes de opcodes para lógica interna =========
  localparam ALI_OP    = 7'b0010011;
  localparam AL_OP     = 7'b0110011;
  localparam MEM_WR_OP = 7'b0100011;
  localparam MEM_RD_OP = 7'b0000011;
  localparam BR_OP     = 7'b1100011;
  localparam JALR      = 7'b1100111;
  localparam JAL       = 7'b1101111;
  localparam LUI       = 7'b0110111;
  localparam AUIPC     = 7'b0010111;

  // ------------------------------------------------------------
  // Señales de hazards
  // ------------------------------------------------------------
  logic pc_en;
  logic if_id_en;
  logic if_id_flush;
  logic id_ex_flush;

  // ------------------------------------------------------------
  // IF stage
  // ------------------------------------------------------------
  logic [WIDTH-1:0] pc_next;
  logic [WIDTH-1:0] pc_4_if;
  logic [WIDTH-1:0] instr_if;

  rv32_register #(.WIDTH(WIDTH)) u_pc (
    .clk     (clk_i),
    .rst     (rst_i),
    .data_in (pc_next),
    .wr      (pc_en),
    .data_out(pc_out)
  );

  rv32_adder #(.WIDTH(WIDTH)) u_pc_plus4_if (
    .A   (pc_out),
    .B   (32'd4),
    .out (pc_4_if)
  );

  // Instruccion suministrada por la ROM externa del sistema
  assign instr_if = ProgIn_i;

  // ------------------------------------------------------------
  // IF/ID
  // ------------------------------------------------------------
  logic [WIDTH-1:0] pc_id;
  logic [WIDTH-1:0] instr_id;     // esta es la "instruction" visible al TB

  rv32_if_id_reg #(.WIDTH(WIDTH)) u_if_id (
    .clk      (clk_i),
    .rst      (rst_i),
    .en       (if_id_en),
    .flush    (if_id_flush),
    .pc_if    (pc_out),
    .instr_if (instr_if),
    .pc_id    (pc_id),
    .instr_id (instr_id)
  );

  // ------------------------------------------------------------
  // ID stage
  // ------------------------------------------------------------
  logic [4:0] rs1_idx_id, rs2_idx_id, rd_idx_id;
  assign rs1_idx_id = instr_id[19:15];
  assign rs2_idx_id = instr_id[24:20];
  assign rd_idx_id  = instr_id[11:7];

  logic [WIDTH-1:0] rs1_data_id, rs2_data_id;
  logic [WIDTH-1:0] imm_id;

  // WB signals (desde la etapa WB)
  logic [WIDTH-1:0] wb_data;
  logic [4:0]       rd_idx_wb;
  logic             reg_file_wr_wb;

  rv32_reg_file #(.WIDTH(WIDTH), .DEPTH(REG_FILE_DEPTH)) u_rf (
    .clk              (clk_i),
    .rst              (rst_i),
    .write_data       (wb_data),
    .write_register   (rd_idx_wb),
    .wr               (reg_file_wr_wb),
    .read_register_1  (rs1_idx_id),
    .read_register_2  (rs2_idx_id),
    .rd               (1'b1),
    .read_data_1      (rs1_data_id),
    .read_data_2      (rs2_data_id)
  );

  rv32_imm_gen #(.WIDTH(WIDTH)) u_imm (
    .instr    (instr_id),
    .data_out (imm_id)
  );

  // ------------------------------------------------------------
  // ID/EX
  // ------------------------------------------------------------
  logic [WIDTH-1:0] pc_ex;
  logic [WIDTH-1:0] rs1_data_ex, rs2_data_ex, imm_ex, instr_ex;

  rv32_id_ex_reg #(.WIDTH(WIDTH)) u_id_ex (
    .clk        (clk_i),
    .rst        (rst_i),
    .en         (1'b1),
    .flush      (id_ex_flush),
    .pc_id      (pc_id),
    .rs1_data_id(rs1_data_id),
    .rs2_data_id(rs2_data_id),
    .imm_id     (imm_id),
    .instr_id   (instr_id),
    .pc_ex      (pc_ex),
    .rs1_data_ex(rs1_data_ex),
    .rs2_data_ex(rs2_data_ex),
    .imm_ex     (imm_ex),
    .instr_ex   (instr_ex)
  );

  // Índices en EX (para forwarding y hazards)
  logic [4:0] rs1_idx_ex, rs2_idx_ex, rd_idx_ex;
  assign rs1_idx_ex = instr_ex[19:15];
  assign rs2_idx_ex = instr_ex[24:20];
  assign rd_idx_ex  = instr_ex[11:7];

  // ------------------------------------------------------------
  // Señales de MEM y WB (para forwarding)
  // ------------------------------------------------------------
  logic [WIDTH-1:0] pc4_mem, pcimm_mem;
  logic [WIDTH-1:0] alu_out_mem, rs2_data_mem;
  logic [4:0]       rd_idx_mem;
  logic [1:0]       wb_mux_sel_mem;
  logic             reg_file_wr_mem;
  logic             mem_read_mem, mem_write_mem;
  logic             one_byte_mem, two_bytes_mem, four_bytes_mem;

  logic [WIDTH-1:0] mem_data_mem;

  // Valor real producido por la etapa MEM para forwarding.
  // No siempre es alu_out_mem:
  //   0 -> resultado ALU
  //   1 -> dato leído de memoria/MMIO
  //   2 -> PC+4
  //   3 -> PC+IMM
  logic [WIDTH-1:0] mem_forward_data;

  always_comb begin
    case (wb_mux_sel_mem)
      2'd0: mem_forward_data = alu_out_mem;
      2'd1: mem_forward_data = mem_data_mem;
      2'd2: mem_forward_data = pc4_mem;
      2'd3: mem_forward_data = pcimm_mem;
      default: mem_forward_data = alu_out_mem;
    endcase
  end

  logic [WIDTH-1:0] mem_data_wb, alu_out_wb, pc4_wb, pcimm_wb;
  logic [1:0]       wb_mux_sel_wb;

  // ------------------------------------------------------------
  // EX stage (con FORWARDING)
  // ------------------------------------------------------------
  logic [2:0] func3_ex;
  logic [6:0] func7_ex, opcode_ex;
  assign func3_ex  = instr_ex[14:12];
  assign func7_ex  = instr_ex[31:25];
  assign opcode_ex = instr_ex[6:0];

  // ex_mux_sel se calcula localmente (sin bucle con rv32_control_deco)
  logic ex_mux_sel_ex;
  always_comb begin
    case (opcode_ex)
      AL_OP:     ex_mux_sel_ex = 1'b0;  // R-type usa rs2
      ALI_OP,
      MEM_RD_OP,
      MEM_WR_OP,
      JALR,
      LUI,
      AUIPC:     ex_mux_sel_ex = 1'b1;  // usa imm
      default:   ex_mux_sel_ex = 1'b0;
    endcase
  end

  // -------- Forwarding unit --------
  typedef enum logic [1:0] {FWD_NONE=2'b00, FWD_MEM=2'b01, FWD_WB=2'b10} fwd_t;
  fwd_t forwardA, forwardB;

  always_comb begin
    forwardA = FWD_NONE;
    forwardB = FWD_NONE;

    // A: rs1_ex
    if (reg_file_wr_mem && (rd_idx_mem != 0) && (rd_idx_mem == rs1_idx_ex))
      forwardA = FWD_MEM;
    else if (reg_file_wr_wb && (rd_idx_wb != 0) && (rd_idx_wb == rs1_idx_ex))
      forwardA = FWD_WB;

    // B: rs2_ex
    if (reg_file_wr_mem && (rd_idx_mem != 0) && (rd_idx_mem == rs2_idx_ex))
      forwardB = FWD_MEM;
    else if (reg_file_wr_wb && (rd_idx_wb != 0) && (rd_idx_wb == rs2_idx_ex))
      forwardB = FWD_WB;
  end

  logic [WIDTH-1:0] fwd_rs1_ex, fwd_rs2_ex;

  always_comb begin
    // rs1
    case (forwardA)
      FWD_NONE: fwd_rs1_ex = rs1_data_ex;
      FWD_MEM:  fwd_rs1_ex = mem_forward_data; // resultado real producido en MEM
      FWD_WB:   fwd_rs1_ex = wb_data;     // dato final en WB
      default:  fwd_rs1_ex = rs1_data_ex;
    endcase

    // rs2 (para ALU y para stores)
    case (forwardB)
      FWD_NONE: fwd_rs2_ex = rs2_data_ex;
      FWD_MEM:  fwd_rs2_ex = mem_forward_data;
      FWD_WB:   fwd_rs2_ex = wb_data;
      default:  fwd_rs2_ex = rs2_data_ex;
    endcase
  end

  // Entrada B de la ALU: o inmediato o rs2 con forwarding
  logic [WIDTH-1:0] alu_b_in_ex;
  assign alu_b_in_ex = ex_mux_sel_ex ? imm_ex : fwd_rs2_ex;

  logic [WIDTH-1:0] alu_out_ex;
  logic             zero_ex;
  logic             comparison_ex;

  rv32_alu #(.WIDTH(WIDTH)) u_alu (
    .data_in_1  (fwd_rs1_ex),
    .data_in_2  (alu_b_in_ex),
    .func3      (func3_ex),
    .func7      (func7_ex),
    .opcode     (opcode_ex),
    .data_out   (alu_out_ex),
    .zero       (zero_ex),
    .comparison (comparison_ex)
  );

  // PC+4 y PC+IMM en EX
  logic [WIDTH-1:0] pc4_ex, pcimm_ex;
  rv32_adder #(.WIDTH(WIDTH)) u_pc_plus4_ex (
    .A   (pc_ex),
    .B   (32'd4),
    .out (pc4_ex)
  );

  rv32_adder #(.WIDTH(WIDTH)) u_pc_plus_imm_ex (
    .A   (pc_ex),
    .B   (imm_ex),
    .out (pcimm_ex)
  );

  logic [WIDTH-1:0] jalr_target_ex;
  assign jalr_target_ex = alu_out_ex & ~32'd1;

  
  logic [1:0] if_mux_sel_ex;
  logic       ex_mux_sel_dummy;
  logic [1:0] wb_mux_sel_ex;
  logic       reg_file_wr_ex;
  logic       mem_read_ex, mem_write_ex;
  logic       one_byte_ex, two_bytes_ex, four_bytes_ex;
  logic       reg_file_rd_dummy;

  rv32_control_deco #(.INST_SIZE(INST_SIZE)) u_ctrl (
    .instr       (instr_ex),
    .comparison  (comparison_ex),
    .if_mux_sel  (if_mux_sel_ex),
    .ex_mux_sel  (ex_mux_sel_dummy),
    .wb_mux_sel  (wb_mux_sel_ex),
    .reg_file_rd (reg_file_rd_dummy),
    .reg_file_wr (reg_file_wr_ex),
    .mem_read    (mem_read_ex),
    .mem_write   (mem_write_ex),
    .one_byte    (one_byte_ex),
    .two_bytes   (two_bytes_ex),
    .four_bytes  (four_bytes_ex)
  );

  // -------- Unidad de hazards --------
  rv32_hazard_unit u_haz (
    .rs1_id        (rs1_idx_id),
    .rs2_id        (rs2_idx_id),
    .mem_read_ex   (mem_read_ex),
    .rd_ex         (rd_idx_ex),
    .if_mux_sel_ex (if_mux_sel_ex),
    .pc_en         (pc_en),
    .if_id_en      (if_id_en),
    .if_id_flush   (if_id_flush),
    .id_ex_flush   (id_ex_flush)
  );

  // ------------------------------------------------------------
  // EX/MEM  (nota: pasamos rs2 ya adelantado para stores)
  // ------------------------------------------------------------
  rv32_ex_mem_reg #(.WIDTH(WIDTH)) u_ex_mem (
    .clk           (clk_i),
    .rst           (rst_i),
    .en            (1'b1),
    .flush         (1'b0),
    .pc4_ex        (pc4_ex),
    .pcimm_ex      (pcimm_ex),
    .alu_out_ex    (alu_out_ex),
    .rs2_data_ex   (fwd_rs2_ex),      // store data con forwarding
    .rd_ex         (rd_idx_ex),
    .wb_mux_sel_ex (wb_mux_sel_ex),
    .reg_file_wr_ex(reg_file_wr_ex),
    .mem_read_ex   (mem_read_ex),
    .mem_write_ex  (mem_write_ex),
    .one_byte_ex   (one_byte_ex),
    .two_bytes_ex  (two_bytes_ex),
    .four_bytes_ex (four_bytes_ex),
    .pc4_mem       (pc4_mem),
    .pcimm_mem     (pcimm_mem),
    .alu_out_mem   (alu_out_mem),
    .rs2_data_mem  (rs2_data_mem),
    .rd_mem        (rd_idx_mem),
    .wb_mux_sel_mem(wb_mux_sel_mem),
    .reg_file_wr_mem(reg_file_wr_mem),
    .mem_read_mem  (mem_read_mem),
    .mem_write_mem (mem_write_mem),
    .one_byte_mem  (one_byte_mem),
    .two_bytes_mem (two_bytes_mem),
    .four_bytes_mem(four_bytes_mem)
  );

  // ------------------------------------------------------------
  // MEM stage
  // ------------------------------------------------------------

  // Dato suministrado por RAM o perifericos externos mediante MMIO
  assign mem_data_mem = DataIn_i;

  // ------------------------------------------------------------
  // MEM/WB
  // ------------------------------------------------------------
  rv32_mem_wb_reg #(.WIDTH(WIDTH)) u_mem_wb (
    .clk            (clk_i),
    .rst            (rst_i),
    .en             (1'b1),
    .flush          (1'b0),
    .mem_data_mem   (mem_data_mem),
    .alu_out_mem    (alu_out_mem),
    .pc4_mem        (pc4_mem),
    .pcimm_mem      (pcimm_mem),
    .rd_mem         (rd_idx_mem),
    .wb_mux_sel_mem (wb_mux_sel_mem),
    .reg_file_wr_mem(reg_file_wr_mem),
    .mem_data_wb    (mem_data_wb),
    .alu_out_wb     (alu_out_wb),
    .pc4_wb         (pc4_wb),
    .pcimm_wb       (pcimm_wb),
    .rd_wb          (rd_idx_wb),
    .wb_mux_sel_wb  (wb_mux_sel_wb),
    .reg_file_wr_wb (reg_file_wr_wb)
  );

  // ------------------------------------------------------------
  // WB stage
  // ------------------------------------------------------------
  rv32_mux_4_1 #(.WIDTH(WIDTH)) u_wb_mux (
    .A   (alu_out_wb),
    .B   (mem_data_wb),
    .C   (pc4_wb),
    .D   (pcimm_wb),
    .sel (wb_mux_sel_wb),
    .out (wb_data)
  );

  // ------------------------------------------------------------
  // NEXT PC (PC selection usando decisión en EX)
  // ------------------------------------------------------------
  always_comb begin
    case (if_mux_sel_ex)
      2'd0: pc_next = pc_4_if;       // flujo normal
      2'd1: pc_next = pcimm_ex;      // BR/JAL: PC+IMM (desde EX)
      2'd2: pc_next = jalr_target_ex;// JALR
      default: pc_next = pc_4_if;
    endcase
  end

  // ------------------------------------------------------------
  // Mapeo + señales internas que usa el testbench
  // ------------------------------------------------------------
  assign ProgAddress_o = pc_out;
  assign DataAddress_o = alu_out_mem;
  assign DataOut_o     = rs2_data_mem;
  assign we_o          = mem_write_mem;

  
  logic [WIDTH-1:0] alu_out;
  logic [WIDTH-1:0] rs2_data;
  logic             mem_write;
  logic             one_byte;

  assign alu_out    = alu_out_mem;
  assign rs2_data   = rs2_data_mem;
  assign mem_write  = mem_write_mem;
  assign one_byte   = one_byte_mem;

  
  logic [WIDTH-1:0] instruction;
  assign instruction = instr_id;

endmodule