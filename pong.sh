#!/usr/bin/env bash

ball_x=0
ball_y=0
ball_accel_x=1
ball_accel_y=1
ball_max_x=$(tput cols)

paddle='####################'
paddle_mask='                    '
paddle_x=1
paddle_y=$(tput lines)
paddle_length=8
paddle_accel_x=0
paddle_max_x=$((ball_max_x - paddle_length))


move_ball() {
    tput cup $ball_y $ball_x
    echo -n ' '

    ((ball_x += ball_accel_x))
    ((ball_y += ball_accel_y))

    if ((ball_x > ball_max_x)); then
        ((ball_x = ball_max_x))
    fi

    if ((ball_x >= ball_max_x)); then
        ((ball_x = ball_max_x))
        ((ball_accel_x = -ball_accel_x))
    elif ((ball_x <= 0)); then
        ((ball_x = 0))
        ((ball_accel_x = -ball_accel_x))
    fi

    if ((ball_y >= paddle_y - 2)); then
        ((ball_y = paddle_y - 2))
        ((ball_accel_y = -ball_accel_y--))
        if ((ball_x >= paddle_x && ball_x <= 1 + paddle_x + paddle_length)); then
            ((ball_accel_x = -paddle_accel_x))
        else
            ((ball_y = 0))
        fi
    elif ((ball_y <= 0)); then
        ((ball_y = 0))
        ((ball_accel_y = -ball_accel_y))
    fi

    tput cup $ball_y $ball_x
    echo -n '®'
}

move_paddle() {
    tput cup $paddle_y $paddle_x
    echo -n "${paddle_mask:0:paddle_length}"

    if ((RANDOM % 5 == 0)); then
        ((paddle_accel_x += RANDOM % 3 - 1))
    else
        if ((paddle_x < ball_x))
            then ((paddle_accel_x++))
            else ((paddle_accel_x--))
        fi
    fi

    ((paddle_x += paddle_accel_x))

    if ((paddle_x > paddle_max_x)); then
        ((paddle_x = paddle_max_x))
        ((paddle_accel_x = 0))
    fi

    if ((paddle_x < 0)); then
        ((paddle_x = 0))
        ((paddle_accel_x = 0))
    fi

    tput cup $paddle_y $paddle_x
    echo -n "${paddle:0:paddle_length}"
}


clear
while true; do
    move_paddle
    move_ball
    tput cup 0 0
    tput el
    sleep 0.05
done

