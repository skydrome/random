#!/usr/bin/env python

## Windows
# https://visualstudio.microsoft.com/visual-cpp-build-tools
# msvc++ and win sdk
# pip install psutil wmi pypiwin32 pywin32
## nvidia
# pip install py3nvml

## Linux
# pacman install python3-psutil util-linux mesa-utils

## RouterOS
# pip install librouteros

__module_name__ = "sysinfo"
__module_author__ = "numbafive"
__module_version__ = "1.2"
__module_description__ = "outputs system information"

import platform
import re
import sys
import time

import psutil

# windows config
net_iface: int = 0

# linux config
# regex: matches /boot /snap*
ignore_mount: str = "boot$|snap"

# mikrotik routerOS api
router = {
    "host": "192.168.1.1",
    "user": "admin",
    "pass": "123"
}


def get_size(bytes: float, decimals: int = 1) -> str:
    factor = 1024.0
    for unit in ["", "K", "M", "G", "T", "P", "E"]:
        if bytes < factor:
            return f"{round(bytes, decimals)}\00314{unit}B\003" if decimals > 0 else f"{int(bytes)}\00314{unit}B\003"
        bytes /= factor


def sys_uptime(seconds: float) -> str:
    if seconds < 1.0:
        return "∞"
    parts: list[str] = []
    for unit, div in (
        ("\00314w\003", 60 * 60 * 24 * 7),
        ("\00314d\003", 60 * 60 * 24),
        ("\00314h\003", 60 * 60),
        ("\00314m\003", 60),
        # ('\00314s\003', 1),
    ):
        amount, seconds = divmod(int(seconds), div)
        if amount > 0:
            parts.append(f"{amount}{unit}")
    return " ".join(parts)


def fetch_network_rate():
    io1 = psutil.net_io_counters()
    time.sleep(0.5)
    io2 = psutil.net_io_counters()

    rate = {
        "tx": (io2.bytes_sent - io1.bytes_sent) * 2,
        "rx": (io2.bytes_recv - io1.bytes_recv) * 2,
    }
    total = {
        "up": io2.bytes_sent,
        "dn": io2.bytes_recv,
    }
    return rate, total


