    Request = (require 'superagent').agent()
    {foot} = (require 'tangible') 'guarded-punishment'

    hour = 3600*1000

Build a base replication query from the name of the DB.

    repl = (db) ->
      source: "#{local_base}/#{db}"
      target: "#{remote_base}/#{db}"

Start a continuous replication.

    start_replication = (db) ->
      console.log 'start_replication', db
      res = await Request
        .post "#{local_base}/_replicate"
        .send Object.assign (repl db),
          continuous: true
        .accept 'json'
      console.log 'start_replication', db, res
      return

Cancel a continuous replication.

    cancel_replication = (db) ->
      console.log 'cancel_replication', db
      res = await Request
        .post "#{local_base}/_replicate"
        .send Object.assign (repl db),
          continuous: true
          cancel: true
        .accept 'json'
      console.log 'cancel_replication', db, res
      return

Run a one-time replication.

    onetime_replication = (db) ->
      console.log 'onetime_replication', db
      res = await Request
        .post "#{local_base}/_replicate"
        .send (repl db)
        .accept 'json'
      console.log 'onetime_replication', db, res
      return

    yesterday = -> new Date(Date.now()-24*hour).toJSON()[0...10]

Handle the changes for a single database.

The DB name is normally along the lines of `cdr-YYYY-MM-DD`, see astonishing-competition.

    handle_db = foot 'handle_db', (db) ->
      console.log 'handle_db', db
      try
        await Request.put "#{spicy_base}/#{db}" # use grumpy-actor to create the DB
      catch error
        return Promise.reject error unless error.status is 409

      if db < "cdr-#{yesterday()}"
        if remote_base
          console.log "Finishing replication of #{db}"
          await cancel_replication db
          await onetime_replication db
          console.log "Deleting #{db}"
          await Request.delete "#{local_base}/#{db}"
        else
          console.error "Not deleting #{db}, no remote base"
      else
        await start_replication today
      return

    main = foot 'main', ->

Don't do too much with streaming. The idea is that we keep this list _very_ short.

      cdr_dbs = await Request
        .get "#{local_base}/_all_dbs"
        .send
          start_key: JSON.stringify 'cdr-'
          end_key: JSON.stringify 'cdr.'
        .accept 'json'

      console.log 'main', 'Received CDR dbs', cdr_dbs.length

      for db in cdr_dbs
        await handle_db db
      return

    local_base = process.env.CDR_LOCAL_BASE
    unless local_base?
      throw new Error 'Missing CDR_LOCAL_BASE'
    remote_base = process.env.CDR_REMOTE_BASE
    spicy_base = process.env.SPICY_BASE

    setInterval main, 0.25*hour
    do main
