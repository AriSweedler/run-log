# run-log's package: the four bins, with their library defaults pinned to ari-zshlib's store copy
# and python3 to the store's. The sources keep their live defaults (Ari's dotfiles paths), so a
# checkout's bin/run_log runs unpackaged on a machine that has them.
{ lib, stdenvNoCC, zsh, python3, zshlib }:
let
  libDefault = "\${ARI_ZSHLIB:-\${HOME}/.config/zsh/plugins}";
  pluginsDefault = "\${ARI_PLUGINS:-\${HOME}/.config/zsh/plugins}";
  paneDefault = "\"\${XDG_CONFIG_HOME:-\$HOME/.config}/claude/lib/tmux-pane.sh\"";
in
stdenvNoCC.mkDerivation {
  pname = "run-log";
  version = "0";
  src = ./bin;
  buildInputs = [ zsh python3 ];
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm755 -t $out/bin run_log run_log-capture.py irun strip-ansi
    patchShebangs $out/bin
    substituteInPlace $out/bin/run_log \
      --replace-fail ${lib.escapeShellArg libDefault} ${lib.escapeShellArg "\${ARI_ZSHLIB:-${zshlib}/lib}"} \
      --replace-fail ${lib.escapeShellArg paneDefault} ${zshlib}/lib/tmux-pane.sh \
      --replace-fail 'python3 -I "''${CAPTURE_HELPER}"' '${python3}/bin/python3 -I "''${CAPTURE_HELPER}"'
    substituteInPlace $out/bin/strip-ansi \
      --replace-fail ${lib.escapeShellArg pluginsDefault} ${lib.escapeShellArg "\${ARI_PLUGINS:-${zshlib}/lib}"}
    runHook postInstall
  '';

  # A capture of a plain command lands, holds its output and its exit code.
  doInstallCheck = true;
  installCheckPhase = ''
    export HOME=$TMPDIR ZDOTDIR=$TMPDIR
    $out/bin/run_log --dir $TMPDIR/caps --no-copy -- echo hello >/dev/null
    grep -qx hello $TMPDIR/caps/*/stdout.plain
    grep -qx exit=0 $TMPDIR/caps/*/metadata
    [[ "$(printf '\033[31mred\033[0m' | $out/bin/strip-ansi)" == red ]]
    # Every library file the bins name exists in the pinned ari-zshlib.
    for f in log.zsh strip_ansi.zsh tmux-pane.sh; do [[ -r ${zshlib}/lib/$f ]] || { echo "ari-zshlib lacks $f"; exit 1; }; done
  '';

  meta.mainProgram = "run_log";
}
