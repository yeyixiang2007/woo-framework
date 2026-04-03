# API Overview (English)

API reference is split by responsibility:

- [Core Runtime API](core-runtime.md)
- [Module API](module-api.md)
- [Builder API](builder-api.md)

## Suggested reading order

1. `core-runtime.md`: runtime container and buses.
2. `module-api.md`: module lifecycle and registration.
3. `builder-api.md`: editor builder extension layer.

## Conventions

- Most IDs are `StringName` (recommended as constants, example: `&"counter"`).
- `Command`/`Query` handlers can be:
  - `Callable`
  - `Script` (instance must implement `execute(context, payload)`)
  - `Object` (object must implement `execute(context, payload)`)
