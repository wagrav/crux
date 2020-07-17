#!/usr/bin/env bash

readThresholds(){
  local thresholdsFile="$1"
  local statisticsFile="$2"
  local testResultsDir="$3"
  local templatesDir="$4"
  while IFS=: read -r f1 f2 f3 || [[ -n "$f1" ]]; do #to include last line for non POSIX files
     if [[ ! "$f1" =~ \#.* ]];then #skip comments
        local sampler=$f1
        local metric=$f2
        local threshold_max=$f3
        echo " -- Evaluating condition for sampler: $sampler, metric: $metric, threshold: $threshold_max"
        local samplerEscaped=$(echo "$sampler" | sed 's/\//_/g') # chnage / to _
        local testName="Metric $metric should not breach threshold for sampler $samplerEscaped"
        if [ "$sampler" == "ANY" ];then #ANY is a special keyword
          res=$(getHighestValueForAnyMetric "$statisticsFile" "$metric")
        else
          res=$(getMetricForSampler "$statisticsFile" "$sampler" "$metric")
        fi
        local stackTrace=" Condition : $sampler, metric actual value: $res, max threshold: $threshold_max"
        cond=$(awk 'BEGIN {print ('$threshold_max' >= '$res')}')
        if [ "$cond" == "1" ] ;then #use awk for floating point comparisons
          echo " -- --> Test for $sampler has passed with metric value: $res"
          copyTestTemplate "PASS" "$testResultsDir" "$templatesDir" "Threshold has not been breached" "$stackTrace" "$testName"
        else
          echo " -- --> Test for $sampler has failed with metric value: $res"
          copyTestTemplate "FAILED" "$testResultsDir" "$templatesDir" "Threshold has been breached" "$stackTrace" "$testName"
        fi
      fi
  done <"$thresholdsFile"
}

getMetricForSampler(){
  local statisticsFile=$1
  local samplerName=$2
  local metric=$3
  getSampleResultsJSON "$statisticsFile" "$samplerName" | jq ".$metric"
}

getSampleResultsJSON(){
  local statisticsFile=$1
  local sampleName=$2
  cat "$statisticsFile" | jq ".[\"$sampleName\"]"
}
getErrorCount(){
  local statisticsFile=$1
  getHighestValueForAnyMetric "$statisticsFile" errorCount
}
getHighestValueForAnyMetric(){
    local statisticsFile=$1
    local metric=$2
    getAnyMetric "$statisticsFile" $metric | uniq | sort -nr | head -n1
}
getAnyMetric(){
  local statisticsFile=$1
  local metric=$2
  cat "$statisticsFile" | jq ".[].\"$metric"\"
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
  local name="$6"
  name=$(echo "$name" | sed 's/ /_/g')
  name="$type"_"$name"
  mkdir -p "$resDir"
  cp "$templateDir/$type"_template.xml "$resDir/$name"_TEST.xml
  sed -i "s+@message+$(echo $message)+g" "$resDir/$name"_TEST.xml
  sed -i "s+@stacktrace+$(echo $stackTrace)+g" "$resDir/$name"_TEST.xml
  sed -i "s+@name+$(echo $name)+g" "$resDir/$name"_TEST.xml
}
checkForErrors(){
  local statisticsFile=$1
  local testResultsDir=$2
  local templatesDir=$3
  local testName="Should pass without errors"
  if [ -f "$statisticsFile" ]; then
    errors=$(getErrorCount $statisticsFile)
    if [ "$errors" != "0" ];then
      echo "Test ended with errors"
      stackTrace=$(getErrorStackTrace $statisticsFile)
      copyTestTemplate "FAILED" "$testResultsDir" "$templatesDir" "There are multiple errors in tests" "$stackTrace" "$testName"
    else
      echo "Test ended without errors"
      copyTestTemplate "PASS" "results" "templates" "There are no errors in tests" "no errors" "$testName"
    fi
  else
    echo "$statisticsFile does not exist"
    copyTestTemplate "SKIP" "results" "templates" "Tests have not been run or statistics.json does not exist" "skipped" "$testName"
  fi

}
run_main(){
  local statisticsFile=$1
  local testResultsDir=$2
  local templatesDir=$3
  local thresholdsFile=$4
  checkForErrors $statisticsFile $testResultsDir $templatesDir
  readThresholds "$statisticsFile" "$thresholdsFile" $testResultsDir $templatesDir

}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_main "$1" "$2" "$3" "$4"
fi