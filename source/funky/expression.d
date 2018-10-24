module funky.expression;


import std.algorithm.searching;
import std.conv;


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

mixin template ValueType(string Value, string BaseValue, Primitive, string[] unOps, string[] binOps)
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

                        ` ~ BaseValue ~ ` opUnary(string op)() const
                                if (unOps.canFind(op))
                        {
                                return new ` ~ BaseValue ~ `(mixin(op ~ "this.value"));
                        }

                        ` ~ BaseValue ~ ` opBinary(string op)(inout ` ~ Value ~ ` rhs) const
                                if (binOps.canFind(op))
                        {
                                return new ` ~ BaseValue ~ `(mixin("this.value" ~ op ~ "rhs.value"));
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

                static if (unOps.length)
                class ` ~ Value ~ `Unary(string OP) if (unOps.canFind(OP)) : ` ~ Value ~ `
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

                        ` ~ BaseValue ~ ` opUnary(string op)() const
                                if (unOps.canFind(op))
                        {
                                return new ` ~ BaseValue ~ `(mixin(op ~ "this.value"));
                        }

                        ` ~ BaseValue ~ ` opBinary(string op)(inout ` ~ Value ~ ` rhs) const
                                if (binOps.canFind(op))
                        {
                                return new ` ~ BaseValue ~ `(mixin("this.value" ~ op ~ "rhs.value"));
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

                static if (binOps.length)
                class ` ~ Value ~ `Binary(string OP) : ` ~ Value ~ `
                        if (binOps.canFind(OP))
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
                                                "((cast(` ~ BaseValue ~ `) this.lhs.evaluate)" ~ OP ~ "(cast(` ~ BaseValue ~ `) this.rhs.evaluate))"
                                        );
                                }
                        }

                        ` ~ BaseValue ~ ` opUnary(string op)() const
                                if (unOps.canFind(op))
                        {
                                return new ` ~ BaseValue ~ `(mixin(op ~ "this.value"));
                        }

                        ` ~ BaseValue ~ ` opBinary(string op)(inout ` ~ Value ~ ` rhs) const
                                if (binOps.canFind(op))
                        {
                                return new ` ~ BaseValue ~ `(mixin("this.value" ~ op ~ "rhs.value"));
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

mixin ValueType!("Arithmetic", "Number",  double, ["+", "-"], ["+", "-", "*", "/", "%", "^^"]);
mixin ValueType!("Logical",    "Boolean", bool,   ["!"],      ["||", "&&", "^"]);


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