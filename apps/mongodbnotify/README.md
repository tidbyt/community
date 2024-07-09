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

```
use tidbyt
db.notify.createIndex({expire: 1}, { expireAfterSeconds: 0 })
```

You can test the expiration by changing the date-time below to 10 minutes into the future (UTC) (**expire**, below):

```
db.notify.insertOne(
  {
    topic: 'homeassistant',
    priority: 1,
    entity: 'test',
    create_ts: ISODate('2024-07-09T17:02:42.000Z'),
    expire: new Date(new Date().getTime() + (10 * 60 * 1000)),
    page: {
      Column: {
        children: [
          {
            Box: {
              child: {
                Column: {
                  children: [
                    { Text: { content: 'TEST', color: '' } },
                    {
                      Box: {
                        child: {
                          WrappedText: {
                            content: 'This is a test',
                            color: ''
                          }
                        },
                        width: 62,
                        height: 22,
                        color: '#000000',
                        padding: 1
                      }
                    }
                  ]
                }
              },
              width: 64,
              height: 32,
              color: '#880000'
            }
          }
        ]
      }
    }
  }
)
```

After 10 minutes the TTL index should delete the document.

You can check the the mongosh by searching for it periodically:

```
db.notify.find()
```

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

```
db.notify.insertOne(
  {
    topic: 'homeassistant',
    priority: 1,
    entity: 'test',
    create_ts: ISODate('2024-07-09T17:02:42.000Z'),
    expire: new Date(new Date().getTime() + (10 * 60 * 1000)),
    page: {
      Column: {
        children: [
          {
            Box: {
              child: {
                Column: {
                  children: [
                    { Text: { content: 'TEST', color: '' } },
                    {
                      Box: {
                        child: {
                          WrappedText: {
                            content: 'This is a test',
                            color: ''
                          }
                        },
                        width: 62,
                        height: 22,
                        color: '#000000',
                        padding: 1
                      }
                    }
                  ]
                }
              },
              width: 64,
              height: 32,
              color: '#880000'
            }
          }
        ]
      }
    }
  }
)
```

This notification will show up on your Tidbyt if everything is configured correctly.

## Document format:
When inserting a document, the format is:

```
db.notify.insertOne(
  {
    topic: <string>,
    priority: <integer>,
    entity: <string>,
    create_ts: <date>,
    expire: <date>,
    page: {...}
    }
  }
)
```

| Field     | Description                                                  |
| --------- | ------------------------------------------------------------ |
| topic     | The "topic". You may have multiple items and apps using this. If you're just using this for Home Assistant then just use something simple like, "homeassistant". You can change this in the configuration. |
| priority  | This determines the priority of the message with "1" being the highest priority. |
| entity    | This is the entity that the message is referring to. It can be anything. For example, you may want to use, "refrigerator_door", with a message saying that the refrigerator door has been left open. This allows you to capture the door being closed event and remove the message based upon the topic and entity. (ie. db.notify.deleteMany({topic: "homeassistant", entity: "refrigerator_door"})) |
| create_ts | This is just a timestamp of the creation of the event. Just pass in the current date and time. |
| expire    | (optional) This is the time when the message will expire. If used, the message will expire at this time and be deleted using the TTL index, created above. If unused, the message will persist until you explicitly delete it. |
| page      | This is a set of Tidbyt widgets, in JSON form that will be drawn as part of the message. |



# Tidbyt Widgets in JSON

Tidbyt Widgets: https://tidbyt.dev/docs/reference/widgets

All widgets are coded for but do not use Root, as that is accounted for in the app, and Marquee isn't going to work because of the way the screen is timed. Other than that you should be able to piece together a number of different widgets to give a unique message. The messages will be displayed in the Tidbyt app, one after the other, ordered by priority (ascending) and create_ts (descending).

You MUST specifify each parameter to the widget. For example:

```
{
  Text: "Some text."
}
```

Will NOT work. You'd need to put it in the form of:

```
{
   Text: { content: 'TEST2' }
}
```

A simple example of what you may use for a page:

```
{
  "Column": {
    "children": [
      {
        "Text": {
          "content": "Title",
          "color": "#FF0000"
        }
      },
      {
        "WrappedText": {
          "content": "This is a message",
          "color": "#FFFFFF"
        }
      }
    ]
  }
}
```

Another, more complex, example:

```
{
  Column: {
    children: [
      {
        Box: {
          child: {
            Column: {
              children: [
                { Text: { content: 'TEST2' } },
                {
                  Box: {
                    child: {
                      WrappedText: {
                        content: 'This is the second test'                        
                      }
                    },
                    width: 62,
                    height: 22,
                    color: '#000000',
                    padding: 1
                  }
                }
              ]
            }
          },
          width: 64,
          height: 32,
          color: '#880000'
        }
      }
    ]
  }
}
```



# Home Assistant

## Setup
### configuration.yaml

Adding the code below will get you three services in Home Assistant:

- tidbyt_remove_nofity
- tidbyt_simple_notify
- tidbyt_placard_notify

Ensure that the dataSource, database, and collection for each of the calls below match what you've setup in your database and configuration in the Tidbyt app.

