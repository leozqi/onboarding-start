/*
 * Copyright (c) 2025 Leo Qi
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_uwasic_onboarding_leozqi (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  // Add this inside the module block
  assign uio_oe = 8'hFF; // Set all IOs to output

  // Create wires to refer to the values of the registers
  wire [7:0] en_reg_out_7_0;
  wire [7:0] en_reg_out_15_8;
  wire [7:0] en_reg_pwm_7_0;
  wire [7:0] en_reg_pwm_15_8;
  wire [7:0] pwm_duty_cycle;

  spi spi_inst (
    .clk(clk),
    .rst_n(rst_n),
    .ncs(ui_in[2]), // Chip Select (active low)
    .sclk(ui_in[0]), // controller clock: 100Khz
    .copi(ui_in[1]),  // controller-out peripheral-in input
    .reg_en_out({en_reg_out_15_8, en_reg_out_7_0}),
    .reg_en_pwm({en_reg_pwm_15_8, en_reg_pwm_7_0}),
    .reg_pwm_duty(pwm_duty_cycle)
  );

  // Instantiate the PWM module
  pwm_peripheral pwm_peripheral_inst (
    .clk(clk),
    .rst_n(rst_n),
    .en_reg_out_7_0(en_reg_out_7_0),
    .en_reg_out_15_8(en_reg_out_15_8),
    .en_reg_pwm_7_0(en_reg_pwm_7_0),
    .en_reg_pwm_15_8(en_reg_pwm_15_8),
    .pwm_duty_cycle(pwm_duty_cycle),
    .out({uio_out, uo_out})
  );
  // Add uio_in and ui_in[7:3] to the list of unused signals:
  wire _unused = &{ena, ui_in[7:3], uio_in, 1'b0};
endmodule
