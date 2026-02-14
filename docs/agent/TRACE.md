# Trace

This file records milestone work on the default branch.

Fields:
- task_id: milestone or work item identifier (e.g. M0.1)
- branch: git branch name
- commit_parent: the parent commit SHA before the change
- timestamp: ISO-8601 timestamp (UTC preferred)
- head_after: optional commit SHA after the change

---

- task_id: bootstrap
  branch: main
  commit_parent: 9a76095caac257276782d94ae560c0edfc7d6162
  timestamp: 2026-02-13T20:59:00Z

- task_id: M0.2
  branch: main
  commit_parent: a105ad0520ea20826e307b7087068fda8fa0bb61
  timestamp: 2026-02-14T06:50:34Z
  head_after: 4fdd5b182e08563879969e67972e6b83ed7d7f59

- task_id: M0.1
  branch: main
  commit_parent: 9eafc2df12afb3954476c69b031c68e3910c5948
  timestamp: 2026-02-13T21:07:00Z

- task_id: M1.1
  branch: subagent/M1.1-country-metadata
  commit_parent: 5dca686ca07fd4c552d35c5054dc5a4c724197c9
  timestamp: 2026-02-14T11:40:37Z
  head_after: 4addeadda9c018546eedc8c3c97277cbe8ef5ebf
