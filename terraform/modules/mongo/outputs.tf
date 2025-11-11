output "mongo_private_ip" {
  value = aws_instance.mongo.private_ip
}
output "mongo_instance_id" {
  value = aws_instance.mongo.id
}
