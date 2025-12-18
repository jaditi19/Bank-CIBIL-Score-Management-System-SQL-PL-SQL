/*
------------------------------------------------------
    Bank CIBIL Score Management System 
------------------------------------------------------
*/

------------------------------------------------------
-- 1. CREATE TABLES
------------------------------------------------------

CREATE TABLE customer1 (
  pan    VARCHAR2(10) PRIMARY KEY,
  name   VARCHAR2(100),
  mobile VARCHAR2(15),
  aadhar VARCHAR2(12),
  dob    DATE
);

CREATE TABLE account1 (
  acc_no NUMBER PRIMARY KEY,
  pan    VARCHAR2(10),
  acc_type VARCHAR2(20),
  balance  NUMBER,
  CONSTRAINT fk_acc1 FOREIGN KEY (pan) REFERENCES customer1(pan)
);

CREATE TABLE loan1 (
  loan_id     NUMBER PRIMARY KEY,
  pan         VARCHAR2(10),
  loan_type   VARCHAR2(50),
  amount      NUMBER,
  emi         NUMBER,
  loan_status VARCHAR2(10) DEFAULT 'ACTIVE',
  CONSTRAINT fk_loan1 FOREIGN KEY (pan) REFERENCES customer1(pan)
);

CREATE TABLE cibil_score1 (
  pan         VARCHAR2(10) PRIMARY KEY,
  score       NUMBER CHECK(score BETWEEN 300 AND 900),
  last_update DATE
);

CREATE TABLE loan_payment1 (
  payment_id   NUMBER PRIMARY KEY,
  loan_id      NUMBER,
  pan          VARCHAR2(10),
  payment_date DATE,
  amount_paid  NUMBER,
  status       VARCHAR2(10),
  CONSTRAINT fk_lp1 FOREIGN KEY (loan_id) REFERENCES loan1(loan_id)
);

COMMIT;

------------------------------------------------------
-- 2. PACKAGE loan_pkg1 (Fix mutating error)
------------------------------------------------------

CREATE OR REPLACE PACKAGE loan_pkg1 AS
  TYPE pan_table IS TABLE OF VARCHAR2(10);
  PROCEDURE add_pan(p_pan VARCHAR2);
  FUNCTION get_pans RETURN pan_table;
  PROCEDURE clear_pans;
END loan_pkg1;
/

CREATE OR REPLACE PACKAGE BODY loan_pkg1 AS
  g_pans pan_table := pan_table();

  PROCEDURE add_pan(p_pan VARCHAR2) IS
    found BOOLEAN := FALSE;
  BEGIN
    FOR i IN 1..g_pans.COUNT LOOP
      IF g_pans(i) = p_pan THEN
        found := TRUE;
      END IF;
    END LOOP;

    IF NOT found THEN
      g_pans.EXTEND;
      g_pans(g_pans.COUNT) := p_pan;
    END IF;
  END;

  FUNCTION get_pans RETURN pan_table IS
  BEGIN
    RETURN g_pans;
  END;

  PROCEDURE clear_pans IS
  BEGIN
    g_pans := pan_table();
  END;
END loan_pkg1;
/
COMMIT;

------------------------------------------------------
-- 3. PROCEDURE update_cibil1
------------------------------------------------------

CREATE OR REPLACE PROCEDURE update_cibil1(p_pan VARCHAR2) AS
  v_active NUMBER;
  v_closed NUMBER;
  v_missed NUMBER;
  v_late   NUMBER;
  v_on     NUMBER;
  v_bal    NUMBER;
  v_score  NUMBER := 700;
BEGIN
  SELECT NVL(SUM(CASE WHEN loan_status='ACTIVE' THEN 1 END),0),
         NVL(SUM(CASE WHEN loan_status='CLOSED' THEN 1 END),0)
  INTO v_active, v_closed
  FROM loan1 WHERE pan=p_pan;

  SELECT NVL(SUM(CASE WHEN status='MISSED' THEN 1 END),0),
         NVL(SUM(CASE WHEN status='LATE' THEN 1 END),0),
         NVL(SUM(CASE WHEN status='ONTIME' THEN 1 END),0)
  INTO v_missed, v_late, v_on
  FROM loan_payment1 WHERE pan=p_pan;

  SELECT NVL(SUM(balance),0) INTO v_bal FROM account1 WHERE pan=p_pan;

  v_score := v_score 
             - (v_active*10)
             - (v_missed*50)
             - (v_late*20)
             + (v_on*15)
             + (v_closed*30);

  IF v_bal < 10000 THEN v_score := v_score - 15; END IF;
  IF v_bal > 100000 THEN v_score := v_score + 10; END IF;

  IF v_score < 300 THEN v_score := 300; END IF;
  IF v_score > 900 THEN v_score := 900; END IF;

  MERGE INTO cibil_score1 cs
  USING (SELECT p_pan pan FROM dual) src
  ON (cs.pan = src.pan)
  WHEN MATCHED THEN UPDATE SET score=v_score, last_update=SYSDATE
  WHEN NOT MATCHED THEN INSERT VALUES(p_pan,v_score,SYSDATE);
END;
/
COMMIT;

------------------------------------------------------
-- 4. TRIGGERS
------------------------------------------------------

