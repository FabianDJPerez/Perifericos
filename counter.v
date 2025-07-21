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

    reg [1:0] prev_state;
    reg [1:0] prev_prev_state;
    wire [1:0] curr_state = {A, B};

    reg [15:0] counter;
    reg [1:0] state_history [0:3];
    integer state_index;

    // Dirección: 1 = CW, 0 = CCW
    reg rotation_dir;
    reg last_direction;

    function is_full_rotation;
        input [1:0] s0, s1, s2, s3;
        begin
            is_full_rotation = (
                (s0 == 2'b00 && s1 == 2'b01 && s2 == 2'b11 && s3 == 2'b10) || // CW
                (s0 == 2'b00 && s1 == 2'b10 && s2 == 2'b11 && s3 == 2'b01)    // CCW
            );
        end
    endfunction

    function detect_direction;
        input [1:0] s0, s1, s2, s3;
        begin
            if (s0 == 2'b00 && s1 == 2'b01 && s2 == 2'b11 && s3 == 2'b10)
                detect_direction = 1; // CW
            else if (s0 == 2'b00 && s1 == 2'b10 && s2 == 2'b11 && s3 == 2'b01)
                detect_direction = 0; // CCW
            else
                detect_direction = last_direction; // No cambio válido
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_state <= 2'b00;
            prev_prev_state <= 2'b00;
            counter <= 0;
            last_direction <= 1; // valor por defecto
            state_index <= 0;
            state_history[0] <= 2'b00;
            state_history[1] <= 2'b00;
            state_history[2] <= 2'b00;
            state_history[3] <= 2'b00;
        end else begin
            prev_prev_state <= prev_state;
            prev_state <= curr_state;

            // Control de historial
            state_history[state_index] <= curr_state;
            if (state_index == 3)
                state_index <= 0;
            else
                state_index <= state_index + 1;

            // Giro completo detectado
            if (curr_state == 2'b00 && is_full_rotation(state_history[0], state_history[1], state_history[2], state_history[3])) begin
                rotation_dir = detect_direction(state_history[0], state_history[1], state_history[2], state_history[3]);

                // Reinicia si cambió de dirección
                if (rotation_dir != last_direction)
                    counter <= 1;
                else
                    counter <= counter + 1;

                last_direction <= rotation_dir;
            end
        end
    end

endmodule
