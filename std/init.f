== Constructs an object used as exit status. If used as a printed value,
== the program will terminate with given `error code`.
==
== Returns: Object
EXIT STATUS << (error code, message) -> {
        error code <- error code,
        message <- message
}

STATUS SUCCESS << 0
STATUS FAILURE << 1

== Exits the program successfully.
==
== Returns: Object
==      EXIT STATUS with STATUS SUCCESS and empty message.
exit () -> EXIT STATUS (STATUS SUCCESS, "")

== Quits the program successfully.
==
== Returns: Object
==      EXIT STATUS with STATUS SUCCESS and empty message.
quit () -> exit ()