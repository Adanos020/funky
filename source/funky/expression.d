module funky.expression;


import funky.interpreter;

import pegged.grammar;

import std.algorithm.comparison;
import std.algorithm.searching;
import std.conv;
import std.math;
import std.string;


// Used for storage.
struct Variable
{
        bool constant;
        Expression value;
}


interface Expression
{
        Expression evaluate() const;
        string toString() const;
        string dataType() const;
}


// ERROR

class InvalidExpr : Expression
{
public:

        this(string whatsWrong)
        {
                this.whatsWrong = whatsWrong;
        }

        override Expression evaluate() const
        {
                return cast(Expression) this;
        }

        override string toString() const
        {
                return this.whatsWrong;
        }

        override string dataType() const
        {
                return "Invalid Expression";
        }

private:

        string whatsWrong;
}


// VALUES AND OPERATORS

mixin template ValueType(string Value, string BaseValue, Primitive, string[] BinOps = [], string[] UnOps = [])
{
        enum COMMON_MEMBERS = `
                static if (UnOps.length)
                ` ~ BaseValue ~ ` opUnary(string op)() const
                        if (UnOps.canFind(op))
                {
                        return new ` ~ BaseValue ~ `(mixin(op ~ "this.value"));
                }

                static if (BinOps.length)
                ` ~ BaseValue ~ ` opBinary(string op)(inout ` ~ Value ~ ` rhs) const
                        if (BinOps.canFind(op))
                {
                        return new ` ~ BaseValue ~ `(mixin("this.value" ~ op ~ "rhs.value"));
                }

                override bool opEquals(Object o) const
                {
                        if (auto rhs = cast(Expression) o)
                        {
                                if (auto res = cast(` ~ BaseValue ~ `) rhs.evaluate)
                                {
                                        return res.value == this.value;
                                }
                                static if (Value == "Arithmetic")
                                {
                                        if (auto res = cast(Range) rhs)
                                        {
                                                return res.contains(this.value);
                                        }
                                }
                        }
                        return false;
                }

                int opCmp()(inout Expression rhs) const
                {
                        if (!rhs || !cast(` ~ BaseValue ~ `) rhs.evaluate) { return -1; }
                        static if (is(Primitive == double))
                        {
                                return cast(int)(this.value - (cast(Number) rhs.evaluate).value);
                        }
                        else
                        {
                                return (cast(`~ BaseValue ~`) rhs.evaluate).value.cmp(this.value);
                        }
                }

                override string toString() const
                {
                        static if (is(Primitive == string))
                        {
                                return this.value;
                        }
                        else
                        {
                                return this.value.to!string;
                        }
                }
        `;

        mixin(`
                interface ` ~ Value ~ ` : Expression
                {
                        Primitive value() const;
                }

                class ` ~ BaseValue ~ ` : ` ~ Value ~ `
                {
                public:

                        this(Primitive val)
                        {
                                this.val = val;
                        }

                        override Expression evaluate() const
                        {
                                return cast(Expression) this;
                        }

                        ` ~ COMMON_MEMBERS ~ `

                        @property override Primitive value() const
                        {
                                return this.val;
                        }

                        string dataType() const
                        {
                                return BaseValue;
                        }

                private:

                        Primitive val;
                }

                static if (UnOps.length)
                class ` ~ Value ~ `Unary(string OP) : ` ~ Value ~ `
                        if (UnOps.canFind(OP))
                {
                public:

                        this(` ~ Value ~ ` rhs)
                        {
                                this.rhs = rhs;
                        }

                        override Expression evaluate() const
                        {
                                static if (is(` ~ Value ~ ` == Logical))
                                {
                                        return mixin("new Boolean(" ~ OP ~ "this.rhs.value)");                        
                                }
                                else
                                {
                                        return cast(Expression) mixin(OP ~ "(cast(` ~ BaseValue ~ `) this.rhs)");
                                }
                        }

                        ` ~ COMMON_MEMBERS ~ `

                        @property override Primitive value() const
                        {
                                return (cast(` ~ Value ~ `) this.evaluate).value;
                        }

                        string dataType() const
                        {
                                return Value ~ " Unary";
                        }

                private:

                        ` ~ Value ~ ` rhs;
                }

                static if (BinOps.length)
                class ` ~ Value ~ `Binary(string OP) : ` ~ Value ~ `
                        if (BinOps.canFind(OP))
                {
                public:

                        this(` ~ Value ~ ` lhs, ` ~ Value ~ ` rhs)
                        {
                                this.lhs = lhs;
                                this.rhs = rhs;
                        }

                        override Expression evaluate() const
                        {
                                static if (is(` ~ Value ~ ` == Logical))
                                {
                                        static if (OP == "&&")
                                        {
                                                if (!this.lhs.value) return new Boolean(false);
                                                return new Boolean(this.rhs.value);
                                        }
                                        else static if (OP == "||")
                                        {
                                                if (this.lhs.value) return new Boolean(true);
                                                return new Boolean(this.rhs.value);
                                        }
                                        else // Only the XOR operator is left.
                                        {
                                                return new Boolean(this.lhs.value ^ this.rhs.value);
                                        }
                                }
                                else
                                {
                                        return cast(Expression) mixin(
                                                "((cast(` ~ BaseValue ~ `) this.lhs.evaluate)" ~ OP ~
                                                 "(cast(` ~ BaseValue ~ `) this.rhs.evaluate))"
                                        );
                                }
                        }

                        ` ~ COMMON_MEMBERS ~ `

                        @property override Primitive value() const
                        {
                                return (cast(` ~ Value ~ `) this.evaluate).value;
                        }

                        string dataType() const
                        {
                                return Value ~ " Binary";
                        }

                private:

                        ` ~ Value ~ ` lhs;
                        ` ~ Value ~ ` rhs;
                }
        `);
}

