class CovenantCompute < Formula
  desc "Rent GPUs by the second, hire coding agents and run nodes on Covenant Compute"
  homepage "https://docs.opencovenant.org/compute"
  version "0.2.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.2.0/covenant-compute-darwin-arm64.tar.gz"
      sha256 "733756b78a71ef8e3e2bf5e8d24d6915af5c8684261a6e217e8965eeea99fe3f"
    end
    on_intel do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.2.0/covenant-compute-darwin-x86_64.tar.gz"
      sha256 "c191e1ef2b910bdcb8ead4349499f5ae97ee045f09c871211bf09e194d7e6e8c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.2.0/covenant-compute-linux-arm64.tar.gz"
      sha256 "1bc68c73ae11af20ab82b1babd1eace41c9f7a24d408330223ee531c4e9bcd5b"
    end
    on_intel do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.2.0/covenant-compute-linux-x86_64.tar.gz"
      sha256 "b52d0b583f0ebdf8c3c5b37f1b651123677a6f8eabaca62765f2b656489b6a95"
    end
  end

  def install
    bin.install "covenant-compute", "covenant-compute-mcp", "covenant-compute-node", "covenant-compute-stake"
  end

  test do
    %w[covenant-compute covenant-compute-mcp covenant-compute-node covenant-compute-stake].each do |cmd|
      assert_equal "#{cmd} #{version}", shell_output("#{bin}/#{cmd} --version").strip
    end
  end
end
