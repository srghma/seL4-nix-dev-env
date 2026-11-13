{
  stdenv,
  writeText,
  isabelle,
  isabelleSrc,
  fetchYarnDeps,
  yarnConfigHook,
  nodejs,
  yarn,
  vsce,
  unzip,
  writableTmpDirAsHomeHook,
}:

let
  buildScript = writeText "BuildVSCode.scala" ''
    import scala.jdk.CollectionConverters._
    import isabelle._
    import isabelle.vscode._

    object BuildVSCode {
      private def options_json(options: Options): String = {
        val relevant_options =
          Set(
            "editor_output_state",
            "auto_time_start",
            "auto_time_limit",
            "auto_nitpick",
            "auto_sledgehammer",
            "auto_methods",
            "auto_quickcheck",
            "auto_solve_direct",
            "sledgehammer_provers",
            "sledgehammer_timeout")

        (for {
          opt <- options.iterator
          if opt.for_vscode || opt.for_content || relevant_options.contains(opt.name)
        } yield {
          val (enum_values, enum_descriptions) = opt.typ match {
            case Options.Bool => (
              Some(List("", "true", "false")),
              Some(List("Use System Preference.", "Enable.", "Disable.")))
            case _ => (None, None)
          }

          val default = opt.name match {
            case "vscode_unicode_symbols_output" => "true"
            case "vscode_unicode_symbols_edits" => "true"
            case "vscode_pide_extensions" => "true"
            case "vscode_html_output" => "true"
            case _ => ""
          }

          quote("isabelle.options." + opt.name) + ": " +
            JSON.Format(
              JSON.Object(
                "type" -> "string",
                "default" -> default,
                "description" -> opt.description) ++
              JSON.optional("enum" -> enum_values) ++
              JSON.optional("enumDescriptions" -> enum_descriptions)) + ","
        }).mkString
      }

      def main(args: Array[String]): Unit = {
        val build_dir = Path.explode(args(0))
        val options = Options.init()
        val progress = new Console_Progress()

        val extension_dir = Path.explode("$ISABELLE_VSCODE_HOME/extension")
        val context = setup.Build.component_context(extension_dir.java_path).nn
        val extension_sources =
          for (name <- context.sources.nn.asScala.toList if File.is_scala(name))
          yield extension_dir + Path.explode(name)

        Component_VSCode.make_symbol_provider().write(build_dir)
        val scala_sources = (build_dir + Component_VSCode.symbol_static) :: extension_sources

        val modules =
          List(
            Scalajs.Module("output_view", "isabelle.vscode.extension.Output_View"),
            Scalajs.Module("sledgehammer_view", "isabelle.vscode.extension.Sledgehammer_View"),
            Scalajs.Module("state_panel", "isabelle.vscode.extension.State_Panel"),
            Scalajs.Module("symbols_view", "isabelle.vscode.extension.Symbols_View"))

        progress.echo("Compiling scalajs modules ...")
        val js_dir = Isabelle_System.make_directory(build_dir + Path.basic("js"))
        val scalajs_result = Scalajs.compile(scala_sources.map(_.file), modules, js_dir)

        scalajs_result.messages.foreach(_.output(progress))
        if (!scalajs_result.ok) error("Failed to compile js modules")

        val manifest_text = File.read(extension_dir + Path.basic("MANIFEST"))
        val fonts_dir = Isabelle_System.make_directory(build_dir + Path.basic("fonts"))
        for (entry <- Isabelle_Fonts.fonts()) { Isabelle_System.copy_file(entry.path, fonts_dir) }
        val manifest_text2 =
          manifest_text + cat_lines(
            Isabelle_Fonts.fonts().map(e => "fonts/" + e.path.file_name) :::
              scalajs_result.outputs.map(m => "js/" + m.file_name))
        val manifest_entries2 = split_lines(manifest_text2).filter(_.nonEmpty)

        val manifest_shasum = {
          val a = Shasum.make_meta_info(SHA1.digest(manifest_text2))
          val bs =
            for (name <- manifest_entries2)
              yield Shasum.make(SHA1.digest(build_dir + Path.explode(name)), name)
          Shasum.flat(a :: bs)
        }
        File.write(build_dir + Path.basic("MANIFEST").shasum, manifest_shasum.toString)

        val opt_json = options_json(options)
        val package_path = build_dir + Path.basic("package.json")
        val package_body = File.read(package_path).replacing("\"ISABELLE_OPTIONS\": {}," -> opt_json)
        File.write(package_path, package_body)

        Component_VSCode.build_grammar(options, build_dir, progress = progress)
      }
    }
  '';
in
stdenv.mkDerivation {
  pname = "isabelle-vscode-extension";
  version = "2.0.0";

  src = "${isabelleSrc}/src/Tools/VSCode/extension";

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${isabelleSrc}/src/Tools/VSCode/extension/yarn.lock";
    hash = "sha256-UnsSOa8iAjxdTzF7aPkDaJOj0h1CZYaasbozMTW6u1I=";
  };

  nativeBuildInputs = [
    isabelle
    writableTmpDirAsHomeHook
    yarnConfigHook
    nodejs
    yarn
    vsce
    unzip
  ];

  buildPhase = ''
    runHook preBuild

    substituteInPlace package.json \
      --replace-fail '"vscode": "^1.135.0"' '"vscode": "^1.107.0"' \
      --replace-fail '"@types/vscode": "^1.135.0"' '"@types/vscode": "^1.107.0"'

    cp ${isabelleSrc}/COPYRIGHT LICENSE.txt
    isabelle scala ${buildScript} "$PWD"
    yarn --offline compile
    printf 'y\ny\n' | vsce package --no-dependencies -o isabelle-2.0.0.vsix

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out $out/share/vscode/extensions/isabelle.isabelle
    cp isabelle-2.0.0.vsix $out/
    unzip -q isabelle-2.0.0.vsix -d unpacked
    cp -r unpacked/extension/. $out/share/vscode/extensions/isabelle.isabelle/

    runHook postInstall
  '';
}
