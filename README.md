# gitolize

`gitolize` is a simple tool that wraps arbitrary shell commands
so that they get a working directory cloned from git and
any changes made by them are pushed back to the git repository.

## Usage

```console
house-reliability-engineering/gitolize$ ./gitolize.sh
Usage: gitolize.sh [-a] [-b <branch>] [-c] [-l <local_directory>] [-m <message>] [-p <project>] [-r <repository>] [-s] [-v] [-w] [command...]
house-reliability-engineering/gitolize$


```

### Options

- `-a`:
  when used with `-s`, ANSI escape sequences from the command's
  output are preserved in the git commit message.
  By default the ANSI escape sequences are stripped.

- `-b <branch>`:
  operate on a different branch than the
  repository's default one.

- `-c`:
  print the git commit SHA on stderr.

- `-l <local_directory>`:
  use a particular directory for a git checkout instead
  of a tmpdir. If this directory is a git checkout, then
  the `-r` option is ignored.

- `-m <message>`:
  use a particular git message content instead of
  the command that has been run.

- `-p <project>`:
  lock the state for a particular project.
  This allows multiple projects to be manipulated
  concurrently without blocking each other when
  using the `-w` option.

- `-r <repository>`:
  clone the git repository from the provided URL.
  This option is ignored if `-l` is used with
  an existing git checkout.

- `-s`:
  capture stdout and stderr of the command
  and add it to the git commit message.

- `-v`:
  be verbose.

- `-w`:
  lock the repository before running the command.
  After the command exits, commit back changes made by it
  and unlock the repository again.
