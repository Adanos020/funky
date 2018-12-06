module funky.expression;


import funky.exception;
import funky.interpreter;
import funky.parser;

import pegged.grammar;

import std.algorithm.comparison;
import std.algorithm.iteration;
import std.algorithm.searching;
import std.conv;
import std.math;
import std.range;
import std.string;


// Used for storage.
struct Variable
{
        bool constant;
        Expression value;
}

// GENERAL EXPRESSION

interface Expression
{
        Expression evaluate() const;
        string toString() const;
        string dataType() const;
}

interface Logical : Expression
{
        bool value() const;
}

// ARRAY

class Array : Expression
{
public:

        this(Expression[] values = [])
        {
                this.values = values;
        }

        private size_t normalise(long index)
        {
                // Negative index values work like arr[length(arr) - index].
                const len = cast(long) this.values.length;
                return index < 0 ? len + index : index;
        }

        private bool inBounds(long index)
        {
                return index < this.values.length && index >= 0;
        }

        Expression opIndex()(long index)
        {
                index = this.normalise(index);
                if (!this.inBounds(index))
                {
                        throw new OutOfArrayBoundsException(index);
                }

                return this.values[index];
        }

        Expression opIndexAssign()(Expression value, long index)
        {
                index = this.normalise(index);
                if (!this.inBounds(index))
                {
                        throw new OutOfArrayBoundsException(index);
                }

                this.values[index] = value;
                return this;
        }

        Expression slice(Range sliceRange)
        {
                const(size_t) begin = clamp(
                        this.normalise(cast(long) sliceRange.lower),
                        0, this.values.length
                );

                const(size_t) end = clamp(
                        this.normalise(cast(long) sliceRange.upper)
                                + cast(size_t) sliceRange.inclusive,
                        0, this.values.length
                );

                if (begin > end)
                {
                        throw new WrongSliceRangeException(
                                sliceRange.lower,
                                sliceRange.upper,
                                sliceRange.inclusive
                        );
                }
                return new Array(this.values[begin .. end]);
        }

        Array opBinary(string op)(inout Expression rhs)
                if (op == "~")
        {
                auto lhs = new Array(this.values);

                if (auto arr = cast(Array) rhs)
                {
                        foreach (value; arr.values)
                        {
                                lhs = lhs ~ value;
                        }
                }
                else if (auto conc = cast(Concatenation) rhs)
                {
                        lhs = lhs ~ conc.evaluate;
                }
                else
                {
                        lhs.values ~= cast(Expression) rhs;
                }

                return lhs;
        }

        override bool opEquals(Object rhs) const
        {
                if (auto r = cast(Array) rhs)
                {
                        if (!this.values.isSameLength(r.values))
                        {
                                return false;
                        }
                        for (int i; i < this.values.length; ++i)
                        {
                                if (this.values[i] != r.values[i])
                                {
                                        return false;
                                }
                        }
                        return true;
                }
                return false;
        }

        override Expression evaluate() const
        {
                return cast(Expression) this;
        }

        override string toString() const
        {
                return this.values[].to!string;
        }

        override string dataType() const
        {
                return "Array";
        }

private:

        Expression[] values;
}

// BOOLEAN

class Boolean : Logical
{
public:

        this(bool val)
        {
                this.val = val;
        }

        override Expression evaluate() const
        {
                return cast(Expression) this;
        }

        @property bool value() const
        {
                return this.val;
        }

        string dataType() const
        {
                return "Boolean";
        }

        override bool opEquals(Object o) const
        {
                if (auto rhs = cast(Expression) o)
                {
                        if (auto res = cast(Boolean) rhs.evaluate)
                        {
                                return res.value == this.value;
                        }
                }
                return false;
        }

        int opCmp()(inout Expression rhs) const
        {
                if (!rhs || !cast(Boolean) rhs.evaluate) { return -1; }
                return cast(int) (this.value - (cast(Boolean) rhs.evaluate).value);
        }

        override string toString() const
        {
                return this.value.to!string;
        }

private:

        bool val;
}

// RELATIONAL OPERATIONS

class Comparison : Logical
{
public:

