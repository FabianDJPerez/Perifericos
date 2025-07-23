`timescale 1ns/1ps

module tb_full_system;

    // Clock & reset
    reg clk;
    reg rst_n;

    // Motor control
    reg enable;
    reg motor_dir;
    wire A, B;

    // Límite de pasos
    reg [15:0] limit_in;
    reg load_limit;
    wire done;

    // Encoder interface
    wire [7:0] encoder_data_out;
    reg [15:0] encoder_addr;
    reg encoder_cs, encoder_rd;

    // Step counter interface
    wire [7:0] counter_data_out;
    reg [15:0] counter_addr;
    reg counter_cs, counter_rd;

    // Clock: 100 MHz (10ns período)
    always #5 clk = ~clk;

    // ------------------ INSTANCIAS ------------------ //
    simulated_motor_encoder #(
        .STEP_PERIOD(1000) // 1000ns entre pasos
    ) motor_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .motor_dir(motor_dir),
        .A(A),
        .B(B)
    );

    step_counter_limit counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(counter_addr),
        .cs(counter_cs),
        .rd(counter_rd),
        .data_out(counter_data_out),
        .A(A),
        .B(B),
        .limit_in(limit_in),
        .load_limit(load_limit),
        .done(done)
    );

    quadrature_encoder_velocity encoder_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(encoder_addr),
        .data_out(encoder_data_out),
        .cs(encoder_cs),
        .rd(encoder_rd),
        .A(A),
        .B(B)
    );

    // ------------------ TESTBENCH ------------------ //
    initial begin
        $dumpfile("full_system_sim.vcd");
        $dumpvars(0, tb_full_system);

        // Inicialización
        clk = 0;
        rst_n = 0;
        enable = 0;
        motor_dir = 0;
        limit_in = 20;          // 5 ciclos * 4 pasos
        load_limit = 0;
        encoder_addr = 0;
        encoder_cs = 0;
        encoder_rd = 0;
        counter_addr = 0;
        counter_cs = 0;
        counter_rd = 0;

        // Reset
        #200;
        rst_n = 1;

        // Cargar límite
        #200;
        load_limit = 1;
        #10;
        load_limit = 0;

        // Activar motor CW
        enable = 1;
        motor_dir = 0;

        // Esperar que se alcance el límite
        wait (done == 1);

        // Detener motor
        enable = 0;
        $display("Primer sentido completo. Pasos: %0d", counter_data_out);
        #1000;

        // Invertir dirección y resetear sistema
        rst_n = 0;
        #200;
        rst_n = 1;

        // Cargar nuevo límite
        limit_in = 20; // nuevamente 5 ciclos
        #20;
        load_limit = 1;
        #10;
        load_limit = 0;

        // Activar motor en dirección contraria
        enable = 1;
        motor_dir = 1;

        wait (done == 1);
        enable = 0;

        // Lectura de registros
        #50;
        $display("----- RESULTADOS DEL CONTADOR -----");
        read_counter(16'h0000);
        read_counter(16'h0001);
        read_counter(16'h0004);

        $display("----- RESULTADOS DEL ENCODER -----");
        read_encoder(16'h0001);
        read_encoder(16'h0002);
        read_encoder(16'h0003);

        #100000; // Tiempo de espera final
        $finish;
    end

    // Timeout de respaldo extendido
    initial begin
        #10000000;  // 10 ms = suficiente para 2 giros completos
        $display("Timeout alcanzado");
        $finish;
    end

    // ------------------ TAREAS ------------------ //
    task read_counter(input [15:0] addr);
        begin
            counter_addr = addr;
            counter_cs = 1;
            counter_rd = 1;
            #10;
            $display("Counter[0x%0h] = 0x%0h", addr, counter_data_out);
            counter_cs = 0;
            counter_rd = 0;
            #10;
        end
    endtask

    task read_encoder(input [15:0] addr);
        begin
            encoder_addr = addr;
            encoder_cs = 1;
            encoder_rd = 1;
            #10;
            $display("Encoder[0x%0h] = 0x%0h", addr, encoder_data_out);
            encoder_cs = 0;
            encoder_rd = 0;
            #10;
        end
    endtask

endmodule
