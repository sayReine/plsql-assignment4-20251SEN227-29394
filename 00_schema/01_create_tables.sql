
BEGIN
    FOR t IN (SELECT table_name FROM user_tables
              WHERE table_name IN ('BILLING','MEDICAL_RECORDS','APPOINTMENTS',
                                   'PATIENTS','DOCTORS','DEPARTMENTS',
                                   'ERROR_LOG','PERF_DEMO'))
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;

    FOR s IN (SELECT sequence_name FROM user_sequences
              WHERE sequence_name IN ('SEQ_DEPT','SEQ_DOCTOR','SEQ_PATIENT','SEQ_APPT',
                                      'SEQ_RECORD','SEQ_BILL','SEQ_ERROR_LOG'))
    LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/


CREATE SEQUENCE seq_dept      START WITH 50   INCREMENT BY 10;
CREATE SEQUENCE seq_doctor    START WITH 201;
CREATE SEQUENCE seq_patient   START WITH 2001;
CREATE SEQUENCE seq_appt      START WITH 6001;
CREATE SEQUENCE seq_record    START WITH 8001;
CREATE SEQUENCE seq_bill      START WITH 4501;
CREATE SEQUENCE seq_error_log START WITH 1;


CREATE TABLE departments (
    dept_id    NUMBER(4)     CONSTRAINT pk_departments PRIMARY KEY,
    dept_name  VARCHAR2(50)  NOT NULL
                             CONSTRAINT uq_dept_name UNIQUE,
    location   VARCHAR2(50)
);


CREATE TABLE doctors (
    doctor_id        NUMBER(6)     CONSTRAINT pk_doctors PRIMARY KEY,
    full_name        VARCHAR2(80)  NOT NULL,
    specialty        VARCHAR2(50)  NOT NULL,
    dept_id          NUMBER(4)     NOT NULL
                                   CONSTRAINT fk_doctor_dept REFERENCES departments(dept_id),
    consultation_fee NUMBER(10,2)  NOT NULL
                                   CONSTRAINT ck_doctor_fee
                                   CHECK (consultation_fee > 0 AND consultation_fee <= 100000),
    status           VARCHAR2(10)  DEFAULT 'ACTIVE' NOT NULL
                                   CONSTRAINT ck_doctor_status
                                   CHECK (status IN ('ACTIVE','ON_LEAVE','RETIRED')),
    hire_date        DATE          DEFAULT SYSDATE
);


CREATE TABLE patients (
    patient_id         NUMBER(8)     CONSTRAINT pk_patients PRIMARY KEY,
    full_name          VARCHAR2(80)  NOT NULL,
    date_of_birth      DATE          NOT NULL,
    gender             CHAR(1)       NOT NULL
                                     CONSTRAINT ck_patient_gender CHECK (gender IN ('M','F')),
    phone              VARCHAR2(20)  NOT NULL
                                     CONSTRAINT uq_patient_phone UNIQUE,
    insurance_provider VARCHAR2(40),              
    registered_on      DATE          DEFAULT SYSDATE NOT NULL
);


CREATE TABLE appointments (
    appt_id     NUMBER(10)    CONSTRAINT pk_appointments PRIMARY KEY,
    patient_id  NUMBER(8)     NOT NULL
                              CONSTRAINT fk_appt_patient REFERENCES patients(patient_id),
    doctor_id   NUMBER(6)     NOT NULL
                              CONSTRAINT fk_appt_doctor  REFERENCES doctors(doctor_id),
    appt_date   DATE          NOT NULL,
    reason      VARCHAR2(200),
    status      VARCHAR2(12)  DEFAULT 'SCHEDULED' NOT NULL
                              CONSTRAINT ck_appt_status
                              CHECK (status IN ('SCHEDULED','COMPLETED','CANCELLED')),
    created_on  DATE          DEFAULT SYSDATE NOT NULL
);


CREATE UNIQUE INDEX uq_doctor_slot ON appointments (
    CASE WHEN status <> 'CANCELLED' THEN doctor_id END,
    CASE WHEN status <> 'CANCELLED' THEN appt_date END
);

CREATE INDEX ix_appt_patient ON appointments(patient_id);
CREATE INDEX ix_appt_doctor  ON appointments(doctor_id);


CREATE TABLE medical_records (
    record_id   NUMBER(10)     CONSTRAINT pk_medical_records PRIMARY KEY,
    patient_id  NUMBER(8)      NOT NULL
                               CONSTRAINT fk_rec_patient REFERENCES patients(patient_id),
    doctor_id   NUMBER(6)      NOT NULL
                               CONSTRAINT fk_rec_doctor  REFERENCES doctors(doctor_id),
    appt_id     NUMBER(10)     CONSTRAINT fk_rec_appt REFERENCES appointments(appt_id)
                               CONSTRAINT uq_rec_appt UNIQUE,
    diagnosis   VARCHAR2(200)  NOT NULL,
    treatment   VARCHAR2(400),
    visit_date  DATE           DEFAULT SYSDATE NOT NULL
);

CREATE INDEX ix_rec_patient ON medical_records(patient_id);


CREATE TABLE billing (
    bill_id     NUMBER(10)    CONSTRAINT pk_billing PRIMARY KEY,
    patient_id  NUMBER(8)     NOT NULL
                              CONSTRAINT fk_bill_patient REFERENCES patients(patient_id),
    appt_id     NUMBER(10)    NOT NULL
                              CONSTRAINT fk_bill_appt REFERENCES appointments(appt_id)
                              CONSTRAINT uq_bill_appt UNIQUE,
    amount      NUMBER(10,2)  NOT NULL
                              CONSTRAINT ck_bill_amount CHECK (amount >= 0),
    status      VARCHAR2(10)  DEFAULT 'UNPAID' NOT NULL
                              CONSTRAINT ck_bill_status
                              CHECK (status IN ('UNPAID','PAID','WAIVED')),
    bill_date   DATE          DEFAULT SYSDATE NOT NULL
);

CREATE INDEX ix_bill_patient ON billing(patient_id);


CREATE TABLE error_log (
    log_id        NUMBER        CONSTRAINT pk_error_log PRIMARY KEY,
    source_name   VARCHAR2(60)  NOT NULL,
    error_code    NUMBER,
    error_message VARCHAR2(4000),
    logged_at     TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);


CREATE TABLE perf_demo (
    id    NUMBER,
    note  VARCHAR2(50)
);

PROMPT Tables created.
