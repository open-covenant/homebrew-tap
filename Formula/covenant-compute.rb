class CovenantCompute < Formula
  desc "Rent GPUs by the second, hire coding agents and run nodes on Covenant Compute"
  homepage "https://docs.opencovenant.org/compute"
  version "0.5.2"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.5.2/covenant-compute-darwin-arm64.tar.gz"
      sha256 "0f28f486057e72f081a2dc3e3914e843eca2d1050691ea83e61614bff6977b9f"
    end
    on_intel do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.5.2/covenant-compute-darwin-x86_64.tar.gz"
      sha256 "ae928d4f0d1f8f92c12f161acfb95d1adbfb0de833f0de77ae221c66ee5e89c2"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.5.2/covenant-compute-linux-arm64.tar.gz"
      sha256 "b85bb1c835cc8b8a5c29b3b993ac3ea72b6acd767ffb153e72736f76690a7558"
    end
    on_intel do
      url "https://github.com/open-covenant/covenant/releases/download/compute-v0.5.2/covenant-compute-linux-x86_64.tar.gz"
      sha256 "58c93d93d02a1f1945613f66409547b288041e1da99c875696366391d8fd193b"
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
    setup = JSON.parse(shell_output("#{buyer} knowledge setup #{testpath}/source --query calculate_total --json"))
    assert_equal "ready", setup.fetch("status")
    assert_equal "verified", setup.fetch("citation_verification").fetch("status")
    refute setup.fetch("configuration_written")
    assert_equal "current", setup.fetch("freshness").fetch("state")
    compiled = setup.fetch("compile")
    project = compiled.fetch("project").fetch("id")
    snapshot = compiled.fetch("snapshot_id")
    servers = setup.fetch("mcp_config").fetch("mcpServers").values
    assert_equal 1, servers.length
    assert_equal buyer.realpath.to_s, servers.first.fetch("command")
    expected_args = ["knowledge", "mcp", "--project", project, "--store", (testpath/"knowledge").realpath.to_s]
    assert_equal expected_args, servers.first.fetch("args")
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

    pricing = testpath/"source/python/pricing.py"
    original = pricing.read
    File.write(pricing, "#{original}\n# freshness check\n")
    status_command = "#{buyer} knowledge status --project #{project} --json"
    stale = JSON.parse(shell_output(status_command))
    assert_equal "stale", stale.fetch("freshness").fetch("state")
    assert_equal snapshot, stale.fetch("snapshot_id")
    File.write(pricing, original)
    assert_equal "current", JSON.parse(shell_output(status_command)).fetch("freshness").fetch("state")
    refute_path_exists testpath/"unused-buyer"
  end
end
