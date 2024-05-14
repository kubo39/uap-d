import UaParser;

import std.stdio;

void main()
{
    auto agent = UaParser.parse("Mozilla/5.0 (iPhone; CPU iPhone OS 5_1_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B206 Safari/7534.48.3");
    writeln(agent.browser.family);
    writeln(agent.browser.major);
    writeln(agent.browser.minor);
    writeln(agent.browser.patch);
    writeln(agent.browser.toString);
    writeln(agent.browser.toVersionString);

    writeln("=================================");

    writeln(agent.os.family);
    writeln(agent.os.major);
    writeln(agent.os.minor);
    writeln(agent.os.patch);
    writeln(agent.os.toString);
    writeln(agent.os.toVersionString);

    writeln("=================================");

    writeln(agent.toFullString);

    writeln("=================================");
    
    writeln(agent.device.family);
    
    writeln(agent.isSpider);
}
