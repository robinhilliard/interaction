<!---
   Render a UML interaction diagram using pseudocode syntax in the tag body:

   key caption         Column declarations. Capitalised key starts instantiated (solid line)
   Key caption
   key caption
                    Empty line to finish column declarations
   key label {         Synchronous call (filled arrow), label can contain spaces and "\" for additional lines
   key! label {        Asynchronous call (hollow arrow)
   ! label {           Asynchronous call/message to right side of diagram
   return label        Optional return (hollow dashed arrow) back to caller
   }                   pass execution back to caller
   ...                 Add space
   ///                 Time passes marker
   label               Column calling itself
   #comment            hash must be first character, end of line comments not supported

   (c) RocketBoots 2014

   Interaction is free software: you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License as
   published by the Free Software Foundation, either version 3 of
   the License, or (at your option) any later version.

   Interaction is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with Pattern.  If not, see
   <http://www.gnu.org/licenses/>.

   @see http://www.ibm.com/developerworks/rational/library/3101.html
 --->
<cfscript>
if (thistag.executionMode eq "end") {

	structClear(request);

	request.append({
		DEFAULT_WIDTH = 200,
		TITLE_BOX_PADDING = 35,
		TITLE_TEXT_Y = 18,
		TITLE_BOX_HEIGHT = 28,
		IMAGE_WIDTH = 2000,         // Max size - image cropped down after drawing to fit
		IMAGE_HEIGHT = 2000,
		ACTIVE_PADDING = 5,         // Height of activation bar above call arrow and below return arrow
		ACTIVE_WIDTH = 16,          // Width of the activation rectangle
		Y_ADVANCE = 35,             // Vertical gap between interactions
		ARROW_HEAD_SIZE = 10,
		ARROW_HEAD_RATIO = 0.5,     // Height as % of length
		TEXT_ARROW_GAP = 5,         // Vertical gap between arrow and its label
	});


	// Define text styles

	normal = {style = "bold", size = 12, font = "chalkboard"};
	title = normal.copy().append({underline = false, size = 14});

	// Define line styles

	solid = {width = 1.4, endcaps = "round"};
	dashed = solid.copy().append({dashArray = [8, 6]});
	request.solid = solid;



	// Helper functions

	function drawHCentredRect(x, y, width, height) {
		imageSetDrawingColor(request.canvas, "white");
		imageDrawRect(request.canvas, x - width / 2, y, width, height, true);
		imageSetDrawingColor(request.canvas, "black");
		imageDrawRect(request.canvas, x - width / 2, y, width, height, false);
	}



	function drawBreak(y, height) {
		imageSetDrawingColor(request.canvas, "white");
		imageDrawRect(request.canvas, 0, y, request.IMAGE_WIDTH, height, true);
		imageSetDrawingColor(request.canvas, "black");
	}


	function drawText(text, x, y, style, vCentre = false) {
		if (not structKeyExists(request, "drawTextBuffer"))
			request.drawTextBuffer = [];

		request.drawTextBuffer.append(arguments);
	}

	// Call at end of rendering so that labels appear on top
	function drawBufferedText() {
		request.drawTextBuffer.each(function(p) {
			if (p.text neq "") {
				if (p.text contains "\") {
					lineHeight = getTextDimensions("Yy", p.style).height * 1.2;
					textLines = listToArray(p.text, "\");

					if (p.vCentre) {
						yOffset = lineHeight * (textLines.len() - 1) * 0.5;
					} else {
						yOffset = lineHeight * (textLines.len() - 1);
					}

					textLines.each(
						function(line) {
							drawText(trim(line), p.x, p.y - yOffset, p.style);
							yOffset -= lineHeight;
						}
					);

				} else {
					dim = getTextDimensions(p.text, p.style);
					imageSetDrawingColor(request.canvas, "white");
					imageDrawRect(request.canvas, p.x, p.y - dim.height * 0.9, dim.width, dim.height, true);
					imageSetDrawingColor(request.canvas, "black");
					imageDrawText(request.canvas, p.text, p.x, p.y, p.style);
				}
			}
		});
	}



	function drawHCentredText(text, x, y, style) {
		dim = getTextDimensions(text, style);
		drawText(text, x - dim.width / 2, y, style);
	}



	function getTextDimensions(text, style) {
		if (text eq "")
			return {width = 0, height = 0};

		if (text contains "\") {
			maxTextWidth = 0;
			maxTextHeight = 0;

			listToArray(text, "\").each(function(t) {
				dims = getTextDimensions(t, style);
				maxTextWidth = max(maxTextWidth, dims.width);
				maxTextHeight = max(maxTextHeight, dims.height);
			});

			return {width = maxTextWidth, height = maxTextHeight};

		} else {
			buffered = ImageGetBufferedImage(request.canvas);
			context = buffered.getGraphics().getFontRenderContext();
			Font = createObject("java", "java.awt.Font");
			textFont = Font.init( style.font, Font[uCase(style.style)], javacast("int", style.size));
			textLayout = createObject("java", "java.awt.font.TextLayout").init( text, textFont, context);
			textBounds = textLayout.getBounds();
			return {width = textBounds.getWidth(), height = textBounds.getHeight()};
		}
	}



	function setDrawingStroke(stroke) {
		imageSetDrawingStroke(request.canvas, stroke);
	}



	function drawLine(x1, y1, x2, y2) {
		imageDrawLine(request.canvas, x1, y1, x2, y2);
	}



	function drawArrow(x1, x2, y, open = false) {
		if (x1 lt x2) {
			arrowXOffset = -request.ACTIVE_WIDTH / 2;
			arrowHeadXOffset = -request.ARROW_HEAD_SIZE;
		} else {
			arrowXOffset = request.ACTIVE_WIDTH / 2;
			arrowHeadXOffset = request.ARROW_HEAD_SIZE;
		}

		imageDrawLine(request.canvas, x1 - arrowXOffset, y, x2 + arrowXOffset, y);
		setDrawingStroke(request.solid);

		if (open) {
			imageDrawLines(request.canvas,
				[x2 + arrowXOffset + arrowHeadXOffset, x2 + arrowXOffset, x2 + arrowXOffset + arrowHeadXOffset],
				[y - (request.ARROW_HEAD_SIZE * request.ARROW_HEAD_RATIO), y, y + (request.ARROW_HEAD_SIZE * request.ARROW_HEAD_RATIO)],
				false,
				false);
		} else {
			imageDrawLines(request.canvas,
				[x2 + arrowXOffset, x2 + arrowXOffset + arrowHeadXOffset, x2 + arrowXOffset + arrowHeadXOffset],
				[y, y - (request.ARROW_HEAD_SIZE * request.ARROW_HEAD_RATIO), y + (request.ARROW_HEAD_SIZE * request.ARROW_HEAD_RATIO)],
				true,
				true);
		}
	}



	function drawLoopArrow(x, y) {
		imageDrawLines(request.canvas,
			[x + request.ACTIVE_WIDTH / 2, x + request.ACTIVE_WIDTH / 2 + request.ARROW_HEAD_SIZE * 2, x + request.ACTIVE_WIDTH / 2 + request.ARROW_HEAD_SIZE * 2],
			[y, y, y + request.Y_ADVANCE],
			false,
			false
		);
		drawArrow(x + request.ACTIVE_WIDTH + request.ARROW_HEAD_SIZE * 2, x, y + request.Y_ADVANCE);
	}



	function shoveOver(columns, requiredSpacing, caller, callee) {
		currentSpacing = abs(caller.x - callee.x);

		if (currentSpacing lt requiredSpacing) {
			shoveX = requiredSpacing - currentSpacing;
			bSeenEither = false;

			columns.each(function(c) {
				if (bSeenEither) {
					c.x += shoveX;

				} else if (c.key eq caller.key or c.key eq callee.key) {
					bSeenEither = true;

				}
			});
		}
	}


	// Parse directions

	content = reReplace(thistag.generatedcontent, "{}#chr(10)#", "{#chr(10)#}#chr(10)#", "all");
	content = reReplace(content, "#chr(10)#{2,}", chr(10) & "-" & chr(10), "all");
	thistag.generatedcontent = "";
	lines = listToArray(content, chr(10));
	lineIndex = 1;
	maxY = 0;
	columnIndex = 1;
	left = {key = "_left", width = request.DEFAULT_WIDTH, caption = "", index = columnIndex++};
	columns = [left];
	columnsByKey = {_left = left};

	while (lineIndex le lines.len() and trim(lines[lineIndex]) neq "-") {
		rawProperties = listToArray(lines[lineIndex++], " ");
		properties = {key = trim(lCase(rawProperties[1])), lineDrawn = false, index = columnIndex++, active = reFind("[A-Z].*", rawProperties[1]) neq 0};
		if (isNumeric(rawProperties[2])) {
			properties.width = rawProperties[2];
			properties.caption = arrayToList(rawProperties.subList(2, rawProperties.len()), " ");
		} else {
			properties.width = request.DEFAULT_WIDTH;
			properties.caption = arrayToList(rawProperties.subList(1, rawProperties.len()), " ");
		}
		columns.append(properties);
		columnsByKey[properties.key] = properties;
	}

	right = {key = "_right", width = request.DEFAULT_WIDTH, caption = "", index = columnIndex++};
	columns.append(right);
	columnsByKey["_right"] = right;
	bRightColumnWasUsed = false;



	// Init image

	canvas = imageNew(source = "", width = request.IMAGE_WIDTH, height = request.IMAGE_HEIGHT, imageType = "grayscale", canvasColor = "white");
	imageSetDrawingColor(canvas, "black");
	imageSetAntialiasing(canvas, true);
	request.canvas = canvas;



	// Determine column x centres

	dims = getTextDimensions(columns[1].caption, title);
	columns[1].x = 1 + (dims.width + request.TITLE_BOX_PADDING ) / 2;
	columns[1].titleDims = dims;

	for (columnIndex = 2; columnIndex le columns.len(); columnIndex++) {
		columns[columnIndex].titleDims = getTextDimensions(columns[columnIndex].caption, title);
		columns[columnIndex].x = columns[columnIndex - 1].x +
			(columns[columnIndex - 1].titleDims.width + columns[columnIndex].titleDims.width) / 2 +
			request.TITLE_BOX_PADDING * 2;
	}

	dividerLineIndex = lineIndex;
	stack = [left];
	lineIndex++;

	// TODO Big refactor so that there is less code replicated between this and the next while loop

	while (lineIndex le lines.len()) {
		nextLine = listToArray(lines[lineIndex++], " ");
		nextLine[1] = trim(nextLine[1]);

		if (nextLine[1] eq "!") {
			nextLine[1] = "_right";   // message off screen to right
		}

		nextLine[1] = replace(nextLine[1], "!", "");

		if (nextLine[1] eq "return") {
			label = arrayToList(nextLine.subList(1, nextLine.len()), " ");

			if (label neq "") {
				caller = stack[2];
				callee = stack[1];
				requiredSpacing = getTextDimensions(label, normal).width + request.ARROW_HEAD_SIZE + request.ACTIVE_WIDTH * 4;
				shoveOver(columns, requiredSpacing, caller, callee);
			}
		} else if (structKeyExists(columnsByKey, nextLine[1]) and nextLine[nextLine.len()] eq "{") {
			label = arrayToList(nextLine.subList(1, nextLine.len() - 1), " ");
			stack.insertAt(1, columnsByKey[nextLine[1]]);
			caller = stack[2];
			callee = stack[1];
			requiredSpacing = getTextDimensions(label, normal).width + request.ARROW_HEAD_SIZE + request.ACTIVE_WIDTH * 4;
			shoveOver(columns, requiredSpacing, caller, callee);

		} else if (nextLine[1] eq "}") {
			stack.deleteAt(1);

		} else if (nextLine[1] eq "-" or nextLine[1] eq "..." or nextLine[1] eq "///" or left(nextLine[1], 1) eq "##") {
			// ignore all these for purposes of column spacing

		} else {
			label = arrayToList(nextLine, " ");
			callee = stack[1];
			nextColumn = columns[callee.index + 1];
			requiredSpacing = getTextDimensions(label, normal).width + request.ARROW_HEAD_SIZE * 2 + request.ACTIVE_WIDTH * 3;
			shoveOver(columns, requiredSpacing, nextColumn, callee);

		}
	}



	// Draw column titles

	columns.each(
		function(c) {
			if (left(c.key, 1) eq "_")
				return;

			setDrawingStroke(solid);
			drawHCentredRect(c.x, 0, c.titleDims.width + request.TITLE_BOX_PADDING, request.TITLE_BOX_HEIGHT);
			drawHCentredText(c.caption, c.x, request.TITLE_TEXT_Y, title);
		}
	);



	// Work through calls

	y = request.TITLE_BOX_HEIGHT + request.TITLE_BOX_PADDING * 2;
	stack = [left];
	lineIndex = dividerLineIndex + 1;
	bGlue = false;

	while (lineIndex le lines.len()) {
		nextLine = listToArray(lines[lineIndex++], " ");
		nextLine[1] = trim(nextLine[1]);

		if (nextLine[1] eq "!") {
			nextLine[1] = "_right!";   // message off screen to right
			bRightColumnWasUsed = true;
		}

		if (structKeyExists(stack[1], "savedAsyncY")) {
			y = stack[1].savedAsyncY + request.Y_ADVANCE;
			structDelete(stack[1], "savedAsyncY");
		}

		if (nextLine[1] eq "return") {
			if (structKeyExists(columnsByKey, nextLine[2])) {
				caller = columnsByKey[nextLine[2]];
				nextLine.deleteAt(2);
			} else {
				caller = stack[2];
			}

			callee = stack[1];
			label = arrayToList(nextLine.subList(1, nextLine.len()), " ");
			setDrawingStroke(dashed);
			drawArrow(callee.x, caller.x, y, true);

			if (label neq "") {
				drawHCentredText(label, (callee.x + caller.x) / 2, y - request.TEXT_ARROW_GAP, normal);
			}

		} else if ((structKeyExists(columnsByKey, nextLine[1])  or structKeyExists(columnsByKey, replace(nextLine[1], "!", "")))
			and nextLine[nextLine.len()] eq "{") {
			async = nextLine[1] contains "!";
			label = arrayToList(nextLine.subList(1, nextLine.len() - 1), " ");
			stack.insertAt(1, columnsByKey[replace(nextLine[1], "!", "")]);
			caller = stack[2];
			callee = stack[1];

			if (bGlue) {
				bGlue = false;
			} else {
				callee.activeY = y - request.ACTIVE_PADDING;
			}

			if (async) {
				caller.savedAsyncY = y;
			}

			if (label neq "") {
				setDrawingStroke(solid);
				drawArrow(caller.x, callee.x, y, async);
			}

			if (callee.key neq "_right" and not callee.lineDrawn) {
				callee.lineDrawn = true;

				if (callee.active) {
					setDrawingStroke(solid);
				} else {
					setDrawingStroke(dashed);
				}

				drawLine(callee.x, request.TITLE_BOX_HEIGHT, callee.x, y);
				setDrawingStroke(solid);
				drawLine(callee.x, y, callee.x, request.IMAGE_HEIGHT);
			}

			if (label neq "") {
				drawHCentredText(label, (callee.x + caller.x) / 2, y - request.TEXT_ARROW_GAP, normal);
			}


		} else if (nextLine[1] eq "}") {
			caller = stack[2];
			callee = stack[1];

			y += -request.Y_ADVANCE + request.ACTIVE_PADDING;

			if (callee.key neq "_right") {
				drawHCentredRect(callee.x, callee.activeY, request.ACTIVE_WIDTH, y - callee.activeY,  true);
			}

			stack.deleteAt(1);

		} else if (nextLine[1] eq "-" or left(nextLine[1], 1) eq "##") {
			// ignore empty lines and comments

		} else if (nextLine[1] eq "...") {
			y += request.Y_ADVANCE;

		} else if (nextLine[1] eq "===") {
			// indicate that next activation should continue the previous one
			bGlue = true;

		} else if (nextLine[1] eq "///") {
			drawBreak(y, request.Y_ADVANCE / 2);

			columns.each(function(c) {
				if (left(c.key, 1) neq "_") {
					drawLine(c.x - request.ACTIVE_WIDTH, y + 5, c.x + request.ACTIVE_WIDTH, y - 5);
					drawLine(c.x - request.ACTIVE_WIDTH, y + 5 + request.Y_ADVANCE / 2, c.x + request.ACTIVE_WIDTH, y - 5 + request.Y_ADVANCE / 2);
				}
			});

			y += request.Y_ADVANCE;

		// TODO a "glue" operator so that next activation continues previous activation of that column
		} else {
			label = arrayToList(nextLine, " ");
			caller = stack[2];
			callee = stack[1];
			drawLoopArrow(callee.x, y);
			drawText(label, callee.x + request.ACTIVE_WIDTH / 2 + request.ARROW_HEAD_SIZE * 3, y + request.Y_ADVANCE / 2 + request.TEXT_ARROW_GAP, normal, true);
			y += request.Y_ADVANCE;

		}

		y += request.Y_ADVANCE;
		maxY = max(y, maxY);

	}

	drawBufferedText();

	if (bRightColumnWasUsed) {
		lastColumn = columns[columns.len()];
		lastColumn.x -= request.TITLE_BOX_PADDING + request.ACTIVE_WIDTH;
	} else {
		lastColumn = columns[columns.len() - 1];
	}

	imageCrop(canvas, (request.TITLE_BOX_PADDING + request.ACTIVE_WIDTH) / 2, 0, lastColumn. x + lastColumn.titleDims.width / 2 + request.TITLE_BOX_PADDING, maxY);

	image action="writeToBrowser" source="#canvas#" ;
}


</cfscript>