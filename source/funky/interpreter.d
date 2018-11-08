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
        enum string fileExtension = ".hs";
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
                else if (p.name == "Funky.Code")
                {
                        foreach (ref child; p.children)
                        {
                                processTree(child);
                        }
                }
                else if (p.name == "Funky.Import")
                {
                        string path = p.children[0].match;
                        status = importModule(path);
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

Expression toExpressionHelper(Type : Expression, string badTypeErrorMsg)(ParseTree p, Expression delegate(Type) process)
{
        auto expr = p.toExpression.evaluate;

        if (auto inv = cast(InvalidExpr) expr)
        {
                return inv;
        }

        if (auto val = cast(Type) expr)
        {
                return process(val).evaluate;
        }
        return new InvalidExpr(badTypeErrorMsg.format(p.match, expr.dataType));
}

Expression toExpression(ParseTree p)
{
        // For assignments.
        bool constant;

        // Error messages.
        enum notArithmetic      = "Value `%s` was expected to be of arithmetic type, not %s.";
        enum notArray           = "Value `%s` was expected to be of array type, not %s.";
        enum notArithmeticRange = "Value `%s` used in a range expression was expected to be of arithmetic type, not %s.";
        enum notLogical         = "Value `%s` was expected to be of logical type, not %s.";
        enum notStruct          = "Value `%s` was expected to be of struct type, not %s.";

        enum wrongStructField       = "Struct `%s` has no field named `%s`.";
        enum wrongFunctionParamsNum = "Function `%s` called with %s parameters while expecting 0";

        final switch (p.name)
        {
                case "Funky.Sum", "Funky.Product", "Funky.Power":
                {
                        return p.children[0].toExpressionHelper!(Arithmetic, notArithmetic)((Arithmetic left)
                        {
                                for (int i = 2; i < p.children.length; i += 2)
                                {
                                        const(string) op = p.children[i - 1].match;
                                        left = cast(Arithmetic) p.children[i].toExpressionHelper!(Arithmetic, notArithmetic)((Arithmetic right)
                                        {
                                                switch (op)
                                                {
                                                        case "+": return cast(Arithmetic) new ArithmeticBinary!"+" (left, right);
                                                        case "-": return cast(Arithmetic) new ArithmeticBinary!"-" (left, right);
                                                        case "*": return cast(Arithmetic) new ArithmeticBinary!"*" (left, right);
                                                        case "/": return cast(Arithmetic) new ArithmeticBinary!"/" (left, right);
                                                        case "%": return cast(Arithmetic) new ArithmeticBinary!"%" (left, right);
                                                        default: break;
                                                }
                                                return cast(Arithmetic) new ArithmeticBinary!"^^"(left, right);
                                        });
                                }
                                return left;
                        });
                }

                case "Funky.Unary":
                {
                        const(string) op = p.children[0].match;
                        return p.children[1].toExpressionHelper!(Arithmetic, notArithmetic)((Arithmetic right)
                        {
                                // Unary `+` doesn't change the value.
                                return op == "-" ? new ArithmeticUnary!"-"(right) : right;
                        });
                }

                case "Funky.ArrayAccess":
                {
                        return p.children[0].toExpressionHelper!(Array, notArray)((Array array)
                        {
                                return p.children[1].toExpressionHelper!(Arithmetic, notArithmetic)((Arithmetic index)
                                {
                                        return array[cast(int) index.value];
                                });
                        });
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
                        return p.children[0].toExpressionHelper!(Array, notArray)((Array array)
                        {
                                return p.children[1].toExpressionHelper!(Range, "")((Range range)
                                {
                                        return array.slice(range);
                                });
                        });
                }

                case "Funky.AssignConstant":
                {
                        constant = true;
                        goto case;
                }

                case "Funky.AssignFunction", "Funky.AssignVariable":
                {
                        if (p.children[0].name == "Funky.Identifier")
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
                                return expr;
                        }
                        if (p.children[0].name == "Funky.ArrayAccess")
                        {

                        }
                        if (p.children[0].name == "Funky.StructFieldAccess")
                        {
                                Expression expr = p.children[1].toExpression;
                                return p.children[0].children[0].toExpressionHelper!(Struct, notStruct)((Struct str)
                                {
                                        return str.field(p.children[0].children[1].match, expr, constant);
                                });
                        }
                        break;
                }

                case "Funky.BooleanLiteral":
                {
                        return new Boolean(p.match.to!bool);
                }

                case "Funky.Class":
                {
                        break;
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
                        return p.children[0].toExpressionHelper!(Logical, notLogical)((Logical condition)
                        {
                                return condition.value ? p.children[1].toExpression.evaluate
                                                       : p.children[2].toExpression.evaluate;
                        });
                }

                case "Funky.Error":
                {
                        return p.children[0].toExpressionHelper!(Arithmetic, notArithmetic)((Arithmetic value)
                        {
                                return p.children[1].toExpressionHelper!(Arithmetic, notArithmetic)((Arithmetic error)
                                {
                                        const double v = value.value;
                                        const double e = error.value;
                                        return new Range(v - e, v + e, true);
                                });
                        });
                }

                case "Funky.FunctionCall":
                {
                        string funcName = p.children[0].match;
                        if (funcName == "exit" || funcName == "quit")
                        {
                                if (p.children.length == 1)
                                {
                                        return new Number(0);
                                }
                                else
                                {
                                        return new InvalidExpr(wrongFunctionParamsNum
                                                .format(funcName, p.children[1].children.length));
                                }
                        }
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
                        return p.children[0].toExpressionHelper!(Logical, notLogical)((Logical left)
                        {
                                for (int i = 2; i < p.children.length; i += 2)
                                {
                                        const(string) op = p.children[i - 1].match;

                                        left = cast(Logical) p.children[i].toExpressionHelper!(Logical, notLogical)((Logical right)
                                        {
                                                if (op == "|")
                                                {
                                                        return cast(Logical) new LogicalBinary!"||"(left, right);
                                                }
                                                if (op == "&")
                                                {
                                                        return cast(Logical) new LogicalBinary!"&&"(left, right);
                                                }
                                                return cast(Logical) new LogicalBinary!"^"(left, right);
                                        });
                                }
                                return left;
                        });
                }

                case "Funky.Not":
                {
                        return p.children[1].toExpressionHelper!(Logical, notLogical)((Logical right)
                        {
                                return new LogicalUnary!"!"(right);
                        });
                }

                case "Funky.NumberLiteral":
                {
                        return new Number(p.match == "infinity" ? double.infinity : p.match.to!double);
                }

                case "Funky.ArraySliceRange":
                {
                        // array[lower..upper]
                        if (p.children.length == 3)
                        {
                                goto case;
                        }

                        // array[..upper]
                        if (p.children[0].name == "Funky.OpRange")
                        {
                                return p.children[1].toExpressionHelper!(Arithmetic, notArithmeticRange)((Arithmetic upper)
                                {
                                        return new Range(0, upper.value, p.children[0].match == "...");
                                });
                        }

                        // array[lower..]
                        return p.children[0].toExpressionHelper!(Arithmetic, notArithmeticRange)((Arithmetic lower)
                        {
                                return new Range(lower.value, -1, p.children[0].match == "...");
                        });
                }

                case "Funky.Range":
                {
                        return p.children[0].toExpressionHelper!(Arithmetic, notArithmeticRange)((Arithmetic lower)
                        {
                                return p.children[2].toExpressionHelper!(Arithmetic, notArithmeticRange)((Arithmetic upper)
                                {
                                        return new Range(lower.value, upper.value, p.children[1].match == "...");
                                });
                        });
                }

                case "Funky.StringLiteral":
                {
                        // Each StringLiteral has a StringContent child.
                        return new String(p.child.match);
                }

                case "Funky.StructLiteral":
                {
                        Variable[string] fields;
                        foreach (ch; p.child.children)
                        {
                                string name = ch.children[0].match;
                                Expression value = ch.children[1].toExpression.evaluate;

                                if (auto inv = cast(InvalidExpr) value)
                                {
                                        return inv;
                                }

                                fields[name] = Variable(ch.child.name == "Funky.AssignConstant" , value);
                        }
                        return new Struct("", fields);
                }

                case "Funky.StructFieldAccess":
                {
                        return p.children[0].toExpressionHelper!(Struct, notStruct)((Struct str)
                        {
                                Expression field = str.field(p.children[1].match);

                                if (auto inv = cast(InvalidExpr) field)
                                {
                                        return new InvalidExpr(wrongStructField
                                                .format(p.children[0].match, p.children[1].match));
                                }

                                return field;
                        });
                }
        }

        return new InvalidExpr("Unrecognised value type `%s`".format(p.name));
}