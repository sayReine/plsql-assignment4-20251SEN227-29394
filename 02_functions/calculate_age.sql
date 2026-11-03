
CREATE OR REPLACE FUNCTION calculate_age (
    p_dob IN DATE
) RETURN NUMBER
IS
    v_age NUMBER;
BEGIN
    IF p_dob IS NULL THEN
        RAISE_APPLICATION_ERROR(-20010, 'Date of birth is required to calculate age.');
    ELSIF p_dob > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20011,
            'Date of birth cannot be in the future: ' || TO_CHAR(p_dob, 'YYYY-MM-DD'));
    END IF;

    v_age := TRUNC(MONTHS_BETWEEN(SYSDATE, p_dob) / 12);
    RETURN v_age;
END calculate_age;
/
SHOW ERRORS
