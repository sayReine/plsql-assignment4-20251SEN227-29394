
CREATE OR REPLACE PROCEDURE purge_cancelled_appointments (
    p_days_old IN  NUMBER,
    p_deleted  OUT NUMBER
)
IS
    e_child_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_child_exists, -2292);   
BEGIN
    p_deleted := 0;

    IF p_days_old IS NULL OR p_days_old < 0 THEN
        RAISE_APPLICATION_ERROR(-20501, 'Number of days must be zero or greater.');
    END IF;

    DELETE FROM appointments
    WHERE  status = 'CANCELLED'
    AND    appt_date < SYSDATE - p_days_old;

    p_deleted := SQL%ROWCOUNT;

    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nothing to purge: no cancelled appointments older than ' ||
                             p_days_old || ' days.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Purged ' || p_deleted || ' cancelled appointment(s).');
    END IF;
EXCEPTION
    WHEN e_child_exists THEN
        RAISE_APPLICATION_ERROR(-20502,
            'Cannot purge: some appointments are still referenced by records or bills.');
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('purge_cancelled_appointments', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END purge_cancelled_appointments;
/
SHOW ERRORS
