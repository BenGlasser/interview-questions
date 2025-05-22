# 🧠 Senior Fullstack Developer Interview – Technical Questions

**Stack**: React.js · Node.js · MySQL
**Focus Areas**: Performance, Scalability, Architecture, Debugging
**Interview Duration**: 45 minutes (30 mins technical, 15 mins intro/questions)

---

## ✅ Scoring Guide
- [ ] **1 = Poor** – Incomplete or incorrect answer
- [ ] **2 = Fair** – Basic understanding with some gaps
- [ ] **3 = Excellent** – Deep expertise with clear examples

---

## 🧩 Technical Questions (30 minutes)

---

### 1. React Performance Optimization
**Question**:
How would you optimize performance in a React application that renders a large, dynamic dataset (e.g., a list with thousands of items)?

**Rubric**:
- [ ] **Poor** – Vague about `useEffect` or pagination only
- [ ] **Fair** – Mentions virtualization (`react-window`), basic memoization
- [ ] **Excellent** – Virtualization, `React.memo`, `useMemo`, debouncing, batching, lazy loading

---

### 2. Node.js Scalability
**Question**:
How do you handle CPU-intensive operations or large dataset processing in Node.js while keeping the app responsive?

**Rubric**:
- [ ] **Poor** – Blocking code, no async consideration
- [ ] **Fair** – Uses async, streams, or background jobs
- [ ] **Excellent** – Worker threads, queues, streaming, chunking, task scheduling

---

### 3. MySQL Query Optimization
**Question**:
Describe how you would identify and fix performance issues in a slow MySQL query used in production.

**Rubric**:
- [ ] **Poor** – Vague idea of “optimize the query”
- [ ] **Fair** – Uses EXPLAIN plan, indexes, and joins
- [ ] **Excellent** – Covers EXPLAIN, indexing, avoiding `SELECT *`, caching, slow query logs

---

### 4. Designing APIs for Large Datasets
**Question**:
How would you design an API endpoint to return a list of items from a dataset with millions of records?

**Rubric**:
- [ ] **Poor** – No pagination; fetches everything
- [ ] **Fair** – Offset-based pagination and basic filters
- [ ] **Excellent** – Cursor pagination, caching, shaping, rate limiting

---

### 5. React + Backend Integration
**Question**:
How do you manage state and side effects when consuming large datasets from a backend in React?

**Rubric**:
- [ ] **Poor** – Just uses `fetch` + `useEffect`
- [ ] **Fair** – SWR/React Query with error handling
- [ ] **Excellent** – Advanced caching, optimistic updates, stale-while-revalidate patterns

---

### 6. System Design: Real-Time Large List Viewer
**Question**:
Design a system where users can view, search, and filter millions of product records in real-time. Walk me through the architecture.

**Rubric**:
- [ ] **Poor** – Vague, unclear separation of layers
- [ ] **Fair** – Three-tier setup with filters and queries
- [ ] **Excellent** – Virtualized frontend, optimized backend, caching, search indexing

---

### 7. Debugging Slowness Under Load
**Question**:
Users report that part of the app is slow when loading lots of data. How would you debug this?

**Rubric**:
- [ ] **Poor** – No real strategy or tooling
- [ ] **Fair** – Logs, DB analysis
- [ ] **Excellent** – Profilers, APM, performance logs, full-stack monitoring

---

### 8. Security in Fullstack Apps
**Question**:
What are some common security risks in fullstack apps and how do you prevent them?

**Rubric**:
- [ ] **Poor** – Only mentions “sanitizing input”
- [ ] **Fair** – XSS, CSRF, SQLi, token usage
- [ ] **Excellent** – Adds secure cookies, CSP, OWASP Top 10, validation layers

---

### 9. Code Review Philosophy
**Question**:
What do you focus on when reviewing code from your teammates?

**Rubric**:
- [ ] **Poor** – Skims or only comments on syntax
- [ ] **Fair** – Code structure, readability, logic
- [ ] **Excellent** – Testability, long-term maintainability, mentoring through PRs

---

### 10. Refactoring Legacy Code
**Question**:
You inherit a legacy component (React + Node API) that’s slow and hard to maintain. What’s your approach to improving it?

**Rubric**:
- [ ] **Poor** – “Rewrite it” without plan
- [ ] **Fair** – Refactor with test coverage
- [ ] **Excellent** – Incremental changes, profiling, rollback strategy, tests

---

## 🧮 Final Score: ____ / 30

---

## 📋 Recommendation:
- [ ] Strong Hire
- [ ] Hire
- [ ] No Hire
- [ ] Follow-Up Interview Needed