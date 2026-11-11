
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ComplAccountingIsUsed = GetFunctionalOption("UseLocal");
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	ThisIsUT = GetFunctionalOption("TradeManagement");

	Items.OffsettingAccount.Visible = False;
	
	If Not LocalizationRFService Or Not ComplAccountingIsUsed Then
		Items.NotIncludedInASTSTaxBase.Visible = False;
	EndIf;
	
	If ThisIsUT Or Not LocalizationRFService Or Not ComplAccountingIsUsed Then
		Items.OffsettingAccount.Visible = True;
		Items.OffsettingAccount.DropListButton = False;
		If LocalizationRFService Then
			
			
			Items.OffsettingAccount.DropListButton = True;
		EndIf;
	EndIf;
	
	If Not AccessRight("Edit", Metadata.Catalogs.CashFlowReportItems) Then
		Items.EditTheBusinessTransactionList.Enabled = False;
	EndIf;
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	BusinessTransactionsDescription = CreateTitleForEditingListOfOperations();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		
		Object.BusinessTransactions.Clear();
		
		For Each ListItem In ValueSelected Do
			Object.BusinessTransactions.Add().BusinessOperation = ListItem.Value;
		EndDo;
		
		BusinessTransactionsDescription = CreateTitleForEditingListOfOperations();
		
		WhenChangingListOfBusinessTransactions();
		
		Modified = True;
		
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure BusinessOperationsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("BusinessTransactionList", New ValueList);
	For Each BusinessTransactionRow In Object.BusinessTransactions Do
		FormParameters.BusinessTransactionList.Add(BusinessTransactionRow.BusinessOperation);
	EndDo;
	
	OpenForm("Catalog.CashFlowReportItems.Form.BusinessTransactionListEditForm",
		FormParameters, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtClient
Function CreateTitleForEditingListOfOperations()

	Result = "";
	For Each BusinessTransactionRow In Object.BusinessTransactions Do
		Result = Result + ?(Result="","","; ") + TrimAll(BusinessTransactionRow.BusinessOperation);
	EndDo;
	
	If IsBlankString(Result) Then
		Result = NStr("vi = '<Chỉ ra giao dịch kinh doanh>';
						|ru = '<Указать хозяйственные операции>';
						|en = '<Specify business transactions>'; fa = '<Specify business transactions>';
						|it = '<Indicare le operazioni commerciali>';
						|pl = '<Wskaż operacje gospodarcze>';
						|tr = '<Ticari işlemleri belirt>'");
	EndIf;
	
	Return Result;

EndFunction

&AtServer
Procedure WhenChangingListOfBusinessTransactions()
	
	FillInTypeOfCashFlow();
	
	If (ThisIsUT Or Not ComplAccountingIsUsed) And LocalizationRFService Then
		Object.OffsettingAccount = "";
		
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTypeOfCashFlow()
	
	For Each LineOfATabularSection In Object.BusinessTransactions Do
		
		TypeOfDDSMovement = Undefined;
		
		If (LineOfATabularSection.BusinessOperation = Enums.BusinessTransactions.SalaryPayment) Then
			TypeOfDDSMovement = Enums.CashFlowKinds.Payroll;
			
		ElsIf (LineOfATabularSection.BusinessOperation = Enums.BusinessTransactions.CashReceiptUnderDeposits)
			Or (LineOfATabularSection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromLoansRepayment)
			Or (LineOfATabularSection.BusinessOperation = Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty)
			Or (LineOfATabularSection.BusinessOperation = Enums.BusinessTransactions.OtherIncome) Then
			TypeOfDDSMovement = Enums.CashFlowKinds.OtherReceiptsFromOperatingActivities;
			
		ElsIf (LineOfATabularSection.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer)
			Or (LineOfATabularSection.BusinessOperation = Enums.BusinessTransactions.CashRecieptFromCustomerByAcquiringTransactions) Then
			TypeOfDDSMovement = Enums.CashFlowKinds.CahsReceiptFromCustomesSales; 
			
		ElsIf (LineOfATabularSection.BusinessOperation = Enums.BusinessTransactions.OtherExpenses) Then
			TypeOfDDSMovement = Enums.CashFlowKinds.OtherPaymentsForCurrentActivities;
			
		EndIf;
		
		If TypeOfDDSMovement <> Undefined Then
			If Not Object.CashFlowKind.IsEmpty()  Then
				If TypeOfDDSMovement <> Object.CashFlowKind Then
					Object.CashFlowKind = Enums.CashFlowKinds.EmptyRef();
					Break;
				EndIf;
			Else
				Object.CashFlowKind = TypeOfDDSMovement;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// PROCEDURES OF THE "PROPERTIES" SUBSYSTEM

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm, FormAttributeToValue("Object"));
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

