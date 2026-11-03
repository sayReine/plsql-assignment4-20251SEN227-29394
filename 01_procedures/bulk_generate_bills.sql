
CREATE OR REPLACE PROCEDURE bulk_generate_bills (
    p_billed OUT NUMBER,
    p_failed OUT NUMBER
)
IS
    TYPE t_bill_rec IS RECORD (
        appt_id    appointments.appt_id%TYPE,
        patient_id appointments.patient_id%TYPE,
        amount     billing.amount%TYPE
    );
    TYPE t_bill_tab IS TABLE OF t_bill_rec;
    TYPE t_int_tab  IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;

    v_bills     t_bill_tab;
    v_err_idx   t_int_tab;
    v_err_code  t_int_tab;
    v_err_total PLS_INTEGER;

    e_bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);
BEGIN
    p_billed := 0;
    p_failed := 0;

    
    SELECT a.appt_id,
           a.patient_id,
           calculate_bill_amount(a.appt_id)
    BULK COLLECT INTO v_bills
    FROM   appointments a
    WHERE  a.status = 'COMPLETED'
    AND    NOT EXISTS (SELECT 1 FROM billing b WHERE b.appt_id = a.appt_id)
    ORDER  BY a.appt_id;

    IF v_bills.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No un-billed completed appointments found.');
        RETURN;
    END IF;

    
    
    BEGIN
        FORALL i IN 1 .. v_bills.COUNT SAVE EXCEPTIONS
            INSERT INTO billing (bill_id, patient_id, appt_id, amount, status, bill_date)
            VALUES (seq_bill.NEXTVAL, v_bills(i).patient_id, v_bills(i).appt_id,
                    v_bills(i).amount, 'UNPAID', SYSDATE);

        p_billed := SQL%ROWCOUNT;
    EXCEPTION
        WHEN e_bulk_errors THEN
            p_billed    := SQL%ROWCOUNT;
            v_err_total := SQL%BULK_EXCEPTIONS.COUNT;

            FOR j IN 1 .. v_err_total LOOP
                v_err_idx(j)  := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX;
                v_err_code(j) := SQL%BULK_EXCEPTIONS(j).ERROR_CODE;
            END LOOP;

            FOR j IN 1 .. v_err_total LOOP
                DBMS_OUTPUT.PUT_LINE('  FAILED bill for appointment ' ||
                                     v_bills(v_err_idx(j)).appt_id || ': ' ||
                                     SQLERRM(-v_err_code(j)));
                log_error('bulk_generate_bills', -v_err_code(j),
                          'Appointment ' || v_bills(v_err_idx(j)).appt_id || ': ' ||
                          SQLERRM(-v_err_code(j)));
            END LOOP;
            p_failed := v_err_total;
    END;

    DBMS_OUTPUT.PUT_LINE('Bills generated: ' || p_billed || ' created, ' || p_failed || ' failed.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('bulk_generate_bills', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END bulk_generate_bills;
/
SHOW ERRORS
