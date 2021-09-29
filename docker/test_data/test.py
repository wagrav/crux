import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

options = Options()
options.add_argument('--headless')
options.add_argument('--disable-gpu')
driver = webdriver.Chrome('/usr/bin/chromedriver',chrome_options=options)  # Optional argument, if not specified will search path.
driver.get('http://www.google.com/');
time.sleep(1) # Let the user actually see something!
driver.quit()