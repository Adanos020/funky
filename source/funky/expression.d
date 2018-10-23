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


// ARITHMETIC

interface Arithmetic : Expression
{
        double value() const;
}

class Number : Arithmetic
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

        Number opUnary(string op)() const
                if (op == "+" || op == "-")
        {
                return new Number(mixin(op ~ "this.value"));
        }

        Number opBinary(string op)(inout Arithmetic rhs) const
                if (["+", "-", "*", "/", "%", "^^"].canFind(op))
        {
                return new Number(mixin("this.value" ~ op ~ "rhs.value"));
        }

        @property override double value() const
        {
                return this.val;
        }

        override string toString() const
        {
                return this.val.to!string;
        }

private:

        double val;
}

class ArithmeticUnary(string OP) : Arithmetic
        if (OP == "+" || OP == "-")
{
public:

        this(Arithmetic rhs)
        {
                this.rhs = rhs;
        }

        override Expression evaluate() const
        {
                return cast(Expression) mixin(OP ~ "(cast(Number) this.rhs)");
        }

        Number opUnary(string op)() const
                if (op == "+" || op == "-")
        {
                return new Number(mixin(op ~ "this.value"));
        }

        Number opBinary(string op)(inout Arithmetic rhs) const
                if (["+", "-", "*", "/", "%", "^^"].canFind(op))
        {
                return new Number(mixin("this.value" ~ op ~ "rhs.value"));
        }

        @property override double value() const
        {
                return (cast(Arithmetic) this.evaluate).value;
        }

        override string toString() const
        {
                return this.value.to!string;
        }

private:

        Arithmetic rhs;
}

class ArithmeticBinary(string OP) : Arithmetic
        if (["+", "-", "*", "/", "%", "^^"].canFind(OP))
{
public:

        this(Arithmetic lhs, Arithmetic rhs)
        {
                this.lhs = lhs;
                this.rhs = rhs;
        }

        override Expression evaluate() const
        {
                return cast(Expression) mixin(
                        "((cast(Number) this.lhs.evaluate)" ~ OP ~ "(cast(Number) this.rhs.evaluate))"
                );
        }

        Number opUnary(string op)() const
                if (op == "+" || op == "-")
        {
                return new Number(mixin(op ~ "this.value"));
        }

        Number opBinary(string op)(inout Arithmetic rhs) const
                if (["+", "-", "*", "/", "%", "^^"].canFind(op))
        {
                return new Number(mixin("this.value" ~ op ~ "rhs.value"));
        }

        @property override double value() const
        {
                return (cast(Arithmetic) this.evaluate).value;
        }

        override string toString() const
        {
                return this.value.to!string;
        }

private:

        Arithmetic lhs;
        Arithmetic rhs;
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