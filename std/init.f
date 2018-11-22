Exit Status { error code, message <- "" }

STATUS SUCCESS << 0
STATUS FAILURE << 1

exit () -> Exit Status (STATUS SUCCESS)
quit () -> exit ()