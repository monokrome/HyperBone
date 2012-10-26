hyperbone = window.hyperbone = window.hyperbone or {}

# Maps resource names from the API to better names for API name discovery.
# TODO: Deprecate this.
resource_names_map =
	cartitems: 'cart_item'
	countries: 'country'
	categories: 'category'
	authenticate: 'authenticate'
	currencies: 'currency'

hyperbone.util =
	naturalModelName: (pluralName) ->
		modelName = resource_names_map[pluralName] or pluralName.substring 0, pluralName.length - 1

		parts = modelName.split('_')
		natural = ''

		for part in parts
			upperPart = (part.charAt 0).toUpperCase() + (part.substring 1).toLowerCase()
			natural = natural + upperPart

		natural

hyperbone.Bone = class Bone
	resources: {}

	namespaces: {}

	registry: {}

	constructor: (@originalOptions) ->
		@parseOptions()
		@readSchema()

	parseOptions: =>
		@registry.root = @originalOptions.rootUrl or @originalOptions.root

		if !@originalOptions.communicationType?
			@registry.communicationType = 'cors'
		else
			@registry.communicationType = @originalOptions.communicationType.toLowerCase()

	readSchema: =>
		# Discovers our API endpoints.

		@request @registry.root,
			success: @updateSchema

	updateSchema: (response) =>
		namespaces = {}

		for namespaceName of response._embedded
			namespace = response._embedded[namespaceName]

			namespaces[namespaceName] = @discoverResources namespace

		@namespaces = namespaces

	discoverResources: (namespace) =>
		models = {}

		for resourceName of namespace._links
			if resourceName is 'self'
				continue

			resourceName = hyperbone.util.naturalModelName resourceName

			models[resourceName] = 'wat'

		models

	request: (url, options) =>
		# Wraps jQuery's ajax call in order to automatically convert requests between
		# different communication types (IE, CORS or JSON-P) and generate URLs
		# when necessary.

		options = options or {}

		options.dataType = @registry.communicationType

		# TODO: Get this to use the HTTP standard Accept header, not ?format=json-p
		if @registry.communicationType == 'jsonp'
			options.crossDomain = options.crossDomain or true

			options.data = options.data or {}
			options.data.format = 'json-p'

		jQuery.ajax url, options
