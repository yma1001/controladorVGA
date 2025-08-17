module pbl (
    input wire clk, reset, button,
    input wire [3:0] color_sw,
    input wire [5:0] pos_size_sw,
    output wire [3:0] vga_r, vga_g, vga_b,
    output wire vga_hsync, vga_vsync
);
    wire pixel_clk, btn_pulse;
    wire [9:0] h_count, v_count;
    wire h_sync, v_sync, h_display, v_display, h_sync_rising_edge;
    wire [5:0] x_pos, y_pos;
    wire [1:0] size;
    wire square_on;
    wire [11:0] bg_rgb, square_rgb;

    clock_divider clk_div (
        .clk(clk),
        .reset(reset),
        .pixel_clk(pixel_clk)
    );

    debouncer db (
        .clk(clk),
        .reset(reset),
        .button(button),
        .pulse(btn_pulse)
    );

    cores_rgb bg_color (
        .A(color_sw[0]),
        .B(color_sw[1]),
        .C(color_sw[2]),
        .D(color_sw[3]),
        .saida1(bg_rgb[0]),
        .saida2(bg_rgb[1]),
        .saida3(bg_rgb[2]),
        .saida4(bg_rgb[3]),
        .saida5(bg_rgb[4]),
        .saida6(bg_rgb[5]),
        .saida7(bg_rgb[6]),
        .saida8(bg_rgb[7]),
        .saida9(bg_rgb[8]),
        .saida10(bg_rgb[9]),
        .saida11(bg_rgb[10]),
        .saida12(bg_rgb[11])
    );

    state_machine sm (
        .clk(clk),
        .reset(reset),
        .btn_pulse(btn_pulse),
        .switches(pos_size_sw),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .size(size)
    );

    h_sync_generator hsync (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .h_sync(h_sync),
        .h_display(h_display),
        .h_count(h_count)
    );

    v_sync_generator vsync (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .h_sync_rising_edge(h_sync_rising_edge),
        .v_sync(v_sync),
        .v_display(v_display),
        .v_count(v_count)
    );

    square_generator square (
        .h_count(h_count),
        .v_count(v_count),
        .h_display(h_display),
        .v_display(v_display),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .size(size),
        .bg_rgb(bg_rgb),
        .square_on(square_on),
        .square_rgb(square_rgb)
    );

    vga_controller vga (
        .h_sync(h_sync),
        .v_sync(v_sync),
        .h_display(h_display),
        .v_display(v_display),
        .bg_rgb(bg_rgb),
        .square_rgb(square_rgb),
        .square_on(square_on),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync)
    );

    assign h_sync_rising_edge = (h_count == 10'd799);
endmodule

module clock_divider (
    input wire clk, reset,
    output wire pixel_clk
);
    wire q, q_bar;
    flip_flop_d ff (
        .clk(clk),
        .reset(reset),
        .d(q_bar),
        .q(q),
        .q_bar(q_bar)
    );
    assign pixel_clk = q;
endmodule

module debouncer (
    input wire clk, reset, button,
    output wire pulse
);
    wire [1:0] state, state_bar;
    wire [1:0] state_next;
    wire s0, s1, ns0, ns1;
    assign s0 = state[0];
    assign s1 = state[1];
    not not_s0 (ns0, s0);
    not not_s1 (ns1, s1);
    wire next0_idle, next0_press; and and_n0i (next0_idle, ns1, ns0, button); and and_n0p (next0_press, ns1, s0); or or_n0 (state_next[0], next0_idle, next0_press);
    wire next1_press, next1_release; and and_n1p (next1_press, ns1, ns0, button); and and_n1r (next1_release, s1, ns0); or or_n1 (state_next[1], next1_press, next1_release);
    wire [1:0] state_d;
    wire keep_s0, update_s0; and and_ks0 (keep_s0, ~clk, state[0]); and and_us0 (update_s0, clk, state_next[0]); or or_ds0 (state_d[0], keep_s0, update_s0);
    wire keep_s1, update_s1; and and_ks1 (keep_s1, ~clk, state[1]); and and_us1 (update_s1, clk, state_next[1]); or or_ds1 (state_d[1], keep_s1, update_s1);
    flip_flop_d state_ff0 (.clk(clk), .reset(reset), .d(state_d[0]), .q(state[0]), .q_bar(state_bar[0]));
    flip_flop_d state_ff1 (.clk(clk), .reset(reset), .d(state_d[1]), .q(state[1]), .q_bar(state_bar[1]));
    wire is_pulse_state; and and_pulse_state (is_pulse_state, ns1, s0);
    assign pulse = is_pulse_state;
endmodule

module state_machine (
    input wire clk, reset, btn_pulse,
    input wire [5:0] switches,
    output wire [5:0] x_pos, y_pos,
    output wire [1:0] size
);
    wire [1:0] state, state_bar;
    wire [1:0] state_next;

    // Transição de estados (código Gray)
    wire s0, s1, ns0, ns1;
    assign s0 = state[0];
    assign s1 = state[1];
    not not_s0 (ns0, s0);
    not not_s1 (ns1, s1);
    wire next0_pos, next0_size, next1_pos, next1_size;
    and and_n0p (next0_pos, ns1, s0); // 01 -> 11
    and and_n0s (next0_size, s1, ns0); // 10 -> 00
    or or_n0 (state_next[0], next0_pos, next0_size);
    and and_n1p (next1_pos, ns1, ns0); // 00 -> 01
    and and_n1s (next1_size, s1, s0); // 11 -> 10
    or or_n1 (state_next[1], next1_pos, next1_size);

    // Multiplexadores para entrada de estado
    wire [1:0] state_d;
    wire keep_s0, update_s0; and and_ks0 (keep_s0, ~btn_pulse, state[0]); and and_us0 (update_s0, btn_pulse, state_next[0]); or or_ds0 (state_d[0], keep_s0, update_s0);
    wire keep_s1, update_s1; and and_ks1 (keep_s1, ~btn_pulse, state[1]); and and_us1 (update_s1, btn_pulse, state_next[1]); or or_ds1 (state_d[1], keep_s1, update_s1);

    // Flip-flops para estado
    flip_flop_d state_ff0 (.clk(clk), .reset(reset), .d(state_d[0]), .q(state[0]), .q_bar(state_bar[0]));
    flip_flop_d state_ff1 (.clk(clk), .reset(reset), .d(state_d[1]), .q(state[1]), .q_bar(state_bar[1]));

    // Sinais de controle
    wire is_pos_state, is_size_state;
    and and_pos_state (is_pos_state, ns1, ns0); // 00
    and and_size_state (is_size_state, ns1, s0); // 01

    // Registros de posição e tamanho
    wire [5:0] x_reg, x_reg_bar, y_reg, y_reg_bar;
    wire [1:0] size_reg, size_reg_bar;

    // Limites máximos baseados no tamanho
    wire [5:0] max_x, max_y;
    wire s00, s01, s10, s11;
    and and_s00 (s00, ~size_reg[1], ~size_reg[0]); // size = 00
    and and_s01 (s01, ~size_reg[1], size_reg[0]);  // size = 01
    and and_s10 (s10, size_reg[1], ~size_reg[0]);  // size = 10
    and and_s11 (s11, size_reg[1], size_reg[0]);   // size = 11

    // max_x: 77 (size=00), 74 (size=01), 72 (size=10), 69 (size=11)
    wire [5:0] max_x_00 = 6'd77; // 01001101
    wire [5:0] max_x_01 = 6'd74; // 01001010
    wire [5:0] max_x_10 = 6'd72; // 01001000
    wire [5:0] max_x_11 = 6'd69; // 01000101
    wire [5:0] max_x_out;
    wire [5:0] max_x_s00, max_x_s01, max_x_s10, max_x_s11;
    and and_mx0_s00 (max_x_s00[0], s00, max_x_00[0]); and and_mx0_s01 (max_x_s01[0], s01, max_x_01[0]); and and_mx0_s10 (max_x_s10[0], s10, max_x_10[0]); and and_mx0_s11 (max_x_s11[0], s11, max_x_11[0]); or or_mx0 (max_x_out[0], max_x_s00[0], max_x_s01[0], max_x_s10[0], max_x_s11[0]);
    and and_mx1_s00 (max_x_s00[1], s00, max_x_00[1]); and and_mx1_s01 (max_x_s01[1], s01, max_x_01[1]); and and_mx1_s10 (max_x_s10[1], s10, max_x_10[1]); and and_mx1_s11 (max_x_s11[1], s11, max_x_11[1]); or or_mx1 (max_x_out[1], max_x_s00[1], max_x_s01[1], max_x_s10[1], max_x_s11[1]);
    and and_mx2_s00 (max_x_s00[2], s00, max_x_00[2]); and and_mx2_s01 (max_x_s01[2], s01, max_x_01[2]); and and_mx2_s10 (max_x_s10[2], s10, max_x_10[2]); and and_mx2_s11 (max_x_s11[2], s11, max_x_11[2]); or or_mx2 (max_x_out[2], max_x_s00[2], max_x_s01[2], max_x_s10[2], max_x_s11[2]);
    and and_mx3_s00 (max_x_s00[3], s00, max_x_00[3]); and and_mx3_s01 (max_x_s01[3], s01, max_x_01[3]); and and_mx3_s10 (max_x_s10[3], s10, max_x_10[3]); and and_mx3_s11 (max_x_s11[3], s11, max_x_11[3]); or or_mx3 (max_x_out[3], max_x_s00[3], max_x_s01[3], max_x_s10[3], max_x_s11[3]);
    and and_mx4_s00 (max_x_s00[4], s00, max_x_00[4]); and and_mx4_s01 (max_x_s01[4], s01, max_x_01[4]); and and_mx4_s10 (max_x_s10[4], s10, max_x_10[4]); and and_mx4_s11 (max_x_s11[4], s11, max_x_11[4]); or or_mx4 (max_x_out[4], max_x_s00[4], max_x_s01[4], max_x_s10[4], max_x_s11[4]);
    and and_mx5_s00 (max_x_s00[5], s00, max_x_00[5]); and and_mx5_s01 (max_x_s01[5], s01, max_x_01[5]); and and_mx5_s10 (max_x_s10[5], s10, max_x_10[5]); and and_mx5_s11 (max_x_s11[5], s11, max_x_11[5]); or or_mx5 (max_x_out[5], max_x_s00[5], max_x_s01[5], max_x_s10[5], max_x_s11[5]);
    assign max_x = max_x_out;

    // max_y: 57 (size=00), 54 (size=01), 52 (size=10), 49 (size=11)
    wire [5:0] max_y_00 = 6'd57; // 00111001
    wire [5:0] max_y_01 = 6'd54; // 00110110
    wire [5:0] max_y_10 = 6'd52; // 00110100
    wire [5:0] max_y_11 = 6'd49; // 00110001
    wire [5:0] max_y_out;
    wire [5:0] max_y_s00, max_y_s01, max_y_s10, max_y_s11;
    and and_my0_s00 (max_y_s00[0], s00, max_y_00[0]); and and_my0_s01 (max_y_s01[0], s01, max_y_01[0]); and and_my0_s10 (max_y_s10[0], s10, max_y_10[0]); and and_my0_s11 (max_y_s11[0], s11, max_y_11[0]); or or_my0 (max_y_out[0], max_y_s00[0], max_y_s01[0], max_y_s10[0], max_y_s11[0]);
    and and_my1_s00 (max_y_s00[1], s00, max_y_00[1]); and and_my1_s01 (max_y_s01[1], s01, max_y_01[1]); and and_my1_s10 (max_y_s10[1], s10, max_y_10[1]); and and_my1_s11 (max_y_s11[1], s11, max_y_11[1]); or or_my1 (max_y_out[1], max_y_s00[1], max_y_s01[1], max_y_s10[1], max_y_s11[1]);
    and and_my2_s00 (max_y_s00[2], s00, max_y_00[2]); and and_my2_s01 (max_y_s01[2], s01, max_y_01[2]); and and_my2_s10 (max_y_s10[2], s10, max_y_10[2]); and and_my2_s11 (max_y_s11[2], s11, max_y_11[2]); or or_my2 (max_y_out[2], max_y_s00[2], max_y_s01[2], max_y_s10[2], max_y_s11[2]);
    and and_my3_s00 (max_y_s00[3], s00, max_y_00[3]); and and_my3_s01 (max_y_s01[3], s01, max_y_01[3]); and and_my3_s10 (max_y_s10[3], s10, max_y_10[3]); and and_my3_s11 (max_y_s11[3], s11, max_y_11[3]); or or_my3 (max_y_out[3], max_y_s00[3], max_y_s01[3], max_y_s10[3], max_y_s11[3]);
    and and_my4_s00 (max_y_s00[4], s00, max_y_00[4]); and and_my4_s01 (max_y_s01[4], s01, max_y_01[4]); and and_my4_s10 (max_y_s10[4], s10, max_y_10[4]); and and_my4_s11 (max_y_s11[4], s11, max_y_11[4]); or or_my4 (max_y_out[4], max_y_s00[4], max_y_s01[4], max_y_s10[4], max_y_s11[4]);
    and and_my5_s00 (max_y_s00[5], s00, max_y_00[5]); and and_my5_s01 (max_y_s01[5], s01, max_y_01[5]); and and_my5_s10 (max_y_s10[5], s10, max_y_10[5]); and and_my5_s11 (max_y_s11[5], s11, max_y_11[5]); or or_my5 (max_y_out[5], max_y_s00[5], max_y_s01[5], max_y_s10[5], max_y_s11[5]);
    assign max_y = max_y_out;

    // Comparador para x_pos: min(switches[5:3], max_x)
    wire [2:0] x_input = switches[5:3];
    wire x_lt_max;
    wire [2:0] x_diff;
    wire x_borrow;
    subtractor_10bit sub_x (.a({3'b0, x_input}), .b({3'b0, max_x[2:0]}), .diff(x_diff), .borrow(x_borrow));
    not not_x_lt (x_lt_max, x_borrow); // x_input < max_x
    wire [2:0] x_clamped;
    wire [2:0] x_in, x_max;
    and and_x0_in (x_in[0], x_lt_max, x_input[0]); and and_x0_max (x_max[0], ~x_lt_max, max_x[0]); or or_x0 (x_clamped[0], x_in[0], x_max[0]);
    and and_x1_in (x_in[1], x_lt_max, x_input[1]); and and_x1_max (x_max[1], ~x_lt_max, max_x[1]); or or_x1 (x_clamped[1], x_in[1], x_max[1]);
    and and_x2_in (x_in[2], x_lt_max, x_input[2]); and and_x2_max (x_max[2], ~x_lt_max, max_x[2]); or or_x2 (x_clamped[2], x_in[2], x_max[2]);

    // Comparador para y_pos: min(switches[2:0], max_y)
    wire [2:0] y_input = switches[2:0];
    wire y_lt_max;
    wire [2:0] y_diff;
    wire y_borrow;
    subtractor_10bit sub_y (.a({3'b0, y_input}), .b({3'b0, max_y[2:0]}), .diff(y_diff), .borrow(y_borrow));
    not not_y_lt (y_lt_max, y_borrow); // y_input < max_y
    wire [2:0] y_clamped;
    wire [2:0] y_in, y_max;
    and and_y0_in (y_in[0], y_lt_max, y_input[0]); and and_y0_max (y_max[0], ~y_lt_max, max_y[0]); or or_y0 (y_clamped[0], y_in[0], y_max[0]);
    and and_y1_in (y_in[1], y_lt_max, y_input[1]); and and_y1_max (y_max[1], ~y_lt_max, max_y[1]); or or_y1 (y_clamped[1], y_in[1], y_max[1]);
    and and_y2_in (y_in[2], y_lt_max, y_input[2]); and and_y2_max (y_max[2], ~y_lt_max, max_y[2]); or or_y2 (y_clamped[2], y_in[2], y_max[2]);

    // Multiplexadores para entrada de x_reg
    wire [5:0] x_d;
    wire keep_x0, update_x0; and and_kx0 (keep_x0, ~btn_pulse, x_reg[0]); and and_ux0 (update_x0, btn_pulse, is_pos_state, x_clamped[0]); or or_dx0 (x_d[0], keep_x0, update_x0);
    wire keep_x1, update_x1; and and_kx1 (keep_x1, ~btn_pulse, x_reg[1]); and and_ux1 (update_x1, btn_pulse, is_pos_state, x_clamped[1]); or or_dx1 (x_d[1], keep_x1, update_x1);
    wire keep_x2, update_x2; and and_kx2 (keep_x2, ~btn_pulse, x_reg[2]); and and_ux2 (update_x2, btn_pulse, is_pos_state, x_clamped[2]); or or_dx2 (x_d[2], keep_x2, update_x2);
    assign x_d[5:3] = 3'b0; // Bits 3 a 5 sempre zero

    // Multiplexadores para entrada de y_reg
    wire [5:0] y_d;
    wire keep_y0, update_y0; and and_ky0 (keep_y0, ~btn_pulse, y_reg[0]); and and_uy0 (update_y0, btn_pulse, is_pos_state, y_clamped[0]); or or_dy0 (y_d[0], keep_y0, update_y0);
    wire keep_y1, update_y1; and and_ky1 (keep_y1, ~btn_pulse, y_reg[1]); and and_uy1 (update_y1, btn_pulse, is_pos_state, y_clamped[1]); or or_dy1 (y_d[1], keep_y1, update_y1);
    wire keep_y2, update_y2; and and_ky2 (keep_y2, ~btn_pulse, y_reg[2]); and and_uy2 (update_y2, btn_pulse, is_pos_state, y_clamped[2]); or or_dy2 (y_d[2], keep_y2, update_y2);
    assign y_d[5:3] = 3'b0; // Bits 3 a 5 sempre zero

    // Multiplexadores para entrada de size_reg
    wire [1:0] size_d;
    wire keep_sz0, update_sz0; and and_ksz0 (keep_sz0, ~btn_pulse, size_reg[0]); and and_usz0 (update_sz0, btn_pulse, is_size_state, switches[0]); or or_dsz0 (size_d[0], keep_sz0, update_sz0);
    wire keep_sz1, update_sz1; and and_ksz1 (keep_sz1, ~btn_pulse, size_reg[1]); and and_usz1 (update_sz1, btn_pulse, is_size_state, switches[1]); or or_dsz1 (size_d[1], keep_sz1, update_sz1);

    // Flip-flops para x_reg, y_reg, size_reg
    flip_flop_d x_ff0 (.clk(clk), .reset(reset), .d(x_d[0]), .q(x_reg[0]), .q_bar(x_reg_bar[0]));
    flip_flop_d x_ff1 (.clk(clk), .reset(reset), .d(x_d[1]), .q(x_reg[1]), .q_bar(x_reg_bar[1]));
    flip_flop_d x_ff2 (.clk(clk), .reset(reset), .d(x_d[2]), .q(x_reg[2]), .q_bar(x_reg_bar[2]));
    flip_flop_d x_ff3 (.clk(clk), .reset(reset), .d(x_d[3]), .q(x_reg[3]), .q_bar(x_reg_bar[3]));
    flip_flop_d x_ff4 (.clk(clk), .reset(reset), .d(x_d[4]), .q(x_reg[4]), .q_bar(x_reg_bar[4]));
    flip_flop_d x_ff5 (.clk(clk), .reset(reset), .d(x_d[5]), .q(x_reg[5]), .q_bar(x_reg_bar[5]));
    flip_flop_d y_ff0 (.clk(clk), .reset(reset), .d(y_d[0]), .q(y_reg[0]), .q_bar(y_reg_bar[0]));
    flip_flop_d y_ff1 (.clk(clk), .reset(reset), .d(y_d[1]), .q(y_reg[1]), .q_bar(y_reg_bar[1]));
    flip_flop_d y_ff2 (.clk(clk), .reset(reset), .d(y_d[2]), .q(y_reg[2]), .q_bar(y_reg_bar[2]));
    flip_flop_d y_ff3 (.clk(clk), .reset(reset), .d(y_d[3]), .q(y_reg[3]), .q_bar(y_reg_bar[3]));
    flip_flop_d y_ff4 (.clk(clk), .reset(reset), .d(y_d[4]), .q(y_reg[4]), .q_bar(y_reg_bar[4]));
    flip_flop_d y_ff5 (.clk(clk), .reset(reset), .d(y_d[5]), .q(y_reg[5]), .q_bar(y_reg_bar[5]));
    flip_flop_d size_ff0 (.clk(clk), .reset(reset), .d(size_d[0]), .q(size_reg[0]), .q_bar(size_reg_bar[0]));
    flip_flop_d size_ff1 (.clk(clk), .reset(reset), .d(size_d[1]), .q(size_reg[1]), .q_bar(size_reg_bar[1]));

    assign x_pos = x_reg;
    assign y_pos = y_reg;
    assign size = size_reg;
endmodule

module h_sync_generator (
    input wire pixel_clk, reset,
    output wire h_sync, h_display,
    output wire [9:0] h_count
);
    wire [9:0] count;
    counter_10bit counter (
        .clk(pixel_clk),
        .reset(reset),
        .count(count)
    );
    assign h_count = count;

    assign h_display = (count < 10'd640);
    wire sync_pulse_active = (count >= 10'd656) && (count < 10'd752);
    not not_hsync (h_sync, sync_pulse_active);
endmodule

module counter_10bit (
    input wire clk, reset,
    output wire [9:0] count
);
    wire [9:0] count_reg, count_bar;
    wire [9:0] count_next;
    wire cout;

    adder_10bit inc (.a(count_reg), .b(10'd1), .sum(count_next), .cout(cout));
    wire eq_799 = (count_reg == 10'd799);

    wire [9:0] count_d;
    wire keep_c0, clear_c0; and and_kc0 (keep_c0, ~eq_799, count_next[0]); and and_cc0 (clear_c0, eq_799, 1'b0); or or_dc0 (count_d[0], keep_c0, clear_c0);
    wire keep_c1, clear_c1; and and_kc1 (keep_c1, ~eq_799, count_next[1]); and and_cc1 (clear_c1, eq_799, 1'b0); or or_dc1 (count_d[1], keep_c1, clear_c1);
    wire keep_c2, clear_c2; and and_kc2 (keep_c2, ~eq_799, count_next[2]); and and_cc2 (clear_c2, eq_799, 1'b0); or or_dc2 (count_d[2], keep_c2, clear_c2);
    wire keep_c3, clear_c3; and and_kc3 (keep_c3, ~eq_799, count_next[3]); and and_cc3 (clear_c3, eq_799, 1'b0); or or_dc3 (count_d[3], keep_c3, clear_c3);
    wire keep_c4, clear_c4; and and_kc4 (keep_c4, ~eq_799, count_next[4]); and and_cc4 (clear_c4, eq_799, 1'b0); or or_dc4 (count_d[4], keep_c4, clear_c4);
    wire keep_c5, clear_c5; and and_kc5 (keep_c5, ~eq_799, count_next[5]); and and_cc5 (clear_c5, eq_799, 1'b0); or or_dc5 (count_d[5], keep_c5, clear_c5);
    wire keep_c6, clear_c6; and and_kc6 (keep_c6, ~eq_799, count_next[6]); and and_cc6 (clear_c6, eq_799, 1'b0); or or_dc6 (count_d[6], keep_c6, clear_c6);
    wire keep_c7, clear_c7; and and_kc7 (keep_c7, ~eq_799, count_next[7]); and and_cc7 (clear_c7, eq_799, 1'b0); or or_dc7 (count_d[7], keep_c7, clear_c7);
    wire keep_c8, clear_c8; and and_kc8 (keep_c8, ~eq_799, count_next[8]); and and_cc8 (clear_c8, eq_799, 1'b0); or or_dc8 (count_d[8], keep_c8, clear_c8);
    wire keep_c9, clear_c9; and and_kc9 (keep_c9, ~eq_799, count_next[9]); and and_cc9 (clear_c9, eq_799, 1'b0); or or_dc9 (count_d[9], keep_c9, clear_c9);

    flip_flop_d ff_c0 (.clk(clk), .reset(reset), .d(count_d[0]), .q(count_reg[0]), .q_bar(count_bar[0]));
    flip_flop_d ff_c1 (.clk(clk), .reset(reset), .d(count_d[1]), .q(count_reg[1]), .q_bar(count_bar[1]));
    flip_flop_d ff_c2 (.clk(clk), .reset(reset), .d(count_d[2]), .q(count_reg[2]), .q_bar(count_bar[2]));
    flip_flop_d ff_c3 (.clk(clk), .reset(reset), .d(count_d[3]), .q(count_reg[3]), .q_bar(count_bar[3]));
    flip_flop_d ff_c4 (.clk(clk), .reset(reset), .d(count_d[4]), .q(count_reg[4]), .q_bar(count_bar[4]));
    flip_flop_d ff_c5 (.clk(clk), .reset(reset), .d(count_d[5]), .q(count_reg[5]), .q_bar(count_bar[5]));
    flip_flop_d ff_c6 (.clk(clk), .reset(reset), .d(count_d[6]), .q(count_reg[6]), .q_bar(count_bar[6]));
    flip_flop_d ff_c7 (.clk(clk), .reset(reset), .d(count_d[7]), .q(count_reg[7]), .q_bar(count_bar[7]));
    flip_flop_d ff_c8 (.clk(clk), .reset(reset), .d(count_d[8]), .q(count_reg[8]), .q_bar(count_bar[8]));
    flip_flop_d ff_c9 (.clk(clk), .reset(reset), .d(count_d[9]), .q(count_reg[9]), .q_bar(count_bar[9]));

    assign count = count_reg;
endmodule

module v_sync_generator (
    input wire pixel_clk, reset, h_sync_rising_edge,
    output wire v_sync, v_display,
    output wire [9:0] v_count
);
    wire [9:0] count;
    vsync_counter counter (
        .clk(pixel_clk),
        .reset(reset),
        .enable_count(h_sync_rising_edge),
        .count(count)
    );
    assign v_count = count;

    assign v_display = (count < 10'd480);
    wire sync_pulse_active = (count >= 10'd490) && (count < 10'd492);
    not not_vsync (v_sync, sync_pulse_active);
endmodule

module vsync_counter (
    input wire clk, reset, enable_count,
    output wire [9:0] count
);
    wire [9:0] count_reg, count_bar;
    wire [9:0] count_next;
    wire cout;

    adder_10bit inc (.a(count_reg), .b(10'd1), .sum(count_next), .cout(cout));
    wire eq_524 = (count_reg == 10'd524);

    wire [9:0] count_d;
    wire keep_v0, clear_v0, enable_v0; and and_ev0 (enable_v0, enable_count, ~eq_524); and and_kv0 (keep_v0, enable_v0, count_next[0]); and and_cv0 (clear_v0, eq_524, 1'b0); or or_dv0 (count_d[0], keep_v0, clear_v0);
    wire keep_v1, clear_v1, enable_v1; and and_ev1 (enable_v1, enable_count, ~eq_524); and and_kv1 (keep_v1, enable_v1, count_next[1]); and and_cv1 (clear_v1, eq_524, 1'b0); or or_dv1 (count_d[1], keep_v1, clear_v1);
    wire keep_v2, clear_v2, enable_v2; and and_ev2 (enable_v2, enable_count, ~eq_524); and and_kv2 (keep_v2, enable_v2, count_next[2]); and and_cv2 (clear_v2, eq_524, 1'b0); or or_dv2 (count_d[2], keep_v2, clear_v2);
    wire keep_v3, clear_v3, enable_v3; and and_ev3 (enable_v3, enable_count, ~eq_524); and and_kv3 (keep_v3, enable_v3, count_next[3]); and and_cv3 (clear_v3, eq_524, 1'b0); or or_dv3 (count_d[3], keep_v3, clear_v3);
    wire keep_v4, clear_v4, enable_v4; and and_ev4 (enable_v4, enable_count, ~eq_524); and and_kv4 (keep_v4, enable_v4, count_next[4]); and and_cv4 (clear_v4, eq_524, 1'b0); or or_dv4 (count_d[4], keep_v4, clear_v4);
    wire keep_v5, clear_v5, enable_v5; and and_ev5 (enable_v5, enable_count, ~eq_524); and and_kv5 (keep_v5, enable_v5, count_next[5]); and and_cv5 (clear_v5, eq_524, 1'b0); or or_dv5 (count_d[5], keep_v5, clear_v5);
    wire keep_v6, clear_v6, enable_v6; and and_ev6 (enable_v6, enable_count, ~eq_524); and and_kv6 (keep_v6, enable_v6, count_next[6]); and and_cv6 (clear_v6, eq_524, 1'b0); or or_dv6 (count_d[6], keep_v6, clear_v6);
    wire keep_v7, clear_v7, enable_v7; and and_ev7 (enable_v7, enable_count, ~eq_524); and and_kv7 (keep_v7, enable_v7, count_next[7]); and and_cv7 (clear_v7, eq_524, 1'b0); or or_dv7 (count_d[7], keep_v7, clear_v7);
    wire keep_v8, clear_v8, enable_v8; and and_ev8 (enable_v8, enable_count, ~eq_524); and and_kv8 (keep_v8, enable_v8, count_next[8]); and and_cv8 (clear_v8, eq_524, 1'b0); or or_dv8 (count_d[8], keep_v8, clear_v8);
    wire keep_v9, clear_v9, enable_v9; and and_ev9 (enable_v9, enable_count, ~eq_524); and and_kv9 (keep_v9, enable_v9, count_next[9]); and and_cv9 (clear_v9, eq_524, 1'b0); or or_dv9 (count_d[9], keep_v9, clear_v9);

    flip_flop_d ff_v0 (.clk(clk), .reset(reset), .d(count_d[0]), .q(count_reg[0]), .q_bar(count_bar[0]));
    flip_flop_d ff_v1 (.clk(clk), .reset(reset), .d(count_d[1]), .q(count_reg[1]), .q_bar(count_bar[1]));
    flip_flop_d ff_v2 (.clk(clk), .reset(reset), .d(count_d[2]), .q(count_reg[2]), .q_bar(count_bar[2]));
    flip_flop_d ff_v3 (.clk(clk), .reset(reset), .d(count_d[3]), .q(count_reg[3]), .q_bar(count_bar[3]));
    flip_flop_d ff_v4 (.clk(clk), .reset(reset), .d(count_d[4]), .q(count_reg[4]), .q_bar(count_bar[4]));
    flip_flop_d ff_v5 (.clk(clk), .reset(reset), .d(count_d[5]), .q(count_reg[5]), .q_bar(count_bar[5]));
    flip_flop_d ff_v6 (.clk(clk), .reset(reset), .d(count_d[6]), .q(count_reg[6]), .q_bar(count_bar[6]));
    flip_flop_d ff_v7 (.clk(clk), .reset(reset), .d(count_d[7]), .q(count_reg[7]), .q_bar(count_bar[7]));
    flip_flop_d ff_v8 (.clk(clk), .reset(reset), .d(count_d[8]), .q(count_reg[8]), .q_bar(count_bar[8]));
    flip_flop_d ff_v9 (.clk(clk), .reset(reset), .d(count_d[9]), .q(count_reg[9]), .q_bar(count_bar[9]));

    assign count = count_reg;
endmodule

module square_generator (
    input wire [9:0] h_count, v_count,
    input wire h_display, v_display,
    input wire [5:0] x_pos, y_pos,
    input wire [1:0] size,
    input wire [11:0] bg_rgb,
    output wire square_on,
    output wire [11:0] square_rgb
);
    wire [9:0] x_scaled = {x_pos, 3'b0};
    wire [9:0] y_scaled = {y_pos, 3'b0};

    wire [9:0] size_scaled;
    wire s0, s1, ns0, ns1;
    assign s0 = size[0];
    assign s1 = size[1];
    not not_s0 (ns0, s0);
    not not_s1 (ns1, s1);
    wire [9:0] sz_20 = 10'd20;
    wire [9:0] sz_40 = 10'd40;
    wire [9:0] sz_60 = 10'd60;
    wire [9:0] sz_80 = 10'd80;
    wire [9:0] size_out;
    wire s20_0, s40_0, s60_0, s80_0; and and_s20_0 (s20_0, ns1, ns0, sz_20[0]); and and_s40_0 (s40_0, ns1, s0, sz_40[0]); and and_s60_0 (s60_0, s1, ns0, sz_60[0]); and and_s80_0 (s80_0, s1, s0, sz_80[0]); or or_sz0 (size_out[0], s20_0, s40_0, s60_0, s80_0);
    wire s20_1, s40_1, s60_1, s80_1; and and_s20_1 (s20_1, ns1, ns0, sz_20[1]); and and_s40_1 (s40_1, ns1, s0, sz_40[1]); and and_s60_1 (s60_1, s1, ns0, sz_60[1]); and and_s80_1 (s80_1, s1, s0, sz_80[1]); or or_sz1 (size_out[1], s20_1, s40_1, s60_1, s80_1);
    wire s20_2, s40_2, s60_2, s80_2; and and_s20_2 (s20_2, ns1, ns0, sz_20[2]); and and_s40_2 (s40_2, ns1, s0, sz_40[2]); and and_s60_2 (s60_2, s1, ns0, sz_60[2]); and and_s80_2 (s80_2, s1, s0, sz_80[2]); or or_sz2 (size_out[2], s20_2, s40_2, s60_2, s80_2);
    wire s20_3, s40_3, s60_3, s80_3; and and_s20_3 (s20_3, ns1, ns0, sz_20[3]); and and_s40_3 (s40_3, ns1, s0, sz_40[3]); and and_s60_3 (s60_3, s1, ns0, sz_60[3]); and and_s80_3 (s80_3, s1, s0, sz_80[3]); or or_sz3 (size_out[3], s20_3, s40_3, s60_3, s80_3);
    wire s20_4, s40_4, s60_4, s80_4; and and_s20_4 (s20_4, ns1, ns0, sz_20[4]); and and_s40_4 (s40_4, ns1, s0, sz_40[4]); and and_s60_4 (s60_4, s1, ns0, sz_60[4]); and and_s80_4 (s80_4, s1, s0, sz_80[4]); or or_sz4 (size_out[4], s20_4, s40_4, s60_4, s80_4);
    wire s20_5, s40_5, s60_5, s80_5; and and_s20_5 (s20_5, ns1, ns0, sz_20[5]); and and_s40_5 (s40_5, ns1, s0, sz_40[5]); and and_s60_5 (s60_5, s1, ns0, sz_60[5]); and and_s80_5 (s80_5, s1, s0, sz_80[5]); or or_sz5 (size_out[5], s20_5, s40_5, s60_5, s80_5);
    wire s20_6, s40_6, s60_6, s80_6; and and_s20_6 (s20_6, ns1, ns0, sz_20[6]); and and_s40_6 (s40_6, ns1, s0, sz_40[6]); and and_s60_6 (s60_6, s1, ns0, sz_60[6]); and and_s80_6 (s80_6, s1, s0, sz_80[6]); or or_sz6 (size_out[6], s20_6, s40_6, s60_6, s80_6);
    wire s20_7, s40_7, s60_7, s80_7; and and_s20_7 (s20_7, ns1, ns0, sz_20[7]); and and_s40_7 (s40_7, ns1, s0, sz_40[7]); and and_s60_7 (s60_7, s1, ns0, sz_60[7]); and and_s80_7 (s80_7, s1, s0, sz_80[7]); or or_sz7 (size_out[7], s20_7, s40_7, s60_7, s80_7);
    wire s20_8, s40_8, s60_8, s80_8; and and_s20_8 (s20_8, ns1, ns0, sz_20[8]); and and_s40_8 (s40_8, ns1, s0, sz_40[8]); and and_s60_8 (s60_8, s1, ns0, sz_60[8]); and and_s80_8 (s80_8, s1, s0, sz_80[8]); or or_sz8 (size_out[8], s20_8, s40_8, s60_8, s80_8);
    wire s20_9, s40_9, s60_9, s80_9; and and_s20_9 (s20_9, ns1, ns0, sz_20[9]); and and_s40_9 (s40_9, ns1, s0, sz_40[9]); and and_s60_9 (s60_9, s1, ns0, sz_60[9]); and and_s80_9 (s80_9, s1, s0, sz_80[9]); or or_sz9 (size_out[9], s20_9, s40_9, s60_9, s80_9);
    assign size_scaled = size_out;

    wire [9:0] x_end, y_end;
    wire cout_x, cout_y;
    adder_10bit add_x (.a(x_scaled), .b(size_scaled), .sum(x_end), .cout(cout_x));
    adder_10bit add_y (.a(y_scaled), .b(size_scaled), .sum(y_end), .cout(cout_y));

    wire [9:0] diff_hx, diff_xend, diff_vy, diff_yend;
    wire borrow_hx, borrow_xend, borrow_vy, borrow_yend;
    subtractor_10bit sub_hx (.a(h_count), .b(x_scaled), .diff(diff_hx), .borrow(borrow_hx));
    subtractor_10bit sub_xend (.a(x_end), .b(h_count), .diff(diff_xend), .borrow(borrow_xend));
    subtractor_10bit sub_vy (.a(v_count), .b(y_scaled), .diff(diff_vy), .borrow(borrow_vy));
    subtractor_10bit sub_yend (.a(y_end), .b(v_count), .diff(diff_yend), .borrow(borrow_yend));

    wire ge_x, lt_xend, ge_y, lt_yend;
    not not_gex (ge_x, borrow_hx);
    not not_ltxend (lt_xend, borrow_xend);
    not not_gey (ge_y, borrow_vy);
    not not_ltyend (lt_yend, borrow_yend);

    wire h_ok, v_ok, disp_ok;
    and and_hok (h_ok, ge_x, lt_xend);
    and and_vok (v_ok, ge_y, lt_yend);
    and and_dispok (disp_ok, h_display, v_display);
    and and_squareon (square_on, h_ok, v_ok, disp_ok);

    // Inverter bg_rgb para square_rgb
    not not_rgb0 (square_rgb[0], bg_rgb[0]);
    not not_rgb1 (square_rgb[1], bg_rgb[1]);
    not not_rgb2 (square_rgb[2], bg_rgb[2]);
    not not_rgb3 (square_rgb[3], bg_rgb[3]);
    not not_rgb4 (square_rgb[4], bg_rgb[4]);
    not not_rgb5 (square_rgb[5], bg_rgb[5]);
    not not_rgb6 (square_rgb[6], bg_rgb[6]);
    not not_rgb7 (square_rgb[7], bg_rgb[7]);
    not not_rgb8 (square_rgb[8], bg_rgb[8]);
    not not_rgb9 (square_rgb[9], bg_rgb[9]);
    not not_rgb10 (square_rgb[10], bg_rgb[10]);
    not not_rgb11 (square_rgb[11], bg_rgb[11]);
endmodule

module adder_10bit (
    input wire [9:0] a, b,
    output wire [9:0] sum,
    output wire cout
);
    wire [9:0] carry;
    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(1'b0), .sum(sum[0]), .cout(carry[0]));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(carry[0]), .sum(sum[1]), .cout(carry[1]));
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(carry[1]), .sum(sum[2]), .cout(carry[2]));
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(carry[2]), .sum(sum[3]), .cout(carry[3]));
    full_adder fa4 (.a(a[4]), .b(b[4]), .cin(carry[3]), .sum(sum[4]), .cout(carry[4]));
    full_adder fa5 (.a(a[5]), .b(b[5]), .cin(carry[4]), .sum(sum[5]), .cout(carry[5]));
    full_adder fa6 (.a(a[6]), .b(b[6]), .cin(carry[5]), .sum(sum[6]), .cout(carry[6]));
    full_adder fa7 (.a(a[7]), .b(b[7]), .cin(carry[6]), .sum(sum[7]), .cout(carry[7]));
    full_adder fa8 (.a(a[8]), .b(b[8]), .cin(carry[7]), .sum(sum[8]), .cout(carry[8]));
    full_adder fa9 (.a(a[9]), .b(b[9]), .cin(carry[8]), .sum(sum[9]), .cout(cout));
endmodule

module subtractor_10bit (
    input wire [9:0] a, b,
    output wire [9:0] diff,
    output wire borrow
);
    wire [9:0] b_comp, sum_temp;
    wire cout;

    wire [9:0] b_not;
    not not_b0 (b_not[0], b[0]);
    not not_b1 (b_not[1], b[1]);
    not not_b2 (b_not[2], b[2]);
    not not_b3 (b_not[3], b[3]);
    not not_b4 (b_not[4], b[4]);
    not not_b5 (b_not[5], b[5]);
    not not_b6 (b_not[6], b[6]);
    not not_b7 (b_not[7], b[7]);
    not not_b8 (b_not[8], b[8]);
    not not_b9 (b_not[9], b[9]);
    adder_10bit add_one (.a(b_not), .b(10'd1), .sum(b_comp), .cout());

    adder_10bit add_diff (.a(a), .b(b_comp), .sum(sum_temp), .cout(cout));
    assign diff = sum_temp;
    not not_borrow (borrow, cout);
endmodule

module vga_controller (
    input wire h_sync, v_sync, h_display, v_display,
    input wire [11:0] bg_rgb, square_rgb,
    input wire square_on,
    output wire [3:0] vga_r, vga_g, vga_b,
    output wire vga_hsync, vga_vsync
);
    assign vga_hsync = h_sync;
    assign vga_vsync = v_sync;

    wire display_active;
    and and_disp_active (display_active, h_display, v_display);

    wire n_square_on, n_display_active;
    not not_sq_on (n_square_on, square_on);
    not not_disp_active (n_display_active, display_active);

    wire [11:0] rgb_out;
    wire sq_sel0, bg_sel0; and and_sq0 (sq_sel0, square_on, display_active, square_rgb[0]); and and_bg0 (bg_sel0, n_square_on, display_active, bg_rgb[0]); or or_rgb0 (rgb_out[0], sq_sel0, bg_sel0);
    wire sq_sel1, bg_sel1; and and_sq1 (sq_sel1, square_on, display_active, square_rgb[1]); and and_bg1 (bg_sel1, n_square_on, display_active, bg_rgb[1]); or or_rgb1 (rgb_out[1], sq_sel1, bg_sel1);
    wire sq_sel2, bg_sel2; and and_sq2 (sq_sel2, square_on, display_active, square_rgb[2]); and and_bg2 (bg_sel2, n_square_on, display_active, bg_rgb[2]); or or_rgb2 (rgb_out[2], sq_sel2, bg_sel2);
    wire sq_sel3, bg_sel3; and and_sq3 (sq_sel3, square_on, display_active, square_rgb[3]); and and_bg3 (bg_sel3, n_square_on, display_active, bg_rgb[3]); or or_rgb3 (rgb_out[3], sq_sel3, bg_sel3);
    wire sq_sel4, bg_sel4; and and_sq4 (sq_sel4, square_on, display_active, square_rgb[4]); and and_bg4 (bg_sel4, n_square_on, display_active, bg_rgb[4]); or or_rgb4 (rgb_out[4], sq_sel4, bg_sel4);
    wire sq_sel5, bg_sel5; and and_sq5 (sq_sel5, square_on, display_active, square_rgb[5]); and and_bg5 (bg_sel5, n_square_on, display_active, bg_rgb[5]); or or_rgb5 (rgb_out[5], sq_sel5, bg_sel5);
    wire sq_sel6, bg_sel6; and and_sq6 (sq_sel6, square_on, display_active, square_rgb[6]); and and_bg6 (bg_sel6, n_square_on, display_active, bg_rgb[6]); or or_rgb6 (rgb_out[6], sq_sel6, bg_sel6);
    wire sq_sel7, bg_sel7; and and_sq7 (sq_sel7, square_on, display_active, square_rgb[7]); and and_bg7 (bg_sel7, n_square_on, display_active, bg_rgb[7]); or or_rgb7 (rgb_out[7], sq_sel7, bg_sel7);
    wire sq_sel8, bg_sel8; and and_sq8 (sq_sel8, square_on, display_active, square_rgb[8]); and and_bg8 (bg_sel8, n_square_on, display_active, bg_rgb[8]); or or_rgb8 (rgb_out[8], sq_sel8, bg_sel8);
    wire sq_sel9, bg_sel9; and and_sq9 (sq_sel9, square_on, display_active, square_rgb[9]); and and_bg9 (bg_sel9, n_square_on, display_active, bg_rgb[9]); or or_rgb9 (rgb_out[9], sq_sel9, bg_sel9);
    wire sq_sel10, bg_sel10; and and_sq10 (sq_sel10, square_on, display_active, square_rgb[10]); and and_bg10 (bg_sel10, n_square_on, display_active, bg_rgb[10]); or or_rgb10 (rgb_out[10], sq_sel10, bg_sel10);
    wire sq_sel11, bg_sel11; and and_sq11 (sq_sel11, square_on, display_active, square_rgb[11]); and and_bg11 (bg_sel11, n_square_on, display_active, bg_rgb[11]); or or_rgb11 (rgb_out[11], sq_sel11, bg_sel11);

    assign vga_r = rgb_out[11:8];
    assign vga_g = rgb_out[7:4];
    assign vga_b = rgb_out[3:0];
endmodule

module cores_rgb (
    input wire A, B, C, D,
    output wire saida1, saida2, saida3, saida4,
    output wire saida5, saida6, saida7, saida8,
    output wire saida9, saida10, saida11, saida12
);
    wire [3:0] R, G, B_color;

    red0 vermelho0_inst (.RED0(R[0]), .A(A), .B(B), .C(C), .D(D));
    red1 vermelho1_inst (.RED1(R[1]), .A(A), .B(B), .C(C), .D(D));
    red2 vermelho2_inst (.RED2(R[2]), .A(A), .B(B), .C(C), .D(D));
    red3 vermelho3_inst (.RED3(R[3]), .A(A), .B(B), .C(C), .D(D));

    green0 verde0_inst (.GREEN0(G[0]), .A(A), .B(B), .C(C), .D(D));
    green1 verde1_inst (.GREEN1(G[1]), .A(A), .B(B), .C(C), .D(D));
    green2 verde2_inst (.GREEN2(G[2]), .A(A), .B(B), .C(C), .D(D));
    green3 verde3_inst (.GREEN3(G[3]), .A(A), .B(B), .C(C), .D(D));

    blue0 azul0_inst (.BLUE0(B_color[0]), .A(A), .B(B), .C(C), .D(D));
    blue1 azul1_inst (.BLUE1(B_color[1]), .A(A), .B(B), .C(C), .D(D));
    blue2 azul2_inst (.BLUE2(B_color[2]), .A(A), .B(B), .C(C), .D(D));
    blue3 azul3_inst (.BLUE3(B_color[3]), .A(A), .B(B), .C(C), .D(D));

    assign saida12 = R[3];
    assign saida11 = R[2];
    assign saida10 = R[1];
    assign saida9 = R[0];
    assign saida8 = G[3];
    assign saida7 = G[2];
    assign saida6 = G[1];
    assign saida5 = G[0];
    assign saida4 = B_color[3];
    assign saida3 = B_color[2];
    assign saida2 = B_color[1];
    assign saida1 = B_color[0];
endmodule

module red0 (
    output RED0,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    wire and1_out, and2_out, or1_out, and3_out, and4_out;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    and AND1(and1_out, nB, nD);
    and AND2(and2_out, B, C);
    or OR1(or1_out, and1_out, and2_out);
    and AND3(and3_out, nA, or1_out);
    and AND4(and4_out, A, nB, C, D);

    or OR_FINAL(RED0, and3_out, and4_out);
endmodule

module red1 (
    output RED1,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    wire and1_out, and2_out, or1_out, and3_out, and4_out;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    and AND1(and1_out, nB, nD);
    and AND2(and2_out, B, C);
    or OR1(or1_out, and1_out, and2_out);
    and AND3(and3_out, nA, or1_out);
    and AND4(and4_out, A, nB, C, D);

    or OR_FINAL(RED1, and3_out, and4_out);
endmodule

module red2 (
    output RED2,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    wire and1_out, and2_out, or1_out, and3_out, and4_out;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    and AND1(and1_out, nB, nD);
    and AND2(and2_out, B, C);
    or OR1(or1_out, and1_out, and2_out);
    and AND3(and3_out, nA, or1_out);
    and AND4(and4_out, A, nB, C, D);

    or OR_FINAL(RED2, and3_out, and4_out);
endmodule

module red3 (
    output RED3,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    wire and1_out, and2_out, or1_out, and3_out, and4_out;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    and AND1(and1_out, B, nC);
    and AND2(and2_out, B, D);
    or OR1(or1_out, and1_out, and2_out);
    and AND3(and3_out, nA, or1_out);
    and AND4(and4_out, A, nB, C, D);

    or OR_FINAL(RED3, and3_out, and4_out);
endmodule

module green0 (
    output GREEN0,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    wire and1_out, and2_out, or1_out, and3_out, and4_out;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    and AND1(and1_out, nB, nD);
    and AND2(and2_out, B, C);
    or OR1(or1_out, and1_out, and2_out);
    and AND3(and3_out, nA, or1_out);
    and AND4(and4_out, A, nB, C, D);

    or OR_FINAL(GREEN0, and3_out, and4_out);
endmodule

module green1 (
    output GREEN1,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    wire and1_out, and2_out, or1_out, and3_out, and4_out;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    and AND1(and1_out, nB, nD);
    and AND2(and2_out, B, C);
    or OR1(or1_out, and1_out, and2_out);
    and AND3(and3_out, nA, or1_out);
    and AND4(and4_out, A, nB, C, D);

    or OR_FINAL(GREEN1, and3_out, and4_out);
endmodule

module green2 (
    output GREEN2,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    wire and1_out, and2_out, or1_out, and3_out, and4_out, and5_out;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    and AND1(and1_out, B, nD);
    and AND2(and2_out, B, C);
    or OR1(or1_out, and1_out, and2_out);
    and AND3(and3_out, nA, or1_out);
    and AND4(and4_out, A, nC, D);
    and AND5(and5_out, nB, C, nD);

    or OR_FINAL(GREEN2, and3_out, and4_out, and5_out);
endmodule

module green3 (
    output GREEN3,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    wire and1_out, and2_out, or1_out, and3_out, and4_out;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    and AND1(and1_out, nB, D);
    and AND2(and2_out, B, C);
    or OR1(or1_out, and1_out, and2_out);
    and AND3(and3_out, nA, or1_out);
    and AND4(and4_out, A, nB, C, nD);

    or OR_FINAL(GREEN3, and3_out, and4_out);
endmodule

module blue0 (
    output BLUE0,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    wire and1_out, and2_out, or1_out, or2_out, and3_out, and4_out;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    or OR1(or1_out, D, A);
    and AND1(and1_out, nC, or1_out);
    and AND2(and2_out, C, nD);
    or OR2(or2_out, and1_out, and2_out);
    and AND3(and3_out, nB, or2_out);
    and AND4(and4_out, nA, C, D);

    or OR_FINAL(BLUE0, and3_out, and4_out);
endmodule

module blue1 (
    output BLUE1,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    wire and1_out, and2_out, or1_out, and3_out, and4_out;

    or OR1(or1_out, D, B); 
    and AND1(and1_out, C, or1_out); 
    and AND2(and2_out, B, D);
    or OR2(or2_out, and1_out, and2_out); 
    and AND3(and3_out, nA, or2_out); 
    and AND4(and4_out, A, nB, C, nD); 
    or OR_FINAL(BLUE1, and3_out, and4_out);
endmodule

module blue2 (
    output BLUE2,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    wire and1_out, and2_out, and3_out, and4_out, and5_out, or1_out, or2_out;

    or OR1(or1_out, D, B);
    and AND1(and1_out, C, or1_out);
    and AND2(and2_out, nB, nC, nD);
    and AND3(and3_out, B, D);
    or OR2(or2_out, and1_out, and2_out, and3_out);
    and AND4(and4_out, nA, or2_out);
    and AND5(and5_out, A, nC, nD);
    and AND6(and6_out, A, nB, C, D);

    or OR_FINAL(BLUE2, and4_out, and5_out, and6_out);
endmodule

module blue3 (
    output BLUE3,
    input A, B, C, D
);
    wire nA, nB, nC, nD;
    not NOT_A(nA, A);
    not NOT_B(nB, B);
    not NOT_C(nC, C);
    not NOT_D(nD, D);

    wire and1_out, and2_out, or1_out, and3_out;

    and AND1(and1_out, nA, D);
    and AND2(and2_out, nA, B);
    or OR1(or1_out, and1_out, and2_out);
    and AND3(and3_out, C, or1_out);
    and AND4(and4_out, nA, B, D);

    or OR_FINAL(BLUE3, and3_out, and4_out);
endmodule

module full_adder (
    input wire a, b, cin,
    output wire sum, cout
);
    wire xor1, and1, and2, and3;
    xor xor_1 (xor1, a, b);
    xor xor_2 (sum, xor1, cin);
    and and_1 (and1, a, b);
    and and_2 (and2, a, cin);
    and and_3 (and3, b, cin);
    or or_1 (cout, and1, and2, and3);
endmodule

module flip_flop_d (
    input wire clk, reset, d,
    output reg q,
    output reg q_bar
);
    // Atualiza saída no flanco de subida do clock ou reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 1'b0;
            q_bar <= 1'b1;
        end else begin
            q <= d;
            q_bar <= ~d;
        end
    end
endmodule