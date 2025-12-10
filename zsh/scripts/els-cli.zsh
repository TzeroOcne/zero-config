#!/usr/bin/env zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/els-env.zsh" || exit 1

CLI_NAME="server"
CLI_LIBS="$ES_HOME/lib/tools/server-cli"
LAUNCHER_CLASSPATH="$ES_HOME/lib/*;$ES_HOME/lib/cli-launcher/*"

DEFAULT_JAVA_OPTS=(-Xms4m -Xmx64m -XX:+UseSerialGC)
USER_JAVA_OPTS=()
if [[ -n "$CLI_JAVA_OPTS" ]]; then
  USER_JAVA_OPTS=("${(@s/ /)CLI_JAVA_OPTS}")
fi

(cd "$ES_HOME" && "$JAVA" \
  "${DEFAULT_JAVA_OPTS[@]}" \
  "${USER_JAVA_OPTS[@]}" \
  -Dcli.name=$CLI_NAME \
  -Dcli.script=$CLI_SCRIPT \
  -Dcli.libs=$CLI_LIBS \
  -Des.path.home=$ES_HOME \
  -Des.path.conf=$ES_PATH_CONF \
  -Des.distribution.type=$ES_DISTRIBUTION_TYPE \
  -cp "$LAUNCHER_CLASSPATH" \
  org.elasticsearch.launcher.CliToolLauncher "$@")
