#SingleInstance Force
F5::Reload()

#HotIf WinActive("Destiny 2", )
F9::bake_start()
bake_start()
{
    static Toggle := 0
    SetTimer(bake, (Toggle:=!Toggle) ? 1250 : 0)

    bake()
    {
        Send("{lbutton down}")
        Sleep(1000)
        Send("{lbutton up}")
        return
    }
}

; You have to watch for when postmaster is out of space
#HotIf WinActive("Destiny 2", )
F10::give_start()
give_start()
{
    static Toggle := 0
    SetTimer(give, (Toggle:=!Toggle) ? 250 : 0)

    give()
    {
        MouseClick("left")
        return
    }
}

#HotIf WinActive("Destiny 2", )
F11::vendor_start()
vendor_start()
{
    static Toggle := 0
    SetTimer(vendor, (Toggle:=!Toggle) ? 1800 : 0)

    vendor()
    {
        Send("{f down}")
        Sleep(1000)
        Send("{f up}")
        return
    }
}
