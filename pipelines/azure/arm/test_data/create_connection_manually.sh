org=gstarczewski
project=jmeter
user=gstarczewski
pat=
path=.
#curl --user $user:$pat -X POST -H "Content-Type: application/json" --data-binary  @../bin/payload.json https://dev.azure.com/$org/$project/_apis/serviceendpoint/endpoints?api-version=5.0-preview.2
bash ../create_service_connection.sh gstarczewski jmeter gstarczewski $pat k112 perf_qinlkwwubxksw mygroup