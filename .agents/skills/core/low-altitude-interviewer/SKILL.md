---
name: low-altitude-interviewer
description: Screen resumes and prepare interviews for low-altitude aviation roles such as drone inspection, facade cleaning, and related operational backends. Use this skill when the user wants candidate fit analysis, ranking, interview questions, or hiring recommendations shaped by low-altitude business needs rather than generic software hiring.
---

# Low-Altitude Interviewer

Use this skill when hiring or interviewing for low-altitude roles, especially backend positions that support drones, inspection, cleaning operations, device connectivity, mission execution, media handling, and work-order systems.

## Read First

- the job description or the user's hiring intent
- the candidate resumes or candidate summaries
- `references/screening-rubric.md`
- any user-specific hiring preferences such as preferred stack, internship duration, location, or arrival time

## Goals

- rank candidates against the actual low-altitude role rather than generic Java backend standards
- distinguish resume buzzwords from real internship responsibilities
- surface the most transferable experience for drone, inspection, and operational backend work
- generate interview questions that validate the candidate's claimed depth

## Rules

- prioritize actual internship or work responsibilities over long technology keyword lists
- separate `strong fit`, `possible fit`, and `weak fit` clearly
- treat device communication, realtime status return, task scheduling, media/file pipelines, work orders, and industrial system experience as high-signal evidence
- call out when a candidate is mainly frontend, mainly AI research, or mainly generic ecommerce backend
- when evidence is weak because the resume text is incomplete or OCR quality is poor, say so explicitly
- default reports, summaries, and screening tables to Chinese unless the user requests another language

## Process

1. Extract the real hiring target: business context, stack, role seniority, and practical constraints.
2. Read resumes with emphasis on internship and work responsibilities.
3. Use `references/screening-rubric.md` to score relevance.
4. Group candidates into recommendation tiers.
5. For shortlisted candidates, prepare targeted interview questions that test claimed responsibilities.
6. If useful, produce a structured table the user can reuse in hiring review.

## Output

Provide:

- a short description of the hiring target
- candidate tiers such as `优先面`, `可面`, `不优先`
- for each candidate: main responsibilities, matching points, risk points, and recommendation level
- suggested interview questions for the top candidates
- any evidence gaps caused by unreadable resumes, scanned PDFs, or missing experience details
