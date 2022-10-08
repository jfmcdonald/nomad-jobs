# nomad job to build out a minecraft server. Based of the fantastic work done
# by Pandom @ https://github.com/pandom/cloud-nomad
job "minecraft"{
  datacenters = ["dc1"]
  priority = 80
  # The job type denotes the scheduler we will use. Since we want this to be
  # a long running job we'll choose service
  type = "service" 
  # The update block sets paramaters for health checks. We set the deadlines
  # really long here because the first deployment takes a long time to build
  # out the world and the job will fail with the defaults. 
  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "15m"
    progress_deadline = "20m"
    auto_revert = false
    canary = 0
  }

  group "mc-server" {
    # We want some level of percistance so we need to mount a directory 
    # outside the container. In this case we'll use a host volume. This
    # directory needs to be owned by the "nobody" user or you have to 
    # add a user stanza to the group. This has to be set up on the node
    # before it can be uses. This doesn't mount the drive just makes it
    # available to the tasks in the group
    volume "minecraftdir" {
      type      = "host"
      read_only = false
      source    = "local_minecraftdir"
    }
    # define the resorces for the server. Modern versions of minecraft 
    # seem to need at least 3 gigs of ram
    task "minecraft" {
      resources {
        cores = 1
        memory = 4096
        disk = 2000
      }
      # mount out percistant disk into the execution space
      volume_mount {
        volume      = "minecraftdir"
        destination = "/var/minecraft-worlds"
        read_only   = false
      }

      # eula required otherwise runtime will fail to start
      artifact {
        source = "https://raw.githubusercontent.com/pandom/cloud-nomad/master/minecraft/common/eula.txt"
        mode = "file"
        destination = "eula.txt"
      }
      # now we download the server.jar, this link needs to be updated
      # when new versions are released. Mojang does not offer a 
      # percistant "latest" link. Currently pulls 1.19.1
      artifact {
        source = "https://piston-data.mojang.com/v1/objects/f69c284232d7c7580bd89a5a4931c3581eae1378/server.jar"
        mode = "file"
        destination = "server.jar"
      }
      # set our task driver
      driver = "java"
      # configure the various options for the server
      config {
        jar_path    = "server.jar"
        # set rame use for the JVM, can not execed the ram allocated
        # to the job or OOM will kill it.
        jvm_options = ["-Xmx3G", "-Xms1G"]
        # the universe option needs to match the volume mount location
        args = ["EULA=true", "--universe",  "/var/minecraft-worlds", "nogui"]
      }
      # set up a service check
      service {
        # new to nomad 1.4, internal service checks no consul needed :)
        provider = "nomad"
        name = "minecraft-port-check"
        tags = ["minecraft" ]
        port = "access"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "30s"
          timeout  = "2s"
        }
      }
    }
    # make the default minecraft port available on the network
    network {
      port "access" {
        static = 25565
      }
    }
  }
}