        this(Expression[] compared, string[] ops)
        in {
                assert(compared.length == ops.length + 1, "compared.length: %s, ops.length: %s"
                        .format(compared.length, ops.length));
        }
        body {
                this.compared = compared;
                this.ops = ops;
        }

        override Expression evaluate() const
        {
                auto result = new Boolean(true);

                for (int i; i < ops.length; ++i)
                {
                        const(string) op = ops[i];
                        auto lhs = compared[i].evaluate;
                        auto rhs = compared[i + 1].evaluate;

                        final switch (op)
                        {
                                case "=":
                                {
                                        result = new Boolean(result.value && lhs == rhs);
                                        break;
                                }

                                case "!=":
                                {
                                        result = new Boolean(result.value && lhs != rhs);
                                        break;
                                }

                                case ">":
                                {
                                        if (auto left = cast(Number) lhs)
                                        {
                                                if (auto right = cast(Number) rhs)
                                                {
                                                        result = new Boolean(result.value && left > right);
                                                        break;
                                                }
                                                throw new InvalidTypeException!Number(rhs.dataType, rhs.toString);
                                        }
                                        throw new InvalidTypeException!Number(lhs.dataType, lhs.toString);
                                }

                                case ">=":
                                {
                                        if (auto left = cast(Number) lhs)
                                        {
                                                if (auto right = cast(Number) rhs)
                                                {
                                                        result = new Boolean(result.value && left >= right);
                                                        break;
                                                }
                                                throw new InvalidTypeException!Number(rhs.dataType, rhs.toString);
                                        }
                                        throw new InvalidTypeException!Number(lhs.dataType, lhs.toString);
                                }

                                case "<":
                                {
                                        if (auto left = cast(Number) lhs)
                                        {
                                                if (auto right = cast(Number) rhs)
                                                {
                                                        result = new Boolean(result.value && left < right);
                                                        break;
                                                }
                                                throw new InvalidTypeException!Number(rhs.dataType, rhs.toString);
                                        }
                                        throw new InvalidTypeException!Number(lhs.dataType, lhs.toString);
                                }

                                case "<=":
                                {
                                        if (auto left = cast(Number) lhs)
                                        {
                                                if (auto right = cast(Number) rhs)
                                                {
                                                        result = new Boolean(result.value && left <= right);
                                                        break;
                                                }
                                                throw new InvalidTypeException!Number(rhs.dataType, rhs.toString);
                                        }
                                        throw new InvalidTypeException!Number(lhs.dataType, lhs.toString);
                                }
                        }

                        if (!result.value)
                        {
                                return result;
                        }
                }

                return result;
        }

        @property override bool value() const
        {
                // You must externally make sure that the evaluated value is a valid Boolean object.
                return (cast(Boolean) this.evaluate).value;
        }

        override string toString() const
        {
                return this.value.to!string;
        }

        override string dataType() const
        {
                return "Comparison";
        }

private:

        Expression[] compared;
        string[] ops;
}

// CONCATENATION

class Concatenation : Expression
{
public:

        this(Expression[] values)
        {
                this.values = values;
        }

        override Expression evaluate() const
        {
                if (cast(String) this.values[0].evaluate)
                {
                        auto str = new String("");
                        foreach (value; this.values)
                        {
                                str = str ~ value;
                        }
                        return str;
                }
                
                if (cast(Array) this.values[0].evaluate)
                {
                        auto arr = new Array();
                        foreach (value; this.values)
                        {
                                arr = arr ~ value.evaluate;
                        }
                        return arr;
                }

                throw new NotJoinableException(this.values[0].toString, this.values[0].dataType);
        }

        override string toString() const
        {
                return this.evaluate.toString;
        }

        override string dataType() const
        {
                return "Concatenation";
        }

private:

        Expression[] values;
}

// FUNCTION

class Function : Expression
{
public:

        this(string[] argNames, ParseTree[] localsCode, ParseTree code)
        {
                this.argNames   = argNames;
                this.localsCode = localsCode;
                this.code       = code;
        }

