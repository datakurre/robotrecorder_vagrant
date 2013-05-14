exec { "apt-get update":
  command => "sudo apt-get update",
  # Update package list once every day:
  onlyif => "test `sudo find /var/lib/apt -type f -mtime 0 | wc -l` -eq 0",
  path => ["/usr/bin"],
  timeout => 3600
}

package { "python":
  ensure => "present",
  require => Exec["apt-get update"]
}

package { "python-pip":
  ensure => "present",
  require => Package["python"]
}

package { "python-dev":
  ensure => "present",
  require => Exec["apt-get update"]
}

package { "alsa-utils":
  ensure => "present",
  require => Exec["apt-get update"]
}

package { "lame":
  ensure => "present",
  require => Exec["apt-get update"]
}

exec { "vnc2flv":
  command => "pip install vnc2flv",
  creates => "/usr/local/bin/recordwin.sh",
  require => [
    Package["x11vnc"],
    Package["python-pip"],
    Package["python-dev"],
    Package["alsa-utils"],
    Package["lame"]
  ],
  path => ["/usr/bin"]
}

package { "supervisor":
  ensure => "present",
  require => Exec["apt-get update"]
}

package { "openjdk-6-jre":
  ensure => "present",
  require => Exec["apt-get update"]
}

package { "icedtea-6-plugin":
  ensure => "present",
  require => Package["openjdk-6-jre"]
}

package { "xserver-xorg-core":
  ensure => "present",
  require => Exec["apt-get update"]
}

package { "x11-xkb-utils":
  ensure => "present",
  require => Package["xserver-xorg-core"]
}

package { "xfonts-75dpi":
  ensure => "present",
  require => Package["xserver-xorg-core"]
}

package { "xfonts-100dpi":
  ensure => "present",
  require => Package["xserver-xorg-core"]
}

package { "xfonts-scalable":
  ensure => "present",
  require => Package["xserver-xorg-core"]
}

package { "xfonts-cyrillic":
  ensure => "present",
  require => Package["xserver-xorg-core"]
}

package { "xvfb":
  ensure => "present",
  require => [
    Package["xfonts-75dpi"],
    Package["xfonts-100dpi"],
    Package["xfonts-scalable"],
    Package["xfonts-cyrillic"]
  ]
}

package { "x11vnc":
  ensure => "present",
  require => Package["xvfb"]
}

package { "iceweasel":
  ensure => "present",
  require => Exec["apt-get update"]
}

file { "/usr/share/selenium":
  ensure => "directory",
}

exec { "/usr/share/selenium/selenium-server-standalone.jar":
  creates => "/usr/share/selenium/selenium-server-standalone.jar",
  command => "wget -O /usr/share/selenium/selenium-server-standalone.jar http://selenium.googlecode.com/files/selenium-server-standalone-2.32.0.jar",
  require => File["/usr/share/selenium"],
  path => ["/usr/bin"]
}

file { "/usr/local/bin/rec-window.py":
  ensure => "present",
  mode => 0744,
  content => '#!/usr/bin/python
import os
import re
import subprocess
import time

FIREFOX = re.compile(
    r\'(0x\d+)\s"[^"]*":\s*\("Navigator"\s*"Iceweasel"\)\', re.I + re.M
)


while True:
    p = subprocess.Popen(["xwininfo", "-tree", "-root"],
                         stdout=subprocess.PIPE)
    windows = FIREFOX.findall(p.stdout.read())
    if windows:
        with open("/run/recordwin.wid", "w") as output:
            output.write(windows[0])
    elif os.path.exists("/run/recordwin.wid"):
        os.unlink("/run/recordwin.wid")
    time.sleep(1)',
  require => Package['python']
}

exec { "modprobe snd-aloop":
  command => "sudo modprobe snd-aloop index=0 pcm_substreams=1",
  path => ["/bin", "/usr/bin"],
  require => Package["alsa-utils"]
}

file { "/etc/modules":
  ensure => "present",
  content => 'loop
snd-aloop index=0 pcm_substreams=1
',
  require => Exec["modprobe snd-aloop"]
}

file { "/etc/asound.conf":
  ensure => "present",
  content => 'pcm.!default {
  type plug
  slave.pcm "dmixer"
}
pcm.dmixer {
  type dmix
  ipc_key 1024
  slave.pcm "hw:Loopback,0,0"
  slave.period_time 0
  slave.period_size 1024
  slave.buffer_size 4096
  slave.rate 4410
}
pcm.loop {
  type plug
  slave.pcm "hw:Loopback,1,0"
}',
  require => File["/etc/modules"]
}

