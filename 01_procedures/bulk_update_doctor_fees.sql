
CREATE OR REPLACE PROCEDURE bulk_update_doctor_fees (
    p_dept_id IN  departments.dept_id%TYPE,
    p_percent IN  NUMBER,
    p_updated OUT NUMBER,
    p_failed  OUT NUMBER
)
IS
    c_batch_size CONSTANT PLS_INTEGER := 100;

    TYPE t_id_tab  IS TABLE OF doctors.doctor_id%TYPE;
    TYPE t_fee_tab IS TABLE OF doctors.consultation_fee%TYPE;
    TYPE t_int_tab IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;

    v_ids       t_id_tab;
    v_fees      t_fee_tab;
    v_err_idx   t_int_tab;
    v_err_code  t_int_tab;
    v_err_total PLS_INTEGER;
    v_batch_ok  PLS_INTEGER;
    v_dept_cnt  PLS_INTEGER;

    e_bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);  

    CURSOR c_docs (cp_dept doctors.dept_id%TYPE) IS
        SELECT doctor_id, consultation_fee
        FROM   doctors
        WHERE  dept_id = cp_dept
        AND    status  = 'ACTIVE'
        ORDER  BY doctor_id;
BEGIN
    p_updated := 0;
    p_failed  := 0;

    IF p_percent IS NULL OR p_percent <= -100 THEN
        RAISE_APPLICATION_ERROR(-20801, 'Percentage must be a number greater than -100.');
    END IF;

    SELECT COUNT(*) INTO v_dept_cnt FROM departments WHERE dept_id = p_dept_id;
    IF v_dept_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20802, 'Department ' || p_dept_id || ' does not exist.');
    END IF;

    OPEN c_docs(p_dept_id);
    LOOP
        
        FETCH c_docs BULK COLLECT INTO v_ids, v_fees LIMIT c_batch_size;
        EXIT WHEN v_ids.COUNT = 0;

        FOR i IN 1 .. v_ids.COUNT LOOP
            v_fees(i) := ROUND(v_fees(i) * (1 + p_percent / 100), 2);
        END LOOP;

        BEGIN
            
            FORALL i IN 1 .. v_ids.COUNT SAVE EXCEPTIONS
                UPDATE doctors
                SET    consultation_fee = v_fees(i)
                WHERE  doctor_id = v_ids(i);

            v_batch_ok := SQL%ROWCOUNT;
        EXCEPTION
            WHEN e_bulk_errors THEN
                v_batch_ok  := SQL%ROWCOUNT;             
                v_err_total := SQL%BULK_EXCEPTIONS.COUNT;

                
                FOR j IN 1 .. v_err_total LOOP
                    v_err_idx(j)  := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX;
                    v_err_code(j) := SQL%BULK_EXCEPTIONS(j).ERROR_CODE;
                END LOOP;

                FOR j IN 1 .. v_err_total LOOP
                    DBMS_OUTPUT.PUT_LINE('  FAILED doctor ' || v_ids(v_err_idx(j)) ||
                                         ' (new fee ' || v_fees(v_err_idx(j)) || '): ' ||
                                         SQLERRM(-v_err_code(j)));
                    log_error('bulk_update_doctor_fees', -v_err_code(j),
                              'Doctor ' || v_ids(v_err_idx(j)) || ' new fee ' ||
                              v_fees(v_err_idx(j)) || ': ' || SQLERRM(-v_err_code(j)));
                END LOOP;
                p_failed := p_failed + v_err_total;
        END;

        p_updated := p_updated + v_batch_ok;
    END LOOP;
    CLOSE c_docs;

    DBMS_OUTPUT.PUT_LINE('Fee update finished: ' || p_updated || ' updated, ' ||
                         p_failed || ' failed.');
EXCEPTION
    WHEN OTHERS THEN
        IF c_docs%ISOPEN THEN
            CLOSE c_docs;
        END IF;
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('bulk_update_doctor_fees', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END bulk_update_doctor_fees;
/
SHOW ERRORS
