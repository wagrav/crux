//This script takes the one developed in Intellij where we mock WDS as in jmeter
//Removes mocked set-up and imports that are unnecessary for jmeter and produces ready copy-paste solution for jmeter
//after that one can test it in jmeter

final String devFilePath = "wds.groovy"
final String jmeterWDSFilePath = "../resources/wds_jmeter.groovy"
final String dockerWDSFilePath = "../resources/wds_docker.groovy"
final TOKEN_REMOVE = "TOKEN_REMOVE"
final TOKEN_REMOVE_BLOCK_START = "TOKEN_REMOVE_BLOCK_START"
final TOKEN_REMOVE_BLOCK_END = "TOKEN_REMOVE_BLOCK_END"

def file = new File(devFilePath)
//Generate JMeter version
//remove lines marked with a token
List wdsFileContentsLines = file.readLines().findAll() {
    line -> !line.endsWith(TOKEN_REMOVE)
}
//Find blocke to remove
int removeStartIndex = wdsFileContentsLines.findIndexOf {
    line -> line.endsWith(TOKEN_REMOVE_BLOCK_START)
}
int removeEndIndex = wdsFileContentsLines.findIndexOf {
    line -> line.endsWith(TOKEN_REMOVE_BLOCK_END)
}

//check block is ok
assert removeStartIndex: "Cannot Find " + TOKEN_REMOVE_BLOCK_START
assert removeEndIndex: "Cannot Find " + TOKEN_REMOVE_BLOCK_END
assert removeStartIndex < removeEndIndex: "BLOCK REMOVE TOKENS ORDER MISMATCH"
println("LINES TO CUT: <${removeStartIndex}:${removeEndIndex}>")

//remove block
try {
    wdsFileContents = (wdsFileContentsLines.subList(0, removeStartIndex) +
            wdsFileContentsLines.subList(removeEndIndex + 1, wdsFileContentsLines.size())).join("\n")
}catch(Exception e){
    println("Block removal not done or not exists in the script")
}
//save new file
new File(jmeterWDSFilePath).text = wdsFileContents

//Generate windows docker version for headless chrome and application as local service
def text = new File(devFilePath).text
        .replace("../resources/chromedriver.exe","/usr/bin/chromedriver")
        .replace("'--verbose'","'--headless','--verbose'")
        .replace("localhost","host.docker.internal" +
                "")
new File(dockerWDSFilePath).text = text