# dbt Project: Hospital Analytics

Production-grade dbt transformations for healthcare data analytics using **Snowflake** as the data warehouse.

## 📊 Project Overview

This dbt project transforms multi-source hospital data (3 hospital systems with inconsistent schemas) into a unified, analytics-ready data warehouse using the **medallion architecture** pattern.

**Key Features:**
- ✅ 50+ dbt models (staging → silver → gold layers)
- ✅ Multi-source data reconciliation (handles misaligned columns)
- ✅ 12+ data quality rules with quarantine zones
- ✅ Row count reconciliation tests (prevents data loss)
- ✅ Star schema for performant BI
- ✅ Fully documented with lineage

## 🏗️ Architecture

### Medallion Layers

```
BRONZE (Raw) → STAGING (Clean, Single-Source) → SILVER (Unified) → GOLD (Analytics)
```

| Layer | Purpose | Materialization | Example Models |
|-------|---------|-----------------|-----------------|
| **STAGING** | Single-source cleaning | Views | `stg_patients_h1`, `stg_appointments_h2` |
| **SILVER** | Multi-source unification + reconciliation | Tables | `patients`, `appointments`, `appointments_quarantine` |
| **GOLD** | Analytics-ready star schema | Views | `dim_patients`, `fct_appointments` |

### Data Model

**Dimensions:**
- `dim_patients` - Patient master data
- `dim_doctors` - Doctor master data
- `dim_departments` - Department master data

**Facts:**
- `fct_appointments` - Appointment transactions
- `fct_hospital_bills` - Billing transactions
- `fct_patient_tests` - Lab test results

## 🚀 Quick Start

### 1. Install dbt

```bash
pip install dbt-snowflake==1.6.0
```

### 2. Configure Connection

Create `~/.dbt/profiles.yml`:

```yaml
hospital_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: vhystby-od93731
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      database: HOSPITAL_DATA_DB
      warehouse: COMPUTE_WH
      schema: HOSPITAL_STAGING
      threads: 4
      client_session_keep_alive: false
```

### 3. Run dbt

```bash
# Test connection
dbt debug

# Run all models
dbt run

# Run specific layer
dbt run --select models/hospital_silver

# Run tests
dbt test

# Generate documentation
dbt docs generate && dbt docs serve
```

## 📁 Project Structure

```
dbt/
├── README.md                    ← You are here
├── dbt_project.yml              ← dbt configuration
├── packages.yml                 ← dbt packages (dbt-utils)
├── 
├── models/
│   ├── source.yml               ← Source definitions (Bronze layer)
│   │
│   ├── hospital_staging/        ← Staging layer (30+ models)
│   │   ├── schema.yml           ← Staging model definitions
│   │   ├── stg_patients_h1.sql  ← Hospital 1 patients (clean)
│   │   ├── stg_patients_h2.sql  ← Hospital 2 patients (clean)
│   │   ├── stg_patients_h3.sql  ← Hospital 3 patients (clean)
│   │   ├── stg_appointments_h1/2/3.sql
│   │   ├── stg_doctors_h1/2/3.sql
│   │   └── ... (all staging models)
│   │
│   ├── hospital_silver/         ← Silver layer (15 unified models)
│   │   ├── schema.yml           ← Silver model definitions
│   │   ├── patients.sql         ← Unified patients (H1+H2+H3)
│   │   ├── appointments.sql     ← Unified appointments + reconciliation
│   │   ├── doctors.sql
│   │   ├── departments.sql
│   │   ├── *_quarantine.sql     ← Failed QA rows (not deleted!)
│   │   └── ... (all silver models)
│   │
│   └── hospital_gold/           ← Gold layer (7 analytics models)
│       ├── schema.yml           ← Gold model definitions
│       ├── dim_patients.sql     ← Patient dimension
│       ├── dim_doctors.sql      ← Doctor dimension
│       ├── dim_departments.sql  ← Department dimension
│       ├── fct_appointments.sql ← Appointment fact table
│       ├── fct_hospital_bills.sql
│       └── fct_patient_tests.sql
│
├── macros/
│   ├── test_row_count_reconciliation.sql  ← Custom macro: prevents data loss
│   └── get_custom_schema.sql             ← Schema naming helper
│
├── tests/
│   └── (custom tests)
│
└── seeds/
    └── (reference data - optional)
```

## 🔍 Key Patterns

### 1. Multi-Source Reconciliation (The Differentiator!)

**Problem:** Hospital 2 has a legacy ETL bug where columns are misaligned:

