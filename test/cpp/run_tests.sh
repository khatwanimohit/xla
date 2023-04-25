#!/bin/bash
set -ex
RUNDIR="$(cd "$(dirname "$0")" ; pwd -P)"
BUILDDIR="$RUNDIR/build"
BUILDTYPE="opt"
VERB=
FILTER=
BUILD_ONLY=0
RMBUILD=1
LOGFILE=/tmp/pytorch_cpp_test.log
XLA_EXPERIMENTAL="nonzero:masked_select"
BAZEL_REMOTE_CACHE="0"

# See Note [Keep Going]
CONTINUE_ON_ERROR=false
if [[ "$CONTINUE_ON_ERROR" == "1" ]]; then
  set +e
fi

if [ "$DEBUG" == "1" ]; then
  BUILDTYPE="dbg"
fi

while getopts 'VLDKBF:X:R' OPTION
do
  case $OPTION in
    V)
      VERB="VERBOSE=1"
      ;;
    L)
      LOGFILE=
      ;;
    D)
      BUILDTYPE="dbg"
      ;;
    K)
      RMBUILD=0
      ;;
    B)
      BUILD_ONLY=1
      ;;
    F)
      FILTER="--gtest_filter=$OPTARG"
      ;;
    X)
      XLA_EXPERIMENTAL="$OPTARG"
      ;;
    R)
      BAZEL_REMOTE_CACHE="1"
      ;;
  esac
done
shift $(($OPTIND - 1))

# Set XLA_EXPERIMENTAL var to subsequently executed commands.
export XLA_EXPERIMENTAL

# Inherit env flags for tests.
EXTRA_FLAGS="--test_env=XRT_DEVICE_MAP --test_env=XRT_WORKERS --test_env=XRT_TPU_CONFIG --test_env=GPU_NUM_DEVICES --test_env=PJRT_DEVICE"

# Inherit env flags for tests.
if [[ "$BAZEL_REMOTE_CACHE" == "1" ]]; then
  EXTRA_FLAGS="$EXTRA_FLAGS --config=remote_cache"
  if [[ ! -z "$GCLOUD_SERVICE_KEY_FILE" ]]; then
    EXTRA_FLAGS="$EXTRA_FLAGS --google_credentials=$GCLOUD_SERVICE_KEY_FILE"
  fi
fi

if [ $BUILD_ONLY -eq 0 ]; then
  if [ "$LOGFILE" != "" ]; then
    bazel test $EXTRA_FLAGS --test_output=all //third_party/xla_client:all //test/cpp:all ${FILTER:+"$FILTER"} 2> $LOGFILE
  else 
    bazel test $EXTRA_FLAGS --test_output=all //third_party/xla_client:all //test/cpp:all ${FILTER:+"$FILTER"}
  fi
fi