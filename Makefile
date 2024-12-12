# This file is for you! Edit it to implement your own hooks (make targets) into
# the project as automated steps to be executed on locally and in the CD pipeline.

include scripts/init.mk

# ==============================================================================

# Example CI/CD targets are: dependencies, build, publish, deploy, clean, etc.

dependencies: # Install dependencies needed to build and test the project @Pipeline
	# TODO: Implement installation of your project dependencies

build: # Build the project artefact @Pipeline
	make _project name="build"

up: # Run your code @Pipeline
	make _project name="up"

down: # Stop your code @Pipeline
	make _project name="down"

sh: up # Get a shell inside your running project, running it first if necessary @Development
	make _project name="sh"

publish: # Publish the project artefact @Pipeline
	# TODO: Implement the artefact publishing step

deploy: # Deploy the project artefact to the target environment @Pipeline
	# TODO: Implement the artefact deployment step

clean:: # Clean-up project resources (main) @Operations
	# TODO: Implement project resources clean-up step

config:: # Configure development environment (main) @Configuration
	# TODO: Use only 'make' targets that are specific to this project, e.g. you may not need to install Node.js
	make _install-dependencies

# ==============================================================================

_project:
	set -e
	SCRIPT="./scripts/projecthooks/${name}.sh"
	if [ -e "$${SCRIPT}" ]; then
		exec $$SCRIPT
	else
		echo "make ${name} not implemented: $${SCRIPT} not found" >&2
	fi

${VERBOSE}.SILENT: \
	_project \
	build \
	clean \
	config \
	dependencies \
	deploy \
	down \
	sh \
	up \
