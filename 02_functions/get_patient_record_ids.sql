
CREATE OR REPLACE FUNCTION get_patient_record_ids (
    p_patient_id IN patients.patient_id%TYPE
) RETURN t_num_tab
IS
    v_ids   t_num_tab;
    v_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM   patients
    WHERE  patient_id = p_patient_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20060, 'Patient ' || p_patient_id || ' does not exist.');
    END IF;

    SELECT record_id
    BULK COLLECT INTO v_ids
    FROM   medical_records
    WHERE  patient_id = p_patient_id
    ORDER  BY visit_date, record_id;

    RETURN v_ids;  
END get_patient_record_ids;
/
SHOW ERRORS