        Expression call(Variable[string] outerLocals, Expression[] args = [])
        {
                if (args.length != this.argNames.length)
                {
                        throw new TooFewArgumentsException(this, args.length, this.argNames.length);
                }

                Variable[string] locals;

                // Taking all outer locals that are actually used.
                foreach (key; outerLocals.byKey)
                {
                        if (this.argNames.canFind(key) || this.localsCode.any!(
                                (loc) => loc.matches[0] == key))
                        {
                                continue;
                        }

                        if (this.code.matches.canFind(key) || this.localsCode.any!(
                                (loc) => loc.matches[2 .. $].canFind(key)))
                        {       //                  \__  __/
                                //                     \/
                                // Skipping the local variable name and the assignment operator.
                                locals[key] = outerLocals[key];
                        }
                }

                foreach (i, arg; args)
                {
                        locals[argNames[i]] = Variable(false, arg);
                }

                foreach (loc; localsCode)
                {
                        // All of these are assignment expressions so they will
                        // be all assigned to the right container.
                        loc.toExpression(locals);
                }

                return new FunctionCall(locals, this.code).call.evaluate;
        }

        override Expression evaluate() const
        {
                return cast(Expression) this;
        }

        override string toString() const
        {
                string str;
                if (!this.localsCode.empty)
                {
                        str = " {\n    %-(%s,\n    %)\n}".format(
                                this.localsCode.map!(lc => lc.matches.join).array
                        );
                }
                
                return "(%-(%s, %))%s -> %s".format(argNames, str, code.matches.join);
        }

        override string dataType() const
        {
                return "Function";
        }

private:

        string[] argNames;
        ParseTree[] localsCode;
        ParseTree code;

private:

        class FunctionCall : Expression
        {
        public:

                this(Variable[string] locals, ParseTree code)
                {
                        this.locals = locals;
                        this.code = code;
                }

                Expression call()
                {
                        return this.code.toExpression(this.locals);
                }

                override Expression evaluate() const
                {
                        return cast(Expression) this;
                }

                override string toString() const
                {
                        return this.evaluate.toString;
                }

                override string dataType() const
                {
                        return "FunctionCall";
                }

        private:

                Variable[string] locals;
                ParseTree code;
        }
}

// NUMBER

class Number : Expression
{
public:

        this(double val)
        {
                this.val = val;
        }

        override Expression evaluate() const
        {
                return cast(Expression) this;
        }

        @property double value() const
        {
                return this.val;
        }

        string dataType() const
        {
                return "Number";
        }

        override bool opEquals(Object o) const
        {
                if (auto rhs = cast(Expression) o)
                {
                        if (auto res = cast(Number) rhs.evaluate)
                        {
                                return res.val == this.val;
                        }
                        if (auto res = cast(Range) rhs)
                        {
                                return res.contains(this.val);
                        }
                }
                return false;
        }

        int opCmp()(inout Expression rhs) const
        {
                if (!rhs || !cast(Number) rhs.evaluate) { return -1; }
                return cast(int) (this.val - (cast(Number) rhs.evaluate).val);
        }

        override string toString() const
        {
                if (this.val == this.val.floor)
                {
                        return "%d".format(cast(long) this.val);
                }
                return "%g".format(this.val);
        }

private:

        double val;
}

// NUMBER RANGES

class Range : Expression
{
public:

        this(double lower, double upper, bool inclusive = false)
        {
                this.lower = lower;
                this.upper = upper;
                this.inclusive = inclusive;
        }

        override Expression evaluate() const
        {
                return cast(Expression) this;
        }

        override bool opEquals(Object o) const
        {
                if (auto rhs = cast(Expression) o)
                {
                        if (auto range = cast(Range) rhs.evaluate)
                        {
                                return this.lower     == range.lower
                                    && this.upper     == range.upper
                                    && this.inclusive == range.inclusive;
                        }
                        if (auto number = cast(Number) rhs.evaluate)
                        {
                                return this.contains(number.value);
                        }
                }
                return false;
        }

        int opCmp()(inout Expression rhs) const
        {
                if (!cast(Number) rhs) { return -1; }

                double value = (cast(Number) rhs).value;
                if (this.lower <= value && this.contains(value))
                {
                        return 0;
                }
                if (value < this.lower) { return -1; }
                if (value > this.lower) { return 1; }
        }

