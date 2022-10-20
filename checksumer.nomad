job "checksumer_test_v4" {

  namespace   = "default"

  datacenters = ["dc1"]
  type        = "batch"
  priority    = 40

  group "checksumer_test" {
  
    volume "home" {
      type      = "host"
      read_only = true
      source    = "local_home"
    }

    task "checksum_generation" {
      driver = "exec"
      user = "jm442"

      resources {
        cores = "1"
        memory = "1024"
      }
      volume_mount {
        volume      = "home"
        destination = "/home"
        read_only   = true
      }

      config {
        #command = "/home/jm442/bin/checksumer"
        #args    = ["/home/jm442/"]
	command = "bash"
	args    = ["-c", "/home/jm442/bin/checksumer", "/home/jm442"]
      }
    }
  }
}
