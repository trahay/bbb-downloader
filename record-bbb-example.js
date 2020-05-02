var webdriver = require('selenium-webdriver'),
    By = webdriver.By,
    until = webdriver.until;

var driver = new webdriver.Builder()
/*    .forBrowser('chrome') */
    .forBrowser('firefox')
    .usingServer('http://localhost:4444/wd/hub')
    .build();

driver.get('https://webconf.imtbs-tsp.eu/playback/presentation/2.0/playback.html?meetingId=522d1d51bee82a57b535ced7091addeecb074d47-1588254659509');

driver.sleep(1000 * 5);
driver.manage().window().maximize();

/* Cannot put it in full-screen with F11 in marionette mode */
/*driver.sleep(1000 * 5);*/
/*driver.findElement(By.tagName("body")).sendKeys(webdriver.Key.F11);*/

/* Start playback */
driver.sleep(1000 * 5);
driver.findElement(By.className('acorn-play-button')).click();

/* Stop after a minute */
driver.sleep(1000 * 60);
driver.quit();
