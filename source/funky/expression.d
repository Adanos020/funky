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


// OPERATORS

class Unary(Value, BaseValue, Primitive, string OP, string[] unOps, string[] binOps) : Value
        if (unOps.canFind(OP))
{
public:

        this(Value rhs)
        {
                this.rhs = rhs;
        }

        override Expression evaluate() const
        {
                static if (is(Value == Logical))
                {
                        return mixin("new BaseValue(" ~ OP ~ "this.rhs.value)");                        
                }
                else
                {
                        return cast(Expression) mixin(OP ~ "(cast(BaseValue) this.rhs)");
                }
        }

        BaseValue opUnary(string op)() const
                if (unOps.canFind(op))
        {
                return new BaseValue(mixin(op ~ "this.value"));
        }

        BaseValue opBinary(string op)(inout Value rhs) const
                if (binOps.canFind(op))
        {
                return new BaseValue(mixin("this.value" ~ op ~ "rhs.value"));
        }

        @property override Primitive value() const
        {
                return (cast(Value) this.evaluate).value;
        }

        override string toString() const
        {
                return this.value.to!string;
        }

private:

        Value rhs;
}

class Binary(Value, BaseValue, Primitive, string OP, string[] unOps, string[] binOps) : Value
        if (binOps.canFind(OP))
{
public:

        this(Value lhs, Value rhs)
        {
                this.lhs = lhs;
                this.rhs = rhs;
        }

        override Expression evaluate() const
        {
                static if (is(Value == Logical))
                {
                        return mixin("new BaseValue(this.lhs.value" ~ OP ~ "this.rhs.value)");
                }
                else
                {
                        return cast(Expression) mixin(
                                "((cast(BaseValue) this.lhs.evaluate)" ~ OP ~ "(cast(BaseValue) this.rhs.evaluate))"
                        );
                }
        }

        BaseValue opUnary(string op)() const
                if (op == "+" || op == "-")
        {
                return new BaseValue(mixin(op ~ "this.value"));
        }

        BaseValue opBinary(string op)(inout Value rhs) const
                if (["+", "-", "*", "/", "%", "^^"].canFind(op))
        {
                return new BaseValue(mixin("this.value" ~ op ~ "rhs.value"));
        }

        @property override Primitive value() const
        {
                return (cast(Value) this.evaluate).value;
        }

        override string toString() const
        {
                return this.value.to!string;
        }

private:

        Value lhs;
        Value rhs;
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

alias ArithmeticUnary(string op)  =  Unary!(Arithmetic, Number, double, op, ["+", "-"], ["+", "-", "*", "/", "%", "^^"]);
alias ArithmeticBinary(string op) = Binary!(Arithmetic, Number, double, op, ["+", "-"], ["+", "-", "*", "/", "%", "^^"]);


// LOGICAL

interface Logical : Expression
{
        bool value() const;
}

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

        Boolean opUnary(string op)() const
                if (op == "!")
        {
                return new Boolean(!this.val);
        }

        Boolean opBinary(string op)(inout Logical rhs) const
                if (op == "|" || op == "&" || op == "^")
        {
                return new Boolean(mixin("this.value" ~ op ~ "rhs.value"));
        }

        override bool value() const
        {
                return this.val;
        }

        override string toString() const
        {
                return this.val.to!string;
        }

private:

        bool val;
}

alias LogicalUnary(string op)  =  Unary!(Logical, Boolean, bool, op, ["!"], ["||", "&&", "^"]);
alias LogicalBinary(string op) = Binary!(Logical, Boolean, bool, op, ["!"], ["||", "&&", "^"]);


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