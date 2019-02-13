sim:
	iverilog -o test stack.v stack_tb.v && ./test && gtkwave dump.vcd

yosys:
	yosys -p 'read_verilog stack.v; proc; opt; memory; opt; hierarchy; opt; show -prefix output -format svg -colors 42 -viewer eog stack;'

deserializer:
	sby -f deserializer.sby

deserializer_rst:
	sby -f deserializer_rst.sby

serializer:
	sby -f serializer.sby

formal: deserializer deserializer_rst serializer
