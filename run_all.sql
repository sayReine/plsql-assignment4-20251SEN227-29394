
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF

PROMPT --- 1. Schema ---
@00_schema/01_create_tables.sql
@00_schema/02_insert_sample_data.sql
@00_schema/03_create_types.sql

PROMPT --- 2. Functions ---
@02_functions/calculate_age.sql
@02_functions/get_patient_balance.sql
@02_functions/calculate_bill_amount.sql
@02_functions/get_patient_id_by_name.sql
@02_functions/get_patient_row.sql
@02_functions/get_patient_record_ids.sql
@02_functions/is_doctor_available.sql

PROMPT --- 3. Procedures (log_error first: the others call it) ---
@01_procedures/log_error.sql
@01_procedures/register_patient.sql
@01_procedures/book_appointment.sql
@01_procedures/update_appointment_status.sql
@01_procedures/add_medical_record.sql
@01_procedures/purge_cancelled_appointments.sql
@01_procedures/print_patient_history.sql
@01_procedures/doctor_workload_report.sql
@01_procedures/bulk_update_doctor_fees.sql
@01_procedures/bulk_generate_bills.sql
@01_procedures/benchmark_bulk_vs_row.sql

PROMPT --- 4. Check for compilation errors (should return no rows) ---
SELECT name, type, line, text FROM user_errors ORDER BY name, sequence;

PROMPT --- 5. Tests ---
@03_tests/test_success_cases.sql
@03_tests/test_error_cases.sql
