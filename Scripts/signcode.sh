
if [ $ACTION == "build" ] && [ $BUILD_STYLE == "Release" ]; then
	codesign -s SwissSMS --force "$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME"
	exit $?
fi
