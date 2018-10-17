import interpreter.interpreter;

import colorize;

import std.stdio;
import std.string;


void main(string[] args)
{
        importModule("std/init");

        // Importing modules.
        foreach (arg; args[1 .. $])
        {
                importModule(arg);
        }

        while (true)
        {
                write(">>> ");
                string command = readln.strip;

                ParseStatus status = command.interpret;

                if (status.code == StatusCode.EXIT)
                {
                        break;
                }

                if (status.code != StatusCode.SUCCESS)
                {
                        cwritefln(
                                "Error in module `%s`, line %s: %s\n".color(fg.red) ~ status.extra,
                                status.moduleName,
                                status.line,
                                status.message
                        );
                }
        }
}