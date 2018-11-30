module funky.interpreter;

import arsd.terminal;

import funky.exception;
import funky.expression;
import funky.parser;

import pegged.grammar;

import std.algorithm.searching;
import std.conv;
import std.exception;
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
        return code.interpret(modulePath);
}

ParseStatus interpret(string code, string moduleName = "console")
{
        auto tree = Funky(code).trim;

        if (!tree.successful)
        {
                return ParseStatus(StatusCode.FAILURE,
                        tree.failMsg,
                        tree.position.line + 1,
                        moduleName
                );
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

        void processTree(ParseTree p)
        {
                if (status.code == StatusCode.EXIT)
                {
                        return;
                }

                if (valueTypes.canFind(p.name))
                {
                        try
                        {
                                Expression expr = p.toExpression((Variable[string]).init);
                                if (!expr)
                                {
                                        throw new Exception("Null expression.");
                                }

                                expr = expr.evaluate;

                                if (auto sct = cast(Struct) expr)
                                {
                                        if (sct.fields.length == 2 &&
                                                "error code" in sct.fields && "message" in sct.fields)
                                        {
                                                if (auto ec = cast(Number) sct.field("error code"))
                                                {
                                                        status = ec.value == 0 ?
                                                                ParseStatus(
                                                                        StatusCode.EXIT
                                                                ) :
                                                                ParseStatus(
                                                                        StatusCode.FAILURE,
                                                                        sct.field("message").toString
                                                                );
                                                        return;
                                                }
                                        }
                                }
                                if (!p.name.startsWith("Funky.Assign"))
                                {
                                        term.writeln(expr);
                                }
                        }
                        catch (Exception ex)
                        {
                                status = ParseStatus(StatusCode.FAILURE,
                                        ex.msg,
                                        p.position.line + 1,
                                        moduleName
                                );
                        }
                }
                else if (p.name == "Funky.Import")
                {
                        string path = p.children[0].match;
                        status = importModule(path);
                }
                else if (p.name == "Funky.Code")
                {
                        foreach (ref ch; p.children)
                        {
                                processTree(ch);
                        }
                }
        }

        processTree(tree);

        return status;
}


package:

Variable[string] globals;


private:

enum string fileExtension = ".f";
enum string[] valueTypes = [
        "Funky.ArrayAccess",
        "Funky.ArrayLiteral",
        "Funky.ArraySlice",
        "Funky.AssignConstant",
        "Funky.AssignFunction",
        "Funky.AssignVariable",
        "Funky.BooleanLiteral",
        "Funky.FunctionLiteral",
        "Funky.Identifier",
        "Funky.NumberLiteral",
        "Funky.StructLiteral",
        "Funky.StringLiteral",
        "Funky.Comparison",
        "Funky.Concatenation",
        "Funky.Conditional",
        "Funky.SafeConditional",
        "Funky.Sum",
        "Funky.Product",
        "Funky.Power",
        "Funky.Unary",
        "Funky.And",
        "Funky.Xor",
        "Funky.Or",
        "Funky.Not",
        "Funky.StructFieldAccess",
        "Funky.FunctionCall",
];

string[] importedModules;

Terminal* term;