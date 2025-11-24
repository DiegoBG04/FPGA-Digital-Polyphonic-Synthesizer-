
// Top-level: connects PS2 synth core to the DE1-SoC audio codec
module Synth_Top (
    // 50 MHz clock and keys
    input               CLOCK_50,
    input       [3:0]   KEY,

    // PS/2 keyboard
    inout               PS2_CLK,
    inout               PS2_DAT,

    // Audio codec inputs
    input               AUD_ADCDAT,

    // Audio codec bidirectionals
    inout               AUD_BCLK,
    inout               AUD_ADCLRCK,
    inout               AUD_DACLRCK,

    inout               FPGA_I2C_SDAT,

    // Audio codec outputs
    output              AUD_XCK,
    output              AUD_DACDAT,
    output              FPGA_I2C_SCLK,

    // 7-segment displays

    output      [6:0]   HEX0,
    output      [6:0]   HEX1,
    output      [6:0]   HEX2,
    output      [6:0]   HEX3,
    output      [6:0]   HEX4,
    output      [6:0]   HEX5,
    output      [6:0]   HEX6,
    output      [6:0]   HEX7,
	 output      [9:0]   LEDR
);

/*****************************************************************************
 *                    Wires between modules                                  *
 *****************************************************************************/

wire [15:0] synth_audio_out;          // from PS2_Main                                      
wire [6:0]  hex0_s, hex1_s, hex2_s;   // internal hex from PS2_Main (we just pass them out)

/*** Audio_Controller side ***/
wire               audio_in_available;
wire [31:0]        left_channel_audio_in;
wire [31:0]        right_channel_audio_in;

wire               audio_out_allowed;
wire [31:0]        left_channel_audio_out;
wire [31:0]        right_channel_audio_out;
reg                write_audio_out;

/*****************************************************************************
 *                         PS2 Synth Core                                    *
 *****************************************************************************/

PS2_Main SynthCore (
    .CLOCK_50 (CLOCK_50),
    .KEY      (KEY),

    .PS2_CLK  (PS2_CLK),
    .PS2_DAT  (PS2_DAT),

    .HEX0     (HEX0),
    .HEX1     (HEX1),
    .HEX2     (HEX2),
    .HEX3     (HEX3),
    .HEX4     (HEX4),
    .HEX5     (HEX5),
    .HEX6     (HEX6),
    .HEX7     (HEX7),
	 .LEDR     (LEDR),

    .audio_out(synth_audio_out)
);

/*****************************************************************************
 *                    Map synth output to audio codec                        *
 *****************************************************************************/


/*reg [15:0] test_saw;
always @(posedge CLOCK_50) begin
	test_saw <= test_saw + 16'd1;
end

wire [15:0] synth_audio_out = test_saw;
*/
assign left_channel_audio_out  = {synth_audio_out, 16'b0};                                    
assign right_channel_audio_out = {synth_audio_out, 16'b0};

assign left_channel_audio_in   = 32'd0;
assign right_channel_audio_in  = 32'd0;

/*****************************************************************************
 *                     Write control to Audio_Controller                     *
 *****************************************************************************/

wire reset_n = KEY[0];   // KEY0 low = reset
wire reset   = ~reset_n;

always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        write_audio_out <= 1'b0;
    end else begin
        if (audio_out_allowed) begin
            write_audio_out <= 1'b1;
        end else begin
            write_audio_out <= 1'b0;
        end
    end
end

/*****************************************************************************
 *                          Audio_Controller instance                        *
 *****************************************************************************/

Audio_Controller Audio_Controller_inst (
    // Inputs
    .CLOCK_50               (CLOCK_50),
    .reset                  (reset),

    .clear_audio_in_memory  (1'b0),
    .read_audio_in          (1'b0),

    .clear_audio_out_memory (1'b0),
    .left_channel_audio_out (left_channel_audio_out),
    .right_channel_audio_out(right_channel_audio_out),
    .write_audio_out        (write_audio_out),

    .AUD_ADCDAT             (AUD_ADCDAT),

    // Bidirectionals
    .AUD_BCLK               (AUD_BCLK),
    .AUD_ADCLRCK            (AUD_ADCLRCK),
    .AUD_DACLRCK            (AUD_DACLRCK),

    // Outputs
    .audio_in_available     (audio_in_available),
    .left_channel_audio_in  (left_channel_audio_in),
    .right_channel_audio_in (right_channel_audio_in),

    .audio_out_allowed      (audio_out_allowed),

    .AUD_XCK                (AUD_XCK),
    .AUD_DACDAT             (AUD_DACDAT)
);

/*****************************************************************************
 *                       Audio codec configuration (I2C)                     *
 *****************************************************************************/

avconf #(.USE_MIC_INPUT(1)) avc (
    .FPGA_I2C_SCLK          (FPGA_I2C_SCLK),
    .FPGA_I2C_SDAT          (FPGA_I2C_SDAT),
    .CLOCK_50               (CLOCK_50),
    .reset                  (reset)
);

endmodule