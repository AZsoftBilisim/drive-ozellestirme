
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Parameters.Property("Scenario", Scenario);
	Parameters.Property("Currency",   Currency);
	
	CommonClientServer.SetDynamicListParameter(ForecastedExchangeRates, "Scenario", Scenario);
		
	If ValueIsFilled(Currency) Then
		CommonClientServer.SetFilterItem(
			ForecastedExchangeRates.Filter, "Currency", Currency, DataCompositionComparisonType.Equal, "Currency", True);
	EndIf;
	
	Item = Items.ForecastRatesDownload;
	Item.Visible = (AccessRight("Edit", Metadata.InformationRegisters.ForecastedExchangeRatesOfScenarios));
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DownloadedScriptCourses" Then
		Items.ForecastedExchangeRates.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Currency) Then
		CommonClientServer.SetFilterItem(ForecastedExchangeRates.Filter, "Currency", Currency);
	Else
		CommonClientServer.DeleteFilterItems(ForecastedExchangeRates.Filter, "Currency");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersForecastedExchangeRates

&AtClient
Procedure ForecastedExchangeRatesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	If Copy Then
		
		CurrentData = Item.CurrentData;
		FillingValues = New Structure;
		If CurrentData <> Undefined Then
			FillingValues.Insert("Scenario", Scenario);
			FillingValues.Insert("Currency", CurrentData.Currency);
			FillingValues.Insert("CourseNumerator", CurrentData.CourseNumerator);
			FillingValues.Insert("CourseDenominator", CurrentData.CourseDenominator);
		EndIf;
		
	Else
		
		FillingValues = New Structure;
		FillingValues.Insert("Scenario", Scenario);
		FillingValues.Insert("Currency",   Currency);
	
	EndIf;
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("InformationRegister.ForecastedExchangeRatesOfScenarios.Form.RecordingFormForScenario", 
		FormParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure ForecastedExchangeRatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenEntryForm();
	
EndProcedure

&AtClient
Procedure ForecastedExchangeRatesBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenEntryForm();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportCurrencyRates(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Scenario", Scenario);
	FormParameters.Insert("Currency",   Currency);
	
	OpenForm("InformationRegister.ForecastedExchangeRatesOfScenarios.Form.LoadForm", FormParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure OpenEntryForm()
	
	FormParameters = New Structure("Key", Items.ForecastedExchangeRates.CurrentRow);
	
	OpenForm("InformationRegister.ForecastedExchangeRatesOfScenarios.Form.RecordingFormForScenario",
		FormParameters,
		ThisForm);
	
EndProcedure

#EndRegion

#EndRegion
