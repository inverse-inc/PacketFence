import apache from './apache'
import authentication from './authentication'
import dhcp from './dhcp'
import haproxy from './haproxy'
import logs from './logs'
import mysql from './mysql'
import queue from './queue'
import radius from './radius'
import services from './services'
import system from './system'

export default [
  ...system,
  ...services,
  ...radius,
  ...apache,
  ...authentication,
  ...dhcp,
  ...haproxy,
  ...mysql,
  ...queue,
  ...logs,
]