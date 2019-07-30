debImport "-f" "loadweights.v"
verdiDockWidgetDisplay -dock widgetDock_WelcomePage
verdiDockWidgetHide -dock widgetDock_WelcomePage
nsMsgSwitchTab -tab general
debImport "/media/cqiu/e/work/prj/AIPrj/sim/sim_cnna190717a/selfip/loadweights.v" \
          -path {/media/cqiu/e/work/prj/AIPrj/sim/sim_cnna190717a/selfip}
srcDeselectAll -win $_nTrace1
verdiWindowResize -win Verdi_1 "260" "90" "901" "700"
verdiWindowResize -win Verdi_1 "260" "90" "935" "700"
verdiWindowResize -win Verdi_1 "260" "90" "955" "700"
verdiWindowResize -win Verdi_1 "260" "90" "989" "700"
verdiWindowResize -win Verdi_1 "260" "90" "1019" "700"
verdiWindowResize -win Verdi_1 "260" "90" "1028" "700"
verdiWindowResize -win Verdi_1 "260" "90" "1031" "700"
srcDeselectAll -win $_nTrace1
debExit