mixin ValueType!("Arithmetic", "Number",  double, ["+", "-", "*", "/", "%", "^^"], ["+", "-"]);
mixin ValueType!("Logical",    "Boolean", bool,   ["||", "&&", "^"],               ["!"]);


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

// RELATIONAL OPERATIONS

class Comparison : Logical
{
public:

        this(Expression[] compared, string[] ops)
        in {
                assert(compared.length == ops.length + 1,
                        "compared.length: %s, ops.length: %s"
                                .format(compared.length, ops.length)
                );
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
                        string op = ops[i];
                        auto lhs = compared[i].evaluate;
                        auto rhs = compared[i + 1].evaluate;

                        enum notArithmetic = "Value `%s` was expected to be an Arithmetic, not %s.";
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
                                        if (!cast(Number) lhs)
                                        {
                                                return new InvalidExpr(notArithmetic.format(lhs, lhs.dataType));
                                        }
                                        if (!cast(Number) rhs)
                                        {
                                                return new InvalidExpr(notArithmetic.format(rhs, rhs.dataType));
                                        }
                                        result = new Boolean(result.value && cast(Number) lhs > cast(Number) rhs);
                                        break;
                                }

                                case ">=":
                                {
                                        if (!cast(Number) lhs)
                                        {
                                                return new InvalidExpr(notArithmetic.format(lhs, lhs.dataType));
                                        }
                                        if (!cast(Number) rhs)
                                        {
                                                return new InvalidExpr(notArithmetic.format(rhs, rhs.dataType));
                                        }
                                        result = new Boolean(result.value && cast(Number) lhs >= cast(Number) rhs);
                                        break;
                                }

                                case "<":
                                {
                                        if (!cast(Number) lhs)
                                        {
                                                return new InvalidExpr(notArithmetic.format(lhs, lhs.dataType));
                                        }
                                        if (!cast(Number) rhs)
                                        {
                                                return new InvalidExpr(notArithmetic.format(rhs, rhs.dataType));
                                        }
                                        result = new Boolean(result.value && cast(Number) lhs < cast(Number) rhs);
                                        break;
                                }

                                case "<=":
                                {
                                        if (!cast(Number) lhs)
                                        {
                                                return new InvalidExpr(notArithmetic.format(lhs, lhs.dataType));
                                        }
                                        if (!cast(Number) rhs)
                                        {
                                                return new InvalidExpr(notArithmetic.format(rhs, rhs.dataType));
                                        }
                                        result = new Boolean(result.value && cast(Number) lhs <= cast(Number) rhs);
                                        break;
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
                // You must externally make sure that the evaluated value
                // is a valid Boolean object.
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

                return new InvalidExpr(
                        "Value `%s` is expected to be an array or string, not %s."
                                .format(this.values[0], this.values[0].dataType)
                );
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

        private Expression inBounds(long index)
        {
                if (index >= this.values.length || index < 0)
                {
                        return new InvalidExpr(
                                "Index %s is out of the array's bounds.".format(index)
                        );
                }
                return null;
        }

        Expression opIndex()(long index)
        {
                index = this.normalise(index);
                if (auto ib = this.inBounds(index))
                {
                        return ib;
                }

                return this.values[index];
        }

        Expression opIndexAssign()(Expression value, long index)
        {
                index = this.normalise(index);
                if (auto ib = this.inBounds(index))
                {
                        return ib;
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
                        return new Array(this.values[begin .. $] ~ this.values[0 .. end]);
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

        this(string className, Variable[string] fields)
        {
                this.className = className;
                this.fields = fields;
        }

        Expression field(string name)
        {
                if (name !in this.fields)
                {
                        return new InvalidExpr(name);
                }
                return this.fields[name].value;
        }

        Expression field(string name, Expression newValue, bool constant = false)
        {
                if (name in this.fields && this.fields[name].constant)
                {
                        return new InvalidExpr("Attempting to assign to a constant `%s`.".format(name));
                }
                this.fields[name] = Variable(constant, newValue);
                return newValue;
        }

        override bool opEquals(Object rhs) const
        {
                if (auto str = cast(Struct) rhs)
                {
                        return str.className == this.className
                            && str.fields.length == this.fields.length
                            && str.fields.keys == this.fields.keys
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

                foreach (key; this.fields.byKey)
                {
                        const(Variable) var = this.fields[key];
                        str ~= "%s %s %s, ".format(key, var.constant ? "<<" : "<-", var.value);
                }

                str.length -= 2;
                str ~= "}";

                return this.className ~ str.idup;
        }

        override string dataType() const
        {
                return "Struct";
        }

private:

        string className;
        Variable[string] fields;
}

// FUNCTION

class Function : Expression
{
public:

        this(string[] argNames, Variable[string] locals, ParseTree code)
        {
                this.argNames = argNames;
                this.locals   = locals;
                this.code     = code;
        }

        Expression call(Expression[] args = [])
        {
                if (args.length != this.argNames.length)
                {
                        return new InvalidExpr(
                                "Function called with %s arguments while %s is required."
                                        .format(args.length, this.argNames.length)
                        );
                }

                foreach (i, arg; args)
                {
                        this.locals[argNames[i]] = Variable(false, arg);
                }

                return code.toExpression(this.locals);
        }

        override Expression evaluate() const
        {
                return cast(Expression) this;
        }

        override string toString() const
        {
                return code.matches.join;
        }

        override string dataType() const
        {
                return "Function";
        }

private:

        string[] argNames;
        Variable[string] locals;
        ParseTree code;
}