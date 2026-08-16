# Changelog

## 0.1.4

- Bound HSM ancestry, initial-child resolution, and descendant queries when
  malformed metadata contains cycles.
- Added diagnostics for missing or inconsistent initial children, parent-link
  cycles, and initial-child cycles.
- Clamped negative workflow retry policies and kept retry-budget reporting
  non-negative.
- Added checked periodic scheduling and made the legacy periodic API safe for
  zero or negative intervals.
- Added regression coverage for all of the above boundary cases across the
  supported MoonBit backends.

Verification for this release:

```text
moon check --deny-warn          PASS
moon build --target all         PASS
moon test --target all          47/47 PASS
moon fmt --check                PASS
moon info --target all          PASS
```
