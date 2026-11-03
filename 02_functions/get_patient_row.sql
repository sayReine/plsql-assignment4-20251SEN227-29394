
CREATE OR REPLACE FUNCTION get_patient_row (
    p_patient_id IN patients.patient_id%TYPE
) RETURN patients%ROWTYPE
IS
    v_row patients%ROWTYPE;
BEGIN
    SELECT *
    INTO   v_row
    FROM   patients
    WHERE  patient_id = p_patient_id;

    RETURN v_row;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20050, 'Patient ' || p_patient_id || ' does not exist.');
END get_patient_row;
/
SHOW ERRORS
