// led_fold.v — Mojo v3 8-LED "folding" pattern.
// One LED on at a time, 100 ms each (50 MHz clk), looping:
//   1, 8, 2, 7, 3, 6, 4, 5   (human numbering)
// i.e. from the outside in. Ports match led_test.ucf (clk P56, rst_n P38,
// led[0..7] = P134,133,132,131,127,126,124,123).
module led_fold #(
  parameter integer TICKS_PER_STEP = 5_000_000    // 100 ms at 50 MHz
) (
  input  wire clk,
  input  wire rst_n,
  output reg  [7:0] led
);
  localparam integer TICK_MAX = TICKS_PER_STEP - 1;
  localparam integer TICK_W   = 26;               // 2^26 > 50,000,000

  reg [TICK_W-1:0] tick;
  reg [2:0] seq;                                  // 0..7: position in pattern

  // seq -> LED index: [0,7,1,6,2,5,3,4]  (0-based: 1,8,2,7,3,6,4,5)
  wire [2:0] sel = (seq == 3'd0) ? 3'd0 :
                   (seq == 3'd1) ? 3'd7 :
                   (seq == 3'd2) ? 3'd1 :
                   (seq == 3'd3) ? 3'd6 :
                   (seq == 3'd4) ? 3'd2 :
                   (seq == 3'd5) ? 3'd5 :
                   (seq == 3'd6) ? 3'd3 : 3'd4;

  always @(posedge clk) begin
    if (!rst_n) begin
      tick <= {TICK_W{1'b0}};
      seq  <= 3'd0;
      led  <= 8'h01;
    end else begin
      if (tick == TICK_MAX) begin
        tick <= {TICK_W{1'b0}};
        seq  <= seq + 3'd1;
      end else begin
        tick <= tick + 1'b1;
      end
      led <= 8'b1 << sel;
    end
  end
endmodule
