# frozen_string_literal: true

class Eengine < Formula
  desc "Express Engine - EXPRESS language parser and interpreter"
  homepage "https://github.com/expresslang/eep-releases"
  version "5.2.7"
  license "BSD-2-Clause"

  on_macos do
    on_arm do
      url "https://github.com/expresslang/eep-releases/releases/download/eeng-5.2.7/eengine-5.2.7-mac-arm64-sbcl"
      sha256 "cb0cb1837d5a8eaf9cc46db9aaa88fdecea90eb20c2b3f845c18bf1f12fa3136"
    end

    on_intel do
      url "https://github.com/expresslang/eep-releases/releases/download/eeng-5.2.7/eengine-5.2.7-mac-x86-64-sbcl"
      sha256 "2f83aada2e4467dcb0f23e5c08388f7a53fe0b521c42e6f01ce97c6c6e217e4c"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/expresslang/eep-releases/releases/download/eeng-5.2.7/eengine-5.2.7-lnx-x86-64-sbcl"
      sha256 "27f785b3d2ff21859977c427c5455345bd9f6c6eab75f203e457e6d6f96658ec"
    end

    on_arm do
      url "https://github.com/expresslang/eep-releases/releases/download/eeng-5.2.7/eengine-5.2.7-lnx-arm64-sbcl"
      sha256 "3f595e6c082cb36b7e6b1937150ea9e8edf9b09634a7dcd5c2275bed822c3bc9"
    end
  end

  def install
    bin.install Dir["*"].first => "eengine"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/eengine --version 2>&1", 0)
  end
end
