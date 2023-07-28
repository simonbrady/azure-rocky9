output "lb_dns_name" {
  value = module.vm.lb_dns_name
}

output "lb_public_ip" {
  value = module.vm.lb_public_ip
}

output "vm_private_ips" {
  value = module.vm.vm_private_ips
}

output "vm_public_ips" {
  value = module.vm.vm_public_ips
}
