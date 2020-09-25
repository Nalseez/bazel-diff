#!/bin/bash

workspace_path="$PWD/integration"
bazel_path=$(which bazelisk)

previous_revision="HEAD^"
final_revision="HEAD"
modified_filepaths_output="$PWD/integration/modified_filepaths.txt"
starting_hashes_json="/tmp/starting_hashes.json"
final_hashes_json="/tmp/final_hashes_json.json"
impacted_targets_path="/tmp/impacted_targets.txt"
impacted_test_targets_path="/tmp/impacted_test_targets.txt"

$bazel_path run :bazel-diff -- generate-hashes -w $workspace_path -b $bazel_path $starting_hashes_json

$bazel_path run :bazel-diff -- generate-hashes -w $workspace_path -b $bazel_path -m $modified_filepaths_output $final_hashes_json

$bazel_path run :bazel-diff -- -sh $starting_hashes_json -fh $final_hashes_json -w $workspace_path -b $bazel_path -o $impacted_targets_path

$bazel_path run :bazel-diff -- impacted-tests -w $workspace_path -b $bazel_path $impacted_targets_path $impacted_test_targets_path

IFS=$'\n' read -d '' -r -a impacted_targets < $impacted_targets_path
if [ ${impacted_targets[0]} == "//src/main/java/com/integration:StringGenerator.java" ]
then
    echo "Correct first impacted target"
else
    echo "Incorrect first impacted target: ${impacted_targets[0]}"
    exit 1
fi

if [ ${impacted_targets[1]} == "//test/java/com/integration:bazel-diff-integration-test-lib" ]
then
    echo "Correct second impacted target"
else
    echo "Incorrect second impacted target: ${impacted_targets[1]}"
    exit 1
fi

IFS=$'\n' read -d '' -r -a impacted_test_targets < $impacted_test_targets_path

if [ ${impacted_test_targets[0]} == "//test/java/com/integration:bazel-diff-integration-tests" ]
then
    echo "Correct first impacted test target"
else
    echo "Incorrect first impacted test target: ${impacted_test_targets[0]}"
    exit 1
fi
