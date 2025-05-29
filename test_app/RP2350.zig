//! Dual Cortex-M33 or Hazard3 processors at 150MHz 520kB on-chip SRAM, in 10 independent banks Extended low-power sleep states with optional SRAM retention: as low as 10uA DVDD 8kB of one-time-programmable storage (OTP) Up to 16MB of external QSPI flash/PSRAM via dedicated QSPI bus Additional 16MB flash/PSRAM accessible via optional second chip-select On-chip switched-mode power supply to generate core voltage Low-quiescent-current LDO mode can be enabled for sleep states 2x on-chip PLLs for internal or external clock generation GPIOs are 5V-tolerant (powered), and 3.3V-failsafe (unpowered) Security features: Optional boot signing, enforced by on-chip mask ROM, with key fingerprint in OTP Protected OTP storage for optional boot decryption key Global bus filtering based on Arm or RISC-V security/privilege levels Peripherals, GPIOs and DMA channels individually assignable to security domains Hardware mitigations for fault injection attacks Hardware SHA-256 accelerator Peripherals: 2x UARTs 2x SPI controllers 2x I2C controllers 24x PWM channels USB 1.1 controller and PHY, with host and device support 12x PIO state machines 1x HSTX peripheral
const microzig = @import("microzig");
const mmio = microzig.mmio;

pub const types = @import("types.zig");

pub const Interrupt = struct {
    name: [:0]const u8,
    index: i16,
    description: ?[:0]const u8,
};

pub const properties = struct {
    pub const @"cpu.deviceNumInterrupts" = "52";
    pub const @"cpu.dspPresent" = "1";
    pub const @"cpu.endian" = "little";
    pub const @"cpu.fpuPresent" = "true";
    pub const @"cpu.mpuPresent" = "true";
    pub const @"cpu.name" = "CM33";
    pub const @"cpu.nvicPrioBits" = "4";
    pub const @"cpu.revision" = "r1p0";
    pub const @"cpu.sauNumRegions" = "8";
    pub const @"cpu.vendorSystickConfig" = "false";
    pub const @"cpu.vtorPresent" = "1";
    pub const license =
        \\
        \\        Copyright (c) 2024 Raspberry Pi Ltd.
        \\
        \\        SPDX-License-Identifier: BSD-3-Clause
        \\    
    ;
};

