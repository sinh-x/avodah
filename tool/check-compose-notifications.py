#!/usr/bin/env python3
"""Render notification Compose contracts with synthetic input; never deploy.

Run from any directory: python3 tool/check-compose-notifications.py
No local .env, Docker daemon or third-party Python modules are needed. Rendered environments are captured, never printed.
"""

import json
import os
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parent.parent
BASE = "docker-compose.yml"
SYNTHETIC_TOKEN = "compose-fixture-only-not-a-secret-00000000"


def compose(*files, values=None):
    # Do not inherit real producer/provider credentials or COMPOSE_* overrides.
    env = {
        "PATH": os.environ.get("PATH", os.defpath),
        "HOME": os.environ.get("HOME", "/nonexistent"),
        "LANG": "C.UTF-8",
        "COMPOSE_DISABLE_ENV_FILE": "true",
        **(values or {}),
    }
    command = [
        "docker", "compose", "--env-file", "/dev/null",
        "--project-name", "avodah-compose-check",
    ]
    for file in files or (BASE,):
        command.extend(["-f", str(ROOT / file)])
    command.extend(["config", "--format", "json"])
    return subprocess.run(
        command, cwd=ROOT, env=env, capture_output=True, text=True,
        timeout=30, check=False,
    )


class ComposeNotificationsTest(unittest.TestCase):
    def render(self, *files, values=None):
        result = compose(*files, values=values)
        # Intentionally avoid dumping stdout/stderr or a rendered environment.
        self.assertEqual(result.returncode, 0, "Compose rendering failed")
        return json.loads(result.stdout)["services"]

    def test_default_is_private_persistent_and_sending_disabled(self):
        services = self.render()
        sync = services["avodah-sync"]
        env = sync["environment"]
        self.assertEqual(sync["network_mode"], "host")
        self.assertEqual(env["SYNC_HOST"], "127.0.0.1")
        self.assertEqual(env["JIRA_ENABLED"], "false")
        self.assertEqual(env["AGENT_API_URL"], "http://localhost:9848")
        self.assertEqual(sync["command"], ["/app/sync_server", "--port", "9847"])
        self.assertEqual(env["AVODAH_NOTIFICATION_SEND_TOKEN"], "")
        self.assertNotIn("AVODAH_FCM_PROJECT_ID", env)
        self.assertNotIn("GOOGLE_APPLICATION_CREDENTIALS", env)
        self.assertEqual(sync["restart"], "unless-stopped")
        self.assertFalse(sync.get("ports"))
        mounts = {mount["target"]: mount for mount in sync["volumes"]}
        self.assertEqual(set(mounts), {"/data", "/config"})
        for mount in mounts.values():
            self.assertEqual(mount["type"], "bind")
            self.assertFalse(mount.get("read_only", False))
        self.assertEqual(env["AVODAH_DATA_DIR"], "/data")
        self.assertEqual(env["AVODAH_CONFIG_DIR"], "/config")

    def test_producer_credential_is_runtime_sync_only(self):
        services = self.render(values={
            "AVODAH_NOTIFICATION_SEND_TOKEN": SYNTHETIC_TOKEN,
        })
        self.assertEqual(
            services["avodah-sync"]["environment"]["AVODAH_NOTIFICATION_SEND_TOKEN"],
            SYNTHETIC_TOKEN,
        )
        self.assertNotIn("AVODAH_NOTIFICATION_SEND_TOKEN", services["avodah-web"]["environment"])
        for service in services.values():
            self.assertNotIn(SYNTHETIC_TOKEN, json.dumps(service.get("build", {})))

    def test_custom_port_and_existing_operator_settings_are_preserved(self):
        services = self.render(values={
            "SYNC_PORT": "19847", "AGENT_PORT": "19848", "JIRA_ENABLED": "true",
            "AVODAH_CONFIG": "/var/empty/avodah-compose-check/config",
            "AVODAH_DATA": "/var/empty/avodah-compose-check/data",
        })
        sync = services["avodah-sync"]
        self.assertEqual(sync["command"][-1], "19847")
        self.assertEqual(sync["environment"]["SYNC_PORT"], "19847")
        self.assertEqual(sync["environment"]["AGENT_API_URL"], "http://localhost:19848")
        self.assertEqual(sync["environment"]["JIRA_ENABLED"], "true")
        self.assertEqual(services["avodah-web"]["environment"]["SYNC_SERVER_PORT"], "19847")
        self.assertEqual(
            {v["target"]: v["source"] for v in sync["volumes"]},
            {"/config": "/var/empty/avodah-compose-check/config",
             "/data": "/var/empty/avodah-compose-check/data"},
        )

    def test_environment_files_are_excluded_from_server_build_context(self):
        patterns = (ROOT / ".dockerignore").read_text().splitlines()
        self.assertIn(".env", patterns)
        self.assertIn(".env.*", patterns)


if __name__ == "__main__":
    unittest.main(verbosity=2)
