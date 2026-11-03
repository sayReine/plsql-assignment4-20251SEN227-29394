
CREATE OR REPLACE PROCEDURE update_appointment_status (
    p_appt_id    IN appointments.appt_id%TYPE,
    p_new_status IN appointments.status%TYPE
)
IS
    TYPE t_status_list IS VARRAY(3) OF VARCHAR2(12);
    v_valid  t_status_list := t_status_list('SCHEDULED', 'COMPLETED', 'CANCELLED');
    v_status appointments.status%TYPE := UPPER(TRIM(p_new_status));
    v_ok     BOOLEAN := FALSE;

    e_invalid_status EXCEPTION;
    e_not_updatable  EXCEPTION;
BEGIN
   
    FOR i IN 1 .. v_valid.COUNT LOOP
        IF v_valid(i) = v_status THEN
            v_ok := TRUE;
            EXIT;
        END IF;
    END LOOP;

    IF NOT v_ok OR v_status = 'SCHEDULED' THEN
        RAISE e_invalid_status;     
    END IF;

    
    UPDATE appointments
    SET    status = v_status
    WHERE  appt_id = p_appt_id
    AND    status  = 'SCHEDULED';

    IF SQL%NOTFOUND THEN
        RAISE e_not_updatable;
    END IF;

    IF SQL%FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Appointment ' || p_appt_id || ' set to ' || v_status ||
                             ' (rows updated: ' || SQL%ROWCOUNT || ')');
    END IF;
EXCEPTION
    WHEN e_invalid_status THEN
        RAISE_APPLICATION_ERROR(-20301,
            'Invalid status "' || p_new_status || '". Use COMPLETED or CANCELLED.');
    WHEN e_not_updatable THEN
        RAISE_APPLICATION_ERROR(-20302,
            'Appointment ' || p_appt_id || ' does not exist or is no longer SCHEDULED.');
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('update_appointment_status', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END update_appointment_status;
/
SHOW ERRORS
