#!/usr/bin/env bats
#shellcheck disable

load 'helpers/bats-support/load'
load 'helpers/bats-file/load'
load 'helpers/bats-assert/load'

s="${HOME}/dotfiles/scripting/helpers/baseHelpers.bash"
base="$(basename $s)"

[ -f "$s" ] \
  && { source "$s"; trap - EXIT INT TERM ; } \
  || { echo "Can not find script to test" ; exit 1 ; }

# Set Flags
quiet=false;              printLog=false;             logErrors=true;   verbose=false;
force=false;              strict=false;               dryrun=false;
debug=false;              sourceOnly=false;           args=();

setup() {

  testdir="$(temp_make)"
  curPath="$PWD"

  BATSLIB_FILE_PATH_REM="#${TEST_TEMP_DIR}"
  BATSLIB_FILE_PATH_ADD='<temp>'

  cd "${testdir}"
}

teardown() {
  cd $curPath
  temp_del "${testdir}"
}

@test "Sanity..." {
  run true

  assert_success
  assert_output ""
}

########### BEGIN TESTS ##########

@test "debug" {
  run debug "testing"
  assert_output --partial "[  debug] testing"
}

@test "die" {
  run die "testing"
  assert_line --index 0 --partial "[  fatal] testing ("
}

@test "error" {
  run error "testing"
  assert_output --partial "[  error] testing (func: run < test_error < bats_perform_test < main)"
}

@test "_execute_: Debug command" {
  dryrun=true
  run _execute_ "rm testfile.txt"
  assert_success
  assert_output --partial "[ dryrun] rm testfile.txt"
  dryrun=false
}

@test "_execute_: No command" {
  run _execute_

  assert_failure
  assert_output --regexp "_execute_ needs a command$"
}

@test "_execute_: Bad command" {
  touch "testfile.txt"
  run _execute_ "rm nonexistant.txt"

  assert_failure
  assert_output --partial "[warning] rm nonexistant.txt"
  assert_file_exist "testfile.txt"
}

@test "_execute_: Good command" {
  touch "testfile.txt"
  run _execute_ "rm testfile.txt"
  assert_success
  assert_output --partial "[success] rm testfile.txt"
  assert_file_not_exist "testfile.txt"
}

@test "_findBaseDir_" {
  run _findBaseDir_
  assert_output "/usr/local/Cellar/bats/0.4.0/libexec"
}

@test "_haveFunction_: Success" {
  run _haveFunction_ "_haveFunction_"

  assert_success
}

@test "_haveFunction_: Failure" {
  run _haveFunction_ "_someUndefinedFunction_"

  assert_failure
}

@test "header" {
  run header "testing"
  assert_output --regexp "\[ header\] == testing =="
}

@test "info" {
  run info "testing"
  assert_output --regexp "[0-9]+:[0-9]+:[0-9]+ (AM|PM) \[   info\] testing"
}

@test "input" {
  run input "testing"
  assert_output --partial "[  input] testing"
}

@test "logging" {
  printLog=true; logFile="${HOME}/tmp/bats-baseHelpers-test.log";
  header "$logFile"
  dryrun "dryrun"
  notice "testing"
  info "testing again"
  success "last test"

  assert_file_exist "${logFile}"

  run cat "${logFile}"
  assert_line --index 1 --partial "[ notice] testing"
  assert_line --index 2 --partial "[   info] testing again"
  assert_line --index 3 --partial "[success] last test"

  rm "$logFile"
  printLog=false; unset logFile;
}

@test "logging: Errors only" {
  printLog=false; logFile="${HOME}/tmp/bats-baseHelpers-tests.log"; quiet=true;
  header "$logFile"
  dryrun "dryrun"
  notice "testing"
  info "testing again"
  success "last test"
  error "test error"
  warning "test warning"

  assert_file_exist "${logFile}"

  run cat "${logFile}"
  assert_line --index 0 --partial "[  error] test error (func: test_logging-3a_Errors_only < bats_perform_test < main)"

  rm "$logFile"
  printLog=false; quiet=false; unset logFile;
}

@test "notice" {
  run notice "testing"
  assert_output --regexp "\[ notice\] testing"
}

@test "_progressBar_: verbose" {
  verbose=true
  run _progressBar_ 100

  assert_success
  assert_output ""
  verbose=false
}

@test "_progressBar_: quiet" {
  quiet=true
  run _progressBar_ 100

  assert_success
  assert_output ""
  quiet=false
}

@test "_seekConfirmation_: yes" {
  run _seekConfirmation_ 'test' <<<"y"

  assert_success
  assert_output --partial "[  input] test"
}

@test "_seekConfirmation_: no" {
  run _seekConfirmation_ 'test' <<<"n"

  assert_failure
  assert_output --partial "[  input] test"
}

@test "_seekConfirmation_: Force" {
  force=true

  run _seekConfirmation_ "test"
  assert_success
  assert_output --partial "test"

  force=false
}

@test "_seekConfirmation_: Quiet" {
  quiet=true
  run _seekConfirmation_ 'test' <<<"y"

  assert_success
  refute_output --partial "test"

  quiet=false
}

@test "success" {
  run success "testing"
  assert_output --regexp "\[success\] testing"
}

@test "quiet" {
  quiet=true
  run notice "testing"
  assert_success
  refute_output --partial "testing"
  quiet=false
}

@test "verbose" {
  run verbose "testing"
  refute_output --regexp "\[  debug\] testing"

  verbose=true
  run verbose "testing"
  assert_output --regexp "\[  debug\] testing"
  verbose=false
}

@test "warning" {
  run warning "testing"
  assert_output --regexp "\[warning\] testing"
}