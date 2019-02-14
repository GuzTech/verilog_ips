## verilog_ips
Various IPs implemented in Verilog

* stack.v - A circular stack
* deserializer.sv - A formally verified, parameterizable deserializer.
* deserializer_rst.sv - With a reset signal.
* serializer.sv - A formally verified, parameterizable serializer.
* serializer_rst.sv - With a reset signal.

## Formal verification
The deserializer, deserializer_rst, serializer, and serializer_rst IPs come with formal specifications. You need to install [SymbiYosys](https://symbiyosys.readthedocs.io/en/latest/quickstart.html) 
first. To check a specific IP, run `make <IP name>` or if you want to check all of them, run `make formal`.

## Status
The stack implementation has only been partially formally verified, and is being worked on.

## License
verilog_ips is free and open hardware and is licensed under the [ISC licence](http://en.wikipedia.org/wiki/ISC_license).
