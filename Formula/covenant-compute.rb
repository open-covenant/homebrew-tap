class CovenantCompute < Formula
  desc "Rent GPUs by the second, hire coding agents and run nodes on Covenant Compute"
  homepage "https://docs.opencovenant.org/compute"
  version "0.4.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.4.1/covenant-compute-darwin-arm64.tar.gz"
      sha256 "bcea9e9bd493cef0f7568197a6b06ed8d14d36bf2502d98b838338c043a6ee39"
    end
    on_intel do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.4.1/covenant-compute-darwin-x86_64.tar.gz"
      sha256 "54340753b65f22c04b4b50e16d1a21e30d230d8a6138c847bd085285c7594928"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.4.1/covenant-compute-linux-arm64.tar.gz"
      sha256 "5aa9d0673a56094322043a495e39563e8b009b4c643e9f878feaf4ed9a9e0b94"
    end
    on_intel do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.4.1/covenant-compute-linux-x86_64.tar.gz"
      sha256 "a8a91cb60f2251ac070b0bacc104010b121698b65ca9efab6424ef62d79718bb"
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
