
&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.LoanAndDepositInterestCharge.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.LoanAndDepositInterestCharge.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If Object.Patch Then
		Items.AccrualsFill.Visible = False;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If TypeOf(SelectionResult) = Type("Structure") Then
		If SelectionResult.Property("AccrualAddressInTheStorage") Then
			GetAccrualsFromVault(SelectionResult.AccrualAddressInTheStorage);
			Modified = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.LoanAndDepositInterestCharge.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.LoanAndDepositInterestCharge.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_LoanAndDepositInterestCharge", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// The end of the standard subsystem.Managemented
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	ItemsAndDimensionsSelectionParameters = Documents.LoanAndDepositInterestCharge.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	CheckLoanAndDepositAgreement();
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	SetContractSelectionParameters();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccruals

&AtClient
Procedure AccrualsSelection(Item, RowSelected, Field, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	Return;
	
EndProcedure

&AtClient
Procedure AccrualsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		
		CurrentData = Items.Accruals.CurrentData;
		CurrentData.ScheduleAmountType = PredefinedValue("Enum.LoanAndDepositScheduleAmountTypes.Interests");
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.Accruals");
	//Setting up accounting accounts 
	ElsIf NewRow And Copy Then
		
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	CurrentData = Items.Accruals.CurrentData;
	PartnerWhenChangesAreMadeOnServer(CurrentData.Partner, CurrentData.Counterparty);
	
EndProcedure

&AtServerNoContext
Procedure PartnerWhenChangesAreMadeOnServer(Partner, Counterparty)
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer(CachedValues);
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer(CachedValues)
	
	CurrentData = Object.Accruals.FindByID(Items.Accruals.CurrentRow);
	
	Contract = ContractDetails_Server(CurrentData.Contract);
	
	CurrentData.Department = Contract.Department;
	CurrentData.LineOfBusiness = Contract.LineOfBusiness;
	
	If CurrentData.ARAPCurrency <> Contract.ARAPCurrency Then
		CurrentData.ARAPCurrency = Contract.ARAPCurrency;
		CurrentData.AmountARAP = 0;
	EndIf;
	
	If CurrentData.ScheduleAmountType = Enums.LoanAndDepositScheduleAmountTypes.Interests Then
		CurrentData.IncomeAndExpenseItem = Contract.IncomeExpenseItemForInterestAccruals;
	ElsIf CurrentData.ScheduleAmountType = Enums.LoanAndDepositScheduleAmountTypes.Fee Then
		CurrentData.IncomeAndExpenseItem = Contract.IncomeExpenseItemForFeeAccruals;
	EndIf;
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.IncomeAndExpenseItem);
	
EndProcedure

&AtClient
Procedure IncomeAndExpenseItemOnChange(Item)
	
	IncomeAndExpenseItemOnChangeServer();
	
EndProcedure

&AtServer
Procedure IncomeAndExpenseItemOnChangeServer()
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.IncomeAndExpenseItem);
	
EndProcedure

