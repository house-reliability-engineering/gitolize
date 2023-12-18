import pulumi

reference = pulumi.StackReference("organization/a/test")

pulumi.export("proxied-output", reference.get_output("test-output"))
