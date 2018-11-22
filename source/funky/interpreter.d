module funky.interpreter;

import arsd.terminal;

import funky.exception;
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

        Variable[string] globals;

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
                        try
                        {
                                Expression expr = p.toExpression((Variable[string]).init).evaluate;

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


private:


string match(ParseTree p)
{
        return p.matches[0];
}

ParseTree child(ParseTree p)
{
        return p.children[0];
}


Type process(Type : Expression)(ParseTree p, Variable[string] locals, Expression delegate(Type) process)
{
        auto expr = p.toExpression(locals).evaluate;

        if (auto val = cast(Type) expr)
        {
                return cast(Type) process(val).evaluate;
        }

        throw new InvalidTypeException!Type(expr.dataType, expr.toString);
}

package Expression toExpression(ParseTree p, Variable[string] locals)
{
        // For assignments.
        bool constant;

        final switch (p.name)
        {
                case "Funky.Sum", "Funky.Product", "Funky.Power":
                {
                        return p.children[0].process!(Arithmetic)(locals, (left)
                        {
                                for (int i = 2; i < p.children.length; i += 2)
                                {
                                        const(string) op = p.children[i - 1].match;
                                        left = cast(Arithmetic) p.children[i].process!(Arithmetic)(locals, (right)
                                        {
                                                Arithmetic aBinOp(string op)()
                                                {
                                                        return new ArithmeticBinary!op(left, right);
                                                }
                                                final switch (op)
                                                {
                                                        case "+": return aBinOp!"+";
                                                        case "-": return aBinOp!"-";
                                                        case "*": return aBinOp!"*";
                                                        case "/": return aBinOp!"/";
                                                        case "%": return aBinOp!"%";
                                                        case "^": return aBinOp!"^^";
                                                }
                                        });
                                }
                                return left;
                        });
                }

                case "Funky.Unary":
                {
                        const(string) op = p.children[0].match;
                        return p.children[1].process!(Arithmetic)(locals, (right)
                        {
                                // Unary `+` doesn't change the value.
                                return op == "-" ? new ArithmeticUnary!"-"(right) : right;
                        });
                }

                case "Funky.ArrayAccess":
                {
                        return p.children[0].process!(Array)(locals, (array)
                        {
                                return p.children[1].process!(Arithmetic)(locals, (index)
                                {
                                        return array[cast(int) index.value];
                                });
                        });
                }

                case "Funky.ArrayLiteral":
                {
                        Expression[] arr;

                        if (!p.children.empty) foreach (ref ch; p.child.children)
                        {
                                arr ~= ch.toExpression(locals).evaluate;
                        }

                        return new Array(arr);
                }

                case "Funky.ArraySlice":
                {
                        return p.children[0].process!(Array)(locals, (array)
                        {
                                return p.children[1].process!(Range)(locals, (range)
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
                                string varName = p.child.match;

                                Variable[string]* container = locals ? &locals : &globals;

                                if (varName in *container && (*container)[varName].constant)
                                {
                                        throw new ConstantMutationException(varName);
                                }

                                Expression expr = p.children[1].toExpression(locals);

                                (*container)[varName] = Variable(constant, expr);
                                constant = false;
                                return expr;
                        }

                        if (p.children[0].name == "Funky.ArrayAccess")
                        {
                                return p.children[0].children[0].process!(Array)(locals, (arr)
                                {
                                        return p.children[0].children[1].process!(Arithmetic)(locals, (index)
                                        {
                                                arr[cast(int) index.value] = p.children[1].toExpression(locals).evaluate;
                                                return arr;
                                        });
                                });
                        }
                        
                        if (p.children[0].name == "Funky.StructFieldAccess")
                        {
                                Expression expr = p.children[1].toExpression(locals).evaluate;
                                return p.children[0].children[0].process!(Struct)(locals, (str)
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

                        foreach (ref ch; p.children)
                        {
                                values ~= ch.toExpression(locals);
                        }

                        return new Concatenation(values);
                }

                case "Funky.Comparison":
                {
                        Expression[] compared;
                        string[] ops;

                        foreach (i, ref ch; p.children)
                        {
                                // The odd indices belong to operators
                                if (i & 1)
                                {
                                        ops ~= ch.match;
                                }
                                // and the even ones to expressions.
                                else
                                {
                                        compared ~= ch.toExpression(locals);
                                }
                        }

                        return new Comparison(compared, ops);
                }

                case "Funky.Conditional":
                {
                        return p.children[0].process!(Logical)(locals, (condition)
                        {
                                return condition.value ? p.children[1].toExpression(locals).evaluate
                                                       : p.children[2].toExpression(locals).evaluate;
                        });
                }

                case "Funky.Error":
                {
                        return p.children[0].process!(Arithmetic)(locals, (value)
                        {
                                return p.children[1].process!(Arithmetic)(locals, (error)
                                {
                                        const(double) v = value.value;
                                        const(double) e = error.value;
                                        return new Range(v - e, v + e, true);
                                });
                        });
                }

                case "Funky.FunctionCall":
                {
                        return p.children[0].process!(Function)(locals, (func)
                        {
                                if (p.children.length < 2)
                                {
                                        return func.call();
                                }
                                auto args = new Expression[p.children[1].children.length];

                                foreach (i, ref ch; p.children[1].children)
                                {
                                        args[i] = ch.toExpression(locals).evaluate;
                                }

                                return func.call(args);
                        });
                }

                case "Funky.FunctionLiteral":
                {
                        string[] args;
                        ParseTree[] localsCode;

                        int childN;
                        if (p.children[childN].name == "Funky.ArgumentDeclarations")
                        {
                                args.length = p.child.children.length; 
                                foreach (i, ref ch; p.child.children)
                                {
                                        args[i] = ch.match;
                                }
                                ++childN;
                        }
                        else if (p.children[childN].name == "Funky.Identifier")
                        {
                                args = [p.children[childN++].match];
                        }
                        if (p.children[childN].name == "Funky.FunctionLocals")
                        {
                                localsCode = p.children[childN].children;
                        }

                        return new Function(args, localsCode, p.children.back);
                }

                case "Funky.Identifier":
                {
                        const(string) name = p.match;

                        if (name in locals)
                        {
                                return locals[name].value;
                        }

                        if (name in globals)
                        {
                                return globals[name].value;
                        }

                        throw new UnknownIdentifierException(name);
                }

                case "Funky.Or", "Funky.And", "Funky.Xor":
                {
                        return p.children[0].process!(Logical)(locals, (left)
                        {
                                for (int i = 2; i < p.children.length; i += 2)
                                {
                                        const(string) op = p.children[i - 1].match;

                                        const(bool) lval = left.value;
                                        if ((op == "|" && !lval) || (op == "&" && lval) || op == "^")
                                        {
                                                left = cast(Logical) p.children[i].process!(Logical)(locals, (right)
                                                {
                                                        if (op == "|")
                                                        {
                                                                return new Boolean(lval || right.value);
                                                        }
                                                        if (op == "&")
                                                        {
                                                                return new Boolean(lval && right.value);
                                                        }
                                                        return new Boolean(lval ^ right.value);
                                                });
                                        }
                                        else
                                        {
                                                break;
                                        }
                                }
                                return left;
                        });
                }

                case "Funky.Not":
                {
                        return p.children[1].process!(Logical)(locals, (right)
                        {
                                return new Boolean(!right.value);
                        });
                }

                case "Funky.NumberLiteral":
                {
                        return new Number(p.match.to!double);
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
                                return p.children[1].process!(Arithmetic)(locals, (upper)
                                {
                                        return new Range(0, upper.value, p.children[0].match == "...");
                                });
                        }

                        // array[lower..]
                        return p.children[0].process!(Arithmetic)(locals, (lower)
                        {
                                return new Range(lower.value, -1, p.children[1].match == "...");
                        });
                }

                case "Funky.Range":
                {
                        return p.children[0].process!(Arithmetic)(locals, (lower)
                        {
                                return p.children[2].process!(Arithmetic)(locals, (upper)
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
                        foreach (ref ch; p.child.children)
                        {
                                string name = ch.children[0].match;
                                Expression value = ch.children[1].toExpression(locals).evaluate;

                                fields[name] = Variable(ch.child.name == "Funky.AssignConstant", value);
                        }
                        return new Struct("", fields);
                }

                case "Funky.StructFieldAccess":
                {
                        return p.children[0].process!(Struct)(locals, (str)
                        {
                                return str.field(p.children[1].match);
                        });
                }
        }

        return new String("Unrecognised value type `%s`".format(p.name));
}