file { "/usr/local/bin/rec-start.sh":
  ensure => "present",
  mode => 0744,
  content => '#!/bin/sh
cd /vagrant
while [ ! -f /run/recordwin.wid ]
do
  sleep 1
done
echo $$ > /run/recordwin.pid
X11VNC="x11vnc -nocursor" ARECORD="arecord -Dloop -r22050 -fS16_LE" recordwin.sh -display :99 -id `cat /run/recordwin.wid`',
  require => [
    Exec['vnc2flv'],
    File['/etc/asound.conf']
  ]
}

file { "/usr/local/bin/rec-stop.sh":
  ensure => "present",
  mode => 0744,
  content => '#!/bin/sh
while [ true ]
do
  if [ -f /run/recordwin.pid ]
  then
    while [ -f /run/recordwin.wid ]
    do
      sleep 1
    done
    bash -c "kill -n 2 -`cat /run/recordwin.pid`"
    rm /run/recordwin.pid
  fi
  sleep 1
done',
  require => [
    File['/usr/local/bin/rec-start.sh']
  ]
}

file { "/etc/supervisor/conf.d/xvfb.conf":
  ensure => present,
  content => '[program:xvfb]
command=/usr/bin/Xvfb -fp /usr/share/fonts/X11/misc/ :99 -screen 0 1280x1024x24
priority=10
autostart=true
autorestart=false',
  require => [
    Package["supervisor"],
    Package["xvfb"]
  ]
}

exec { "DISPLAY=:99 supervisord":
  command => "sudo sed -i -e 's/DESC=supervisor/DESC=supervisor\\n\\nexport DISPLAY=:99/' /etc/init.d/supervisor",
  onlyif => "test `grep DISPLAY /etc/init.d/supervisor | wc -l` -lt 1",
  require => Package["supervisor"],
  path => ["/bin", "/usr/bin"]
}

file { "/etc/supervisor/conf.d/selenium-server.conf":
  ensure => present,
  content => '[program:selenium-server]
command=java -jar /usr/share/selenium/selenium-server-standalone.jar
priority=20
autostart=true
autorestart=false
stopasgroup=true',
  require => [
    Package["openjdk-6-jre"],
    Package["icedtea-6-plugin"],
    Package["iceweasel"],
    Exec["/usr/share/selenium/selenium-server-standalone.jar"],
    File["/etc/supervisor/conf.d/xvfb.conf"],
    Exec["DISPLAY=:99 supervisord"]
  ]
}

file { "/etc/supervisor/conf.d/rec-window.conf":
  ensure => present,
  content => '[program:rec-window]
command=/usr/local/bin/rec-window.py
priority=30
autostart=true
autorestart=false',
  require => [
    Package["python"],
    File["/etc/supervisor/conf.d/xvfb.conf"],
    Exec["DISPLAY=:99 supervisord"]
  ]
}

file { "/etc/supervisor/conf.d/rec-start.conf":
  ensure => present,
  content => '[program:rec-start]
command=/usr/local/bin/rec-start.sh
priority=40
autostart=true
autorestart=true',
  require => File['/usr/local/bin/rec-start.sh']
}

file { "/etc/supervisor/conf.d/rec-stop.conf":
  ensure => present,
  content => '[program:rec-stop]
command=/usr/local/bin/rec-stop.sh
priority=50
autostart=true
autorestart=false',
  require => File['/usr/local/bin/rec-stop.sh']
}

exec { "service supervisor stop":
  command => "sudo service supervisor stop",
  onlyif => "test `sudo supervisorctl status | wc -l` -eq 0",
  require => [
    Package["supervisor"],
    File["/etc/supervisor/conf.d/xvfb.conf"],
    File["/etc/supervisor/conf.d/selenium-server.conf"],
    File["/etc/supervisor/conf.d/rec-window.conf"],
    File["/etc/supervisor/conf.d/rec-start.conf"],
    File["/etc/supervisor/conf.d/rec-stop.conf"]
  ],
  path => ["/usr/bin"]
}

exec { "service supervisor start":
  command => "sudo service supervisor start",
  # Start when is not started ("unix:///var/run/supervisor.sock no such file"):
  onlyif => "test `sudo supervisorctl status | wc -l` -eq 1",
  require => Exec["service supervisor stop"],
  path => ["/usr/bin"]
}
