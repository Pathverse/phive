# Project Brief

## Project
`phive` — A generator-first Flutter/Dart package for building annotation-driven Hive CE model adapters with composable, context-aware hook pipelines.

## Goal
Enable users to write clean domain models (even using tools like `Freezed`) and annotate them with `@PHiveType` and `@PHiveField` to attach behaviors (Encryption, TTL, Validation) without polluting model properties with wrapper classes.

## Core Outcome
`phive_generator` reads models with `@PHiveType`/`@PHiveField` and generates a custom `PTypeAdapter<T>`. This adapter orchestrates declared hooks (running `preRead`, `postRead`, `preWrite`, `postWrite`) against a shared `PHiveCtx` to inject payload format, serialize metadata, and apply transformations during persistence.

## TDD Paradigm
Active development strictly follows Test-Driven Development (TDD). The core runtime components (`PTypeAdapter`, `PHiveCtx`, `PHiveHook`) are implemented and verified via unit tests before generator templates are built.
