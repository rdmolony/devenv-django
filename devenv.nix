{ pkgs, ... }:

let
  db_user = "postgres";
  db_host = "localhost";
  db_port = "5432";
  db_name = "db";
  python_version = "3.10";
in
{
  packages = [ pkgs.git pkgs.postgresql_14 pkgs.python310 pkgs.poetry ];

  env = {
    PYTHON_VERSION = python_version;
    DATABASE_URL = "postgresql://${db_user}@${db_host}:${db_port}/${db_name}";
    DEBUG = true;
    STATIC_ROOT = "/tmp/static";
  };

  enterShell = ''
    create-poetry-environment

    # Activate poetry environment on shell entry
    # https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
    VIRTUAL_ENV=`poetry env info --path` && export VIRTUAL_ENV 
    export PATH="$VIRTUAL_ENV/bin:$PATH";
  '';

  services.postgres = {
    enable = true;
    initialScript = "CREATE USER ${db_user} SUPERUSER;";
    initialDatabases = [ { name = db_name; } ];
    listen_addresses = db_host;
  };

  processes = {
    runserver.exec = ''
      devenv shell python manage.py runserver
    '';
  };

  scripts = {
    create-poetry-environment.exec = ''
      echo "Building poetry virtual environment..."

      poetry env use ${python_version}

      echo "Using versions ..."
      python --version
      poetry --version

      poetry install
    '';
    start-db.exec = ''
      psql --version

      # Start Postgres if not running ...
      if ! nc -z ${db_host} ${db_port};
      then
        echo "Starting Postgres in background on ${db_host}:${db_port} ..."
        # NOTE: This is a hack to get Postgres to run in the background
        # ... that relies on `devenv` naming the process `postgres`
        # ... startup shell as `start-postgres`
        nohup start-postgres > /tmp/postgres.log 2>&1 &
      fi
    '';
    wait-for-db.exec = ''
      echo "Waiting for Postgres to start on ${db_host}:${db_port} ..."
      
      timer=0;
      n_seconds=20;
      while true;
      do
        if nc -z ${db_host} ${db_port}; then
          echo "Database is running!"
          break
        elif [ $timer -gt $n_seconds ]; then
          echo "Database failed to launch!"
          break
        else
          sleep 0.1
          let timer++
        fi
      done
    '';
    run-tests.exec = ''
      start-db
      wait-for-db
      python manage.py collectstatic --noinput
      python manage.py test
    '';
  };
}
