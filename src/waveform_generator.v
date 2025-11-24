module waveform_generator (
    input  wire        CLOCK_50,          // core timing
    input  wire        resetn,            // async active-low reset. Used to reset all counts
    input  wire [3:0]  voice_count,       // number of active voices (0..3)
    input  wire [23:0] ticks0_in,            // pitch of note 1 (ticksPerSample)
    input  wire [23:0] ticks1_in,            // pitch of note 2 (ticksPerSample)
    input  wire [23:0] ticks2_in,            // pitch of note 3 (ticksPerSample)
    input  wire [1:0]  waveform1_select,  // 00=sine, 01=saw, 10=tri, 11=square
    input  wire [1:0]  waveform2_select,  // second waveform for mixing
	 input  wire [6:0]  mix_percent,
	 input wire [3:0] octave,
    output wire [15:0] audio_out          // mixed output sample
);
	//octave change
reg [23:0] ticks0, ticks1, ticks2;
always @(*) begin		
	case (octave)
		4'd1: begin
			ticks0 = ticks0_in << 2;
			ticks1 = ticks1_in << 2;
			ticks2 = ticks2_in << 2;
		end
		4'd2: begin
			ticks0 = ticks0_in << 1;
			ticks1 = ticks1_in << 1;
			ticks2 = ticks2_in << 1;
		end
		4'd3: begin
			ticks0 = ticks0_in;
			ticks1 = ticks1_in;
			ticks2 = ticks2_in;
		end

		4'd4: begin
			ticks0 = ticks0_in >> 1;
			ticks1 = ticks1_in >> 1;
			ticks2 = ticks2_in >> 1;
		end

		4'd5: begin
			ticks0 = ticks0_in >> 2;
			ticks1 = ticks1_in >> 2;
			ticks2 = ticks2_in >> 2;
		end
		4'd6: begin
			ticks0 = ticks0_in >> 3;
			ticks1 = ticks1_in >> 3;
			ticks2 = ticks2_in >> 3;
		end
		4'd7: begin
			ticks0 = ticks0_in >> 4;
			ticks1 = ticks1_in >> 4;
			ticks2 = ticks2_in >> 4;
		end
	endcase	
