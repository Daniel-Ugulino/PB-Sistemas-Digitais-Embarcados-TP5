`timescale 1ns / 1ps

// config_tx — 2 testes: quadro completo de telemetria e reinicio apos CS

module config_tx_tb;

    localparam CLK_NS = 10;

    localparam [7:0] STX        = 8'h02;
    localparam [7:0] ETX        = 8'h03;
    localparam [7:0] TYPE_SPEED = 8'h20;

    reg        clk;
    reg        rst;
    reg  [7:0] speed;
    reg  [7:0] dist_e;
    reg  [7:0] dist_c;
    reg  [7:0] dist_d;
    reg  [7:0] vel_e;
    reg  [7:0] vel_c;
    reg  [7:0] vel_d;
    reg  [1:0] dir;
    reg        cs_desce;
    reg        quadro_ativo;
    reg  [7:0] rx_byte;
    reg        byte_valido;
    reg        quadro_fim;

    wire [7:0] tx_byte;

    integer erros;

    config_tx dut (
        .clk          (clk),
        .rst          (rst),
        .speed        (speed),
        .dist_e       (dist_e),
        .dist_c       (dist_c),
        .dist_d       (dist_d),
        .vel_e        (vel_e),
        .vel_c        (vel_c),
        .vel_d        (vel_d),
        .dir          (dir),
        .cs_desce     (cs_desce),
        .quadro_ativo (quadro_ativo),
        .rx_byte      (rx_byte),
        .byte_valido  (byte_valido),
        .quadro_fim   (quadro_fim),
        .tx_byte      (tx_byte)
    );

    initial clk = 1'b0;
    always #(CLK_NS/2) clk = ~clk;

    task check_tx;
        input [7:0]   exp;
        input [255:0] name;
        begin
            if (tx_byte === exp)
                $display("OK   %0s  tx=0x%02x", name, tx_byte);
            else begin
                $display("ERROR %0s  tx=0x%02x (exp 0x%02x)", name, tx_byte, exp);
                erros = erros + 1;
            end
        end
    endtask

    task spi_byte;
        begin
            @(negedge clk);
            byte_valido = 1'b1;
            @(posedge clk);
            @(negedge clk);
            byte_valido = 1'b0;
        end
    endtask

    task load_telemetry;
        input [7:0] sp;
        input [7:0] de;
        input [7:0] dc;
        input [7:0] dd;
        input [7:0] ve;
        input [7:0] vc;
        input [7:0] vd;
        input [1:0] dr;
        begin
            speed  = sp;
            dist_e = de;
            dist_c = dc;
            dist_d = dd;
            vel_e  = ve;
            vel_c  = vc;
            vel_d  = vd;
            dir    = dr;
        end
    endtask

    task run_full_frame;
        begin
            @(negedge clk);
            quadro_ativo = 1'b1;
            cs_desce     = 1'b1;
            byte_valido  = 1'b0;
            @(posedge clk);
            check_tx(STX, "frame STX");
            @(negedge clk);
            cs_desce = 1'b0;

            spi_byte;
            check_tx(TYPE_SPEED, "frame TYPE");
            spi_byte;
            check_tx(speed, "frame speed");
            spi_byte;
            check_tx(dist_e, "frame dist_e");
            spi_byte;
            check_tx(dist_c, "frame dist_c");
            spi_byte;
            check_tx(dist_d, "frame dist_d");
            spi_byte;
            check_tx(vel_e, "frame vel_e");
            spi_byte;
            check_tx(vel_c, "frame vel_c");
            spi_byte;
            check_tx(vel_d, "frame vel_d");
            spi_byte;
            check_tx({6'b0, dir}, "frame dir");
            spi_byte;
            check_tx(ETX, "frame ETX");

            @(negedge clk);
            quadro_ativo = 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("tb/config_tx_tb.vcd");
        $dumpvars(0, config_tx_tb);

        erros        = 0;
        speed        = 8'd0;
        dist_e       = 8'd0;
        dist_c       = 8'd0;
        dist_d       = 8'd0;
        vel_e        = 8'd0;
        vel_c        = 8'd0;
        vel_d        = 8'd0;
        dir          = 2'b00;
        cs_desce     = 1'b0;
        quadro_ativo = 1'b0;
        rx_byte      = 8'd0;
        byte_valido  = 1'b0;
        quadro_fim   = 1'b0;

        rst = 1'b1;
        repeat (3) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        // 1. Normal — 11 bytes STX|0x20|payload|ETX
        load_telemetry(8'd60, 8'd100, 8'd80, 8'd90,
                       8'd10, 8'd20, 8'd30, 2'b01);
        run_full_frame;

        // 2. Borda — quadro_ativo cai no meio; novo CS recomeca em STX
        load_telemetry(8'd45, 8'd55, 8'd65, 8'd75,
                       8'd5, 8'd6, 8'd7, 2'b10);
        @(negedge clk);
        quadro_ativo = 1'b1;
        cs_desce     = 1'b1;
        @(posedge clk);
        check_tx(STX, "2a CS apos reset STX");
        @(negedge clk);
        cs_desce = 1'b0;
        spi_byte;
        check_tx(TYPE_SPEED, "2a TYPE");
        spi_byte;
        check_tx(speed, "2a speed parcial");

        @(negedge clk);
        quadro_ativo = 1'b0;
        @(posedge clk);

        @(negedge clk);
        quadro_ativo = 1'b1;
        cs_desce     = 1'b1;
        @(posedge clk);
        check_tx(STX, "2b reinicio STX");
        @(negedge clk);
        cs_desce = 1'b0;
        spi_byte;
        check_tx(TYPE_SPEED, "2b TYPE");
        spi_byte;
        check_tx(speed, "2b speed");

        if (erros == 0)
            $display("config_tx: 2 testes OK");
        else
            $display("config_tx: %0d FALHAS", erros);

        $finish;
    end

endmodule
