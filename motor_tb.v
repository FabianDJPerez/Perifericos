`timescale 1ns / 1ps

module tb_motor;

    reg clk, rst_n;
    reg enable;
    reg dir;
    wire A, B;

    // Clock de 100MHz (10ns)
    always #5 clk = ~clk;

    // Instancia del encoder con STEP_PERIOD rápido
    simulated_motor_encoder #(
        .STEP_PERIOD(50)  // 50ns -> cambio cada 5 ciclos
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .motor_dir(dir),
        .A(A),
        .B(B)
    );

    initial begin
        $dumpfile("motor_sim.vcd");
        $dumpvars(0, tb_motor);

        clk = 0;
        rst_n = 0;
        enable = 0;
        dir = 0;

        #100; rst_n = 1;
        #100; enable = 1;

        $display(">>> Giro horario...");
        dir = 0;
        #20_000;  // 20us

        $display(">>> Giro antihorario...");
        dir = 1;
        #20_000;  // 20us

        enable = 0;
        #1_000;  // 1us extra antes de terminar
        $finish;
    end

    initial begin
        $monitor("t=%0t | A=%b B=%b dir=%b", $time, A, B, dir);
    end
endmodule