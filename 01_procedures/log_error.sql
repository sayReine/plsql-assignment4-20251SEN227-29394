
CREATE OR REPLACE PROCEDURE log_error (
    p_source  IN VARCHAR2,
    p_code    IN NUMBER,
    p_message IN VARCHAR2
)
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO error_log (log_id, source_name, error_code, error_message)
    VALUES (seq_error_log.NEXTVAL, p_source, p_code, SUBSTR(p_message, 1, 4000));
    COMMIT;
END log_error;
/
SHOW ERRORS
