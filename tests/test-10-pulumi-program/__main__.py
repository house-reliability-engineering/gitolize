import os

import pulumi
import pulumi_command

pulumi_command.local.Command(
    "echo",
    create=f"echo {os.environ['PULUMI_TEST_STRING']}",
)
