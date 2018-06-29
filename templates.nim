# Copyright 2018 - Thomas T. Jarløv

import
  db_sqlite,
  os,
  strutils,
  uri

import ../../nimwcpkg/resources/session/user_data

const pluginTitle       = "Templates"
const pluginAuthor      = "Thomas T. Jarløv"
const pluginVersion     = "0.1"
const pluginVersionDate = "2018-06-29"


proc pluginInfo() =
  echo " "
  echo "--------------------------------------------"
  echo "  Package:      " & pluginTitle & " plugin"
  echo "  Author:       " & pluginAuthor
  echo "  Version:      " & pluginVersion
  echo "  Version date: " & pluginVersionDate
  echo "--------------------------------------------"
  echo " "
pluginInfo()


proc templatesGenerate*(db: DbConn, userID, templateName: string): string =
  ## Generate a template DB
  ##
  ## Only blog, pages and settings will be copied to this DB

  if templateName == "":
    return "No templatename was specified"

  # Check if a template with the same name exists, then exit
  if dirExists("plugins/templates/archive/" & templateName):
    return "A template with that name already exists"
  createDir("plugins/templates/archive/" & templateName)


  # Connect to DB
  var dbTmpl: DbConn
  try:
    dbTmpl = open(connection="plugins/templates/archive/" & templateName & "/" & templateName & ".db", user="template", password="", database=templateName)
  except:
    return "An error occured trying to establish DB connection"


  
  # Copy style.css
  if not fileExists("public/css/style.css"):
    return "The stylesheet could not be found"
    
  copyFile("public/css/style.css", "plugins/templates/archive/" & templateName & "/style.css")



  # Copy js.js
  if not fileExists("public/js/js.js"):
    return "The javascript file could not be found"
    
  copyFile("public/js/js.js", "plugins/templates/archive/" & templateName & "/js.js")



  # Copy all images
  copyDir("public/images", "plugins/templates/archive/" & templateName & "/images")



  # Create tables
  if not dbTmpl.tryExec(sql"""
  create table if not exists settings(
    id INTEGER primary key,
    analytics TEXT,
    head TEXT,
    footer TEXT,
    navbar TEXT,
    title TEXT,
    disabled INTEGER
  );""", []):
    echo " - Database: settings table already exists"

  if not dbTmpl.tryExec(sql"""
  create table if not exists pages(
    id INTEGER primary key,
    author_id INTEGER NOT NULL,
    status INTEGER NOT NULL,
    name VARCHAR(200) NOT NULL,
    url VARCHAR(200) NOT NULL UNIQUE,
    description TEXT,
    head TEXT,
    navbar TEXT,
    footer TEXT,
    standardhead INTEGER,
    standardnavbar INTEGER,
    standardfooter INTEGER,
    tags VARCHAR(1000),
    category VARCHAR(1000),
    date_start VARCHAR(100) ,
    date_end VARCHAR(100) ,
    views INTEGER,
    public INTEGER,
    changes INTEGER,
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now')),

    foreign key (author_id) references person(id)
  );""", []):
    echo " - Database: pages table already exists"

  if not dbTmpl.tryExec(sql"""
  create table if not exists blog(
    id INTEGER primary key,
    author_id INTEGER NOT NULL,
    status INTEGER NOT NULL,
    name VARCHAR(200) NOT NULL,
    url VARCHAR(200) NOT NULL UNIQUE,
    description TEXT,
    head TEXT,
    navbar TEXT,
    footer TEXT,
    standardhead INTEGER,
    standardnavbar INTEGER,
    standardfooter INTEGER,
    tags VARCHAR(1000),
    category VARCHAR(1000),
    date_start VARCHAR(100) ,
    date_end VARCHAR(100) ,
    views INTEGER,
    public INTEGER,
    changes INTEGER,
    modified timestamp not null default (STRFTIME('%s', 'now')),
    creation timestamp not null default (STRFTIME('%s', 'now')),

    foreign key (author_id) references person(id)
  );""", []):
    echo " - Database:blog table already exists"

  # Copy pages
  let oldPages = getAllRows(db, sql"SELECT status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public FROM pages")
  for page in oldPages:
    discard insertID(dbTmpl, sql"INSERT INTO pages (status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public, author_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", page[0], page[1], page[2], page[3], page[4], page[5], page[6], page[7], page[8], page[9], page[10], page[11], page[12], page[13], page[14], userID)

  # Copy blogpages
  let oldBlog = getAllRows(db, sql"SELECT status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public FROM blog")
  for page in oldBlog:
    discard insertID(dbTmpl, sql"INSERT INTO blog (status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public, author_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", page[0], page[1], page[2], page[3], page[4], page[5], page[6], page[7], page[8], page[9], page[10], page[11], page[12], page[13], page[14], userID)

  # Copy settings
  let oldSettings = getAllRows(db, sql"SELECT analytics, head, footer, navbar, title, disabled FROM settings")
  for page in oldSettings:
    discard insertID(dbTmpl, sql"INSERT INTO settings (analytics, head, footer, navbar, title, disabled) VALUES (?, ?, ?, ?, ?, ?)", page[0], page[1], page[2], page[3], page[4], page[5])

  return "Template generated. Name: " & templateName
  

