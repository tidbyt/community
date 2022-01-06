# App Philosophy
Our goal is to keep our opinions pretty light when it comes to the types of apps we will support in this repo. With that being said, this document looks to provide some basic guidance on the types of apps we can support today. At a bare minimum, apps must adhere to our [code of conduct](../CODE_OF_CONDUCT.md).

## Generally Available
Apps added to this repo will be available to everyone. We _love_ niche use cases and **encourage them**. But if the app is only for you, the author, then we likely will not be able to support it. Your app doesn't have to be popular, but there in theory should be more users than just you.

## Support
At the end of the day, Tidbyt employees will be the ones who will have to resolve production issues and respond to support emails. This means a few things:
- Apps need to use a stable API
    - An API hosted on your home network simply won't do
    - Any failures will surface in our monitoring tools and alert our oncalls
- Apps published should be stable
    - If there are bugs, we will make changes quickly and will likely not wait for your review
    - If they are unresolvable, we may have to pull the app from our inventory until we get ahold of you

## Product Direction
We want you, the contributor, to own the product direction of the apps you contribute. If others want to contribute features or modifications, we encourage it! However, we will want your input on the pull request and will wait a week or so to hear back from you before we merge the change. If you're MIA and there is strong interest in the change, we will merge it and won't wait up on you forever. See [modifying apps](modifying_apps.md) for more.