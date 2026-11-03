
CREATE OR REPLACE PROCEDURE add_medical_record (
    p_appt_id   IN  appointments.appt_id%TYPE,
    p_diagnosis IN  medical_records.diagnosis%TYPE,
    p_treatment IN  medical_records.treatment%TYPE,
    p_record_id OUT medical_records.record_id%TYPE,
    p_bill_id   OUT billing.bill_id%TYPE
)
IS
    TYPE t_visit IS RECORD (
        appt_id    appointments.appt_id%TYPE,
        patient_id appointments.patient_id%TYPE,
        doctor_id  appointments.doctor_id%TYPE,
        status     appointments.status%TYPE
    );
    v_visit  t_visit;
    v_amount billing.amount%TYPE;

    e_no_diagnosis  EXCEPTION;
    e_not_scheduled EXCEPTION;
BEGIN
    IF TRIM(p_diagnosis) IS NULL THEN
        RAISE e_no_diagnosis;
    END IF;

   
    SELECT appt_id, patient_id, doctor_id, status
    INTO   v_visit
    FROM   appointments
    WHERE  appt_id = p_appt_id
    FOR UPDATE;

    IF v_visit.status <> 'SCHEDULED' THEN
        RAISE e_not_scheduled;
    END IF;

    INSERT INTO medical_records (record_id, patient_id, doctor_id, appt_id, diagnosis, treatment, visit_date)
    VALUES (seq_record.NEXTVAL, v_visit.patient_id, v_visit.doctor_id, v_visit.appt_id,
            TRIM(p_diagnosis), p_treatment, SYSDATE)
    RETURNING record_id INTO p_record_id;

    update_appointment_status(v_visit.appt_id, 'COMPLETED');

    v_amount := calculate_bill_amount(v_visit.appt_id);

    INSERT INTO billing (bill_id, patient_id, appt_id, amount, status, bill_date)
    VALUES (seq_bill.NEXTVAL, v_visit.patient_id, v_visit.appt_id, v_amount, 'UNPAID', SYSDATE)
    RETURNING bill_id INTO p_bill_id;

    DBMS_OUTPUT.PUT_LINE('Record ' || p_record_id || ' saved; bill ' || p_bill_id ||
                         ' created for ' || v_amount || ' RWF.');
EXCEPTION
    WHEN e_no_diagnosis THEN
        RAISE_APPLICATION_ERROR(-20401, 'A diagnosis is required.');
    WHEN e_not_scheduled THEN
        RAISE_APPLICATION_ERROR(-20402,
            'Appointment ' || p_appt_id || ' is ' || v_visit.status || ', not SCHEDULED.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20403, 'Appointment ' || p_appt_id || ' not found.');
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('add_medical_record', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END add_medical_record;
/
SHOW ERRORS
