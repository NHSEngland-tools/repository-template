# Developer Guide: CI/CD pipeline

- [Developer Guide: CI/CD pipeline](#developer-guide-cicd-pipeline)
  - [The pipeline high-level workflow model](#the-pipeline-high-level-workflow-model)
  - [Workflow stages](#workflow-stages)
    - [End-to-end workflow stages](#end-to-end-workflow-stages)
    - [Stage triggers](#stage-triggers)
    - [Branch review workflow](#branch-review-workflow)
    - [PR review workflow](#pr-review-workflow)
    - [Publish workflow](#publish-workflow)
    - [Deploy workflow](#deploy-workflow)
    - [Rollback workflow](#rollback-workflow)
  - [Environments and artefact promotion](#environments-and-artefact-promotion)
  - [Resources](#resources)

## The pipeline high-level workflow model

```mermaid
flowchart LR
    Review --> Publish
    Publish --> Deploy
    Deploy --> Rollback
```

## Workflow stages

### End-to-end workflow stages

```mermaid
flowchart LR
    commit_local["Commit<br>(local githooks)"] --> commit_remote
    commit_remote["Commit<br>(remote)"] --> Test
    Test --> Build
    Build --> Acceptance
    Acceptance --> Publish
    Publish --> Deploy
    Deploy --> Rollback
```

### Stage triggers

| Workflow | Stage                   |    `main` branch trigger    |  Task branch trigger   |
|---------:|:------------------------|:---------------------------:|:----------------------:|
|   Review | Commit (local githooks) |              -              |       on commit        |
|   Review | Commit (remote)         |          on merge           |        on push         |
|   Review | Test                    |          on merge           |        on push         |
|   Review | Build                   |          on merge           | on push, if PR is open |
|   Review | Acceptance              |          on merge           | on push, if PR is open |
|  Publish | Publish                 |           on tag            |           -            |
|   Deploy | Deploy                  |           on tag            |           -            |
| Rollback | Rollback                | on demand or on healthcheck |           -            |

- Publish:
  - When merged, create snapshot release
  - When tagged, crate Release Candidate
- Deploy
  - Only deploy RCs
  - Deploy to specified environment

### Branch review workflow

```mermaid
flowchart LR
    subgraph commit_local["Commit (local githooks)"]
        direction TB
        clA["Scan secrets"]
        clB["Check file format"]
        clC["Check markdown format"]
        clD["Check Terraform format"]
        clE["Scan dependencies"]
        clA --> clB
        clB --> clC
        clC --> clD
        clD --> clE
    end
    subgraph commit_remote["Commit (remote)"]
        direction TB
        crA["Scan secrets"]
        crB["Check file format"]
        crC["Check markdown format"]
        crD["Lint Terraform"]
        crE["Count lines of code"]
        crF["Scan dependencies"]
        crA -.- crB
        crB -.- crC
        crC -.- crD
        crD -.- crE
        crE -.- crF
    end
    subgraph test[Test]
        direction TB
        tA["Linting"]
        tB["Unit tests"]
        tC["Test coverage"]
        tD["Perform static analysis"]
        tA -.- tB
        tB --> tC
        tB --> tD
    end
    subgraph branch_review["Branch review"]
        direction LR
        commit_local --> commit_remote
        commit_remote --> test
    end
    branch_review --> build
    build["Build"] --> acceptance
    acceptance["Acceptance"] --> publish
    publish["Publish"] --> deploy
    deploy["Deploy"] --> rollback["Rollback"]
```

### PR review workflow

```mermaid
flowchart LR
    subgraph commit_remote["Commit (remote)"]
        direction TB
        crA["Scan secrets"]
        crB["Check file format"]
        crC["Check markdown format"]
        crD["Lint Terraform"]
        crE["Count lines of code"]
        crF["Scan dependencies"]
        crA -.- crB
        crB -.- crC
        crC -.- crD
        crD -.- crE
        crE -.- crF
    end
    subgraph test["Test"]
        direction TB
        tA["Linting"]
        tB["Unit tests"]
        tC["Test coverage"]
        tD["Perform static analysis"]
        tA -.- tB
        tB --> tC
        tB --> tD
    end
    subgraph build["Build"]
        direction TB
        bA["Artefact (back-end)"]
        bB["Artefact (front-end)"]
        bA -.- bB
    end
    subgraph acceptance["Acceptance"]
        direction TB
        aA["Environment set up"]
        aB["Contract test"]
        aC["Security test"]
        aD["UI test"]
        aE["UI performance test"]
        aF["Integration test"]
        aG["Accessibility test"]
        aH["Load test"]
        aI["Environment tear down"]
        aA --> aB
        aA --> aC
        aA --> aD
        aA --> aE
        aA --> aF
        aA --> aG
        aA --> aH
        aB --> aI
        aC --> aI
        aD --> aI
        aE --> aI
        aF --> aI
        aG --> aI
        aH --> aI
    end
    subgraph pr_review["PR review"]
        direction LR
        commit_remote --> test
        test --> build
        build --> acceptance
    end
    branch_review["Branch review"] --> pr_review
    pr_review --> publish
    publish["Publish"] --> deploy
    deploy["Deploy"] --> rollback["Rollback"]
```

### Publish workflow

```mermaid
flowchart LR
    subgraph publish["Publish"]
        direction TB
        pA["Set CI/CD metadata"]
        pB["Publish artefacts"]
        pC["Send notification"]
        pA --> pB
        pB --> pC
    end
    branch_review["Branch review"] --> pr_review
    pr_review["PR review"] --> publish
    publish --> deploy
    deploy["Deploy"] --> rollback["Rollback"]
```

### Deploy workflow

```mermaid
flowchart LR
    subgraph deploy["Deploy"]
        direction TB
        dA["Set CI/CD metadata"]
        dB["Deploy to an environment"]
        dC["Send notification"]
        dA --> dB
        dB --> dC
    end
    branch_review["Branch review"] --> pr_review
    pr_review["PR review"] --> publish
    publish["Publish"] --> deploy
    deploy --> rollback["Rollback"]
```

### Rollback workflow

```mermaid
flowchart LR
    subgraph rollback["Rollback"]
        direction TB
        dA["Set CI/CD metadata"]
        dB["Rollback an environment"]
        dC["Send notification"]
        dA --> dB
        dB --> dC
    end
    branch_review["Branch review"] --> pr_review
    pr_review["PR review"] --> publish
    publish["Publish"] --> deploy
    deploy["Deploy"] --> rollback
```

## Environments and artefact promotion

```mermaid
flowchart LR
    subgraph branch_review["Branch review"]
        direction LR
        bA("local")
    end
    subgraph pr_review["PR Review"]
        direction LR
        prA["ephemeral<br>dev environments"]
        prB["automated acceptance<br>test environments"]
        prA --> prB
    end
    subgraph deploy1["Deploy (high-instance)"]
        direction LR
        d1A["non-prod<br>environments"]
    end
    subgraph deploy2["Deploy (Live)"]
        direction LR
        d2A["prod environment"]
    end
    branch_review --> pr_review
    pr_review --> deploy1
    deploy1 --> deploy2
```

## Resources

- Blog post [Going faster with continuous delivery](https://aws.amazon.com/builders-library/going-faster-with-continuous-delivery/)
- Blog post [Automating safe, hands-off deployments](https://aws.amazon.com/builders-library/automating-safe-hands-off-deployments/)
- Book [Continuous Delivery: Reliable Software Releases through Build, Test, and Deployment Automation](https://www.oreilly.com/library/view/continuous-delivery-reliable/9780321670250/)
