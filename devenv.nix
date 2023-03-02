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
      echo
      echo "Building poetry virtual environment..."

      poetry env use ${python_version}

      echo "Using versions ..."
      python --version
      poetry --version

      poetry install
    '';
    start-db.exec = ''
      echo
      psql --version

      # Start Postgres if not running ...
      if ! nc -z ${db_host} ${db_port};
      then
        echo "Starting Database in the background on ${db_host}:${db_port} ..."
        nohup devenv up > /tmp/devenv.log 2>&1 &
      fi
    '';
    wait-for-db.exec = ''
      echo
      echo "Waiting for database to start .."
      echo "(if wait exceeds 100%, check /tmp/devenv.log for errors!)"
      
      timer=0;
      n_steps=99;
      while true;
      do
        if nc -z ${db_host} ${db_port}; then
          printf "\nDatabase is running!\n\n"
          exit 0
        elif [ $timer -gt $n_steps ]; then
          printf "\nDatabase failed to launch!\n\n"
          exit 1
        else
          sleep 0.1
          let timer++
          printf "%-*s" $((timer+1)) '[' | tr ' ' '#'
          printf "%*s%3d%%\r"  $((100-timer))  "]" "$timer"
        fi
      done
    '';
    run-tests.exec = ''
      start-db
      wait-for-db || exit 1
      python manage.py collectstatic --noinput
      python manage.py test
    '';
  };
}
