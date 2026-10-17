// ============================================================================
// Mojo V3 -- "LED PWM cycle" bitstream
// ----------------------------------------------------------------------------
// Each on-board LED cycles through three brightness levels -- 25%, 75% and
// 100% -- stepping to the next level once per second. Starting point:
//
//   led[0] = 25%,  led[1] = 75%,  led[2] = 100%,  led[3] = 25%,
//   led[4] = 75%,  led[5] = 100%, led[6] = 25%,   led[7] = 75%.
//
// After 1 s every LED advances one level (25 -> 75 -> 100 -> 25, ...), so
// the pattern shifts by one level per second; each LED completes a full
// cycle every 3 s.
//
// The LEDs are plain digital outputs (LVTTL, active high) -- there is no
// analog dimming. Brightness is implemented as PWM: a 1 kHz PWM waveform
// (1 ms period = 50,000 ticks of the 50 MHz clock) with duty cycle
// 25 / 75 / 100%. 1 kHz is far above the human flicker-fusion threshold, so
// the duty cycles read as steady brightnesses.
//
// Ports match led_test.ucf (clk P56, rst_n P38,
// led[0..7] = P134,133,132,131,127,126,124,123). LEDs are active-high.
// ============================================================================

module led_pwm_cycle (
    input        clk,   // 50 MHz board clock  (P56)
    input        rst_n, // reset button, active low (P38)
    output [7:0] led
);

  localparam PWM_DIV  = 16'd50000;  // 50 MHz / 50000 = 1 kHz PWM
  localparam SEC_DIV  = 26'd50000000; // 50 MHz / 50e6 = 1 Hz (level step)

  // ---------------------------------------------------------------------------
  // 1 kHz PWM counter: 0 .. 49999, 1 ms period.
  // ---------------------------------------------------------------------------
  reg [15:0] pwm_cnt = 16'd0;

  // ---------------------------------------------------------------------------
  // 1 Hz counter: rollover every second advances the brightness phase.
  // ---------------------------------------------------------------------------
  reg [25:0] sec_cnt   = 26'd0;
  reg [1:0]  phase_sel = 2'd0;   // which level shift: 0, 1 or 2

  // ---------------------------------------------------------------------------
  // level = a + b (mod 3), for a, b in {0,1,2}.
  // ---------------------------------------------------------------------------
  function [1:0] add3;
    input [1:0] a;
    input [1:0] b;
    reg   [2:0] s;
    begin
      s = {1'b0, a} + {1'b0, b};
      if (s >= 3'd3) s = s - 3'd3;
      add3 = s[1:0];
    end
  endfunction

  // ---------------------------------------------------------------------------
  // duty = number of PWM ticks the LED is high within one 1 ms period:
  // level 0 -> 12500 (25%), level 1 -> 37500 (75%), level 2 -> 50000 (on).
  // ---------------------------------------------------------------------------
  function [15:0] duty_of;
    input [1:0] lvl;
    begin
      case (lvl)
        2'd0:    duty_of = 16'd12500;
        2'd1:    duty_of = 16'd37500;
        2'd2:    duty_of = 16'd50000;
        default: duty_of = 16'd0;
      endcase
    end
  endfunction

  always @(posedge clk) begin
    if (rst_n == 1'b0) begin
      pwm_cnt   <= 16'd0;
      sec_cnt   <= 26'd0;
      phase_sel <= 2'd0;
    end else begin
      if (pwm_cnt == PWM_DIV - 1)
        pwm_cnt <= 16'd0;
      else
        pwm_cnt <= pwm_cnt + 1'b1;

      if (sec_cnt == SEC_DIV - 1) begin
        sec_cnt   <= 26'd0;
        phase_sel <= add3(phase_sel, 2'd1);
      end else begin
        sec_cnt   <= sec_cnt + 1'b1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // LED i starts at level (i mod 3): {0,1,2,0,1,2,0,1}. Each second the
  // phase advances one level.
  // ---------------------------------------------------------------------------
  wire [1:0] lvl0 = add3(phase_sel, 2'd0);  // led[0] base level 0
  wire [1:0] lvl1 = add3(phase_sel, 2'd1);  // led[1] base level 1
  wire [1:0] lvl2 = add3(phase_sel, 2'd2);  // led[2] base level 2
  wire [1:0] lvl3 = add3(phase_sel, 2'd0);
  wire [1:0] lvl4 = add3(phase_sel, 2'd1);
  wire [1:0] lvl5 = add3(phase_sel, 2'd2);
  wire [1:0] lvl6 = add3(phase_sel, 2'd0);
  wire [1:0] lvl7 = add3(phase_sel, 2'd1);  // led[7] base level 1 (7 mod 3)

  assign led[0] = pwm_cnt < duty_of(lvl0);
  assign led[1] = pwm_cnt < duty_of(lvl1);
  assign led[2] = pwm_cnt < duty_of(lvl2);
  assign led[3] = pwm_cnt < duty_of(lvl3);
  assign led[4] = pwm_cnt < duty_of(lvl4);
  assign led[5] = pwm_cnt < duty_of(lvl5);
  assign led[6] = pwm_cnt < duty_of(lvl6);
  assign led[7] = pwm_cnt < duty_of(lvl7);

endmodule
