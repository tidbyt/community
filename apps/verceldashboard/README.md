# Vercel Dashboard

![Vercel Dashboard](screenshot.png)

This Vercel dashboard allows you to see the latest deployment and some relative information about it.

Currently, it shows:

- Commit message
- Project name
- Author name
- Success/Failure
- Time it was created

In order for it to work, you will need a Vercel API Token. You can read [Vercel's Documentation](https://vercel.com/docs/rest-api#creating-an-access-token) on how to create one.

For team accounts, ensure the access token has the correct scope and include the Team Id [Vercel's Documentation](https://vercel.com/guides/how-do-i-use-a-vercel-api-access-token). Your team Id can be found in the team's Settings > General > Team Id

## Configuration

| Title    | Description                    | Required | Default |
| -------- | ------------------------------ | -------- | ------- |
| API Key  | Your Vercel API Key            | Yes      | --      |
| Team ID  | Your Vercel Team's ID          | No       | --      |
| Timezone | Timezone to show build time at | No       | UTC     |
| 24hr     | Show time as 24hr (13:04)      | No       | True    |
