const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const raspberrypi = mb.ports.rp2xxx.boards.raspberrypi;

    const firmware = mb.add_firmware(.{
        .name = "test_app",
        .target = raspberrypi.pico2_arm,
        .optimize = optimize,
        .root_source_file = b.path("src/app.zig"),
    });

    // `install_firmware()` is the MicroZig pendant to `Build.installArtifact()`
    // and allows installing the firmware as a typical firmware file.
    //
    // This will also install into `$prefix/firmware` instead of `$prefix/bin`.
    mb.install_firmware(firmware, .{});

    // For debugging, we also always install the firmware as an ELF file
    mb.install_firmware(firmware, .{ .format = .elf });
}
