output "lb_public_ip" {
  value = module.vm.lb_public_ip
}

output "vm_public_ips" {
  value = module.vm.vm_public_ips
}
