PROVIDES += "virtual/${TARGET_PREFIX}gccgo"
LANGUAGES := "${LANGUAGES},go"

do_install_append () {
	for t in gccgo; do
		ln -sf ${BINRELPATH}/${TARGET_PREFIX}$t $dest$t
		ln -sf ${BINRELPATH}/${TARGET_PREFIX}$t ${dest}${TARGET_PREFIX}$t
	done
}
