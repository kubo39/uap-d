ua-parser
=========

`ua-parser` is a multi-language port of [BrowserScope][1]'s [user agent string parser][2].

The crux of the original parser--the data collected by [Steve Souders][3] over the years--has been extracted into a separate [YAML file][4] so as to be reusable _as is_ by implementations in other programming languages.

`ua-parser` is just a small wrapper around this data.

Installation
---------------------

Install [DMD][5].
Install [D-YAML][6] and make sure you add the relevant paths to dmd.conf so the linker can find the module.

Once setup, you can directly include the source file (UaParser.d) in your working directory or you can generate a library and add the path to dmd.conf.

Or use dub:

```sdl
...
dependency "ua-parser" path=</path/to/uap-d>
...
```

Usage
---------------

Please refer to the examples directory. To run the example, execute the following command in terminal:

```console
cd examples/simple
dub run
```

[1]: http://www.browserscope.org
[2]: https://github.com/ua-parser
[3]: https://www.stevesouders.com/blog/2009/09/13/browserscope-how-does-your-browser-compare/
[4]: https://github.com/ua-parser/uap-core
[5]: https://dlang.org/download.html
[6]: https://github.com/dlang-community/D-YAML/wiki/Getting-Started
