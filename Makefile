# TODO: ensure JulieInterface is up-to-date
default:
	@echo "Use 'make doc' or 'make check' or 'make tags'""

check:
	julia --color=yes test/runtests.jl

doc:
	julia --color=yes docs/make.jl

tags:
	etc/tags.sh --recurse pkg src

.PHONY: default check doc tags
