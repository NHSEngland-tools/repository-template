# The Simplest Thing That Can Possibly Work

This tutorial is to walk you through the steps of getting a basic
Hello-World-style app into production, to show you where to find the
functionality you need and to demystify some of the content so that
you can get the most out of it.

We'll be building a Python AWS Lambda handler, so to complete the
later parts of the tutorial you'll need AWS credentials that let you
deploy to it.

I will assume familiarity with git itself.

## First things first

You will need certain tools to be installed in order to use the tools
in the repository template.  They are listed in the
[`README`](../README.md#prerequisites) at the root of the project, so
make sure you have them installed first, before trying to continue.

These prerequisites are some of the tools that the engineering
community assumes you will have for compatibility with a wide range of
projects and products.

Some other tools will be installed by the framework if you don't
already have them installed.  I'll call those out as and when they
come up.

I do not assume, dictate, or otherwise hint at the correct text
editor for you to be using.  I just silently judge you for your
choice.

## Cloning the template

The first step to your brand new app is to clone the repository.  For
the purposes of this tutorial, we're going to clone it into your
personal account rather than into any of the NHS GitHub
organisations. That's not what you'd be doing for anything we want to
go into production, but it means you can keep it as a reference and we
don't need to worry about naming collisions.

Go to <https://github.com/nhs-england-tools/repository-template> in your
browser, and click the green button marked `Use this template`. From
the dropdown that appears, select `Create a new repository`.

You will be taken to GitHub's `Create a new repository` page.  You
might notice that this is the same page as GitHub shows you when you
create an ordinary repository in the web user interface, but pay
attention to the `Repository template` field: you will see that it is
pre-populated with the `nhs-england-tools/repository-template` value.
That is as we want, so leave it as is.

Leave the `Include all branches` checkbox un-ticked.

Under `Owner`, select yourself from the `Choose an owner` dropdown.
Visibility options will appear under the Description field.  The
repository is MIT-licensed, and we're working in the open, so you
don't need to worry about this being a public repository.  You can
make it private if you prefer.

Under `Repository name`, give the repository a name of
`nhset-hello-world`.

If a description will help you remember the purpose of this project in
the future, put something meaningful to you in the `Description`
field.

Click the green `Create repository` button, and GitHub will show you a
loading page while your new instance of the repository is created.

Now that you have your repository, clone it to your local machine for
the next step.

## Python time

For our Python application, we will be building an API endpoint which
returns a JSON blob that looks like this:

```json
{
  "message": "Hello World"
}
```

The framework contains a mechanism for ensuring that your local
development Python interpreter is at a known version; that mechanism
relies on [`asdf`](https://github.com/asdf-vm/asdf).  The next step
will use `asdf` to install dependencies for you, but there's something
we need to edit first.

The framework assumes that all tool dependencies and versions are
specified in the `.tool-versions` file, so open it and add these lines
at the top:

```text
python 3.11.4
poetry 1.6.1
```

Run the task:

```shell
make config
```

The first time you run this it will download and build `python` for
you, so you may want to make a cup of tea.  The version it picks is in
the `.tool-versions` file at the top level of the template.

`make config` also sets up some `git` commit hooks that will come in
handy later.

Now, the template has given us a `poetry` installation for dependency
management.  There is a configuration option that I recommend you set
unless you have a good reason not to:

```shell
poetry config virtualenvs.in-project true
```

This tells `poetry` to always make a virtual environment within the
project directory.  If you don't set that, it's somewhere else - `poetry`'s
cache directory, to be specific.  With it within the project's working
directory, fixing certain types of packaging problems becomes much
easier: if you get really stuck, you can be absolutely certain that
deleting the working directory and starting again will reset all
(well, nearly all) the relevant state.

However, you don't want to be committing the virtual environment to
`git`, so edit the file `.gitignore` and add:

```text
.venv/
```

## A Failing Test

Let's get ourselves set up to run a unit test.  We'll want to use
`pytest` for this.  The configuration we need for that lives in
`pyproject.toml`.  That file doesn't exist yet, so edit it and add the
following:

```toml
[tool.poetry]
name = "nhset-hello-world"
version = "2023.09.13"
description = "A short description"
authors = []

[tool.poetry.dependencies]
python = "^3.11"
```

Now we add `pytest`:

```shell
poetry add --group=dev pytest
```

With that prologue out of the way, we can write our test.  It will
fail, but seeing it fail in the right way will tell us that the Python
environment is how we need it.  First, make a directory to put our
code into:

```shell
mkdir api
```

Now, open `api/test_hello_world.py`, and add the following:

```python
from hello_world import lambda_handler

def test_lambda_handler():
  response = lambda_handler(None, None)
  assert "message" in response
  assert response["message"] == "Hello World"
```

Run `pytest` with the command `poetry run pytest` and you will see the
following (among some other test failure info):

```console
$ poetry run pytest
...
    from hello_world import lambda_handler
E   ModuleNotFoundError: No module named 'hello_world'
...
```

So, edit `api/hello_world.py` and add:

```python
def lambda_handler(event, context):
  return {}
```

Run `poetry run pytest` again, and the output is a failure that we
should now be expecting:

```text
    def test_lambda_handler():
        response = lambda_handler(None, None)
>       assert "message" in response
E       AssertionError: assert 'message' in {}

api/test_hello_world.py:5: AssertionError
```

Now let's get the test to pass. Edit the `lambda_handler` function in
`api/hello_world.py` to read as follows:

```python
def lambda_handler(event, context):
    return {"message": "Hello World"}
```

Running `pytest` again gives us what we want:

```console
 $ poetry run pytest --quiet
.                                                           [100%]
1 passed in 0.02s
```

In order to be able to integrate our tests with the rest of the
framework, we want to hide our `poetry run` behind a standard command
that the framework recognises.  As you saw above, the template relies
on `make` for its entry points, and testing is no different.  Run
`make test-unit` and you should see the following:

```console
 $ make test-unit
Unit tests are not yet implemented. See scripts/tests/unit.sh for more.
```

So, edit `scripts/tests/unit.sh` and change the last line from:

```shell
echo "Unit tests are not yet implemented. See scripts/tests/unit.sh for more."
```

to

```shell
poetry run pytest --quiet
```

and save.  Now when you run `make test-unit` you will see our familiar
`pytest` output:

```console
 $ make test-unit
.                                                           [100%]
1 passed in 0.01s
```

Now, what other `make` test tasks might you want to define?  Run `make
test` and you will see your options:

```console
 $ make test
.                                                           [100%]
1 passed in 0.01s
make test-lint not implemented: ./scripts/tests/lint.sh not found
make test-coverage not implemented: ./scripts/tests/coverage.sh not found
make test-contract not implemented: ./scripts/tests/contract.sh not found
make test-security not implemented: ./scripts/tests/security.sh not found
make test-ui not implemented: ./scripts/tests/ui.sh not found
make test-ui-performance not implemented: ./scripts/tests/ui-performance.sh not found
make test-integration not implemented: ./scripts/tests/integration.sh not found
make test-accessibility not implemented: ./scripts/tests/accessibility.sh not found
make test-capacity not implemented: ./scripts/tests/capacity.sh not found
```

You can see that the unit test we wrote has been run, and there are
several further test options predefined.  They all follow the same
pattern as `scripts/tests/unit.sh`: by putting a shell script with the
right name under `scripts/tests`, you can control how the framework
executes that sort of test.

Let's add another: let's get `make test-lint` working, and as an
arbitrary choice we'll use Python's `black` tool.  First add it to
`pyproject.toml` with `poetry`:

```console
poetry add --group=dev black
```

Now, let's add it to the `test-lint` task.  Edit a new file at
`scripts/tests/lint.sh` and add this:

```shell
#!/bin/bash

poetry run black --diff --check api/
```

Save it and set it to be executable:

```console
chmod +x scripts/tests/lint.sh
```

Now when I run `make test-lint` I see this:

```console
 $ make test-lint
--- /Users/alex/src/repository-template/api/test_hello_world.py	2023-09-13 15:31:39.692962+00:00
+++ /Users/alex/src/repository-template/api/test_hello_world.py	2023-09-13 16:30:16.798188+00:00
@@ -1,5 +1,6 @@
 from hello_world import lambda_handler
+

 def test_lambda_handler():
     response = lambda_handler(None, None)
     assert "message" in response
would reformat /Users/alex/src/repository-template/api/test_hello_world.py

Oh no! 💥 💔 💥
1 file would be reformatted, 1 file would be left unchanged.
make[1]: *** [scripts/tests/test.mk:68: _test] Error 1
make: *** [scripts/tests/test.mk:15: test-lint] Error 2
```

It's picked up that there's a blank line missing after our import.  We
could fix that manually, but `black` can do it for us.  Let's add a
`make` task we can run to format our code.  Let's call it,
imaginatively, `make format`.

Open the top-level `Makefile` in the project.  You'll see some
predefined tasks that you can edit.  There isn't one called `format`
yet, so we need to add it.

Find the `sh` task, and in the space under it, add this `make` rule
definition:

```make
format: # Apply code formatting
	make _project name="format"

```

Note, if you're not used to `make` syntax, that the space before
`make` on the second line needs to be a single `tab` character.  It
will break otherwise.  Copy and paste if in doubt.

Close the `Makefile`, and create the file
`scripts/projecthooks/format.sh` with the contents:

```shell
#!/bin/bash

poetry run black api/
```

Save it and run `chmod +x scrips/projecthooks/format.sh` to make it
executable.

That's all you need to do: run `make format` and you will see
something like this:

```console
 $ make format
make _project name="format"
reformatted /Users/alex/src/repository-template/api/test_hello_world.py

All done! ✨ 🍰 ✨
1 file reformatted, 1 file left unchanged.
```
