job "checksumer" {

  namespace   = "default"

  datacenters = ["dc1"]
  type        = "batch"
  priority    = 40

  group "checksumer_test" {
  
    volume "home" {
      type      = "host"
      read_only = true
      source    = "local_home"  # name of a export shared from the underlying node
    }

    task "checksum_generation" {
      driver = "exec"
      # the user needs to be a local system user. if it's not a local user e.g. an AD user
      # you need to replace this with the UUID. Either way the user needs access to the 
      # data you want to scan.
      user = "joe" 

      resources {
        cores = "1"
        memory = "2048"
      }
      volume_mount {
        volume      = "home"
        destination = "/home"
        read_only   = true
      }
      artifact {
        source = "https://github.com/jfmcdonald/checksumer/releases/download/v0.1/checksumer"
        destination = "local/"
      }

      config {
        command = "local/checksumer"
        args    = ["/home/joe/"]   # directory you want to scan
      }
    }
  }
}
