module funky.interpreter;

import arsd.terminal;

import funky.parser;

import pegged.grammar;

import std.algorithm.searching;
import std.file;
import std.range;
import std.stdio;
import std.string;


enum StatusCode
{
        SUCCESS,
        FAILURE,
        EXIT,
}

struct ParseStatus
{
        StatusCode code;
        string message;
        size_t line;
        string moduleName;
        string extra;
}


private
{
        struct VariableID
        {
                string name;
                bool constant;
        }

        const(string) fileExtension = ".hs";

        string[] importedModules;

        Terminal* term;
}


void init(Terminal* terminal)
{
        term = terminal;
}


ParseStatus importModule(string modulePath)
{
        scope(failure)
        {
                return ParseStatus(
                        StatusCode.FAILURE,
                        "Could not import module: `%s`".format(modulePath)
                );
        }

        if (importedModules.canFind(modulePath))
        {
                return ParseStatus(StatusCode.SUCCESS);
        }

        if (modulePath.exists && modulePath.isDir)
        {
                foreach (entry; dirEntries(modulePath, SpanMode.depth))
                {
                        // Removing file extension from filename. ↓
                        ParseStatus status = importModule(entry.array.retro.find(".").retro.chop);
                        if (status.code == StatusCode.FAILURE)
                        {
                                return status;
                        }
                }
                return ParseStatus(StatusCode.SUCCESS);
        }

        string code = readText(modulePath ~ fileExtension);
        importedModules ~= modulePath;
        return code.interpret;
}

ParseStatus interpret(string code)
{
        auto tree = Funky(code).trim;

        if (!tree.successful)
        {
                return ParseStatus(StatusCode.FAILURE, tree.failMsg);
        }

        debug
        {
                import pegged.tohtml;

                toHTML(tree, "tree.html");
                if ("tree.txt".exists)
                {
                        std.file.remove("tree.txt");
                }
                std.file.write("tree.txt", tree.toString);
        }

        auto status = ParseStatus(StatusCode.SUCCESS);

        bool inFunctionDef = false;

        void processTree(ParseTree p)
        {
                if (status.code == StatusCode.EXIT)
                {
                        return;
                }
                
                if (inFunctionDef) switch (p.name)
                {
                        default:
                        {
                                break;
                        }
                }
                else switch (p.name)
                {
                        case "Funky.Code":
                        {
                                processTree(p.children[0]);
                                break;
                        }

                        case "Funky.FunctionCall":
                        {
                                string funcName = p.children[0].matches[0];
                                if (p.children.length == 1)
                                {
                                        if (funcName == "exit" || funcName == "quit")
                                        {
                                                status = ParseStatus(StatusCode.EXIT);
                                                break;
                                        }
                                }
                                else
                                {
                                        if (funcName == "exit" || funcName == "quit")
                                        {
                                                status = ParseStatus(
                                                        StatusCode.FAILURE,
                                                        "Function `%s` called with %s parameters while expecting 0"
                                                                .format(funcName, p.children[1].children.length)
                                                );
                                                break;
                                        }
                                        auto args = p.children[1].children;
                                        // TODO - call function
                                }
                                break;
                        }

                        case "Funky.Import":
                        {
                                string path = p.children[0].matches[0];
                                status = importModule(path);
                                break;
                        }

                        case "Funky.ConstantAssignment":
                        {
                                bool constant = true;
                                goto case;

                        case "Funky.FunctionAssignment", "Funky.VariableAssignment":
                        
                                break;
                        }

                        default:
                        {
                                break;
                        }
                }
        }

        processTree(tree);

        return status;
}