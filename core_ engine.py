    #!/usr/bin/env python3
# ============================================================================
# TITLE:       PRIME PARADIGM — MASTER CLEARING PIPELINE
# VERSION:     1.0.0
# FUNCTION:    Wires ISO 20022 parser → ZK commitment → ingestion sentinel
#              → telemetry export into a single end-to-end clearing cycle.
# ============================================================================

import json

from prime_paradigm.iso20022_parser    import ISO20022HighIQParser
from prime_paradigm.zk_proof_bridge    import ZKProofBridge
from prime_paradigm.ingestion_sentinel import TemporalIngestionSentinel
from prime_paradigm.telemetry_exporter import TelemetryExporter


def run_clearing_cycle(raw_payment: dict, simulated_latency_ns: float) -> None:
    """
    Execute one end-to-end clearing cycle:

    1. Parse the ISO 20022 payment message.
    2. Commit the debtor/creditor pair to the ZK shadow map.
    3. Route the packet through the ingestion sentinel.
    4. Publish anonymised telemetry.
    """

    print("=" * 60)
    print("STEP 1 — ISO 20022 parsing")
    print("=" * 60)
    parser     = ISO20022HighIQParser()
    vector     = parser.translate_xml_to_tensor_coordinates(raw_payment)
    if "error" in vector:
        print(f"[ERROR] Parser rejected message: {vector['error']}")
        return
    print(json.dumps(vector, indent=2))

    print("\n" + "=" * 60)
    print("STEP 2 — Zero-Knowledge commitment")
    print("=" * 60)
    zk        = ZKProofBridge()
    node_tag  = f"DEBTOR_{vector['debtor_index']}_CREDITOR_{vector['creditor_index']}"
    token     = zk.commit(node_tag, vector["liability_magnitude"])
    print(f"  Node tag : {node_tag}")
    print(f"  ZK token : {token[:32]}...[MASKED]")
    verified  = zk.verify(token, node_tag, vector["liability_magnitude"])
    print(f"  Verified : {verified}")

    print("\n" + "=" * 60)
    print("STEP 3 — Ingestion sentinel routing")
    print("=" * 60)
    sentinel  = TemporalIngestionSentinel()
    routing   = sentinel.process_telemetry_packet(
                    volume_usd=vector["liability_magnitude"],
                    latency_ns=simulated_latency_ns,
                )
    print(routing)

    routing_state = json.loads(routing)["system_state"]

    print("\n" + "=" * 60)
    print("STEP 4 — Public telemetry export")
    print("=" * 60)
    if routing_state == "NOMINAL":
        exporter  = TelemetryExporter(rng_seed=1)
        telemetry = exporter.serialize_public_dashboard_metrics(
                        cleared_volume_usd=vector["liability_magnitude"]
                    )
        print(telemetry)
    else:
        print("[INFO] Packet was diverted — no public telemetry emitted for this cycle.")


# ---------------------------------------------------------------------------
# Demo
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    sample_payment = {
        "Document": {
            "FIToFICstmrCdtTrf": {
                "GrpHdr": {"MsgId": "PRIME-SWIFT-2026-M49X"},
                "CdtTrfTxInf": {
                    "Dbtr": {"Id": "104"},
                    "Cdtr": {"Id": "892"},
                    "IntrBkSttlmAmt": {"Value": "14500000.00", "Ccy": "USD"},
                },
            }
        }
    }

    print("\n>>> CLEAN PACKET (latency = 860 ns)")
    run_clearing_cycle(sample_payment, simulated_latency_ns=860)

    print("\n\n>>> ATTACK VECTOR (latency = 450 000 ns — should be diverted)")
    run_clearing_cycle(sample_payment, simulated_latency_ns=450_000)
    
