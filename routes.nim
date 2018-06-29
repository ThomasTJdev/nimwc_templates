  get "/templates/settings":
    createTFD()
    if c.loggedIn and c.rank in [Admin, Moderator]:
      resp genMain(c, genTemplatesSettings(c, @"msg"))

  get "/templates/apply":
    createTFD()
    if c.loggedIn and c.rank in [Admin, Moderator]:
      let applyTemplate = templatesApply(db, c.userid, @"templatename")
      redirect("/templates/settings?msg=" & encodeUrl(applyTemplate))

  get "/templates/new":
    createTFD()
    if c.loggedIn and c.rank in [Admin, Moderator]:
      let newTemplate = templatesGenerate(db, c.userid, @"templatename")
      redirect("/templates/settings?msg=" & encodeUrl(newTemplate))

  get "/templates/delete":
    createTFD()
    if c.loggedIn and c.rank in [Admin, Moderator]:
      let deleteTemplate = templatesDelete(@"templatename")
      redirect("/templates/settings?msg=" & encodeUrl(deleteTemplate))
