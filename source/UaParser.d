module UaParser;

private:

import dyaml;

Node regexes;
DeviceStore[] deviceStore;
OsStore[] osStore;
BrowserStore[] browserStore;

int parseInt(string input)
{
    import std.conv : parse;
    return parse!int(input);
}

struct DeviceStore
{
    string rexp;
    string rexpFlag;
    string deviceReplacement;
    string brandReplacement;
    string modelReplacement;
}

struct OsStore
{
    string rexp;
    string family;
    string majorVersion;
    string minorVersion;
    string patchVersion;
}

struct BrowserStore
{
    string rexp;
    string family;
    string majorVersion;
    string minorVersion;
    string patchVersion;
}

public:

/**
 *  Device information parsed from a user agent string.
 */
class Device
{
    string family;
    string brand;
    string model;

    override string toString() const { return family; }
}

/**
 *  OS information parsed from a user agent string.
 */
class Os
{
    string family;
    int major;  // major version
    int minor;  // minor version
    int patch;  // patch version

    override string toString() const
    {
        return family ~ " " ~ toVersionString();
    }

    string toVersionString() const
    {
        import std.conv : to;
        return to!string(major) ~ "."
             ~ to!string(minor) ~ "."
             ~ to!string(patch);
    }
}

/**
 *  Browser information parsed from a user agent string.
 */
class Browser
{
    string family;
    int major;  // major version
    int minor;  // minor version
    int patch;  // patch version

    override string toString() const
    {
        return family ~ " " ~ toVersionString();
    }

    string toVersionString() const
    {
        import std.conv : to;
        return to!string(major) ~ "."
             ~ to!string(minor) ~ "."
             ~ to!string(patch);
    }
}

class UserAgent
{
    Device device;
    Os os;
    Browser browser;

    string toFullString() const
    {
        return browser.toString() ~ "/" ~ os.toString();
    }

    bool isSpider() const
    {
        return device.family == "Spider";
    }
}

shared static this()
{
    import std.path : dirName;
    immutable filePath = __FILE_FULL_PATH__.dirName;
    regexes = Loader.fromFile(
         filePath ~ "/../uap-core/regexes.yaml"
    ).load();

    const userAgentParsers = regexes["user_agent_parsers"];
    foreach (const ref Node userAgent; userAgentParsers)
    {
        BrowserStore browser;
        foreach (const ref Node key, const ref Node value; userAgent)
        {
            switch (key.as!string)
            {
                case "regex":
                    browser.rexp =value.as!string;
                    break;
                case "family_replacement":
                    browser.family = value.as!string;
                    break;
                case "v1_replacement":
                    browser.majorVersion = value.as!string;
                    break;
                case "v2_replacement":
                    browser.minorVersion = value.as!string;
                    break;
                case "v3_replacement":
                    browser.patchVersion = value.as!string;
                    break;
                default:
                    throw new Exception("Unknown user_agent_parsers key : " ~ key.as!string);
            }
        }
        browserStore ~= browser;
    }

    const osParsers = regexes["os_parsers"];
    foreach (const ref Node o; osParsers)
    {
        OsStore os;
        foreach (const ref Node key, const ref Node value; o)
        {
            switch (key.as!string)
            {
                case "regex":
                    os.rexp = value.as!string;
                    break;
                case "os_replacement":
                    os.family = value.as!string;
                    break;
                case "os_v1_replacement":
                    os.majorVersion = value.as!string;
                    break;
                case "os_v2_replacement":
                    os.minorVersion = value.as!string;
                    break;
                case "os_v3_replacement":
                    os.patchVersion = value.as!string;
                    break;
                default:
                    throw new Exception("Unknown os_parsers key : " ~ key.as!string);
            }
        }
        osStore ~= os;
    }

    const deviceParsers = regexes["device_parsers"];
    foreach (const ref Node d; deviceParsers)
    {
        DeviceStore device;
        foreach (const ref Node key, const ref Node value; d)
        {
            switch (key.as!string)
            {
                case "regex":
                    device.rexp = value.as!string;
                    break;
                case "regex_flag":
                    device.rexpFlag = value.as!string;
                    break;
                case "device_replacement":
                    device.deviceReplacement = value.as!string;
                    break;
                case "brand_replacement":
                    device.brandReplacement = value.as!string;
                    break;
                case "model_replacement":
                    device.modelReplacement = value.as!string;
                    break;
                default:
                    throw new Exception("Unknown device_parsers key : " ~ key.as!string);
            }
        }
        deviceStore ~= device;
    }
}

static if (__VERSION__ < 2103)
{
    import std.experimental.logger;
}
else
{
    import std.logger;
}

/**
 *  Parse a user agent string.
 */
