## Weather Clock

---

This app renders the time and current weather for your location.

The weather is obtained from

  https://openweathermap.org  

In order to use the weather information, you need to first request and obtain a Free API key.  The key is obtained from

   https://openweathermap.org/price

The Free API key provides 60 calls/minute (1,000,000 calls/month).  As an example, performing a call every second equates to 86,400 calls per day. This equates to 1,000,000 calls in about 11.5 days.  For this reason caching is used for the weather to make a new call once per minute.  This equates to only 44,640 calls in 31 days.  The uptime of this API is 95%.  There will not be any weather data without the API key.


  <img width="640" alt="image" src="https://user-images.githubusercontent.com/25423905/236636564-91e1080c-0dc1-456d-8100-be914309e480.gif">


The layout of the Tidbyt screen is the current time (**12:37 PM**), an icon to represent the current weather conditions, the current temperature and feels like temperature (**68 * 67**), and the current humidity (**44%**).


The schema consists of the following data:
<table>
  <tr>
    <td> Enter API Key</td>
    <td>  <img width="300" alt="image" src="https://user-images.githubusercontent.com/25423905/236008230-1365b33b-8d15-4ecc-b26e-3278aac23035.png"> </td>
  </tr>
  <tr>
    <td> Location data </td>
    <td> <img width="300" alt="image" src="https://user-images.githubusercontent.com/25423905/236045103-abd1455f-2f0f-4c0e-a73a-bedf9e2ec982.png"> </td>
  </tr>
  <tr>
    <td> Night mode if you do not <br>want to use Tidbyt's night mode </td>
    <td> <img width="300" alt="image" src="https://user-images.githubusercontent.com/25423905/236059087-139e8969-a576-40b1-99cc-bcc482cdbc09.png">
</td>
  </tr>  
   <tr>
    <td> If you turn on night mode,<br>enter start and end times.<br><br>Use times between 0000 and 2359</td>
    <td> <img width="300" alt="image" src="https://user-images.githubusercontent.com/25423905/236046686-ced2a02a-06d6-4560-ba6a-b2103646268e.png"></td>
  </tr>   
</table>
 
The weather condition icons are 16 x 16 pixels so they are best viewed on the Tidbyt from a distance to permit the eyes to blend the dots of the images.  The icons for the various weather conditions is shown in the following table:
<table>
  <tr>
    <td><b><span style="color:purple">Weather Conditions</span></b></td>
    <td><b><span style="color:orange">Day</span></b></td>
    <td><b><span style="color:blue">Night</span></b></td>
  </tr>
  </tr>
  </tr>
    <td> No weather data</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066331-9ebb7a15-2b9d-41b1-a3bf-999bf5a19918.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066341-ce7d2400-94bb-4643-93d7-28c3dafc2f2b.png"> </td>
  </tr>
  <tr>
    <td> Clear </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236005427-a087c1e4-2ef9-439a-a7d3-1087e73643f9.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236006626-e194dfa3-cb50-4e97-a702-71851b227c71.png"> </td>
  </tr>
    <td> Few clouds</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236061706-c2a853be-564a-402e-8f0c-6bf73655050a.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236638749-e136d68b-5f15-40f0-ab6e-918c344955a4.png">
 </td>
  </tr>
  </tr>
    <td> Scattered clouds</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236061771-f40d7c1d-04cd-4830-b4f0-bad7c8d3a277.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236680320-fe0f7485-23eb-4beb-8ae5-abb1429ff09f.png"> </td>
  </tr>
  </tr>
    <td> Broken clouds</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236061819-a70f7964-5996-4e94-ac58-82da8bf92ac5.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236680409-a87fe18b-894f-43de-827b-63faeaf918a8.png"> </td>
  </tr>
  </tr>
    <td> Overcast clouds</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236061864-c66fc4d6-83e4-41ef-8c01-bf955be6b41e.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236061885-6414e68f-1fdf-4135-95e8-13e4c23428ff.png"> </td>
  </tr>
   </tr>
    <td> Thunderstorm</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236064915-df4f7813-0674-41ae-a97e-83f29f3c7fe7.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236064943-af0d9858-bdd5-4ea7-a754-c1fd5fced3df.png"> </td>
  </tr>
  </tr>
    <td> Mist<br>Drizzle<br>Light rain<br> Heavy intensity rain<br>Very heavy rain<br>Extreme rain</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236064655-2b8cc920-8d31-4b0f-806b-413f2433cfcd.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236064707-95bd1eec-a0f8-4ab8-9652-c6b6d6dc4e19.png"> </td>
  </tr>
  </tr>
    <td> Freezing rain</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236065251-53d8e7fe-05a5-4cc3-b803-5e9fadad1fb0.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236065269-33d2f7be-1b31-4895-b8ed-e380be62afd0.png"> </td>
  </tr>
  </tr>
    <td> Ligh intensity shower rain<br>Shower rain<br>Heavy intensity shower rain<br>Ragged shower rain</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236065328-ce7fb0ed-d19c-4076-a605-18daffa82bb5.png"></td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236065364-3a92068f-c6ab-4720-bce7-cfc41fd76295.png"> </td>
  </tr>
  </tr>
    <td> Ligh snow<br>Snow<br>Heavy snow</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236065692-435036a7-438b-4360-b258-e4a72b73ca1c.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236065722-7a74f568-de43-43d7-9f4a-474f99c36fc1.png"> </td>
  </tr>
  </tr>
    <td> Sleet<br>Light shower sleet<br>Light rain and snow<br> Rain and Snow</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236065849-84185a40-b4c1-4c64-93b2-4b149555f689.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236065885-15e30548-e304-4ca8-8e78-91909c757a12.png"> </td>
  </tr>
  </tr>
    <td> Smoke</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236065990-7a4cc217-2517-4c35-87a1-d890fc61797c.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066018-d76610b3-614a-4a16-bd91-483ae586f248.png"> </td>
  </tr>
  </tr>
    <td> Haze</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066381-d08f3b72-2c8d-41e5-ab53-d996249a6ebb.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066364-85a0c64c-e624-4310-9990-b688843eea56.png"> </td>
  </tr>
  </tr>
    <td> Sand/dust whirls<br>Sand<br>Dust<br>Volcanic ash</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066521-ed384cb4-0cbd-4940-9d65-cf3a9bbd9d2f.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066538-a110d760-f374-4636-b963-5470101000a6.png"> </td>
  </tr>
  </tr>
    <td> Fog</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066571-4cc3bd79-6890-4c6a-86f0-c355faf01fa4.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066645-30e5747d-6ef2-4a97-a477-b655db0b15b3.png"> </td>
  </tr>
  </tr>
    <td> Squalls</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066698-efa8260b-659a-4dca-97a9-8343e7537202.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066725-01cbd6df-37e4-4080-9d95-9b7ec0c10c24.png"> </td>
  </tr>
  </tr>
    <td> Tornado</td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066749-f3f76b28-3676-47f6-85b0-da199f37dbc6.png"> </td>
    <td> <img width="150" alt="image" src="https://user-images.githubusercontent.com/25423905/236066761-a69d3441-b9e4-4a08-94d7-831a613468be.png"> </td>
  </tr>
</table>
