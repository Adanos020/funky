module funky.expression;


import std.algorithm.comparison;
import std.algorithm.searching;
import std.conv;
import std.string;


interface Expression
{
        Expression evaluate() const;
        string toString() const;
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
                                        return cast(int)(this.value - (cast(`~ BaseValue ~`) rhs.evaluate).value);
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
                                        return mixin("new ` ~ BaseValue ~ `(" ~ OP ~ "this.rhs.value)");                        
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
                                        return cast(int)(this.value - (cast(`~ BaseValue ~`) rhs.evaluate).value);
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
                                        return mixin("new ` ~ BaseValue ~ `(this.lhs.value" ~ OP ~ "this.rhs.value)");
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
                                        return cast(int)(this.value - (cast(`~ BaseValue ~`) rhs.evaluate).value);
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

        override bool opEquals(Object o)
        {
                auto rhs = cast(Number) o;
                if (!rhs) { return false; }

                double value = rhs.value;
                return this.lower <= value &&
                        (this.inclusive ? value <= this.upper : value < this.upper);
        }

        int opCmp()(inout Expression rhs)
        {
                if (!cast(Number) rhs)  { return -1; }
                if (this.opEquals(rhs)) { return 0; }

                double value = (cast(Number) rhs).value;
                if (value < this.lower) { return -1; }
                if (value > this.lower) { return 1; }
        }

        override string toString() const
        {
                return "%s%s%s".format(this.lower, this.inclusive ? "..." : "..", this.upper);
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

private:

        Expression[] compared;
        string[] ops;
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

private:

        string str;
}