UserAgent parse(string ua, Logger logger = new NullLogger)
{
    import std.stdio : stderr;
    import std.regex : matchFirst, Regex, regex, replace;

    auto uagent  = new UserAgent;
    auto device  = new Device;
    auto os      = new Os;
    auto browser = new Browser;

    uagent.device  = device;
    uagent.os      = os;
    uagent.browser = browser;

    foreach (b; browserStore)
    {
        Regex!char r;
        try r = regex(r""~b.rexp~"");
        catch (Throwable e)
        {
            logger.info("skipping `%s`, due to %s", b.rexp, e.msg);
            continue;
        }

        auto m = matchFirst(ua, r);
        if (m.empty)
            continue;
        try
        {
            browser.family = b.family ? replace(
                                            b.family,
                                            regex(r"\$1"),
                                            m.captures[1]
                                        )
                                      : m.captures[1];
        }
        catch (Throwable e)
        {
            browser.family = "";
        }
        try
        {
            browser.major = parseInt(b.majorVersion ? b.majorVersion
                                                    : m.captures[2]);
        }
        catch (Throwable e)
        {
            browser.major = 0;
        }
        try
        {
            browser.minor = parseInt(b.minorVersion ? b.minorVersion
                                                    : m.captures[3]);
        }
        catch (Throwable e)
        {
            browser.minor = 0;
        }
        try
        {
            browser.patch = parseInt(b.patchVersion ? b.patchVersion
                                                    : m.captures[4]);
        }
        catch (Throwable e)
        {
            browser.patch = 0;
        }
        break;
    }

    foreach (o; osStore)
    {
        Regex!char r;
        try r = regex(r""~o.rexp~"");
        catch (Throwable e)
        {
            logger.info("skipping `%s`, due to %s", o.rexp, e.msg);
            continue;
        }
        auto m = matchFirst(ua, r);
        if (m.empty)
            continue;
        try
        {
            os.family = o.family ? replace(
                                        o.family,
                                        regex(r"\$1"),
                                        m.captures[1]
                                    )
                                 : m.captures[1];
        }
        catch (Throwable e)
        {
            os.family = "";
        }
        try
        {
            os.major = parseInt(o.majorVersion ? o.majorVersion
                                               : m.captures[2]);
        }
        catch (Throwable e)
        {
            os.major = 0;
        }
        try
        {
            os.minor = parseInt(o.minorVersion ? o.minorVersion
                                               : m.captures[3]);
        }
        catch (Throwable e)
        {
            os.minor = 0;
        }
        try
        {
            os.patch = parseInt(o.patchVersion ? o.patchVersion
                                               : m.captures[4]);
        }
        catch (Throwable e)
        {
            os.patch = 0;
        }
        break;
    }

    foreach (d; deviceStore)
    {
        Regex!char r;
        try r = regex(r""~d.rexp~"", d.rexpFlag);
        catch (Throwable e)
        {
            logger.info("skipping `%s`, due to %s", d.rexp, e.msg);
            continue;
        }
        auto m = matchFirst(ua, r);
        if (m.empty)
            continue;
        try
        {
            device.family = d.deviceReplacement ? replace(
                                            d.deviceReplacement,
                                            regex(r"\$1"),
                                            m.captures[1]
                                        )
                                      : m.captures[1];
        }
        catch (Throwable e)
        {
            device.family = "";
        }
        try
        {
            device.brand = d.brandReplacement ? replace(
                                            d.brandReplacement,
                                            regex(r"\$1"),
                                            m.captures[2]
                                        )
                                      : m.captures[2];
        }
        catch (Throwable e)
        {
            device.brand = "";
        }
        try
        {
            device.model = d.modelReplacement ? replace(
                                            d.modelReplacement,
                                            regex(r"\$1"),
                                            m.captures[3]
                                        )
                                      : m.captures[3];
        }
        catch (Throwable e)
        {
            device.model = "";
        }
        break;
    }
    return uagent;
}

unittest
{
    import std.stdio : stderr;
    const pagent = parse(
        "Mozilla/5.0 (iPhone; CPU iPhone OS 5_1_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B206 Safari/7534.48.3",
        new FileLogger(stderr)
    );

    assert(pagent.browser.family == "Mobile Safari");
    assert(pagent.browser.major == 5);
    assert(pagent.browser.minor == 1);
    assert(pagent.browser.patch == 0);
    assert(pagent.browser.toString == "Mobile Safari 5.1.0");
    assert(pagent.browser.toVersionString == "5.1.0");

    assert(pagent.os.family == "iOS");
    assert(pagent.os.major == 5);
    assert(pagent.os.minor == 1);
    assert(pagent.os.patch == 1);
    assert(pagent.os.toString == "iOS 5.1.1");
    assert(pagent.os.toVersionString == "5.1.1");

    assert(pagent.toFullString == "Mobile Safari 5.1.0/iOS 5.1.1");

    assert(pagent.device.family == "iPhone");

    assert(!pagent.isSpider);
}
