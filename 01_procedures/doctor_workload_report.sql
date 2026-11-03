
CREATE OR REPLACE PROCEDURE doctor_workload_report (
    p_dept_id IN departments.dept_id%TYPE
)
IS
    CURSOR c_workload (cp_dept doctors.dept_id%TYPE) IS
        SELECT d.doctor_id,
               d.full_name,
               COUNT(a.appt_id) AS total_appts
        FROM   doctors d
               LEFT JOIN appointments a
                      ON a.doctor_id = d.doctor_id
                     AND a.status   <> 'CANCELLED'
        WHERE  d.dept_id = cp_dept
        GROUP  BY d.doctor_id, d.full_name
        ORDER  BY d.full_name;

    TYPE t_workload IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(80);
    v_workload     t_workload;
    v_key          VARCHAR2(80);
    v_dept_name    departments.dept_name%TYPE;
    v_busiest_name VARCHAR2(80);
    v_busiest_cnt  PLS_INTEGER := -1;
BEGIN
    SELECT dept_name INTO v_dept_name
    FROM   departments
    WHERE  dept_id = p_dept_id;

   
    FOR rec IN c_workload(p_dept_id) LOOP
        v_workload(rec.full_name) := rec.total_appts;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('=== Workload report: ' || v_dept_name || ' ===');

    IF v_workload.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('This department has no doctors.');
        RETURN;
    END IF;

    
    v_key := v_workload.FIRST;
    WHILE v_key IS NOT NULL LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(v_key, 32) || v_workload(v_key) || ' appointment(s)');
        IF v_workload(v_key) > v_busiest_cnt THEN
            v_busiest_cnt  := v_workload(v_key);
            v_busiest_name := v_key;
        END IF;
        v_key := v_workload.NEXT(v_key);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Doctors: ' || v_workload.COUNT ||
                         ' | Busiest: ' || v_busiest_name || ' (' || v_busiest_cnt || ')');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20701, 'Department ' || p_dept_id || ' does not exist.');
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('doctor_workload_report', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END doctor_workload_report;
/
SHOW ERRORS
