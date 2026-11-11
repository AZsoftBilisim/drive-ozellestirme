
#Region Public

#Region GraphicalPresentationOfProcess

// Creates a graphical representation of the stages of a process that has a specific sequence.
//
// Parameters:
//  ProcessSteps - ValueTable - data of process stages, required columns (See UniversalDataProcessor.AddRequiredColumnsToProcessSteps):
//                   * OutputParameters      - Structure -
//                   * DurationOfDays     - Number -
//                   * Parent             - Arbitrary -
//                   * SequenceNumber      - Number -
//                   * StagesPredecessors - ValueTable -
//                   * Group               - Number -
//  OutputParameters - Structure - output parameters for the graphical representation of the process.
// 
// Returns:
//  Structure - contains a tabular document with a graphical representation of the process and its increasing duration.
//
Function GenerateGraphicalPresentationOfProcess(ProcessSteps, OutputParameters = Undefined) Export
	
	Var Levels;

	If OutputParameters = Undefined Then
		OutputParameters = NewOutputParameters();
	EndIf;
	
	AddRequiredColumnsToProcessSteps(ProcessSteps);
	
	ProcessProcessSteps(ProcessSteps, Levels);
	
	Result = OutputStageDiagram(ProcessSteps, Levels, OutputParameters);
	
	Stages  = Undefined;
	Levels = Undefined;
	
	Return Result;
	
EndFunction

// Checks for required columns in the process stages and adds the missing ones.
//
// Parameters:
//  ProcessSteps - ValueTable - critical stages of the process.
//
Procedure AddRequiredColumnsToProcessSteps(ProcessSteps) Export

	If ProcessSteps.Columns.Find("OutputParameters") = Undefined Then
		ProcessSteps.Columns.Add("OutputParameters", New TypeDescription("Structure"));
	EndIf; 
	
	If ProcessSteps.Columns.Find("DurationOfDays") = Undefined Then
		ProcessSteps.Columns.Add("DurationOfDays", New TypeDescription("Number"));
	EndIf; 
	
	If ProcessSteps.Columns.Find("Parent") = Undefined Then
		ProcessSteps.Columns.Add("Parent");
	EndIf; 
	
	If ProcessSteps.Columns.Find("SequenceNumber") = Undefined Then
		ProcessSteps.Columns.Add("SequenceNumber", New TypeDescription("Number"));
	EndIf; 
	
	If ProcessSteps.Columns.Find("StagesPredecessors") = Undefined Then
		ProcessSteps.Columns.Add("StagesPredecessors", New TypeDescription("ValueTable"));
	EndIf;
	
	If ProcessSteps.Columns.Find("Group") = Undefined Then
		ProcessSteps.Columns.Add("Group", New TypeDescription("Number"));
	EndIf; 
	
EndProcedure

// Defines the default output parameters for the graphical representation of the process
//
// Returns:
//  Structure - output parameters.
//
Function NewOutputParameters() Export

	OutputParameters = New Structure; 
	OutputParameters.Insert("IndentationHeight", 4);
	OutputParameters.Insert("IndentationWidth", 4);
	OutputParameters.Insert("BendingWidth",  1.2);
	OutputParameters.Insert("StageWidth",   40);
	OutputParameters.Insert("StageHeight",   28);
	OutputParameters.Insert("CurrentStep",   Undefined);

	Return OutputParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Other

// This function determines the position of the stage on the chart along the Y axis
// 
Function DefineNewPositionInYLevel(StageString_, OccupiedLevelsByY, Preference = Undefined)
	
	If Not Preference = Undefined And OccupiedLevelsByY[Preference] = Undefined Then
		Result = Preference;
	Else
		Result = 0;
		
		While Not OccupiedLevelsByY[Result] = Undefined Do
			Result = Result + 1;
		EndDo;
		
	EndIf;
	OccupiedLevelsByY.Insert(Result, True);
	Return Result;
	
EndFunction

