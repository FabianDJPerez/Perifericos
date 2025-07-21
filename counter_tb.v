`timescale 1ns / 1ps

module tb_step_counter_limit;

    reg clk;
    reg rst_n;

    // Bus
    reg [15:0] addr;
    reg cs;
    reg rd;
    wire [7:0] data_out;

    // Encoder
    reg A;
    reg B;

    // Límite
    reg [15:0] limit_in;
    reg load_limit;
    wire done;

    // Exponer contador y bandera de cambio de dirección
    wire [15:0] counter_internal;
    wire flag_direction_change;
    assign counter_internal = uut.counter;
    assign flag_direction_change = uut.flag_direction_change;

    // DUT
    step_counter_limit uut (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .cs(cs),
        .rd(rd),
        .data_out(data_out),
        .A(A),
        .B(B),
        .limit_in(limit_in),
        .load_limit(load_limit),
        .done(done)
    );

    // Generador de reloj (100 MHz)
    always #5 clk = ~clk;

    // Simula una secuencia prolongada de A y B alternando direcciones
    reg [1:0] step_sequence [0:3];
    integer step_index = 0;
    integer i;

    initial begin
        // Secuencia para CW: 00 → 01 → 11 → 10
        step_sequence[0] = 2'b00;
        step_sequence[1] = 2'b01;
        step_sequence[2] = 2'b11;
        step_sequence[3] = 2'b10;
    end

    task simulate_rotations;
        input integer cycles;
        input integer direction; // 1 = CW, 0 = CCW
        begin
            for (i = 0; i < cycles; i = i + 1) begin
                if (direction) begin
                    step_index = 0;
                    repeat (4) begin
                        {A, B} = step_sequence[step_index];
                        #40;
                        step_index = (step_index + 1) % 4;
                    end
                    {A, B} = 2'b00; #40;
                end else begin
                    step_index = 3;
                    repeat (4) begin
                        {A, B} = step_sequence[step_index];
                        #40;
                        step_index = (step_index - 1 + 4) % 4;
                    end
                    {A, B} = 2'b00; #40;
                end
            end
        end
    endtask

    // Lectura de registro
    task read_reg(input [15:0] address);
        begin
            addr = address;
            cs = 1;
            rd = 1;
            #20;
            $display("Lectura de addr %h: %h", address, data_out);
            cs = 0;
            rd = 0;
            #20;
        end
    endtask

    initial begin
        $dumpfile("counter_sim.vcd");
        $dumpvars(0, tb_step_counter_limit);

        // Inicialización
        clk = 0;
        rst_n = 0;
        A = 0; B = 0;
        cs = 0; rd = 0;
        addr = 0;
        limit_in = 0;
        load_limit = 0;

        #50;
        rst_n = 1;

        $display("\n--- Simulación prolongada con cambios de dirección ---");

        simulate_rotations(3, 1); // 3 giros CW
        simulate_rotations(3, 0); // 3 giros CCW
        simulate_rotations(3, 1); // 3 giros CW

        read_reg(16'h0005); // counter LSB
        read_reg(16'h0006); // counter MSB
        $display("Valor interno de counter: %d", counter_internal);
        $display("Flag de cambio de dirección: %b", flag_direction_change);

        $display("\nSimulación completa.");
        #100;
        $finish;
    end

endmodule