def sysinfo(word, word_eol, userdata) -> None:
    # no arguments defaults to showing everything
    section = word[1] if len(word) > 1 else "all"

    if HEXCHAT and section in ("all", "version", "hexchat"):
        hexchat.command(f"say \017-\002Hexchat {hexchat.get_info('version')}-\002")

    if platform.system() == "Windows":
        # Vbox needs: VBoxManage setextradata "vm name" "VBoxInternal/Devices/pcbios/0/Config/DmiExposeMemoryTable" 1

        c = wmi.WMI()

        # change return type from DWORD to LONGLONG otherwise windows will return a negative number after 49.7 days
        GetTickCount = ctypes.windll.kernel32.GetTickCount64
        GetTickCount.restype = ctypes.c_ulonglong

        if section in ("all", "os"):
            os_info = c.query("SELECT Caption, BuildNumber FROM Win32_OperatingSystem")[0]
            os_name = os_info_sub.sub("", os_info.Caption)
            header = "    os" if section == "all" else "os"
            _print(f"say \017\002{header}\002: {os_name} Build {os_info.BuildNumber} \002uptime\002: {sys_uptime(GetTickCount() / 1000.0)}")

        if section in ("mobo", "motherboard"):
            motherboard = c.query("SELECT Product FROM Win32_BaseBoard")[0].Product
            header = "  mobo" if section == "all" else "mobo"
            _print(f"say \017\002{header}\002: {motherboard.title()}")

        if section in ("all", "cpu"):
            global CPU_PERF
            if CPU_PERF is None:
                CPU_PERF = CpuPerfCounter()

            cpu_info = c.query("SELECT Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed FROM Win32_Processor")[0]
            cpu_name = cpu_name_sub.sub("", cpu_info.Name.strip())
            turbo = cpu_info.MaxClockSpeed * (CPU_PERF.read() / 100.0)
            header = "   cpu" if section == "all" else "cpu"
            _print(f"say \017\002{header}\002: {cpu_name} {cpu_info.NumberOfCores}C/{cpu_info.NumberOfLogicalProcessors}T • {cpu_info.MaxClockSpeed / 1000:.2f}\00314→\017{turbo / 1000:.2f}\00314GHz\003")

        if section in ("uptime"):
            _print(f"say \017\002uptime\002: {sys_uptime(GetTickCount() / 1000.0)}")

        if section in ("all", "gpu"):
            gpu_info = c.query("SELECT Name, VideoModeDescription FROM Win32_VideoController")[0]
            # if gpu_info.AdapterCompatibility == "NVIDIA":
            #     # https://py3nvml.readthedocs.io/en/latest
            #     from py3nvml import py3nvml
            #     nvmlDeviceGetMemoryInfo()
            resolution = gpu_info.VideoModeDescription.split(" x ")
            header = "   gpu" if section == "all" else "gpu"
            gpu_name = gpu_name_sub.sub("", gpu_info.Name.strip())
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000") as k:
                vram = winreg.QueryValueEx(k, "HardwareInformation.qwMemorySize")[0]
            _print(f"say \017\002{header}\002: {gpu_name} {get_size(vram, 0)} • {resolution[0]}\00314x\017{resolution[1]}")

        if section in ("all", "memory", "mem"):
            speed = c.query("SELECT ConfiguredClockSpeed FROM Win32_PhysicalMemory")[0]
            memory = c.query("SELECT FreePhysicalMemory, TotalVisibleMemorySize FROM Win32_OperatingSystem")[0]
            total = int(memory.TotalVisibleMemorySize) * 1024
            used = total - int(memory.FreePhysicalMemory) * 1024
            header = "   mem" if section == "all" else "mem"
            _print(f"say \017\002{header}\002: {get_size(used)}/{get_size(total)} used • {speed.ConfiguredClockSpeed:.0f}\00314MHz\003")

        if section in ("all", "disk", "hdd", "drives"):
            num = cap = use = 0
            partitions = psutil.disk_partitions()
            for volume in partitions:
                # prevents reading from empty drives such as cd-roms, card readers etc
                if volume.fstype:
                    try:
                        stat = psutil.disk_usage(volume.device)
                        cap += stat.total
                        use += stat.used
                        num += 1
                    except (OSError, PermissionError):
                        pass
            header = "  disk" if section == "all" else "disk"
            _print(f"say \017\002{header}\002: {num} volumes with {get_size(use)}/{get_size(int(cap))} used")

        if section in ("all", "network", "net"):
            adapter = c.query("SELECT Name FROM Win32_PerfRawData_Tcpip_NetworkInterface")[net_iface].Name
            adapter = network_name_sub.sub("", adapter)
            net_rate, net_total = fetch_network_rate()
            header = "   net" if section == "all" else "net"
            _print(f"say \017\002{header}\002: {adapter} ▲{get_size(net_total['up'])} {get_size(net_rate['tx'])}/s • {get_size(net_total['dn'])}▼ {get_size(net_rate['rx'])}/s")

    else:
        # Linux
        import subprocess

        try:
            gpu_name = subprocess.run(["glxinfo", "-B"], text=True, stdout=subprocess.PIPE, timeout=5).stdout
            gpu_name = [x.split(":")[1] for x in gpu_name.split("\n") if "OpenGL renderer string" in x][0].strip()
        except IndexError:
            gpu_name = "None"
        except FileNotFoundError:
            raise SystemExit("Not Found: glxinfo")

        if section in ("all", "os"):
            os_info = platform.uname()
            header = "    os" if section == "all" else "os"
            _print(f"say \017\002{header}\002: {os_info.system} {os_info.release}  uptime: {sys_uptime(time.time() - psutil.boot_time())}")

        if section in ("all", "cpu"):
            freq = psutil.cpu_freq()
            cores = psutil.cpu_count(logical=False)
            # threads = psutil.cpu_count()

            try:
                cpu_name = subprocess.run(["lscpu"], text=True, stdout=subprocess.PIPE, timeout=5).stdout
                cpu_name = [x.split(":")[1] for x in cpu_name.split("\n") if "Model name:" in x][-1].strip()
                cpu_name = cpu_name_sub.sub("", cpu_name)
            except IndexError:
                cpu_name = None
            except FileNotFoundError:
                raise SystemExit("Not Found: lscpu")

            # try to parse ARM cpu model
            if not cpu_name or cpu_name.startswith("Cortex"):
                try:
                    with open("/proc/device-tree/compatible", "r") as f:
                        cpu_name = f.readline().strip("\x00").split(",")[-1]
                except Exception as e:
                    print(f"cpu error: {repr(e)}")
                    cpu_name = "unknown"

            header = "   cpu" if section == "all" else "cpu"
            _print(f"say \017\002{header}\002: {cpu_name} {cores} Core • {freq.min:.0f}\00314→\017{freq.max:.0f}\00314MHz\003  \002gpu\002: {gpu_name}")

        if section in ("gpu"):
            header = "   gpu" if section == "all" else "gpu"
            _print(f"say \017\002{header}\002: {gpu_name}")

        if section in ("all", "memory", "mem"):
            mem = psutil.virtual_memory()
            cur_load = psutil.getloadavg()
            header = "   mem" if section == "all" else "mem"
            _print(f"say \017\002{header}\002: {get_size(mem.used - mem.buffers)}/{get_size(mem.total)} used  load: {cur_load[1]:.1f}\00314 5min\003 • {cur_load[2]:.1f}\00314 15min\003")

        if section in ("all", "disk", "hdd", "drives"):
            partitions = psutil.disk_partitions()
            for f in partitions:
                # exclude these partitions
                if re.search(rf"/({ignore_mount})", f.mountpoint):
                    continue
                try:
                    mount = psutil.disk_usage(f.mountpoint)
                except PermissionError:
                    continue

                header = "  disk" if section == "all" else "disk"
                _print(f"say \017\002{header}\002: {f.device.replace('/dev/', '')} {f.fstype} • {get_size(mount.used)}/{get_size(mount.total)} {mount.percent}\00314%\003 used")

        if section in ("all", "temp"):
            # only show temps if they exist
            if hasattr(psutil, "sensors_temperatures"):
                temp = psutil.sensors_temperatures()
                temps = ""
                for t in temp:
                    temps += f"{t.replace('_thermal', '')} {round(temp[t][0].current)}\00314°C\003 • "

                header = "  temp" if section == "all" else "temp"
                _print(f"say \017\002{header}\002: {temps[:len(temps) - 3]}")

        if section in ("all", "network", "net"):
            net_rate, net_total = fetch_network_rate()
            header = "   net" if section == "all" else "net"
            _print(f"say \017\002{header}\002: ▲{get_size(net_total['up'])} {get_size(net_rate['tx'])}/s • {get_size(net_total['dn'])}▼ {get_size(net_rate['rx'])}/s")

    # try:
    #     from ros import Ros
    #     from requests.packages import urllib3
    #     urllib3.disable_warnings()
    #     ros = Ros("https://192.168.1.1", "admin", "123")
    #     model = ros.system.routerboard.model.split("+")[0]
    #     firmware = ros.system.routerboard.current_firmware
    #     voltage = ros.system.health[0].value
    #     temp = ros.system.health[1].value
    #     _print(f"say \017router: {model} on \00314v\017{firmware} • {temp}\00314°C\003 @ {voltage} \00314volts\003")
    # except Exception as e:
    #     print(f"router error: {repr(e)}")
    #     pass

    if section in ("all", "router"):
        try:
            from librouteros import connect

            api = connect(host=router["host"], username=router["user"], password=router["pass"])
            health = tuple(api(cmd="/system/health/print"))
            voltage, temp = health[0]["value"], health[1]["value"]
            resource = tuple(api(cmd="/system/resource/print"))[0]
            model, firmware = (resource["board-name"].split("+")[0], resource["version"].split(" ")[0])
            mem_total, mem_free = resource["total-memory"], resource["free-memory"]
            load = resource["cpu-load"]

            m = re.match(r"(?P<year>\d+y)?(?P<week>\d+w)?(?P<day>\d+d)?", resource["uptime"])
            uptime = 0
            if m["year"]:
                uptime = int(m["year"][:-1]) * 365 + uptime
            if m["week"]:
                uptime = int(m["week"][:-1]) * 7 + uptime
            if m["day"]:
                uptime = int(m["day"][:-1]) + uptime

            _print(f"say \017\002router\002: {model} \00314v\017{firmware} up {uptime}\00314d\003 • {load}% load • {get_size(mem_total - mem_free)}/{get_size(mem_total)} mem • {temp}\00314°C\003 @ {voltage}\00314V\003")
        except Exception as e:
            print(f"router error: {repr(e)}")
            pass

    if HEXCHAT:
        # dont foward this command to other clients on the same bouncer
        return hexchat.EAT_ALL


