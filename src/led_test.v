// ============================================================================
// Mojo V3 -- LED test / demo bitstream
// ----------------------------------------------------------------------------
// Standalone top module that drives all 8 on-board LEDs with an easy-to-see
// pattern so you can confirm a bitstream successfully loaded onto the FPGA.
//
//   Pattern (50 MHz clock):
//     * A ~1 Hz "clock" bit (led[0]) blinks.
//     * A "chase" bit walks around the remaining 7 LEDs (~1.5 steps/sec).
//   Together this is a very obvious, unmistakable motion on the LED strip.
//
// This is intended for TEST purposes only. To build it you can either:
//   (a) replace the body of mojo_top.v with this file's logic and reuse the
//       existing mojo.ucf constraints, or
//   (b) use led_test.v as the top and the led_test.ucf constraints below.
//
// LED polarity: the base project's `led` output maps 1:1 to the 8 LED pads
// (P134..P123). The base project drives `led = 8'b0` for "all off". On the
// Mojo v3 the LEDs light on the HIGH level of these outputs (active-high),
// so a '1' turns the LED on.
// ============================================================================

module led_test(
    input        clk,   // 50 MHz board clock  (P56)
    input        rst_n, // reset button, active low (P38) -- ignored, self-clocks
    output [7:0] led
);

  // ---------------------------------------------------------------------------
  // Free-running 50 MHz -> ~1 Hz tick (for the blink bit)
  // ---------------------------------------------------------------------------
  localparam BLINK_DIV = 50_000_000 / 2;   // ~0.5 Hz toggle -> ~1 Hz on/off
  reg [25:0]    blink_cnt = 26'd0;
  reg           blink_bit = 1'b0;

  always @(posedge clk) begin
    if (blink_cnt == BLINK_DIV - 1) begin
      blink_cnt <= 26'd0;
      blink_bit <= ~blink_bit;
    end
    else
      blink_cnt <= blink_cnt + 1'b1;
  end

  // ---------------------------------------------------------------------------
  // Free-running divider for the chase bit (~1.5 steps per second)
  // ---------------------------------------------------------------------------
  localparam CHASE_DIV = 50_000_000 / 75;  // ~666 kHz toggle -> ~1.5 Hz step
  reg [25:0]    chase_cnt = 26'd0;
  reg [6:0]     chase_step = 7'b0000001;

  always @(posedge clk) begin
    if (chase_cnt == CHASE_DIV - 1) begin
      chase_cnt  <= 26'd0;
      chase_step <= chase_step + 7'd1;
    end
    else
      chase_cnt <= chase_cnt + 1'b1;
  end

  // ---------------------------------------------------------------------------
  // Build the LED pattern:
  //   led[0] = slow blink
  //   led[1..7] = a single "1" that walks around the 7-bit chase counter
  // ---------------------------------------------------------------------------
  wire [6:0] chase_sel;
  assign chase_sel = chase_step[6:0];

  assign led[0]   = blink_bit;
  assign led[7:1] = chase_sel;

endmodule
