
CREATE OR REPLACE FUNCTION get_patient_id_by_name (
    p_name IN patients.full_name%TYPE
) RETURN patients.patient_id%TYPE
IS
    v_id patients.patient_id%TYPE;
BEGIN
    SELECT patient_id
    INTO   v_id
    FROM   patients
    WHERE  UPPER(full_name) = UPPER(TRIM(p_name));

    RETURN v_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20040, 'No patient found with name "' || p_name || '".');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20041,
            'More than one patient is named "' || p_name || '"; look up by patient id or phone instead.');
END get_patient_id_by_name;
/
SHOW ERRORS
