# Frequently Asked Questions

## Why is the linter so opinionated?
We know the linter can be annoying. First off, we're sorry it's annoying! But it's in place for good reasons. On the technical front, Starlark is a language with syntactically significant whitespace. That means if a indentation is incorrect, it could change the meaning of your code 🙀. On the practical side, Tidbyt engineers often need to make minor modifications to apps in the Community repo. Our editors format Starlark automatically on save using the [Bazel plugin](https://marketplace.visualstudio.com/items?itemName=BazelBuild.vscode-bazel) for VSCode, which means one small change could auto format your entire app and look like a much bigger change!

The good news is you can fix lint errors automatically! To automatically fix lint errors, run the following:
```
make format
```

## When will my app be available in the Tidbyt mobile app?
First off, we're sorry that this process is so opaque. Making the app release process more transparent is pretty high on our priority list. The short: it is available in the Tidbyt mobile app within an hour or so, but it's only visible to Tidbyt engineers and beta users. If you'd like to see your app before we launch it, give us a DM on Discord!

Here is the long version of how the release works today:
- A Tidbyt engineer reviews your code
- Once it's approved, we will merge it into the Community repo
- Then, a robot will automatically make a pull request to our private repo internally
- Most likely, we will merge it immediately and it will be in production within a few minutes
- From there, the app is only available to beta testers and Tidbyt engineers
- We manually check out the app, add it to a Tidbyt, and just make sure it's going to work
- Once it's ready, we make it available to everyone and announce it in #community on Discord

If you're not sure where your app is in the release process, feel free to ping us on Discord!