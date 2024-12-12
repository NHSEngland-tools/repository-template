# Contributing

## Table of contents

- [Contributing](#contributing)
  - [Table of contents](#table-of-contents)
  - [Local environment](#local-environment)
    - [Prerequisites](#prerequisites)
    - [Development environment configuration](#development-environment-configuration)
  - [Git and GitHub](#git-and-github)
    - [Configuration](#configuration)
    - [Authentication](#authentication)
    - [Signing commits](#signing-commits)
      - [Troubleshooting](#troubleshooting)
      - [Additional settings](#additional-settings)
    - [Branching](#branching)
    - [Commit message](#commit-message)
    - [Hooks](#hooks)
    - [Tags](#tags)
    - [Pull Request](#pull-request)
      - [Review statuses](#review-statuses)
        - [Approve](#approve)
        - [Comment](#comment)
        - [Request changes](#request-changes)
        - [Discarding reviews](#discarding-reviews)
    - [Removing sensitive data](#removing-sensitive-data)
  - [Development](#development)
    - [Unit testing](#unit-testing)
    - [Code review](#code-review)

## Local environment

### Prerequisites

The following software packages must be installed on your laptop before proceeding

- [GitHub CLI](https://cli.github.com/)
- [GNU make](https://formulae.brew.sh/formula/make)
- [Docker](https://www.docker.com/)

To ensure all the prerequisites are installed and configured correctly, please follow the [nhs-england-tools/dotfiles](https://github.com/nhs-england-tools/dotfiles) installation process.

### Development environment configuration

From within the root directory of your project, please run the following command

```shell
make config
```

## Git and GitHub

### Configuration

<!-- markdownlint-disable-next-line no-inline-html -->
The commands below will configure your Git command-line client globally. Please, update your username (<span style="color:red">Your Name</span>) and email address (<span style="color:red">youremail@domain</span>) in the code snippet below prior to executing it.

This configuration is to support trunk-based development and git linear history.

```shell
git config user.name "Your Name" # Use your full name here
git config user.email "youremail@domain" # Use your email address here
git config branch.autosetupmerge false
git config branch.autosetuprebase always
git config commit.gpgsign true
git config core.autocrlf input
git config core.filemode true
git config core.hidedotfiles false
git config core.ignorecase false
git config credential.helper cache
git config pull.rebase true
git config push.default current
git config push.followTags true
git config rebase.autoStash true
git config remote.origin.prune true
```

More information on the git settings can be found in the [Git Reference documentation](https://git-scm.com/docs).

### Authentication

Authenticate to GitHub and set up your authorisation token

```shell
$ gh auth login
? What account do you want to log into? GitHub.com
? What is your preferred protocol for Git operations? HTTPS
? Authenticate Git with your GitHub credentials? No
? How would you like to authenticate GitHub CLI? Paste an authentication token
Tip: you can generate a Personal Access Token here https://github.com/settings/tokens
The minimum required scopes are 'repo', 'read:org'.
? Paste your authentication token: github_pat_**********************************************************************************
- gh config set -h github.com git_protocol https
✓ Configured git protocol
✓ Logged in as your-github-handle
```

### Signing commits

Signing Git commits is a good practice and ensures the correct web of trust has been established for the distributed version control management.

<!-- markdownlint-disable-next-line no-inline-html -->
If you do not have it already generate a new pair of GPG keys. Please, change the passphrase (<span style="color:red">pleaseChooseYourKeyPassphrase</span>) below and save it in your password manager.

```shell
USER_NAME="Your Name"
USER_EMAIL="your.name@email"
file=$(echo $USER_EMAIL | sed "s/[^[:alpha:]]/-/g")

mkdir -p "$HOME/.gnupg"
chmod 0700 "$HOME/.gnupg"
cd "$HOME/.gnupg"
cat > "$file.gpg-key.script" <<EOF
  %echo Generating a GPG key
  Key-Type: ECDSA
  Key-Curve: nistp256
  Subkey-Type: ECDH
  Subkey-Curve: nistp256
  Name-Real: $USER_NAME
  Name-Email: $USER_EMAIL
  Expire-Date: 0
  Passphrase: pleaseChooseYourKeyPassphrase
  %commit
  %echo done
EOF
gpg --batch --generate-key "$file.gpg-key.script"
rm "$file.gpg-key.script"
# or do it manually by running `gpg --full-gen-key`
```

Make note of the ID and save the keys.

```shell
gpg --list-secret-keys --keyid-format LONG $USER_EMAIL
```

You should see a similar output to this

```shell
sec   nistp256/AAAAAAAAAAAAAAAA 2023-01-01 [SCA]
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
uid                 [ultimate] Your Name <your.name@email>
ssb   nistp256/BBBBBBBBBBBBBBBB 2023-01-01 [E]
```

Export your keys.

```shell
ID=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gpg --armor --export $ID > $file.gpg-key.pub
gpg --armor --export-secret-keys $ID > $file.gpg-key
```

Import already existing private key.

```shell
gpg --import $file.gpg-key
```

Remove keys from the GPG agent if no longer needed.

```shell
gpg --delete-secret-keys $ID
gpg --delete-keys $ID
```

Configure Git to use the new key.

```shell
git config user.signingkey $ID
```

Upload the public key to your GitHub profile into the [GPG keys](https://github.com/settings/keys) section. After doing so, please make sure your email address appears as verified against the commits pushed to the remote.

```shell
cat $file.gpg-key.pub
```

#### Troubleshooting

If you receive the error message "error: gpg failed to sign the data", make sure you added `export GPG_TTY=$(tty)` to your `~/.zshrc` and restarted your terminal.

```shell
sed -i '/^export GPG_TTY/d' ~/.exports
echo "export GPG_TTY=\$TTY" >> ~/.exports
```

#### Additional settings

Configure caching git commit signature passphrase for 3 hours

```shell
source ~/.zshrc
mkdir -p ~/.gnupg
sed -i '/^pinentry-program/d' ~/.gnupg/gpg-agent.conf 2>/dev/null ||:
echo "pinentry-program $(whereis -q pinentry)" >> ~/.gnupg/gpg-agent.conf
sed -i '/^default-cache-ttl/d' ~/.gnupg/gpg-agent.conf
echo "default-cache-ttl 10800" >> ~/.gnupg/gpg-agent.conf
sed -i '/^max-cache-ttl/d' ~/.gnupg/gpg-agent.conf
echo "max-cache-ttl 10800" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
git config --global credential.helper cache
#git config --global --unset credential.helper
```

### Branching

Principles to follow

- A direct merge to the main branch is not allowed and can only be done by creating a Pull Request
- If not stated otherwise the only long-lived branch is main
- Any new branch should be created from main and short-lived
- The preferred short-lived branch name format is `task/REF-XXX_Descriptive_branch_name`
- The preferred hotfix branch name format is `hotfix/REF-XXX_Descriptive_branch_name`
- Commits should be made often and pushed to the remote, at least once a day
- Use rebase to get the latest commits from main and update your local branch
- Squash commits when appropriate
- Merge commits are not allowed and should be squashed
- All commits should be cryptographically signed

There are a couple of good cheatsheets by [GitHub](https://training.github.com/downloads/github-git-cheat-sheet/) and a [visual](https://ndpsoftware.com/git-cheatsheet.html#loc=index;) one.

Add your changes, create a signed commit, update from and push to remote

```shell
git add .
git commit -S -m "Create a signed commit"
git pull
git push
```

Squash all commits on branch as one

```shell
git checkout your-branch-name
git reset $(git merge-base main $(git branch --show-current))
git add .
git commit -S -m "Create just one commit instead"
git push --force-with-lease
```

Working on a new task

```shell
git checkout -b task/REF-XXX_Descriptive_branch_name
# Make your changes here...
git add .
git commit -S -m "Meaningful description of change"
git push --set-upstream origin task/REF-XXX_Descriptive_branch_name
```

Contributing to an already existing branch

```shell
git checkout task/REF-XXX_Descriptive_branch_name
git pull
# Make your changes here...
git add .
git commit -S -m "Meaningful description of change"
git push
```

Squashing commits within a branch

```shell
git checkout task/REF-XXX_Descriptive_branch_name
git rebase -i HEAD~X # Squash X number of commits into one
# When prompted change commit type to `squash` for all the commits except the top one
# On the following screen replace pre-inserted comments by a single summary
git push --force-with-lease
```

Rebasing a branch onto main

```shell
git checkout main
git pull
git checkout task/REF-XXX_Descriptive_branch_name
git rebase main
# Resolve conflicts
git add .
git rebase --continue
git push --force-with-lease
```

Merging a branch to main - this should be done only in an exceptional circumstance as the proper process is to raise a Pull Request

```shell
git checkout main
git pull --prune                                    # Make sure main is up-to-date
git checkout task/REF-XXX_Descriptive_branch_name
git pull                                            # Make sure the task branch is up-to-date

git rebase -i HEAD~X                                # Squash X number of commits, all into one
# When prompted change commit type to `squash` for all the commits except the top one
# On the following screen replace pre-inserted comments by a single summary

git rebase main                                     # Rebase the task branch on top of main
git checkout main                                   # Switch to main branch
git merge -ff task/REF-XXX_Descriptive_branch_name  # Fast-forward merge
git push                                            # Push main to remote

git push -d origin task/REF-XXX_Descriptive_branch_name   # Remove remote branch
git branch -d task/REF-XXX_Descriptive_branch_name        # Remove local branch
```

If REF is currently not in use to track project changes, please drop any reference to it and omit `REF-XXX_` in your commands.

### Commit message

- Separate subject from body with a blank line
- Do not end the subject line with a punctuation mark
- Capitalise the subject line and each paragraph
- Use the imperative mood in the subject line
- Wrap lines at 72 characters
- Use the body to explain what and why you have done something, which should be done as part of a Pull Request description

*(Please, bear in mind that a need for this might be superseded by the GitHub Pull Request setting in your respoitory `Settings > General > Pull Requests > Allow squash merging > Default to pull request title and description` which is a recommended configuration.)*

Example:

```shell
Short (72 chars or less) summary in the imperative mood

More detailed explanatory text. Wrap it to 72 characters. The blank
line separating the summary from the body is critical (unless you omit
the body entirely).

Write your commit message in the imperative: "Fix bug" and not "Fixed
bug" or "Fixes bug." This convention matches up with commit messages
generated by commands like git merge and git revert.

Further paragraphs come after blank lines.

- Bullet points are okay, too.
- Typically a hyphen or asterisk is used for the bullet, followed by a
  single space. Use a hanging indent.
```

### Hooks

Git hooks are located in [`./scripts/githooks`](scripts/githooks) and executed automatically on each commit and as part of the CI/CD pipeline execution. They are as follows:

- Check file format ([EditorConfig](https://github.com/editorconfig))
- Check markdown format ([markdownlint](https://github.com/DavidAnson/markdownlint))
- Scan secrets ([GitLeaks](https://github.com/gitleaks/gitleaks))

### Tags

Aim at driving more complex deployment workflows by tags with an exception of the main branch where the continuous deployment to a development environment should be enabled by default.

### Pull Request

- Set the title to `REF-XXX: Descriptive branch name`, where `REF-XXX` is the ticket reference number
- Use the imperative mood in the title
- Ensure all commits will be squashed and the source branch will be removed once the Pull Request is merged
- Notify the team on Slack to give your colleagues opportunity to review changes and share the knowledge
- If the change has not been pair or mob programmed it must follow the code review process and be approved by at least by one peer and all discussions must be resolved
- A merge to main must be squashed and rebased on top, preserving the list of all commit messages or/and the Pull Request description

#### Review statuses

Please, use the review statuses appropriately.

##### Approve

Approving a PR means that you have confidence in that the code works and that it does what the PR claims. This can be based on testing the change or on previous domain knowledge.

- You have read and understood all the code changes in the PR
- You have verified that the linked ticket issue description matches the changes made in the PR
- The code is well structured, follows the code styling patterns, does not have a better or more appropriate solution, and is free of unintended side-effects

If you are unsure about any of the above, consider using a different status or check in with the author to discuss things first. Also do not hesitate to request a second review from someone else.

##### Comment

Comment is a great way to discuss things without explicitly approving or requesting changes.

##### Request changes

Request changes should be used when you believe something needs to change prior to the PR getting merged, as it will prevent someone else from approving the PR before your concerns have been tackled.

We should not hesitate to use this status. However, we should give clear feedback on what needs to change for the PR to get approved. Likewise a PR author should not be discouraged by a request for changes, it is simply an indication that changes should be made prior to the PR being merged.

##### Discarding reviews

While it is possible to discard reviews, this should be used sparingly. Whenever possible please reach out to the reviewer first to ensure their concerns have been resolved. Below are a couple of scenarios where discarding the reviews are generally seen as accepted.

- The reviewer is out of office for a longer duration and their original feedback has been resolved. It is the responsibility of the new reviewer to ensure the original feedback has been addressed
- The PR is a hotfix that needs to be deployed quickly. The feedback can be addressed in a follow up PR, if it has not already have been resolved

### Removing sensitive data

The secret scan git hook and the corresponding GitHub action set up in this repository should prevent committing sensitive data to git history. However, if any sensitive information was included, please follow the [Removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) guide.

## Development

Read the [Code of Conduct](../docs/CODE_OF_CONDUCT.md) to keep the community approachable and respectable.

### Unit testing

When writing or updating unit tests (whether you use Python, Java, Go or Bash), please always structure them using the 3 A's approach of 'Arrange', 'Act', and 'Assert'. For example:

```java
@Test
public listServicesNullReturn() {

  // Arrange
  List<String> criteria = new ArrayList<>();
  criteria.add("Null");
  when(repository.findBy(criteria)).thenReturn(null);

  // Act
  List<Service> list = service.list(criteria);

  // Assert
  assertEquals(0, list.size());
}
```

### Code review

Whether possible, please practice pair or/and mob programming. While performing code reviews, please refer to the [Clean Code](https://learning.oreilly.com/library/view/clean-code/9780136083238/) (especially chapter 17) and [Clean Architecture](https://learning.oreilly.com/library/view/clean-architecture-a/9780134494272/) books written by Robert C. Martin.

To have efficient code reviews there are a few things to keep in mind (from [Best Practices for Code Review | SmartBear](https://smartbear.com/learn/code-review/best-practices-for-peer-code-review/)):

- As an author, keep your PRs small ideally less than 400 lines
  - This can be tricky in our code base since many things are tightly coupled
  - Consider splitting up a PR into multiple smaller PRs to encourage easier and better quality reviews
  - Target main if the code is functionally complete, otherwise target a feature branch
- Take your time when reviewing, expect a rate of less than 500 lines of code per hour
- Take breaks, do not review for longer than 60 minutes

Do not feel bad for taking your time when doing code reviews. They often take longer than you think and we should be spending as much time as needed.
