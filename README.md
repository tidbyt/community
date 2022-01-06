# Community Apps
![Main Workflow](https://github.com/tidbyt/community/actions/workflows/push.yml/badge.svg)

Community Apps is a publishing platform for apps developed by the [Tidbyt community][3] 🚀 

![Banner Image](docs/assets/banner.jpg)

📸  [Fuzzy Clock](apps/fuzzy_clock.star) by [Max Timkovich][5], photographed  by [Tidbyt][1].

## ⚠️⚠️⚠️ Notice ⚠️⚠️⚠️
Hello! If you're reading this, we've invited you to check out this repo and would _love_ if you added your apps here and **provide feedback** for how it goes through a GitHub issue on the repo. We plan to make this repo public for all in the next week or so, but we wanted to work out a few kinks before we did.

The biggest gotcha is the `get_schema` method inside of the applet. Schema is how we populate the config values from the mobile app. We know we need to open source our schema but it's going to take a few more days to do so. To get around that in the short term, leave the method to return an empty list and we'll follow up with a PR to populate it.

One thing you should note - there is a special config value of `$tz` that we populate from the location of the device. To use it, do the following:

```starlark
DEFAULT_TIME_ZONE = "America/New_York"

def main(config):
    tz = config.get("$tz", DEFAULT_TIME_ZONE)
    now = time.now().in_location(tz)
```

The final note, we may have to do a few refactors so please bear with us until we make this repo public 😅

## About
This repo is for publishing apps to all Tidbyt users. Interested in developing apps? Check out [Pixlet][2] and follow the [Hello, World!][4] tutorial. When your applet is ready to publish, follow our [contributions guide](docs/CONTRIBUTING.md).


[1]: https://tidbyt.com
[2]: https://github.com/tidbyt/pixlet
[3]: https://discuss.tidbyt.com/
[4]: https://github.com/tidbyt/pixlet#hello-world
[5]: https://github.com/mtimkovich
