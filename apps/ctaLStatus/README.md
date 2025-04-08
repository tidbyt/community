# CTA 'L' Status

Display the status of the CTA 'L' along with any travel alerts

## Feeds

- [CTA Status API](http://www.transitchicago.com/api/1.0/routes.aspx)
- [CTA Alerts API](https://www.transitchicago.com/api/1.0/alerts.aspx)

## Configuration

|Option|Description|
|------|-----------|
|**Rail Line**|Choose one of the 'L' Lines to display the status of.|
|**Alert Display**|Choose whether to display the headline of the alerts or the full description.|
|**Scroll Speed**|Display how fast the scroll speed is.|
|**Display Active Alerts**|Default is `TRUE`. When `TRUE`, response yields events only where the start time is in the past and the end time is in the future or unknown.|
|**Display Accessibility Alerts**|Default is `FALSE`. If `TRUE`, response includes events that affect accessible paths in stations.|
|**Display Planned Alerts**|Default is `TRUE`. If `FALSE`, response excludes common planned alerts. Otherwise, result does include planned alerts.|
|**Display Recent Alerts**|Default is `TRUE`. When `TRUE`, response excludes alerts that started more than seven days ago.|