pub const interrupts: []const Interrupt = &.{
    .{ .name = "NMI", .index = -14, .description = null },
    .{ .name = "HardFault", .index = -13, .description = null },
    .{ .name = "MemManageFault", .index = -12, .description = null },
    .{ .name = "BusFault", .index = -11, .description = null },
    .{ .name = "UsageFault", .index = -10, .description = null },
    .{ .name = "SecureFault", .index = -9, .description = null },
    .{ .name = "SVCall", .index = -5, .description = null },
    .{ .name = "DebugMonitor", .index = -4, .description = null },
    .{ .name = "PendSV", .index = -2, .description = null },
    .{ .name = "SysTick", .index = -1, .description = null },
    .{ .name = "TIMER0_IRQ_0", .index = 0, .description = null },
    .{ .name = "TIMER0_IRQ_1", .index = 1, .description = null },
    .{ .name = "TIMER0_IRQ_2", .index = 2, .description = null },
    .{ .name = "TIMER0_IRQ_3", .index = 3, .description = null },
    .{ .name = "TIMER1_IRQ_0", .index = 4, .description = null },
    .{ .name = "TIMER1_IRQ_1", .index = 5, .description = null },
    .{ .name = "TIMER1_IRQ_2", .index = 6, .description = null },
    .{ .name = "TIMER1_IRQ_3", .index = 7, .description = null },
    .{ .name = "PWM_IRQ_WRAP_0", .index = 8, .description = null },
    .{ .name = "PWM_IRQ_WRAP_1", .index = 9, .description = null },
    .{ .name = "DMA_IRQ_0", .index = 10, .description = null },
    .{ .name = "DMA_IRQ_1", .index = 11, .description = null },
    .{ .name = "DMA_IRQ_2", .index = 12, .description = null },
    .{ .name = "DMA_IRQ_3", .index = 13, .description = null },
    .{ .name = "USBCTRL_IRQ", .index = 14, .description = null },
    .{ .name = "PIO0_IRQ_0", .index = 15, .description = null },
    .{ .name = "PIO0_IRQ_1", .index = 16, .description = null },
    .{ .name = "PIO1_IRQ_0", .index = 17, .description = null },
    .{ .name = "PIO1_IRQ_1", .index = 18, .description = null },
    .{ .name = "PIO2_IRQ_0", .index = 19, .description = null },
    .{ .name = "PIO2_IRQ_1", .index = 20, .description = null },
    .{ .name = "IO_IRQ_BANK0", .index = 21, .description = null },
    .{ .name = "IO_IRQ_BANK0_NS", .index = 22, .description = null },
    .{ .name = "IO_IRQ_QSPI", .index = 23, .description = null },
    .{ .name = "IO_IRQ_QSPI_NS", .index = 24, .description = null },
    .{ .name = "SIO_IRQ_FIFO", .index = 25, .description = null },
    .{ .name = "SIO_IRQ_BELL", .index = 26, .description = null },
    .{ .name = "SIO_IRQ_FIFO_NS", .index = 27, .description = null },
    .{ .name = "SIO_IRQ_BELL_NS", .index = 28, .description = null },
    .{ .name = "SIO_IRQ_MTIMECMP", .index = 29, .description = null },
    .{ .name = "CLOCKS_IRQ", .index = 30, .description = null },
    .{ .name = "SPI0_IRQ", .index = 31, .description = null },
    .{ .name = "SPI1_IRQ", .index = 32, .description = null },
    .{ .name = "UART0_IRQ", .index = 33, .description = null },
    .{ .name = "UART1_IRQ", .index = 34, .description = null },
    .{ .name = "ADC_IRQ_FIFO", .index = 35, .description = null },
    .{ .name = "I2C0_IRQ", .index = 36, .description = null },
    .{ .name = "I2C1_IRQ", .index = 37, .description = null },
    .{ .name = "OTP_IRQ", .index = 38, .description = null },
    .{ .name = "TRNG_IRQ", .index = 39, .description = null },
    .{ .name = "PROC0_IRQ_CTI", .index = 40, .description = null },
    .{ .name = "PROC1_IRQ_CTI", .index = 41, .description = null },
    .{ .name = "PLL_SYS_IRQ", .index = 42, .description = null },
    .{ .name = "PLL_USB_IRQ", .index = 43, .description = null },
    .{ .name = "POWMAN_IRQ_POW", .index = 44, .description = null },
    .{ .name = "POWMAN_IRQ_TIMER", .index = 45, .description = null },
    .{ .name = "SPAREIRQ_IRQ_0", .index = 46, .description = null },
    .{ .name = "SPAREIRQ_IRQ_1", .index = 47, .description = "Spare interrupt 1 (triggered only by software)" },
    .{ .name = "SPAREIRQ_IRQ_2", .index = 48, .description = "Spare interrupt 2 (triggered only by software)" },
    .{ .name = "SPAREIRQ_IRQ_3", .index = 49, .description = "Spare interrupt 3 (triggered only by software)" },
    .{ .name = "SPAREIRQ_IRQ_4", .index = 50, .description = "Spare interrupt 4 (triggered only by software)" },
    .{ .name = "SPAREIRQ_IRQ_5", .index = 51, .description = "Spare interrupt 5 (triggered only by software)" },
};

