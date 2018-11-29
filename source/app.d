import funky.interpreter;

import arsd.terminal;

import std.algorithm.searching;
import std.stdio;
import std.string;


string getCommand(ref Terminal term)
{
        try
        {
                return term.getline.strip;
        }
        catch (UserInterruptionException ex)
        {
                // return "exit()";
                return null;
        }
}

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
                term.write(">>> ");

                const(string) command = term.getCommand;
                if (!command)
                {
                        break;
                }

                ParseStatus status = command.interpret;

                if (status.code == StatusCode.EXIT)
                {
                        break;
                }

                if (status.code == StatusCode.FAILURE)
                {
                        if (status.extra.length)
                        {
                                status.extra = "\n" ~ status.extra;
                        }

                        term.color(Color.red, Color.DEFAULT);
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