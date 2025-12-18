# Bank CIBIL Score Management System (SQL / PL-SQL)

## 📌 Project Description
This project is a **Bank CIBIL Score Management System** developed using **Oracle SQL and PL/SQL**.  
It simulates how banks manage customer details, accounts, loans, loan payments, and dynamically calculate **CIBIL credit scores** based on customer financial behavior.

---

## 🛠️ Technologies Used
- Oracle SQL
- PL/SQL
- Triggers
- Packages
- Stored Procedures

---

## 🗂️ Database Objects
### Tables
- `customer1`
- `account1`
- `loan1`
- `loan_payment1`
- `cibil_score1`

### PL/SQL Components
- **Package**: `loan_pkg1` (used to fix mutating table errors)
- **Procedure**: `update_cibil1`
- **Procedure**: `record_payment1`
- **Triggers**:
  - `trg_loan_before1`
  - `trg_loan_after1`

---

## ⚙️ Key Features
- Automatic CIBIL score calculation
- Score range enforced between **300 – 900**
- Dynamic updates based on:
  - Active & closed loans
  - Missed, late, and on-time payments
  - Account balance
- Uses triggers to update CIBIL score automatically on loan changes
- Handles mutating table errors using PL/SQL package




