#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);

	StandardProcessing = False;
	
	ArrayOfResourceHeaders = New Array;
	ReportSettings = SettingsComposer.GetSettings();
	For Each  ChoiceItem In ReportSettings.Selection.Items Do

		If Not TypeOf(ChoiceItem) = Type("DataCompositionSelectedField") Then
			Continue;
		EndIf;

		If DataCompositionSchema.TotalFields.Find(ChoiceItem.Field) <> Undefined Then
			If Not IsBlankString(ChoiceItem.Title) Then
				ArrayOfResourceHeaders.Add(ChoiceItem.Title);
			Else
				DataSetField = DataCompositionSchema.DataSets.RevenueAndCOGS.Fields.Find(ChoiceItem.Field); // DataCompositionSchemaDataSetField
				If DataSetField <> Undefined Then
					ArrayOfResourceHeaders.Add(DataSetField.Title);
				EndIf;
			EndIf;
		EndIf;

	EndDo;

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	For Each CurTemplate In CompositionTemplate.Templates Do

		If TypeOf(CurTemplate.Template) <> Type("DataCompositionAreaTemplate") Then
			Continue;
		EndIf;

		For Each RowOfLayoutTable In CurTemplate.Template Do
			For Each LayoutAreaTableCell In RowOfLayoutTable.Cells Do
				For Each Item In LayoutAreaTableCell.Items Do
					If ArrayOfResourceHeaders.Find(Item.Value) <> Undefined Then

						Parameter = LayoutAreaTableCell.Appearance.Items.Find(New DataCompositionParameter("HorizontalAlign"));
						Parameter.Value = HorizontalAlign.Center;
						Parameter.Use = True;

					EndIf;
				EndDo;
			EndDo;
		EndDo;

	EndDo;

	// Create and initialize the layout processor
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	// Let's create and initialize the output processor of the result
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);

	// Denote the beginning of the output
	OutputProcessor.BeginOutput();
	TableIsFixed = False;

	ResultDocument.FixedTop = 0;
	// Main report output cycle
	While True Do
		// We get the following element of the layout result
		ResultItem = CompositionProcessor.Next();

		If ResultItem = Undefined Then
			// The next element is not received - we end the output cycle
			Break;
		Else
			// Fix the header
			If  Not TableIsFixed 
				  And ResultItem.ParameterValues.Count() > 0 
				  And TypeOf(SettingsComposer.Settings.Structure[0]) <> Type("DataCompositionChart") Then

				TableIsFixed = True;
				ResultDocument.FixedTop = ResultDocument.TableHeight;

			EndIf;
			// The element is received - we will output it using the output processor
			OutputProcessor.OutputItem(ResultItem);
		EndIf;
	EndDo;

	OutputProcessor.EndOutput();

	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, CompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetFieldHeaders()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ManagementAccountingCurrency = String(Constants.ManagementAccountingCurrency.Get());

	For Each DataSetField In DataCompositionSchema.DataSets.RevenueAndCOGS.Fields Do
		If TypeOf(DataSetField) = Type("DataCompositionSchemaDataSetField") Then
			If StrFind(DataSetField.Title, "%2%") > 0 Then
				DataSetField.Title = StrReplace(DataSetField.Title, "%2%", ManagementAccountingCurrency);
			EndIf;
		EndIf;
	EndDo;

EndProcedure

SetFieldHeaders();

#EndRegion

#EndIf