        override string toString() const
        {
                return "%s%s%s".format(this.lower, this.inclusive ? "..." : "..", this.upper);
        }

        bool contains(double value) const
        {
                return this.inclusive ? value <= this.upper : value < this.upper
                        && value >= this.lower;
        }

        override string dataType() const
        {
                return "Range";
        }

private:

        double lower;
        double upper;
        bool inclusive;
}

// STRING

class String : Expression
{
public:

        this(string str)
        {
                this.str = str;
        }

        String opBinary(string op)(inout Expression rhs)
                if (op == "~")
        {
                return new String(this.str ~ rhs.toString);
        }

        override bool opEquals(Object o) const
        {
                if (!cast(Expression) o) { return false; }
                String rhs = cast(String) (cast(Expression) o).evaluate;
                return rhs && rhs.str == this.str;
        }

        int opCmp()(inout Expression rhs) const
        {
                if (!rhs || !cast(String) rhs.evaluate) { return -1; }
                return (cast(String) rhs.evaluate).str.opCmp(this.str);
        }

        override Expression evaluate() const
        {
                return cast(Expression) this;
        }

        override string toString() const
        {
                return this.str;
        }

        override string dataType() const
        {
                return "String";
        }

private:

        string str;
}

// STRUCT

class Struct : Expression
{
public:

        this(Variable[string] fields)
        {
                this.fields = fields;
        }

        Expression field(string name)
        {
                if (name !in this.fields)
                {
                        throw new NoFieldException(name);
                }
                return this.fields[name].value;
        }

        Expression field(string name, Expression newValue, bool constant = false)
        {
                if (name in this.fields && this.fields[name].constant)
                {
                        throw new ConstantMutationException(name);
                }
                this.fields[name] = Variable(constant, newValue);
                return newValue;
        }

        override bool opEquals(Object rhs) const
        {
                if (auto str = cast(Struct) rhs)
                {
                        return str.fields.length == this.fields.length
                            && str.fields.keys   == this.fields.keys
                            && str.fields.values == this.fields.values
                        ;
                }

                return false;
        }

        override Expression evaluate() const
        {
                return cast(Expression) this;
        }

        override string toString() const
        {
                string str = "{";
                if (this.fields.length)
                {
                        foreach (key; this.fields.byKey)
                        {
                                const(Variable) var = this.fields[key];
                                const(bool) isString = var.value.dataType == "String";

                                str ~= "%s %s %s; ".format(key, var.constant ? "<<" : "<-",
                                        isString ? `"` ~ var.value.toString ~ `"` : var.value.toString);
                        }

                        str.length -= 2;
                }

                str ~= "}";

                return str;
        }

        override string dataType() const
        {
                return "Struct";
        }

package:

        Variable[string] fields;
}


