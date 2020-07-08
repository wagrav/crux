 #confirm container has headless chrome
 #RUN on windows in powershell
 docker run -v C:\Users\gstarczewski\repos\performance\IBR\docker\test_data:/test --shm-size=2g --rm -it gabrielstar/jmeter-master python /test/test.py
 #get inside the container
 docker run --shm-size=2g --rm -it gabrielstar/jmeter-master bash
 #then run jmeter tests with selenium and webdriver subsamples
 jmeter -Jwebdriver.sampleresult_class=com.googlecode.jmeter.plugins.webdriver.sampler.SampleResultWithSubs -n -l result.csv -t selenium_test_chrome_headless.jmx

