#
# LAB Kick start file
#
yum update -y
yum -y install wget mc bzip2 mailx git
yum -y install epel-release
yum -y install psmisc
yum -y  install yum-utils

echo "admin@example.com" > /root/.forward
chmod 644 /root/.forward 

mkdir -p /root/.ssh
chmod 700 /root/.ssh

cat << EOF >> /root/.ssh/authorized_keys
ssh-dss RSA_KEY
EOF

yum install -y open-vm-tools
systemctl enable vmtoolsd
systemctl start vmtoolsd
systemctl status vmtoolsd

yum install chrony -y
systemctl enable chronyd
mv -f /etc/chrony.conf /etc/chrony.conf.orig-smu
cat <<EOF> /etc/chrony.conf
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server ntp1.lab iburst
server ntp2.lab iburst
server ntp3.lab iburst
# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift
# Allow the system clock to be stepped in the first three updates
# if its offset is larger than 1 second.
makestep 1.0 3
# Enable kernel synchronization of the real-time clock (RTC).
rtcsync
# Specify directory for log files.
logdir /var/log/chrony
EOF

systemctl start chronyd
timedatectl set-timezone Europe/Prague
chronyc ntpdata
systemctl restart chronyd
timedatectl
chronyc sources
chronyc makestep

mv -f /etc/resolv.conf /etc/resolv.conf.orig-smu
cat << EOF > /etc/resolv.conf
search lab
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 8.8.4.4
EOF
cat /etc/resolv.conf

cp -f /etc/rsyslog.conf /etc/rsyslog.orig-smu
cat << EOF >> /etc/rsyslog.conf
*.*       @syslog.lab_IP:514
EOF
service rsyslog restart


yum -y install http://check_mk.lab:5000/dc5monitor/check_mk/agents/check-mk-agent-1.5.0p21-1.noarch.rpm
systemctl enable check_mk.socket
systemctl restart check_mk.socket
firewall-cmd --add-port=6556/tcp --permanent
firewall-cmd --reload
