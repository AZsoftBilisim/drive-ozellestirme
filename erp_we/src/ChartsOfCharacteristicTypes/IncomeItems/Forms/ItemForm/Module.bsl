
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ThisIsUT = GetFunctionalOption("TradeManagement");
	TransferToFinLeaseIsUsed = False;
	TransferToFinLeaseIsUsed = GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25");
	ComplAccountingIsUsed = GetFunctionalOption("UseLocal");
	LocalizationRFService = GetFunctionalOption("LocalizationRFService");
	Items.OffsettingAccount.Visible = False;
	If ThisIsUT Or Not LocalizationRFService Or Not ComplAccountingIsUsed Then
		Items.OffsettingAccount.Visible = True;
		Items.OffsettingAccount.Mask = DataExchangeEventsTMERP.AccountMask();
		If Not LocalizationRFService Then
			Items.OffsettingAccount.DropListButton = False;
		EndIf;
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
		
	SetFieldVisibility();
	
	If Not GetFunctionalOption("UseLocal") Then
		Items.RegulatedAccountingPage.Visible = False;
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	GLAccountSettingsClient.FinishedSettingUpAccountingAccounts(ThisObject, EventName, Parameter);
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If IsBlankString(ValueType) Then
		MessageText = NStr("vi = 'Tại trường ""Chỉ số thu nhập"" chưa chọn dạng chỉ số nào';
							|ru = 'В поле ""Аналитика доходов"" не выбрано ни одного вида аналитики';
							|en = 'No dimension kind is selected in the ""Income dimension"" field'; fa = 'No dimension kind is selected in the ""Income dimension"" field';
							|it = 'Nel campo ""Analitica delle entrate"" non è indicato nemmeno un tipo di analitica';
							|pl = 'W polu ""Analityka dochodów"" nie wybrano żadnego rodzaju analityki';
							|tr = '""Gelir boyutu"" alanında herhangi bir boyut türü seçilmemiş'");
		CommonClientServer.MessageToUser(
			MessageText,
			, // ObjectOrRef
			"ValueType",
			, // DataPath
			Cancel);
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core	
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ValueTypeOnChange(Item)
	
	If Not IsBlankString(ValueType) Then
		Object.ValueType = New TypeDescription(ValueType);
	EndIf;
	If ValueType = "CatalogRef.Assets"
		Or ValueType = "CatalogRef.IntangibleAssets" Then
		Object.ControlDimensionFilling = True;
		Items.ControlDimensionFilling.Enabled = TransferToFinLeaseIsUsed;
	Else
		Items.ControlDimensionFilling.Enabled = True;
	EndIf;
	Return; // The handler is only used in UT
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingLocalizationAttribute(Item)
	
	IncomeItemsClientLocalization.OnChangeAttribute(Item.Name, ThisForm);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, Var_Parameters = Undefined) Export
	
	If Var_Parameters.ServerCallRequired_ Then
		AtEndOfChangingLocalizationLimitOnServer(TagName);
	EndIf;
	
EndProcedure

&AtServer
Procedure AtEndOfChangingLocalizationLimitOnServer(TagName)
	
	IncomeItemsLocalization.OnChangeAttribute(TagName, ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// Procedure-handler for executing the command.
//
// Parameters:
//	Command - FormCommand - form command.
//
&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	IncomeItemsClientLocalization.ExecuteCommand(Command.Name, ThisForm);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, Var_Parameters) Export
	
	If Var_Parameters.ServerCallRequired_ Then
		RunLocalizationCommandOnServer(CommandName);
	EndIf;
	
EndProcedure