def _print(text: str) -> None:
    if HEXCHAT:
        hexchat.command(text)
    else:
        print(IRC_CONTROL_RE.sub("", text))


# strip control codes from console output
IRC_CONTROL_RE = re.compile(
    r"(?:"
    r"\x03(?:\d{1,2}(?:,\d{1,2})?)?"
    r"|[\x02\x0F\x16\x1D\x1E\x1F]"
    r"|say "
    r")"
)
cpu_name_sub = re.compile(r" (Dual|Triple|Quad|Six|Eight|\d?\d)-.*Processor| CPU| @.*[Hh]z| \(R|TM|\)")
gpu_name_sub = re.compile(r" (Series|Graphics|\(TM\))")
os_info_sub = re.compile(r"Microsoft | Preview| multi-session")
network_name_sub = re.compile(r" (Controller|Family|Adapter)|Network | (#|_)\d+")


if platform.system() == "Windows":
    import ctypes
    import winreg

    import win32pdh
    import wmi

    CPU_PERF = None

    class CpuPerfCounter:
        def __init__(self) -> None:
            self.query = win32pdh.OpenQuery()
            self.counter = win32pdh.AddCounter(
                self.query,
                r"\Processor Information(_Total)\% Processor Performance"
            )
            win32pdh.CollectQueryData(self.query)

        def read(self) -> float:
            # Perf counters need two samples
            win32pdh.CollectQueryData(self.query)
            _, value = win32pdh.GetFormattedCounterValue(
                self.counter,
                win32pdh.PDH_FMT_DOUBLE
            )
            return value


try:
    import hexchat
    hexchat.hook_command("sysinfo", sysinfo, help="Usage: /sysinfo")
    hexchat.hook_unload(print(f"{__module_name__} unloaded."))
    print(f"{__module_name__} version {__module_version__} loaded.")
    HEXCHAT: bool = True

except ModuleNotFoundError as e:
    HEXCHAT = False
    sysinfo(sys.argv, 0, 0)
