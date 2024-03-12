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
    jsonrpc-el = {
      url = "https://elpa.gnu.org/packages/jsonrpc-1.0.25.tar";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, copilot-el, jsonrpc-el, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # currently only version 1.0.17 is available in nixpkgs. 1.0.24 is required for copilot.el.
        jsonrpc = pkgs.emacsPackages.elpaBuild {
          pname = "jsonrpc";
          ename = "jsonrpc";
          version = "1.0.24";
          src = "${jsonrpc-el}/jsonrpc.el";
          packageRequires = [ pkgs.emacs ];
        };

        # copilot.el is not on MELPA, so we need to build it ourselves
        copilot = pkgs.emacsPackages.trivialBuild {
          pname = "copilot";
          version = "2023-11-08";
          packageRequires = with pkgs.emacsPackages; [
            dash
            editorconfig
            s
            jsonrpc
          ];
          preInstall = ''
            mkdir -p $out/share/emacs/site-lisp
            cp -vr $src/dist $out/share/emacs/site-lisp
          '';
          src = copilot-el;
          meta.homepage = "https://github.com/zerolfx/copilot.el/";
        };

      in {
        packages = {
          inherit copilot;
          inherit jsonrpc;
        };
      }) // {
        overlays.default = final: prev: {
          emacsPackages = prev.emacsPackages // {
            inherit (self.packages.${prev.system}) copilot jsonrpc;
          };
        };
      };
}

