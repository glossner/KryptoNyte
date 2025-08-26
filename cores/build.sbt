name := "ZeroNyteCore"

version := "0.1"

scalaVersion := "2.12.17" // Compatible with Chisel 3.6.x

libraryDependencies ++= Seq(
  "edu.berkeley.cs" %% "chisel3" % "3.6.0",
  "edu.berkeley.cs" %% "chiseltest" % "0.5.5" % "test"
)

