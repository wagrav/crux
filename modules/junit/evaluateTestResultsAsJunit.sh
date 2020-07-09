#!/usr/bin/env bash

getSampleResultsJSON(){
  local statisticsFile=$1
  local sampleName=$2
  cat "$statisticsFile" | jq ".[\"$sampleName\"]"
}
getErrorCount(){
  local statisticsFile=$1
  cat "$statisticsFile" | jq '.[].errorCount' | uniq | sort -nr | head -n1
}
getErrorStackTrace(){
  local statisticsFile=$1
  cat "$statisticsFile" | jq '.[] | select (.errorCount > 0) | [{SamplerName:.transaction,errorCount,percentile_99_milis:.pct3ResTime}]'
}
copyTestTemplate(){
  local type="$1"
  local resDir="$2"
  local templateDir="$3"
  local message="$4"
  local stackTrace="$5"
  cp "$templateDir/$type"_template.xml "$resDir/$type"_TEST.xml
  sed -i "s+@message+$(echo $message)+g" "$resDir/$type"_TEST.xml
  sed -i "s+@stacktrace+$(echo $stackTrace)+g" "$resDir/$type"_TEST.xml
}
checkForErrors(){
  local statisticsFile=$1
  local testResultsDir=$2
  local templatesDir=$3
  if [ -f "$statisticsFile" ]; then
    errors=$(getErrorCount $statisticsFile)
    if [ "$errors" != "0" ];then
      echo "Test ended with errors"
      stackTrace=$(getErrorStackTrace $statisticsFile)
      copyTestTemplate "FAILED" "$testResultsDir" "$templatesDir" "There are multiple errors in tests" "$stackTrace"
    else
      echo "Test ended without errors"
      copyTestTemplate "PASS" "results" "templates" "There are no errors in tests"
    fi
  else
    echo "$statisticsFile does not exist"
    copyTestTemplate "SKIP" "results" "templates" "Tests have not been run or statistics.json does not exist"
  fi

}
run_main(){
  local statisticsFile=$1
  local testResultsDir=$2
  local templatesDir=$3
  checkForErrors $statisticsFile $testResultsDir $templatesDir

}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_main "$1" "$2" "$3"
fi