# Contribution Guidelines

Thank you for your interest in contributing to the EEG-Based Wheelchair Navigation System.

This document outlines the guidelines for maintaining, improving and extending the project.

## 1. Project Scope

Contributions should support one or more of the following areas:

- EEG signal preprocessing
- Dataset organization and preparation
- Feature extraction
- Machine learning model development
- Model evaluation
- Real-time prediction
- MATLAB and Arduino communication
- Documentation and usability improvements

## 2. Development Guidelines

When contributing code:

- Keep MATLAB scripts organized and readable.
- Use meaningful variable and function names.
- Add comments where the implementation needs clarification.
- Avoid unnecessary duplication of code.
- Preserve compatibility with the existing project structure.
- Clearly document new dependencies and configuration requirements.

## 3. Dataset Guidelines

When adding or modifying EEG recordings:

- Maintain the existing command-based folder organization.
- Use consistent file naming conventions.
- Preserve the original data wherever possible.
- Document the recording format and relevant metadata.
- Do not publish recordings or personal information without the necessary authorization.
- Ensure that dataset changes do not unintentionally affect existing functionality.

## 4. Model Development and Evaluation

Changes to machine learning models should include:

- A description of the changes made.
- Details of the training and testing procedure.
- Relevant evaluation metrics.
- A comparison with the previous implementation, where applicable.
- Any known limitations or performance issues.

Avoid reporting performance improvements without supporting evaluation results.

## 5. Hardware and Safety

Contributions involving Arduino or physical wheelchair control must prioritize safety.

- Test hardware communication independently before integration.
- Document communication settings and hardware requirements.
- Include appropriate stop and emergency-stop considerations.
- Do not test experimental control logic on an occupied wheelchair.
- Clearly identify unverified hardware functionality.

## 6. Documentation

Update the README whenever a contribution changes:

- Installation requirements
- Project structure
- Execution instructions
- Dataset format
- Model functionality
- Hardware configuration

## 7. Suggested Contribution Workflow

1. Fork the repository.
2. Create a separate branch for your changes.
3. Implement and test the changes.
4. Update relevant documentation.
5. Commit changes with clear messages.
6. Submit a pull request describing the changes.

## 8. Commit Message Examples

```text
Add EEG preprocessing improvements
Update feature extraction module
Improve model evaluation
Fix real-time prediction issue
Update project documentation
```

## 9. Reporting Issues

When reporting an issue, include:

- A clear description of the problem.
- Steps to reproduce the issue.
- Relevant MATLAB error messages.
- MATLAB version and operating environment.
- Relevant details about the dataset or hardware configuration.

## 10. Code Review

Contributions should be reviewed for correctness, readability, compatibility and safety before being merged into the main branch.

Thank you for helping improve this project.