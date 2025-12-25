# Bloom Filter Based Semi-Join & Join Support in PostgreSQL (CS631)

This repository contains modified PostgreSQL source files implementing
**Bloom filter–based semi-join optimization** and extended **join support**
for foreign relations, developed as part of **CS631 –  Implementation techniques in DBMS**.
---

## Project Summary

PostgreSQL supports efficient SEMI JOINs for local relations, but when foreign
tables are involved, the entire foreign relation is often fetched, leading to
high network overhead.

This project improves FDW query execution by:
- Introducing Bloom filters use in SEMI JOIN queries
- Extending support to **multiple join attributes**
- Fixing correctness issues in **INNER JOIN execution**
- Dynamically sizing Bloom filters using runtime tuple counts

---

## Key Contributions

- **Dynamic Bloom Filter Construction**
  - Bloom filter size determined using actual tuple counts at runtime
  - Composite keys used for multi-attribute joins

- **Correct SEMI JOIN Semantics**
  - Each outer tuple emitted at most once
  - Early termination on first match

- **Multi-Attribute Join Support**
  - Supports multiple equality predicates combined with AND
  - Works across Hash Join, Merge Join, and Nested Loop Join

- **Improved INNER JOIN Handling**
  - Ensures correctness for joins involving foreign relations

---
## PostgreSQL Version

- PostgreSQL 16

---
## Attribution

Based on the official PostgreSQL source code and an extension of the work done by seniors.  
GitHub repository: https://github.com/sammagnet7/cs631_DB_project_FDW_Semijoin

All modifications were done for **academic purposes** as part of CS631 coursework.



## Folder Structure

