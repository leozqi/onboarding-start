/*
 * Copyright (c) 2025 Leo Qi
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module spi (
    input  wire       clk,      // systemclock: 10MHz
    input  wire       rst_n,    // reset_n - low to reset
    input  wire       ncs,     // Chip Select (active low)
    input  wire       sclk,    // controller clock: 100Khz
    input  wire       copi,    // controller-out peripheral-in input
    output reg[15:0]  reg_en_out,
    output reg[15:0]  reg_en_pwm,
    output reg[7:0]   reg_pwm_duty,
);

reg [2:0] sample_sclk;
reg [1:0] sample_copi;
reg [1:0] sample_ncs;
reg [15:0] data_in;
// states:
// 0: ready
// 1: 
// 1-6: getting address
// 7-15: getting data
reg [4:0] state;

always @(posedge clk) begin
  if (!rst_n) begin
    // Explicit reset everything
    reg_en_out <= 0;
    reg_en_pwm <= 0;
    sample_sclk <= 0;
    sample_copi <= 0;
    sample_ncs <= 0;
    state <= 0;
    data_in <= 0;
  end else begin
    // Sample the SPI signals and shift left (prevent metastability)
    sample_sclk <= {sample_sclk[1:0], sclk};
    sample_copi <= {sample_copi[0], copi};
    sample_ncs <= {sample_ncs[0], ncs};

    if (state == 0 && !sample_ncs[1] && sample_ncs[0]) begin
      // nCS goes low, all we need is to wait for the first clock edge
      state <= 'd1;
      data_in <= 0;
      reg_en_out <= reg_en_out;
      reg_en_pwm <= reg_en_pwm;
      reg_pwm_duty <= reg_pwm_duty;
    end else if (state >= 'd1 && state <= 'd16 && sample_sclk[2] && !sample_sclk[1]) begin
      state <= state + 1;
      data_in <= {data_in[14:0], sample_copi[1]};
    end else if (state == 'd17) begin
      if (data_in[14:8] == 8'd0) begin // en_reg_out_7_0
        reg_en_out <= {reg_en_out[15:8], data_in[7:0]};
        reg_en_pwm <= reg_en_pwm;
        reg_pwm_duty <= reg_pwm_duty;
      end else if (data_in[14:8] == 8'd1) begin
        reg_en_out <= {data_in[7:0], reg_en_out[7:0]};
        reg_en_pwm <= reg_en_pwm;
        reg_pwm_duty <= reg_pwm_duty;
      end else if (data_in[14:8] == 8'd2) begin // en_reg_pwm_7_0
        reg_en_out <= reg_en_out;
        reg_en_pwm <= {reg_en_pwm[15:8], data_in[7:0]};
        reg_pwm_duty <= reg_pwm_duty;
      end else if (data_in[14:8] == 8'd3) begin
        reg_en_out <= reg_en_out;
        reg_en_pwm <= {data_in[7:0], reg_en_pwm[7:0]};
        reg_pwm_duty <= reg_pwm_duty;
      end else if (data_in[14:8] == 8'd4) begin // pwm_duty_cycle
        reg_en_out <= reg_en_out;
        reg_en_pwm <= reg_en_pwm;
        reg_pwm_duty <= data_in[7:0];
      end else begin
        // Ignore invalid addresses
        reg_en_out <= reg_en_out;
        reg_en_pwm <= reg_en_pwm;
        reg_pwm_duty <= reg_pwm_duty;
      end
    end else begin
      state <= 0;
      data_in <= 0;
      reg_en_out <= reg_en_out;
      reg_en_pwm <= reg_en_pwm;
      reg_pwm_duty <= reg_pwm_duty;
    end
  end
end

endmodule
