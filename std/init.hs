Status { code, msg <- "" }

STATUS SUCCESS << 0
STATUS FAILURE << 1

exit() -> Status(STATUS SUCCESS)
quit() -> exit()