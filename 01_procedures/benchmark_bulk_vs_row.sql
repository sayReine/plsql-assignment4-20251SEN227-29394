
CREATE OR REPLACE PROCEDURE benchmark_bulk_vs_row (
    p_rows    IN  PLS_INTEGER DEFAULT 50000,
    p_row_ms  OUT NUMBER,
    p_bulk_ms OUT NUMBER
)
IS
    TYPE t_id_tab IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
    v_ids   t_id_tab;
    v_start PLS_INTEGER;
BEGIN
    IF p_rows IS NULL OR p_rows < 1 OR p_rows > 1000000 THEN
        RAISE_APPLICATION_ERROR(-20950, 'Number of rows must be between 1 and 1,000,000.');
    END IF;

    SAVEPOINT bench_start;

    
    v_start := DBMS_UTILITY.GET_TIME;
    FOR i IN 1 .. p_rows LOOP
        INSERT INTO perf_demo (id, note) VALUES (i, 'row-by-row');
    END LOOP;
    p_row_ms := (DBMS_UTILITY.GET_TIME - v_start) * 10;
    ROLLBACK TO bench_start;

    
    FOR i IN 1 .. p_rows LOOP
        v_ids(i) := i;
    END LOOP;

    v_start := DBMS_UTILITY.GET_TIME;
    FORALL i IN 1 .. p_rows
        INSERT INTO perf_demo (id, note) VALUES (v_ids(i), 'bulk');
    p_bulk_ms := (DBMS_UTILITY.GET_TIME - v_start) * 10;
    ROLLBACK TO bench_start;

    DBMS_OUTPUT.PUT_LINE('Rows inserted per method : ' || p_rows);
    DBMS_OUTPUT.PUT_LINE('Row-by-row loop          : ' || p_row_ms  || ' ms');
    DBMS_OUTPUT.PUT_LINE('FORALL bulk insert       : ' || p_bulk_ms || ' ms');
    IF p_bulk_ms > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Bulk was about ' || ROUND(p_row_ms / p_bulk_ms, 1) || 'x faster.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Bulk finished below timer resolution (<10 ms); increase p_rows.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            log_error('benchmark_bulk_vs_row', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END benchmark_bulk_vs_row;
/
SHOW ERRORS
