_ = require 'underscore'
express = require 'express'
mongoose = require 'mongoose'
request = require 'request'


mongoose.connect process.env.MONGO_URL or process.env.MONGOLAB_URI

Snippet = mongoose.model 'Snippet', new mongoose.Schema
	id:
		type: require('mongoose-shortid')
		unique: yes

	stack:
		type: String

	source:
		type: String

	input:
		type: String

	output:
		type: String

	program:
		id:
			type: String

		build:
			status:
				type: String

		status:
			type: String

	createdAt:
		type: Date


app = express()

app.set 'views', "#{__dirname}/views"
app.set 'view engine', 'jade'

app.use require('connect-assets')()
app.use express.static("#{__dirname}/public")

app.use require('body-parser').json()

app.route('/api/snippets')
.post(({body}, res, next) ->
	snip = new Snippet()
	_.extend snip, _.pick body, [
		'stack'
		'source'
		'input'
	]

	switch body.stack
		when 'bash4'
			ext = 'sh'
		when 'gcc4'
			ext = 'c'
		when 'g++4'
			ext = 'cpp'
		when 'openjdk7'
			ext = 'java'
		when 'go1'
			ext = 'go'
		when 'python2'
			ext = 'py'
		when 'python3'
			ext = 'py'
		else
			return

	await request
		method: 'post'
		url: "https://api.arturia.io/programs?secret=#{process.env.ARTURIA_SECRET}"
		json: {
			stack: body.stack,
			files: [
				name: "code.#{ext}"
				src: "data:base64,#{new Buffer(body.source.substr(0, 65536)).toString('base64')}"
			]
			stdin:
				src: "data:base64,#{new Buffer(body.input.substr(0, 65536)).toString('base64')}"
			limits:
				cpu: 2*1e9
				memory: 268435456
		}
	, defer err, resp, body
	if err?
		return console.log err

	snip.program.id = body.id

	await snip.save defer err
	if err?
		return next err

	res.json _.pick snip, [
		'id'
	]

)

app.route('/api/snippets/:id')
.get(({params}, res, next) ->
	await Snippet.findOne()
	.where('id', params.id)
	.exec defer err, snip
	if err?
		return next err

	if snip.program.status not in ['exited', 'killed', 'failed', 'skipped']
		await request.get "https://api.arturia.io/programs/#{snip.program.id}?secret=#{process.env.ARTURIA_SECRET}", defer err, resp, body
		if err?
			return console.log err

		body = JSON.parse body
		_.extend snip.program, body

		if snip.program.status in ['exited', 'killed']
			await request.get body.stdout.src, defer err, resp, body
			if err?
				return next err

			snip.output = body.substr 0, 65536

		await snip.save defer err
		if err?
			return next err

	res.json snip
)

app.route('/tpls/:name.html')
.get((req, res, next) ->
	res.render "tpls/#{req.params.name}"
)

app.route('/*')
.get((req, res, next) ->
	res.render 'layout'
)

await app.listen (port = process.env.PORT), defer err
if err?
	throw err

console.log "Listening on #{port}"
