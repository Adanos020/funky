module funky.exception;

import std.exception;
import std.string;

class InvalidTypeException(ExpectedType) : Exception
{
        this(string actualType, string value)
        {
                super("Value `%s` was expected to be `%s`, not `%s`."
                        .format(value, ExpectedType.stringof, actualType));
        }
}

class ConstantMutationException : Exception
{
        this(string varName)
        {
                super("Attempting to assign to a constant `%s`.".format(varName));
        }
}

class UnknownIdentifierException : Exception
{
        this(string identifier)
        {
                super("Identifier `%s` is unknown.".format(identifier));
        }
}

class NoFieldException : Exception
{
        this(string fieldName)
        {
                super("Given struct has no field named `%s`.".format(fieldName));
        }
}

class OutOfArrayBoundsException : Exception
{
        this(long index)
        {
                super("Index %s is out of the array's bounds.".format(index));
        }
}

class NotConcatenatableException : Exception
{
        this(string value, string type)
        {
                super("Value `%s` is expected to be an Array or String, not %s.".format(value, type));
        }
}

class TooFewArgumentsException : Exception
{
        this(size_t given, size_t required)
        {
                super("Function called with %s arguments while %s is required.".format(given, required));
        }
}