private Expression process(Type : Expression, size_t line = __LINE__)
                  (ParseTree p, Variable[string] locals, Expression delegate(Type) process)
{
        pragma(msg, "funky/expression.d, line %s: Generated expression processing for type %s."
                        .format(line, Type.stringof));

        auto expr = p.toExpression(locals).evaluate;

        if (auto val = cast(Type) expr)
        {
                return process(val).evaluate;
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
                        return p.children[0].process!Number(locals, (left)
                        {
                                for (int i = 2; i < p.children.length; i += 2)
                                {
                                        const(string) op = p.children[i - 1].match;
                                        left = cast(Number) p.children[i].process!Number(locals, (right)
                                        {
                                                Number aBinOp(string op)()
                                                {
                                                        return new Number(mixin("left.value" ~ op ~ "right.value"));
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
                        return p.children[1].process!Number(locals, (right)
                        {
                                // Unary `+` doesn't change the value.
                                return new Number(op == "-" ? -right.value : right.value);
                        });
                }

                case "Funky.ArrayAccess":
                {
                        return p.children[0].process!Array(locals, (array)
                        {
                                return p.children[1].process!Number(locals, (index)
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
                        return p.children[0].process!Array(locals, (array)
                        {
                                return p.children[1].process!Range(locals, (range)
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
                                return p.child.children[0].process!Array(locals, (arr)
                                {
                                        return p.children[0].children[1].process!Number(locals, (index)
                                        {
                                                arr[cast(int) index.value] = p.children[1].toExpression(locals).evaluate;
                                                return arr;
                                        });
                                });
                        }
                        
                        if (p.children[0].name == "Funky.StructFieldAccess")
                        {
                                Expression expr = p.children[1].toExpression(locals).evaluate;
                                return p.child.children[0].process!Struct(locals, (str)
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
                        return p.children[0].process!Logical(locals, (condition)
                        {
                                return condition.value ? p.children[1].toExpression(locals).evaluate
                                                       : p.children[2].toExpression(locals).evaluate;
                        });
                }

                case "Funky.Error":
                {
                        return p.children[0].process!Number(locals, (value)
                        {
                                return p.children[1].process!Number(locals, (error)
                                {
                                        const(double) v = value.value;
                                        const(double) e = error.value;
                                        return new Range(v - e, v + e, true);
                                });
                        });
                }

                case "Funky.FunctionCall":
                {
                        return p.children[0].process!Function(locals, (func)
                        {
                                if (p.children.length < 2)
                                {
                                        return func.call(locals);
                                }
                                auto args = new Expression[p.children[1].children.length];

                                foreach (i, ref ch; p.children[1].children)
                                {
                                        args[i] = ch.toExpression(locals).evaluate;
                                }

                                return func.call(locals, args);
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
                        return p.children[0].process!Logical(locals, (left)
                        {
                                for (int i = 2; i < p.children.length; i += 2)
                                {
                                        const(string) op = p.children[i - 1].match;

                                        const(bool) lval = left.value;
                                        if (((op == "|" || op == "!|") && !lval) ||
                                            ((op == "&" || op == "!&") && lval)  ||
                                             (op == "@" || op == "!@"))
                                        {
                                                left = cast(Logical) p.children[i].process!Logical(locals, (right)
                                                {
                                                        const(bool) rval = right.value;
                                                        const(bool) result = (op ==  "|") ?  (lval || rval)
                                                                           : (op == "!|") ? !(lval || rval)
                                                                           : (op ==  "&") ?  (lval && rval)
                                                                           : (op == "!&") ? !(lval && rval)
                                                                           : (op ==  "@") ?  (lval ^  rval)
                                                                           :                !(lval ^  rval);
                                                        return new Boolean(result);
                                                });
                                        }
                                        else
                                        {
                                                return op[0] == '!' ? new Boolean(!lval) : left;
                                        }
                                }
                                return left;
                        });
                }

                case "Funky.Not":
                {
                        return p.children[1].process!Logical(locals, (right)
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
                                return p.children[1].process!Number(locals, (upper)
                                {
                                        return new Range(0, upper.value, p.children[0].match == "...");
                                });
                        }

                        // array[lower..]
                        return p.children[0].process!Number(locals, (lower)
                        {
                                return new Range(lower.value, -1, p.children[1].match == "...");
                        });
                }

                case "Funky.Range":
                {
                        return p.children[0].process!Number(locals, (lower)
                        {
                                return p.children[2].process!Number(locals, (upper)
                                {
                                        return new Range(lower.value, upper.value, p.children[1].match == "...");
                                });
                        });
                }

                case "Funky.StringLiteral":
                {
                        // Each StringLiteral has a StringContent child.
                        return new String(p.children.length ? p.child.match : "");
                }

                case "Funky.StructLiteral":
                {
                        Variable[string] fields;

                        if (p.children.length) foreach (ref ch; p.child.children)
                        {
                                string name = ch.children[0].match;
                                Expression value = ch.children[1].toExpression(locals).evaluate;

                                fields[name] = Variable(ch.child.name == "Funky.AssignConstant", value);
                        }
                        return new Struct(fields);
                }

                case "Funky.StructFieldAccess":
                {
                        return p.children[0].process!Struct(locals, (str)
                        {
                                return str.field(p.children[1].match);
                        });
                }
        }

        return new String("Unrecognised value type `%s`".format(p.name));
}