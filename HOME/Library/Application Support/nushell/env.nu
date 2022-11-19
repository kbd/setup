let-env PROMPT_COMMAND = {
    let-env PROMPT_RETURN_CODE = $env.LAST_EXIT_CODE
    let-env PROMPT_HR = (term size | get columns)
    let-env PROMPT_PATH = ($env.PWD | str replace ^($nu.home-path) ~)
    let-env PROMPT_PREFIX = 'NU'
    prompt
}
let-env PROMPT_COMMAND_RIGHT = { date format '%m/%d %H:%M:%S' }
let-env PROMPT_INDICATOR = { "" }
