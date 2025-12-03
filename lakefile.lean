import Lake
open Lake DSL

package «base64-lean» where
  version := v!"0.1.0"


@[default_target]
lean_lib «Base64Lean» where
  moreLinkArgs := #["-lbase64", "-lssl", "-lcrypto", "-lz", "-L.lake/build/lib"]

target base64.o pkg : System.FilePath := do
  let oFile := pkg.buildDir / "lib" / "base64.o"
  let srcPath := pkg.dir / "c" / "base64.c"
  let srcJob ← inputTextFile srcPath
  let flags := #["-I", (← getLeanIncludeDir).toString, "-fPIC"]
  buildO oFile srcJob flags

extern_lib libbase64 pkg := do
  let name := nameToStaticLib "base64"
  let base64_o ← fetch <| pkg.target ``base64.o
  buildStaticLib (pkg.staticLibDir / name) #[base64_o]

script compdb do
  let leancInclude ← getLeanIncludeDir
  let projectDir ← IO.currentDir
  
  let entry1 := Lean.Json.mkObj [
    ("directory", Lean.Json.str projectDir.toString),
    ("command", Lean.Json.str s!"cc -c -o .lake/build/lib/base64.o c/base64.c -I{leancInclude} -fPIC"),
    ("file", Lean.Json.str "c/base64.c")
  ]
  
  let json := Lean.Json.arr #[entry1]
  let jsonStr := Lean.Json.pretty json
  
  IO.FS.writeFile "compile_commands.json" jsonStr
  return 0
