`timescale 1ns / 1ps

// config_rx — 2 testes: pacote valido e aborto por quadro_fim

module config_rx_tb;

    localparam CLK_NS = 10;

    localparam [7:0] STX      = 8'h02;
    localparam [7:0] ETX      = 8'h03;
    localparam [7:0] TYPE_CFG = 8'h10;

    reg        clk;
    reg        rst;
    reg  [7:0] rx_byte;
    reg        byte_valido;
    reg        quadro_fim;

    wire [7:0] dist_free;
    wire [7:0] dist_att;
    wire [7:0] vel_max;
    wire       cfg_valid;

    integer erros;

    config_rx dut (
        .clk         (clk),
        .rst         (rst),
        .rx_byte     (rx_byte),
        .byte_valido (byte_valido),
        .quadro_fim  (quadro_fim),
        .dist_free   (dist_free),
        .dist_att    (dist_att),
        .vel_max     (vel_max),
        .cfg_valid   (cfg_valid)
    );

    initial clk = 1'b0;
    always #(CLK_NS/2) clk = ~clk;

    task send_byte;
        input [7:0] data;
        begin
            @(negedge clk);
            rx_byte     = data;
            byte_valido = 1'b1;
            quadro_fim  = 1'b0;
            @(posedge clk);
            @(negedge clk);
            byte_valido = 1'b0;
        end
    endtask

    task send_cfg_packet;
        input [7:0] free;
        input [7:0] att;
        input [7:0] vel;
        begin
            send_byte(STX);
            send_byte(TYPE_CFG);
            send_byte(free);
            send_byte(att);
            send_byte(vel);
            send_byte(ETX);
        end
    endtask

    task check_regs;
        input [7:0]   exp_free;
        input [7:0]   exp_att;
        input [7:0]   exp_vel;
        input         exp_valid;
        input [255:0] name;
        begin
            if (dist_free === exp_free && dist_att === exp_att &&
                vel_max === exp_vel && cfg_valid === exp_valid)
                $display("OK   %0s  free=%0d att=%0d vel=%0d valid=%0b",
                         name, dist_free, dist_att, vel_max, cfg_valid);
            else begin
                $display("ERROR %0s  free=%0d (exp %0d) att=%0d (exp %0d) vel=%0d (exp %0d) valid=%0b (exp %0b)",
                         name, dist_free, exp_free, dist_att, exp_att,
                         vel_max, exp_vel, cfg_valid, exp_valid);
                erros = erros + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb/config_rx_tb.vcd");
        $dumpvars(0, config_rx_tb);

        erros       = 0;
        rx_byte     = 8'd0;
        byte_valido = 1'b0;
        quadro_fim  = 1'b0;

        rst = 1'b1;
        repeat (3) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        // 1. Normal — pacote completo STX|0x10|80|40|120|ETX
        send_cfg_packet(8'd80, 8'd40, 8'd120);
        check_regs(8'd80, 8'd40, 8'd120, 1'b1, "1 pacote valido");

        // 2. Borda — quadro_fim no meio do pacote aborta sem gravar
        send_byte(STX);
        send_byte(TYPE_CFG);
        send_byte(8'd99);
        @(negedge clk);
        quadro_fim = 1'b1;
        @(posedge clk);
        quadro_fim = 1'b0;
        @(posedge clk);
        check_regs(8'd80, 8'd40, 8'd120, 1'b0, "2 aborto quadro_fim");

        if (erros == 0)
            $display("config_rx: 2 testes OK");
        else
            $display("config_rx: %0d FALHAS", erros);

        $finish;
    end

endmodule