CREATE OR REPLACE TRIGGER trg_loan_before1
BEFORE INSERT OR UPDATE ON loan1
FOR EACH ROW
BEGIN
  loan_pkg1.add_pan(:NEW.pan);
END;
/
CREATE OR REPLACE TRIGGER trg_loan_after1
AFTER INSERT OR UPDATE ON loan1
DECLARE 
  l loan_pkg1.pan_table;
BEGIN
  l := loan_pkg1.get_pans;
  FOR i IN 1..l.COUNT LOOP
    update_cibil1(l(i));
  END LOOP;
  loan_pkg1.clear_pans;
END;
/
COMMIT;

------------------------------------------------------
-- 5. PROCEDURE record_payment1
------------------------------------------------------

CREATE OR REPLACE PROCEDURE record_payment1(
  p_pid NUMBER,
  p_lid NUMBER,
  p_pan VARCHAR2,
  p_date DATE,
  p_amt NUMBER,
  p_stat VARCHAR2
) AS
  v_paid NUMBER;
  v_amt  NUMBER;
BEGIN
  INSERT INTO loan_payment1 VALUES(p_pid,p_lid,p_pan,p_date,p_amt,p_stat);

  SELECT NVL(SUM(amount_paid),0)
  INTO v_paid FROM loan_payment1 WHERE loan_id=p_lid;

  SELECT amount INTO v_amt FROM loan1 WHERE loan_id=p_lid;

  IF v_paid >= v_amt THEN
    UPDATE loan1 SET loan_status='CLOSED' WHERE loan_id=p_lid;
  END IF;

  update_cibil1(p_pan);
END;
/
COMMIT;

------------------------------------------------------
-- 6. INSERT DATA
------------------------------------------------------

INSERT INTO customer1 VALUES ('AAAAA1111A','Rohan Sharma','9876500001','111122223333',DATE '1998-05-10');
INSERT INTO customer1 VALUES ('BBBBB2222B','Sneha Patil','9876500002','222233334444',DATE '2000-07-15');
INSERT INTO customer1 VALUES ('CCCCC3333C','Vikas Gupta','9876500003','333344445555',DATE '1995-11-22');
INSERT INTO customer1 VALUES ('DDDDD4444D','Priya Nair','9876500004','444455556666',DATE '1999-03-08');
INSERT INTO customer1 VALUES ('EEEEE5555E','Rahul Verma','9876500005','555566667777',DATE '1997-12-30');
INSERT INTO customer1 VALUES ('ABCDE1234F','Aditi Jadhav','9876543210','123412341234',DATE '2003-01-01');

INSERT INTO account1 VALUES (2001,'AAAAA1111A','Savings',35000);
INSERT INTO account1 VALUES (2002,'AAAAA1111A','Current',50000);
INSERT INTO account1 VALUES (2003,'BBBBB2222B','Savings',45000);
INSERT INTO account1 VALUES (2004,'CCCCC3333C','Savings',12000);
INSERT INTO account1 VALUES (2005,'CCCCC3333C','Salary',25000);
INSERT INTO account1 VALUES (2006,'DDDDD4444D','Savings',8000);
INSERT INTO account1 VALUES (2007,'EEEEE5555E','Savings',60000);
INSERT INTO account1 VALUES (1001,'ABCDE1234F','Savings',50000);

INSERT INTO loan1 VALUES (3001,'AAAAA1111A','Home Loan',1200000,15000,'ACTIVE');
INSERT INTO loan1 VALUES (3002,'AAAAA1111A','Car Loan',550000,8500,'ACTIVE');
INSERT INTO loan1 VALUES (3003,'BBBBB2222B','Personal Loan',250000,6500,'ACTIVE');
INSERT INTO loan1 VALUES (3004,'CCCCC3333C','Education Loan',400000,9500,'ACTIVE');
INSERT INTO loan1 VALUES (3005,'DDDDD4444D','Bike Loan',90000,2500,'ACTIVE');
INSERT INTO loan1 VALUES (3006,'EEEEE5555E','Business Loan',750000,12000,'ACTIVE');
INSERT INTO loan1 VALUES (3007,'ABCDE1234F','Personal Loan',300000,8500,'ACTIVE');

INSERT INTO cibil_score1 VALUES ('AAAAA1111A',700,SYSDATE);
INSERT INTO cibil_score1 VALUES ('BBBBB2222B',720,SYSDATE);
INSERT INTO cibil_score1 VALUES ('CCCCC3333C',750,SYSDATE);
INSERT INTO cibil_score1 VALUES ('DDDDD4444D',680,SYSDATE);
INSERT INTO cibil_score1 VALUES ('EEEEE5555E',800,SYSDATE);
INSERT INTO cibil_score1 VALUES ('ABCDE1234F',750,SYSDATE);

COMMIT;

------------------------------------------------------
-- 7. UPDATE CIBIL FOR ALL
------------------------------------------------------

BEGIN
  update_cibil1('AAAAA1111A');
  update_cibil1('BBBBB2222B');
  update_cibil1('CCCCC3333C');
  update_cibil1('DDDDD4444D');
  update_cibil1('EEEEE5555E');
  update_cibil1('ABCDE1234F');
END;
/
COMMIT;

------------------------------------------------------
-- SHOW CIBIL
------------------------------------------------------
SELECT * FROM cibil_score1 ORDER BY pan;
