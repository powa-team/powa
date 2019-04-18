Protocol
========

A minimal communication protocol is implented, using the LISTEN/NOTIFY facility
provided by postgres, which is used by the powa-web project.  You can send
queries to collector by sending messages on the "powa_collector" channel.  The
collector will send answers on the channel you specified, so make sure to
listen on it before sending any query to not miss answers.

The requests are of the following form:

    COMMAND RESPONSE_CHANNEL OPTIONAL_ARGUMENTS

    - COMMAND: mandatory argument describing the query.  The following commands
      are supported:

      - RELOAD: reload the configuration and report that the main thread
        successfully received the command.  The reload will be attempted even
        if no response channel was provided.

      - WORKERS_STATUS: return a JSON (srvid is the key, status is the content)
        describing the status of each remote server thread.  Command is ignored
        if no response channel was provided.  This command accept an optional
        argument to get the status of a single remote server, identified by its
        srvid.  If no worker exists for this server, an empty JSON  will be
        returned.

    - RESPONSE_CHANNEL: mandatory argument to describe the NOTIFY channel the
      client listens a response on.  '-' can be used if no answer should be
      sent.

    - OPTIONAL_ARGUMENTS: space separated list of arguments, specific to the
      underlying command.

The answers are of the form:

    COMMAND STATUS DATA

    - COMMAND: same as the command in the query

    - STATUS: OK or KO.

    - DATA: reason for the failure if status is KO, otherwise the data for the
      answer.

