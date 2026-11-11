
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.DefaultButtonTitle) Then
		Items.FormSetFilter.Title = Parameters.DefaultButtonTitle;
	EndIf;
	
	Documents.ARAPReconciliation2_5_11.InitializeSettingsComposer(LinkerSelection, UUID, Parameters.Filter_Settings);
	
	If Parameters.HideServiceSelections Then
		
		ServiceFields = New Array;
		ServiceFields.Add(New DataCompositionField("Organization"));
		ServiceFields.Add(New DataCompositionField("Counterparty"));
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			ServiceFields.Add(New DataCompositionField("Partner"));
		EndIf;
		If Not GetFunctionalOption("UseCustomerContracts")
			And Not GetFunctionalOption("UseContractsWithVendors") Then
			ServiceFields.Add(New DataCompositionField("Contract"));
			ServiceFields.Add(New DataCompositionField("Contract.Status"));
		EndIf;
		
		For Each FIlterRow In LinkerSelection.Settings.Filter.Items Do
			If TypeOf(FIlterRow) = Type("DataCompositionFilterItemGroup") Then
				Continue;
			EndIf;
			ThisIsServiceLineOfSelection = ServiceFields.Find(FIlterRow.LeftValue) <> Undefined;
			If ThisIsServiceLineOfSelection Then
				FIlterRow.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
			EndIf;
		EndDo;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetFilter(Command)
	
	Result = New Structure;
	Result.Insert("Filter_Settings", GetSelectionSettings());
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure CancelInstallation(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetSelectionSettings()
	
	Return LinkerSelection.GetSettings();
	
EndFunction

#EndRegion