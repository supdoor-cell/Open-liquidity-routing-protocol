# 🚀 PRIME PARADIGM PROTOCOL - DEPLOYMENT GUIDE

## Pre-Launch Checklist ✓

- [x] All critical bugs fixed
- [x] Code duplications removed
- [x] Thread safety implemented
- [x] Security credentials externalized
- [x] Error handling comprehensive
- [x] Setup script validated
- [x] Cloud provisioning completed

---

## Deployment Instructions

### Phase 1: Prerequisites

```bash
# 1. Ensure you have Ubuntu 20.04+ or Debian 11+
lsb_release -a

# 2. Install git
sudo apt-get update
sudo apt-get install -y git

# 3. Clone the repository
git clone https://github.com/supdoor-cell/open-liquidity-routing-protocol.git
cd open-liquidity-routing-protocol

# 4. Switch to main branch (fixes merged)
git checkout main
git pull origin main
```

### Phase 2: Set Environment Variables

```bash
# Create a .env file for security credentials
cp .env.example .env

# Edit with your values
nano .env  # or vi .env

# Set the following:
export ENFORCER_IDENTITY="your-enforcer-name"
export ENFORCER_MASTER_SECRET="your-secure-secret-key"

# Load environment
source .env

# Verify
echo "Enforcer ID: $ENFORCER_IDENTITY"
```

### Phase 3: Run Setup Script

```bash
# Make setup script executable
chmod +x setup.sh

# Run the automated provisioning
./setup.sh

# Monitor the deployment
tail -f runtime_telemetry.log
```

### Phase 4: Verify Cloud Provisioning

```bash
# Run cloud provisioner to deploy instances
python3 cloud_provision.py

# Expected output:
# >>> [API] Connecting to Regional Infrastructure Hub: Singapore-SG1...
# >>> [INIT] Starting multi-region deployment...
# [SUCCESS] Instance PRIME-NODE-XXXX deployed successfully
```

### Phase 5: Test Core Engine

```bash
# Run the core engine directly to test
python3 core_engine.py

# Expected output:
# [INIT] Launching Prime Paradigm Trust Core Architecture...
# ========================================================
#            PRIME PARADIGM RUNTIME METRICS REPORT
# ========================================================
#  Total Trapped Capital Successfully Freed : $XXX,XXX.00M
#  Platform Micro-Tax Revenue Generated    : $XXX.XX
#  System Continuous Flow Security Status   : 100.000% Operational
```

---

## Post-Deployment Verification

### Check Core Engine Status
```bash
python3 -c "
from core_engine import PrimeNettingFabric, UltraLowLatencySentinel
fabric = PrimeNettingFabric(num_nodes=100)
sentinel = UltraLowLatencySentinel()
print('✓ Core Engine Initialized Successfully')
print(f'✓ Sentinel Latency Window: {sentinel.planck_window_ns} ns')
"
```

### Check Cloud Infrastructure
```bash
python3 -c "
from cloud_provision import AutomatedCloudProvisioner
provisioner = AutomatedCloudProvisioner()
provisioner.deploy_ephemeral_node('Test-Region-01')
summary = provisioner.get_deployment_summary()
print(f'✓ Instances Deployed: {summary[\"total_instances\"]}')
print(f'✓ Credits Remaining: \${summary[\"remaining_credits\"]:.2f}')
"
```

### Check Security Backend
```bash
# Test authentication
python3 enforcer_backend.py
```

---

## Monitoring & Logs

### Runtime Telemetry
```bash
# Monitor core engine output
tail -f runtime_telemetry.log

# Check for errors
grep -i "error\|failed\|critical" runtime_telemetry.log
```

### Performance Metrics
```bash
# Get deployment summary
python3 -c "
from cloud_provision import AutomatedCloudProvisioner
provisioner = AutomatedCloudProvisioner()
summary = provisioner.get_deployment_summary()
import json
print(json.dumps(summary, indent=2))
"
```

---

## Troubleshooting

### Issue: "Failed to fetch core_engine.py"
**Solution:**
```bash
# Manually download and place
wget https://raw.githubusercontent.com/supdoor-cell/Open-liquidity-routing-protocol/main/core_engine.py -O /opt/prime_paradigm_core/core_engine.py
chmod +x /opt/prime_paradigm_core/core_engine.py
```

### Issue: "ENFORCER_IDENTITY not set"
**Solution:**
```bash
export ENFORCER_IDENTITY="YourName"
export ENFORCER_MASTER_SECRET="YourSecret"
source .env
python3 enforcer_backend.py
```

### Issue: "Permission denied" on setup.sh
**Solution:**
```bash
chmod +x setup.sh
./setup.sh
```

---

## Security Notes

⚠️ **IMPORTANT:**
- Never commit `.env` file to repository
- Rotate `ENFORCER_MASTER_SECRET` regularly
- Use secure secrets management in production (HashiCorp Vault, AWS Secrets Manager)
- Enable environment variable protection in CI/CD

---

## Support & Maintenance

For issues or updates:
1. Check repository GitHub Issues
2. Review telemetry logs
3. Validate environment variables
4. Test individual components

---

## Version Info

- **Protocol Version:** 1.0.1
- **Status:** Production Ready
- **Last Updated:** 2026-06-01
- **Branch:** main

---

**🚀 System is ready for production deployment!**
