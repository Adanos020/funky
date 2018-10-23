import arsd.terminal;

import funky.interpreter;

import std.stdio;
import std.string;


void main(string[] args)
{
        auto term = Terminal(ConsoleOutputType.linear);

        init(&term);
        importModule("std/init");

        // Importing modules.
        foreach (arg; args[1 .. $])
        {
                importModule(arg);
        }

        while (true)
        {
                scope(failure) break;

                term.write(">>> ");
                string command = term.getline.strip;

                ParseStatus status = command.interpret;

                if (status.code == StatusCode.EXIT)
                {
                        break;
                }

                if (status.code != StatusCode.SUCCESS)
                {
                        term.color(Color.red, Color.DEFAULT);
                        if (status.extra.length)
                        {
                                status.extra = "\n" ~ status.extra;
                        }
                        term.writefln(
                                "Error in %s, line %s: %s%s",
                                status.moduleName,
                                status.line,
                                status.message,
                                status.extra
                        );
                        term.reset;
                }
        }
}