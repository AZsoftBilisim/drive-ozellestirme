#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillFilterParameters();
	SetListLimit();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	CashServerLocalization.AddBankAccountCreationCommands(ThisObject, Metadata.Catalogs.CounterpartyBankAccounts);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_CreateBankAccount(Command)
	CashClientLocalization.OpenBankAccountCreation(List, Command, False);
EndProcedure

&AtClient
Procedure Show_ClosedAccounts(Command)

	Items.FormShow_ClosedAccounts.Check = Not DisplayClosedAccounts;
	DisplayClosedAccounts = Not DisplayClosedAccounts;
	SetListLimit();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillFilterParameters()

	FilterParameters = New Structure;
	
	For Each FilterElement In Parameters.Filter Do
		
		If ValueIsFilled(Parameters.Filter[FilterElement.Key]) Then
			FilterParameters.Insert(FilterElement.Key, Parameters.Filter[FilterElement.Key]);
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure SetListLimit()

	DescriptionOfListSelections = New Array;
	RestrictedFields = New Array;
	RestrictedFields.Add("Closed");
	
	If Not DisplayClosedAccounts Then
		
		FilterDetails = New Structure;
		FilterDetails.Insert("FilterCriterion", "BankAccounts.Closed = &Closed");
		FilterDetails.Insert("ParameterValues", New Structure("Closed", DisplayClosedAccounts));
		
		DescriptionOfListSelections.Add(FilterDetails);
		
	EndIf;
	
	For Each FilterElement In FilterParameters Do
		
		If FilterElement.Key = "Closed" Then
			Continue;
		EndIf;
		
		If FilterElement.Key = "OwnerOfLegalEntityIsNaturalPerson" Then
			
			FilterDetails = New Structure;
			FilterDetails.Insert("FilterCriterion", "BankAccounts.Owner.LegalEntityIndividual = &LegalEntityIndividual");
			FilterDetails.Insert("ParameterValues", New Structure("LegalEntityIndividual", FilterParameters[FilterElement.Key]));
			
			DescriptionOfListSelections.Add(FilterDetails);
			
		ElsIf FilterElement.Key = "Key" Then
			
			FilterDetails = New Structure;
			FilterDetails.Insert("FilterCriterion", "BankAccounts.Ref = &Ref");
			FilterDetails.Insert("ParameterValues", New Structure("Ref", FilterParameters[FilterElement.Key]));
			
			DescriptionOfListSelections.Add(FilterDetails);
			RestrictedFields.Add("Ref");
			
		ElsIf List.Fields.Find(FilterElement.Key) <> Undefined Then
			
			If TypeOf(FilterElement.Value) = Type("Array")
				Or TypeOf(FilterElement.Value) = Type("ValueList")
				Or TypeOf(FilterElement.Value) = Type("FixedArray") Then
				Template = "BankAccounts.%1 IN (&%1)";
			Else
				Template = "BankAccounts.%1 = &%1"
			EndIf;
			
			FilterCriterion = StrTemplate(Template, FilterElement.Key);
			FilterDetails = New Structure;
			FilterDetails.Insert("FilterCriterion", FilterCriterion);
			FilterDetails.Insert("ParameterValues", New Structure(FilterElement.Key, FilterElement.Value));
			DescriptionOfListSelections.Add(FilterDetails);
			RestrictedFields.Add(FilterElement.Key);
			
		EndIf;
		
	EndDo;
	
	SetListRequestText(DescriptionOfListSelections, RestrictedFields);

EndProcedure

&AtServer
Procedure SetListRequestText(FiltersDetails, RestrictedFields)
	
	QueryText = "
	|SELECT
	|	BankAccounts.Owner AS Owner,
	|	BankAccounts.Description AS Description,
	|	BankAccounts.AccountNumber AS AccountNumber,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BankBIC,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	BankAccounts.CashCurrency AS CashCurrency,
	|	BankAccounts.Closed AS Closed,
	|	BankAccounts.Ref AS Ref
	|FROM
	|	Catalog.CounterpartyBankAccounts AS BankAccounts
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON BankAccounts.Bank = BankClassifier.Ref
	|WHERE
	|	&FilterConditions";
	
	SelectionConditionsInList = New Array;
	
	For Each FilterDetails In FiltersDetails Do
		SelectionConditionsInList.Add(FilterDetails["FilterCriterion"]);
	EndDo;
	
	FilterConditions = StrConcat(SelectionConditionsInList," And ");
	QueryText = StrReplace(QueryText, "&FilterConditions", ?(IsBlankString(FilterConditions), "TRUE", FilterConditions));

	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	For Each FilterDetails In FiltersDetails Do
		ParameterValues = FilterDetails.ParameterValues;
		For Each ParameterValue In ParameterValues Do
			List.Parameters.SetParameterValue(ParameterValue.Key, ParameterValue.Value);
		EndDo;
	EndDo;
	
	If RestrictedFields.Count() > 0 Then
		
		For Each ListBox In RestrictedFields Do
			FieldWithRestriction = List.Fields.Find(ListBox);
			If Not FieldWithRestriction = Undefined Then
				FieldWithRestriction.UseRestriction.Condition = True;
				FieldWithRestriction.UseRestriction.Group = True;
				FieldWithRestriction.UseRestriction.Order = True;
				FieldWithRestriction.AttributeUseRestriction.Condition = True;
				FieldWithRestriction.AttributeUseRestriction.Group = True;
				FieldWithRestriction.AttributeUseRestriction.Order = True;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion
