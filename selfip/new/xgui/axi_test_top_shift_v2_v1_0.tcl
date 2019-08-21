# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_AXIWIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_LITE_DWIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.C_ADDR_WIDTH { PARAM_VALUE.C_ADDR_WIDTH } {
	# Procedure called to update C_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_ADDR_WIDTH { PARAM_VALUE.C_ADDR_WIDTH } {
	# Procedure called to validate C_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_AXIWIDTH { PARAM_VALUE.C_AXIWIDTH } {
	# Procedure called to update C_AXIWIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_AXIWIDTH { PARAM_VALUE.C_AXIWIDTH } {
	# Procedure called to validate C_AXIWIDTH
	return true
}

proc update_PARAM_VALUE.C_LITE_DWIDTH { PARAM_VALUE.C_LITE_DWIDTH } {
	# Procedure called to update C_LITE_DWIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_LITE_DWIDTH { PARAM_VALUE.C_LITE_DWIDTH } {
	# Procedure called to validate C_LITE_DWIDTH
	return true
}


proc update_MODELPARAM_VALUE.C_AXIWIDTH { MODELPARAM_VALUE.C_AXIWIDTH PARAM_VALUE.C_AXIWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_AXIWIDTH}] ${MODELPARAM_VALUE.C_AXIWIDTH}
}

proc update_MODELPARAM_VALUE.C_ADDR_WIDTH { MODELPARAM_VALUE.C_ADDR_WIDTH PARAM_VALUE.C_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_LITE_DWIDTH { MODELPARAM_VALUE.C_LITE_DWIDTH PARAM_VALUE.C_LITE_DWIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_LITE_DWIDTH}] ${MODELPARAM_VALUE.C_LITE_DWIDTH}
}

