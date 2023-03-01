{ pkgs, ... }:

let
  db_user = "postgres";
  db_host = "localhost";
  db_port = "5432";
  db_name = "db";
  dj = djangoArgs: ''
    devenv shell python manage.py collectstatic --no-input
    && devenv shell python manage.py ${djangoArgs}
  '';
  
  test = testArgs: ''
    echo "Launching database..."
    # Redirect logs to `devenv.log` via `> /tmp/devenv.log 2>&1`
    # ... & run in background via `&`
    start-db > /tmp/devenv.log 2>&1 & 
    
    echo "Waiting for database to launch..."
    while ! nc -z localhost ${db_port}; do
      sleep 0.1
    done

    # Run tests
    python manage.py test ${testArgs}

    # Kill background processes running the database & Django server
    fuser -k ${db_port}/tcp
  '';
in
{
  packages = [ pkgs.git pkgs.postgresql_14 pkgs.python310 pkgs.poetry ];

  env = {
    PYTHON_VERSION = "3.10";
    DATABASE_URL = "postgresql://${db_user}@${db_host}:${db_port}/${db_name}";
    DEBUG = true;
    STATIC_ROOT = "/tmp/static";
  };

  enterShell = ''
    echo "Building poetry virtual environment..."
    poetry env use $PYTHON_VERSION
    poetry install

    # Automatically activate virtual environment on shell entry
    # https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
    VIRTUAL_ENV=`poetry env info --path` && export VIRTUAL_ENV 
    export PATH="$VIRTUAL_ENV/bin:$PATH";

    echo "Using versions..."
    psql --version
    python --version
    pip --version
    poetry --version
  '';

  services.postgres = {
    enable = true;
    initialScript = "CREATE USER ${db_user} SUPERUSER;";
    initialDatabases = [ { name = db_name; } ];
    listen_addresses = db_host;
  };

  scripts = {
      run-tests.exec = test "";
      start-db.exec = "devenv up";
  };
}
