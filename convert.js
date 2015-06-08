#!/usr/local/bin/node

var Promise = require("bluebird");
var _ = require('underscore');
var s = require('underscore.string');
var fs = Promise.promisifyAll(require("fs-extra"));
var path = Promise.promisifyAll(require("path"));
var xml2js = Promise.promisifyAll(require("xml2js"));
var unzip = require('unzip');
var util = require('util');
var escaper = require('true-html-escape');

var usage = " Usage: convert.js -f <filename.docx>";

var args = require('minimist')(process.argv.slice(2));
var filename = args.f;

if (!_.isString(filename)) {
	console.log(usage);
	process.exit(0);
}

if (!s.endsWith(filename, ".docx")) {
	console.log(filename, "does not end with .docx");
	console.log(usage);
	process.exit(0);
}

docxToDir(filename, s.strLeftBack(filename, ".docx"))
	.then(loadDocumentXml)
	.then(xmlToObject)
	.then(wpToHtml)
	.then(saveHtmlFile)
	.then(printDone)
	.error(logError);

/**
 * Log an error
 *
 * @param  {Error} err  the error to log
 *
 */
function logError(err) {
	console.log(err);
}

/**
 * Write done to the console
 *
 */
function printDone() {
	console.log("done!");
}

/**
 * Save HTML contents in a buffer to a file
 *
 * @param  {Buffer} html the HTML contents to save
 * @return {Promise}     Promise that completes when the save has completed
 *
 */
function saveHtmlFile(html) {
	var htmlFileName = s.strLeftBack(filename, ".docx") + ".html";
	console.log("Saving", htmlFileName);
	return fs.writeFileAsync(htmlFileName, html);
}

/**
 * Converts Word Processing ML to very simple HTML
 *
 * @param  {Object} wp JS object representing WPML
 * @return {Promise}   Promise that resolves with HTML text
 *
 */
function wpToHtml(wp) {

	console.log("Converting wordprocessingML to HTML");
	var body = wp['w:document']['w:body'][0];

	var sections = {
		"DocumentTitle": {
			start: "<h1>",
			end: "</h1>"
		},
		"Heading1": {
			start: "<h1>",
			end: "</h1>"
		},
		"Heading2": {
			start: "<h2>",
			end: "</h2>"
		},
		"Heading3": {
			start: "<h3>",
			end: "</h3>"
		},
		"Heading4": {
			start: "<h4>",
			end: "</h4>"
		},
		"Heading5": {
			start: "<h5>",
			end: "</h5>"
		},
	}

	var header = "<html><head></head><body>";
	var footer = "</body></html>";

	var output = header;

	// recursive descent to convert w:p to <p>
	// adding text along the way
	return new Promise(function(resolve, reject) {

		var paras = body['w:p'];
		_.each(paras, function(para) {

			var sectionStart = "<p>";
			var sectionEnd = "</p>";

			var paraStyleProps = para['w:pPr'];
			if (_.isArray(paraStyleProps) && paraStyleProps.length > 0) {
				var paraStyleProp = paraStyleProps[0];

				var paraStyle = paraStyleProp['w:pStyle'];
				if (_.isArray(paraStyle) && paraStyle.length > 0) {
					var paraStyleVal = paraStyle[0];
					if (_.isObject(paraStyleVal.$) && _.has(paraStyleVal.$, 'w:val')) {
						var sectionName = paraStyleVal.$['w:val'];
						if (_.has(sections, sectionName)) {
							sectionStart = sections[sectionName].start;
							sectionEnd = sections[sectionName].end;
						} else {
							console.log("unsupported section name", sectionName);
						}
					}
				}

				var numProps = paraStyleProp['w:numPr'];
				if (_.isArray(numProps) && numProps.length > 0) {
					var numProp = numProps[0];
					if (_.isObject(numProp)) {
						sectionStart = "<li>";
						sectionEnd = "</li>";
					}
				}
			}

			output += sectionStart;

			var runs = para['w:r'];
			_.each(runs, function(run) {

				var texts = run['w:t'];
				_.each(texts, function(text) {
					if (_.isString(text)) {
						output += escaper.escape(text);
					} else if (_.isObject(text) && _.isString(text._)) {
						output += escaper.escape(text._);
					}

				});
			});

			output += sectionEnd;
		});

		output += footer;

		console.log("Finished converting wordprocessingML to HTML");
		resolve(output);
	});
}



/**
 * Loads the main XML file of a OpenXML package into memory
 *
 * @param  {String} packageDir Unzipped directory containing openXML files
 * @return {Promise}           Promise that completes with the contents of the main doc file
 *
 */
function loadDocumentXml(packageDir) {
	var mainFileName = packageDir + "/word/document.xml"
	console.log("loading", mainFileName);
	return fs.readFileAsync(mainFileName);
}


/**
 * convert XML data to JS object
 *
 * @param  {Buffer} data buffer containing xml data to convert
 * @return {Object}      JS Object matching the XML
 *
 */
function xmlToObject(data) {
	console.log("converting loaded XML to JS Object");
	var p = new xml2js.Parser();
	return p.parseStringAsync(data);
}



/**
 * extract a docx files contents to the output directory
 *
 * @param  {String} docxFileName  the name of the docx file
 * @param  {String} outputDirName the name of the output directory
 * @return {Promise}              a Promise that resolves when completed
 *
 */
function docxToDir(docxFileName, outputDirName) {
	console.log("Extracting", docxFileName, "to", outputDirName);
	return new Promise(function(resolve, reject) {
		var extractor = unzip.Extract({
			path: outputDirName
		});
		fs.createReadStream(docxFileName)
			.pipe(extractor)
			.on('close', function() {
				console.log("Extraction completed to", outputDirName);
				resolve(outputDirName);
			})
			.on('error', reject);
	});
}