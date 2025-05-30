openocd -f /usr/share/openocd/scripts/interface/cmsis-dap.cfg  -f /usr/share/openocd/scripts/target/rp2350.cfg -c "adapter speed 5000"  -c "program $1 verify reset exit"
