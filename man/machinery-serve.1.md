
## serve — Serve A System Description Using A Web Server

### SYNOPSIS

`machinery serve` [-p PORT | --port=PORT] [-i IP | --ip=IP] NAME

`machinery` help serve


### DESCRIPTION

The `serve` command spawns a web server and serves a stored system description on
it.
By default the description is available from http://127.0.0.1:7585 but both the
IP address and the port can be configured using the according options.


### ARGUMENTS

  * `NAME` (required):
    Use specified system description.


### OPTIONS

  * `-p PORT`, `--port=PORT` (optional):
    Specify the port on which the web server will serve the system description: Default: 7585

  * `-i IP`, `--ip=IP` (optional):
    Specify the IP address on which the web server will be made available. Default: 127.0.0.1

### EXAMPLES

  * Serve the system description taken from the last inspection, saved as `earth`:

    $ `machinery` serve earth

  * Make the system description available to other machines on the network:

    $ `machinery` serve earth -i 10.10.100.123 -p 3000
