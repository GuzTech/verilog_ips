sim:
	iverilog -o test stack.v stack_tb.v && ./test && gtkwave dump.vcd

yosys:
	yosys -p 'read_verilog stack.v; proc; opt; memory; opt; hierarchy; opt; show -prefix output -format svg -colors 42 -viewer eog stack;'

stack:
	sby -f stack.sby

deserializer:
	sby -f deserializer.sby

deserializer_rst:
	sby -f deserializer_rst.sby

serializer:
	sby -f serializer.sby

serializer_rst:
	sby -f serializer_rst.sby

formal: stack deserializer deserializer_rst serializer serializer_rst
