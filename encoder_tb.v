`timescale 1ns / 1ps

module tb_encoder;

    reg clk;
    reg rst_n;
    reg [15:0] addr;
    wire [7:0] data_out;
    reg cs;
    reg rd;

    // Señales del encoder
    reg A;
    reg B;

    // Internos para simulación sin delay
    integer step_index = 0;
    integer step_interval = 1000; // Intervalo inicial de 10us (1000 ciclos)
    integer step_counter = 0;
    reg [1:0] step_sequence [0:3];
    reg rotation_dir = 1; // 1 = CW, 0 = CCW
    reg sim_active = 0;

    // Para etiquetas de texto
    reg [127:0] label;

    // Temporizador de 20ms para cambio de dirección
    integer rotation_timer;

    // Instancia del periférico
    quadrature_encoder_velocity uut (
        .clk(clk), 
        .rst_n(rst_n),
        .addr(addr),
        .data_out(data_out),
        .cs(cs),
        .rd(rd),
        .A(A),
        .B(B)
    );

    // Generador de reloj: 1 MHz
    always #500 clk = ~clk;

    // Secuencia de 4 pasos para codificador en cuadratura
    initial begin
        step_sequence[0] = 2'b00;
        step_sequence[1] = 2'b01;
        step_sequence[2] = 2'b11;
        step_sequence[3] = 2'b10;
    end

    // Simulación principal
    initial begin
        // Dump para GTKWave
        $dumpfile("encoder_sim.vcd");
        $dumpvars(0, tb_encoder);

        // Inicialización
        clk = 0;
        rst_n = 0;
        A = 0;
        B = 0;
        cs = 0;
        rd = 0;
        addr = 16'h0000;
        step_counter = 0;
        rotation_timer = 0;
        sim_active = 1;

        #20 rst_n = 1;

        // Simulación continua durante 100 ms (1e8 ns)
        #100_000_000;
        sim_active = 0;
        $display("Simulación completa.");
        $finish;
    end

    // Control automático de dirección a los 20 ms
    always @(posedge clk) begin
        if (rst_n && sim_active) begin
            if (rotation_timer < 20000) begin
                rotation_timer <= rotation_timer + 1;
            end else begin
                rotation_dir <= ~rotation_dir;
                rotation_timer <= 0;
                $display(">>> Dirección cambiada a %s en t=%0t ns <<<", 
                         (rotation_dir ? "CW" : "CCW"), $time);
                read_registers((rotation_dir ? "Cambio a CW" : "Cambio a CCW"));
            end
        end else begin
            rotation_timer <= 0;
        end
    end

    // Simulador de rotación sin delay
    always @(posedge clk) begin
        if (sim_active) begin
            if (step_counter == 0) begin
                if (rotation_dir)
                    step_index = (step_index + 1) % 4; // CW
                else
                    step_index = (step_index + 3) % 4; // CCW
                {A, B} <= step_sequence[step_index];
                step_counter <= step_interval;
            end else begin
                step_counter <= step_counter - 1;
            end
        end else begin
            step_counter <= 0;
        end
    end

    // Lectura de registros al cambiar dirección
    task read_register(input [15:0] reg_addr);
        cs = 1;
        rd = 1;
        addr = reg_addr;
        #100_000;
        $display("Leído valor %h desde dirección %h", data_out, reg_addr);
        cs = 0;
        rd = 0;
        addr = 16'h0000;
        #100_000;
    endtask

    task read_registers(input [127:0] label);
        $display("\n--- %s ---", label);
        read_register(16'h0001); // Paso LSB
        read_register(16'h0002); // Paso MSB
        read_register(16'h0003); // Estado interno
    endtask

endmodule