&AtClient
Procedure IncomeAndExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AccrualsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure AccrualsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure AccrualsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure SelectPeriod(Command)
	
	TMCommonUseClient.EditPeriod(Object);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	If CheckSelectionFields() Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("AccrualAddressInTheStorage", AccrualAddressInTheStorage());
		FilterParameters.Insert("Organization", Object.Organization);
		FilterParameters.Insert("Recorder", Object.Ref);
		FilterParameters.Insert("BusinessOperation", Object.BusinessOperation);
		FilterParameters.Insert("StartDate", Object.StartDate);
		FilterParameters.Insert("EndDate", Object.EndDate);
		FilterParameters.Insert("DocumentFormID", UUID);
		
		OpenForm("Document.LoanAndDepositInterestCharge.Form.FormFilling", FilterParameters, ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Function CheckSelectionFields()
	
	Result = True;
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Text = NStr("vi = 'Để điền vào các khoản phí, cần có một chỉ dẫn về giao dịch kinh doanh.';
					|ru = 'Для заполнения начислений требуется указание хозяйственной операции.';
					|en = 'Specify the business transaction to fill in accruals.'; fa = 'Specify the business transaction to fill in accruals.';
					|it = 'Per compilare l''accredito è necessario indicare l''operazione commerciale.';
					|pl = 'Dla wypełnienia naliczeń należy wskazać operację gospodarczą.';
					|tr = 'Tahakkukları doldurmak için ticari işlem göstergesi gereklidir.'");
		CommonClientServer.MessageToUser(Text,, "BusinessOperation", "Object");
		Result = False;
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		Text = NStr("vi = 'Dấu hiệu của doanh nghiệp là cần thiết để điền vào các chi phí.';
					|ru = 'Для заполнения начислений требуется указание организации.';
					|en = 'Specify the company to fill in accruals.'; fa = 'Specify the company to fill in accruals.';
					|it = 'Per compilare la maturazione è necessario indicare l''azienda.';
					|pl = 'Dla wypełnienia naliczeń należy podać firmę.';
					|tr = 'Tahakkukları doldurmak için iş yerinin bir göstergesi gereklidir.'");
		CommonClientServer.MessageToUser(Text,, "Organization", "Object");
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure SetDeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);

EndProcedure
#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IncomeAndExpenseItem.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Accruals.ScheduleAmountType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.LoanAndDepositScheduleAmountTypes.Fee;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Accruals.IncomeAndExpenseItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.IncomeAndExpenseItem.Title = NStr("vi = 'Dạng thu nhập / chi phí';
												|ru = 'Статья доходов / расходов';
												|en = 'Income / expense item'; fa = 'قلم درآمد / هزینه';
												|it = 'Voce di entrate / spese';
												|pl = 'Rodzaj przychodów / kosztów';
												|tr = 'Gelir / gider kalemi'");
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	SetContractSelectionParameters();
	
	ParametersForChoosingDirectionOfActivity = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.LoansInterestCharge Then
		ParametersForChoosingDirectionOfActivity.Add(New ChoiceParameter("Filter.CostAccounting", True));
	Else
		ParametersForChoosingDirectionOfActivity.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
	EndIf;
	
	ParametersForChoosingDirectionOfActivity.Add(New ChoiceParameter("Filter.Status", Enums.LineOfBusinessStatuses.Used));
	
	Items.LineOfBusiness.ChoiceParameters = New FixedArray(ParametersForChoosingDirectionOfActivity);
	
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation( ThisObject, "Partner", Object.BusinessOperation);
	
EndProcedure

&AtServerNoContext
Function ContractDetails_Server(Contract)
	
	Return Common.ObjectAttributesValues(Contract,
		"Partner, Counterparty, ARAPCurrency, IncomeExpenseItemForInterestAccruals, IncomeExpenseItemForFeeAccruals, ContractKind,
		|Department, LineOfBusiness");
	
EndFunction

&AtServer
Procedure SetContractSelectionParameters(Partner = Undefined, Counterparty = Undefined)
	
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark",False));
	ParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ParametersArray.Add(New ChoiceParameter("Filter.ContractKind",
		Catalogs.LoanAndDepositContracts.NatureOfTransactionAgreement(Object.BusinessOperation)));
		
	If Not Object.Organization.IsEmpty() Then
		ParametersArray.Add(New ChoiceParameter("Filter.Organization", Object.Organization));
	EndIf;
	
	If ValueIsFilled(Partner) Then
		ParametersArray.Add(New ChoiceParameter("Filter.Partner", Partner));
	EndIf;
	
	If ValueIsFilled(Counterparty) Then
		ParametersArray.Add(New ChoiceParameter("Filter.Counterparty", Counterparty));
	EndIf;
	
	Items.Contract.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Function AccrualAddressInTheStorage()
	
	Return PutToTempStorage(Object.Accruals.Unload(), UUID);
	
EndFunction

&AtServer
Procedure GetAccrualsFromVault(AccrualAddressInTheStorage)
	
	Object.Accruals.Load(GetFromTempStorage(AccrualAddressInTheStorage));
	
	If Object.Accruals.Count() = 0 Then
		
		OrganizationForPeriod = NStr("vi = 'Đối với doanh nghiệp ""%1"" trong  kỳ từ %2 đến %3';
									|ru = 'Для организации ""%1"" за период с %2 по %3';
									|en = 'For the ""%1"" company for the period from %2 to %3'; fa = 'For the ""%1"" company for the period from %2 to %3';
									|it = 'Per l''azienda ""%1"" nel periodo dal %2 al %3';
									|pl = 'Dla firmy ""%1"" za okres od %2 do %3';
									|tr = '""%1"" iş yeri için dönem içerisinde %2 tarihinde %3 kadar'");
		OrganizationForPeriod = StrTemplate(
			OrganizationForPeriod, Object.Organization, Format(Object.StartDate, "DLF=D"), Format(Object.EndDate, "DLF=D"));
			
		If Object.BusinessOperation = Enums.BusinessTransactions.LoansInterestCharge Then
			ByContracts = NStr("vi = 'không tìm thấy lịch trình trích cho các khoản vay hiện tại và nhận khoản vay';
								|ru = 'по действующим договорам кредитов и полученных займов не обнаружены графики начислений';
								|en = 'accrual schedules were not found for the valid contracts of credits and received loans'; fa = 'accrual schedules were not found for the valid contracts of credits and received loans';
								|it = 'per i contratti di crediti e prestiti ricevuti validi non sono stati trovati i grafici di maturazione';
								|pl = 'według ważnych kontraktów pożyczek i otrzymanych pożyczek nie znaleziono harmonogramów naliczań';
								|tr = 'mevcut kredi sözleşmeleri ve alınan borçlar kapsamında herhangi bir tahakkuk planı bulunamadı'");
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.DepositInterestCharge Then
			ByContracts = NStr("vi = 'không tìm thấy lịch trình trích cho các hợp đồng tiền gửi hiện tại';
								|ru = 'по действующим договорам депозитов не обнаружены графики начислений';
								|en = 'accrual schedules were not found for the valid deposit contracts'; fa = 'accrual schedules were not found for the valid deposit contracts';
								|it = 'per i contratti di deposito validi non sono stati trovati i grafici di maturazione';
								|pl = 'według ważnych kontraktów depozytów nie znaleziono harmonogramów naliczań';
								|tr = 'mevcut mevduat sözleşmeler kapsamında tahakkuk planı bulunamadı'");
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.IssuedBorrowingsInterestCharge Then
			ByContracts = NStr("vi = 'không tìm thấy lịch trình trích cho các khoản vay hiện có';
								|ru = 'по действующим договорам выданных займов не обнаружены графики начислений';
								|en = 'accrual schedules were not found for the valid contracts of issued loans'; fa = 'accrual schedules were not found for the valid contracts of issued loans';
								|it = 'per i contratti dei prestiti rilasciati validi non sono stati trovati i grafici di maturazione';
								|pl = 'według ważnych kontraktów wydanych pożyczek nie znaleziono harmonogramów naliczań';
								|tr = 'verilen borçların mevcut sözleşmelerinde tahakkuk planları bulunamadı'");
		EndIf;
		
		MessageText = OrganizationForPeriod + Chars.LF + ByContracts + ".";
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.LoanAndDepositInterestCharge.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.LoanAndDepositInterestCharge.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
EndProcedure

&AtServer
Procedure CheckLoanAndDepositAgreement()

	ContractKind = Catalogs.LoanAndDepositContracts.NatureOfTransactionAgreement(Object.BusinessOperation);
	AccrualTable = Object.Accruals.Unload();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	AccrualsOfLoansAndDepositsAccruals.Contract AS Contract,
		|	AccrualsOfLoansAndDepositsAccruals.LineNumber AS LineNumber
		|INTO AccrualTable
		|FROM
		|	&Accruals AS AccrualsOfLoansAndDepositsAccruals
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccrualTable.LineNumber AS LineNumber
		|FROM
		|	AccrualTable AS AccrualTable
		|WHERE
		|	AccrualTable.Contract.ContractKind <> &ContractKind";
	
	Query.SetParameter("Accruals", AccrualTable);
	Query.SetParameter("ContractKind", ContractKind);
	
	QueryResult = Query.Execute().Select();
	
	While QueryResult.Next() Do
		
		TableRow =  Object.Accruals.Get(QueryResult.LineNumber - 1);
		TableRow.Contract = Catalogs.LoanAndDepositContracts.EmptyRef();
		
	EndDo;

EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
