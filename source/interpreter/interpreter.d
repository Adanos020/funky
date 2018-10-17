module interpreter.interpreter;
import interpreter.parser;

import pegged.grammar;

import std.algorithm.searching;
import std.stdio;


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
        const(string) fileExtension = ".hs";

        string[] importedModules;
}


ParseStatus importModule(string modulePath)
{
        if (importedModules.canFind(modulePath))
        {
                return ParseStatus(StatusCode.SUCCESS);
        }

        scope(failure)
        {
                return ParseStatus(
                        StatusCode.FAILURE,
                        "Could not import module: " ~ modulePath
                );
        }

        File file = File(modulePath ~ fileExtension, "r");
        string code;

        importedModules ~= modulePath;

        while (!file.eof)
        {
                code ~= file.readln;
        }

        return code.interpret;
}

ParseStatus interpret(string code)
{
        import pegged.tohtml;

        auto tree = Funky(code).trim;
        toHTML(tree, "tree.html");
        writeln(tree);
        
        auto status = ParseStatus(StatusCode.SUCCESS);

        void processTree(ParseTree p)
        {
                switch (p.name)
                {
                        case "Funky.Code":
                        {
                                processTree(p.children[0]);
                                break;
                        }

                        case "Funky.Import":
                        {
                                string path = p.children[1].matches[0];
                                status = importModule(path);
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