pub const VectorTable = extern struct {
    const Handler = microzig.interrupt.Handler;
    const unhandled = microzig.interrupt.unhandled;

    initial_stack_pointer: u32,
    Reset: Handler,
    NMI: Handler = unhandled,
    HardFault: Handler = unhandled,
    MemManageFault: Handler = unhandled,
    BusFault: Handler = unhandled,
    UsageFault: Handler = unhandled,
    SecureFault: Handler = unhandled,
    reserved6: [3]u32 = undefined,
    SVCall: Handler = unhandled,
    DebugMonitor: Handler = unhandled,
    reserved11: [1]u32 = undefined,
    PendSV: Handler = unhandled,
    SysTick: Handler = unhandled,
    TIMER0_IRQ_0: Handler = unhandled,
    TIMER0_IRQ_1: Handler = unhandled,
    TIMER0_IRQ_2: Handler = unhandled,
    TIMER0_IRQ_3: Handler = unhandled,
    TIMER1_IRQ_0: Handler = unhandled,
    TIMER1_IRQ_1: Handler = unhandled,
    TIMER1_IRQ_2: Handler = unhandled,
    TIMER1_IRQ_3: Handler = unhandled,
    PWM_IRQ_WRAP_0: Handler = unhandled,
    PWM_IRQ_WRAP_1: Handler = unhandled,
    DMA_IRQ_0: Handler = unhandled,
    DMA_IRQ_1: Handler = unhandled,
    DMA_IRQ_2: Handler = unhandled,
    DMA_IRQ_3: Handler = unhandled,
    USBCTRL_IRQ: Handler = unhandled,
    PIO0_IRQ_0: Handler = unhandled,
    PIO0_IRQ_1: Handler = unhandled,
    PIO1_IRQ_0: Handler = unhandled,
    PIO1_IRQ_1: Handler = unhandled,
    PIO2_IRQ_0: Handler = unhandled,
    PIO2_IRQ_1: Handler = unhandled,
    IO_IRQ_BANK0: Handler = unhandled,
    IO_IRQ_BANK0_NS: Handler = unhandled,
    IO_IRQ_QSPI: Handler = unhandled,
    IO_IRQ_QSPI_NS: Handler = unhandled,
    SIO_IRQ_FIFO: Handler = unhandled,
    SIO_IRQ_BELL: Handler = unhandled,
    SIO_IRQ_FIFO_NS: Handler = unhandled,
    SIO_IRQ_BELL_NS: Handler = unhandled,
    SIO_IRQ_MTIMECMP: Handler = unhandled,
    CLOCKS_IRQ: Handler = unhandled,
    SPI0_IRQ: Handler = unhandled,
    SPI1_IRQ: Handler = unhandled,
    UART0_IRQ: Handler = unhandled,
    UART1_IRQ: Handler = unhandled,
    ADC_IRQ_FIFO: Handler = unhandled,
    I2C0_IRQ: Handler = unhandled,
    I2C1_IRQ: Handler = unhandled,
    OTP_IRQ: Handler = unhandled,
    TRNG_IRQ: Handler = unhandled,
    PROC0_IRQ_CTI: Handler = unhandled,
    PROC1_IRQ_CTI: Handler = unhandled,
    PLL_SYS_IRQ: Handler = unhandled,
    PLL_USB_IRQ: Handler = unhandled,
    POWMAN_IRQ_POW: Handler = unhandled,
    POWMAN_IRQ_TIMER: Handler = unhandled,
    SPAREIRQ_IRQ_0: Handler = unhandled,
    /// Spare interrupt 1 (triggered only by software)
    SPAREIRQ_IRQ_1: Handler = unhandled,
    /// Spare interrupt 2 (triggered only by software)
    SPAREIRQ_IRQ_2: Handler = unhandled,
    /// Spare interrupt 3 (triggered only by software)
    SPAREIRQ_IRQ_3: Handler = unhandled,
    /// Spare interrupt 4 (triggered only by software)
    SPAREIRQ_IRQ_4: Handler = unhandled,
    /// Spare interrupt 5 (triggered only by software)
    SPAREIRQ_IRQ_5: Handler = unhandled,
};

