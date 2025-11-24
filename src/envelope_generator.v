// Global ASR envelope generator
// attack_time, sustain_level, release_time: 0..100 (decimal)
// Each unit of attack/release_time = 10 ms
// Sustain_level = % volume (0..100)
//
// If attack_time = 50 -> attack â‰ˆ 500 ms
// If release_time = 20 -> release â‰ˆ 200 ms
//
// env is a 16-bit scale factor to multiply with your mixed audio.
module envelope_generator (
    input        clk,            // 50 MHz
    input        resetn,         // active-low
    input        gate,           // 1 when ANY key is down (|key_down)

    input  [6:0] attack_time,    // 0..100 (Ã—10 ms)
    input  [6:0] sustain_level,  // 0..100 (%)
    input  [6:0] release_time,   // 0..100 (Ã—10 ms)

    output reg [15:0] env        // 0..65535
);

    // ------------------------------------------------------------
    // 1 kHz envelope tick: 50 MHz / 50_000 = 1 kHz
    // ------------------------------------------------------------
    localparam integer ENV_DIV = 50000;
    reg [15:0] div_cnt;
    reg        env_tick;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            div_cnt  <= 16'd0;
            env_tick <= 1'b0;
        end else begin
            if (div_cnt == ENV_DIV - 1) begin
                div_cnt  <= 16'd0;
                env_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 16'd1;
                env_tick <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------
    localparam S_IDLE    = 2'd0;
    localparam S_ATTACK  = 2'd1;
    localparam S_SUSTAIN = 2'd2;
    localparam S_RELEASE = 2'd3;

    reg [1:0] state;

    // Gate edges
    reg gate_d;
    wire gate_rise =  gate & ~gate_d;
    wire gate_fall = ~gate &  gate_d;

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            gate_d <= 1'b0;
        else
            gate_d <= gate;
    end

	 
	 reg [15:0] attack_step;
    reg [15:0] release_step;

    // Clamp inputs to 0..100
    wire [6:0] atk = (attack_time   > 7'd100) ? 7'd100 : attack_time;
    wire [6:0] sus = (sustain_level > 7'd100) ? 7'd100 : sustain_level;
    wire [6:0] rel = (release_time  > 7'd100) ? 7'd100 : release_time;
	 wire [16:0] env_plus_attack = {1'b0, env} + {1'b0, attack_step};

    // Sustain: 0..100 â†’ 0..65535
    // 65535 / 100 â‰ˆ 655
    wire [15:0] sustain_amp = sus * 16'd655;

    // ------------------------------------------------------------
    // Compute attack_step and release_step
    //
    // env updates at 1 kHz (1 ms per step).
    // We want 0 -> 65535 in atk*10 ms.
    // Samples = atk*10  => step â‰ˆ 65535 / (atk*10) = 6553 / atk
    // Same idea for release.
    // ------------------------------------------------------------
   
    always @(*) begin
        if (atk == 7'd0)
            attack_step = 16'hFFFF;         // instant attack
        else
            attack_step = 16'd6553 / atk;   // approx 0..1000 ms

        if (rel == 7'd0)
            release_step = 16'hFFFF;        // instant release
        else
            release_step = 16'd6553 / rel;
    end

    // ------------------------------------------------------------
    // Envelope update
    // ------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        state <= S_IDLE;
        env   <= 16'd0;

    end else if (env_tick) begin
        case (state)

            //------------------------------------------------------------------
            // IDLE — no keys pressed
            //------------------------------------------------------------------
            S_IDLE: begin
                env <= 16'd0;

                if (gate) begin
                    // Start attack immediately
                    if (atk == 7'd0) begin
                        env   <= 16'hFFFF;
                        state <= S_SUSTAIN;
                    end else begin
                        state <= S_ATTACK;
                    end
                end
            end

            //------------------------------------------------------------------
            // ATTACK — ramp up toward full scale
            //------------------------------------------------------------------
            S_ATTACK: begin
                if (!gate) begin
                    // Released during attack → go to release or idle
                    if (rel == 7'd0) begin
                        env   <= 16'd0;
                        state <= S_IDLE;
                    end else begin
                        state <= S_RELEASE;
                    end

                end else begin
                    // Overflow-safe ramp
                    if (env_plus_attack >= 17'h1_0000) begin
                        env   <= 16'hFFFF;
                        state <= S_SUSTAIN;
                    end else begin
                        env <= env_plus_attack[15:0];
                    end
                end
            end

            //------------------------------------------------------------------
            // SUSTAIN — hold sustain level while gate = 1
            //------------------------------------------------------------------
            S_SUSTAIN: begin
                env <= sustain_amp;

                if (!gate) begin
                    // All notes released → go to release or idle
                    if (rel == 7'd0) begin
                        env   <= 16'd0;
                        state <= S_IDLE;
                    end else begin
                        state <= S_RELEASE;
                    end
                end
            end

            //------------------------------------------------------------------
            // RELEASE — fade down when last note is released
            //------------------------------------------------------------------
            S_RELEASE: begin
                if (gate) begin
                    // New key pressed during release → retrigger attack
                    if (atk == 7'd0) begin
                        env   <= 16'hFFFF;
                        state <= S_SUSTAIN;
                    end else begin
                        state <= S_ATTACK;
                    end

                end else if (env <= release_step) begin
                    env   <= 16'd0;
                    state <= S_IDLE;

                end else begin
                    env <= env - release_step;
                end
            end

            //------------------------------------------------------------------
            default: begin
                state <= S_IDLE;
                env   <= 16'd0;
            end
        endcase
    end
end

endmodule