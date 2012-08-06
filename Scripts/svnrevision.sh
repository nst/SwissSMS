export PATH=/opt/local/bin:/usr/local/bin:/sw/bin/:$PATH

if [ $ACTION == "build" ]; then
	revision=`svnversion`
	
	if [ $BUILD_STYLE == "Release" ]; then
		errorLevel="warning"#"error"
	else
		errorLevel="warning"
	fi
	
	warned=0
	
	if echo $revision | grep -q :
	then
		echo "$errorLevel: mixed revision working copy ($revision)"
		warned=1
	fi
	
	if echo $revision | grep -q M && [ $warned -eq 0 ]
	then
		echo "$errorLevel: modified working copy ($revision)"
		warned=1
	fi
	
	if echo $revision | grep -q S && [ $warned -eq 0 ]
	then
		echo "$errorLevel: switched working copy ($revision)"
		warned=1
	fi
	
	if [ $warned -eq 1 ] && [ $errorLevel == "error" ]
	then
		exit 1
	fi
	
	perl -i -pe "undef $/; s{(<key>CFBundleVersion</key>.*?)<string>.*?</string>}{\\1<string>$revision</string>}s" "$CONFIGURATION_BUILD_DIR/$INFOPLIST_PATH"
	exitCode=$?
	
	if [ $exitCode -ne 0 ]; then
		echo "error: could not set CFBundleVersion ($exitCode)"
		exit $exitCode
	fi
	
	echo $revision > "$DERIVED_FILE_DIR/revision"
fi
