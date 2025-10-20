# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir project for building an MCP (Model Context Protocol) Server with a plugin architecture for request processing. The project is in early stages and uses Mix as the build tool.

## Development Commands

### Dependencies
```bash
mix deps.get          # Fetch dependencies
```

### Building and Running
```bash
mix compile           # Compile the project
iex -S mix            # Start interactive Elixir shell with project loaded
```

### Testing
```bash
mix test              # Run all tests
mix test <file_path>  # Run a specific test file
mix test --trace      # Run tests with detailed trace output
```

### Code Quality
```bash
mix format            # Format code according to .formatter.exs
mix format --check-formatted  # Check if code is properly formatted
```

## Architecture

The project follows standard Elixir/Mix conventions:
- Application entry point: `lib/hit_me_db_one_more_times.ex`
- Tests in `test/` directory with `_test.exs` suffix
- Mix configuration in `mix.exs`

The goal is to build an MCP server with a plugin-based architecture, allowing dynamic loading and processing of requests through plugins.
