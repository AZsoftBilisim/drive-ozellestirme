#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	UserSettings = StorageOfDataCompositionUserSettings.Get();
	If Ref.IsEmpty() Then
		If UserSettings = Undefined Then
			UserSettings = Catalogs.StructureOfTargets.DefaultUserSettings_(Owner);
			
		EndIf;
		
	EndIf;
	
	// Fill in the required parameter of the currency calculation for the SKD where it is and is not filled in
	If Not UserSettings = Undefined Then
		CalculationCurrencyParameter = DataCompositionClientServer.GetParameter(UserSettings,
			"SettlementCurrency");
		If Not CalculationCurrencyParameter = Undefined And CalculationCurrencyParameter.Value = Catalogs.Currencies.EmptyRef() Then
			DataCompositionClientServer.SetParameter(UserSettings,
				"SettlementCurrency",
				TargetValueMonitoring.GetDefaultCurrency(),
				True);
			
			StorageOfDataCompositionUserSettings = New ValueStorage(UserSettings);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Let's clear the cache of calculated values of the analysis variant, 
	// because the structure of the calculated stored data depends on its settings.
	RecordSet = InformationRegisters.DataSourcesOfTargetValueAnalysisOptions.CreateRecordSet();
	RecordSet.Filter.AnalysisOption.Set(Ref);
	RecordSet.Write();
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	EmployeeResponsible = Users.CurrentUser();
EndProcedure

#EndRegion

#EndIf