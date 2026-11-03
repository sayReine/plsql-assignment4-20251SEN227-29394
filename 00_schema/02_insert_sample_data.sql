

-- ---------- Departments ----------
INSERT INTO departments VALUES (10, 'Cardiology',       'Block A');
INSERT INTO departments VALUES (20, 'Pediatrics',       'Block B');
INSERT INTO departments VALUES (30, 'General Medicine', 'Block C');
INSERT INTO departments VALUES (40, 'Orthopedics',      'Block D');

-- ---------- Doctors (id, name, specialty, dept, fee RWF, status, hired) ----------
INSERT INTO doctors VALUES (101, 'Dr. Alice Uwase',            'Cardiologist',         10, 50000, 'ACTIVE',   DATE '2015-02-01');
INSERT INTO doctors VALUES (102, 'Dr. Eric Habimana',          'Cardiologist',         10, 55000, 'ACTIVE',   DATE '2012-06-15');
INSERT INTO doctors VALUES (103, 'Dr. Grace Mukamana',         'Pediatrician',         20, 30000, 'ACTIVE',   DATE '2018-09-10');
INSERT INTO doctors VALUES (104, 'Dr. Paul Nkurunziza',        'Pediatrician',         20, 32000, 'ON_LEAVE', DATE '2016-03-20');
INSERT INTO doctors VALUES (105, 'Dr. Sandra Ingabire',        'General Practitioner', 30, 20000, 'ACTIVE',   DATE '2019-01-07');
INSERT INTO doctors VALUES (106, 'Dr. Jean Bosco Niyonsenga',  'General Practitioner', 30, 22000, 'ACTIVE',   DATE '2017-11-28');
INSERT INTO doctors VALUES (107, 'Dr. Diane Uwimana',          'Orthopedic Surgeon',   40, 60000, 'ACTIVE',   DATE '2014-05-05');
INSERT INTO doctors VALUES (108, 'Dr. Samuel Mugabo',          'Orthopedic Surgeon',   40, 58000, 'RETIRED',  DATE '2005-08-12');

-- ---------- Patients (NULL insurance = uninsured) ----------
INSERT INTO patients VALUES (1001, 'John Mugisha',        DATE '1985-03-14', 'M', '0788000001', 'RSSB', DATE '2024-01-10');
INSERT INTO patients VALUES (1002, 'Aline Uwera',         DATE '1992-07-22', 'F', '0788000002', 'MMI',  DATE '2024-02-14');
INSERT INTO patients VALUES (1003, 'Eric Ndayisaba',      DATE '1978-11-05', 'M', '0788000003', NULL,   DATE '2024-03-01');
INSERT INTO patients VALUES (1004, 'Chantal Mukeshimana', DATE '2015-01-30', 'F', '0788000004', 'RSSB', DATE '2024-03-18');
INSERT INTO patients VALUES (1005, 'David Habineza',      DATE '2020-06-18', 'M', '0788000005', NULL,   DATE '2024-04-02');
INSERT INTO patients VALUES (1006, 'Esther Mutoni',       DATE '1969-09-09', 'F', '0788000006', 'MMI',  DATE '2024-04-25');
INSERT INTO patients VALUES (1007, 'John Mugisha',        DATE '1999-12-01', 'M', '0788000007', NULL,   DATE '2024-05-11');
INSERT INTO patients VALUES (1008, 'Claudine Uwamahoro',  DATE '1990-04-25', 'F', '0788000008', 'RSSB', DATE '2024-06-09');
INSERT INTO patients VALUES (1009, 'Patrick Nsengimana',  DATE '1955-02-17', 'M', '0788000009', 'RSSB', DATE '2024-06-30');
INSERT INTO patients VALUES (1010, 'Divine Ishimwe',      DATE '2018-08-08', 'F', '0788000010', NULL,   DATE '2024-07-19');
INSERT INTO patients VALUES (1011, 'Olivier Bizimana',    DATE '1983-10-12', 'M', '0788000011', 'MMI',  DATE '2024-08-05');
INSERT INTO patients VALUES (1012, 'Joyce Kamikazi',      DATE '1975-05-30', 'F', '0788000012', NULL,   DATE '2024-09-12');

