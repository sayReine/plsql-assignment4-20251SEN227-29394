
CREATE OR REPLACE FUNCTION calculate_bill_amount (
    p_appt_id IN appointments.appt_id%TYPE
) RETURN NUMBER
IS
    c_insured_discount CONSTANT NUMBER := 0.20;
    v_fee       doctors.consultation_fee%TYPE;
    v_insurance patients.insurance_provider%TYPE;
BEGIN
    SELECT d.consultation_fee, p.insurance_provider
    INTO   v_fee, v_insurance
    FROM   appointments a
           JOIN doctors  d ON d.doctor_id  = a.doctor_id
           JOIN patients p ON p.patient_id = a.patient_id
    WHERE  a.appt_id = p_appt_id;

    IF v_insurance IS NOT NULL THEN
        RETURN ROUND(v_fee * (1 - c_insured_discount), 2);
    END IF;
    RETURN v_fee;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20030, 'Appointment ' || p_appt_id || ' does not exist.');
END calculate_bill_amount;
/
SHOW ERRORS
