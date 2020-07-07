This is the source for https://bokut.in/freebsd-patch-level-table/ .

There was a request, so I will publish it.

1. install perl modules.
    
    cpm .

2. edit etc/freebsd_patchleveltable.pl or create etc/freebsd_patchleveltable_local.pl.

3. crontab -e
    
    ex:
        0 0  * * * runcron /root/freebsd-patch-level-table/script/cron.pl
        0 8  * * * runcron /root/freebsd-patch-level-table/script/cron.pl --check_remote
        0 16 * * * runcron /root/freebsd-patch-level-table/script/cron.pl

4. script/web_server.pl -d
