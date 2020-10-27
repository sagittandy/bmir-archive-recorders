Mon 2020-1026 NOTES ON LIQUIDSOAP WITH ICECAST2 ON RASPBERRY PI

When using install.liquidsoap.sh in this folder today,
'apt-get install liquidsoap' on Raspbian Stretch installs Liquidsoap v1.1.1.
I couldn't get v1.1.1 to play to a colocated icecast server...

To get it to work, I installed liquidsoap v1.3.3 using OPAM package manager.
Install OPAM (as root)
	http://opam.ocaml.org/doc/Install.html
	apt-get -y install opam
	Answered 'Yes' to all questions
Install Liquidsoap (as non-root user):
	https://www.liquidsoap.info/doc-1.4.3/install.html
	opam depext taglib mad lame vorbis cry samplerate liquidsoap
	opam install taglib mad lame vorbis cry samplerate liquidsoap
Result (as non-root user):
	liquidsoap --version
	Liquidsoap 1.3.3
	Copyright (c) 2003-2017 Savonet team
