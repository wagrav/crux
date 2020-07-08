import groovy.transform.Canonical
import org.openqa.selenium.By
import org.openqa.selenium.JavascriptExecutor
@Grab(group = 'org.seleniumhq.selenium', module = 'selenium-support', version = '3.7.1')//TOKEN_REMOVE
@Grab(group = "org.seleniumhq.selenium", module = "selenium-java", version = "3.7.1")//TOKEN_REMOVE
@Grab(group = 'org.apache.commons', module = 'commons-lang3', version = '3.9')//TOKEN_REMOVE

import org.openqa.selenium.WebDriver
import org.openqa.selenium.WebElement
import org.openqa.selenium.chrome.ChromeDriver
import org.openqa.selenium.chrome.ChromeOptions
import org.openqa.selenium.support.ui.ExpectedConditions
import org.openqa.selenium.support.ui.WebDriverWait

//TOKEN_REMOVE

//TOKEN_REMOVE_BLOCK_START
//START MOCK
class SampleResult {
    public void sampleStart() {}

    public void sampleEnd() {}
}

@Canonical
class WDSampler {
    public args;
    public SampleResult sampleResult;
    public WebDriver browser
    final static String CHROME_DRIVER_PATH = '/usr/bin/chromedriver'
    final static String WEBDRIVER_CHROME_PROPERTY = "webdriver.chrome.driver"
    def chromeDriverSelectedOptions = ['--headless','--verbose', '--ignore-certificate-errors']

    WDSampler() {
        args = ["user", "pass","somedata","https://google.es","data"]
        sampleResult = new SampleResult();
        System.setProperty(WEBDRIVER_CHROME_PROPERTY, CHROME_DRIVER_PATH);
        browser = new ChromeDriver(setOptions())
    }

    private setOptions() {
        ChromeOptions chromeOptions = new ChromeOptions()
        chromeDriverSelectedOptions.each {
            option -> chromeOptions.addArguments(option);
        }

        chromeOptions
    }
}

WDSampler WDS = new WDSampler();
//End MOCK Jmeter dependencies TOKEN_REMOVE
//COPY PASTE HERE DOWN to WDS SAMPLER or by automated script TOKEN_REMOVE
//TOKEN_REMOVE_BLOCK_END


final String username = WDS.args[0]
final String password = WDS.args[1]
final String project = WDS.args[2]
final String url = WDS.args[3]
final String scenario = WDS.args[4]

class Config {
    static final int TIMEOUT_S = 30;//s
    static final int SLEEP_TIME_MS = 1500;//ms
}

class Page {
    protected WebDriver driver
    protected String URL
    protected WebDriverWait wait
    private static final LOGOUT_BUTTON_XPATH = "//a[text()='Log Out']"

    def Page(WebDriver driver, String URL) {
        this.driver = driver
        this.URL = URL
        this.wait = new WebDriverWait(this.driver, Config.TIMEOUT_S);
    }

    def get() {
        driver.get(URL)
    }

    def enterInputText(String inputText, By selector) {
        driver.findElement(selector).sendKeys(inputText);
    }

    def submitButton(By selector) {
        driver.findElement(selector).submit();
    }

    def clickElementBy(By selector) {
        driver.findElement(selector).click();
    }

    def waitForVisibilityOfElementBy(By selector, int timeout = Config.TIMEOUT_S) {
        WebDriverWait wait = new WebDriverWait(driver, timeout);
        wait.until(ExpectedConditions.visibilityOfElementLocated(selector));
    }

    def waitForClickabilityOfElementBy(By selector, int timeout = Config.TIMEOUT_S) {
        WebDriverWait wait = new WebDriverWait(driver, timeout);
        wait.until(ExpectedConditions.elementToBeClickable(selector));
    }

    def waitForInvisibilityOfElementBy(By selector, int timeout = Config.TIMEOUT_S) {
        WebDriverWait wait = new WebDriverWait(driver, timeout);
        wait.until(ExpectedConditions.invisibilityOfElementLocated(selector));
    }
    def scrollIntoView(By selector){
        WebElement element = driver.findElement(selector);
        ((JavascriptExecutor) driver).executeScript("arguments[0].scrollIntoView(true);", element);
    }
    Page think(def sleepTime = Config.SLEEP_TIME_MS) {
        sleep(sleepTime)
        this
    }

    Page logout() {
        waitForClickabilityOfElementBy(By.xpath(LOGOUT_BUTTON_XPATH))
        clickElementBy(By.xpath(LOGOUT_BUTTON_XPATH));
    }
}

class IndexPage extends Page {
    private static final String URL = "https://google.com"
    private static final String FIRST_CHILD_CSS = "span.mx-text.mx-name-text1.card-header-description.text-large.cardproduct-overlay-title"

    def IndexPage(def driver) {
        super(driver, URL)
    }

    @Override
    def get() {
        driver.get(URL)
        this
    }

    def openFirstChildProfile() {
        waitForVisibilityOfElementBy(By.cssSelector(FIRST_CHILD_CSS))
        clickElementBy(By.cssSelector(FIRST_CHILD_CSS))
        this
    }
    //only necessary due to intellij highlights ...
    @Override
    IndexPage think() {
        super.think()
    }

}

def indexPage = new IndexPage(WDS.browser)

//actual flow
WDS.sampleResult.sampleStart();
indexPage.get().think();
WDS.sampleResult.sampleEnd();