```
rest_command:
  tidbyt_remove_notify:
    url: !secret atlas_data_api_url_deleteMany
    content_type: 'application/json'
    verify_ssl: true
    method: 'post'
    timeout: 20
    headers:
      Access-Control-Request-Headers: "*"
      api-key: !secret atlas_data_api_key
    payload: >
      {
        "dataSource": "personal",
        "database": "tidbyt",
        "collection": "notify",
        "filter": { "topic": "{{ topic if topic is defined and topic != none else 'homeassistant' }}", "entity": "{{ entity if entity is defined and entity != none else 'test' }}" }
      }
  tidbyt_simple_notify:
    url: !secret atlas_data_api_url_insertOne
    content_type: 'application/json'
    verify_ssl: true
    method: 'post'
    timeout: 20
    headers:
      Access-Control-Request-Headers: "*"
      api-key: !secret atlas_data_api_key
    payload: >
      {
        "dataSource": "personal",
        "database": "tidbyt",
        "collection": "notify",
        "document":  {
          "topic": "{{ topic if topic is defined and topic != none else 'homeassistant' }}",
          "priority": {{ priority if priority is defined and priority != none else 1 }},
          "entity": "{{ entity if entity is defined and entity != none else 'test' }}",
          "create_ts": { "$date": { "$numberLong": "{{ as_timestamp(utcnow()) | int * 1000 }}" } },
          {%- if expire_mins is defined and expire_mins != none -%} 
            "expire": { "$date": { "$numberLong": "{{ (as_timestamp(utcnow()) | int * 1000) + ( expire_mins * 60 * 1000) }}"  } },
          {%- endif -%}
          "page": {
            "Column": {
              "children": [
                {
                  "Text": {
                    "content": "{{ title if title is defined and title != none else 'No Title' }}",
                    "color": "{{ title_color if title_color is defined and title_color != none else '#FFFFFF' }}"
                  }
                },
                {
                  "WrappedText": {
                    "content": "{{ message if message is defined and message != none else 'No message' }}",
                    "color": "{{ message_color if message_color is defined and message_color != none else '#CCCCCC' }}"
                  }
                }
              ]
            }
          }
        }
      }
  tidbyt_placard_notify:
    url: !secret atlas_data_api_url_insertOne
    content_type: 'application/json'
    verify_ssl: true
    method: 'post'
    timeout: 20
    headers:
      Access-Control-Request-Headers: "*"
      api-key: !secret atlas_data_api_key
    payload: >
      {
        "dataSource": "personal",
        "database": "tidbyt",
        "collection": "notify",
        "document":  {
          "topic": "{{ topic if topic is defined and topic != none else 'homeassistant' }}",
          "priority": {{ priority if priority is defined and priority != none else 1 }},
          "entity": "{{ entity if entity is defined and entity != none else 'test' }}",
          "create_ts": { "$date": { "$numberLong": "{{ as_timestamp(utcnow()) | int * 1000 }}" } },
          {%- if expire_mins is defined and expire_mins != none -%} 
            "expire": { "$date": { "$numberLong": "{{ (as_timestamp(utcnow()) | int * 1000) + ( expire_mins * 60 * 1000) }}"  } },
          {%- endif -%}
          "page": {
            "Column": {
              "children": [
                {
                  "Box": {
                    "child": {
                      "Column": {
                        "children": [
                          {
                            "Text": {
                              "content": "{{ title if title is defined and title != none else 'No Title' }}",
                              "color": "{{ title_color if title_color is defined and title_color != none else '#FFFFFF' }}"
                            }
                          },
                          {
                            "Box": {
                              "child": {
                                "WrappedText": {
                                  "content": "{{ message if message is defined and message != none else 'No message' }}",
                                  "color": "{{ message_color if message_color is defined and message_color != none else '#CCCCCC' }}"
                                }
                            },
                              "width": 62,
                              "height": 22,
                              "color": "{{ inner_color if inner_color is defined and inner_color != none else '#000000' }}",
                              "padding": 1
                            }
                          }
                        ]
                      }
                    },
                    "width": 64,
                    "height": 32,
                    "color": "{{ placard_color if placard_color is defined and placard_color != none else '#880000' }}"
                  }
                }
              ]
            }
          }
        }
      }

```

The following needs to be stored in secrets.yaml and they, too, should match your configuration in the Tidbyt app:

```
atlas_data_api_url_deleteMany: <atlas_data_api_url>/action/deleteMany
atlas_data_api_url_insertOne: <atlas_data_api_url>/action/insertOne
atlas_data_api_key: <atlas_data_api_key>
```

You can test it in Developer -> Services:

```
service: rest_command.tidbyt_simple_notify
data: 
  entity: test
  title: Simple
  message: You have been simply notified
```



```
service: rest_command.tidbyt_placard_notify
data: 
  entity: test
  title: Placard
  message: You have been placard
```

```
service: rest_command.tidbyt_remove_notify
data: 
  entity: test
```

| tidbyt_remove_notify parameters |                                                              |
| ------------------------------- | ------------------------------------------------------------ |
| topic                           | Defaults to "homeassistant"                                  |
| entity                          | Defaults to "test". Use this to identify which entity you're trying to remove the message for. |

| tidbyt_simple_notify parameters |                                               |
| ------------------------------- | --------------------------------------------- |
| title                           | The title.                                    |
| Title_color                     | The color of the title. Defaults to #FFFFFF.  |
| message                         | The message.                                  |
| Message_color                   | The color of the message. Defaults to #CCCCCC |

| tidbyt_placard_notify parameters |                                                         |
| -------------------------------- | ------------------------------------------------------- |
| title                            | The title.                                              |
| title_color                      | The color of the title. Defaults to #FFFFFF.            |
| message                          | The message.                                            |
| message_color                    | The color of the message. Defaults to #CCCCCC           |
| placard_color                    | The color of the placard. Defaults to #AA0000           |
| inner_color                      | The color of the inner message box. Defaults to #000000 |

# Notes

- When you first start it there won't be any notifications so you won't see anything.
- Config is case-sensitive. If you have a database named "homeassistant" and then you type "Homeassistant" into the config then it won't error out but it also won't be looking in your "homeassistant" database for your notifications.
- The app is designed to give you error messages through the Tidbyt itself. If you're missing config settings or get a an error back from it trying to connect to the database then you'll see those errors on the Tidbyt.
