# Go patch version resolution

This document outlines how vmatch resolves which patch version to pick when only minor version has been specfied in `go.mod`.

## Background

### Patch version specification in `go.mod`

A basic `go.mod` file can look as follows

```
module github.com/anttiharju/vmatch

go 1.23.5
```

To unlock the patch version, the file would be modified like this:

```diff
module github.com/anttiharju/vmatch

-go 1.23.5
+go 1.23
```

Both version specifications (`1.23` and `1.23.5`) are valid.

### Semantic versioning (major.minor.patch) and Go

Based on the go.mod example above, one could reasonably assume that

- `1` is the major version. Go maintainers have asserted that "There will not be a Go 2 that breaks Go 1 programs" [\[1\]](https://go.dev/blog/compat#go2). The statement is not as strong as it may seem, as Go 1.22 made a breaking change [\[2\]](https://tip.golang.org/wiki/LoopvarExperiment#can-this-change-break-programs) to for loops [\[3\]](https://go.dev/blog/loopvar-preview). This change was welcome as it removed a common footgun. Migration tooling was provided for the breaking change [\[4\]](https://tip.golang.org/wiki/LoopvarExperiment#can-i-see-a-list-of-places-in-my-code-affected-by-the-change), which unfortunately does not work if package main contains other Go files than `main.go`. In reasonably structured projects the tooling makes the migration process fairly easy.
- `23` is the minor version. Developers care about this one because as mentioned above, breaking changes may happen in minor versions.
- `5` is the patch version. Developers may have various reasons for leaving it unlocked, some of them are
  1. reduced maintenance effort.
  2. tooling such as [`stringer`](https://pkg.go.dev/golang.org/x/tools/cmd/stringer) refusing to work if patch version is specified.
  3. patch versions presumably do not introduce breaking changes. In typical semversioned projects minor versions would also not introduce breaking changes. Alas, this is not the case with Go.

This is not the case as Go's version format stands for 1.N.P [\[5\]](https://tip.golang.org/doc/toolchain#version):

- `1` is hardcoded per their commitment to not releasing Go 2 (trying to the infamous Python 2 -> 3 situation?).
- `N` stands for 'language version' so they may make breaking changes here
- `P` standing for P, 'often referred to as patch releases'. Sometimes referred to as minor releases elsewhere in Go documentation.

### Download URLs for Go

As of writing,

`vmatch` uses a separate project [`vmatch-go`](https://github.com/anttiharju/vmatch-go) to download Go binaries. The downloads are sourced from https://go.dev/dl.

A typical download URL looks like

https://go.dev/dl/go1.23.5.darwin-arm64.tar.gz

which `vmatch-go` constructs using the following template

```sh
url="https://go.dev/dl/go${goversion}.${goos}-${goarch}.tar.gz"
```

Sometimes patch-unlocked versions can be downloaded with the above template. It for example works for Go 1.20 https://go.dev/dl/go1.20.darwin-arm64.tar.gz. However this pattern is inconsistent, as a similar url for Go 1.24 results in a 404 https://go.dev/dl/go1.24.darwin-arm64.tar.gz.

Therefore specifying the patch version is desirable for vmatch.

These inconsistent URLs are made even more curious by the fact that the downloaded Go 1.20 binary does not report a patch version for itself

```sh
$ ~/.vmatch/go/v1.20/bin/go version
go version go1.20 darwin/arm64
```

this leaves open whether the downloaded binary is

1. Go 1.20.0
2. Latest patch of Go 1.20 as of downloading, or
3. a version of 1.20 _before_ 1.20.0.
4. a release candidate of 1.20

Thankfully this is largely a nonconcern for vmatch as patch versions should not introduce breaking changes.

## Locking a patch-unlocked version

### Go version API

Fortunately, go.dev provides an API at https://go.dev/dl/?mode=json&include=all which includes data about all released versions of Go.

Unfortunately, it is about 58k lines of JSON. Not that downloading it takes a long time, but doing computation on it on-demand may introduce undesirable delay and the problem would only get worse over time.

Thankfully, vmatch only needs to know what is the latest patch for a given patch-unlocked version of Go.

#### When should vmatch be concerned with what is the latest patch?

Querying the API endpoint each time vmatch is invoked in projects that have the patch version unlocked, would likely provide a poor experience because

- API calls (networking!) cause additional delay
- Even if you have downloaded a viable version for a given patch-unlocked version of Go, your development environment would sease to function should the endpoint be down or your computer offline.

Both of the above are highly undesirable as vmatch aims to be as non-existent of a wrapper as it can.

- It also needs to be acknowledged that when vmatch downloads a given version of Go for the first time, there is a noticeable delay compared to if a person was directly invoking a Go binary.

While the above is undesirable, it is the core functionality of vmatch.

#### Customising the endpoint for the needs of vmatch

It is clear that vmatch needs _a_ dynamic endpoint for fetching the latest patch of a patch-unlocked version of Go. But that does not necessitate that we have to call the go.dev provided one directly. With an approach similar to `vmatch-go`, we could setup another repository, for example `vmatch-go-version`, which could have a scheduled GitHub Actions workflow run that parses the go.dev endpoint into a more granular format, to a directory structure such as

```
latest
├── patch
│   └── 1.20 # contains value like "14"
└── version # contains a value like "1.20"
```

This way vmatch can be security-hardened to lock `vmatch-go` to a SHA while leaving `vmatch-go-version` unlocked at HEAD for convenience. Finally, having `vmatch-go-version` separate from `vmatch` is also desirable to keep the automation (when should a new relase be made) in `vmatch` easy.

### Being a good API citizen

In the unlikely case that this tool becomes popular, vmatch does not want to bombard GitHub with bunch of traffic to `vmatch-go-version`. Not that I doubt that they could not handle it.

So vmatch would require some sort of functionality that it only checks every N hours what the latest patch version is. It could maintain a partial copy of the latest patch tree under `~/.vmatch/go`.

#### How often the API should be called?

_Technically_ it could be that some external dependency _would_ work on the latest patch of a given Go version, but not on patch 0. And perhaps more importantly, the patches appear to contain security fixes. _Therefore_, it would be important for the Go versions of vmatch users to _eventually_ gravitate towards the latest patch. What is a good interval will be worked out in this section.

vmatch will assume that new versions of Go can be released at any time.

The GitHub Actions automation in `vmatch-go-version` will depend on GitHub runners, and the GitHub Free plan includes 2,000 free minutes per month [\[6\]](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions#included-storage-and-minutes)

If we assume a month can have up to 31 days and that the job would complete within a minute, running the scan every 12 hours would consume ~62 minutes a month, or in other words 3,1% of the free runner capacity. And vmatch waits at least 12 hours before checking for the latest version again.

I think that in the rare case that the patch version is important for a given project, having vmatch fix the issue within a day would be acceptable.

So in the worst case:

- vmatch-go-version completes a scan (t=0h0m)
- Go releases a version immediately after (t=0h1m)
- vmatch checks vmatch-go-version what the latest version is (t=11h59m)
- vmatch-go-version becomes aware of the new version (t=12h0m)
- vmatch can become aware of the new Go version (t=23h59m)

But in practice:

- a user notices their development environment is not working at the end of their workday
- the development environment cannot fix itself during their next workday

-> vmatch should have the ability to become aware of new Go versions within 12 hours of release. This would translate to running the GitHub Actions job every 6 hours, resulting in the worst case scenario of

- vmatch-go-version completes a scan (t=0h0m)
- Go releases a version immediately after (t=0h1m)
- vmatch checks vmatch-go-version what the latest version is (t=5h59m)
- vmatch-go-version becomes aware of the new version (t=6h0m)
- vmatch can become aware of the new Go version (t=11h59m)

So in practice:

- user notices their development environment is not working at the end of their workday
- the development environment can fix itself by tomorrow (assuming a somewhat regular working schedule)

The 12-hour schedule leaves slack for irregular work schedules and possible GitHub Actions downtime. It would consume 31\*(24/6)=124 minutes a month which is 6,2% (124/2000) of the free capacity. As of writing this appears acceptable, to be adjusted if limits are hit.

#### How to manage a partial state copy?

According to the release policy [\[7\]](https://go.dev/doc/devel/release#policy) patch versions (confusingly referred to as minor releases, but specified with an example) can be released for supported releases. The latest two versions are considered supported. In other words, if Go 1.24 is the latest, both it and Go 1.23 receive patches.

Therefore vmatch in its queries to vmatch-go-version should stay aware of the latest version at all times to avoid needlessly asking whether non-supported versions have new patch releases, leading to the flow:

- if a supported binary has been downloaded:
  - fail silently in case of any networking issues:
    - fetch latest patch from vmatch-go-version for the two latest patches, download binaries upon a change
      - an extra delay at most once per workday
        - at best an API call
        - at worst a Go binary download
    - update the latest version, two api calls:
      - vmatch-go-version/language-version/latest (for example Go 1.24, not saved in a file)
      - vmatch-go-version/1.24 (patch 0, saved to a file)
  - call the latest patch binary of the minor Go version appropriate for the patch-unlocked project

#### vmatch-go-version repository

Should always scan all existing Go versions from the upstream API to maintain a solid ground truth.

In case a local vmatch installation ends up in a state where it cannot fetch the latest patch for a given Go release, user can always rm -rf `~/.vmatch` directory to reset local cache (should not happen given Go's release policy and the vmatch update flow above).

## Further reading

- Go's toolchain feature https://tip.golang.org/doc/toolchain. The relevant bit:

  > The Go toolchain refuses to load a module or workspace that declares a minimum required Go version greater than the toolchain’s own version.
  >
  > For example, Go 1.21.2 will refuse to load a module or workspace with a go 1.21.3 or go 1.22 line.

  toolchain is a cool feature. It does not nullify the purpose of vmatch, as vmatch would simply download the newer release and presumably the language-version features such as toolchain would continue to work within vmatch-downloaded versions of Go.
