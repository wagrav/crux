#on windows
#local
C:\Users\gstarczewski\tools\apache-jmeter-5.2.1\bin\jmeter.bat -DjmeterPlugin.sts.loadAndRunOnStartup=true -DjmeterPlugin.sts.port=9191 -DjmeterPlugin.sts.datasetDirectory=C:\Users\gstarczewski\repos\performance\IBR\test_data -n -t C:\Users\gstarczewski\repos\performance\IBR\ibr.jmx
#remote  - with one server running on localhost too
C:\Users\gstarczewski\tools\apache-jmeter-5.2.1\bin\jmeter.bat -f -Gsts=localhost -l a.csv -e -o report -Rlocalhost -DjmeterPlugin.sts.loadAndRunOnStartup=true -DjmeterPlugin.sts.port=9191 -DjmeterPlugin.sts.datasetDirectory=C:\Users\gstarczewski\repos\performance\IBR\test_data -n -t C:\Users\gstarczewski\repos\performance\IBR\ibr.jmx

#testing on remote both sts and chrome headless

C:\Users\gstarczewski\tools\apache-jmeter-5.2.1\bin\jmeter.bat -f -Gsts=localhost -l a.csv -e -o report -Rlocalhost -DjmeterPlugin.sts.loadAndRunOnStartup=true -DjmeterPlugin.sts.port=9191 -DjmeterPlugin.sts.datasetDirectory=C:\Users\gstarczewski\repos\performance\IBR\test_data -n -t C:\Users\gstarczewski\repos\performance\IBR\ibr.jmx