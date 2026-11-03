
CREATE OR REPLACE FUNCTION is_doctor_available (
    p_doctor_id IN doctors.doctor_id%TYPE,
    p_datetime  IN DATE
) RETURN VARCHAR2
IS
    v_status doctors.status%TYPE;
    v_busy   PLS_INTEGER;
BEGIN
    SELECT status INTO v_status
    FROM   doctors
    WHERE  doctor_id = p_doctor_id;

    IF v_status <> 'ACTIVE' THEN
        RETURN 'N';
    END IF;

    SELECT COUNT(*) INTO v_busy
    FROM   appointments
    WHERE  doctor_id = p_doctor_id
    AND    appt_date = p_datetime
    AND    status   <> 'CANCELLED';

    IF v_busy = 0 THEN
        RETURN 'Y';
    END IF;
    RETURN 'N';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20070, 'Doctor ' || p_doctor_id || ' does not exist.');
END is_doctor_available;
/
SHOW ERRORS
