# middleman-headless

**Middleman extension to load content from the Headless Content Management System.**

## Example

The example middleman site in `./example` shows how you can retrieve data from a headless instance.

First of all, you need to create a new space in your headless server with the slug `example`.

After that you need to create the following content types:

```
post:
  title: string
  body: string (multiline)
  image: asset
  author: reference (author)

author (has no fields)
```

Now you need to add English as a language with the slug `en`.

Finally, you can create as many entries you like.
