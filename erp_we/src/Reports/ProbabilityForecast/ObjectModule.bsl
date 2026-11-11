#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	// set the base date for calculating the forecast of closing transactions
	SettingsComposer.Settings.DataParameters.SetParameterValue("Today", CurrentSessionDate());

	// exclude unnecessary fields in the transcript of transactions
	Structure = SettingsComposer.Settings.Structure;
	TransactionField = New DataCompositionField("SalesOpportunity");
	For Each Item In Structure Do
		If Item.Name = "Details" Then
			If Item.GroupFields.Items.Count() = 1
			   And Item.GroupFields.Items[0].Field = TransactionField Then
				ProbabilityField     = New DataCompositionField("Probability");
				FieldPotential       = New DataCompositionField("SalesOpportunityPotentialSaleAmount");
				ClosingForecastField = New DataCompositionField("ForecastOfTheClosingDate");
				SelectedFields   = Item.Selection.Items;
				For Each ChoiceItem In SelectedFields Do
					If ChoiceItem.Field = ProbabilityField
					 Or ChoiceItem.Field = FieldPotential
					 Or ChoiceItem.Field = ClosingForecastField Then
						ChoiceItem.Use = False;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#EndIf