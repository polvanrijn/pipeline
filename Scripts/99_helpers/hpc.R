library(hpcR)

setup_connection = function(){
  start_octopus()
}

start_octopus = function(){
  host = Sys.getenv('SSH_HOST')
  overwrite_default = list(
    telegram = list(
      token = Sys.getenv('TELEGRAM_TOKEN'),
      chat_id = Sys.getenv('TELEGRAM_CHAT_ID'),
      send_on_start = F,
      send_on_finish = F
    ),
    tunnel = list(
      executable = Sys.getenv('SSH_EXECUTABLE'),
      args = strsplit(Sys.getenv('SSH_TUNNEL_ARGS'), ",")[[1]],
      timeout = 1
    ),
    slurm = list(
      enabled = T,
      mode = 'parallel',
      nodes = 8,
      cpus_per_node = 32,
      options = list(
        partition = 'octopus'
      ),

      r_path = 'module use /hpc/shared/EasyBuild/modules/all; module load R; R'
    )
  )

  return(connect(host, overwrite_default))
}

start_GWDG = function(){
  host = Sys.getenv('GWDG_HOST')
  overwrite_default = list(
    telegram = list(
      token = Sys.getenv('TELEGRAM_TOKEN'),
      chat_id = Sys.getenv('TELEGRAM_CHAT_ID'),
      send_on_start = F,
      send_on_finish = F
    ),
    tunnel = list(
      executable = Sys.getenv('SSH_EXECUTABLE'),
      args = c(strsplit(Sys.getenv('SSH_TUNNEL_ARGS_NN'), ",")[[1]], "GWDG"),
      timeout = 1
    ),
    slurm = list(
      enabled = T,
      mode = 'parallel',
      options = list(
        partition = 'medium'
      ),
      
      r_path = 'R'
    )
  )
  
  return(connect(host, overwrite_default))
}

start_interactive = function(){
  host = Sys.getenv('SSH_HOST')
  overwrite_default = list(
    telegram = list(
      token = Sys.getenv('TELEGRAM_TOKEN'),
      chat_id = Sys.getenv('TELEGRAM_CHAT_ID'),
      send_on_start = F,
      send_on_finish = F
    ),
    tunnel = list(
      executable = Sys.getenv('SSH_EXECUTABLE'),
      args = strsplit(Sys.getenv('SSH_TUNNEL_ARGS'), ",")[[1]],
      timeout = 1
    ),
    slurm = list(
      enabled = T,
      mode = 'parallel'
    )
  )

  return(connect(host, overwrite_default))
}

start_workspace = function(){
  host = Sys.getenv('SSH_HOST')
  overwrite_default = list(
    telegram = list(
      token = Sys.getenv('TELEGRAM_TOKEN'),
      chat_id = Sys.getenv('TELEGRAM_CHAT_ID'),
      send_on_start = F,
      send_on_finish = F
    ),
    tunnel = list(
      executable = Sys.getenv('SSH_EXECUTABLE'),
      args = strsplit(Sys.getenv('SSH_TUNNEL_ARGS'), ",")[[1]],
      timeout = 1
    )
  )

  return(connect(host, overwrite_default))
}
