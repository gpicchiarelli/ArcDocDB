(:schema-version 1
 :kind :ci-toolchain-lock
 :sbcl-version "2.6.9"
 :recipe-path ".github/actions/setup-sbcl/action.yml"
 :observed-date "2026-10-17"
 :digest-method :sha256-of-downloaded-bytes
 :platforms
 ((:runner "ubuntu-24.04" :runner-os "Linux" :architecture "x86_64"
   :recipe-id "sbcl-2.6.9-linux-binary-v1"
   :distribution
   (:kind :binary :version "2.6.9"
    :url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.6.9/sbcl-2.6.9-x86-64-linux-binary.tar.bz2"
    :sha256 "39fac28407405841003e4c2abfbe0d96abd93b7701e8b61cdd35e713943b46d6")
   :bootstrap NIL :build NIL)
  (:runner "macos-15" :runner-os "macOS" :architecture "arm64"
   :recipe-id "sbcl-2.6.9-darwin-source-v1"
   :distribution
   (:kind :source :version "2.6.9"
    :url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.6.9/sbcl-2.6.9-source.tar.bz2"
    :sha256 "c6fd1d735570eb4ff34caf9609988ca77ed0bd12b55d09a4fed075be890da513")
   :bootstrap
   (:kind :binary :version "2.4.0" :architecture "arm64"
    :url "https://downloads.sourceforge.net/project/sbcl/sbcl/2.4.0/sbcl-2.4.0-arm64-darwin-binary.tar.bz2"
    :sha256 "1d01fac2d9748f769c9246a0a11a2c011d7843337f8f06ca144f5a500e10c117")
   :build
   (:arch "arm64" :dynamic-space-mib 2048
    :with-features ("sb-thread") :without-features ("sb-core-compression")
    :xc-host "sbcl --dynamic-space-size 2048 --noinform --no-sysinit --no-userinit --disable-debugger"
    :environment (("CC" "clang") ("LC_ALL" "C")
                  ("SBCL_MACOSX_VERSION_MIN" "15.0") ("SBCL_MAKE_JOBS" "-j2")
                  ("SBCL_CONTRIB_BLOCKLIST" ""))
    :compiler-origin :runner-apple-clang
    :compiler-version :record-at-installation
    :installed-output-sha256 NIL :installed-output-policy :measure-on-runner)))
 :upstream
 (:platform-table "https://www.sbcl.org/platform-table.html"
  :build-instructions "https://github.com/sbcl/sbcl/blob/68a6b27d7ec8a8be45024d5e62db4f316e5ac7ea/INSTALL"
  :source-tag "sbcl-2.6.9" :source-tag-type :tag
  :source-tag-object "236c6a4acf3c08e61778012f4b01ede60bf68c59"
  :source-commit "68a6b27d7ec8a8be45024d5e62db4f316e5ac7ea")
 :actions
 ((:repository "actions/checkout" :tag "v4.2.2" :ref-type :commit
   :commit "11bd71901bbe5b1630ceea73d27597364c9af683"
   :api-ref "https://api.github.com/repos/actions/checkout/git/ref/tags/v4.2.2")
  (:repository "actions/upload-artifact" :tag "v4.6.2" :ref-type :commit
   :commit "ea165f8d65b6e75b540449e92b4886f43607fa02"
   :api-ref "https://api.github.com/repos/actions/upload-artifact/git/ref/tags/v4.6.2")
  (:repository "actions/download-artifact" :tag "v4.3.0" :ref-type :commit
   :commit "d3f86a106a0bac45b974a628896c90dbdf5c8093"
   :api-ref "https://api.github.com/repos/actions/download-artifact/git/ref/tags/v4.3.0")))
