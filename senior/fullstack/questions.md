Here’s a well-rounded 30-minute technical interview plan for a senior fullstack developer focused on React.js, Node.js, MySQL, and performance with large datasets. The questions cover frontend, backend, database optimization, system design, and debugging.

⸻

🕑 Interview Structure (45 mins)

Time	Activity
0–5 min	Introduction and rapport building
5–35 min	Technical questions
35–45 min	Candidate questions and closing



⸻

✅ Technical Questions (with Rubric)

⸻

1. React Performance Optimization

Question: How would you optimize performance in a React application that renders a large, dynamic dataset (e.g., a list with thousands of items)?

Rubric:
	•	Poor: Mentions useEffect/useState vaguely; no real strategy; suggests pagination without detail.
	•	Fair: Mentions virtualization libraries (e.g., react-window), basic memoization, key usage.
	•	Excellent: Explains virtualization, component memoization (React.memo, useMemo, useCallback), debouncing input, lazy loading, batching updates, and DOM diffing principles.

⸻

2. Node.js Scalability

Question: How do you handle CPU-intensive operations or large dataset processing in Node.js while keeping the app responsive?

Rubric:
	•	Poor: Doesn’t distinguish between sync/async processing; suggests blocking approaches.
	•	Fair: Talks about using async streams or background jobs.
	•	Excellent: Covers worker threads, message queues (like Bull), streaming APIs, chunking data, breaking work into smaller async tasks using setImmediate or process.nextTick.

⸻

3. MySQL Query Optimization

Question: Describe how you would identify and fix performance issues in a slow MySQL query used in production.

Rubric:
	•	Poor: Says “optimize the query” without details; guesses at indexes.
	•	Fair: Mentions EXPLAIN plan, adding indexes, basic joins.
	•	Excellent: Talks about indexing strategy, avoiding SELECT *, covering indexes, analyzing execution plan, optimizing joins/subqueries, caching results when appropriate.

⸻

4. API Design for Large Lists

Question: How would you design an API endpoint to return a list of items when the dataset is large (e.g., millions of rows)?

Rubric:
	•	Poor: Returns entire dataset or vague about pagination.
	•	Fair: Talks about limit/offset pagination and maybe filtering.
	•	Excellent: Discusses cursor-based pagination, caching layers (Redis/CDNs), query tuning, response shaping (fields, compression), and rate limiting.

⸻

5. React + Backend Integration

Question: How do you manage state and side effects when consuming large datasets from a backend in a React app?

Rubric:
	•	Poor: Mentions useEffect and fetch only.
	•	Fair: Uses SWR, React Query, or similar; handles loading/errors; some state management (e.g., Redux).
	•	Excellent: Clear use of SWR/React Query for caching/stale-while-revalidate, optimistic updates, error boundaries, centralized state management (Redux/Zustand/Recoil), and scalable architecture.

⸻

6. System Design

Question: Design a system where users can view, search, and filter millions of product records in real-time. How would you architect it (frontend, backend, database)?

Rubric:
	•	Poor: Doesn’t break system into components; vague on technologies.
	•	Fair: Describes API, DB, and frontend layers reasonably; some mention of caching.
	•	Excellent: Breaks into frontend (virtualized table, filters), backend (RESTful API or GraphQL), DB (indexes, full-text search), caching (Redis, CDN), async processing, and horizontal scaling.

⸻

7. Debugging Under Load

Question: Imagine users report slowness in part of the app that loads a lot of data. Walk me through your debugging process.

Rubric:
	•	Poor: Focuses on client only, or restarts the server.
	•	Fair: Talks about logs, performance tools, maybe inspecting DB.
	•	Excellent: Uses profiling tools (Chrome DevTools, Lighthouse, New Relic, PM2), APM, log correlation, DB slow query logs, performance monitoring, and load testing tools (k6, Artillery).

⸻

8. Security in Fullstack Apps

Question: What are some common security risks in fullstack apps and how do you prevent them?

Rubric:
	•	Poor: General idea of “sanitize input”.
	•	Fair: Talks about XSS, CSRF, SQL Injection, bcrypt, JWTs.
	•	Excellent: Adds CSP headers, OWASP Top 10 awareness, HttpOnly/Secure cookies, rate limiting, input validation, database access control, secure secrets management.

⸻

9. Code Review Philosophy

Question: What do you focus on when reviewing code from teammates?

Rubric:
	•	Poor: Only looks at syntax or lets tools handle it.
	•	Fair: Reviews for style, structure, logic bugs, and readability.
	•	Excellent: Adds focus on scalability, testability, security, adherence to conventions, useful commit messages, and mentoring through PR comments.

⸻

10. Handling Legacy Code

Question: You inherit a React component and Node API that are slow and hard to understand. What’s your approach to improving them?

Rubric:
	•	Poor: Says “rewrite it”.
	•	Fair: Tries to refactor incrementally and write tests.
	•	Excellent: Reads through existing behavior, adds test coverage, sets metrics for improvement, uses profiling, and refactors incrementally with clear version control and rollback strategy.

⸻

✅ Tips for Evaluation
	•	Take Notes Live: Score each response quickly on a 1–3 scale (Poor=1, Fair=2, Excellent=3).
	•	Prioritize Depth Over Breadth: If a candidate gives an excellent answer early, feel free to skip to later questions or dive deeper.
	•	Leave Time for Culture Fit & Questions.

⸻

Would you like a printable or shareable interview scorecard template to go with this list?