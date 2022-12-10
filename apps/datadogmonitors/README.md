# DataDog Monitors for Tidbyt

Displays any triggered monitors connected to your DataDog account. A valid DataDog API Key and Application Key are required. By default this app uses the query string `status:alert` but you are able to override this to whatever query DataDog supports. Currently the app will query DataDog every 5 minutes. See [DataDog Monitor API reference.](https://docs.datadoghq.com/api/latest/monitors/#monitors-search).

![DataDog Monitors for Tidbyt - Success Example](screenshot.png)
![DataDog Monitors for Tidbyt - Error Example](screenshot_errors.png)
![DataDog Monitors for Tidbyt - Auth Example](screenshot_auth.png)
