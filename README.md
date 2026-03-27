# 🏥 ESMOS Healthcare deployment: Odoo

> [!IMPORTANT]
> **INTERNAL FORK DISCLAIMER**
> *   **Fork Purpose**: Moving this workload over to **Azure Container Apps (ACA)** isolated backplanes.
> *   **Internal Owner**: DevOps Team

## 🚀 Internal Operations & Delivery (CI/CD)

### 📂 Repository Structure
*   `terraform/`: Provisions the Container App matching this environment.

### 🛠️ Fork Adjustments
*   **Decentralized IaC**: Added `terraform/` directory defining the Azure Container App utilizing data lookups backplane references.
*   **Azure Storage Links configuration links**: Attached environmental mappings mounting Azure Files persistent volumes setups bridges automatically.
