---
name: prototype
description: Build a throwaway prototype to flush out a design before committing to it. Routes between two branches — a runnable terminal app for state/business-logic questions, or several radically different UI variations toggleable from one route. Use when the user wants to prototype, sanity-check a data model or state machine, mock up a UI, explore design options, or says "prototype this", "let me play with it", "try a few designs".
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify which question is being answered:

- **"Does this logic / state model feel right?"** → Build a tiny interactive terminal app that pushes the state machine through cases that are hard to reason about on paper.
- **"What should this look like?"** → Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar.

## Rules

1. **Throwaway from day one, and clearly marked as such.** Locate the prototype code close to where it will actually be used.
2. **One command to run.** Whatever the project's existing task runner supports.
3. **No persistence by default.** State lives in memory.
4. **Skip the polish.** No tests, no error handling beyond what makes the prototype runnable.
5. **Surface the state.** After every action, print or render the full relevant state so the user can see what changed.
6. **Delete or absorb when done.** When the prototype has answered its question, either delete it or fold the validated decision into the real code.

## When done

The *answer* is the only thing worth keeping from a prototype. Capture it somewhere durable (commit message, ADR, issue) along with the question it was answering.
