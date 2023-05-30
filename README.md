# Finando | Infrastructure modules

A collection of reusable infrastructure modules.

[![GitHub Actions](https://github.com/finando/infrastructure-modules/actions/workflows/release.yaml/badge.svg)](https://github.com/finando/infrastructure-modules/actions/workflows/release.yaml)

## Table of Contents

  - [Contributing](#contributing)
    - [Development environment](#development-environment)
    - [Implementing changes](#implementing-changes)
    - [Releasing new versions](#releasing-new-versions)

## Contributing

### Development environment

The project is structured as a monorepo and is managed by [Lerna](https://lerna.js.org/).

Follow the outlined steps in order to set up a development environment.

#### Step 1 - Install dependencies
```sh
npm install
```

#### Step 2 - Run preparation script
```sh
npm run prepare
```

#### Step 3 - Bootstrap project
```sh
npx lerna bootstrap
```

### Implementing changes

In order to implement changes, create a branch from `master` branch, commit changes and open a pull request. Use [atomic](https://en.wikipedia.org/wiki/Atomic_commit) [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) to add changes to Git history. Use `npm run commit` to start an interactive wizard that helps with formatting commits according to specified standard.

### Releasing new versions

Once changes are approved by pull request reviewers, merge the pull request to `master` branch. This will trigger an automatic release workflow in GitHub Actions. Follow along to make sure it completes successfully.