// The procedure calculates the position of the stage on the graph along the X axis
// 
Procedure CalculateLevelX(StageString_, Stages)
	
	If Not StageString_.LevelX = Undefined Then
		Return;
	EndIf;
	
	StageString_.StagesPredecessors.Columns.Add("PredecessorStageString");
	If StageString_.StagesPredecessors.Count() Then
		MaxLevel_ = 0;
		TheStructureOfTheSearch = New Structure("Stage, Group");
		For Each PredecessorString In StageString_.StagesPredecessors Do
			
			TheStructureOfTheSearch.Stage = PredecessorString.ProcessStep;
			TheStructureOfTheSearch.Group = PredecessorString.Group;
			FoundRows = Stages.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() = 1 Then
				PredecessorString.PredecessorStageString = FoundRows[0];
			EndIf;
			
			CalculateLevelX(PredecessorString.PredecessorStageString, Stages);
			MaxLevel_ = Max(MaxLevel_, PredecessorString.PredecessorStageString.LevelX);
			
		EndDo;
		StageString_.LevelX = MaxLevel_ + 1;
	Else
		StageString_.LevelX = 0;
	EndIf;
	
EndProcedure

// The function returns a table of stages based on the process template, 
// with additional intermediate data.
// 
Procedure ProcessProcessSteps(ProcessSteps, Levels)
	
	ProcessSteps.Columns.Add("LevelX");
	ProcessSteps.Columns.Add("NumberOfPredecessors");
	ProcessSteps.Columns.Add("DurationIncreasing", New TypeDescription("Number"));
	
	For Each StageString_ In ProcessSteps Do
		CalculateLevelX(StageString_, ProcessSteps);
		StageString_.NumberOfPredecessors = StageString_.StagesPredecessors.Count();
	EndDo;
	
	ProcessSteps.Sort("LevelX, NumberOfPredecessors, Parent, SequenceNumber");
	
	ProcessSteps.Columns.Add("LevelY");
	
	Levels = New Structure("X, U", New Map, New Map);
	LevelX = 0;
	LevelLines = ProcessSteps.FindRows(New Structure("LevelX", LevelX));
	While LevelLines.Count() Do
		StructureX = New Structure("IndentationX, OccupiedLevelsByY", 0, New Map);
		Levels.X.Insert(LevelX, StructureX);
		LevelY = -1;
		For Each StageString_ In LevelLines Do
			
			StageString_.StagesPredecessors.Columns.Add("IndentationX", New TypeDescription("Number"));
			StageString_.StagesPredecessors.Columns.Add("IndentationY", New TypeDescription("Number"));
			If StageString_.StagesPredecessors.Count() = 0 Then
				StageString_.DurationIncreasing = StageString_.DurationOfDays;
				LevelY = LevelY + 1;
			Else
				
				If StageString_.StagesPredecessors.Count() = 1 Then
					Preference =StageString_.StagesPredecessors[0].PredecessorStageString.LevelY;
				Else
					Preference = Undefined;
				EndIf;
				
				LevelY = DefineNewPositionInYLevel(StageString_, StructureX.OccupiedLevelsByY, Preference);
				
				For Each PredecessorString In StageString_.StagesPredecessors Do
					
					StageString_.DurationIncreasing = Max(StageString_.DurationIncreasing, PredecessorString.PredecessorStageString.DurationIncreasing + StageString_.DurationOfDays);
					
					StructureX.IndentationX = StructureX.IndentationX + 1;
					
					If Not StageString_.LevelX = PredecessorString.PredecessorStageString.LevelX + 1 Then
						YStructure = Levels.U[PredecessorString.PredecessorStageString.LevelY];
						YStructure.IndentationY = YStructure.IndentationY + 1;
						PredecessorString.IndentationY = YStructure.IndentationY;
					EndIf;
					
					PredecessorString.IndentationX = StructureX.IndentationX;
					
				EndDo;
				
			EndIf;
			
			YStructure = Levels.U[LevelY];
			If YStructure = Undefined Then
				YStructure = New Structure("IndentationY", 0);
				Levels.U.Insert(LevelY, YStructure);
			EndIf;
			
			StageString_.LevelY = LevelY;
			
		EndDo;
		
		LevelX = LevelX + 1;
		LevelLines = ProcessSteps.FindRows(New Structure("LevelX", LevelX));
	EndDo;
	
EndProcedure

