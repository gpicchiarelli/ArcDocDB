"""Read-only inventory helper for the independent publication audit."""
from pathlib import Path
import hashlib
import os
import stat
import sys


def lisp_string(value):
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"') + '"'


def inventory(root, mode):
    rows = []
    for directory, children, files in os.walk(root, followlinks=False):
        children[:] = sorted(name for name in children if name != 'fasl')
        for name in children:
            if (Path(directory) / name).is_symlink():
                raise ValueError('Symlink directory: ' + str(Path(directory) / name))
        for name in sorted(files):
            path = Path(directory) / name
            info = path.lstat()
            if not stat.S_ISREG(info.st_mode):
                raise ValueError('Nonregular file: ' + str(path))
            if mode == 'filtered' and path.suffix not in ('.lisp', '.log', '.gz'):
                continue
            before = path.stat()
            digest = hashlib.sha256()
            count = 0
            with path.open('rb') as stream:
                for block in iter(lambda: stream.read(1048576), b''):
                    digest.update(block)
                    count += len(block)
            after = path.stat()
            if (before.st_size, before.st_mtime_ns, before.st_ino) != (
                after.st_size, after.st_mtime_ns, after.st_ino
            ) or count != before.st_size:
                raise ValueError('File changed while hashing: ' + str(path))
            rows.append((path.relative_to(root).as_posix(), count, digest.hexdigest()))
    return sorted(rows)


if __name__ == '__main__':
    root = Path(sys.argv[1])
    mode = sys.argv[2]
    if not root.is_dir() or mode not in ('all', 'filtered'):
        raise ValueError('Expected directory and all/filtered mode')
    print('(:schema-version 1 :kind :read-only-file-inventory :files (')
    for path, count, digest in inventory(root, mode):
        print('(:path ' + lisp_string(path) + ' :bytes ' + str(count) +
              ' :sha256 ' + lisp_string(digest) + ')')
    print('))')
