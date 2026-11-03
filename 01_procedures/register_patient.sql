
CREATE OR REPLACE PROCEDURE register_patient (
    p_full_name  IN  patients.full_name%TYPE,
    p_dob        IN  patients.date_of_birth%TYPE,
    p_gender     IN  patients.gender%TYPE,
    p_phone      IN  patients.phone%TYPE,
    p_insurance  IN  patients.insurance_provider%TYPE DEFAULT NULL,
    p_patient_id OUT patients.patient_id%TYPE
)
IS
    
    TYPE t_new_patient IS RECORD (
        full_name patients.full_name%TYPE,
        dob       patients.date_of_birth%TYPE,
        gender    patients.gender%TYPE,
        phone     patients.phone%TYPE,
        insurance patients.insurance_provider%TYPE
    );
    v_new t_new_patient;
    v_msg VARCHAR2(200);

    e_invalid_input EXCEPTION;   
BEGIN
   
    v_new.full_name := TRIM(p_full_name);
    v_new.dob       := p_dob;
    v_new.gender    := UPPER(TRIM(p_gender));
    v_new.phone     := TRIM(p_phone);
    v_new.insurance := TRIM(p_insurance);

    
    IF v_new.full_name IS NULL THEN
        v_msg := 'Full name is required.';
        RAISE e_invalid_input;
    ELSIF v_new.dob IS NULL OR v_new.dob > SYSDATE THEN
        v_msg := 'Date of birth is required and cannot be in the future.';
        RAISE e_invalid_input;
    ELSIF v_new.gender IS NULL OR v_new.gender NOT IN ('M', 'F') THEN
        v_msg := 'Gender must be M or F.';
        RAISE e_invalid_input;
    ELSIF v_new.phone IS NULL THEN
        v_msg := 'Phone number is required.';
        RAISE e_invalid_input;
    END IF;

   
    INSERT INTO patients (patient_id, full_name, date_of_birth, gender, phone, insurance_provider)
    VALUES (seq_patient.NEXTVAL, v_new.full_name, v_new.dob, v_new.gender, v_new.phone, v_new.insurance)
    RETURNING patient_id INTO p_patient_id;

    IF SQL%ROWCOUNT = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Patient registered: id=' || p_patient_id ||
                             ', name=' || v_new.full_name ||
                             ' (rows inserted: ' || SQL%ROWCOUNT || ')');
    END IF;
EXCEPTION
    WHEN e_invalid_input THEN
        RAISE_APPLICATION_ERROR(-20101, v_msg);
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20102,
            'A patient with phone number ' || v_new.phone || ' is already registered.');
    WHEN OTHERS THEN
       
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('register_patient', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END register_patient;
/
SHOW ERRORS