// The procedure displays a diagram of the stages in the table document field
//
Function OutputStageDiagram(ProcessSteps, Levels, OutputParameters)
	
	IndentationWidth = OutputParameters.IndentationWidth;
	StageWidth   = OutputParameters.StageWidth;
	IndentationHeight = OutputParameters.IndentationHeight;
	StageHeight   = OutputParameters.StageHeight;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	StageLeft = IndentationWidth;
	For IndexOf = 0 To Levels.X.Count() - 1 Do
		
		StructureX = Levels.X.Get(IndexOf);
		If StructureX <> Undefined Then
			
			If IndexOf Then
				StageLeft = StageLeft + Max(StructureX.IndentationX + 1, 2) * IndentationWidth + StageWidth;
			EndIf;
			
			StructureX.Insert("StageLeft", StageLeft);
			
		EndIf;
		
	EndDo;
	
	StageTop = IndentationHeight;
	For IndexOf = 0 To Levels.U.Count() - 1 Do
		
		YStructure = Levels.U.Get(IndexOf);
		If YStructure <> Undefined Then
			
			If IndexOf Then
				StageTop = StageTop + Max(Levels.U[IndexOf - 1].IndentationY + 1, 1) * IndentationHeight + StageHeight;
			EndIf;
			
			YStructure.Insert("StageTop", StageTop);
			
		EndIf;
		
	EndDo;
	
	For IndexOf = 0 To Levels.X.Count() - 1 Do
		
		LevelLines = ProcessSteps.FindRows(New Structure("LevelX", IndexOf));
		
		For Each StageString_ In LevelLines Do
			
			DrawConnections(SpreadsheetDocument, StageString_, Levels, OutputParameters);
			
		EndDo;
		
	EndDo;
	
	DurationIncreasing = 0;
	For IndexOf = 0 To Levels.X.Count() - 1 Do
		
		LevelLines = ProcessSteps.FindRows(New Structure("LevelX", IndexOf));
		
		For Each StageString_ In LevelLines Do
			DrawStage(SpreadsheetDocument, StageString_, Levels, OutputParameters);
			DurationIncreasing = Max(DurationIncreasing, StageString_.DurationIncreasing)
		EndDo;
		
	EndDo;
	
	Result = New Structure;
	Result.Insert("DurationIncreasing", DurationIncreasing);
	Result.Insert("SpreadsheetDocument",       SpreadsheetDocument);
	
	Return Result;
	
EndFunction

// The procedure draws a stage on the table document field
//
Procedure DrawStage(SpreadsheetDocument, StageString_, Levels, OutputParameters)
	
	StageBackgroundColor = Undefined;
	If StageString_.OutputParameters.Property("StageBackgroundColor") Then
		StageBackgroundColor = StageString_.OutputParameters.StageBackgroundColor;
	EndIf; 
	
	StageLineColor = Undefined;
	If StageString_.OperationNumber = OutputParameters.CurrentStep Then
		StageLineColor = WebColors.Blue;
	EndIf; 
	
	StageWidth = OutputParameters.StageWidth;	
	StageHeight = OutputParameters.StageHeight;	
	
	StageTop = Levels.U[StageString_.LevelY].StageTop;
	StageLeft = Levels.X[StageString_.LevelX].StageLeft;
	
	Drawing = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Rectangle);
	Drawing.Left = StageLeft;
	Drawing.Top = StageTop;
	Drawing.Width = StageWidth;
	Drawing.Height = StageHeight;
	
	If StageBackgroundColor <> Undefined Then
		Drawing.BackColor = StageBackgroundColor;
	EndIf; 
	If StageLineColor <> Undefined Then
		Drawing.LineColor = StageLineColor;
	EndIf; 
	
	Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
	
	TextLineHeight = 4;
	
	Details = StageString_.Details;
	
	Text = ""  + StageString_.PresentationStage;
	
	TextParameters = TextParameters();
	TextParameters.Left = StageLeft;
	TextParameters.Top = StageTop;
	TextParameters.Width = StageWidth;
	TextParameters.Height = TextLineHeight * 3;
	TextParameters.BackColor = StageBackgroundColor;
	TextParameters.LineColor = StageLineColor;
	Drawing = DrawText(SpreadsheetDocument, Text, Details, TextParameters);
									
	Drawing.Font = New Font(Drawing.Font,,,True);
	Drawing.Name = StageString_.OperationNumber;
	
	If StageString_.Text1 <> "" Then
		
		TextParameters = TextParameters();
		TextParameters.Left = StageLeft;
		TextParameters.Top = StageTop + TextLineHeight * 3;
		TextParameters.Width = StageWidth;
		TextParameters.Height = TextLineHeight * 2;
		TextParameters.BackColor = StageBackgroundColor;
		TextParameters.LineColor = StageLineColor;
		Drawing = DrawText(SpreadsheetDocument, StageString_.Text1, Details, TextParameters);
		
		If StageString_.OutputParameters.Property("TextPlacement1") Then
			Drawing.TextPlacement = StageString_.OutputParameters.TextPlacement1;
		EndIf; 
	EndIf;
	
	If StageString_.Text2 <> "" Then
		
		TextParameters = TextParameters();
		TextParameters.Left = StageLeft;
		TextParameters.Top = StageTop + TextLineHeight * 5;
		TextParameters.Width = StageWidth;
		TextParameters.Height = StageHeight - TextLineHeight * 5;
		TextParameters.BackColor = StageBackgroundColor;
		TextParameters.LineColor = StageLineColor;
		Drawing = DrawText(SpreadsheetDocument, StageString_.Text2, Details, TextParameters);
									
		If StageString_.OutputParameters.Property("TextPlacement2") Then
			Drawing.TextPlacement = StageString_.OutputParameters.TextPlacement2;
		EndIf; 
	EndIf;
	
