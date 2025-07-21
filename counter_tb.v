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

    // Instancia del módulo
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
    
    // Agrega aquí la definición del módulo step_counter_limit o asegúrate de que esté en otro archivo incluido en la simulación.
    // Por ejemplo:
    /*
    module step_counter_limit(
        input clk,
        input rst_n,
        input [15:0] addr,
        input cs,
        input rd,
        output [7:0] data_out,
        input A,
        input B,
        input [15:0] limit_in,
        input load_limit,
        output done
    );
    // Implementación del módulo aquí
    endmodule
    */

    // Generador de reloj (100 MHz)
    always #5 clk = ~clk;

    // Secuencia de señales cuadratura
    task simulate_step(input integer dir);
        begin
            if (dir == 1) begin // CW
                {A, B} = 2'b00; #20;
                {A, B} = 2'b01; #20;
                {A, B} = 2'b11; #20;
                {A, B} = 2'b10; #20;
                {A, B} = 2'b00; #20;
            end else begin // CCW
                {A, B} = 2'b00; #20;
                {A, B} = 2'b10; #20;
                {A, B} = 2'b11; #20;
                {A, B} = 2'b01; #20;
                {A, B} = 2'b00; #20;
            end
        end
    endtask

    // Lectura del bus
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
        // Dump para GTKWave
        $dumpfile("counter_tb.vcd");
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

        // Establecer límite a 5 pasos
        limit_in = 16'd5;
        load_limit = 1;
        #10 load_limit = 0;

        // Simular 5 pasos en sentido horario
        $display("Simulando pasos CW...");
        repeat (5) simulate_step(1);

        // Leer valores
        $display("--- Lecturas después de CW ---");
        read_reg(16'h0000); // Step count LSB
        read_reg(16'h0001); // Step count MSB
        read_reg(16'h0002); // Limit LSB
        read_reg(16'h0003); // Limit MSB
        read_reg(16'h0004); // Done flag

        // Simular 2 pasos CCW
        $display("Simulando pasos CCW...");
        repeat (2) simulate_step(0);

        // Leer valores nuevamente
        $display("--- Lecturas después de CCW ---");
        read_reg(16'h0000); // Step count LSB
        read_reg(16'h0001); // Step count MSB
        read_reg(16'h0004); // Done flag

        #200;
        $display("Simulación completa.");
        $finish;
    end

endmodule
