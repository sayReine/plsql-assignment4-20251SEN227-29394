
CREATE OR REPLACE PROCEDURE print_patient_history (
    p_patient_id IN patients.patient_id%TYPE
)
IS
    CURSOR c_history (cp_patient medical_records.patient_id%TYPE) IS
        SELECT r.record_id,
               r.visit_date,
               d.full_name AS doctor_name,
               r.diagnosis,
               r.treatment
        FROM   medical_records r
               JOIN doctors d ON d.doctor_id = r.doctor_id
        WHERE  r.patient_id = cp_patient
        ORDER  BY r.visit_date, r.record_id;

    v_row     c_history%ROWTYPE;      
    v_patient patients%ROWTYPE;
BEGIN
    v_patient := get_patient_row(p_patient_id);   

    DBMS_OUTPUT.PUT_LINE('=== Medical history: ' || v_patient.full_name ||
                         ' (id ' || v_patient.patient_id || ', age ' ||
                         calculate_age(v_patient.date_of_birth) || ') ===');

    OPEN c_history(p_patient_id);
    LOOP
        FETCH c_history INTO v_row;
        EXIT WHEN c_history%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(c_history%ROWCOUNT || '. ' ||
                             TO_CHAR(v_row.visit_date, 'YYYY-MM-DD') || ' | ' ||
                             v_row.doctor_name || ' | ' ||
                             v_row.diagnosis   || ' | ' ||
                             NVL(v_row.treatment, '-'));
    END LOOP;

    IF c_history%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No medical records on file.');
    END IF;
    CLOSE c_history;

    DBMS_OUTPUT.PUT_LINE('Outstanding balance: ' || get_patient_balance(p_patient_id) || ' RWF');
EXCEPTION
    WHEN OTHERS THEN
        IF c_history%ISOPEN THEN
            CLOSE c_history;           
        END IF;
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('print_patient_history', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END print_patient_history;
/
SHOW ERRORS
