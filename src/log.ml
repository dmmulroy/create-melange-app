let prefix = {js|[create-melange-app]: |js}

let log ?(without_prefix = false) msg =
  if without_prefix then msg else prefix ^ msg
