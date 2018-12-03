== Constructs an object used as exit status.
EXIT STATUS << (error code, message) -> {
        error code <- error code,
        message <- message
}

STATUS SUCCESS << 0
STATUS FAILURE << 1

exit () -> EXIT STATUS (STATUS SUCCESS, "")
quit () -> exit ()