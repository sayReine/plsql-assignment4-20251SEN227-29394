SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET FEEDBACK ON

PROMPT
PROMPT ===== S1: Functions called from SQL =====
COLUMN full_name FORMAT A22
COLUMN balance   FORMAT 999,999
SELECT patient_id,
       full_name,
       calculate_age(date_of_birth)  AS age,
       get_patient_balance(patient_id) AS balance
FROM   patients
ORDER  BY patient_id;

PROMPT -- Nested-table function used with TABLE(): record ids of patient 1001
SELECT column_value AS record_id FROM TABLE(get_patient_record_ids(1001));

PROMPT -- Availability of every doctor at the slot of appointment 5014 (Dr. Uwase is busy)
SELECT doctor_id, full_name, status,
       is_doctor_available(doctor_id,
           (SELECT appt_date FROM appointments WHERE appt_id = 5014)) AS available
FROM   doctors
ORDER  BY doctor_id;

PROMPT
PROMPT ===== S2: Functions called from PL/SQL (records, bill calculation) =====
DECLARE
    v_id      patients.patient_id%TYPE;
    v_patient patients%ROWTYPE;
    v_amount  NUMBER;
BEGIN
    v_id      := get_patient_id_by_name('aline uwera');
    v_patient := get_patient_row(v_id);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_id = 1002 THEN 'PASS' ELSE 'FAIL' END ||
        ' S2a get_patient_id_by_name -> ' || v_id || ' / ' || v_patient.full_name);

    v_amount := calculate_bill_amount(5007);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_amount = 16000 THEN 'PASS' ELSE 'FAIL' END ||
        ' S2b insured bill = ' || v_amount);

    v_amount := calculate_bill_amount(5010);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_amount = 60000 THEN 'PASS' ELSE 'FAIL' END ||
        ' S2c uninsured bill = ' || v_amount);

    DBMS_OUTPUT.PUT_LINE(CASE WHEN calculate_age(DATE '2000-01-01') >= 26 THEN 'PASS' ELSE 'FAIL' END ||
        ' S2d calculate_age(2000-01-01) = ' || calculate_age(DATE '2000-01-01'));
END;
/

PROMPT
PROMPT ===== S3: register_patient (record + implicit INSERT cursor) =====
DECLARE
    v_id    patients.patient_id%TYPE;
    v_count PLS_INTEGER;
BEGIN
    register_patient('Test Patient', DATE '1995-05-05', 'f', '0788999999', 'RSSB', v_id);
    SELECT COUNT(*) INTO v_count FROM patients WHERE patient_id = v_id AND gender = 'F';
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_count = 1 THEN 'PASS' ELSE 'FAIL' END ||
        ' S3 patient ' || v_id || ' stored (gender normalised to F)');
END;
/

PROMPT
PROMPT ===== S4: book_appointment + update_appointment_status =====
DECLARE
    v_appt   appointments.appt_id%TYPE;
    v_status appointments.status%TYPE;
BEGIN
    book_appointment(1003, 105, TRUNC(SYSDATE) + 10 + 14/24, 'Test booking', v_appt);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_appt IS NOT NULL THEN 'PASS' ELSE 'FAIL' END ||
        ' S4a appointment booked: ' || v_appt);

    update_appointment_status(v_appt, 'cancelled');
    SELECT status INTO v_status FROM appointments WHERE appt_id = v_appt;
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_status = 'CANCELLED' THEN 'PASS' ELSE 'FAIL' END ||
        ' S4b status is now ' || v_status);
END;
/

PROMPT
PROMPT ===== S5: add_medical_record (record + procedure + function + 2 OUT params) =====
DECLARE
    v_record_id medical_records.record_id%TYPE;
    v_bill_id   billing.bill_id%TYPE;
    v_amount    billing.amount%TYPE;
    v_status    appointments.status%TYPE;
BEGIN
    add_medical_record(5014, 'Hypertension - stage 1', 'Medication and diet review', v_record_id, v_bill_id);

    SELECT amount INTO v_amount FROM billing WHERE bill_id = v_bill_id;
    SELECT status INTO v_status FROM appointments WHERE appt_id = 5014;

    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_amount = 40000 AND v_status = 'COMPLETED' THEN 'PASS' ELSE 'FAIL' END ||
        ' S5 record ' || v_record_id || ', bill ' || v_bill_id || ' = ' || v_amount ||
        ', appointment ' || v_status);
END;
/

PROMPT
PROMPT ===== S6: Explicit cursors - patient history and doctor workload =====
BEGIN
    print_patient_history(1001);
    DBMS_OUTPUT.PUT_LINE('---');
    doctor_workload_report(10);
    DBMS_OUTPUT.PUT_LINE('---');
    doctor_workload_report(30);
END;
/

PROMPT
PROMPT ===== S7: bulk_update_doctor_fees (BULK COLLECT LIMIT + FORALL) =====
PROMPT -- Before:
SELECT doctor_id, full_name, consultation_fee FROM doctors WHERE dept_id = 30 ORDER BY doctor_id;
DECLARE
    v_updated NUMBER;
    v_failed  NUMBER;
BEGIN
    bulk_update_doctor_fees(30, 10, v_updated, v_failed);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_updated = 2 AND v_failed = 0 THEN 'PASS' ELSE 'FAIL' END ||
        ' S7 updated=' || v_updated || ' failed=' || v_failed);
END;
/
PROMPT -- After (expect 22000 and 24200):
SELECT doctor_id, full_name, consultation_fee FROM doctors WHERE dept_id = 30 ORDER BY doctor_id;

PROMPT
PROMPT ===== S8: bulk_generate_bills (collection of records + FORALL INSERT) =====
DECLARE
    v_billed NUMBER;
    v_failed NUMBER;
BEGIN
    bulk_generate_bills(v_billed, v_failed);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_billed = 4 AND v_failed = 0 THEN 'PASS' ELSE 'FAIL' END ||
        ' S8a first run: billed=' || v_billed || ' failed=' || v_failed);

    bulk_generate_bills(v_billed, v_failed);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_billed = 0 AND v_failed = 0 THEN 'PASS' ELSE 'FAIL' END ||
        ' S8b second run is a no-op: billed=' || v_billed);
END;
/
SELECT b.bill_id, b.appt_id, b.patient_id, b.amount, b.status
FROM   billing b
WHERE  b.appt_id BETWEEN 5007 AND 5010
ORDER  BY b.bill_id;

PROMPT
PROMPT ===== S9: purge_cancelled_appointments (implicit DELETE cursor) =====
DECLARE
    v_deleted NUMBER;
BEGIN
    purge_cancelled_appointments(30, v_deleted);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_deleted >= 2 THEN 'PASS' ELSE 'FAIL' END ||
        ' S9a deleted=' || v_deleted);

    purge_cancelled_appointments(30, v_deleted);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_deleted = 0 THEN 'PASS' ELSE 'FAIL' END ||
        ' S9b deleted=' || v_deleted);
END;
/

PROMPT
PROMPT ===== S10: Bulk vs row-by-row benchmark =====
DECLARE
    v_row_ms  NUMBER;
    v_bulk_ms NUMBER;
BEGIN
    benchmark_bulk_vs_row(100000, v_row_ms, v_bulk_ms);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_bulk_ms <= v_row_ms THEN 'PASS' ELSE 'CHECK' END ||
        ' S10 bulk (' || v_bulk_ms || ' ms) vs row-by-row (' || v_row_ms || ' ms)');
END;
/

PROMPT
PROMPT ===== Cleaning up: ROLLBACK keeps the sample data unchanged =====
ROLLBACK;
PROMPT Done.