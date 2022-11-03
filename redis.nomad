job "redis" {
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
  group "cache" {
    count = 1
    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
    ephemeral_disk {
      size = 300
    }
    task "redis" {
      driver = "docker"
      user = "1001"
      config {
        #image = "library://sylabs/examples/redis"
        image = "redis"
        ports = ["db"]
      }
      resources {
      }
      service {
        provider = "nomad"
        name = "global-redis-check"
        tags = ["global", "cache", "urlprefix-/redis" ]
        port = "db"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
    }
    network {
      port "db" {
        static = 6379
      }
    }
  }
}
