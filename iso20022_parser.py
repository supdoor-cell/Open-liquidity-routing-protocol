#!/usr/bin/env python3
# ============================================================================
# TITLE:       PRIME PARADIGM ISO 20022 HIGH-IQ PROTOCOL PARSER
# VERSION:     1.1.0
# MATRIX:      Structural Financial Message Mapping Fields
# LICENSE:     Apache License 2.0 (Open-Source Standard)
# FIXES:       - Removed invalid JavaScript-style // comments inside json.dumps()
#              - Fixed missing closing parenthesis on json.dumps(coordinates)
#              - Added input type validation and safe float parsing
#              - Expanded supported message types list
# ============================================================================

import json
from typing import Union


class ISO20022HighIQParser:
    """
    Parses ISO 20022 pacs.008 / pacs.009 wholesale payment messages and
    projects their settlement fields onto a flat vector dict suitable for
    downstream hypergraph ingestion.
    """

    SUPPORTED_MESSAGE_TYPES = [
        "pacs.008.001.10",
        "pacs.009.001.10",
        "pacs.008.001.08",
        "pacs.009.001.08",
    ]

    def translate_xml_to_tensor_coordinates(
        self, iso_payload: Union[str, dict]
    ) -> dict:
        """
        Extracts structural payment blocks from an ISO 20022 JSON/XML payload.

        Args:
            iso_payload: Either a JSON string or an already-parsed dict
                         representing a FIToFICstmrCdtTrf document.

        Returns:
            A flat dict with typed fields ready for hypergraph ingestion, or
            an error dict if the schema is malformed.
        """
        # Accept either a pre-parsed dict or a raw JSON string
        if isinstance(iso_payload, str):
            try:
                parsed_document = json.loads(iso_payload)
            except json.JSONDecodeError as exc:
                return {"error": f"Invalid JSON payload: {exc}"}
        elif isinstance(iso_payload, dict):
            parsed_document = iso_payload
        else:
            return {"error": "iso_payload must be a JSON string or dict"}

        try:
            fi_block = parsed_document["Document"]["FIToFICstmrCdtTrf"]
            grp_hdr  = fi_block["GrpHdr"]
            tx_info  = fi_block["CdtTrfTxInf"]
            amt_block = tx_info["IntrBkSttlmAmt"]

            # Safe numeric coercion with descriptive errors
            debtor_id   = int(tx_info["Dbtr"]["Id"])
            creditor_id = int(tx_info["Cdtr"]["Id"])
            amount      = float(amt_block["Value"])

            if amount < 0:
                return {"error": "Negative settlement amounts are not permitted"}

            vector_data = {
                "message_identifier":  grp_hdr["MsgId"],
                "debtor_index":        debtor_id,
                "creditor_index":      creditor_id,
                "liability_magnitude": amount,
                "currency_iso":        amt_block["Ccy"].upper(),
            }
            return vector_data

        except KeyError as exc:
            return {"error": f"Invalid ISO 20022 schema — missing tag: {exc}"}
        except (ValueError, TypeError) as exc:
            return {"error": f"Type conversion failed: {exc}"}


# ---------------------------------------------------------------------------
# Smoke-test
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    parser = ISO20022HighIQParser()

    # NOTE: Standard Python json.dumps() does NOT accept // comments.
    #       The mock payload is built as a plain dict and serialised cleanly.
    mock_payment = {
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

    coordinates = parser.translate_xml_to_tensor_coordinates(mock_payment)
    print(">>> PARSED TRANSLATION VECTOR FOR HYPERGRAPH INGESTION:")
    print(json.dumps(coordinates, indent=2))
                        
