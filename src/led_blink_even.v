// ============================================================================
// Mojo V3 -- "even LEDs" 1 Hz blink bitstream
// ----------------------------------------------------------------------------
// Lights the even-numbered on-board LEDs (led[0], led[2], led[4], led[6])
// every second (1 Hz), all four on and off together. The odd LEDs
// (led[1], led[3], led[5], led[7]) stay off.
//
//   Pattern (50 MHz clock): led = 8'b0101_0101 when on, 8'b0000_0000 when off.
//
// Ports match led_test.ucf (clk P56, rst_n P38,
// led[0..7] = P134,133,132,131,127,126,124,123). LEDs are active-high.
// ============================================================================

module led_blink_even (
    input        clk,   // 50 MHz board clock  (P56)
    input        rst_n, // reset button, active low (P38)
    output [7:0] led
);

  // ---------------------------------------------------------------------------
  // Free-running 50 MHz -> 1 Hz toggle.
  // Toggle every 25,000,000 cycles = 0.5 s, so the LEDs are ON for 0.5 s
  // and OFF for 0.5 s: "lights one LED every second" (1 Hz on/off).
  // ---------------------------------------------------------------------------
  localparam BLINK_DIV = 50000000 / 2;     // 25000000
  reg [24:0]    blink_cnt = 25'd0;
  reg           blink_bit = 1'b0;

  always @(posedge clk) begin
    if (rst_n == 1'b0) begin
      blink_cnt <= 25'd0;
      blink_bit <= 1'b0;
    end else if (blink_cnt == BLINK_DIV - 1) begin
      blink_cnt <= 25'd0;
      blink_bit <= ~blink_bit;
    end else begin
      blink_cnt <= blink_cnt + 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // Only the even LEDs (bit indices 0, 2, 4, 6) are driven; the rest stay off.
  // ---------------------------------------------------------------------------
  assign led = blink_bit ? 8'b0101_0101 : 8'b0000_0000;

endmodule