EndProcedure

// The procedure draws stage relationships on the table document field
//
Procedure DrawConnections(SpreadsheetDocument, StageString_, Levels, OutputParameters)
	
	BendingWidth   = OutputParameters.BendingWidth;	
	StageHeight    = OutputParameters.StageHeight;	
	StageWidth    = OutputParameters.StageWidth;	
	IndentationHeight  = OutputParameters.IndentationHeight;	
	IndentationWidth  = OutputParameters.IndentationWidth;	
	
	StageTop = Levels.U[StageString_.LevelY].StageTop;
	
	StageLeft = Levels.X[StageString_.LevelX].StageLeft;
	
	For Each PredecessorString In StageString_.StagesPredecessors Do
		
		PredecessorStageString = PredecessorString.PredecessorStageString;
		
		TopOfPredecessor = Levels.U[PredecessorStageString.LevelY].StageTop;
		LeftOfPredecessor = Levels.X[PredecessorStageString.LevelX].StageLeft;
		
		Details = New Structure("Stage, PredecessorStage", StageString_.Stage, PredecessorString.ProcessStep);
		Flag = ?(PredecessorStageString.LevelY > StageString_.LevelY, -1, 1);
		If PredecessorStageString.LevelX + 1 = StageString_.LevelX Then
			LeftOfLine   = LeftOfPredecessor + StageWidth;
			TopOfLine   = TopOfPredecessor + StageHeight / 4;
			
			DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, StageLeft - LeftOfLine - PredecessorString.IndentationX*IndentationWidth - BendingWidth, 0);
			If PredecessorStageString.LevelY = StageString_.LevelY Then
				DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, BendingWidth, BendingWidth);
				DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, 0, StageHeight / 2 - BendingWidth * 2);
				DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, BendingWidth, BendingWidth);
			Else
				DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, BendingWidth, Flag * BendingWidth);
				DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, 0, StageTop + StageHeight / 4 * 3 - TopOfLine - Flag * BendingWidth);
				DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, BendingWidth, Flag * BendingWidth);
			EndIf;
			
			DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, StageLeft - LeftOfLine, 0);
			DrawArrow(SpreadsheetDocument, Details, LeftOfLine, TopOfLine);
			
		Else
			
			LeftOfLine   = LeftOfPredecessor + StageWidth / 4 * 3;
			TopOfLine   = TopOfPredecessor + StageHeight;
			
			DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, 0, IndentationHeight* PredecessorString.IndentationY - BendingWidth);
			DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, BendingWidth, BendingWidth);
			
			DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, StageLeft - LeftOfLine - PredecessorString.IndentationX*IndentationWidth - BendingWidth, 0);
			
			If PredecessorStageString.LevelY = StageString_.LevelY Then
				DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, BendingWidth, - BendingWidth);
				DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, 0, StageTop + StageHeight / 4 * 3 - TopOfLine + BendingWidth);
				DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, BendingWidth, - BendingWidth);
			Else
				DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, BendingWidth, Flag * BendingWidth);
				DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, 0, StageTop + StageHeight / 4 * 3 - TopOfLine - Flag * BendingWidth);
				DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, BendingWidth, Flag * BendingWidth);
			EndIf;
			
			DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, StageLeft - LeftOfLine, 0);
			DrawArrow(SpreadsheetDocument, Details, LeftOfLine, TopOfLine);
			
		EndIf;
	EndDo;
	
