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

        enum string fileExtension = ".hs";
        enum string[] valueTypes = [
                "Funky.ArrayLiteral",
                "Funky.ArraySlice",
                "Funky.AssignConstant",
                "Funky.AssignFunction",
                "Funky.AssignVariable",
                "Funky.BooleanLiteral",
                "Funky.FunctionLiteral",
                "Funky.Identifier",
                "Funky.NumberLiteral",
                "Funky.ObjectLiteral",
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
                "Funky.ObjectFieldAccess",
                "Funky.FunctionCall",
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
                        Expression expr = p.toExpression;
                        if (cast(InvalidExpr) expr)
                        {
                                status = ParseStatus(StatusCode.FAILURE,
                                        expr.toString,
                                        p.position.line + 1,
                                        moduleName
                                );
                        }
                        else if (!p.name.startsWith("Funky.Assign"))
                        {
                                term.writeln(expr);
                        }
                }
                else switch (p.name)
                {
                        case "Funky.Code":
                        {
                                foreach (ref child; p.children)
                                {
                                        processTree(child);
                                }
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
                                                status = ParseStatus(StatusCode.FAILURE,
                                                        "Function `%s` called with %s parameters while expecting 0"
                                                                .format(funcName, p.children[1].children.length),
                                                        p.position.line + 1,
                                                        moduleName
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
                                string path = p.children[0].match;
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


private:


string match(ParseTree p)
{
        return p.matches[0];
}

ParseTree child(ParseTree p)
{
        return p.children[0];
}

Expression toExpression(ParseTree p)
{
        // For assignments.
        bool constant;

        switch (p.name)
        {
                case "Funky.Sum", "Funky.Product", "Funky.Power":
                {
                        auto lhs = cast(Arithmetic) p.child.toExpression;

                        if (!lhs)
                        {
                                return new InvalidExpr(
                                        "`%s` is not of an arithmetic type.".format(p.child.match)
                                );
                        }

                        for (int i = 2; i < p.children.length; i += 2)
                        {
                                const(string) op = p.children[i - 1].match;
                                auto rhs = cast(Arithmetic) p.children[i].toExpression;

                                if (!rhs)
                                {
                                        return new InvalidExpr(
                                                "`%s` is not of an arithmetic type.".format(p.children[i].match)
                                        );
                                }

                                final switch (op)
                                {
                                        case "+":
                                        {
                                                lhs = new ArithmeticBinary!"+"(lhs, rhs);
                                                break;
                                        }

                                        case "-":
                                        {
                                                lhs = new ArithmeticBinary!"-"(lhs, rhs);
                                                break;
                                        }

                                        case "*":
                                        {
                                                lhs = new ArithmeticBinary!"*"(lhs, rhs);
                                                break;
                                        }

                                        case "/":
                                        {
                                                lhs = new ArithmeticBinary!"/"(lhs, rhs);
                                                break;
                                        }

                                        case "%":
                                        {
                                                lhs = new ArithmeticBinary!"%"(lhs, rhs);
                                                break;
                                        }

                                        case "^":
                                        {
                                                lhs = new ArithmeticBinary!"^^"(lhs, rhs);
                                                break;
                                        }
                                }
                        }

                        return lhs;
                }

                case "Funky.Unary":
                {
                        const(string) op = p.children[0].match;
                        auto rhs = cast(Arithmetic) p.children[1].toExpression;

                        if (!rhs)
                        {
                                return new InvalidExpr(
                                        "`%s` is not of an arithmetic type.".format(p.children[1].match)
                                );
                        }

                        if (op == "-")
                        {
                                return new ArithmeticUnary!"-"(rhs);
                        }
                        // Unary `+` doesn't really change the value.
                        return rhs;
                }

                case "Funky.ArrayAccess":
                {
                        auto array = p.children[0].toExpression;

                        if (auto inv = cast(InvalidExpr) array)
                        {
                                return inv;
                        }

                        if (auto arr = cast(Array) array)
                        {
                                auto index = p.children[1].toExpression;

                                if (auto inv = cast(InvalidExpr) index)
                                {
                                        return inv;
                                }

                                if (auto i = cast(Number) index)
                                {
                                        return arr[cast(int) i.value];
                                }

                                return new InvalidExpr(
                                        "Value `%s` was expected to be a number.".format(index.toString)
                                );
                        }

                        return new InvalidExpr(
                                "Value `%s` was expected to be an array.".format(array.toString)
                        );
                }

                case "Funky.ArrayLiteral":
                {
                        Expression[] arr;

                        foreach (ch; p.child.children)
                        {
                                arr ~= ch.toExpression.evaluate;
                        }

                        return new Array(arr);
                }

                case "Funky.ArraySlice":
                {
                        break;
                }

                case "Funky.AssignConstant":
                {
                        constant = true;
                        goto case;
                }

                case "Funky.AssignFunction", "Funky.AssignVariable":
                {
                        string varname = p.child.match;

                        if (varname in variables && variables[varname].constant)
                        {
                                return new InvalidExpr(
                                        "Attempting to assign to a constant `%s`.".format(varname)
                                );
                        }

                        Expression expr = p.children[1].toExpression;
                        if (cast(InvalidExpr) expr)
                        {
                                return expr;
                        }

                        variables[varname] = Variable(constant, expr);
                        constant = false;
                        return p.children[1].toExpression;
                }

                case "Funky.BooleanLiteral":
                {
                        return new Boolean(p.match.to!bool);
                }

                case "Funky.Concatenation":
                {
                        Expression[] values;

                        foreach (ch; p.children)
                        {
                                Expression expr = ch.toExpression;
                                if (cast(InvalidExpr) expr)
                                {
                                        return expr;
                                }
                                values ~= expr;
                        }

                        return new Concatenation(values);
                }

                case "Funky.Comparison":
                {
                        Expression[] compared;
                        string[] ops;

                        foreach (i, child; p.children)
                        {
                                // The odd indices belong to operators
                                if (i & 1)
                                {
                                        ops ~= child.match;
                                }
                                // and the even ones to expressions.
                                else
                                {
                                        compared ~= child.toExpression;
                                }
                        }

                        return new Comparison(compared, ops);
                }

                case "Funky.Conditional":
                {
                        auto condition = cast(Boolean) p.children[0].toExpression.evaluate;

                        if (!condition)
                        {
                                return new InvalidExpr(
                                        "The value `%s` used as the condition was expected to be boolean."
                                                .format(condition.toString)
                                );
                        }

                        auto thenExpr = p.children[1].toExpression.evaluate;
                        auto elseExpr = p.children[2].toExpression.evaluate;

                        return condition.value ? thenExpr : elseExpr;
                }

                case "Funky.Error":
                {
                        auto value = cast(Number) p.children[0].toExpression.evaluate;
                        auto error = cast(Number) p.children[1].toExpression.evaluate;

                        string notNumericError = "Value `%s` used in a range expression is not of numeric type.";
                        if (!value)
                        {
                                return new InvalidExpr(notNumericError.format(value));
                        }
                        if (!error)
                        {
                                return new InvalidExpr(notNumericError.format(error));
                        }

                        double v = value.value;
                        double e = error.value;
                        return new Range(v - e, v + e, true);
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
                        return new InvalidExpr("Identifier `%s` is unknown.".format(p.match));
                }

                case "Funky.Or", "Funky.And", "Funky.Xor":
                {
                        auto lhs = cast(Logical) p.child.toExpression;

                        if (!lhs)
                        {
                                return new InvalidExpr(
                                        "`%s` is not of a logical type."
                                                .format(p.child.match)
                                );
                        }

                        for (int i = 2; i < p.children.length; i += 2)
                        {
                                const(string) op = p.children[i - 1].match;
                                auto rhs = cast(Logical) p.children[i].toExpression;

                                if (!rhs)
                                {
                                        return new InvalidExpr(
                                                "`%s` is not of a logical type."
                                                        .format(p.children[i].match)
                                        );
                                }

                                final switch (op)
                                {
                                        case "|":
                                        {
                                                lhs = new LogicalBinary!"||"(lhs, rhs);
                                                break;
                                        }

                                        case "&":
                                        {
                                                lhs = new LogicalBinary!"&&"(lhs, rhs);
                                                break;
                                        }

                                        case "@":
                                        {
                                                lhs = new LogicalBinary!"^"(lhs, rhs);
                                                break;
                                        }
                                }
                        }

                        return lhs;
                }

                case "Funky.Not":
                {
                        auto rhs = cast(Logical) p.children[1].toExpression;

                        if (!rhs)
                        {
                                return new InvalidExpr(
                                        "`%s` is not of an arithmetic type.".format(p.children[1].match)
                                );
                        }

                        return new LogicalUnary!"!"(rhs);
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

                case "Funky.Range":
                {
                        auto lower = cast(Number) p.children[0].toExpression.evaluate;
                        auto upper = cast(Number) p.children[2].toExpression.evaluate;

                        string notNumericError = "Value `%s` used in a range expression is not of numeric type.";
                        if (!lower)
                        {
                                return new InvalidExpr(notNumericError.format(lower));
                        }
                        if (!upper)
                        {
                                return new InvalidExpr(notNumericError.format(upper));
                        }

                        if (p.children[1].match == "...")
                        {
                                return new Range(lower.value, upper.value, true);
                        }
                        return new Range(lower.value, upper.value);
                }

                case "Funky.StringLiteral":
                {
                        // Each StringLiteral has a StringContent child.
                        return new String(p.child.match);
                }

                default:
                {
                        return new InvalidExpr("Unrecognised value type `%s`".format(p.name));
                }
        }

        return new InvalidExpr("Unrecognised value type `%s`".format(p.name));
}