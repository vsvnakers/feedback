`timescale 1ns/1ps

module feedback_tb;

    parameter CLAUSE_NUM = 4;
    parameter WEIGHT_WIDTH = 8;
    parameter LITERAL_NUM = 8;
    parameter STATE_WIDTH = 4;

    reg clk, rst_n, en, is_positive_sample;
    reg [CLAUSE_NUM-1:0] conjunction_result;
    reg [LITERAL_NUM-1:0] actions;
    reg [LITERAL_NUM-1:0] literals;

    reg [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_in;
    wire [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] weight_out;

    reg [LITERAL_NUM * STATE_WIDTH - 1:0] state_in;
    wire [LITERAL_NUM * STATE_WIDTH - 1:0] state_out;

    // DUT
    feedback #(
        .CLAUSE_NUM(CLAUSE_NUM),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .LITERAL_NUM(LITERAL_NUM),
        .STATE_WIDTH(STATE_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .is_positive_sample(is_positive_sample),
        .conjunction_result(conjunction_result),
        .actions(actions),
        .literals(literals),
        .weight_in(weight_in),
        .weight_out(weight_out),
        .state_in(state_in),
        .state_out(state_out)
    );

    always #5 clk = ~clk;

    task check;
        input [LITERAL_NUM * STATE_WIDTH - 1:0] expected_state;
        input [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] expected_weight;
        input integer test_type;
        begin
            if (state_out === expected_state)
                $display("[PASS] Type %0d State", test_type);
            else begin
                $display("[ERROR] Type %0d State Mismatch", test_type);
                $display("Expected: %h", expected_state);
                $display("Got     : %h", state_out);
            end

            if (weight_out === expected_weight)
                $display("[PASS] Type %0d Weight", test_type);
            else begin
                $display("[ERROR] Type %0d Weight Mismatch", test_type);
                $display("Expected: %h", expected_weight);
                $display("Got     : %h", weight_out);
            end
        end
    endtask

    function [STATE_WIDTH-1:0] update_state;
        input [STATE_WIDTH-1:0] curr;
        input action, literal, is_pos;
        begin
            if (is_pos) begin
                if (action && literal && curr < ((1<<STATE_WIDTH)-1)) update_state = curr + 1;
                else if (!action && !literal && curr > 0) update_state = curr - 1;
                else update_state = curr;
            end else begin
                if (action && literal && curr > 0) update_state = curr - 1;
                else if (!action && !literal && curr < ((1<<STATE_WIDTH)-1)) update_state = curr + 1;
                else update_state = curr;
            end
        end
    endfunction

    function [WEIGHT_WIDTH-1:0] update_weight;
        input signed [WEIGHT_WIDTH-1:0] w;
        input match;
        input is_pos;
        begin
            if (match) begin
                if (is_pos)
                    update_weight = (w >= 0) ? w + 1 : w - 1;
                else
                    update_weight = (w >= 0) ? w - 1 : w + 1;
            end else begin
                update_weight = w;
            end
        end
    endfunction

    initial begin
        integer i;
        reg [LITERAL_NUM * STATE_WIDTH - 1:0] expected_state_I, expected_state_II;
        reg [CLAUSE_NUM * WEIGHT_WIDTH - 1:0] expected_weight_I, expected_weight_II;

        reg [STATE_WIDTH-1:0] curr_state_1 [0:LITERAL_NUM-1];
        reg signed [WEIGHT_WIDTH-1:0] curr_weight_1 [0:CLAUSE_NUM-1];

        clk = 0; rst_n = 0; en = 0;

        actions = 8'b10101010;
        literals = 8'b11001100;
        conjunction_result = 4'b1010;

        for (i = 0; i < LITERAL_NUM; i = i + 1)
            state_in[i*STATE_WIDTH +: STATE_WIDTH] = 4'd3;

        for (i = 0; i < CLAUSE_NUM; i = i + 1)
            weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] = 8'sd0;

        #10 rst_n = 1;
        #10;

        // === Type I ===
        en = 1;
        is_positive_sample = 1;
        #10 en = 0;

        for (i = 0; i < LITERAL_NUM; i = i + 1) begin
            curr_state_1[i] = update_state(4'd3, actions[i], literals[i], 1);
            expected_state_I[i*STATE_WIDTH +: STATE_WIDTH] = curr_state_1[i];
        end

        for (i = 0; i < CLAUSE_NUM; i = i + 1) begin
            curr_weight_1[i] = update_weight(8'sd0, conjunction_result[i], 1);
            expected_weight_I[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] = curr_weight_1[i];
        end

        check(expected_state_I, expected_weight_I, 1);

        // === Type II ===
        en = 1;
        is_positive_sample = 0;
        conjunction_result = 4'b0101;
        state_in = state_out;
        weight_in = weight_out;
        #10 en = 0;

        for (i = 0; i < LITERAL_NUM; i = i + 1) begin
            expected_state_II[i*STATE_WIDTH +: STATE_WIDTH] =
                update_state(curr_state_1[i], actions[i], literals[i], 0);
        end

        for (i = 0; i < CLAUSE_NUM; i = i + 1) begin
            expected_weight_II[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] =
                update_weight(curr_weight_1[i], conjunction_result[i], 0);
        end

        check(expected_state_II, expected_weight_II, 2);

        $finish;
    end

endmodule
