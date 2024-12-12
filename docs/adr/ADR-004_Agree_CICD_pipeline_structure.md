# ADR-004: Agree CI/CD pipeline structure

>|              | |
>| ------------ | --- |
>| Date         | `15/09/2022` |
>| Status       | `RFC` |
>| Deciders     | `Engineering` |
>| Significance | `Construction techniques` |
>| Owners       | `Dan Stefaniuk, Nick Sparks` |

---

- [ADR-004: Agree CI/CD pipeline structure](#adr-004-agree-cicd-pipeline-structure)
  - [Context](#context)
  - [Decision](#decision)
    - [Assumptions](#assumptions)
    - [Drivers](#drivers)
    - [Options](#options)
    - [Outcome](#outcome)
    - [Rationale](#rationale)
  - [Consequences](#consequences)
  - [Compliance](#compliance)
  - [Tags](#tags)

## Context

Continuous integration and continuous delivery pipeline is to organise all steps required to go from idea to a releasable software using automation of the development process. The key ideas upon it is founded are as follows:

- The reliable, repeatable production of high quality software.
- The application of scientific principles, experimentation, feedback and learning.
- The pipeline (or set of workflows) as a mechanism to organise and automate the development process.

For this to work it is essential to apply principles and practices noted in the [NHSE Software Engineering Quality Framework](https://github.com/NHSDigital/software-engineering-quality-framework)

Requirements:

- Implement the exemplar CI/CD pipeline using GitHub workflows and actions
- Incorporate the four main CI/CD stages, which are as follows:
  1. Commit, max. execution time 2 mins
  2. Test, max. execution time 5 mins
  3. Build, max. execution time 3 mins
  4. Acceptance, max. execution time 10 mins
- Provide `publish`, `deploy` and `rollback` workflows as the complementary processes
- Maintain simplicity in the pipeline but ensure it is scalable and extensible for larger projects
- Enable parallel execution of jobs to speed up the overall process
- Prevent the workflow from being triggered twice, i.e. when pushing to a branch with an existing pull request
- Implement good CI/CD practices, such as:
  - Setting the build time variables at the start of the process
  - Storing the tooling versions like Terraform, Python and Node.js in the `./.tools-version` file (dependency management)
  - Storing the software/project version in the `VERSION` file at the project root-level or in an artifact directory
  - Keeping the main workflow modular
  - Ensuring a timeout is set for each job
  - Listing environment variables
  - Making actions portable, e.g. allowing them to be run on a workstation or Azure DevOps using scripts
  - Providing testable CI/CD building blogs

## Decision

### Assumptions

TODO: state the assumptions

### Drivers

TODO: list the drivers

### Options

TODO: table, SEE: the [CI/CD pipeline](../developer-guides/CICD_pipeline.md) high-level design.

### Outcome

TODO: decision outcome

### Rationale

TODO: rationale

## Consequences

TODO: consequences

## Compliance

TODO: how the success is going to be measured

## Tags

`#maintainability, #testability, #deployability, #modularity, #simplicity, #reliability`
