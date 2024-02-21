# Telegram

## Overview

This app uses the [Telegram BOT API](https://core.telegram.org/bots/api) to show the number of members of a given group/chat.

The app user needs to add the `@tidbytbot` bot to their group. The bot will send a message to the group with the value of the `Chat ID` that needs to be provided in the app configuration (Schema).

Note: the bot has **no access** to the messages exchanged in the group, but it needs to be a member of the group or else the Telegram API will not allow us to get the current member count.

This is what the app displays:

![app](telegram.webp)

---

## API Details

We currently use the [getChatMemberCount](https://core.telegram.org/bots/api#getchatmembercount) endpoint. As long as the bot remains a member of the group, the API will successfully return a response like this:

```json
{
  "ok": true,
  "result": 3456
}
```

### Authentication

Telegram API calls are authenticated by a _bot token_ that is passed as part of the URL.

The production bot token is stored in the app and secured with the `secret` module.

_Note: to run the code locally you will need to [create your own bot](https://core.telegram.org/bots#how-do-i-create-a-bot) and provide its token in the `DEV_BOT_TOKEN` variable._

### Rate Limiting

Most Telegram APIs are not rate limited, the only exception is the `sendMessage` API which is not used by this app.

Anyway, the app caches the responses for 1 hour using the native caching feature of the `http` module.

---

## Configuration (Schema)

The app requires a `Chat ID` to work. There are also options to configure the channel name and if the user wants to use dots (instead of commas) as the thousands separator character.

---

## Error Handling

The app has safeguards in place to identify potential errors and always display something on the screen. For instance, Telegram API errors will be displayed on the screen along with the error code and description, making it easy for app users to reach us and ask for support.

The only situation where the `fail` function is called is if you try to run the app locally without providing an API key in the `DEV_BOT_TOKEN` variable.

---

## Future Improvements

One possible improvement is to add options for the user to customize the colors of the app.

Other than that, there isn't anything relevant that can be done with this app in regards to the Telegram API. There aren't other useful information to display and trying to show things like the user's messages would require frequent calls to the API (let alone the Tidbyt screen being less than ideal for it).

Currently the user needs to supply the name of the group in the app configuration, but we could fetch it with the [getChat](https://core.telegram.org/bots/api#getchat) endpoint. This behavior was not included in the app for performance reasons as it would require an additional http call.
