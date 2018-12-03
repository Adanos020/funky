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
                return "exit()";
        }
}

void logErrorIfOccured(ref Terminal term, ParseStatus status)
{
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

                if (status.moduleName != "console")
                {
                        // what
                }
        }
}

void main(string[] args)
{
        auto term = Terminal(ConsoleOutputType.linear);

        init(&term);
        term.logErrorIfOccured(importModule("std/init"));

        // Importing modules.
        foreach (arg; args[1 .. $])
        {
                if (arg.endsWith(".f"))
                {
                        arg = arg[0 .. $ - 2];
                }
                term.logErrorIfOccured(importModule(arg));
        }

        while (true)
        {
                term.write(">>> ");

                const(string) command = term.getCommand;
                ParseStatus status = command.interpret;

                term.logErrorIfOccured(status);

                if (status.code == StatusCode.EXIT)
                {
                        break;
                }
        }
}