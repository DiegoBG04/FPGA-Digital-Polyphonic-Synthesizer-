module PS2_Main (
    // Inputs
    CLOCK_50,
    KEY,

    // Bidirectional
    PS2_CLK,
    PS2_DAT,
    
    // Outputs
    HEX0,
    HEX1,
    HEX2,
    HEX3,
    HEX4,
    HEX5,
    HEX6,
    HEX7,
	 LEDR,
    audio_out
);

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/

// Inputs
input               CLOCK_50;
input       [3:0]   KEY;
// Bidirectionals
input               PS2_CLK;
input               PS2_DAT;

// Outputs

output reg     [6:0]   HEX0;
output reg     [6:0]   HEX1;
output reg     [6:0]   HEX2;
output reg     [6:0]   HEX3;
output reg     [6:0]   HEX4;
output reg     [6:0]   HEX5;
output reg     [6:0]   HEX6;
output reg     [6:0]   HEX7;
output         [9:0]   LEDR;
output         [15:0]  audio_out;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

wire        [7:0]   ps2_key_data;
wire                ps2_key_pressed;

reg                 break_pending;
reg         [255:0] key_down;

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50) begin
    if (KEY[0] == 1'b0) begin
        break_pending <= 1'b0;
        key_down      <= 256'b0;
    end else if (ps2_key_pressed) begin
        case (ps2_key_data)
            8'hF0: begin
                break_pending <= 1'b1;
            end
            8'hE0: begin
                // Extended code (not used here)
            end
            default: begin
                if (break_pending) begin
                    key_down[ps2_key_data] <= 1'b0;
                    break_pending <= 1'b0;
                end else begin
                    key_down[ps2_key_data] <= 1'b1;
                end
            end
        endcase
    end
end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

wire [6:0]  seg0, seg1, seg2;
wire [23:0] ticks0, ticks1, ticks2;
wire [3:0]  voice_count;
wire [3:0] octave;
wire [1:0] wave1_sel, wave2_sel;
wire [6:0] mix_percent;
wire [6:0] attack_time;     
wire [6:0] sustain_level;   
wire [6:0] release_time; 
wire [15:0] env_level;
wire [15:0] raw_audio;  
wire any_key_down = (voice_count != 4'd0); //measures keys pressed to go between attack,sustain and release phases
reg hex_mode;

reg [3:0]  held_voice_count;
reg [23:0] held_ticks0;
reg [23:0] held_ticks1;
reg [23:0] held_ticks2;

// Hold the last active notes so waveform_generator can keep running during release
always @(posedge CLOCK_50 or negedge KEY[0]) begin
    if (!KEY[0]) begin
        held_voice_count <= 4'd0;
        held_ticks0      <= 24'd0;
        held_ticks1      <= 24'd0;
        held_ticks2      <= 24'd0;
    end else begin
        if (any_key_down) begin
            // While at least one note key is down, track the current voices
            held_voice_count <= voice_count;
            held_ticks0      <= ticks0;
            held_ticks1      <= ticks1;
            held_ticks2      <= ticks2;
        end else if (env_level == 16'd0) begin
            // When envelope has fully decayed, clear held notes
            held_voice_count <= 4'd0;
            held_ticks0      <= 24'd0;
            held_ticks1      <= 24'd0;
            held_ticks2      <= 24'd0;
        end
    end
end

// Drive the waveform generator from the held notes so it continues through release
wire [3:0]  voice_count_drive = held_voice_count;
wire [23:0] ticks0_drive      = held_ticks0;
wire [23:0] ticks1_drive      = held_ticks1;
wire [23:0] ticks2_drive      = held_ticks2;


always @(posedge CLOCK_50 or negedge KEY[0]) begin
    if (!KEY[0]) begin
        hex_mode <= 1'b0;          // default to mixer mode on reset
    end else begin
        if (KEY[1] == 1'b0)
            hex_mode <= 1'b0;      // mixer 
        else if (KEY[2] == 1'b0)
            hex_mode <= 1'b1;      // ASR
    end
end


synth_controls Controls(
	.clk (CLOCK_50),
	.reset_n (KEY[0]),
	.key_down (key_down),
	.octave (octave),
	.wave1_sel (wave1_sel),
	.wave2_sel (wave2_sel),
	.mix_percent (mix_percent),
    .attack_time (attack_time),
    .sustain_level (sustain_level),
    .release_time (release_time)
);

function [6:0] hex;
    input [3:0] val;
    case (val)
        4'h0: hex = 7'b1000000;
        4'h1: hex = 7'b1111001;
        4'h2: hex = 7'b0100100;
        4'h3: hex = 7'b0110000;
        4'h4: hex = 7'b0011001;
        4'h5: hex = 7'b0010010;
        4'h6: hex = 7'b0000010;
        4'h7: hex = 7'b1111000;
        4'h8: hex = 7'b0000000;
        4'h9: hex = 7'b0010000;
        4'hA: hex = 7'b0001000;
        4'hB: hex = 7'b0000011;
        4'hC: hex = 7'b1000110;
        4'hD: hex = 7'b0100001;
        4'hE: hex = 7'b0000110;
        4'hF: hex = 7'b0001110;
        default: hex = 7'b1111111;
    endcase
endfunction

// ---- Mix percentage digits (0..99) ----
wire [3:0] mix_tens = mix_percent / 10;
wire [3:0] mix_ones = mix_percent % 10;
wire [3:0] attack_time_tens = attack_time / 10;
wire [3:0] attack_time_ones = attack_time % 10;
wire [3:0] sustain_level_tens = sustain_level / 10;
wire [3:0] sustain_level_ones = sustain_level % 10;
wire [3:0] release_time_tens = release_time / 10;
wire [3:0] release_time_ones = release_time % 10;






//hex mode selections for mixer and ASR module//////////
always @(*) begin
    case (hex_mode)
        //  MODE 0: MIXER MODE (KEY1)
        1'b0: begin
            // Waveform 2 selection (binary)
            HEX1 = hex({3'b000, wave2_sel[1]});
            HEX0 = hex({3'b000, wave2_sel[0]});

            // Mix percentage
            HEX3 = hex(mix_tens);
            HEX2 = hex(mix_ones);

            // Waveform 1 selection (binary)
            HEX5 = hex({3'b000, wave1_sel[1]});
            HEX4 = hex({3'b000, wave1_sel[0]});

            // Unused HEX displays
            HEX6 = 7'h7F;
            HEX7 = 7'h7F;
        end

        //  MODE 1: ASR MODE (KEY2)
        1'b1: begin
            // Attack time (2 digits)
            HEX5 = hex(attack_time_tens);
            HEX4 = hex(attack_time_ones);

            // Sustain level (2 digits)
            HEX3 = hex(sustain_level_tens);
            HEX2 = hex(sustain_level_ones);

            // Release time (2 digits)
            HEX1 = hex(release_time_tens);
            HEX0 = hex(release_time_ones);

            // Unused HEX displays
            HEX6 = 7'h7F;
            HEX7 = 7'h7F;
        end

    endcase
end



key_to_note_ticks NoteConverter(
    .key_down(key_down),
    .voice_count(voice_count),
    .seg0(seg0),
    .seg1(seg1),
    .seg2(seg2),
    .ticks0(ticks0),
    .ticks1(ticks1),
    .ticks2(ticks2)
);


waveform_generator SynthCoreModule(
    .CLOCK_50(CLOCK_50),
    .resetn(KEY[0]),          // KEY0 low = reset
    .voice_count(voice_count_drive),
    .ticks0_in(ticks0_drive),
    .ticks1_in(ticks1_drive),
    .ticks2_in(ticks2_drive),
    .waveform1_select(wave1_sel), 
    .waveform2_select(wave2_sel), 
	 .mix_percent(mix_percent),
	 .octave(octave),
    .audio_out(raw_audio)
);

envelope_generator EnvGen (
    .clk           (CLOCK_50),
    .resetn        (KEY[0]),
    .gate          (any_key_down),
    .attack_time   (attack_time),     // from synth_controls
    .sustain_level (sustain_level),
    .release_time  (release_time),
    .env           (env_level)
);




wire signed [15:0] raw_audio_s  = raw_audio;
wire signed [31:0] env_product  = raw_audio_s * env_level;

assign audio_out = env_product[31:16];  // top 16 bits
assign LEDR[0] = any_key_down;
assign LEDR[4:1] = env_level[15:12];
assign LEDR[9:5] = 5'b0;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

PS2_Controller PS2 (
    .CLOCK_50           (CLOCK_50),
    .reset              (~KEY[0]),

    .PS2_CLK            (PS2_CLK),
    .PS2_DAT            (PS2_DAT),

    .received_data      (ps2_key_data),
    .received_data_en   (ps2_key_pressed)
);

endmodule
