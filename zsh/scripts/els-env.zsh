# els-env.zsh — defines ES environment (not exported)

# NOTE: Use this inside another script like:
#   source els-env.zsh

readonly ES_HOME="C:/ProgramData/chocolatey/lib/elasticsearch/tools/elasticsearch-8.18.2"

readonly ES_CLASSPATH="$ES_HOME/lib/*"
readonly ES_MODULEPATH="$ES_HOME/lib"
readonly LAUNCHERS_CLASSPATH="$ES_CLASSPATH;$ES_HOME/lib/launchers/*;$ES_HOME/lib/java-version-checker/*"
readonly SERVER_CLI_CLASSPATH="$ES_CLASSPATH;$ES_HOME/lib/tools/server-cli/*"

readonly HOSTNAME="$(hostname)"

if [[ -z "$ES_PATH_CONF" ]]; then
  readonly ES_PATH_CONF="$ES_HOME/config"
else
  readonly ES_PATH_CONF="$(cd "$ES_PATH_CONF" && pwd)"
fi

readonly ES_DISTRIBUTION_TYPE="zip"

if [[ -n "$ES_JAVA_HOME" ]]; then
  JAVA="$ES_JAVA_HOME/bin/java"
  JAVA_TYPE="ES_JAVA_HOME"
  if [[ ! -x "$JAVA" ]]; then
    echo "could not find java in $JAVA_TYPE at $JAVA" >&2
    return 1
  fi
  "$JAVA" -cp "$ES_HOME/lib/java-version-checker/*" \
    org.elasticsearch.tools.java_version_checker.JavaVersionChecker || return 1
else
  JAVA="$ES_HOME/jdk/bin/java"
  ES_JAVA_HOME="$ES_HOME/jdk"
  JAVA_TYPE="bundled JDK"
fi

if [[ -n "$JAVA_TOOL_OPTIONS" ]]; then
  echo "ignoring JAVA_TOOL_OPTIONS=$JAVA_TOOL_OPTIONS"
  echo "pass JVM parameters via ES_JAVA_OPTS"
  unset JAVA_TOOL_OPTIONS
fi
if [[ -n "$_JAVA_OPTIONS" ]]; then
  echo "ignoring _JAVA_OPTIONS=$_JAVA_OPTIONS"
  echo "pass JVM parameters via ES_JAVA_OPTS"
  unset _JAVA_OPTIONS
fi
if [[ -n "$JAVA_HOME" ]]; then
  echo "warning: ignoring JAVA_HOME=$JAVA_HOME; using $JAVA_TYPE" >&2
fi
if [[ -n "$JAVA_OPTS" ]]; then
  echo "warning: ignoring JAVA_OPTS=$JAVA_OPTS"
  echo "pass JVM parameters via ES_JAVA_OPTS"
fi

