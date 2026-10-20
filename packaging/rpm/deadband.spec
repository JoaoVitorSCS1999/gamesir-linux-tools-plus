%{!?app_version:%global app_version 0.6.0}
%{!?app_release:%global app_release 1}
%{!?_udevrulesdir:%global _udevrulesdir %{_prefix}/lib/udev/rules.d}

Name:           deadband
Version:        %{app_version}
Release:        %{app_release}%{?dist}
Summary:        Linux configuration app for game controllers and mice
License:        MIT
URL:            https://github.com/JoaoVitorSCS1999/gamesir-linux-tools-plus
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       python3
Requires:       python3-pyside6
Requires:       python3-hid
Requires:       libusb1
Requires:       qt6-qtdeclarative

%description
Deadband is a Qt/QML desktop application for configuring supported GameSir
controllers and Logitech gaming mice on Linux.

%prep
%autosetup -n %{name}-%{version}

%build
# The application is Python and QML; no compilation step is required.

%install
install -d %{buildroot}%{_datadir}/deadband
install -m 0644 ./*.py %{buildroot}%{_datadir}/deadband/
rm -f %{buildroot}%{_datadir}/deadband/smoke_test.py
cp -a vendors qml %{buildroot}%{_datadir}/deadband/
install -d %{buildroot}%{_datadir}/deadband/assets
install -m 0644 assets/icon.png assets/icon-48.png assets/icon-64.png \
    assets/icon-128.png assets/glyph-pad.png assets/glyph-pad-dark.png \
    %{buildroot}%{_datadir}/deadband/assets/
install -m 0644 70-gamesir.rules %{buildroot}%{_datadir}/deadband/
install -D -m 0644 70-gamesir.rules \
    %{buildroot}%{_udevrulesdir}/70-gamesir.rules
install -D -m 0644 packaging/udev/70-deadband-g502x.rules \
    %{buildroot}%{_udevrulesdir}/70-deadband-g502x.rules
install -D -m 0644 LICENSE \
    %{buildroot}%{_licensedir}/%{name}/LICENSE
install -D -m 0644 packaging/deadband.desktop \
    %{buildroot}%{_datadir}/applications/deadband.desktop
for size in 48 64 128; do
    install -D -m 0644 assets/icon-${size}.png \
        %{buildroot}%{_datadir}/icons/hicolor/${size}x${size}/apps/deadband.png
done
install -D -m 0644 assets/icon.png \
    %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/deadband.png
install -d %{buildroot}%{_bindir}
cat > %{buildroot}%{_bindir}/deadband <<'EOF'
#!/usr/bin/python3
import runpy
import sys
sys.path.insert(0, '/usr/share/deadband')
runpy.run_path('/usr/share/deadband/deadband.py', run_name='__main__')
EOF
chmod 0755 %{buildroot}%{_bindir}/deadband
install -D -m 0644 completions/bash/deadband \
    %{buildroot}%{_datadir}/bash-completion/completions/deadband
install -D -m 0644 completions/zsh/_deadband \
    %{buildroot}%{_datadir}/zsh/site-functions/_deadband
install -D -m 0644 completions/fish/deadband.fish \
    %{buildroot}%{_datadir}/fish/vendor_completions.d/deadband.fish

%post
udevadm control --reload-rules || :

%files
%{_bindir}/deadband
%{_datadir}/deadband
%{_udevrulesdir}/70-gamesir.rules
%{_udevrulesdir}/70-deadband-g502x.rules
%{_datadir}/applications/deadband.desktop
%{_datadir}/icons/hicolor/*/apps/deadband.png
%{_datadir}/bash-completion/completions/deadband
%{_datadir}/zsh/site-functions/_deadband
%{_datadir}/fish/vendor_completions.d/deadband.fish
%{_licensedir}/%{name}/LICENSE

%changelog
* Mon Oct 19 2026 Deadband contributors - 0.6.0-0.0.dev
- Initial Fedora RPM package
