# IsItUp

Display the status of a web site from a specified URL.  Will display OK with a green background if site responds with a 200-299 response code.  
Will display 'Failed: [response code]' with a red background if not OK.

You can optionally extract a version number from a response that looks something like:

```
    {
        "version": "1.2.3.4",
        ...
    }
```

Cheers!

![screenshot](site_ok.png)

![screenshot](site_fail.png)
