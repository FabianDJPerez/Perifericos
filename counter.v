module step_counter_limit (
    input        clk,
    input        rst_n,

    input  [15:0] addr,
    input         cs,
    input         rd,
    output reg [7:0] data_out,

    input         A,
    input         B,

    input  [15:0] limit_in,
    input         load_limit,
    output reg    done
);

    // Estado cuadratura anterior
    reg [1:0] prev_state;
    wire [1:0] curr_state = {A, B};

    // Contador de pasos
    reg [15:0] step_count;

    // Límite programable
    reg [15:0] limit_reg;

    // Señal de paso detectado
    wire step_up;
    wire step_down;

    assign step_up   = ({prev_state, curr_state} == 4'b0001) ||
                       ({prev_state, curr_state} == 4'b0111) ||
                       ({prev_state, curr_state} == 4'b1110) ||
                       ({prev_state, curr_state} == 4'b1000);

    assign step_down = ({prev_state, curr_state} == 4'b0010) ||
                       ({prev_state, curr_state} == 4'b0100) ||
                       ({prev_state, curr_state} == 4'b1101) ||
                       ({prev_state, curr_state} == 4'b1011);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_state <= 2'b00;
            step_count <= 0;
            limit_reg  <= 0;
            done <= 0;
        end else begin
            prev_state <= curr_state;

            // Carga límite programado
            if (load_limit)
                limit_reg <= limit_in;

            // Actualiza contador
            if (step_up && !done)
                step_count <= step_count + 1;
            else if (step_down && step_count > 0 && !done)
                step_count <= step_count - 1;

            // Verifica si alcanzó el límite
            if (step_count >= limit_reg && limit_reg != 0)
                done <= 1;
        end
    end

    // Interfaz de lectura
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h00;
        end else if (cs && rd) begin
            case (addr)
                16'h0000: data_out <= step_count[7:0];     // LSB contador
                16'h0001: data_out <= step_count[15:8];    // MSB contador
                16'h0002: data_out <= limit_reg[7:0];      // LSB límite
                16'h0003: data_out <= limit_reg[15:8];     // MSB límite
                16'h0004: data_out <= {7'b0, done};        // Bit de estado "done"
                default:  data_out <= 8'h00;
            endcase
        end else begin
            data_out <= 8'bz;
        end
    end

endmodule
