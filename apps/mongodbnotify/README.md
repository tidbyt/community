# mongodb-notify
Tidbyt MongoDB integration for notifications.

# Goal
The goal of mongodb-notify was to add the ability to have Home Assistant notifications displayed on a Tidbyt. The original problem is that you can't query Home Assistant for current, unacknowledge notifications. You can, however, send a notification via REST and that's where MongoDB's Atlas (M0 - free cluster) and this app come into play.

Note that this is just one example of how you could use this Tidbyt app as it's generic. The notifications can be populated by anything and this app will pick them up and display them.

# Setup
## MongoDB Atlas
In Atlas you'll need to sign up for an account and create an Atlas Project and then, inside the Atlas Project create an M0 cluster. The M0 cluster is free.

You'll also need to create a user ID and password through the Atlas interface so that you can use mongosh to connect to your cluster.

Once the cluster is built, click on the "Connect" button in Atlas and it will walk you through how to download mongosh and connect to your cluster from the command line.

Once connected, you'll want to create a database ("tidbyt", below) and a time-to-live (TTL) index on a collection (the collection will be created implicitly and is named 'notify', below) which expires documents after 0 seconds:
`use tidbyt`
`db.notify.createIndex({expire: 1}, { expireAfterSeconds: 0 })`

You can test the expiration by changing the date-time below to 10 minutes into the future (UTC):
`db.notify.insertOne(
  {
    title: { content: 'OK', color: '#00FFFF' },
    message: { content: 'Everything is OK', color: '#AAAAAA' },
    expire: ISODate('2024-05-20T06:11:56.883Z')
  }
)`

After 10 minutes the TTL index should delete the document.

## Data API
In the Atlas UI, click on the "Data API" menu item on the left side of the screen. Follow the instructions on setting up a URL Endpoint and API Key. Write both of those down and you will use them to configure the mongodb-notify Tidbyt app.

## mongodb-notify
At this point you can configure the mongodb-notify Tidbyt app on your phone. The parameters you'll need:
* Data API URL - from the step above
* API Key - this is the generated key from when you created the API key above.
* datasource - this is whatever name you gave your cluster when you created it
* database - this is the name of the database inside your cluster ("tidbyt" - if you used the examples above)
* collection - this is the name of the collection inside the database from which documents will be read ("notify" - if you used the examples above)

Any errors you get will be displayed on the Tidbyt. If everything is working it won't display anything until there is a notification to display.

Try inserting the notification, again, setting the expire to 10 minutes from now (UTC):
`db.notify.insertOne(
  {
    title: { content: 'OK', color: '#00FFFF' },
    message: { content: 'Everything is OK', color: '#AAAAAA' },
    expire: ISODate('2024-05-20T06:11:56.883Z')
  }
)`

This notification should show up on your Tidbyt.

## Document format:
When inserting a document, the format is:
`{ 
  "title": { 
    "content": "{{ title }}", 
    "color": "{{ title_color }}"
  },
  "message": {
    "content": "{{ message }}",
    "color": "{{ message_color }}",
    "create_ts": { "$date": { "$numberLong": "{{ (as_timestamp(utcnow()) | int * 1000) }}" }    },
    "expire": { "$date": { "$numberLong": "{{ (as_timestamp(utcnow()) | int * 1000) + (mins * 60 * 1000) }}" } }
  }
}`

The color is in the form of:
[Widgets!](https://tidbyt.dev/docs/reference/widgets)
> A quick note about colors. When specifying colors, use a CSS-like hexdecimal color specification. Pixlet supports #rgb, #rrggbb, #rgba, and #rrggbbaa color specifications.

Defaults:
* title_color: #00FFFF
* message_color: #AAAAAA

# Home Assistant
## Setup
### configuration.yaml
Add:

`rest_command:
  mongodb_notify_insert:
    url: <data-api-url-from-atlas>/action/insertOne
    content_type: 'application/json'
    verify_ssl: true
    method: 'post'
    timeout: 20
    headers:
      Access-Control-Request-Headers: "*"
      api-key: <your-api-key-from-atlas>
    payload: >
      {
        "dataSource": "personal",
        "database": "tidbyt",
        "collection": "notify",
        "document":  { 
          "title": { 
            "content": "{{ title }}", 
            "color": "{{ title_color }}"
          },
          "message": {
            "content": "{{ message }}",
            "color": "{{ message_color }}",
            "create_ts": { "$date": { "$numberLong": "{{ (as_timestamp(utcnow()) | int * 1000) }}" } },
            "expire": { "$date": { "$numberLong": "{{ (as_timestamp(utcnow()) | int * 1000) + (mins * 60 * 1000) }}" } }
          }
        }
      }`

Call it via:

`service: rest_command.mongodb_notify_insert
data: {
  title: <title>,
  title_color: "#FF0000",
  message: <message>,
  message_color: "#FFFF00",
  mins: <expire>
}`

Note: `mins` is how many minutes into the future that the this notification will expire.

# Notes

- When you first start it there won't be any notifications so you won't see anything.
- Config is case-sensitive. If you have a database named "homeassistant" and then you type "Homeassistant" into the config then it won't error out but it also won't be looking in your "homeassistant" database for your notifications.
- The app is designed to give you error messages through the Tidbyt itself. If you're missing config settings or get a an error back from it trying to connect to the database then you'll see those errors on the Tidbyt.
