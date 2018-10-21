module funky.interpreter;

import arsd.terminal;

import funky.expression;
import funky.parser;

import pegged.grammar;

import std.algorithm.searching;
import std.conv;
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
        struct Variable
        {
                bool constant;
                Expression value;
        }

        const(string) fileExtension = ".hs";
        const(string[]) valueTypes = [
                "Funky.Sum",             "Funky.Product",    "Funky.Power", "Funky.Unary",
                "Funky.ArrayLiteral",    "Funky.ArraySlice",
                "Funky.BooleanLiteral",  "Funky.Comparison",
                "Funky.Concatenation",
                "Funky.Conditional",     "Funky.SafeConditional",
                "Funky.FunctionLiteral", "Funky.FunctionCall",
                "Funky.Identifier",
                "Funky.And",             "Funky.Xor",        "Funky.Or",    "Funky.Not",
                "Funky.NumberLiteral",
                "Funky.ObjectLiteral",   "Funky.ObjectFieldAccess",
                "Funky.StringLiteral",
        ];

        string[] importedModules;
        Variable[string] variables;

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
        bool constant = false;

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
                else
                {
                        if (valueTypes.canFind(p.name))
                        {
                                Expression expr = p.toExpression;
                                term.writeln(expr.toString);
                        }

                        switch (p.name)
                        {
                                case "Funky.Code":
                                {
                                        processTree(p.children[0]);
                                        break;
                                }

                                case "Funky.FunctionCall":
                                {
                                        string funcName = p.children[0].match;
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

                                case "Funky.Identifier":
                                {

                                        break;
                                }

                                case "Funky.Import":
                                {
                                        string path = p.children[0].match;
                                        status = importModule(path);
                                        break;
                                }

                                case "Funky.ConstantAssignment":
                                {
                                        constant = true;
                                        goto case;
                                }

                                case "Funky.FunctionAssignment", "Funky.VariableAssignment":
                                {
                                        string varname = p.children[0].match;

                                        if (varname in variables && variables[varname].constant)
                                        {
                                                status = ParseStatus(StatusCode.FAILURE,
                                                        "Attempting to assign to a constant `%s`."
                                                                .format(varname)
                                                );
                                                constant = false;
                                                break;
                                        }

                                        variables[varname] = Variable(constant, p.children[1].toExpression);
                                        constant = false;
                                        break;
                                }

                                default:
                                {
                                        break;
                                }
                        }
                }
        }

        processTree(tree);

        return status;
}

private:

string match(ParseTree p)
{
        return p.matches[0];
}

Expression toExpression(ParseTree p)
{
        final switch (p.name)
        {
                case "Funky.Sum", "Funky.Product", "Funky.Power":
                {
                        string op = p.children[1].match;
                        auto lhs = cast(Arithmetic) p.children[0].toExpression;
                        auto rhs = cast(Arithmetic) p.children[2].toExpression;

                        switch (op)
                        {
                                case "+":
                                {
                                        return new ArithmeticBinary!"+"(lhs, rhs);
                                }

                                case "-":
                                {
                                        return new ArithmeticBinary!"-"(lhs, rhs);
                                }

                                case "*":
                                {
                                        return new ArithmeticBinary!"*"(lhs, rhs);
                                }

                                case "/":
                                {
                                        return new ArithmeticBinary!"/"(lhs, rhs);
                                }

                                case "%":
                                {
                                        return new ArithmeticBinary!"%"(lhs, rhs);
                                }

                                case "^":
                                {
                                        return new ArithmeticBinary!"^^"(lhs, rhs);
                                }

                                default:
                                {
                                        return null;
                                }
                        }
                }

                case "Funky.Unary":
                {
                        string op = p.children[0].match;
                        auto rhs = cast(Arithmetic) p.children[1].toExpression;

                        if (op == "+")
                        {
                                return new ArithmeticUnary!"+"(rhs);
                        }
                        if (op == "-")
                        {
                                return new ArithmeticUnary!"-"(rhs);
                        }
                        return null;
                }

                case "Funky.ArrayAccess":
                {
                        auto array = p.children[0].toExpression;
                        auto index = p.children[1].toExpression;
                        break;
                }

                case "Funky.ArrayLiteral":
                {
                        break;
                }

                case "Funky.ArraySlice":
                {
                        break;
                }

                case "Funky.AssignConstant",
                     "Funky.AssignFunction",
                     "Funky.AssignVariable":
                {
                        break;
                }

                case "Funky.BooleanLiteral":
                {
                        // return new Boolean(p.match);
                        break;
                }

                case "Funky.Concatenation":
                {
                        break;
                }

                case "Funky.Conditional",
                     "Funky.SafeConditional":
                {
                        break;
                }

                case "Funky.FunctionCall":
                {
                        break;
                }

                case "Funky.FunctionLiteral":
                {
                        break;
                }

                case "Funky.Identifier":
                {
                        if (p.match in variables)
                        {
                                return variables[p.match].value;
                        }
                        break;
                }

                case "Funky.Logical":
                {
                        break;
                }

                case "Funky.NumberLiteral":
                {
                        return new Number(p.match == "infinity" ? double.infinity : p.match.to!double);
                }

                case "Funky.ObjectLiteral":
                {
                        break;
                }

                case "Funky.ObjectFieldAccess":
                {
                        break;
                }

                case "Funky.StringLiteral":
                {
                        // return new String(p.match);
                        break;
                }
        }
        return null;
}