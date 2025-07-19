`timescale 1ns / 1ps

module tb_full_system;

    // Señales globales
    reg clk;
    reg rst_n;

    // Control externo
    reg enable_motor_tb;
    reg motor_dir_tb;
    reg [7:0] limit_tb;

    // Señales observables
    wire A, B;
    wire direction;
    wire [31:0] step_count;
    wire done;
    wire motor_dir_internal;

    // Generación del reloj a 100 MHz
    always #5 clk = ~clk;

    // Instancia del sistema completo
    top_encoder_control_system_custom #(
        .STEP_PERIOD(50000)   // 50us entre pasos (ajustable)
    ) uut (
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

    initial begin
        // Creación del archivo para GTKWave
        $dumpfile("full_encoder_system.vcd");     // nombre del archivo VCD
        $dumpvars(0, tb_full_system);             // guardar todas las señales
        $dumpvars(1, uut);                        // guardar todo dentro del módulo top

        // Inicialización
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

        // Primera etapa: sentido horario con límite 8
        $display(">>> Etapa 1: motor CW con límite 8");
        #3_000_000;

        // Cambiar dirección manualmente
        $display(">>> Etapa 2: motor CCW manual");
        motor_dir_tb = 1;
        #2_000_000;

        // Cambiar el límite a 12 pasos
        $display(">>> Etapa 3: cambiar límite a 12");
        limit_tb = 12;
        #2_000_000;

        // Desactivar motor
        $display(">>> Etapa 4: detener motor");
        enable_motor_tb = 0;
        #1_000_000;

        $display(">>> Simulación completa.");
        $finish;
    end

endmodule