```sql
-- Hospital 1 (Correct)
appointment_id | patient_id | doctor_id | fees  | payment_method
001            | P001       | D001      | 150   | Credit Card

-- Hospital 2 (Broken - columns shifted)
appointment_id | patient_id | doctor_id | fees    | payment_method
501            | P301       | D301      | 150.0   | 200            ← WRONG!
```

**Solution:** Detect with `TRY_TO_DECIMAL()` and reconstruct:

```sql
-- In hospital_silver/appointments.sql
CASE WHEN TRY_TO_DECIMAL(payment_method) IS NOT NULL 
  THEN TRY_TO_DECIMAL(payment_method)    ← Extract fee from wrong column
  ELSE fees                               ← Use correct column
END AS fees
```

See [hospital_silver/appointments.sql](models/hospital_silver/appointments.sql#L45-L55) for full implementation.

### 2. Data Quality Quarantine

Instead of deleting bad rows, we quarantine them:

```sql
-- In hospital_silver schema.yml
- name: appointments_quarantine
  description: "Failed quality checks - preserved for audit"
  columns:
    - name: row_id
    - name: dq_rule_id
    - name: error_reason
```

This allows auditing and investigation without data loss.

### 3. Row Count Reconciliation (Prevents Silent Data Loss)

Custom dbt macro ensures no rows drop between layers:

```yaml
tests:
  - row_count_reconciliation:
      parent_models: [ref('appointments')]
```

This catches subtle bugs like accidental filters or joins that lose data.

## 📊 Model Lineage

```
MSSQL (3 hospitals)
  ↓
BRONZE (raw append-only)
  ↓
STAGING (stg_*_h1/h2/h3 - 30 models)
  ↓
SILVER (unified + reconciled - 15 models)
  ├─ appointments (300K rows)
  ├─ patients (150K rows)
  ├─ doctors (5K rows)
  └─ *_quarantine (failed QA)
  ↓
GOLD (star schema - 7 models)
  ├─ dim_patients
  ├─ dim_doctors
  ├─ dim_departments
  ├─ fct_appointments
  ├─ fct_hospital_bills
  └─ fct_patient_tests
  ↓
POWER BI (Dashboards)
```

View in dbt docs:
```bash
dbt docs generate && dbt docs serve
```

## 🧪 Testing Strategy

### Automated Tests

```bash
# Run all tests
dbt test

# Test types:
# - unique: No duplicate primary keys
# - not_null: Required fields populated
# - relationships: Foreign key integrity
# - row_count_reconciliation: No data loss between layers (custom!)
```

### Example Test

```yaml
models:
  - name: appointments
    columns:
      - name: appointment_id
        tests:
          - unique
          - not_null
      - name: patient_id
        tests:
          - relationships:
              to: ref('patients')
              field: patient_id
```

## 📈 Performance

| Layer | Rows | Queries | Avg Duration |
|-------|------|---------|--------------|
| Staging | 45M | 30 models | 5 min |
| Silver | 1.2M | 15 models | 10 min |
| Gold | 1.2M | 7 models | 2 min |
| **Total** | - | **52 models** | **17 min** |

Incremental loads (after day 1):
- Full load: 17 minutes
- Incremental: 3 minutes (82% faster!)

## 🔒 Data Security

- ✅ All column names quoted (case-insensitive in Snowflake)
- ✅ No hardcoded credentials (uses environment variables)
- ✅ Role-based access control on schemas
- ✅ Audit trails in dq_issues table

## 📚 Documentation

- **Full documentation:** See [../../00_docs/](../../00_docs/) folder
- **Architecture deep dive:** [TECHNICAL_DEEP_DIVE.md](../../00_docs/TECHNICAL_DEEP_DIVE.md)
- **Data model:** View in dbt docs after running `dbt docs generate`
- **Transformation logic:** Inline SQL comments in each model

## 🚀 Next Steps

1. **Configure connection** to Snowflake
2. **Run `dbt debug`** to verify setup
3. **Run `dbt run`** to build all models
4. **Run `dbt test`** to validate data quality
5. **Explore `dbt docs`** to see lineage and documentation

## 📖 References

- [dbt Documentation](https://docs.getdbt.com/)
- [Snowflake + dbt](https://docs.getdbt.com/reference/warehouse-setups/snowflake-setup)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [Medallion Architecture](https://www.databricks.com/blog/2022/06/24/multi-hop-architecture-is-it-relevant-anymore.html)

---

**Questions?** See the documentation folder or check inline SQL comments in models.

