#!/usr/bin/env python3
"""Charm the machine."""
import ops


class PrincipalCharm(ops.CharmBase):
    """Charm the machine."""

    def __init__(self, framework: ops.Framework):
        super().__init__(framework)
        framework.observe(self.on.install, self._on_install)

    def _on_install(self, event: ops.InstallEvent):
        self.unit.status = ops.ActiveStatus()


if __name__ == "__main__":  # pragma: nocover
    ops.main(PrincipalCharm)  # type: ignore
