type
  User
    id
    coins

  Action
    id
    service
    cost

  Account
    id
    user
    service
    username
    password
    data
  
  Automation
    id
    user
    action
    when
    data

  Integration
    id
    user
    service
    data

  # Cache
  #   id
  #   user
  #   service
  #   data
  