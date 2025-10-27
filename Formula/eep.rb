# frozen_string_literal: true

class Eep < Formula
  desc "Eurostep EXPRESS Parser (Eep)"
  homepage "https://github.com/expresslang/eep-releases"
  version "1.4.45"
  license "BSD-2-Clause"

  on_macos do
    # Intel binary works on both Intel and ARM64 (via Rosetta 2)
    url "https://github.com/expresslang/eep-releases/releases/download/v1.4.45/eep-macos-10.11-x64"
    sha256 "75244abb3e87db07e0f72c7f296119d56951007f6a833993db5e0079b4d66632"
  end

  on_linux do
    # x86-64 binary works on both x86-64 and ARM64 (via QEMU user-mode emulation)
    url "https://github.com/expresslang/eep-releases/releases/download/v1.4.45/eep-linux-x64"
    sha256 "055766308589585932171414721b5151f9c66638ddf52758fc6950098d6ca3b6"
  end

  def install
    bin.install Dir["*"].first => "eep"
  end

  def caveats
    on_macos do
      if Hardware::CPU.arm?
        <<~EOS
          This formula installs an Intel binary that runs on Apple Silicon (ARM64)
          via Rosetta 2. Rosetta 2 will be automatically used if available.

          To install Rosetta 2 if not already installed:
            softwareupdate --install-rosetta
        EOS
      end
    end

    on_linux do
      if Hardware::CPU.arm?
        <<~EOS
          This formula installs an x86-64 binary that runs on ARM64 systems
          via QEMU user-mode emulation. Ensure QEMU user-mode is installed:

          On Debian/Ubuntu:
            sudo apt-get install qemu-user-static

          On Fedora/RHEL:
            sudo dnf install qemu-user-static
        EOS
      end
    end
  end

  test do
    system bin/"eep", "-h"
  end
end
