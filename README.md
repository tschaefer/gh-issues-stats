# github-issues

[![Tag](https://img.shields.io/github/tag/tschaefer/github-issues.svg)](https://github.com/tschaefer/github-issues/releases)
![Ruby Version](https://img.shields.io/badge/Ruby-%3E%3D%203.3-%23007d9c)
[![Contributors](https://img.shields.io/github/contributors/tschaefer/github-issues)](https://github.com/tschaefer/github-issues/graphs/contributors)
[![License](https://img.shields.io/github/license/tschaefer/github-issues)](./LICENSE)

A Ruby gem for analyzing GitHub repository issues with statistics and visualizations.

## Description

`github-issues` is a command-line tool that helps you analyze and understand the issues lifecycle in any GitHub repository. It provides detailed statistics, visualizations, and insights about issues including:

- Issue creation trends over time (yearly/monthly breakdowns)
- Closing time statistics (average and median)
- Label-based filtering and analysis
- Visual charts and tables for data representation
- Cached data for faster subsequent queries

## Installation

### Install as a Gem

```bash
gem install github-issues
```

### Install from Source

```bash
git clone https://github.com/tschaefer/github-issues.git
cd github-issues
bundle install
rake install
```

## Requirements

- Ruby >= 3.3.0
- A GitHub account (optional, but recommended for higher API rate limits)

## Usage

> [!IMPORTANT]
> Initial data fetching may take some time and consume a significant amount of
> memory depending on the number of issues in the repository.

### Basic Commands

#### View Issues by Year

Display yearly statistics for a repository:

```bash
github-issues yearly owner/repository
```

Example:
```bash
github-issues yearly rails/rails
```

Options:
- `--format FORMAT`- Specify output format (table, chart, json). (default: table)
- `--label LABEL` - Filter by specific label (can be used multiple times; prefix with `!` to exclude)
- `--[no-]finished` - Show finished stats (default: false)
- `--[no-]legend` - Toggle legend display (default: true)
- `--[no-]pager` - Toggle output paging (default: false)

#### View Issues by Month

Display monthly statistics for a specific year:

```bash
github-issues monthly YEAR owner/repository
```

Example:
```bash
github-issues monthly 2023 rails/rails
```

Options: Same as yearly command

#### List All Labels

Display all labels used in a repository:

```bash
github-issues labels owner/repository
```

### Global Options

- `--configuration-file FILE` - Specify a configuration file (default: ~/.config/github-issues.json)
- `--cache-path PATH` - Specify cache directory (default:
  ~/.cache/github-issues)
- `--refresh INTERVAL` - Set refresh interval (e.g., 30minutes, 2.5hours, 1day) (default: 24hours)
- `-v, --version` - Show version information
- `-m, --man` - Show manual page

### Examples

Filter issues by multiple labels:
```bash
github-issues yearly --label bug --label '!enhancement' rails/rails
```

Show monthly breakdown with chart visualization:
```bash
github-issues monthly --format chart 2023 rails/rails
```

Use with custom refresh interval:
```bash
github-issues --refresh 2hours yearly rails/rails
```

## Configuration

### Authentication

For higher API rate limits, you can provide GitHub credentials through the
configuration file. See [Octokit Authentication](https://github.com/octokit/octokit.rb?tab=readme-ov-file#authentication) for supported authentication methods.

### Caching

Issue data is cached locally in to improve performance on subsequent queries.
The cache is automatically refreshed on call based on the refresh interval
(default: 24 hours).

## Features

- **Statistical Analysis**: Calculate average and median closing times for issues
- **Time-based Grouping**: View issues grouped by year or month
- **Label Filtering**: Filter issues by one or more labels
- **Multiple Output Formats**: Choose between tables and charts
- **Smart Caching**: Local SQLite database for fast repeated queries
- **Flexible Refresh**: Configurable data refresh intervals
- **Pagination Support**: Built-in pager for large datasets
- **Issue Detection**: Skips draft issues and pull requests

## Development

### Setup

```bash
git clone https://github.com/tschaefer/github-issues.git
cd github-issues
bundle install
```

### Running Tests

```bash
bundle exec rspec
```

### Code Quality

```bash
# Run RuboCop
bundle exec rubocop

# Run with auto-correct
bundle exec rubocop -a
```

## Architecture

The gem is structured around several key components:

- **Database Layer**: SQLite-based storage for issue data
- **Fetch Module**: Retrieves issues from GitHub API using Octokit
- **Statistics Module**: Calculates various metrics (average, median, etc.)
- **Group Module**: Organizes issues by time periods
- **App Layer**: CLI interface built with Clamp

## Dependencies

- `clamp` - Command-line parsing
- `faraday-retry` - HTTP request retries
- `hashie` - Enhanced Hash functionality
- `octokit` - GitHub API client
- `pastel` - Terminal color output
- `sqlite3` - Local data caching
- `tty-pager` - Output pagination
- `tty-table` - Table rendering
- `unicode_plot` - Chart visualization

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- All tests pass
- Code follows RuboCop style guidelines
- New features include appropriate tests

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
