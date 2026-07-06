#!/system/bin/sh


CLASH_DIR="/data/adb/modules/ClashRoot"
CLASH_BIN="$CLASH_DIR/clash"
CLASH_LOG="$CLASH_DIR/clash.log"
LOOP_LOG="$CLASH_DIR/loop.log"
LOGS_DIR="$CLASH_DIR/log"
CMD="$1"

log() {
    echo "[$(date '+%F %T')] $*"
}
start_clash() {
    log "start_clash"
    setsid "$CLASH_BIN" -d "$CLASH_DIR" >"$CLASH_LOG" 2>&1 &
    busybox crond -c "$CLASH_DIR"
}

kill_clash() {
    log "kill_clash"
    killall clash
    killall crond
}


if [ "$CMD" = "start" ]; then
    log "CMD=start"
    kill_clash
    start_clash
    : > "$LOOP_LOG"
    echo "启动完毕"

elif [ "$CMD" = "kill" ]; then
    log "CMD=kill"
    kill_clash
    echo "停止完毕"

elif [ "$CMD" = "test" ]; then
    log "CMD=test"
    "$CLASH_BIN" -t -d "$CLASH_DIR"

elif [ "$CMD" = "check" ]; then
    log "CMD=check"
    eval "ps -p \$(pidof clash) -o pid,ppid,%cpu,%mem,cmd; cat /proc/\$(pidof clash)/status"

elif [ "$CMD" = "loop" ]; then
    exec >>"$LOOP_LOG" 2>&1
    log "CMD=loop"
    NOW=$(date '+%F_%H-%M-%S')

    if [ -f "$CLASH_LOG" ]; then
        cp "$CLASH_LOG" "$LOGS_DIR/$NOW.log"
    fi

    # 限制日志数量最多50个
    if [ -d "$LOGS_DIR" ]; then
        LOG_COUNT=$(ls -1 "$LOGS_DIR" 2>/dev/null | wc -l)
        if [ "$LOG_COUNT" -gt 50 ]; then
            ls -1t "$LOGS_DIR" | tail -n +51 | while read f; do
                rm -f "$LOGS_DIR/$f"
            done
        fi
    fi

    HOUR=$(date +%H)
    if [ "$HOUR" -eq 5 ]; then
        log "hour=5, restart clash"
        kill_clash
        start_clash
    else
        log "not 5am, clean log only"
        : > "$CLASH_LOG"
    fi
else
    : > "$LOOP_LOG"
fi