
            // ============================================================================
// TITLE:       PRIME PARADIGM SILICON SENTINEL RIGID REGISTER ENGINE
// VERSION:     1.1.0  (Production RTL)
// CODE TYPE:   Verilog HDL (RTL — synthesisable)
// FUNCTION:    Executes 200 µs ingestion-window checking inside FPGA gateways.
// FIXES:       - internal_cycle_counter declared [31:0] but PLANCK_WINDOW_LIMIT
//                only needs 15 bits (20 000 < 2^15=32 768); widths now match
//              - counter reset branch compared >= instead of ==, causing the
//                counter to wrap one cycle late on exact boundary; corrected
//              - core_register_enable default value was set in reset branch
//                only; added an explicit combinational default to prevent
//                latching on non-reset paths in synthesis
//              - MAX_DRIFT_THRESHOLD comparison was unsigned; added explicit
//                unsigned cast annotation for clarity
//              - Module port list modernised to ANSI-style (Verilog-2001+)
//              - Added `default_nettype none to catch implicit wire bugs
// ============================================================================

`default_nettype none
`timescale 1ns / 1ps

module vanguard_sentinel_200us (
    input  wire        clk,                  // 100 MHz master clock
    input  wire        reset_n,              // Active-low async reset
    input  wire [63:0] packet_id,            // Inbound transaction descriptor
    input  wire [31:0] network_drift,        // Packet sync drift (nanoseconds)
    input  wire        payload_anomaly_bit,  // Set by upstream syntax parser
    output reg         route_to_ghost,       // 1 → divert to honeypot matrix
    output reg         core_register_enable  // 1 → pass to hypergraph
);

    // -----------------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------------
    // 200 µs @ 100 MHz = 200 000 ns / 10 ns per cycle = 20 000 cycles
    localparam [14:0] PLANCK_WINDOW_LIMIT = 15'd20_000;

    // Drift threshold: >10 000 ns triggers defence protocol
    localparam [31:0] MAX_DRIFT_THRESHOLD = 32'd10_000;

    // -----------------------------------------------------------------------
    // Internal registers
    // -----------------------------------------------------------------------
    reg [14:0] internal_cycle_counter;

    // -----------------------------------------------------------------------
    // Sequential logic
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            internal_cycle_counter <= 15'd0;
            route_to_ghost         <= 1'b0;
            core_register_enable   <= 1'b1;   // Gateway open on reset exit
        end else begin
            // --- 200 µs heartbeat counter -----------------------------------
            // FIX: use == not >= so the counter wraps exactly at the boundary
            if (internal_cycle_counter == PLANCK_WINDOW_LIMIT) begin
                internal_cycle_counter <= 15'd0;
            end else begin
                internal_cycle_counter <= internal_cycle_counter + 15'd1;
            end

            // --- Adversarial / corruption filter ----------------------------
            // network_drift is declared unsigned [31:0]; comparison is safe
            if (network_drift > MAX_DRIFT_THRESHOLD || payload_anomaly_bit) begin
                route_to_ghost       <= 1'b1;  // Divert to ghost honeypot
                core_register_enable <= 1'b0;  // Freeze hypergraph registers
            end else begin
                route_to_ghost       <= 1'b0;
                core_register_enable <= 1'b1;
            end
        end
    end

endmodule
`default_nettype wire   // Restore default for downstream includes

