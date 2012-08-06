SwissSMS plug-in template
-------------------------

1. rename classes according to your service, suffix with the country code

	MyServiceCH.h -> BouygesFR.h
	MyServiceCH.m -> BouygesFR.m

2. edit and rename the service image

	MyServiceCH.png -> BouygesFR.png

3. edit Info.plist

	CFBundleIdentifier
	fr.free.toto.Bouyges.fr
	
	NSPrincipalClass
	BouygesFR
	
	SSPAuthor
	Jean-Pierre Boulet
	
	SSPCountryCode
	fr
	
	SSPMaxChars
	150 (change into the right value..)
	
	SSPName
	BouygesFR
	
	SSPNeedsAuthentication
	true
	
	SSPVersion</key>
	0.1 (increment this value each time you release a new version for your plugin)
	
	SSPWebSite
	http://toto.free.fr/my_plugins_page

3. rename Target and product

    Targets > MyServiceCH > rename -> BouygesFR
    BouygesFR > Info > ProductName: MyServiceCH -> BouygesFR

4. put your plugin in "~/Library/Application Support/SwissSMS/PlugIns/"




