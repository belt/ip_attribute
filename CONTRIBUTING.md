# Contributing to IpAttribute

Thank you for your interest in contributing to IpAttribute! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting Started

### Prerequisites
- Ruby 3.4.0 or higher
- Bundler/ore-light
- Git/Gitoxide

### Development Setup

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ip_attribute.git
   cd ip_attribute
   ```

3. Install dependencies:
   ```bash
   bundle install
   ```

4. Run tests to ensure everything works:
   ```bash
   bundle exec rspec
   ```

## Development Workflow

### 1. Create a Branch

Create a feature branch from the `main` branch:
```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

Follow these guidelines when making changes:

#### Code Style
- Follow [Standard Ruby](https://github.com/standardrb/standard) conventions
- Run `bundle exec standardrb` to check your code
- Run `bundle exec standardrb --fix` to automatically fix issues

#### Testing
- Write tests for new functionality
- Ensure all tests pass: `bundle exec rspec`
- For property-based testing, see `spec/fuzz/` examples

#### Documentation
- Update README.md if you add new features
- Update CHANGELOG.md for user-facing changes
- Add comments for complex logic

### 3. Commit Changes

Use [Conventional Commits](https://www.conventionalcommits.org/) format:
```bash
git commit -m "feat: add IPv6 subnet query support"
```

Common commit types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `refactor`: Code refactoring
- `chore`: Maintenance tasks

### 4. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear description of changes
- Reference to related issues
- Summary of testing performed

## Testing Guidelines

### Running Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/lib/ip_attribute/converter_spec.rb

# Run tests with coverage
bundle exec rspec --profile
```

### Property-Based Testing
The project includes property-based fuzz testing in `spec/fuzz/`. These tests:
- Generate random IP addresses
- Test round-trip conversion
- Validate edge cases

## Project Structure

```
lib/ip_attribute/           # Core library
  - converter.rb           # IP ↔ integer conversion
  - type.rb                # ActiveRecord type
  - strategy_*.rb          # Storage strategies
  - query_methods.rb       # Subnet queries

lib/generators/            # Migration generators
spec/                      # Tests
  - lib/ip_attribute/      # Unit tests
  - fuzz/                  # Property-based tests
```

## Reporting Issues

When reporting issues, please include:
- Ruby version
- ActiveRecord version
- Steps to reproduce
- Expected vs actual behavior
- Relevant code snippets

## Feature Requests

For feature requests, please:
1. Check if the feature already exists
2. Explain the use case
3. Suggest implementation approach if possible

## Security Issues

Please report security vulnerabilities privately via email to 153964+belt@users.noreply.github.com. Do not create public issues for security concerns.

## License

By contributing, you agree that your contributions will be licensed under the project's MIT License.
