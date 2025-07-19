`timescale 1ns / 1ps

module tb_full_system;

    // Reloj y reset
    reg clk;
    reg rst_n;

    // Parámetros configurables
    reg enable_motor_tb;
    reg motor_dir_tb;
    reg [7:0] limit_tb;

    // Señales observables
    wire A, B;
    wire direction;
    wire [31:0] step_count;
    wire done;
    wire motor_dir_internal;

    //---------------------------------------
    // Reloj a 100 MHz (10 ns de período)
    //---------------------------------------
    always #5 clk = ~clk;

    //---------------------------------------
    // Instancia del sistema de prueba
    //---------------------------------------
    top_encoder_control_system_custom uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable_motor_in(enable_motor_tb),
        .motor_dir_in(motor_dir_tb),
        .limit_value_in(limit_tb),
        .A_out(A),
        .B_out(B),
        .step_count_out(step_count),
        .direction_out(direction),
        .done_out(done),
        .motor_dir_out(motor_dir_internal)
    );

    //---------------------------------------
    // Proceso de simulación
    //---------------------------------------
    initial begin
        $dumpfile("full_encoder_system.vcd");
        $dumpvars(0, tb_full_system);

        clk = 0;
        rst_n = 0;
        enable_motor_tb = 0;
        motor_dir_tb = 0;
        limit_tb = 8;

        // Reset
        #100;
        rst_n = 1;

        // Activar motor
        #50;
        enable_motor_tb = 1;

        // Simulación con motor horario y límite 8 pasos
        #2_000_000; // 2 ms

        // Cambiar dirección manualmente (aunque normalmente es automático)
        motor_dir_tb = 1;
        #2_000_000;

        // Cambiar el límite a 12 pasos
        limit_tb = 12;
        #2_000_000;

        // Desactivar motor
        enable_motor_tb = 0;
        #1_000_000;

        $display("Simulación completa.");
        $finish;
    end

endmodule
