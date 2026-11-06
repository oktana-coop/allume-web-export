# Testing

The tests use [Swift Testing](https://developer.apple.com/documentation/testing), and none of them
touches the network.

## Running Tests

Run every test with:

```sh
swift test
```

To run one module's tests, or one suite, filter by its name:

```sh
swift test --filter AllumeWebRenderingTests
swift test --filter CardsTests
```

## Unit Tests

Each module has a test target named after it in `Tests/`, e.g. `Tests/AllumeWebRenderingTests/`.
They check the module on its own, with small inputs written in the tests.

## Integration Tests

`Tests/AllumeWebIntegrationTests/` reads the public fixture in `Fixtures/Languages/`, renders and
publishes it, and compares the pages with the expected files in
`Tests/AllumeWebIntegrationTests/Expected/Languages/`. These are the accepted output, so any change
in the pages fails the tests.

### Updating Expected Files

When a change in the output is intended, accept it with:

```sh
ACCEPT=1 swift test --filter AllumeWebIntegrationTests
```

That replaces the expected files with the current output. Review the change with `git diff`, and
commit the expected files together with the change that caused it.
