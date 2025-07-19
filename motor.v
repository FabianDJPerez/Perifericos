module simulated_motor_encoder #(
    parameter STEP_PERIOD = 100_000 // Tiempo entre fases (en ns)
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    input  wire motor_dir,     // 0: CW, 1: CCW
    output reg A,
    output reg B
);

    reg [1:0] state;
    reg [31:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= 2'b00;
            counter <= 0;
            A       <= 0;
            B       <= 0;
        end else if (enable) begin
            if (counter >= STEP_PERIOD) begin
                counter <= 0;

                // Avanzar estado según dirección
                case (state)
                    2'b00: state <= (motor_dir) ? 2'b10 : 2'b01;
                    2'b01: state <= (motor_dir) ? 2'b00 : 2'b11;
                    2'b11: state <= (motor_dir) ? 2'b01 : 2'b10;
                    2'b10: state <= (motor_dir) ? 2'b11 : 2'b00;
                    default: state <= 2'b00;
                endcase

                // Actualizar señales A y B
                case (state)
                    2'b00: begin A <= 0; B <= 0; end
                    2'b01: begin A <= 1; B <= 0; end
                    2'b11: begin A <= 1; B <= 1; end
                    2'b10: begin A <= 0; B <= 1; end
                endcase
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
