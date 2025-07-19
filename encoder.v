module quadrature_encoder_velocity (
    input        clk,
    input        rst_n,

    input  [15:0] addr,
    output reg [7:0] data_out,

    input         cs,
    input         rd,

    // Señales del encoder
    input         A,
    input         B
);

    //------------------------------------
    // Estados internos del encoder
    //------------------------------------
    reg [1:0] state_reg;
    reg [1:0] state_next;

    //------------------------------------
    // Contador de pasos
    //------------------------------------
    reg [15:0] step_count;

    //------------------------------------
    // Lógica secuencial: actualizar estado y pasos
    //------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= 2'b00;
            step_count <= 0;
        end else begin
            state_reg <= state_next;

            if ((A != state_reg[0]) || (B != state_reg[1])) begin
                step_count <= step_count + 1;
            end
        end
    end

    //------------------------------------
    // Lógica combinacional: siguiente estado
    //------------------------------------
    always @(*) begin
        case ({state_reg, A, B})
            4'b00_00: state_next = 2'b00;
            4'b00_01: state_next = 2'b01;
            4'b00_10: state_next = 2'b10;
            4'b00_11: state_next = 2'b11;
            4'b01_00: state_next = 2'b00;
            4'b01_11: state_next = 2'b11;
            4'b10_00: state_next = 2'b00;
            4'b10_11: state_next = 2'b11;
            4'b11_10: state_next = 2'b10;
            4'b11_01: state_next = 2'b01;
            4'b11_11: state_next = 2'b11;
            default:  state_next = state_reg;
        endcase
    end

    //------------------------------------
    // Interfaz con el microcontrolador
    //------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h00;
        end else if (cs && rd) begin
            case (addr)
                16'h0001: data_out <= step_count[7:0];         // Paso - LSB
                16'h0002: data_out <= step_count[15:8];        // Paso - MSB
                16'h0003: data_out <= {6'b0, state_reg};       // Estado actual
                default:   data_out <= 8'h00;
            endcase
        end else begin
            data_out <= 8'bz; // Alta impedancia cuando no se lee
        end
    end

endmodule
