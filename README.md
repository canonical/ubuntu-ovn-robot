# ubuntu-ovn-robot

Automatic validation of binary artifacts maintained by the Ubuntu OVN
Engineering team.

## Usage

While the main purpose of this repository is to run automatic CI workflows,
bulk of the logic is implemented in the `justfile` and can be executed
locally.

To see the list of available recipes, run:

```shell
just
```

### Getting test coverage for OVS/OVN

Both [OVN](https://github.com/ovn-org/ovn) and
[OVS](https://github.com/openvswitch/ovs) share the same workflow fo getting
the test coverage. We will work with `ovn` in this example.

The first step is to bootstrap the project. This will check out the current
code from the `main` branch of the project into `./workspace/<project>/`,
configure the project for compilation with coverage, and install build/test
dependencies.

```shell
just bootstrap ovn
```

(Optional) If you are, at this point, interested only in building the project,
you can run:

```shell
just build ovn
```

Finally, to get the coverage report you can run:

```shell
just cover ovn
```

This step will run unit tests and output two types of coverage reports. One is
the native `lcov` report produced in `./workspace/ovn/tests/lcov/`, and the
other is the `cobertura` XML file in `./workspace/ovn/.coverage/cobertura.xml`

To clean up the workspace afterwards, you can run

```shell
just clean [project]
```

Omitting the `project` parameter will remove the entire `./workspace`
directory.