proc templatesDelete*(templateName: string): string =
  ## Delete a template (deletes the folder)

  if not dirExists("plugins/templates/archive/" & templateName):
    return "No template was found with the name: " & templateName

  removeDir("plugins/templates/archive/" & templateName)
  return (templateName & " was deleted")


proc templatesApply*(db: DbConn, userID, templateName: string): string =
  ## Apply a template

  if templateName == "":
    return "No templatename was specified"

  if not dirExists("plugins/templates/archive/" & templateName):
    return "No template was found with the name: " & templateName

  # Connect to DB
  var dbTmpl: DbConn
  try:
    dbTmpl = open(connection="plugins/templates/archive/" & templateName & "/" & templateName & ".db", user="template", password="", database=templateName)
  except:
    return "An error occured trying to establish DB connection"


  # Copy style.css
  if fileExists("plugins/templates/archive/" & templateName & "/style.css"):
    copyFile("plugins/templates/archive/" & templateName & "/style.css", "public/css/style.css")
    


  # Copy js.js
  if fileExists("plugins/templates/archive/" & templateName & "/js.js"):
    copyFile("plugins/templates/archive/" & templateName & "/js.js", "public/js/js.js")
    


  # Copy all images
  if dirExists("plugins/templates/archive/" & templateName & "/images"):
    copyDir("plugins/templates/archive/" & templateName & "/images", "public/images")


  # Copy pages
  let oldPages = getAllRows(dbTmpl, sql"SELECT status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public FROM pages")
  for page in oldPages:
    if tryInsertID(db, sql"INSERT INTO pages (status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public, author_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", page[0], page[1], page[2], page[3], page[4], page[5], page[6], page[7], page[8], page[9], page[10], page[11], page[12], page[13], page[14], userID) < 0:

      # Delete conflicting page
      exec(db, sql"DELETE FROM pages WHERE url = ?", page[2])
      discard tryInsertID(db, sql"INSERT INTO pages (status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public, author_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", page[0], page[1], page[2], page[3], page[4], page[5], page[6], page[7], page[8], page[9], page[10], page[11], page[12], page[13], page[14], userID)


  # Copy blogpages
  let oldBlog = getAllRows(dbTmpl, sql"SELECT status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public FROM blog")
  for page in oldBlog:
    if tryInsertID(db, sql"INSERT INTO blog (status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public, author_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", page[0], page[1], page[2], page[3], page[4], page[5], page[6], page[7], page[8], page[9], page[10], page[11], page[12], page[13], page[14], userID) < 0:

      # Delete conflicting page
      exec(db, sql"DELETE FROM blog WHERE url = ?", page[2])
      discard tryInsertID(db, sql"INSERT INTO blog (status, name, url, description, head, navbar, footer, standardhead, standardnavbar, standardfooter, tags, category, date_start, date_end, public, author_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", page[0], page[1], page[2], page[3], page[4], page[5], page[6], page[7], page[8], page[9], page[10], page[11], page[12], page[13], page[14], userID)


  # Copy settings
  let oldSettings = getAllRows(dbTmpl, sql"SELECT analytics, head, footer, navbar, title, disabled FROM settings")
  for page in oldSettings:
    #if not tryExec(db, sql"UPDATE settings SET analytics = ?, head = ?, footer = ?, navbar = ?, title = ?, disabled = ?", page[0], page[1], page[2], page[3], page[4], page[5]):
    #  return "Error updating settings table"
    exec(db, sql"UPDATE settings SET analytics = ?, head = ?, footer = ?, navbar = ?, title = ?, disabled = ?", page[0], page[1], page[2], page[3], page[4], page[5])

  return "Template has been loaded"



include "html.tmpl"


proc templatesStart*(db: DbConn) =
  ## Required proc. Will run on each program start
  ##
  ## If there's no need for this proc, just
  ## discard it. The proc may not be removed.

  echo "Templates: Started"