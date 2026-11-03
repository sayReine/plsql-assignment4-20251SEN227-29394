SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100

PROMPT
PROMPT ===== E1: register_patient errors =====
DECLARE
    v_id patients.patient_id%TYPE;
BEGIN
    register_patient('Duplicate Phone', DATE '1990-01-01', 'M', '0788000001', NULL, v_id);
    DBMS_OUTPUT.PUT_LINE('FAIL E1a no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20102 THEN 'PASS' ELSE 'FAIL' END || ' E1a duplicate phone -> ' || SQLERRM);
END;
/
DECLARE
    v_id patients.patient_id%TYPE;
BEGIN
    register_patient('Future Baby', SYSDATE + 30, 'M', '0788111111', NULL, v_id);
    DBMS_OUTPUT.PUT_LINE('FAIL E1b no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20101 THEN 'PASS' ELSE 'FAIL' END || ' E1b future date of birth -> ' || SQLERRM);
END;
/
DECLARE
    v_id patients.patient_id%TYPE;
BEGIN
    register_patient('Bad Gender', DATE '1990-01-01', 'X', '0788222222', NULL, v_id);
    DBMS_OUTPUT.PUT_LINE('FAIL E1c no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20101 THEN 'PASS' ELSE 'FAIL' END || ' E1c invalid gender -> ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E2: UNEXPECTED error is logged AND re-raised (never swallowed) =====
DECLARE
    v_id     patients.patient_id%TYPE;
    v_before PLS_INTEGER;
    v_after  PLS_INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_before FROM error_log;
    register_patient(RPAD('X', 100, 'X'), DATE '1990-01-01', 'M', '0788333333', NULL, v_id);
    DBMS_OUTPUT.PUT_LINE('FAIL E2 no error raised');
EXCEPTION WHEN OTHERS THEN
    SELECT COUNT(*) INTO v_after FROM error_log;
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE IN (-6502, -12899) AND v_after = v_before + 1
                              THEN 'PASS' ELSE 'FAIL' END ||
                         ' E2 ' || SQLERRM || ' | error_log rows: ' || v_before || ' -> ' || v_after);
END;
/

PROMPT
PROMPT ===== E3: book_appointment errors =====
DECLARE
    v_appt appointments.appt_id%TYPE;
BEGIN
    book_appointment(99999, 101, TRUNC(SYSDATE) + 20 + 9/24, 'x', v_appt);
    DBMS_OUTPUT.PUT_LINE('FAIL E3a no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20201 THEN 'PASS' ELSE 'FAIL' END || ' E3a unknown patient -> ' || SQLERRM);
END;
/
DECLARE
    v_appt appointments.appt_id%TYPE;
BEGIN
    book_appointment(1001, 99999, TRUNC(SYSDATE) + 20 + 9/24, 'x', v_appt);
    DBMS_OUTPUT.PUT_LINE('FAIL E3b no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20202 THEN 'PASS' ELSE 'FAIL' END || ' E3b unknown doctor -> ' || SQLERRM);
END;
/
DECLARE
    v_appt appointments.appt_id%TYPE;
BEGIN
    book_appointment(1001, 101, SYSDATE - 1, 'x', v_appt);
    DBMS_OUTPUT.PUT_LINE('FAIL E3c no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20203 THEN 'PASS' ELSE 'FAIL' END || ' E3c date in the past -> ' || SQLERRM);
END;
/
DECLARE
    v_appt appointments.appt_id%TYPE;
BEGIN
    book_appointment(1001, 104, TRUNC(SYSDATE) + 20 + 9/24, 'x', v_appt);
    DBMS_OUTPUT.PUT_LINE('FAIL E3d no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20204 THEN 'PASS' ELSE 'FAIL' END || ' E3d doctor on leave -> ' || SQLERRM);
END;
/
DECLARE
    v_appt appointments.appt_id%TYPE;
    v_slot appointments.appt_date%TYPE;
BEGIN
    SELECT appt_date INTO v_slot FROM appointments WHERE appt_id = 5014;
    book_appointment(1003, 101, v_slot, 'x', v_appt);
    DBMS_OUTPUT.PUT_LINE('FAIL E3e no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20205 THEN 'PASS' ELSE 'FAIL' END || ' E3e slot already taken -> ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E4: update_appointment_status errors (VARRAY check, SQL%NOTFOUND) =====
BEGIN
    update_appointment_status(5014, 'DONE');
    DBMS_OUTPUT.PUT_LINE('FAIL E4a no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20301 THEN 'PASS' ELSE 'FAIL' END || ' E4a invalid status value -> ' || SQLERRM);
END;
/
BEGIN
    update_appointment_status(5001, 'CANCELLED');
    DBMS_OUTPUT.PUT_LINE('FAIL E4b no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20302 THEN 'PASS' ELSE 'FAIL' END || ' E4b already completed -> ' || SQLERRM);
END;
/
BEGIN
    update_appointment_status(99999, 'COMPLETED');
    DBMS_OUTPUT.PUT_LINE('FAIL E4c no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20302 THEN 'PASS' ELSE 'FAIL' END || ' E4c unknown appointment -> ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E5: add_medical_record errors =====
DECLARE
    v_rec medical_records.record_id%TYPE;
    v_bill billing.bill_id%TYPE;
BEGIN
    add_medical_record(5014, '   ', 'none', v_rec, v_bill);
    DBMS_OUTPUT.PUT_LINE('FAIL E5a no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20401 THEN 'PASS' ELSE 'FAIL' END || ' E5a blank diagnosis -> ' || SQLERRM);
END;
/
DECLARE
    v_rec medical_records.record_id%TYPE;
    v_bill billing.bill_id%TYPE;
BEGIN
    add_medical_record(5001, 'Again', 'none', v_rec, v_bill);
    DBMS_OUTPUT.PUT_LINE('FAIL E5b no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20402 THEN 'PASS' ELSE 'FAIL' END || ' E5b not SCHEDULED -> ' || SQLERRM);
END;
/
DECLARE
    v_rec medical_records.record_id%TYPE;
    v_bill billing.bill_id%TYPE;
BEGIN
    add_medical_record(99999, 'Flu', 'none', v_rec, v_bill);
    DBMS_OUTPUT.PUT_LINE('FAIL E5c no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20403 THEN 'PASS' ELSE 'FAIL' END || ' E5c unknown appointment -> ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E6: purge_cancelled_appointments errors =====
DECLARE
    v_deleted NUMBER;
BEGIN
    purge_cancelled_appointments(-5, v_deleted);
    DBMS_OUTPUT.PUT_LINE('FAIL E6 no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20501 THEN 'PASS' ELSE 'FAIL' END || ' E6 negative days -> ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E7: function errors (NO_DATA_FOUND / TOO_MANY_ROWS translated) =====
DECLARE
    v_n NUMBER;
    v_i patients.patient_id%TYPE;
    v_r patients%ROWTYPE;
    v_t t_num_tab;
    v_s VARCHAR2(1);
BEGIN
    BEGIN v_i := get_patient_id_by_name('Nobody Atall');
          DBMS_OUTPUT.PUT_LINE('FAIL E7a no error raised');
    EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20040 THEN 'PASS' ELSE 'FAIL' END || ' E7a NO_DATA_FOUND -> ' || SQLERRM);
    END;

    BEGIN v_i := get_patient_id_by_name('John Mugisha');
          DBMS_OUTPUT.PUT_LINE('FAIL E7b no error raised');
    EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20041 THEN 'PASS' ELSE 'FAIL' END || ' E7b TOO_MANY_ROWS -> ' || SQLERRM);
    END;

    BEGIN v_n := calculate_age(SYSDATE + 10);
          DBMS_OUTPUT.PUT_LINE('FAIL E7c no error raised');
    EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20011 THEN 'PASS' ELSE 'FAIL' END || ' E7c future DOB -> ' || SQLERRM);
    END;

    BEGIN v_n := calculate_age(NULL);
          DBMS_OUTPUT.PUT_LINE('FAIL E7d no error raised');
    EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20010 THEN 'PASS' ELSE 'FAIL' END || ' E7d NULL DOB -> ' || SQLERRM);
    END;

    BEGIN v_n := get_patient_balance(99999);
          DBMS_OUTPUT.PUT_LINE('FAIL E7e no error raised');
    EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20020 THEN 'PASS' ELSE 'FAIL' END || ' E7e unknown patient balance -> ' || SQLERRM);
    END;

    BEGIN v_n := calculate_bill_amount(99999);
          DBMS_OUTPUT.PUT_LINE('FAIL E7f no error raised');
    EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20030 THEN 'PASS' ELSE 'FAIL' END || ' E7f unknown appointment -> ' || SQLERRM);
    END;

    BEGIN v_r := get_patient_row(99999);
          DBMS_OUTPUT.PUT_LINE('FAIL E7g no error raised');
    EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20050 THEN 'PASS' ELSE 'FAIL' END || ' E7g unknown patient row -> ' || SQLERRM);
    END;

    BEGIN v_t := get_patient_record_ids(99999);
          DBMS_OUTPUT.PUT_LINE('FAIL E7h no error raised');
    EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20060 THEN 'PASS' ELSE 'FAIL' END || ' E7h unknown patient records -> ' || SQLERRM);
    END;

    BEGIN v_s := is_doctor_available(99999, SYSDATE + 1);
          DBMS_OUTPUT.PUT_LINE('FAIL E7i no error raised');
    EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20070 THEN 'PASS' ELSE 'FAIL' END || ' E7i unknown doctor -> ' || SQLERRM);
    END;
END;
/

PROMPT
PROMPT ===== E8: cursor procedures - unknown patient / department =====
BEGIN
    print_patient_history(99999);
    DBMS_OUTPUT.PUT_LINE('FAIL E8a no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20050 THEN 'PASS' ELSE 'FAIL' END || ' E8a unknown patient -> ' || SQLERRM);
END;
/
BEGIN
    doctor_workload_report(999);
    DBMS_OUTPUT.PUT_LINE('FAIL E8b no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20701 THEN 'PASS' ELSE 'FAIL' END || ' E8b unknown department -> ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E9: bulk processing errors =====
PROMPT -- E9a: +85 % pushes Dr. Habimana (55000 -> 101750) over the 100000 CHECK limit:
PROMPT --      ONE row fails (FORALL SAVE EXCEPTIONS / ORA-24381), the other row is still updated.
DECLARE
    v_updated NUMBER;
    v_failed  NUMBER;
BEGIN
    bulk_update_doctor_fees(10, 85, v_updated, v_failed);
    DBMS_OUTPUT.PUT_LINE(CASE WHEN v_updated = 1 AND v_failed = 1 THEN 'PASS' ELSE 'FAIL' END ||
        ' E9a partial bulk failure: updated=' || v_updated || ' failed=' || v_failed);
END;
/
DECLARE
    v_updated NUMBER;
    v_failed  NUMBER;
BEGIN
    bulk_update_doctor_fees(10, -100, v_updated, v_failed);
    DBMS_OUTPUT.PUT_LINE('FAIL E9b no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20801 THEN 'PASS' ELSE 'FAIL' END || ' E9b invalid percentage -> ' || SQLERRM);
END;
/
DECLARE
    v_updated NUMBER;
    v_failed  NUMBER;
BEGIN
    bulk_update_doctor_fees(999, 10, v_updated, v_failed);
    DBMS_OUTPUT.PUT_LINE('FAIL E9c no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20802 THEN 'PASS' ELSE 'FAIL' END || ' E9c unknown department -> ' || SQLERRM);
END;
/
DECLARE
    v_row_ms  NUMBER;
    v_bulk_ms NUMBER;
BEGIN
    benchmark_bulk_vs_row(0, v_row_ms, v_bulk_ms);
    DBMS_OUTPUT.PUT_LINE('FAIL E9d no error raised');
EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(CASE WHEN SQLCODE = -20950 THEN 'PASS' ELSE 'FAIL' END || ' E9d zero rows -> ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== Logged unexpected / bulk errors (ERROR_LOG) =====
COLUMN source_name   FORMAT A30
COLUMN error_message FORMAT A90
SELECT log_id, source_name, error_code, SUBSTR(error_message, 1, 90) AS error_message
FROM   error_log
ORDER  BY log_id;

PROMPT
PROMPT ===== Undo E9a's fee change so sample data is unchanged =====
ROLLBACK;
PROMPT Done.