
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
	SetParametersForSelectingSellerSOrganization();
	FormItemsManagement();
	
	Items.CompanyCustomer.ReadOnly = ValueIsFilled(Record.CompanyCustomer);
	Items.CompanyOwner.ReadOnly = ValueIsFilled(Record.CompanyOwner);
	Items.InventoryType.ReadOnly          = ValueIsFilled(Record.InventoryType);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	If CallbackDescriptionOnClose <> Undefined Then
		RunCallback(CallbackDescriptionOnClose, Record);
	EndIf;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	CallbackDescriptionOnClose = Undefined;
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TheMethodOfTransferringGoodsWhenChanging(Item)
	
	TheMethodOfTransferringGoodsWhenChangingServer();
	
EndProcedure

&AtClient
Procedure CompanyOwnerOnChange(Item)
	OrganizationOwnerWhenChangedOnServer();
EndProcedure

#EndRegion

#Region Private

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Items.MethodOfTransferOfGoodsTransferToTheCommission.Visible = (Record.InventoryType <> Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	
	Items.Currency.ReadOnly 			  = (Record.GoodsTransferMethod <> Enums.GoodsTransferMethods.TransferToCommissionAgent);
	Items.Currency.MarkIncomplete 	  = (Record.GoodsTransferMethod = Enums.GoodsTransferMethods.TransferToCommissionAgent);
	Items.Currency.AutoMarkIncomplete = (Record.GoodsTransferMethod = Enums.GoodsTransferMethods.TransferToCommissionAgent);
	
	Items.PriceKind.ReadOnly = (Record.GoodsTransferMethod = Enums.GoodsTransferMethods.NotTransferred);
	Items.Contract.ReadOnly = (Record.GoodsTransferMethod = Enums.GoodsTransferMethods.NotTransferred);
	
	If Record.GoodsTransferMethod <> Enums.GoodsTransferMethods.NotTransferred Then
		ParametersArray = New Array;
		
		If Record.GoodsTransferMethod = Enums.GoodsTransferMethods.TransferToCommissionAgent Then
			ContractSelectionParameter = New ChoiceParameter("Filter.ContractType", Enums.TypesOfIntercompanyContracts.Consignment);
		Else
			ContractSelectionParameter = New ChoiceParameter("Filter.ContractType", Enums.TypesOfIntercompanyContracts.PurchaseAndSale);
		EndIf;
		ParametersArray.Add(ContractSelectionParameter);
		
		ContractSelectionParameter = New ChoiceParameter("Filter.DeletionMark", False);
		ParametersArray.Add(ContractSelectionParameter);
		
		ContractSelectionParameter = New ChoiceParameter("Filter.Status", PredefinedValue("Enum.CounterpartyContractStatuses.Valid"));
		ParametersArray.Add(ContractSelectionParameter);
		
		Items.Contract.ChoiceParameters = New FixedArray(ParametersArray); 
	
	EndIf;
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingSellerSOrganization()
	
	ParametersArray = New Array;
	
	If ValueIsFilled(Record.CompanyOwner) Then
	
		ParametersArray.Add(New ChoiceParameter("Filter.LocalAccountingCurrency",
				SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Record.CompanyOwner)));
		ParametersArray.Add(New ChoiceParameter("Filter.RegistrationCountry",
				Common.ObjectAttributeValue(Record.CompanyOwner, "RegistrationCountry")));
		
	EndIf;
	
	Items.CompanyCustomer.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure TheMethodOfTransferringGoodsWhenChangingServer()
	
	If Record.GoodsTransferMethod <> Enums.GoodsTransferMethods.TransferToCommissionAgent Then
		Record.Currency = Undefined;
	EndIf;
	
	If Record.GoodsTransferMethod = Enums.GoodsTransferMethods.NotTransferred Then
		Record.PriceKind = Undefined;
	EndIf;
	
	Record.Contract = Undefined;
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure OrganizationOwnerWhenChangedOnServer()
	SetParametersForSelectingSellerSOrganization();
EndProcedure

#EndRegion

#EndRegion
