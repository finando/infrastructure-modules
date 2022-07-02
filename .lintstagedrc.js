module.exports = {
  "*.tf": files => files.map(file => `terraform fmt '${file}'`)
}
