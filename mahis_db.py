"""Database settings for the MAHIS DQA scripts.

Settings are read from environment variables, or from a file called .env in the repository root
(copy .env.example to .env and fill it in). Nothing is stored in the code.
"""
import os

_REQUIRED = ("MAHIS_DB_HOST", "MAHIS_DB_USER", "MAHIS_DB_PASSWORD", "MAHIS_DB_NAME")


def _load_env_file():
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    if not os.path.exists(path):
        return
    for line in open(path):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


_load_env_file()
_missing = [k for k in _REQUIRED if not os.environ.get(k)]
if _missing:
    raise SystemExit("Missing database settings: " + ", ".join(_missing) +
                     "\nCopy .env.example to .env and fill it in, or set them as environment variables.")

DB_CONFIG = {
    "host": os.environ["MAHIS_DB_HOST"],
    "port": os.environ.get("MAHIS_DB_PORT", "3306"),
    "user": os.environ["MAHIS_DB_USER"],
    "password": os.environ["MAHIS_DB_PASSWORD"],
    "database": os.environ["MAHIS_DB_NAME"],
}
