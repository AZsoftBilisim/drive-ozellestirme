
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetUnavailableSelectionsFromParameters(Parameters.Filter);
		
	If Parameters.Property("Partner") Then
		
		PartnerList = New ValueList;
		PartnersAndCounterparties.FillInListOfPartnersWithParents(Parameters.Partner, PartnerList);
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Partner",
			PartnerList,
			DataCompositionComparisonType.InList,
			,
			True);
		
		List.Parameters.SetParameterValue("DefaultPartner", Parameters.Partner);
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"DefaultPartner",
			Parameters.Partner,
			DataCompositionComparisonType.Equal,
			,
			True);
		
	Else
		
		List.Parameters.SetParameterValue("DefaultPartner", Catalogs.Partners.EmptyRef());
		
	EndIf;
		
	If Parameters.Property("Counterparty") Then
		
		PartnerList = New ValueList;
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Counterparty",
			Parameters.Counterparty,
			DataCompositionComparisonType.Equal
			, 
			True);
		
	EndIf;
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(ThisObject, "Partner", NStr("vi = 'Đối tác';
																												|ru = 'Контрагент';
																												|en = 'Counterparty'; fa = 'طرف حساب';
																												|it = 'Controparte';
																												|pl = 'Counterparty';
																												|tr = 'Cari hesap'"));
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region Private

#Region Other

// The procedure sets the selections passed in the structure. Selections cannot be changed.
//
// Parameters:
//	FilterStructure1 - Structure - Key: name of the data layout field, Value: selection value.
//
&AtServer
Procedure SetUnavailableSelectionsFromParameters(FilterStructure1)
	
	If FilterStructure1.Property("ArticleOwner") Then
		FilterStructure1.Delete("ArticleOwner");
	EndIf;
	
	For Each FilterElement In FilterStructure1 Do
		
		If TypeOf(FilterElement.Value) = Type("ChartOfCharacteristicTypesRef.ExpenseItems")
			Or TypeOf(FilterElement.Value) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
			Continue;
		EndIf;
		
		If FilterElement.Key = "Counterparty" And GetFunctionalOption("UsePartnersAsCounterparties") Then
			
			CommonClientServer.SetDynamicListFilterItem(
				List,
				"Partner",
				Common.ObjectAttributeValue(FilterElement.Value, "Partner"),
				DataCompositionComparisonType.Equal);
			
			Continue;
			
		EndIf;

		CommonClientServer.SetDynamicListFilterItem(
			List,
			FilterElement.Key,
			FilterElement.Value,
			DataCompositionComparisonType.Equal);
	EndDo; 
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion
