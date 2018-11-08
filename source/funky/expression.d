module funky.expression;


import std.algorithm.comparison;
import std.algorithm.searching;
import std.conv;
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

        string dataType() const
        {
                return "Invalid Expression";
        }

private:

        string whatsWrong;
}


// VALUES AND OPERATORS

mixin template ValueType(string Value, string BaseValue, Primitive, string[] BinOps = [], string[] UnOps = [])
{
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
                                if (!cast(Expression) o) { return false; }
                                auto rhs = cast(` ~ BaseValue ~ `) (cast(Expression) o).evaluate;
                                return rhs && rhs.value == this.value;
                        }

                        int opCmp()(inout Expression rhs) const
                        {
                                if (!rhs || !cast(`~ BaseValue ~`) rhs.evaluate) { return -1; }
                                static if (is(Primitive == double))
                                {
                                        return cast(int)(this.value - (cast(Number) rhs.evaluate).value);
                                }
                                else
                                {
                                        return (cast(`~ BaseValue ~`) rhs.evaluate).value.cmp(this.value);
                                }
                        }

                        @property override Primitive value() const
                        {
                                return this.val;
                        }

                        override string toString() const
                        {
                                static if (is(Primitive == string))
                                {
                                        return this.val;
                                }
                                else
                                {
                                        return this.val.to!string;
                                }
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
                                if (!cast(Expression) rhs) { return false; }
                                auto res = cast(` ~ BaseValue ~ `) (cast(Expression) rhs).evaluate;
                                return res && res.value == this.value;
                        }

                        override int opCmp()(inout Expression rhs) const
                        {
                                if (!rhs || !cast(`~ BaseValue ~`) rhs.evaluate) { return -1; }
                                static if (is(Primitive == double))
                                {
                                        return cast(int)(this.value - (cast(Number) rhs.evaluate).value);
                                }
                                else
                                {
                                        return (cast(`~ BaseValue ~`) rhs.evaluate).value.cmp(this.value);
                                }
                        }

                        @property override Primitive value() const
                        {
                                return (cast(` ~ Value ~ `) this.evaluate).value;
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
                                        else if (OP == "||")
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
                                if (!cast(Expression) rhs) { return false; }
                                auto res = cast(` ~ BaseValue ~ `) (cast(Expression) rhs).evaluate;
                                return res && res.value == this.value;
                        }

                        override int opCmp()(inout Expression rhs) const
                        {
                                if (!rhs || !cast(`~ BaseValue ~`) rhs.evaluate) { return -1; }
                                static if (is(Primitive == double))
                                {
                                        return cast(int)(this.value - (cast(Number) rhs.evaluate).value);
                                }
                                else
                                {
                                        return (cast(`~ BaseValue ~`) rhs.evaluate).value.cmp(this.value);
                                }
                        }

                        @property override Primitive value() const
                        {
                                return (cast(` ~ Value ~ `) this.evaluate).value;
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
                auto rhs = cast(Number) o;
                if (!rhs) { return false; }

                double value = rhs.value;
                return this.lower <= value && this.contains(value);
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
                return this.inclusive ? value <= this.upper : value < this.upper;
        }

        string dataType() const
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
                        auto lhs = cast(Expression) compared[i].evaluate;
                        auto rhs = cast(Expression) compared[i + 1].evaluate;

                        string notNumericError = "Value `%s` used in a comparison is not of numeric type.";
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
                                                return new InvalidExpr(notNumericError.format(lhs));
                                        }
                                        if (!cast(Number) rhs)
                                        {
                                                return new InvalidExpr(notNumericError.format(rhs));
                                        }
                                        result = new Boolean(result.value && cast(Number) lhs > cast(Number) rhs);
                                        break;
                                }

                                case ">=":
                                {
                                        if (!cast(Number) lhs)
                                        {
                                                return new InvalidExpr(notNumericError.format(lhs));
                                        }
                                        if (!cast(Number) rhs)
                                        {
                                                return new InvalidExpr(notNumericError.format(rhs));
                                        }
                                        result = new Boolean(result.value && cast(Number) lhs >= cast(Number) rhs);
                                        break;
                                }

                                case "<":
                                {
                                        if (!cast(Number) lhs)
                                        {
                                                return new InvalidExpr(notNumericError.format(lhs));
                                        }
                                        if (!cast(Number) rhs)
                                        {
                                                return new InvalidExpr(notNumericError.format(rhs));
                                        }
                                        result = new Boolean(result.value && cast(Number) lhs < cast(Number) rhs);
                                        break;
                                }

                                case "<=":
                                {
                                        if (!cast(Number) lhs)
                                        {
                                                return new InvalidExpr(notNumericError.format(lhs));
                                        }
                                        if (!cast(Number) rhs)
                                        {
                                                return new InvalidExpr(notNumericError.format(rhs));
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
                return (cast(Boolean) this.evaluate).value;
        }

        override string toString() const
        {
                return this.value.to!string;
        }

        string dataType() const
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

        string dataType() const
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

        private size_t normalise(int index)
        {
                // Negative index values work like arr[length(arr) - index].
                return (this.values.length + index % this.values.length) % this.values.length;
        }

        Expression opIndex()(int index)
        {
                return this.values[this.normalise(index)];
        }

        Array slice(Range sliceRange)
        {
                size_t begin = this.normalise(cast(int) sliceRange.lower);
                size_t end   = this.normalise(cast(int) sliceRange.upper + cast(int) sliceRange.inclusive);

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
                        if (this.values.isSameLength(r.values))
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

        string dataType() const
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

        string dataType() const
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
                return this.className ~ this.fields.to!string;
        }

        override string dataType() const
        {
                return "Struct";
        }

private:

        string className;
        Variable[string] fields;
}