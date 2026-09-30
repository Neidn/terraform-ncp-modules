output "servers" { value = module.service.servers }
output "ansible_inventory" { value = module.service.ansible_inventory }
output "load_balancers" { value = module.service.load_balancers }
output "database" { value = module.service.database }