&AtServer
Procedure RunLocalizationCommandOnServer(CommandName)
	
	IncomeItemsLocalization.ExecuteCommand(CommandName, ThisForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

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

#Region FormItemsManagement

&AtServer
Procedure SetVisibilityOfAnalyticsValueTypes()
	
	ArrayOfExcludedTypes = New Array;
	
	If Not GetFunctionalOption("UsePurchaseOrders") Then
		ArrayOfExcludedTypes.Add("DocumentRef.PurchaseOrder");
	EndIf;
	
	If Not GetFunctionalOption("GenerateFinancialResult") Then
		ArrayOfExcludedTypes.Add("CatalogRef.LinesOfBusiness");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		ArrayOfExcludedTypes.Add("EnumRef.ExchangeDifferencesDimension");
	EndIf;
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		ArrayOfExcludedTypes.Add("CatalogRef.BusinessStructure");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		ArrayOfExcludedTypes.Add("CatalogRef.Companies");
	EndIf;
	
	If Not GetFunctionalOption("UseLoanAndDepositContracts") Then
		ArrayOfExcludedTypes.Add("CatalogRef.LoanAndDepositContracts");
	EndIf;
	
	For Each TypeToExclude In ArrayOfExcludedTypes Do
		ListItem = Items.ValueType.ChoiceList.FindByValue(TypeToExclude);
		If ListItem <> Undefined And ValueType <> TypeToExclude Then
			Items.ValueType.ChoiceList.Delete(ListItem);
		EndIf;
	EndDo;
		
EndProcedure

&AtServer
Procedure SetFieldVisibility()

	If Object.Ref = ChartsOfCharacteristicTypes.IncomeItems.SalesRevenue Then
		Items.LineOfBusinessAllocationMethod.Visible = False;
	EndIf;
	IncomeOnAssets = (ValueType = "CatalogRef.Assets")
				  Or (ValueType = "CatalogRef.IntangibleAssets");
	
	Items.ControlDimensionFilling.Enabled = Not IncomeOnAssets Or TransferToFinLeaseIsUsed;
EndProcedure

#EndRegion

#Region Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	IncomeItemsLocalization.OnReadCreateAtServer(ThisObject);
	FillInListOfTypesOfRevenueAnalytics();
	SetValueType();
	If Not NonCurrentAssets.VNAManagementIsUsed() Then
		List = Items.ValueType.ChoiceList;
		List.Delete(List.FindByValue("CatalogRef.Assets"));
		List.Delete(List.FindByValue("CatalogRef.IntangibleAssets"));
	EndIf;
EndProcedure

&AtServer
Procedure SetValueType()

	ListOfValueTypes = New ValueList;
	ListOfValueTypes.Add("CatalogRef.Companies");
	ListOfValueTypes.Add("CatalogRef.BusinessStructure");
	ListOfValueTypes.Add("CatalogRef.LinesOfBusiness");
	ListOfValueTypes.Add("CatalogRef.Partners");
	ListOfValueTypes.Add("DocumentRef.PurchaseOrder");
	ListOfValueTypes.Add("CatalogRef.LoanAndDepositContracts");
	ListOfValueTypes.Add("EnumRef.ExchangeDifferencesDimension");
	ListOfValueTypes.Add("CatalogRef.Assets");
	ListOfValueTypes.Add("CatalogRef.IntangibleAssets");
	ListOfValueTypes.Add("CatalogRef.Products");

	For Each ListItem In ListOfValueTypes Do
		If Object.ValueType.ContainsType(Type(ListItem.Value)) Then
			ValueType = ListItem.Value;
			Break;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure FillInListOfTypesOfRevenueAnalytics()
	
	ChoiceList = Items.ValueType.ChoiceList;
	ChoiceList.Clear();
	
	ChoiceList.Add("CatalogRef.Companies", 				NStr("vi = 'Doanh nghiệp';
																|ru = 'Организация';
																|en = 'Company'; fa = 'Company';
																|it = 'Azienda';
																|pl = 'Organizacja';
																|tr = 'İş yeri'"));
	ChoiceList.Add("CatalogRef.BusinessStructure", 		NStr("vi = 'Bộ phận';
																|ru = 'Подразделение';
																|en = 'Business unit'; fa = 'Business unit';
																|it = 'Reparto';
																|pl = 'Dział';
																|tr = 'Departman'"));
	ChoiceList.Add("CatalogRef.LinesOfBusiness", 	NStr("vi = 'Lĩnh vực hoạt động';
															|ru = 'Направление деятельности';
															|en = 'Line of business'; fa = 'خط کسب‌وکار';
															|it = 'Settore di attività';
															|pl = 'Rodzaj działalności';
															|tr = 'İş kolu'"));
	ChoiceList.Add("CatalogRef.Partners",					NStr("vi = 'Nhà cung cấp';
																	|ru = 'Поставщик';
																	|en = 'Vendor'; fa = 'تأمین‌کننده';
																	|it = 'Fornitore';
																	|pl = 'Vendor';
																	|tr = 'Tedarikçi'"));
	ChoiceList.Add("DocumentRef.PurchaseOrder", 			NStr("vi = 'Đơn hàng đặt nhà cung cấp';
																|ru = 'Заказ поставщику';
																|en = 'Purchase order'; fa = 'سفارش خرید';
																|it = 'Ordine al fornitore';
																|pl = 'Zamówienie do dostawcy';
																|tr = 'Satın alma siparişi'"));
	ChoiceList.Add("CatalogRef.LoanAndDepositContracts",NStr("vi = 'Hợp đồng đi vay (tiền gửi)';
															|ru = 'Договор кредита (депозита)';
															|en = 'Loan (deposit) contract'; fa = 'قرارداد وام (سپرده)';
															|it = 'Contratto di credito (deposito)';
															|pl = 'Umowa pożyczki (lokaty)';
															|tr = 'Kredi (mevduat) sözleşmesi'"));
	ChoiceList.Add("EnumRef.ExchangeDifferencesDimension", NStr("vi = 'Dạng chênh lệch tỷ giá';
																|ru = 'Виды курсовых разниц';
																|en = 'Exchange difference types'; fa = 'Exchange difference types';
																|it = 'Tipi delle differenze di cambio';
																|pl = 'Rodzaje różnic kursowych';
																|tr = 'Kur farkları türleri'"));
	ChoiceList.Add("CatalogRef.Assets", 		NStr("vi = 'Tài sản đang vận hành';
													|ru = 'Объекты эксплуатации';
													|en = 'Asset'; fa = 'دارایی';
													|it = 'Oggetti in uso';
													|pl = 'Obiekty eksploatacji';
													|tr = 'İşlem nesneleri'"));
	ChoiceList.Add("CatalogRef.IntangibleAssets", 		NStr("vi = 'TSCĐ vô hình / Chi phí nghiên cứu, triển khai';
																|ru = 'НМА / НИОКР';
																|en = 'Intangible asset / R&&D'; fa = 'Intangible asset / R&&D';
																|it = 'Beni immateriali/Ricerca e sviluppo';
																|pl = 'Aktywa niematerialne / prace naukowo-badawcze i doświadczalno-konstrukcyjne';
																|tr = 'MOG / Ar-Ge'"));
	ChoiceList.Add("CatalogRef.Products", 				NStr("vi = 'Mặt hàng';
																|ru = 'Номенклатура';
																|en = 'Item'; fa = 'قلم';
																|it = 'Articolo';
																|pl = 'Item';
																|tr = 'Öğe'"));
	
	SetVisibilityOfAnalyticsValueTypes();
	
EndProcedure

#EndRegion

#EndRegion
