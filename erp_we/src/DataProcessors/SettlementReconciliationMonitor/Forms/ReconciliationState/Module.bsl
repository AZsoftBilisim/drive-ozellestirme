
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Object.Organization = Parameters.Organization;
	Object.BeginOfPeriod = Parameters.BeginOfPeriod;
	Object.EndOfPeriod = Parameters.EndOfPeriod;
	Counterparty = Parameters.Counterparty;
	TypesOfCalculations_ = New FixedArray(Parameters.TypesOfCalculations_);
	EDIParticipant = Parameters.EDIParticipant;
	Currency = Parameters.Currency;
	IncludeContractsWithoutTurnover = Parameters.IncludeContractsWithoutTurnover;
	
	ReconciliationParameters = ReconciliationParameters();
	DataProcessor = FormAttributeToValue("Object");
	ReportData = DataProcessor.GenerateDecryption(ReconciliationParameters);
	DetailsDataAddress = ReportData.DetailsDataAddress;
	
	ReportResult.Put(ReportData.Result);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportResultDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	StandardProcessing = False;
	
	DetailsValue = GetValueToOpen(Details);
	
	If DetailsValue <> Undefined Then
		ShowValue(, DetailsValue);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ReconciliationParameters()
	
	Result = New Structure;
	
	Result.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	Result.Insert("EndOfPeriod", EndOfDay(Object.EndOfPeriod));
	Result.Insert("Organization", Object.Organization);
	Result.Insert("Counterparty", Counterparty);
	Result.Insert("Manager", Manager);
	Result.Insert("OnlyOurCompanies", False);
	Result.Insert("TypesOfCalculations_", TypesOfCalculations_);
	Result.Insert("EDIParticipant", EDIParticipant);
	Result.Insert("Currency", Currency);
	Result.Insert("IncludeContractsWithoutTurnover", IncludeContractsWithoutTurnover);
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	Result.Insert("ThisIsLocalCurrency", Currency = ComplCurrency);
	Result.Insert("UUID", UUID);
	
	Return Result;
	
EndFunction

&AtServer
Function GetValueToOpen(Details)
	
	If Common.IsReference(TypeOf(Details)) Then
		Return Details;
	EndIf;
	
	DetailsData = GetFromTempStorage(DetailsDataAddress);//DataCompositionDetailsData
	DetailsItem = DetailsData.Items[Details];
	If TypeOf(DetailsItem) = Type("DataCompositionGroupDetailsItem") Then
		Return Undefined;
	EndIf;
	
	DecryptionFields = DetailsItem.GetFields();
	If DecryptionFields.Count() > 0 Then
		DetailsValue = DecryptionFields[0].Value;
		If DetailsItem.MainAction = DataCompositionDetailsProcessingAction.DrillDown Then
			Return DetailsValue;
		EndIf;
		
		If DetailsValue = Null
			Or DetailsValue = Undefined
			Or TypeOf(DetailsValue) = Type("Number")
			Or TypeOf(DetailsValue) = Type("String")
			Or TypeOf(DetailsValue) = Type("Boolean") Then
			Return Undefined;
		Else
			Return DetailsValue;
		EndIf;
	EndIf;
	
EndFunction

#EndRegion
