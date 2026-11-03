
CREATE OR REPLACE PROCEDURE book_appointment (
    p_patient_id IN  appointments.patient_id%TYPE,
    p_doctor_id  IN  appointments.doctor_id%TYPE,
    p_appt_date  IN  appointments.appt_date%TYPE,
    p_reason     IN  appointments.reason%TYPE,
    p_appt_id    OUT appointments.appt_id%TYPE
)
IS
    v_patient patients%ROWTYPE;   
    v_doctor  doctors%ROWTYPE;

    e_bad_date           EXCEPTION;
    e_doctor_unavailable EXCEPTION;
    e_slot_taken         EXCEPTION;
BEGIN
    IF p_appt_date IS NULL OR p_appt_date <= SYSDATE THEN
        RAISE e_bad_date;
    END IF;

    
    BEGIN
        SELECT * INTO v_patient FROM patients WHERE patient_id = p_patient_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20201, 'Patient ' || p_patient_id || ' not found.');
    END;

    BEGIN
        SELECT * INTO v_doctor FROM doctors WHERE doctor_id = p_doctor_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20202, 'Doctor ' || p_doctor_id || ' not found.');
    END;

    IF v_doctor.status <> 'ACTIVE' THEN
        RAISE e_doctor_unavailable;
    END IF;

    IF is_doctor_available(v_doctor.doctor_id, p_appt_date) = 'N' THEN
        RAISE e_slot_taken;
    END IF;

    INSERT INTO appointments (appt_id, patient_id, doctor_id, appt_date, reason, status)
    VALUES (seq_appt.NEXTVAL, v_patient.patient_id, v_doctor.doctor_id, p_appt_date, p_reason, 'SCHEDULED')
    RETURNING appt_id INTO p_appt_id;

    DBMS_OUTPUT.PUT_LINE('Appointment ' || p_appt_id || ' booked: ' || v_patient.full_name ||
                         ' with ' || v_doctor.full_name ||
                         ' on ' || TO_CHAR(p_appt_date, 'YYYY-MM-DD HH24:MI'));
EXCEPTION
    WHEN e_bad_date THEN
        RAISE_APPLICATION_ERROR(-20203, 'Appointment date is required and must be in the future.');
    WHEN e_doctor_unavailable THEN
        RAISE_APPLICATION_ERROR(-20204,
            v_doctor.full_name || ' is not available (status: ' || v_doctor.status || ').');
    WHEN e_slot_taken THEN
        RAISE_APPLICATION_ERROR(-20205,
            v_doctor.full_name || ' already has an appointment at ' ||
            TO_CHAR(p_appt_date, 'YYYY-MM-DD HH24:MI') || '.');
    WHEN DUP_VAL_ON_INDEX THEN
        
        RAISE_APPLICATION_ERROR(-20206, 'That time slot was just taken by another booking.');
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('book_appointment', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END book_appointment;
/
SHOW ERRORS
