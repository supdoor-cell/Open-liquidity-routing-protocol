
            #!/usr/bin/env python3
# ============================================================================
# TITLE:       PRIME PARADIGM AUTOMATED INGESTION DISPATCH MATRIX
# VERSION:     1.1.0
# PLATFORM:    Hardware-Emulated Time-Slicing Registry Core
# SECURITY:    Continuous Standard-Deviation Telemetry Verification
# FIXES:       - process_telemetry_packet() called with keyword args (volume=,
#                latency_ns=) in __main__ but the signature used positional
#                param name 'inbound_signal_bytes' — unified to 'volume_usd'
#              - statistics.stdev() raises StatisticsError with < 2 samples;
#                guard added so cold-start never crashes
#              - latency_history seeded with 50 identical values making initial
#                stdev = 0, causing ZeroDivisionError — resolved by adding
#                tiny jitter on init
#              - JSON key 'active_network_dimensions' renamed to
#                'active_sovereign_nodes' to match dashboard contract
#              - system_state typo "DIVERTHOD" corrected to "DIVERTED"
#              - History window capped to 200 samples (was 100) for better
#                rolling baseline accuracy
# ============================================================================

import json
import statistics
import time
from typing import Optional


class TemporalIngestionSentinel:
    """
    Real-time anomaly detector for inbound clearing-network packets.

    Every packet's latency is compared against a rolling baseline using a
    Z-score test.  Packets that deviate beyond *stability_threshold_sigma*
    are routed to the ghost-matrix honeypot instead of the live hypergraph.
    """

    HISTORY_WINDOW      = 200   # rolling sample window size
    MIN_HISTORY_SAMPLES = 2     # minimum samples before Z-score is meaningful

    def __init__(self, stability_threshold_sigma: float = 4.5) -> None:
        self.stability_threshold_sigma = stability_threshold_sigma
        # Seed with slight jitter so stdev > 0 from the very first packet
        import random
        self._rng = random.Random(42)
        self.latency_history: list[float] = [
            850.0 + self._rng.uniform(-5.0, 5.0)
            for _ in range(50)
        ]

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def process_telemetry_packet(
        self, volume_usd: float, latency_ns: float
    ) -> str:
        """
        Evaluate one inbound packet.

        Args:
            volume_usd:  Settlement value carried by this packet (USD).
            latency_ns:  Measured ingestion latency in nanoseconds.

        Returns:
            JSON string — either a NOMINAL or DIVERTED telemetry payload.
        """
        z_score = self._compute_z_score(latency_ns)

        if z_score is not None and abs(z_score) > self.stability_threshold_sigma:
            print(
                f"[GUARD] Anomaly flagged (Z={z_score:.2f}, "
                f"latency={latency_ns:.0f} ns). "
                "Activating Ghost Matrix Routing."
            )
            return self._build_payload(volume_usd=0.0, diverted=True)

        # Clean packet — update rolling history
        self.latency_history.append(float(latency_ns))
        if len(self.latency_history) > self.HISTORY_WINDOW:
            self.latency_history.pop(0)

        return self._build_payload(volume_usd=volume_usd, diverted=False)

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _compute_z_score(self, latency_ns: float) -> Optional[float]:
        """Return Z-score of *latency_ns* against rolling history, or None."""
        if len(self.latency_history) < self.MIN_HISTORY_SAMPLES:
            return None
        try:
            mean  = statistics.mean(self.latency_history)
            stdev = statistics.stdev(self.latency_history)
        except statistics.StatisticsError:
            return None

        if stdev == 0:
            return None
        return (latency_ns - mean) / stdev

    @staticmethod
    def _build_payload(volume_usd: float, diverted: bool) -> str:
        """Serialise a telemetry event into an anonymous public JSON packet."""
        payload = {
            "epoch_timestamp": int(time.time()),
            "system_state":    "DIVERTED" if diverted else "NOMINAL",
            "telemetry_metrics": {
                "active_sovereign_nodes":      10_000,
                "real_time_liquidity_freed_usd": float(volume_usd),
                "platform_extracted_yield_usd":  float(volume_usd * 0.00005),
            },
        }
        return json.dumps(payload, indent=2)


# ---------------------------------------------------------------------------
# Smoke-test
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    sentinel = TemporalIngestionSentinel()

    print("--- Test 1: clean low-latency packet ---")
    print(sentinel.process_telemetry_packet(volume_usd=85_000_000, latency_ns=860))

    print("\n--- Test 2: high-drift attack vector (should be diverted) ---")
    print(sentinel.process_telemetry_packet(volume_usd=999_000_000, latency_ns=450_000))
    
