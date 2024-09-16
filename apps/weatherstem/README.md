# WeatherSTEM

---

This app renders the current weather conditions from any WeatherSTEM weather station. It is not associated with or supported by WeatherSTEM.

This app uses https://api.weatherstem.com/api which is free to use with registration. Visit https://www.weatherstem.com/register to register and recieve your free API Key which will need to be entered into the settings.

## Settings

<dl>
<dt>API Key</dt>
<dd>Required - API key used to authenticate requests to WeatherSTEM. [Register](https://www.weatherstem.com/register) for free to generate your api key.</dd>
<dt>Station Id</dt>
<dd>Required - Unique identifier of the WeatherSTEM station to use as a data source. A station Id can be determined from its web address, for example, a station of https://leon.weatherstem.com/fsu has an ID of fsu@leon.weatherstem.com.</dd>
<dt>Temperature Type</dt>
<dd>Optional - Whether to display temperature in F or C. Defaults to F if not set.</dd>
<dt>Station Name</dt>
<dd>Optional - Customize name of station to display at top of screen. If not set the name returned by the api is used.</dd>
</dl>