pub const peripherals = struct {
    pub const SYSINFO: *volatile types.peripherals.SYSINFO = @ptrFromInt(0x40000000);
    /// Register block for various chip control signals
    pub const SYSCFG: *volatile types.peripherals.SYSCFG = @ptrFromInt(0x40008000);
    pub const CLOCKS: *volatile types.peripherals.CLOCKS = @ptrFromInt(0x40010000);
    pub const PSM: *volatile types.peripherals.PSM = @ptrFromInt(0x40018000);
    pub const RESETS: *volatile types.peripherals.RESETS = @ptrFromInt(0x40020000);
    pub const IO_BANK0: *volatile types.peripherals.IO_BANK0 = @ptrFromInt(0x40028000);
    pub const IO_QSPI: *volatile types.peripherals.IO_QSPI = @ptrFromInt(0x40030000);
    pub const PADS_BANK0: *volatile types.peripherals.PADS_BANK0 = @ptrFromInt(0x40038000);
    pub const PADS_QSPI: *volatile types.peripherals.PADS_QSPI = @ptrFromInt(0x40040000);
    /// Controls the crystal oscillator
    pub const XOSC: *volatile types.peripherals.XOSC = @ptrFromInt(0x40048000);
    pub const PLL_SYS: *volatile types.peripherals.PLL_SYS = @ptrFromInt(0x40050000);
    pub const PLL_USB: *volatile types.peripherals.PLL_SYS = @ptrFromInt(0x40058000);
    /// Hardware access control registers
    pub const ACCESSCTRL: *volatile types.peripherals.ACCESSCTRL = @ptrFromInt(0x40060000);
    /// Register block for busfabric control signals and performance counters
    pub const BUSCTRL: *volatile types.peripherals.BUSCTRL = @ptrFromInt(0x40068000);
    pub const UART0: *volatile types.peripherals.UART0 = @ptrFromInt(0x40070000);
    pub const UART1: *volatile types.peripherals.UART0 = @ptrFromInt(0x40078000);
    pub const SPI0: *volatile types.peripherals.SPI0 = @ptrFromInt(0x40080000);
    pub const SPI1: *volatile types.peripherals.SPI0 = @ptrFromInt(0x40088000);
    /// DW_apb_i2c address block List of configuration constants for the Synopsys I2C hardware (you may see references to these in I2C register header; these are *fixed* values, set at hardware design time): IC_ULTRA_FAST_MODE ................ 0x0 IC_UFM_TBUF_CNT_DEFAULT ........... 0x8 IC_UFM_SCL_LOW_COUNT .............. 0x0008 IC_UFM_SCL_HIGH_COUNT ............. 0x0006 IC_TX_TL .......................... 0x0 IC_TX_CMD_BLOCK ................... 0x1 IC_HAS_DMA ........................ 0x1 IC_HAS_ASYNC_FIFO ................. 0x0 IC_SMBUS_ARP ...................... 0x0 IC_FIRST_DATA_BYTE_STATUS ......... 0x1 IC_INTR_IO ........................ 0x1 IC_MASTER_MODE .................... 0x1 IC_DEFAULT_ACK_GENERAL_CALL ....... 0x1 IC_INTR_POL ....................... 0x1 IC_OPTIONAL_SAR ................... 0x0 IC_DEFAULT_TAR_SLAVE_ADDR ......... 0x055 IC_DEFAULT_SLAVE_ADDR ............. 0x055 IC_DEFAULT_HS_SPKLEN .............. 0x1 IC_FS_SCL_HIGH_COUNT .............. 0x0006 IC_HS_SCL_LOW_COUNT ............... 0x0008 IC_DEVICE_ID_VALUE ................ 0x0 IC_10BITADDR_MASTER ............... 0x0 IC_CLK_FREQ_OPTIMIZATION .......... 0x0 IC_DEFAULT_FS_SPKLEN .............. 0x7 IC_ADD_ENCODED_PARAMS ............. 0x0 IC_DEFAULT_SDA_HOLD ............... 0x000001 IC_DEFAULT_SDA_SETUP .............. 0x64 IC_AVOID_RX_FIFO_FLUSH_ON_TX_ABRT . 0x0 IC_CLOCK_PERIOD ................... 100 IC_EMPTYFIFO_HOLD_MASTER_EN ....... 1 IC_RESTART_EN ..................... 0x1 IC_TX_CMD_BLOCK_DEFAULT ........... 0x0 IC_BUS_CLEAR_FEATURE .............. 0x0 IC_CAP_LOADING .................... 100 IC_FS_SCL_LOW_COUNT ............... 0x000d APB_DATA_WIDTH .................... 32 IC_SDA_STUCK_TIMEOUT_DEFAULT ...... 0xffffffff IC_SLV_DATA_NACK_ONLY ............. 0x1 IC_10BITADDR_SLAVE ................ 0x0 IC_CLK_TYPE ....................... 0x0 IC_SMBUS_UDID_MSB ................. 0x0 IC_SMBUS_SUSPEND_ALERT ............ 0x0 IC_HS_SCL_HIGH_COUNT .............. 0x0006 IC_SLV_RESTART_DET_EN ............. 0x1 IC_SMBUS .......................... 0x0 IC_OPTIONAL_SAR_DEFAULT ........... 0x0 IC_PERSISTANT_SLV_ADDR_DEFAULT .... 0x0 IC_USE_COUNTS ..................... 0x0 IC_RX_BUFFER_DEPTH ................ 16 IC_SCL_STUCK_TIMEOUT_DEFAULT ...... 0xffffffff IC_RX_FULL_HLD_BUS_EN ............. 0x1 IC_SLAVE_DISABLE .................. 0x1 IC_RX_TL .......................... 0x0 IC_DEVICE_ID ...................... 0x0 IC_HC_COUNT_VALUES ................ 0x0 I2C_DYNAMIC_TAR_UPDATE ............ 0 IC_SMBUS_CLK_LOW_MEXT_DEFAULT ..... 0xffffffff IC_SMBUS_CLK_LOW_SEXT_DEFAULT ..... 0xffffffff IC_HS_MASTER_CODE ................. 0x1 IC_SMBUS_RST_IDLE_CNT_DEFAULT ..... 0xffff IC_SMBUS_UDID_LSB_DEFAULT ......... 0xffffffff IC_SS_SCL_HIGH_COUNT .............. 0x0028 IC_SS_SCL_LOW_COUNT ............... 0x002f IC_MAX_SPEED_MODE ................. 0x2 IC_STAT_FOR_CLK_STRETCH ........... 0x0 IC_STOP_DET_IF_MASTER_ACTIVE ...... 0x0 IC_DEFAULT_UFM_SPKLEN ............. 0x1 IC_TX_BUFFER_DEPTH ................ 16
    pub const I2C0: *volatile types.peripherals.I2C0 = @ptrFromInt(0x40090000);
    /// DW_apb_i2c address block List of configuration constants for the Synopsys I2C hardware (you may see references to these in I2C register header; these are *fixed* values, set at hardware design time): IC_ULTRA_FAST_MODE ................ 0x0 IC_UFM_TBUF_CNT_DEFAULT ........... 0x8 IC_UFM_SCL_LOW_COUNT .............. 0x0008 IC_UFM_SCL_HIGH_COUNT ............. 0x0006 IC_TX_TL .......................... 0x0 IC_TX_CMD_BLOCK ................... 0x1 IC_HAS_DMA ........................ 0x1 IC_HAS_ASYNC_FIFO ................. 0x0 IC_SMBUS_ARP ...................... 0x0 IC_FIRST_DATA_BYTE_STATUS ......... 0x1 IC_INTR_IO ........................ 0x1 IC_MASTER_MODE .................... 0x1 IC_DEFAULT_ACK_GENERAL_CALL ....... 0x1 IC_INTR_POL ....................... 0x1 IC_OPTIONAL_SAR ................... 0x0 IC_DEFAULT_TAR_SLAVE_ADDR ......... 0x055 IC_DEFAULT_SLAVE_ADDR ............. 0x055 IC_DEFAULT_HS_SPKLEN .............. 0x1 IC_FS_SCL_HIGH_COUNT .............. 0x0006 IC_HS_SCL_LOW_COUNT ............... 0x0008 IC_DEVICE_ID_VALUE ................ 0x0 IC_10BITADDR_MASTER ............... 0x0 IC_CLK_FREQ_OPTIMIZATION .......... 0x0 IC_DEFAULT_FS_SPKLEN .............. 0x7 IC_ADD_ENCODED_PARAMS ............. 0x0 IC_DEFAULT_SDA_HOLD ............... 0x000001 IC_DEFAULT_SDA_SETUP .............. 0x64 IC_AVOID_RX_FIFO_FLUSH_ON_TX_ABRT . 0x0 IC_CLOCK_PERIOD ................... 100 IC_EMPTYFIFO_HOLD_MASTER_EN ....... 1 IC_RESTART_EN ..................... 0x1 IC_TX_CMD_BLOCK_DEFAULT ........... 0x0 IC_BUS_CLEAR_FEATURE .............. 0x0 IC_CAP_LOADING .................... 100 IC_FS_SCL_LOW_COUNT ............... 0x000d APB_DATA_WIDTH .................... 32 IC_SDA_STUCK_TIMEOUT_DEFAULT ...... 0xffffffff IC_SLV_DATA_NACK_ONLY ............. 0x1 IC_10BITADDR_SLAVE ................ 0x0 IC_CLK_TYPE ....................... 0x0 IC_SMBUS_UDID_MSB ................. 0x0 IC_SMBUS_SUSPEND_ALERT ............ 0x0 IC_HS_SCL_HIGH_COUNT .............. 0x0006 IC_SLV_RESTART_DET_EN ............. 0x1 IC_SMBUS .......................... 0x0 IC_OPTIONAL_SAR_DEFAULT ........... 0x0 IC_PERSISTANT_SLV_ADDR_DEFAULT .... 0x0 IC_USE_COUNTS ..................... 0x0 IC_RX_BUFFER_DEPTH ................ 16 IC_SCL_STUCK_TIMEOUT_DEFAULT ...... 0xffffffff IC_RX_FULL_HLD_BUS_EN ............. 0x1 IC_SLAVE_DISABLE .................. 0x1 IC_RX_TL .......................... 0x0 IC_DEVICE_ID ...................... 0x0 IC_HC_COUNT_VALUES ................ 0x0 I2C_DYNAMIC_TAR_UPDATE ............ 0 IC_SMBUS_CLK_LOW_MEXT_DEFAULT ..... 0xffffffff IC_SMBUS_CLK_LOW_SEXT_DEFAULT ..... 0xffffffff IC_HS_MASTER_CODE ................. 0x1 IC_SMBUS_RST_IDLE_CNT_DEFAULT ..... 0xffff IC_SMBUS_UDID_LSB_DEFAULT ......... 0xffffffff IC_SS_SCL_HIGH_COUNT .............. 0x0028 IC_SS_SCL_LOW_COUNT ............... 0x002f IC_MAX_SPEED_MODE ................. 0x2 IC_STAT_FOR_CLK_STRETCH ........... 0x0 IC_STOP_DET_IF_MASTER_ACTIVE ...... 0x0 IC_DEFAULT_UFM_SPKLEN ............. 0x1 IC_TX_BUFFER_DEPTH ................ 16
    pub const I2C1: *volatile types.peripherals.I2C0 = @ptrFromInt(0x40098000);
    /// Control and data interface to SAR ADC
    pub const ADC: *volatile types.peripherals.ADC = @ptrFromInt(0x400a0000);
    /// Simple PWM
    pub const PWM: *volatile types.peripherals.PWM = @ptrFromInt(0x400a8000);
    /// Controls time and alarms time is a 64 bit value indicating the time since power-on timeh is the top 32 bits of time & timel is the bottom 32 bits to change time write to timelw before timehw to read time read from timelr before timehr An alarm is set by setting alarm_enable and writing to the corresponding alarm register When an alarm is pending, the corresponding alarm_running signal will be high An alarm can be cancelled before it has finished by clearing the alarm_enable When an alarm fires, the corresponding alarm_irq is set and alarm_running is cleared To clear the interrupt write a 1 to the corresponding alarm_irq The timer can be locked to prevent writing
    pub const TIMER0: *volatile types.peripherals.TIMER0 = @ptrFromInt(0x400b0000);
    /// Controls time and alarms time is a 64 bit value indicating the time since power-on timeh is the top 32 bits of time & timel is the bottom 32 bits to change time write to timelw before timehw to read time read from timelr before timehr An alarm is set by setting alarm_enable and writing to the corresponding alarm register When an alarm is pending, the corresponding alarm_running signal will be high An alarm can be cancelled before it has finished by clearing the alarm_enable When an alarm fires, the corresponding alarm_irq is set and alarm_running is cleared To clear the interrupt write a 1 to the corresponding alarm_irq The timer can be locked to prevent writing
    pub const TIMER1: *volatile types.peripherals.TIMER0 = @ptrFromInt(0x400b8000);
    /// Control interface to HSTX. For FIFO write access and status, see the HSTX_FIFO register block.
    pub const HSTX_CTRL: *volatile types.peripherals.HSTX_CTRL = @ptrFromInt(0x400c0000);
    /// QSPI flash execute-in-place block
    pub const XIP_CTRL: *volatile types.peripherals.XIP_CTRL = @ptrFromInt(0x400c8000);
    /// QSPI Memory Interface. Provides a memory-mapped interface to up to two SPI/DSPI/QSPI flash or PSRAM devices. Also provides a serial interface for programming and configuration of the external device.
    pub const QMI: *volatile types.peripherals.QMI = @ptrFromInt(0x400d0000);
    pub const WATCHDOG: *volatile types.peripherals.WATCHDOG = @ptrFromInt(0x400d8000);
    /// Additional registers mapped adjacent to the bootram, for use by the bootrom.
    pub const BOOTRAM: *volatile types.peripherals.BOOTRAM = @ptrFromInt(0x400e0000);
    pub const ROSC: *volatile types.peripherals.ROSC = @ptrFromInt(0x400e8000);
    /// ARM TrustZone RNG register block
    pub const TRNG: *volatile types.peripherals.TRNG = @ptrFromInt(0x400f0000);
    /// SHA-256 hash function implementation
    pub const SHA256: *volatile types.peripherals.SHA256 = @ptrFromInt(0x400f8000);
    /// Controls vreg, bor, lposc, chip resets & xosc startup, powman and provides scratch register for general use and for bootcode use
    pub const POWMAN: *volatile types.peripherals.POWMAN = @ptrFromInt(0x40100000);
    pub const TICKS: *volatile types.peripherals.TICKS = @ptrFromInt(0x40108000);
    /// SNPS OTP control IF (SBPI and RPi wrapper control)
    pub const OTP: *volatile types.peripherals.OTP = @ptrFromInt(0x40120000);
    /// Predefined OTP data layout for RP2350
    pub const OTP_DATA: *volatile types.peripherals.OTP_DATA = @ptrFromInt(0x40130000);
    /// Predefined OTP data layout for RP2350
    pub const OTP_DATA_RAW: *volatile types.peripherals.OTP_DATA_RAW = @ptrFromInt(0x40134000);
    /// Glitch detector controls
    pub const GLITCH_DETECTOR: *volatile types.peripherals.GLITCH_DETECTOR = @ptrFromInt(0x40158000);
    /// For managing simulation testbenches
    pub const TBMAN: *volatile types.peripherals.TBMAN = @ptrFromInt(0x40160000);
    /// DMA with separate read and write masters
    pub const DMA: *volatile types.peripherals.DMA = @ptrFromInt(0x50000000);
    /// DPRAM layout for USB device.
    pub const USB_DPRAM: *volatile types.peripherals.USB_DPRAM = @ptrFromInt(0x50100000);
    /// USB FS/LS controller device registers
    pub const USB: *volatile types.peripherals.USB = @ptrFromInt(0x50110000);
    /// Programmable IO block
    pub const PIO0: *volatile types.peripherals.PIO0 = @ptrFromInt(0x50200000);
    /// Programmable IO block
    pub const PIO1: *volatile types.peripherals.PIO0 = @ptrFromInt(0x50300000);
    /// Programmable IO block
    pub const PIO2: *volatile types.peripherals.PIO0 = @ptrFromInt(0x50400000);
    /// Auxiliary DMA access to XIP FIFOs, via fast AHB bus access
    pub const XIP_AUX: *volatile types.peripherals.XIP_AUX = @ptrFromInt(0x50500000);
    /// FIFO status and write access for HSTX
    pub const HSTX_FIFO: *volatile types.peripherals.HSTX_FIFO = @ptrFromInt(0x50600000);
    /// Coresight block - RP specific registers
    pub const CORESIGHT_TRACE: *volatile types.peripherals.CORESIGHT_TRACE = @ptrFromInt(0x50700000);
    /// Single-cycle IO block Provides core-local and inter-core hardware for the two processors, with single-cycle access.
    pub const SIO: *volatile types.peripherals.SIO = @ptrFromInt(0xd0000000);
    /// Single-cycle IO block Provides core-local and inter-core hardware for the two processors, with single-cycle access.
    pub const SIO_NS: *volatile types.peripherals.SIO = @ptrFromInt(0xd0020000);
    /// TEAL registers accessible through the debug interface
    pub const PPB: *volatile types.peripherals.PPB = @ptrFromInt(0xe0000000);
    /// TEAL registers accessible through the debug interface
    pub const PPB_NS: *volatile types.peripherals.PPB = @ptrFromInt(0xe0020000);
    /// Cortex-M33 EPPB vendor register block for RP2350
    pub const EPPB: *volatile types.peripherals.EPPB = @ptrFromInt(0xe0080000);
};
