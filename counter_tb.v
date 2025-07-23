`timescale 1ns / 1ps

module tb_step_counter_limit;

    reg clk, rst_n;
    reg A, B;
    reg cs, rd;
    reg [15:0] addr;
    wire [7:0] data_out;
    reg [15:0] limit_in;
    reg load_limit;
    wire done;

    // DUT
    step_counter_limit dut (
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

    // Clock generator
    always #5 clk = ~clk;

    // Tarea para simular un paso CW
    task do_step_cw;
        begin
            {A, B} = 2'b00; #100;
            {A, B} = 2'b01; #100;
            {A, B} = 2'b11; #100;
            {A, B} = 2'b10; #100;
        end
    endtask

    // Tarea para simular un paso CCW
    task do_step_ccw;
        begin
            {A, B} = 2'b00; #100;
            {A, B} = 2'b10; #100;
            {A, B} = 2'b11; #100;
            {A, B} = 2'b01; #100;
        end
    endtask

    initial begin
        $dumpfile("counter_sim.vcd");
        $dumpvars(0, tb_step_counter_limit);

        clk = 0;
        rst_n = 0;
        cs = 0;
        rd = 0;
        addr = 16'h0000;
        limit_in = 9;
        load_limit = 0;
        A = 0; B = 0;

        // Reset
        #50; rst_n = 1;

        // Cargar límite
        #20; load_limit = 1;
        #10; load_limit = 0;

        // Hacer 12 pasos CW 
        repeat (3) begin
            do_step_cw();
        end

        // Leer bandera done
        #50;
        addr = 16'h0004;
        cs = 1; rd = 1;
        #10;
        $display("Done after CW: %b", data_out[0]);
        cs = 0; rd = 0;

        // Reset total para segunda prueba
        #50;
        rst_n = 0;
        #20;
        rst_n = 1;

        // Cargar nuevo límite
        limit_in = 12;
        #20; load_limit = 1;
        #10; load_limit = 0;

        // Hacer 20 pasos CCW 
        repeat (5) do_step_ccw(); 



        // Leer bandera done
        #50;
        addr = 16'h0004;
        cs = 1; rd = 1;
        #10;
        $display("Done after CCW: %b", data_out[0]);

        $finish;
    end

endmodule
