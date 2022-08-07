let-env PROMPT_COMMAND = {
    let-env PROMPT_HR = (term size | get columns)
    prompt
}
let-env PROMPT_COMMAND_RIGHT = { date format '%m/%d %H:%M:%S' }
let-env PROMPT_INDICATOR = { "" }
