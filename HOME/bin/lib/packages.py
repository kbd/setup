import io
import logging
import re
import subprocess
import zipfile

from lib.utils import run

log = logging.getLogger()


def install_packages(settings, *args, **kwargs):
    log.info("Installing/upgrading packages")
    module = globals()
    language_filter = kwargs['language_filter']
    for language, params in settings['packages'].items():
        if language_filter and not re.search(language_filter, language):
            log.debug(f"Skipping {language}")
            continue

        log.info(f"Installing/upgrading packages for: {language}")

        # if the name of the "language" matches a function in this module, call
        # the function and pass it a reference to the settings for that "language"
        if language in module:
            # the function does whatever it wants with its settings
            log.debug(f"Found package function for {language}")
            module[language](params)
        else:
            # allow specific commands
            cmd = params['cmd']
            log.debug(f"Executing: {cmd}")
            run(cmd)


def addons(settings, *args, **kwargs):
    log.info("Installing addons")
    for type, params in settings['addons'].items():
        log.info(f"Installing addons for {type!r}")
        for addon in params['addons']:
            log.info(f"Downloading addon {addon!r}")
            result = addon_install(type, addon, params['installation_path'])
            if result:
                log.info(f"Successfully installed {addon!r}")
            else:
                log.warning(f"Couldn't install {addon!r}")

    log.info("Finished installing addons")


def addon_install(type, name, installation_path):
    import requests

    uri_pattern = 'http://www.curse.com/addons/wow/{}/download'

    # get the download page
    log.debug(f"Requesting download page for {name!r}")
    response = requests.get(uri_pattern.format(name))
    if response.status_code != 200:
        log.warning(f"Error getting download page for {name}")
        return False

    # parse out the download link
    # download links look like:
    # <p>If your download doesn't begin <a data-project="4872" data-file="887016" data-href="http://addons.curse.cursecdn.com/files/887/16/Recount-v6.2.0f_release.zip" class="download-link" href="#">click here</a>.</p>
    log.debug("Parsing out download uri")
    regex = r'<a\s+.*?data-href="([^"]+)".*?class="download-link"'
    match = re.search(regex, response.text)
    download_uri = match.group(1)

    # download the addon
    log.debug(f"Downloading from {download_uri!r}")
    response = requests.get(download_uri)
    if response.status_code != 200:
        return False

    log.debug(f"Extracting zip content to {installation_path!r}")
    try:
        file = io.BytesIO(response.content)
        zfile = zipfile.ZipFile(file)
        zfile.extractall(installation_path)
    except:
        log.exception(f"Couldn't extract files for {name!r}")
        return False

    return True


def vscode(package_settings):
    EXTENSIONS_CONFIG_PATH = 'conf/vscode.txt'
    log.info("Updating Visual Studio Code extensions")

    # show currently installed extensions
    cmd = ['code', '--list-extensions']
    current_extensions = set(s.strip() for s in run(cmd, cap='stdout').splitlines())
    expected_extensions = set(s.strip() for s in open(EXTENSIONS_CONFIG_PATH).readlines())

    fmt = lambda s: ', '.join(sorted(s, key=str.lower))

    log.debug(f"Current extensions are: {fmt(current_extensions)}")
    log.debug(f"Expected extensions are: {fmt(expected_extensions)}")

    # install any missing extensions
    missing = expected_extensions - current_extensions
    for package in sorted(missing):
        log.info(f"Installing missing package: {package}")
        run(['code', '--install-extension', package])

    # report any extensions that are installed that aren't in source control
    unexpected = current_extensions - expected_extensions
    if unexpected:
        log.info(f"The following extensions are installed but not in source control: {fmt(unexpected)}")