EndProcedure

// Returns text parameters to pass to the DrawText function()
// 
// Returns:
//  Structure - list of parameters.
//
Function TextParameters()

	TextParameters = New Structure;
	TextParameters.Insert("Left");
	TextParameters.Insert("Top"); 
	TextParameters.Insert("Width");
	TextParameters.Insert("Height");
	TextParameters.Insert("BackColor", Undefined);
	TextParameters.Insert("LineColor", Undefined);
	
	Return TextParameters;

EndFunction

// This function outputs a "text" drawing to a table document 
//
Function DrawText(SpreadsheetDocument, Text, Details, TextParameters)

	Drawing = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Text);
	Drawing.Left   = TextParameters.Left;
	Drawing.Top   = TextParameters.Top;
	Drawing.Width = TextParameters.Width;
	Drawing.Height = TextParameters.Height;
	
	Drawing.Details = Details;
	Drawing.Text = Text;
	
	If TextParameters.BackColor <> Undefined Then
		Drawing.BackColor = TextParameters.BackColor;
	EndIf; 
	
	If TextParameters.LineColor <> Undefined Then
		Drawing.LineColor = TextParameters.LineColor;
	EndIf; 
	
	Return Drawing;
	
EndFunction

// This function outputs a line drawing to a table document
//
Procedure DrawLine(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, LineWidth, LineHeight);
	
	Line = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Line);
	Line.Left   = LeftOfLine;
	Line.Top   = TopOfLine;
	Line.Width = LineWidth;
	Line.Height = LineHeight;
	
	Line.Details = Details;
	Line.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
	
	LeftOfLine = LeftOfLine + LineWidth;
	TopOfLine = TopOfLine + LineHeight;
	
EndProcedure

// The function outputs a drawing from lines, in the form of a bend, to a table document
//
Procedure DrawBend(SpreadsheetDocument, Details, LeftOfLine, TopOfLine, LineWidth, LineHeight);
	
	Indent = 0.1;
	ShiftLeft = ?(LineWidth > 0, Indent, -Indent);
	ShiftTop = ?(LineHeight > 0, Indent, -Indent);
	
	Line = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Line);
	Line.Left   = LeftOfLine + ShiftLeft;
	Line.Top   = TopOfLine + ShiftTop;
	Line.Width = LineWidth - ShiftLeft * 2;
	Line.Height = LineHeight - ShiftTop * 2;
	
	Line.Details = Details;
	Line.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
	
	LeftOfLine = LeftOfLine + LineWidth;
	TopOfLine = TopOfLine + LineHeight;
	
EndProcedure

// The function outputs a drawing from lines, in the form of an arrow, to a table document
//
Procedure DrawArrow(SpreadsheetDocument, Details, LeftOfLine, TopOfLine)
	
	Line = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Line);
	Line.Left   = LeftOfLine - 2;
	Line.Top   = TopOfLine - 1.5;
	Line.Width = 1.5;
	Line.Height = 1.5;
	
	Line.Details = Details;
	Line.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
	
	Line = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Line);
	Line.Left   = LeftOfLine - 2;
	Line.Top   = TopOfLine + 1.5;
	Line.Width = 1.5;
	Line.Height = -1.5;
	
	Line.Details = Details;
	Line.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid, 2);
	
EndProcedure

#EndRegion

#EndRegion
