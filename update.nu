def main [] {
  let manifest = http get https://piston-meta.mojang.com/mc/game/version_manifest_v2.json

  let versions = $manifest.versions
    | where type == release
    | par-each --keep-order {|version| http get $version.url }
    | reduce --fold {} {|version, acc|
        let jars = { client: $version.downloads.client.sha1, server: $version.downloads.server?.sha1? }
          | transpose kind sha1
          | where sha1 != null
          | transpose --header-row --as-record
        $acc | merge { $version.id: $jars }
      }

  { latest: $manifest.latest.release, versions: $versions }
    | to json --indent 2
    | $in + "\n"
    | save --force versions.json
}
