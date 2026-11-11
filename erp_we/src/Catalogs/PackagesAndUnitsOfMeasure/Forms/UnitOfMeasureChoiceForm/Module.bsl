#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Items.FormSelectingFromClassifier.Visible = AccessRight("Insert",
																	Metadata.Catalogs.PackagesAndUnitsOfMeasure);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(ThisObject);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectingFromClassifier(Command)
	
	FilterParameters = New Array;
	
	For Each FilterElement In List.Filter.Items Do
		If FilterElement.LeftValue = New DataCompositionField("MeasuredValueType")
			And FilterElement.Use Then
			
			If FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
				FilterParameters.Add(FilterElement.RightValue);
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.InList Then 
				FilterParameters = FilterElement.RightValue.UnloadValues();
			EndIf;
		EndIf;
	EndDo;
	
	
	OpenBuiltInSelection(Undefined, FilterParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenBuiltInSelection(Result, AdditionalParameters) Export
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter", AdditionalParameters);
	
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.UnitOfMeasureClassifier",
		OpeningParameters,
		ThisObject,
		,
		,
		,
		New CallbackDescription("SelectingFromClassifierCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure SelectingFromClassifierCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure")
		And Result.Property("NumberOfNewItems_") Then
		
		ProductsClient.NotifyAboutChangesInUnitSelectionList(
			Result.NumberOfNewItems_,
			Result.NewItems);
		
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion