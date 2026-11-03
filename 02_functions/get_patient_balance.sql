
CREATE OR REPLACE FUNCTION get_patient_balance (
    p_patient_id IN patients.patient_id%TYPE
) RETURN NUMBER
IS
    v_name    patients.full_name%TYPE;
    v_balance NUMBER := 0;
BEGIN

    SELECT full_name INTO v_name
    FROM   patients
    WHERE  patient_id = p_patient_id;

    SELECT NVL(SUM(amount), 0) INTO v_balance
    FROM   billing
    WHERE  patient_id = p_patient_id
    AND    status = 'UNPAID';

    RETURN v_balance;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20020, 'Patient ' || p_patient_id || ' does not exist.');
    
END get_patient_balance;
/
SHOW ERRORS
