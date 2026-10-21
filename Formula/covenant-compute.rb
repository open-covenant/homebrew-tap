class CovenantCompute < Formula
  desc "Rent GPUs by the second, hire coding agents and run nodes on Covenant Compute"
  homepage "https://docs.opencovenant.org/compute"
  version "0.5.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.5.1/covenant-compute-darwin-arm64.tar.gz"
      sha256 "8cf3b09bcd4ea950d59a753a98b026e010f6078ed26727fad4062620391b28b1"
    end
    on_intel do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.5.1/covenant-compute-darwin-x86_64.tar.gz"
      sha256 "ecd80b4bbb8bfb53093cdb9f0096f3f39bab0ffc7622b366b170ccc8f0d1c74e"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.5.1/covenant-compute-linux-arm64.tar.gz"
      sha256 "f77c04008d6352df3b9c8daef9638715e6ea70fdd8540ac6f95434ba8fef2e96"
    end
    on_intel do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.5.1/covenant-compute-linux-x86_64.tar.gz"
      sha256 "4873355a9db5dbc18cb8a3e6a71fcddb8e3d77e779b3485cc3785a6e5b8ec484"
    end
  end

  def install
    bin.install "covenant-compute", "covenant-compute-mcp", "covenant-compute-node", "covenant-compute-stake"
    pkgshare.install "examples", "docs", "licenses", "tools"
    pkgshare.install "LICENSE", "NOTICE.md", "SECURITY_AUDIT_LICENSE", "RELEASE_NOTES.md", "BUILD_INFO.json"
  end

  test do
    %w[covenant-compute covenant-compute-mcp covenant-compute-node covenant-compute-stake].each do |cmd|
      assert_equal "#{cmd} #{version}", shell_output("#{bin}/#{cmd} --version").strip
    end

    assert_path_exists pkgshare/"docs/compute-knowledge.md"
    assert_path_exists pkgshare/"licenses/knowledge/sources.json"
    cp_r pkgshare/"examples/knowledge", testpath/"source"
    ENV["COVENANT_KNOWLEDGE_HOME"] = (testpath/"knowledge").to_s
    ENV["COVENANT_COMPUTE_MCP_HOME"] = (testpath/"unused-buyer").to_s
    ENV["COVENANT_COMPUTE_COORDINATOR_URL"] = "http://127.0.0.1:1"

    buyer = bin/"covenant-compute"
    compiled = JSON.parse(shell_output("#{buyer} knowledge compile #{testpath}/source --json"))
    project = compiled.fetch("project").fetch("id")
    snapshot = compiled.fetch("snapshot_id")
    assert_equal 9, compiled.fetch("coverage").fetch("files")
    search_command = "#{buyer} knowledge query calculate_total --project #{project} --limit 50 --json"
    search = JSON.parse(shell_output(search_command))
    paths = search.fetch("results").map { |row| row.fetch("object").fetch("path") }
    %w[python/orders.py rust/src/lib.rs web/orders.ts web/OrderCard.tsx].each { |path| assert_includes paths, path }
    search.fetch("results").each do |row|
      evidence = row.fetch("evidence")
      source = (testpath/"source"/evidence.fetch("path")).binread
      fragment = source.byteslice(evidence.fetch("start_byte")...evidence.fetch("end_byte"))
      assert_equal evidence.fetch("fragment").b, fragment
      assert_equal snapshot, evidence.fetch("snapshot_id")
    end
    verified = JSON.parse(shell_output("#{buyer} knowledge verify #{snapshot} --project #{project} --json"))
    assert verified.fetch("valid")

    requests = [
      { jsonrpc: "2.0", id: 1, method: "initialize", params: {
        protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "homebrew-test", version: "1" }
      } },
      { jsonrpc: "2.0", method: "notifications/initialized" },
      { jsonrpc: "2.0", id: 2, method: "tools/list" },
      { jsonrpc: "2.0", id: 3, method: "tools/call", params: {
        name: "knowledge.search", arguments: { query: "calculate_total" }
      } },
    ]
    output = pipe_output("#{buyer} knowledge mcp --project #{project}",
                         requests.map { |request| JSON.generate(request) }.join("\n") + "\n", 0)
    responses = output.lines.map { |line| JSON.parse(line) }
    assert_equal [1, 2, 3], responses.map { |response| response.fetch("id") }
    tools = responses[1].fetch("result").fetch("tools")
    expected = %w[search get evidence dependencies changes status].map { |name| "knowledge.#{name}" }
    assert_equal expected.sort, tools.map { |tool| tool.fetch("name") }.sort
    assert tools.all? { |tool| tool.fetch("annotations").fetch("readOnlyHint") }
    result = responses[2].fetch("result")
    refute result.fetch("isError")
    assert_predicate JSON.parse(result.fetch("content").first.fetch("text")).fetch("results"), :any?
    refute_path_exists testpath/"unused-buyer"
  end
end
