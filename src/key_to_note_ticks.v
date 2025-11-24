module key_to_note_ticks (
    input  wire [255:0] key_down,     // key matrix from PS2
    output reg  [3:0]   voice_count,  // 0,1,2,3 notes
    output reg  [6:0]   seg0,
    output reg  [6:0]   seg1,
    output reg  [6:0]   seg2,
    output reg  [23:0]  ticks0,       // note 1 pitch
    output reg  [23:0]  ticks1,       // note 2 pitch
    output reg  [23:0]  ticks2        // note 3 pitch
);

    /*************************************************************************
     *  SCAN CODES (PS/2 Set 2) – ONE OCTAVE (C3 → B3)
     *************************************************************************/
    localparam SC_A = 8'h1C; // C3
    localparam SC_W = 8'h1D; // C#3
    localparam SC_S = 8'h1B; // D3
    localparam SC_E = 8'h24; // D#3
    localparam SC_D = 8'h23; // E3
    localparam SC_F = 8'h2B; // F3
    localparam SC_T = 8'h2C; // F#3
    localparam SC_G = 8'h34; // G3
    localparam SC_Y = 8'h35; // G#3
    localparam SC_H = 8'h33; // A3
    localparam SC_U = 8'h3C; // A#3
    localparam SC_J = 8'h3B; // B3
	 localparam SC_K = 8'h42; //C4
	 localparam SC_O = 8'h44; //C#4
 	 localparam SC_L = 8'h4B; //D4
 	 localparam SC_P = 8'h4D; //D#4
    localparam SC_M = 8'h4C; //E4	
	 
	 

    /*************************************************************************
     *  7-SEGMENT GLYPHS (active-low)
     *************************************************************************/
    localparam [6:0] GLF_BLANK = 7'b1111111;
    localparam [6:0] GLF_A     = 7'b0001000;
    localparam [6:0] GLF_b     = 7'b0000011;
    localparam [6:0] GLF_C     = 7'b1000110;
    localparam [6:0] GLF_d     = 7'b0100001;
    localparam [6:0] GLF_E     = 7'b0000110;
    localparam [6:0] GLF_F     = 7'b0001110;
    localparam [6:0] GLF_G     = 7'b0000010;

    /*************************************************************************
     *  NOTE → TICK VALUES (for 50 MHz clock, 256 samples per cycle) t = (freq x 256) / 48000
     *************************************************************************/
    localparam [23:0] T_C3   = 24'd1493;  // 130.81 Hz
    localparam [23:0] T_CS3  = 24'd1409;  // 138.59
    localparam [23:0] T_D3   = 24'd1330;  // 146.83
    localparam [23:0] T_DS3  = 24'd1256;  // 155.56
    localparam [23:0] T_E3   = 24'd1185;  // 164.81
    localparam [23:0] T_F3   = 24'd1119;  // 174.61
    localparam [23:0] T_FS3  = 24'd1056;  // 185.00
    localparam [23:0] T_G3   = 24'd996;   // 196.00
    localparam [23:0] T_GS3  = 24'd941;   // 207.65
    localparam [23:0] T_A3   = 24'd888;   // 220.00
    localparam [23:0] T_AS3  = 24'd838;   // 233.08
    localparam [23:0] T_B3   = 24'd791;   // 246.94
	 localparam [23:0] T_C4   = 24'd747;  // 261.63
    localparam [23:0] T_CS4  = 24'd705;  // 277.18
    localparam [23:0] T_D4   = 24'd665;  // 293.66
    localparam [23:0] T_DS4  = 24'd628;  // 311.13
    localparam [23:0] T_E4   = 24'd593;  // 329.63

    /*************************************************************************
     *  ADD NOTE TASK
     *************************************************************************/
    task add_note;
        input [6:0]  glyph;
        input [23:0] ticks;

        begin
            if (voice_count == 0) begin
                seg0   = glyph;
                ticks0 = ticks;
            end else if (voice_count == 1) begin
                seg1   = glyph;
                ticks1 = ticks;
            end else if (voice_count == 2) begin
                seg2   = glyph;
                ticks2 = ticks;
            end
            voice_count = voice_count + 4'd1;
        end
    endtask

    /*************************************************************************
     *  MAIN COMBINATIONAL LOGIC
     *************************************************************************/
    always @* begin
        voice_count = 0;

        seg0 = GLF_BLANK;
        seg1 = GLF_BLANK;
        seg2 = GLF_BLANK;

        ticks0 = 24'd0;
        ticks1 = 24'd0;
        ticks2 = 24'd0;

        // C3
        if (voice_count < 3 && key_down[SC_A]) add_note(GLF_C, T_C3);
        // C#3
        if (voice_count < 3 && key_down[SC_W]) add_note(GLF_C, T_CS3);
        // D3
        if (voice_count < 3 && key_down[SC_S]) add_note(GLF_d, T_D3);
        // D#3
        if (voice_count < 3 && key_down[SC_E]) add_note(GLF_d, T_DS3);
        // E3
        if (voice_count < 3 && key_down[SC_D]) add_note(GLF_E, T_E3);
        // F3
        if (voice_count < 3 && key_down[SC_F]) add_note(GLF_F, T_F3);
        // F#3
        if (voice_count < 3 && key_down[SC_T]) add_note(GLF_F, T_FS3);
        // G3
        if (voice_count < 3 && key_down[SC_G]) add_note(GLF_G, T_G3);
        // G#3
        if (voice_count < 3 && key_down[SC_Y]) add_note(GLF_G, T_GS3);
        // A3
        if (voice_count < 3 && key_down[SC_H]) add_note(GLF_A, T_A3);
        // A#3
        if (voice_count < 3 && key_down[SC_U]) add_note(GLF_A, T_AS3);
        // B3
        if (voice_count < 3 && key_down[SC_J]) add_note(GLF_b, T_B3);
		  // C4
        if (voice_count < 3 && key_down[SC_K]) add_note(GLF_C, T_C4);
		  // C#4
        if (voice_count < 3 && key_down[SC_O]) add_note(GLF_b, T_CS4);
		  // D4
        if (voice_count < 3 && key_down[SC_L]) add_note(GLF_b, T_D4);
		  // D#4
        if (voice_count < 3 && key_down[SC_P]) add_note(GLF_b, T_DS4);
		  // E4
        if (voice_count < 3 && key_down[SC_M]) add_note(GLF_b, T_E4);
    end

endmodule