end		
		
		

    // Per-voice tick counters and phase indices 
    reg [23:0] tickcnt0, tickcnt1, tickcnt2;
    reg [7:0]  phase0,   phase1,   phase2;

    // Voice 0 phase/tick update
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            tickcnt0 <= 24'd0;
            phase0   <= 8'd0;
        end else begin
            if (voice_count > 0 && ticks0 != 24'd0) begin
                if (tickcnt0 == 24'd0) begin
                    tickcnt0 <= ticks0;
                    phase0   <= phase0 + 8'd1;
                end else begin
                    tickcnt0 <= tickcnt0 - 24'd1;
                end
            end else begin
                tickcnt0 <= 24'd0;
            end
        end
    end

    // Voice 1 phase/tick update
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            tickcnt1 <= 24'd0;
            phase1   <= 8'd0;
        end else begin
            if (voice_count > 1 && ticks1 != 24'd0) begin
                if (tickcnt1 == 24'd0) begin
                    tickcnt1 <= ticks1;
                    phase1   <= phase1 + 8'd1;
                end else begin
                    tickcnt1 <= tickcnt1 - 24'd1;
                end
            end else begin
                tickcnt1 <= 24'd0;
            end
        end
    end

    // Voice 2 phase/tick update
    always @(posedge CLOCK_50 or negedge resetn) begin
        if (!resetn) begin
            tickcnt2 <= 24'd0;
            phase2   <= 8'd0;
        end else begin
            if (voice_count > 2 && ticks2 != 24'd0) begin
                if (tickcnt2 == 24'd0) begin
                    tickcnt2 <= ticks2;
                    phase2   <= phase2 + 8'd1;
                end else begin
                    tickcnt2 <= tickcnt2 - 24'd1;
                end
            end else begin
                tickcnt2 <= 24'd0;
            end
        end
    end
// Helper function: given a phase and waveform selection, output a 12-bit sample
	function [11:0] waveform_sample;
		 input [7:0] phase;
		 input [1:0] sel;
		 reg   [11:0] saw, tri_wave, square, pulse;
		 begin
			  // Simple sawtooth (unsigned)
			  saw = {phase, 4'b0000};

			  // Simple triangle wave (unsigned)
			  if (phase[7] == 1'b0)
					tri_wave = {phase, 4'b0000};
			  else
					tri_wave = {~phase, 4'b0000};

			  // Simple square wave (50% duty)
			  square = phase[7] ? 12'hFFF : 12'h000;

			  // Pulse wave with ~25% duty cycle:
			  // high for phase < 64 (256 * 0.25), low otherwise
			  if (phase < 8'd64)
					pulse = 12'hFFF;
			  else
					pulse = 12'h000;

			  case (sel)
					2'b00: waveform_sample = saw;      // saw 00
					2'b01: waveform_sample = pulse;    // pulse 01
					2'b10: waveform_sample = tri_wave; // triangle 10
					2'b11: waveform_sample = square;   // square 11
					default: waveform_sample = 12'd0;
			  endcase
		 end
	endfunction


    // Per-voice samples for each of the two selected waveforms
    wire [11:0] v0_w1 = waveform_sample(phase0, waveform1_select);
    wire [11:0] v0_w2 = waveform_sample(phase0, waveform2_select);
    wire [11:0] v1_w1 = waveform_sample(phase1, waveform1_select);
    wire [11:0] v1_w2 = waveform_sample(phase1, waveform2_select);
    wire [11:0] v2_w1 = waveform_sample(phase2, waveform1_select);
    wire [11:0] v2_w2 = waveform_sample(phase2, waveform2_select);
	 

	 
	 
	 
	 
	localparam[6:0] MIX_MAX = 7'd100;
	 

	wire [6:0] mix_a = mix_percent;               // weight for wave2
	wire [6:0] mix_b = MIX_MAX - mix_percent;     // weight for wave1

	// Voice 0:

	wire [18:0] v0_mul1 = v0_w1 * mix_b;       
	wire [18:0] v0_mul2 = v0_w2 * mix_a;
	wire [18:0] v0_sum  = v0_mul1 + v0_mul2;

	wire [11:0] v0_mix  = v0_sum / MIX_MAX;       // final mixed sample for voice 0

	// Voice 1:

	wire [18:0] v1_mul1 = v1_w1 * mix_b;
	wire [18:0] v1_mul2 = v1_w2 * mix_a;
	wire [18:0] v1_sum  = v1_mul1 + v1_mul2;

	wire [11:0] v1_mix  = v1_sum / MIX_MAX; // final mixed sample for voice 1

	// Voice 2:

	wire [18:0] v2_mul1 = v2_w1 * mix_b;
	wire [18:0] v2_mul2 = v2_w2 * mix_a;
	wire [18:0] v2_sum  = v2_mul1 + v2_mul2;

	wire [11:0] v2_mix  = v2_sum / MIX_MAX; // final mixed sample for voice 2
		 
	 
	 
	 
	 
	 
	 
	 
    // Mix the two waveforms per voice by averaging
    /*wire [12:0] v0_mix = (v0_w1 + v0_w2) >> 1;
    wire [12:0] v1_mix = (v1_w1 + v1_w2) >> 1;
    wire [12:0] v2_mix = (v2_w1 + v2_w2) >> 1;
	 */

    // Clip/truncate to 12 bits for output stages
    wire [11:0] v0_out  = v0_mix[11:0];
    wire [11:0] v01_out = (v0_mix + v1_mix) / 2;           // average of two voices
    wire [11:0] v012_out = (v0_mix + v1_mix + v2_mix) / 3;  // average of three voices

    reg [15:0] audio_reg;
    always @* begin
        case (voice_count)
            4'd0: audio_reg = 16'd0;
            4'd1: audio_reg = {4'd0, v0_out};     // single voice
            4'd2: audio_reg = {4'd0, v01_out};    // average of two
            default: audio_reg = {4'd0, v012_out}; // average of three
        endcase
    end

    assign audio_out = audio_reg;

endmodule
