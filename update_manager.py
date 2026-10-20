"""Check GitHub Releases and apply the package matching this installation."""

import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import threading
import urllib.request

from PySide6.QtCore import QObject, Property, QProcess, Signal, Slot


OWNER = 'JoaoVitorSCS1999'
REPOSITORY = 'gamesir-linux-tools-plus'
LATEST_RELEASE_API = (
    f'https://api.github.com/repos/{OWNER}/{REPOSITORY}/releases/latest'
)
MAX_ASSET_SIZE = 1024 * 1024 * 1024


def _version_key(value):
    match = re.fullmatch(r'v?(\d+)\.(\d+)\.(\d+)(?:[-+].*)?', str(value))
    if not match:
        return None
    prerelease = bool(re.search(r'[-+]', str(value)))
    return tuple(int(part) for part in match.groups()) + (0 if prerelease else 1,)


def _installation_kind():
    appimage = os.environ.get('APPIMAGE')
    if appimage and os.path.isfile(appimage):
        return 'appimage', os.path.abspath(appimage)

    installed_file = os.path.abspath(__file__)
    checks = (
        ('rpm', ('rpm', '-qf', installed_file)),
        ('deb', ('dpkg-query', '-S', installed_file)),
        ('arch', ('pacman', '-Qo', installed_file)),
    )
    for kind, command in checks:
        if not shutil.which(command[0]):
            continue
        try:
            result = subprocess.run(command, capture_output=True, text=True,
                                    timeout=3, check=False)
            if result.returncode == 0:
                return kind, installed_file
        except (OSError, subprocess.TimeoutExpired):
            pass
    return 'unsupported', installed_file


