# VirtualBox builds
source "virtualbox-iso" "debian-11" {
  vm_name = "${var.vm_name}"
  disk_size = "200000"
  guest_os_type = "Debian_64"
  hard_drive_interface = "scsi"
  headless = "true"

  # hardware used to **build VM**
  cpus = "2"
  memory = "2048"

  # change hardware configuration before exporting VM
  vboxmanage_post = [
    ["modifyvm", "{{.Name}}", "--cpus", "4"],
    ["modifyvm", "{{.Name}}", "--memory", "12288"],
    ["modifyvm", "{{.Name}}", "--uartmode1", "disconnected"],
    ["storagectl", "{{.Name}}", "--name", "IDE Controller", "--remove"]
  ]
  iso_url = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.5.0-amd64-netinst.iso"
  iso_checksum = "sha256:e307d0e583b4a8f7e5b436f8413d4707dd4242b70aea61eb08591dc0378522f3"
  # boot parameters to preseed questions
  # all parameters below can't be moved to preseed file
  boot_command = [
    "<esc><wait>",
    "auto <wait>",
    "net.ifnames=0 <wait>",
    "apparmor=0 <wait>",
    "install <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "kbd-chooser/method=us <wait>",
    "fb=false <wait>",
    "hostname=packetfence <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "<enter><wait>"
  ]
  boot_wait = "5s"
  http_directory = "files"
  ssh_username = "root"
  ssh_password = "p@ck3tf3nc3"
  ssh_timeout = "60m"
  shutdown_command = "echo 'p@ck3tf3nc3' | sudo -S poweroff"
  # export
  format = "ova"
  output_directory = "${var.output_vbox_directory}"
}
