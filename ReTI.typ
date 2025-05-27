#let load_code(path) = {
  return read(path).split("\n").filter(x => x.len() > 1).map(x => x.replace("\r", ""))
}

#let draw_reti_table(file_path, storage_name: "S", start_idx: 0, lang: "de") = {
  let words = (:)
  if lang == "de" {
    words = (
      "if": "falls",
      "command": "Befehl",
      "comment": "Kommentar" 
    )
  } else if lang == "en" {
    words = (
      "if": "if",
      "command": "Command",
      "comment": "Comment" 
    )
  }

  let to_string(it) = {
    if type(it) == str {
      it
    } else if type(it) != content {
      str(it)
    } else if it.has("text") {
      it.text
    } else if it.has("children") {
      it.children.map(to_string).join()
    } else if it.has("body") {
      to_string(it.body)
    } else if it == [ ] {
      " "
    }
  }
  
  let ACC = "ACC"
  let PC = "PC"

  let autodoc(it) = {
    let it_split = it.split(" ")
    let fn = it_split.at(0)
    let num = it_split.at(1)
    if fn == "LOADI" {
      $ACC := #num$
    } else if fn == "LOAD" {
      $ACC := #storage_name$+$(#num)$
    } else if fn == "STORE" {
      $#storage_name$+$(#num) := ACC$
    } else if fn == "ADD" {
      $ACC := ACC + #storage_name (#num)$
    } else if fn == "SUB" {
      $ACC := ACC - #storage_name (#num)$
    } else if fn == "ADDI" {
      $ACC := ACC + #num$
    } else if fn == "SUBI" {
      $ACC := ACC - #num$
    } else if fn == "JUMP<" {
      if num.at(0) == "-" {
        $PC := PC - #num.split("-").at(1)", "+words.at("if")+" ACC < 0"$
      } else {
        $PC := PC + #num", "+words.at("if")+" ACC < 0"$
      }
    }else {
      ""
    }
  }

  let code_lines = load_code(file_path)

  let tabled_code = ()
  {
    let idx = start_idx
    for line in code_lines {
      let splitted = line.split("#")
      let c = splitted.at(0)
      let explanation = autodoc(line)

      if splitted.len() >= 2 {
        explanation = splitted.at(1).replace("GEN", to_string(explanation))
      }

      tabled_code.push(str(idx))
      tabled_code.push(raw(c, lang: "sh"))
      tabled_code.push(explanation)
      idx += 1
    }
  }

  table(
    columns: 3,
    table.header("PC", words.at("command"), words.at("comment")),
    ..tabled_code
  )
}

#let interpret_reti(file_path, init_storage, storage_name: "S") = {
  let storage = init_storage.map(x => x)
  let code_lines = load_code(file_path).map(x => x.split("#").at(0))

  let PC = 0
  let ACC = 0
  let steps = ()
  while PC < code_lines.len() {
    let line = code_lines.at(PC)

    let cmd_split = line.split(" ")
    let fn = cmd_split.at(0)
    let num = int(cmd_split.at(1))


    if fn == "JUMP<" {
      if (ACC <= 0) {
        steps.push((PC, str(ACC) + " <= 0, PC = " + str(PC + num)))
        PC += num
        continue
      } else {
        steps.push((PC, str(ACC) + " > 0, kein Sprung"))
      }
    } else if fn == "LOADI" {
      ACC = num
      steps.push((PC, "ACC = " + str(num)))
    } else if fn == "LOAD" {
      ACC = storage.at(num)
      steps.push((PC, "ACC = " + str(storage.at(num))))
    } else if fn == "STORE" {
      storage.at(num) = ACC
      steps.push((PC, storage_name + "("+str(num)+") = " + str(ACC)))
    } else if fn == "ADD" {
      ACC += storage.at(num)
      steps.push((PC, "ACC = " + str(ACC) + " + " + str(storage.at(num))))
    } else if fn == "SUB" {
      ACC -= storage.at(num)
      steps.push((PC, "ACC = " + str(ACC) + " - " + str(storage.at(num))))
    } else if fn == "ADDI" {
      ACC += num
      steps.push((PC, "ACC = " + str(ACC) + " + " + str(num)))
    } else if fn == "SUBI" {
      ACC -= num
      steps.push((PC, "ACC = " + str(ACC) + " - " + str(num)))
    } else {
      panic("Unknown command " + fn)
    }

    PC += 1

  }

  return (storage, steps)
}
