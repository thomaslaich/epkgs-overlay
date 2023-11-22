{
  description =
    "A flake that provides an overlay for emacs packages in order to use plugins unavailable in nixpkgs.emacsPackages / MELPA";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    copilot-el = {
      type = "github";
      owner = "zerolfx";
      repo = "copilot.el";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, copilot-el, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        copilot = pkgs.emacsPackages.trivialBuild {
          pname = "lsp-progress";
          version = "2023-11-14";
          packageRequires = with pkgs.emacsPackages; [ dash editorconfig s ];
          preInstall = ''
            mkdir -p $out/share/emacs/site-lisp
            cp -vr $src/dist $out/share/emacs/site-lisp
          '';
          src = copilot-el;
          meta.homepage = "https://github.com/zerolfx/copilot.el/";
        };

      in {
        packages = {
          default = copilot;
          inherit copilot;
        };
      }) // {
        overlays.default = final: prev: {
          emacsPackages = prev.emacsPackages // {
            inherit (self.packages.${prev.system}) copilot;
          };
        };
      };
}