class UpdateManager(QObject):
    """Background release checker and installer exposed to QML."""

    stateChanged = Signal()
    _checkFinished = Signal(object)
    _downloadProgress = Signal(int, int)
    _downloadFinished = Signal(str, str)

    def __init__(self, current_version, parent=None):
        super().__init__(parent)
        self._current_version = str(current_version)
        self._kind, self._installed_path = _installation_kind()
        self._latest_version = ''
        self._release_url = ''
        self._asset = None
        self._update_available = False
        self._checking = False
        self._busy = False
        self._progress = 0
        self._installed = False
        self._status = ''
        self._download_path = ''
        self._process = None
        self._checkFinished.connect(self._finish_check)
        self._downloadProgress.connect(self._set_progress)
        self._downloadFinished.connect(self._finish_download)

    @Property(bool, notify=stateChanged)
    def updateAvailable(self):
        return self._update_available

    @Property(str, notify=stateChanged)
    def latestVersion(self):
        return self._latest_version

    @Property(bool, notify=stateChanged)
    def checking(self):
        return self._checking

    @Property(bool, notify=stateChanged)
    def busy(self):
        return self._busy

    @Property(int, notify=stateChanged)
    def progress(self):
        return self._progress

    @Property(bool, notify=stateChanged)
    def installationComplete(self):
        return self._installed

    @Property(str, notify=stateChanged)
    def status(self):
        return self._status

    @Property(str, notify=stateChanged)
    def installationKind(self):
        return self._kind

    @Property(bool, notify=stateChanged)
    def canInstall(self):
        return bool(self._asset and self._asset.get('digest', '').startswith('sha256:')
                    and self._kind in ('rpm', 'deb', 'arch', 'appimage'))

    @Slot()
    def checkForUpdates(self):
        if self._checking:
            return
        self._checking = True
        self._status = 'Checking for updates…'
        self.stateChanged.emit()
        threading.Thread(target=self._check_worker, daemon=True).start()

    def _check_worker(self):
        try:
            request = urllib.request.Request(
                LATEST_RELEASE_API,
                headers={'Accept': 'application/vnd.github+json',
                         'User-Agent': 'Deadband-Updater'})
            with urllib.request.urlopen(request, timeout=12) as response:
                release = json.load(response)
            latest = str(release.get('tag_name', '')).lstrip('v')
            current_key = _version_key(self._current_version)
            latest_key = _version_key(latest)
            if not latest_key or not current_key:
                raise ValueError('Could not parse the installed or release version')
            if latest_key <= current_key:
                self._checkFinished.emit({'available': False, 'latest': latest})
                return

            suffix = {
                'rpm': '.noarch.rpm',
                'deb': '_all.deb',
                'arch': '-any.pkg.tar.zst',
                'appimage': '-x86_64.AppImage',
            }.get(self._kind)
            expected_prefix = {
                'rpm': f'deadband-{latest}-',
                'deb': f'deadband_{latest}_',
                'arch': f'deadband-{latest}-',
                'appimage': f'Deadband-{latest}-',
            }.get(self._kind, '\0')
            assets = release.get('assets', [])
            candidates = [a for a in assets if a.get('name', '').startswith(expected_prefix)
                          and a.get('name', '').endswith(suffix or '\0')]
            asset = candidates[0] if len(candidates) == 1 else None
            self._checkFinished.emit({
                'available': True,
                'latest': latest,
                'url': release.get('html_url', ''),
                'asset': asset,
            })
        except Exception as exc:
            self._checkFinished.emit({'error': str(exc)})

    @Slot(object)
    def _finish_check(self, result):
        self._checking = False
        if result.get('error'):
            self._status = 'Could not check for updates: ' + result['error']
            self.stateChanged.emit()
            return
        self._latest_version = result.get('latest', '')
        self._update_available = bool(result.get('available'))
        self._release_url = result.get('url', '')
        self._asset = result.get('asset')
        if self._update_available:
            if not self._asset:
                self._status = 'An update is available, but there is no package for this installation type.'
            elif not self._asset.get('digest', '').startswith('sha256:'):
                self._status = 'The release does not provide a SHA-256 digest; automatic install is disabled.'
            else:
                self._status = 'Version ' + self._latest_version + ' is ready to install.'
        else:
            self._status = 'Deadband is up to date.'
        self.stateChanged.emit()

    @Slot()
    def installUpdate(self):
        if not self.canInstall or self._busy:
            return
        size = int(self._asset.get('size', 0))
        if size <= 0 or size > MAX_ASSET_SIZE:
            self._status = 'The release package has an invalid size.'
            self.stateChanged.emit()
            return
        self._busy = True
        self._progress = 0
        self._installed = False
        self._status = 'Downloading version ' + self._latest_version + '…'
        self.stateChanged.emit()
        threading.Thread(target=self._download_worker, daemon=True).start()

    def _download_worker(self):
        temp_path = ''
        try:
            asset = self._asset
            url = asset.get('browser_download_url', '')
            if not url.startswith('https://github.com/'):
                raise ValueError('The release asset URL is not a GitHub HTTPS URL')
            expected = asset['digest'].removeprefix('sha256:').lower()
            if not re.fullmatch(r'[0-9a-f]{64}', expected):
                raise ValueError('The release asset SHA-256 digest is invalid')
            request = urllib.request.Request(url, headers={'User-Agent': 'Deadband-Updater'})
            with urllib.request.urlopen(request, timeout=30) as response:
                if self._kind == 'appimage':
                    directory = os.path.dirname(self._installed_path)
                    fd, temp_path = tempfile.mkstemp(prefix='.deadband-update-', dir=directory)
                else:
                    fd, temp_path = tempfile.mkstemp(
                        prefix='deadband-update-', suffix='-' + asset['name'])
                digest = hashlib.sha256()
                received = 0
                with os.fdopen(fd, 'wb') as output:
                    while True:
                        chunk = response.read(1024 * 1024)
                        if not chunk:
                            break
                        received += len(chunk)
                        if received > int(asset['size']) or received > MAX_ASSET_SIZE:
                            raise ValueError('The downloaded package is larger than expected')
                        output.write(chunk)
                        digest.update(chunk)
                        self._downloadProgress.emit(received, int(asset['size']))
            if received != int(asset['size']) or digest.hexdigest() != expected:
                raise ValueError('Downloaded package failed size or SHA-256 verification')
            self._downloadFinished.emit(temp_path, '')
        except Exception as exc:
            if temp_path:
                try:
                    os.unlink(temp_path)
                except OSError:
                    pass
            self._downloadFinished.emit('', str(exc))

    @Slot(int, int)
    def _set_progress(self, received, total):
        self._progress = min(100, int(received * 100 / max(1, total)))
        self._status = f'Downloading update… {self._progress}%'
        self.stateChanged.emit()

    @Slot(str, str)
    def _finish_download(self, path, error):
        if error:
            self._busy = False
            self._status = 'Update download failed: ' + error
            self.stateChanged.emit()
            return
        if self._kind == 'appimage':
            try:
                os.chmod(path, 0o755)
                os.replace(path, self._installed_path)
                self._busy = False
                self._progress = 100
                self._installed = True
                self._status = 'Update installed. Close and reopen Deadband to use it.'
            except OSError as exc:
                try:
                    os.unlink(path)
                except OSError:
                    pass
                self._busy = False
                self._status = 'Could not replace this AppImage: ' + str(exc)
            self.stateChanged.emit()
            return

        managers = {
            'rpm': (('dnf5', 'dnf'), ['install', '-y', path]),
            'deb': (('apt-get',), ['install', '-y', path]),
            'arch': (('pacman',), ['-U', '--noconfirm', path]),
        }
        manager_names, arguments = managers[self._kind]
        manager = next((shutil.which(name) for name in manager_names
                        if shutil.which(name)), None)
        pkexec = shutil.which('pkexec')
        if not manager or not pkexec:
            self._busy = False
            self._download_path = path
            self._status = ('Package downloaded and verified, but a system authorization '
                            'helper or package manager is unavailable.')
            self.stateChanged.emit()
            return

        self._download_path = path
        self._status = 'Waiting for system authorization…'
        self._process = QProcess(self)
        self._process.finished.connect(self._install_finished)
        self._process.errorOccurred.connect(self._install_error)
        self._process.started.connect(self._install_started)
        self.stateChanged.emit()
        self._process.start(pkexec, [manager, *arguments])

    @Slot(int, QProcess.ExitStatus)
    def _install_finished(self, exit_code, _exit_status):
        self._busy = False
        if self._download_path:
            try:
                os.unlink(self._download_path)
            except OSError:
                pass
            self._download_path = ''
        if exit_code == 0:
            self._progress = 100
            self._installed = True
            self._status = 'Update installed. Close and reopen Deadband to use it.'
        else:
            self._status = 'The package manager cancelled or could not install the update.'
        self.stateChanged.emit()

    @Slot()
    def _install_started(self):
        self._status = 'Installing update…'
        self.stateChanged.emit()

    @Slot(QProcess.ProcessError)
    def _install_error(self, _error):
        if (self._process
                and self._process.error() == QProcess.ProcessError.FailedToStart):
            self._busy = False
            if self._download_path:
                try:
                    os.unlink(self._download_path)
                except OSError:
                    pass
                self._download_path = ''
            self._status = 'Could not start the system authorization prompt.'
            self.stateChanged.emit()
