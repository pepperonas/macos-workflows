# Tests

Plain-bash test suite for the workflows in this repo. No external dependencies
(no [bats](https://github.com/bats-core/bats-core), no shellcheck required).

## Running

```bash
./tests/run.sh
```

Exit code is `0` if all tests pass, `1` otherwise. Suitable for CI.

## How it works

`tests/run.sh` discovers every `tests/test-*.sh` file, sources it, then
invokes each `test_*` function defined inside.

Each test file should:

1. **Source** the script under test (using `$REPO_ROOT/...`):
   ```bash
   source "$REPO_ROOT/workflows/cleanup-caches/cleanup-caches.sh"
   ```
2. Define one or more `test_<name>()` functions that:
   - Return `0` on success, non-zero on failure
   - Use the exported helpers `assert_equal`, `assert_contains`,
     `assert_success` to print diagnostics on failure

Scripts that need to be source-safe should guard their main execution:

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## Helpers

| Helper | Signature | Behavior |
|--------|-----------|----------|
| `assert_equal` | `expected actual [msg]` | Compares strings byte-for-byte |
| `assert_contains` | `haystack needle [msg]` | Substring containment |
| `assert_success` | `exit_code [msg]` | Asserts code is `0` |

## Conventions

- One file per workflow: `test-<workflow-name>.sh`
- Tests should be deterministic — use `mktemp -d` for filesystem tests,
  not real `$HOME` paths
- Smoke tests (running the script as a subprocess) are fine for integration
  coverage; pure-function tests are preferred for fast feedback
- Plist validation (`plutil -lint`) belongs in tests too

## Example

```bash
# tests/test-mywflow.sh
source "$REPO_ROOT/workflows/mywflow/mywflow.sh"

test_my_function_basic() {
    local out
    out=$(my_function "input")
    assert_equal "expected" "$out" "my_function returns 'expected'"
}

test_my_workflow_help() {
    local out
    out=$(bash "$REPO_ROOT/workflows/mywflow/mywflow.sh" help)
    assert_contains "$out" "USAGE" "help shows USAGE"
}
```
