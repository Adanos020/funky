module funky.parser;


import pegged.grammar;

import std.algorithm.iteration;
import std.algorithm.mutation;
import std.algorithm.searching;
import std.array;
import std.string;
import std.stdio;
import std.uni;


enum GRAMMAR_STRING = import("grammar.peg");
enum PARSER_CODE = grammar(GRAMMAR_STRING);

mixin(PARSER_CODE);


PT stripName(PT)(PT p)
{
        p.matches[0] = p.matches[0].detab.tr(" ", "", "s");
        return p;
}

PT stripNumber(PT)(PT p)
{
        p.matches[0] = p.matches[0].dup.remove!isWhite;
        return p;
}

PT trimOnce(PT)(PT p)
{
        return p.children.length ? p.children[0] : p;
}

PT trim(PT)(PT p)
{
        enum string[] keepName = map!(x => "Funky." ~ x)([
                "AssignConstant",
                "AssignFunction",
                "AssignVariable",
        ]).array;

        enum string[] keepNode = map!(x => "Funky." ~ x)([
                "ArgumentDeclarations",
                "ArrayContent",
                "ArrayIndexRange",
                "ArrayLiteral",
                "ArraySlice",
                "ClassFields",
                "Code",
                "FunctionArguments",
                "FunctionCall",
                "FunctionLiteral",
                "FunctionLocals",
                "Import",
                "StringLiteral",
                "StructFields",
                "StructLiteral",
        ]).array;

        if (p.children.length == 1 && !keepNode.canFind(p.name))
        {
                PT result = p.children[0].trim;
                if (keepName.canFind(p.name))
                {
                        result.name = p.name;
                }
                return result;
        }

        foreach (ref child; p.children)
        {
                child = child.trim;
        }
        return p;
}

package:

string match(ParseTree p)
{
        return p.matches[0];
}

ParseTree child(ParseTree p)
{
        return p.children[0];
}