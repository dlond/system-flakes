{
  pkgs,
  scheme ? "medium", # "basic", "small", "medium", "full"
  withPandoc ? true,
  withBiber ? true,
  withGraphics ? true,
  withPython ? false, # for pythontex
  extraPackages ? [],
  projectName ? "latex-dev",
}: let
  packages = import ../lib/packages.nix {inherit pkgs;};
  inherit (pkgs) lib;

  # Select TeX scheme
  texlivePackage =
    if scheme == "basic" then pkgs.texlive.combined.scheme-basic
    else if scheme == "small" then pkgs.texlive.combined.scheme-small
    else if scheme == "medium" then pkgs.texlive.combined.scheme-medium
    else pkgs.texlive.combined.scheme-full;

in pkgs.mkShell {
  name = "${projectName}-shell";

  buildInputs =
    [texlivePackage]
    ++ packages.latex.core
    ++ packages.common.lsp
    ++ lib.optionals withPandoc packages.latex.pandoc
    ++ lib.optionals withBiber [pkgs.biber]
    ++ lib.optionals withGraphics packages.latex.graphics
    ++ lib.optionals withPython packages.latex.python
    ++ extraPackages;

  shellHook = ''
    echo "📄 LaTeX Development Environment: ${projectName}"
    echo "TeX scheme: ${scheme}"
    echo "pdflatex: $(pdflatex --version | head -n1)"

    ${if withPandoc then ''
      echo "Pandoc: $(pandoc --version | head -n1)"
    '' else ""}

    ${if withBiber then ''
      echo "Biber available for bibliography management"
    '' else ""}

    # Create standard directories if they don't exist
    [ ! -d "figures" ] && mkdir -p figures
    [ ! -d "sections" ] && mkdir -p sections

    # Set up latexmk if available
    if command -v latexmk >/dev/null 2>&1; then
      echo "💡 Tip: Use 'latexmk -pvc -pdf main.tex' for continuous compilation"

      # Create latexmkrc if it doesn't exist
      if [ ! -f ".latexmkrc" ]; then
        cat > .latexmkrc << 'EOF'
$pdf_mode = 1;
$pdflatex = 'pdflatex -interaction=nonstopmode -synctex=1 %O %S';
$pdf_previewer = 'open -a Skim';
$clean_ext = 'synctex.gz synctex.gz(busy) run.xml tex.bak bbl bcf fdb_latexmk run tdo %R-blx.bib';
EOF
        echo "Created .latexmkrc with default settings"
      fi
    fi

    echo "✅ Environment ready!"
  '';

  # LaTeX-specific environment variables
  TEXMFHOME = "$PWD/texmf";
}