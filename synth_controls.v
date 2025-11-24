module synth_controls #(
    parameter OCTAVE_MIN    = 1,
    parameter OCTAVE_MAX    = 7,
    parameter OCTAVE_INIT   = 3,
    parameter MIX_STEP      = 7'd5,     // 5% step size for mix
    parameter ASR_STEP      = 7'd5      // 5% step size for ASR parameters (0-100)
)(
    input  wire         clk,
    input  wire         reset_n,        // active-low reset (KEY[0] is typically active-low in DE2)
    input  wire [255:0] key_down,       // from PS2_Main

    output reg  [3:0]   octave,         // 1..7
    output reg  [1:0]   wave1_sel,      // 0..3
    output reg  [1:0]   wave2_sel,      // 0..3
    output reg  [6:0]   mix_percent,    // 0..100
    output reg  [6:0]   attack_time,    // 0..100 (Arbitrary scaling for control)
    output reg  [6:0]   sustain_level,  // 0..100 (Arbitrary scaling for control)
    output reg  [6:0]   release_time    // 0..100 (Arbitrary scaling for control)
);

    // ---------- Scan codes (Set 2) ----------
    localparam [7:0] SC_Z        = 8'h1A;
    localparam [7:0] SC_X        = 8'h22;
    localparam [7:0] SC_UP       = 8'h75;
    localparam [7:0] SC_DOWN     = 8'h72;
    localparam [7:0] SC_LEFT     = 8'h6B;
    localparam [7:0] SC_RIGHT    = 8'h74;
    localparam [7:0] SC_MINUS    = 8'h4E; // '-' key (main row)
    localparam [7:0] SC_EQUAL    = 8'h55; // '=' key (shifted is '+')

    // ASR Control Keys
    localparam [7:0] SC_ATKUP    = 8'h70; 
    localparam [7:0] SC_ATKDOWN  = 8'h71; 
    localparam [7:0] SC_SUSUP    = 8'h6C; 
    localparam [7:0] SC_SUSDOWN  = 8'h69; 
    localparam [7:0] SC_RELUP    = 8'h7D; 
    localparam [7:0] SC_RELDOWN  = 8'h7A; 


    // Current level of each control key
    wire z_now       = key_down[SC_Z];
    wire x_now       = key_down[SC_X];
    wire up_now      = key_down[SC_UP];
    wire down_now    = key_down[SC_DOWN];
    wire left_now    = key_down[SC_LEFT];
    wire right_now   = key_down[SC_RIGHT];
    wire minus_now   = key_down[SC_MINUS];
    wire equal_now   = key_down[SC_EQUAL];
    wire atkup_now   = key_down[SC_ATKUP];
    wire atkdown_now = key_down[SC_ATKDOWN];
    wire susup_now   = key_down[SC_SUSUP];
    wire susdown_now = key_down[SC_SUSDOWN];
    wire relup_now   = key_down[SC_RELUP];
    wire reldown_now = key_down[SC_RELDOWN];

    // Previous state for edge detection
    reg prev_z, prev_x, prev_up, prev_down; //for wave mixer
    reg prev_left, prev_right, prev_minus, prev_equal; //for wave mixer
    reg prev_atkup, prev_atkdown, prev_susup, prev_susdown, prev_relup, prev_reldown; // Added ASR previous states

    // One-clock pulses on rising edges (key press)
    wire z_press       = z_now       & ~prev_z;
    wire x_press       = x_now       & ~prev_x;
    wire up_press      = up_now      & ~prev_up;
    wire down_press    = down_now    & ~prev_down;
    wire left_press    = left_now    & ~prev_left;
    wire right_press   = right_now   & ~prev_right;
    wire minus_press   = minus_now   & ~prev_minus;
    wire equal_press   = equal_now   & ~prev_equal;
    wire atkup_press   = atkup_now   & ~prev_atkup;
    wire atkdown_press = atkdown_now & ~prev_atkdown;
    wire susup_press   = susup_now   & ~prev_susup;
    wire susdown_press = susdown_now & ~prev_susdown;
    wire relup_press   = relup_now   & ~prev_relup;
    wire reldown_press = reldown_now & ~prev_reldown;

    // ---------- Sequential logic ----------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Initial state for Synth Parameters
            octave      <= OCTAVE_INIT[3:0];
            wave1_sel   <= 2'b00;    // start with waveform 0 for both
            wave2_sel   <= 2'b00;
            mix_percent <= 7'd50;    // 50/50 mix
            
            // Initial state for ASR Parameters (e.g., fast attack, full sustain, fast release)
            attack_time   <= 7'd00;  // 0%
            sustain_level <= 7'd90;  // 100%
            release_time  <= 7'd00;  // 0%

            // Initialize previous key states
            prev_z      <= 1'b0;
            prev_x      <= 1'b0;
            prev_up     <= 1'b0;
            prev_down   <= 1'b0;
            prev_left   <= 1'b0;
            prev_right  <= 1'b0;
            prev_minus  <= 1'b0;
            prev_equal  <= 1'b0;
            prev_atkup  <= 1'b0;    // Initialize ASR prev states
            prev_atkdown<= 1'b0;
            prev_susup  <= 1'b0;
            prev_susdown<= 1'b0;
            prev_relup  <= 1'b0;
            prev_reldown<= 1'b0;

        end else begin
            // Update previous key states
            prev_z      <= z_now;
            prev_x      <= x_now;
            prev_up     <= up_now;
            prev_down   <= down_now;
            prev_left   <= left_now;
            prev_right  <= right_now;
            prev_minus  <= minus_now;
            prev_equal  <= equal_now;
            prev_atkup  <= atkup_now;    // Update ASR prev states
            prev_atkdown<= atkdown_now;
            prev_susup  <= susup_now;
            prev_susdown<= susdown_now;
            prev_relup  <= relup_now;
            prev_reldown<= reldown_now;

            // ---- Octave control (Z / X) ----
            if (z_press && octave > OCTAVE_MIN[3:0])
                octave <= octave - 1'b1;

            if (x_press && octave < OCTAVE_MAX[3:0])
                octave <= octave + 1'b1;

            // ---- Wave 1 selection (Up / Down) ----
            if (up_press) begin
                wave1_sel <= wave1_sel + 1'b1; // wraps naturally 0..3
            end
            if (down_press) begin
                wave1_sel <= wave1_sel - 1'b1; // wraps naturally 0..3
            end

            // ---- Wave 2 selection (Right / Left) ----
            if (right_press) begin
                wave2_sel <= wave2_sel + 1'b1;
            end
            if (left_press) begin
                wave2_sel <= wave2_sel - 1'b1;
            end

            // ---- Mix percentage ( '+' / '-' ) ----
            if (equal_press) begin
                if (mix_percent <= (7'd100 - MIX_STEP))
                    mix_percent <= mix_percent + MIX_STEP;
                else
                    mix_percent <= 7'd100;    // clamp
            end
            if (minus_press) begin
                if (mix_percent >= MIX_STEP)
                    mix_percent <= mix_percent - MIX_STEP;
                else
                    mix_percent <= 7'd0;      // clamp
            end
            
            // ---- Attack Time Control (SC_ATKUP / SC_ATKDOWN) ----
            if (atkup_press) begin
                if (attack_time <= (7'd100 - ASR_STEP))
                    attack_time <= attack_time + ASR_STEP;
                else
                    attack_time <= 7'd100;
            end
            if (atkdown_press) begin
                if (attack_time >= ASR_STEP)
                    attack_time <= attack_time - ASR_STEP;
                else
                    attack_time <= 7'd0;
            end

            // ---- Sustain Level Control (SC_SUSUP / SC_SUSDOWN) ----
            if (susup_press) begin
                if (sustain_level <= (7'd100 - ASR_STEP))
                    sustain_level <= sustain_level + ASR_STEP;
                else
                    sustain_level <= 7'd100;
            end
            if (susdown_press) begin
                if (sustain_level >= ASR_STEP)
                    sustain_level <= sustain_level - ASR_STEP;
                else
                    sustain_level <= 7'd0;
            end

            // ---- Release Time Control (SC_RELUP / SC_RELDOWN) ----
            if (relup_press) begin
                if (release_time <= (7'd100 - ASR_STEP))
                    release_time <= release_time + ASR_STEP;
                else
                    release_time <= 7'd100;
            end
            if (reldown_press) begin
                if (release_time >= ASR_STEP)
                    release_time <= release_time - ASR_STEP;
                else
                    release_time <= 7'd0;
            end
        end
    end

endmodule