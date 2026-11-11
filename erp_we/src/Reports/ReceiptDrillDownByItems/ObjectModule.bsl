#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	CurrencyOfManAccounting = Constants.ManagementAccountingCurrency.Get();
	UnitOfMeasureForWeight = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	ReportSettings = SettingsComposer.GetSettings();
	For Each  ChoiceItem In ReportSettings.Selection.Items Do
		If StrFind(ChoiceItem.Title,"Sum") > 0 Then
			ChoiceItem.Title = NStr("vi = 'Tổng số';
									|ru = 'Сумма';
									|en = 'Amount'; fa = 'مبلغ';
									|it = 'Importo';
									|pl = 'Amount';
									|tr = 'Tutar'") + " (" + CurrencyOfManAccounting + ")";
		ElsIf StrFind(ChoiceItem.Title,"Weight") > 0 Then
			ChoiceItem.Title = NStr("vi = 'Trọng lượng';
									|ru = 'Вес';
									|en = 'Weight'; fa = 'وزن';
									|it = 'Peso';
									|pl = 'Waga';
									|tr = 'Ağırlık'") + " (" + UnitOfMeasureForWeight + ")";
		ElsIf StrFind(ChoiceItem.Title,"VolumeM3") > 0 Then
			ChoiceItem.Title = NStr("vi = 'Khối lượng';
									|ru = 'Объем';
									|en = 'Volume'; fa = 'حجم';
									|it = 'Volume';
									|pl = 'Objętość';
									|tr = 'Hacim'") + " (" + UnitOfMeasureForVolume + ")";
		EndIf;
	EndDo;
	
	QueryText = DataCompositionSchema.DataSets.Query.Query;

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("CatProducts.UnitOfMeasure", "CatProducts"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("CatProducts.UnitOfMeasure", "CatProducts"));

	DataCompositionSchema.DataSets.Query.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	// Let's create and initialize the layout processor.
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	// Let's create and initialize the output processor of the result.
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	// Let's denote the beginning of the output.
	OutputProcessor.BeginOutput();
	TableIsFixed = False;

	ResultDocument.FixedTop = 0;
	// The main cycle of the report output.
	While True Do
		// We get the next element of the layout result.
		ResultItem = CompositionProcessor.Next();

		If ResultItem = Undefined Then
			// The next element is not received - we end the output cycle.
			Break;
		Else
			// Fix the header
			If  Not TableIsFixed 
				  And ResultItem.ParameterValues.Count() > 0 
				  And TypeOf(SettingsComposer.Settings.Structure[0]) <> Type("DataCompositionChart") Then

				TableIsFixed = True;
				ResultDocument.FixedTop = ResultDocument.TableHeight;

			EndIf;
			// The element is received - we will output it using the output processor.
			OutputProcessor.OutputItem(ResultItem);
		EndIf;
	EndDo;

	OutputProcessor.EndOutput();
	
EndProcedure

#EndRegion

#EndIf