-- ---------- Appointments ----------
-- Completed
INSERT INTO appointments VALUES (5001, 1001, 101, TO_DATE('2026-09-01 09:00','YYYY-MM-DD HH24:MI'), 'Chest pain',      'COMPLETED', DATE '2026-08-25');
INSERT INTO appointments VALUES (5002, 1002, 105, TO_DATE('2026-09-03 10:00','YYYY-MM-DD HH24:MI'), 'Fever',           'COMPLETED', DATE '2026-08-28');
INSERT INTO appointments VALUES (5003, 1004, 103, TO_DATE('2026-09-05 11:00','YYYY-MM-DD HH24:MI'), 'Vaccination',     'COMPLETED', DATE '2026-08-30');
INSERT INTO appointments VALUES (5004, 1006, 102, TO_DATE('2026-09-10 14:00','YYYY-MM-DD HH24:MI'), 'Hypertension',    'COMPLETED', DATE '2026-09-02');
INSERT INTO appointments VALUES (5005, 1009, 107, TO_DATE('2026-09-12 09:30','YYYY-MM-DD HH24:MI'), 'Knee pain',       'COMPLETED', DATE '2026-09-05');
INSERT INTO appointments VALUES (5006, 1003, 106, TO_DATE('2026-09-15 15:00','YYYY-MM-DD HH24:MI'), 'Headache',        'COMPLETED', DATE '2026-09-08');
INSERT INTO appointments VALUES (5007, 1001, 105, TO_DATE('2026-10-02 10:30','YYYY-MM-DD HH24:MI'), 'Follow-up',       'COMPLETED', DATE '2026-09-25');
INSERT INTO appointments VALUES (5008, 1008, 106, TO_DATE('2026-10-05 11:30','YYYY-MM-DD HH24:MI'), 'Stomach ache',    'COMPLETED', DATE '2026-09-28');
INSERT INTO appointments VALUES (5009, 1011, 101, TO_DATE('2026-10-08 08:30','YYYY-MM-DD HH24:MI'), 'Palpitations',    'COMPLETED', DATE '2026-10-01');
INSERT INTO appointments VALUES (5010, 1012, 107, TO_DATE('2026-10-10 13:00','YYYY-MM-DD HH24:MI'), 'Back pain',       'COMPLETED', DATE '2026-10-03');
-- Cancelled
INSERT INTO appointments VALUES (5011, 1005, 103, TO_DATE('2026-08-10 09:00','YYYY-MM-DD HH24:MI'), 'Cough',          'CANCELLED', DATE '2026-08-01');
INSERT INTO appointments VALUES (5012, 1010, 103, TO_DATE('2026-08-20 09:30','YYYY-MM-DD HH24:MI'), 'Skin rash',      'CANCELLED', DATE '2026-08-12');
INSERT INTO appointments VALUES (5013, 1007, 105, TO_DATE('2026-10-20 12:00','YYYY-MM-DD HH24:MI'), 'Check-up',       'CANCELLED', DATE '2026-10-12');
-- Scheduled (relative to today so they are always in the future)
INSERT INTO appointments VALUES (5014, 1002, 101, TRUNC(SYSDATE) + 3 +  9/24, 'Cardiac review',     'SCHEDULED', SYSDATE);
INSERT INTO appointments VALUES (5015, 1006, 105, TRUNC(SYSDATE) + 4 + 10/24, 'Blood pressure check','SCHEDULED', SYSDATE);
INSERT INTO appointments VALUES (5016, 1010, 103, TRUNC(SYSDATE) + 5 + 11/24, 'Vaccination',        'SCHEDULED', SYSDATE);

-- ---------- Medical records (for the 10 completed visits) ----------
INSERT INTO medical_records VALUES (7001, 1001, 101, 5001, 'Angina pectoris (suspected)', 'ECG, aspirin, lifestyle advice',     DATE '2026-09-01');
INSERT INTO medical_records VALUES (7002, 1002, 105, 5002, 'Viral fever',                 'Paracetamol, rest, fluids',           DATE '2026-09-03');
INSERT INTO medical_records VALUES (7003, 1004, 103, 5003, 'Routine immunization',        'MMR vaccine administered',            DATE '2026-09-05');
INSERT INTO medical_records VALUES (7004, 1006, 102, 5004, 'Hypertension',                'Amlodipine 5 mg daily',               DATE '2026-09-10');
INSERT INTO medical_records VALUES (7005, 1009, 107, 5005, 'Osteoarthritis of the knee',  'Physiotherapy, NSAIDs',               DATE '2026-09-12');
INSERT INTO medical_records VALUES (7006, 1003, 106, 5006, 'Tension headache',            'Analgesics, hydration',               DATE '2026-09-15');
INSERT INTO medical_records VALUES (7007, 1001, 105, 5007, 'Follow-up: condition stable', 'Continue current medication',        DATE '2026-10-02');
INSERT INTO medical_records VALUES (7008, 1008, 106, 5008, 'Gastritis',                   'Antacids, dietary advice',            DATE '2026-10-05');
INSERT INTO medical_records VALUES (7009, 1011, 101, 5009, 'Cardiac arrhythmia',          'Holter monitoring, beta blocker',     DATE '2026-10-08');
INSERT INTO medical_records VALUES (7010, 1012, 107, 5010, 'Lumbar strain',               'Rest, physiotherapy',                 DATE '2026-10-10');

-- ---------- Bills (5007-5010 intentionally NOT billed yet) ----------
-- Insured patients receive a 20% discount on the doctor's fee.
INSERT INTO billing VALUES (4001, 1001, 5001, 40000, 'PAID',   DATE '2026-09-01');
INSERT INTO billing VALUES (4002, 1002, 5002, 16000, 'PAID',   DATE '2026-09-03');
INSERT INTO billing VALUES (4003, 1004, 5003, 24000, 'PAID',   DATE '2026-09-05');
INSERT INTO billing VALUES (4004, 1006, 5004, 44000, 'UNPAID', DATE '2026-09-10');
INSERT INTO billing VALUES (4005, 1009, 5005, 48000, 'UNPAID', DATE '2026-09-12');
INSERT INTO billing VALUES (4006, 1003, 5006, 22000, 'PAID',   DATE '2026-09-15');

COMMIT;

PROMPT Sample data inserted.
