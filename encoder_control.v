module top_encoder_control_system_custom #(
    parameter STEP_PERIOD = 50000
)(
    input wire clk,
    input wire rst_n,
    input wire enable_motor_in,
    input wire motor_dir_in,
    input wire [7:0] limit_value_in,

    output wire A_out,
    output wire B_out,
    output wire [31:0] step_count_out,
    output wire direction_out,
    output wire done_out,
    output wire motor_dir_out
);

    wire A, B;
    wire direction;
    wire done;
    reg [31:0] step_count;
    reg [7:0] limit_reg;
    reg motor_dir;

    assign step_count_out = step_count;

    // Reasignar motor_dir para exportarlo
    assign motor_dir_out = motor_dir;

    // Instancia del motor simulado
    simulated_motor_encoder #(
        .STEP_PERIOD(STEP_PERIOD)
    ) motor_sim (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable_motor_in),
        .motor_dir(motor_dir),
        .A(A),
        .B(B)
    );

    // Salidas para observación
    assign A_out = A;
    // Instancia del encoder
    quadrature_encoder_velocity encoder_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(16'h0000),
        .data_out(),
        .cs(1'b0),
        .rd(1'b0),
        .A(A),
        .B(B)
    );


    // Instancia del contador con límite
    step_counter_limit step_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(16'h0000),
        .cs(1'b0),
        .rd(1'b0),
        .data_out(),
        .A(A),
        .B(B),
        .limit_in(limit_value_in),
        .load_limit(1'b0), // Assign a default value or connect to a proper signal
        .done(done)
    );


    assign done_out = done;

    // Lógica de control de dirección
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            motor_dir <= 0;
        end else if (done) begin
            motor_dir <= ~motor_dir;
        end else begin
            motor_dir <= motor_dir_in;
        end
    end

endmodule
