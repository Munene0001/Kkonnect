.PHONY: setup clean test lint security-check update-deps build run docs backup

# Python configuration
PYTHON = python
VENV = .venv
BIN = $(VENV)/bin
PYTHON_VERSION = 3.11.9

# Setup environments
setup:
	pyenv install $(PYTHON_VERSION) -s
		pyenv local $(PYTHON_VERSION)
			$(PYTHON) -m venv $(VENV) --prompt "kkonnect"
				$(BIN)/pip install --upgrade pip
					$(BIN)/pip install -r requirements/dev.txt -c requirements/constraints.txt
						$(BIN)/pre-commit install

						# Clean build artifacts
						clean:
							rm -rf build/
								rm -rf dist/
									rm -rf *.egg-info
										rm -rf .pytest_cache
											rm -rf htmlcov
												rm -rf .coverage
													find . -type d -name __pycache__ -exec rm -rf {} +
														find . -type d -name "*.pyc" -delete

														# Run tests
														test:
															$(BIN)/pytest tests/ --cov=src

															# Run linting
															lint:
																$(BIN)/black --check src tests
																	$(BIN)/pylint src tests

																	# Run security checks
																	security-check:
																		$(BIN)/safety check --full-report
																			$(BIN)/bandit -r src/
																				which trivy > /dev/null && trivy fs --severity HIGH,CRITICAL . || echo "Trivy not installed"

																				# Update dependencies
																				update-deps:
																					$(BIN)/pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 $(BIN)/pip install -U
																						$(BIN)/pip-compile requirements/base.in -o requirements/constraints.txt --resolver=backtracking
																							$(BIN)/pip-compile requirements/dev.in -o requirements/dev.txt --resolver=backtracking

																							# Build Docker image
																							build:
																								docker build -f docker/Dockerfile.dev -t kkonnect-dev .

																								# Run docker container
																								run:
																									docker run -p 8888:8888 -p 8000:8000 -v $(shell pwd):/app kkonnect-dev

																									# Run docker-compose
																									docker-up:
																										docker-compose up -d

																										# Run documentation server
																										docs:
																											$(BIN)/mkdocs serve

																											# Create backup
																											backup:
																												$(BIN)/pip freeze > environment_snapshot_$(shell date +%F).txt
																													docker save kkonnect-dev | gzip > kkonnect-dev_$(shell date +%F).tar.gz

																													# Verify environment
																													verify:
																														@echo "Python version: $$($(BIN)/python -V)"
																															@echo "Pip path: $$(which $(BIN)/pip)"
																																@echo "Dependency check: $$($(BIN)/pip check)"
																																	@echo "Django version: $$($(BIN)/python -m django --version || echo 'Not installed')"
																																		@echo "Docker image: $$(docker images | grep kkonnect-dev || echo 'Not built')"