module fsm_sensors #(
    parameter CLK_HZ       = 27_000_000,
    parameter GAP_MS       = 60,
    parameter TRIG_US      = 20,
    parameter BLIND_US     = 300,
    parameter WARMUP_MS    = 50,
    parameter TIMEOUT_MS   = 30,
    parameter MAX_JUMP_CM  = 12,
    parameter MAX_REJECTS = 3
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       iniciar,
    input  wire       echo_e,
    input  wire       echo_c,
    input  wire       echo_d,
    output wire       trig_e,
    output wire       trig_c,
    output wire       trig_d,
    output reg  [7:0] dist_e,
    output reg  [7:0] dist_c,
    output reg  [7:0] dist_d,
    output reg        valid_e,
    output reg        valid_c,
    output reg        valid_d,
    output reg        ciclo_pronto,
    output reg        timeout_e,
    output reg  [3:0] estado_fsm
);

    localparam GAP_RAW    = (CLK_HZ / 1_000) * GAP_MS;
    localparam GAP_CYCLES = (GAP_RAW > 0) ? GAP_RAW : 1;

    localparam WARMUP_RAW    = (CLK_HZ / 1_000) * WARMUP_MS;
    localparam WARMUP_CYCLES = (WARMUP_RAW > 0) ? WARMUP_RAW : 1;

    localparam F_IDLE   = 4'd0;
    localparam F_MED_E  = 4'd1;
    localparam F_GAP_EC = 4'd2;
    localparam F_MED_C  = 4'd3;
    localparam F_GAP_CD = 4'd4;
    localparam F_MED_D  = 4'd5;
    localparam F_DONE   = 4'd6;
    localparam F_GAP_DE = 4'd7;

    reg [1:0] sensor_atual;
    reg       start_leitura;
    reg [31:0] gap_cnt;
    reg [31:0] warmup_cnt;

    wire       echo_sel;
    wire       trig_leitura;
    wire       busy;
    wire       valido;
    wire       timeout;
    wire [7:0] dist_lida;

    reg       primed_e;
    reg       primed_c;
    reg       primed_d;
    reg [2:0] rej_e;
    reg [2:0] rej_c;
    reg [2:0] rej_d;

    wire [7:0] abs_diff_e = (dist_lida >= dist_e) ? (dist_lida - dist_e) : (dist_e - dist_lida);
    wire [7:0] abs_diff_c = (dist_lida >= dist_c) ? (dist_lida - dist_c) : (dist_c - dist_lida);
    wire [7:0] abs_diff_d = (dist_lida >= dist_d) ? (dist_lida - dist_d) : (dist_d - dist_lida);

    wire accept_e = !primed_e || (abs_diff_e <= MAX_JUMP_CM) || (rej_e >= MAX_REJECTS);
    wire accept_c = !primed_c || (abs_diff_c <= MAX_JUMP_CM) || (rej_c >= MAX_REJECTS);
    wire accept_d = !primed_d || (abs_diff_d <= MAX_JUMP_CM) || (rej_d >= MAX_REJECTS);

    read_hc_sr04 #(
        .CLK_HZ(CLK_HZ),
        .TRIG_US(TRIG_US),
        .BLIND_US(BLIND_US),
        .TIMEOUT_MS(TIMEOUT_MS)
    ) leitor (
        .clk          (clk),
        .rst          (rst),
        .start        (start_leitura),
        .echo         (echo_sel),
        .trig         (trig_leitura),
        .busy         (busy),
        .distancia_cm (dist_lida),
        .valido       (valido),
        .timeout      (timeout)
    );

    assign echo_sel = (sensor_atual == 2'd0) ? echo_e :
                      (sensor_atual == 2'd1) ? echo_c : echo_d;
    assign trig_e = (sensor_atual == 2'd0) ? trig_leitura : 1'b0;
    assign trig_c = (sensor_atual == 2'd1) ? trig_leitura : 1'b0;
    assign trig_d = (sensor_atual == 2'd2) ? trig_leitura : 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            estado_fsm    <= F_IDLE;
            sensor_atual  <= 2'd0;
            start_leitura <= 1'b0;
            gap_cnt       <= 32'd0;
            warmup_cnt    <= 32'd0;
            dist_e        <= 8'd0;
            dist_c        <= 8'd0;
            dist_d        <= 8'd0;
            primed_e      <= 1'b0;
            primed_c      <= 1'b0;
            primed_d      <= 1'b0;
            rej_e         <= 3'd0;
            rej_c         <= 3'd0;
            rej_d         <= 3'd0;
            valid_e       <= 1'b0;
            valid_c       <= 1'b0;
            valid_d       <= 1'b0;
            ciclo_pronto  <= 1'b0;
            timeout_e     <= 1'b0;
        end else begin
            start_leitura <= 1'b0;
            ciclo_pronto  <= 1'b0;
            timeout_e     <= 1'b0;
            valid_e       <= 1'b0;
            valid_c       <= 1'b0;
            valid_d       <= 1'b0;

            if (warmup_cnt < WARMUP_CYCLES)
                warmup_cnt <= warmup_cnt + 32'd1;

            case (estado_fsm)
                F_IDLE: begin
                    if (iniciar && warmup_cnt >= WARMUP_CYCLES) begin
                        sensor_atual  <= 2'd0;
                        start_leitura <= 1'b1;
                        estado_fsm    <= F_MED_E;
                    end
                end

                F_MED_E, F_MED_C, F_MED_D: begin
                    if (valido || timeout) begin
                        if (valido) begin
                            if (sensor_atual == 2'd0) begin
                                if (accept_e) begin
                                    dist_e <= dist_lida;
                                    rej_e  <= 3'd0;
                                end else
                                    rej_e <= rej_e + 3'd1;
                                primed_e <= 1'b1;
                                valid_e  <= 1'b1;
                            end else if (sensor_atual == 2'd1) begin
                                if (accept_c) begin
                                    dist_c <= dist_lida;
                                    rej_c  <= 3'd0;
                                end else
                                    rej_c <= rej_c + 3'd1;
                                primed_c <= 1'b1;
                                valid_c  <= 1'b1;
                            end else begin
                                if (accept_d) begin
                                    dist_d <= dist_lida;
                                    rej_d  <= 3'd0;
                                end else
                                    rej_d <= rej_d + 3'd1;
                                primed_d <= 1'b1;
                                valid_d  <= 1'b1;
                            end
                        end else if (sensor_atual == 2'd0)
                            timeout_e <= 1'b1;

                        if (sensor_atual == 2'd2) begin
                            ciclo_pronto <= 1'b1;
                            estado_fsm   <= F_DONE;
                        end else begin
                            gap_cnt    <= 32'd0;
                            estado_fsm <= (sensor_atual == 2'd0) ? F_GAP_EC : F_GAP_CD;
                        end
                    end
                end

                F_GAP_EC, F_GAP_CD: begin
                    if (gap_cnt >= GAP_CYCLES - 1) begin
                        sensor_atual  <= sensor_atual + 2'd1;
                        start_leitura <= 1'b1;
                        estado_fsm    <= (estado_fsm == F_GAP_EC) ? F_MED_C : F_MED_D;
                    end else
                        gap_cnt <= gap_cnt + 32'd1;
                end

                F_DONE: begin
                    gap_cnt    <= 32'd0;
                    estado_fsm <= F_GAP_DE;
                end

                F_GAP_DE: begin
                    if (gap_cnt >= GAP_CYCLES - 1) begin
                        if (iniciar && warmup_cnt >= WARMUP_CYCLES) begin
                            sensor_atual  <= 2'd0;
                            start_leitura <= 1'b1;
                            estado_fsm    <= F_MED_E;
                        end else
                            estado_fsm <= F_IDLE;
                    end else
                        gap_cnt <= gap_cnt + 32'd1;
                end

                default: estado_fsm <= F_IDLE;
            endcase
        end
    end

endmodule
