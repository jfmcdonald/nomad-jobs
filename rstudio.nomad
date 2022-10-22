job "rstudio" {
  datacenters = ["dc1"]
  type = "service"
  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "19m"
    progress_deadline = "20m"
    auto_revert = false
    canary = 0
  }
  group "server" {
    volume "datadir" {
      type      = "host"
      read_only = false
      source    = "local_datadir"  # update to name of local share
    }

    count = 1
    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
    task "rstudio" {
      volume_mount {
        volume      = "datadir"
        destination = "/home/rstudio/data"   # this path will show up in the Rstudio file browser root by defualt
        read_only   = false
      }
      resources {
        cores = 1
        memory = 4096
        disk = 2000
      }


      driver = "docker"
      config {
        image = "dceoy/rstudio-server"
        ports = ["access"]
      }
      service {
        provider = "nomad"
        name = "rstudio-connect-check"
        tags = ["global", "urlprefix-/rstudio" ]
        port = "access"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
    }
    network {
      port "access" {
        static = 8787
      }
    }
  }
}
