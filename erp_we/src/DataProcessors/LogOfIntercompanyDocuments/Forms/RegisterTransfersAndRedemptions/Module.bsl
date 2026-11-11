
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
		
	RestoreSettings(Parameters);
	
	CustomizeForm(Parameters);
	
	If RegisteredDocuments = "OnlyTransfers" Then
		URL = "e1cib/command/DataProcessor.LogOfIntercompanyDocuments.Command.TransfersToRegister";
	Else
		URL = "e1cib/command/CommonCommand.RedemptionsOfGoodsToRegister";
	EndIf;
	
	HeaderFields = New FixedStructure(InventoriesServer.FieldsInHeaderForRegistrationByOrganizationSProductReserves());
	
	Items.DecorationThereAreExtraReserves.Visible          = False;	
	Items.DecorationThereIsAnErrorTransferringReserves.Visible = False;	
	Items.TheDecorationOfTheTransferForm.Visible           = False;
	
	If Not AccessRight("Insert", Metadata.Documents.CustomerInvoiceIntercompany) Then
		Items.TheDecorationOfTheTransferForm.Title = String(Items.TheDecorationOfTheTransferForm.Title);
	EndIf;
		
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_CustomerInvoiceIntercompany"
		Or EventName = "Write_RedemptionOfGoodsFromStorage"
		Then
		
		RequirementsForRegistrationForPeriod();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RequirementsForRegistrationForPeriod();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOnChange(Item)
	
	ClearMessages();
	
	Period.StartDate		= BegOfMonth(Period.StartDate);
	Period.EndDate	= ?(ValueIsFilled(Period.EndDate),
								EndOfMonth(Period.EndDate),
								Period.EndDate);
	
	If Period.StartDate > Period.EndDate
		And ValueIsFilled(Period.EndDate) Then
		
		MessageText = NStr("vi = 'Ngày bắt đầu Kỳ không thể dài hơn ngày kết thúc';
							|ru = 'Дата начала периода не может быть больше даты окончания периода';
							|en = 'The period start date cannot be greater than the period end date'; fa = 'The period start date cannot be greater than the period end date';
							|it = 'La data di inizio periodo non può essere superiore alla data del termine periodo';
							|pl = 'Data rozpoczęcia okresu nie może być dłuższa niż data zakończenia okresu';
							|tr = 'Dönemin başlangıç tarihi, dönemin bitiş tarihinden büyük olamaz'");
		
		CommonClient.MessageToUser(MessageText, , "Period");
		
		Period.EndDate = EndOfMonth(Period.StartDate);
		
	EndIf;
	
	RequirementsForRegistrationForPeriod();
	
EndProcedure

&AtClient
Procedure SenderOnChange(Item)
	
	RequirementsForRegistrationForPeriod();
	
EndProcedure

&AtClient
Procedure RecipientOnChange(Item)
	
	RequirementsForRegistrationForPeriod();
	
EndProcedure

&AtClient
Procedure StorageLocationOnChange(Item)
	
	RequirementsForRegistrationForPeriod();
	
EndProcedure

&AtClient
Procedure StorageLocationStartChoice(Item, ChoiceData, StandardProcessing)
	
	If StorageLocation = Undefined
		And RegisteredDocuments = "RansomsOnly" Then
		
		StandardProcessing = False;
		
		ChoiceList = New ValueList();
		ChoiceList.Add(PredefinedValue("Catalog.Warehouses.EmptyRef"), NStr("vi = 'Kho bãi';
																			|ru = 'Склад (складская территория)';
																			|en = 'Warehouse (warehouse area)'; fa = 'انبار (ناحیه انبار)';
																			|it = 'Magazzino (area di stoccaggio)';
																			|pl = 'Magazyn (powierzchnia magazynowa)';
																			|tr = 'Ambar (ambar alanı)'"));
		ChoiceList.Add(PredefinedValue("Catalog.BusinessStructure.EmptyRef"), NStr("vi = 'Bộ phận';
																					|ru = 'Подразделение';
																					|en = 'Business unit'; fa = 'Business unit';
																					|it = 'Reparto';
																					|pl = 'Business unit';
																					|tr = 'Departman'"));
		ChoiceList.Add(PredefinedValue("Catalog.CounterpartyContracts.EmptyRef"), NStr("vi = 'Hợp đồng đối tác';
																						|ru = 'Договоры контрагентов';
																						|en = 'Counterparty contracts'; fa = 'قراردادهای طرف حساب';
																						|it = 'Contratti delle controparti';
																						|pl = 'Kontrakty kontrahentów';
																						|tr = 'Cari hesap sözleşmeleri'"));
		
		CallbackDescriptionOnClose = New CallbackDescription(
			"AfterSelectingTypeOfStorageLocation",
			ThisForm);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("ValuesForSelection", ChoiceList);
		OpeningParameters.Insert("Title", NStr("vi = 'Chọn kiểu dữ liệu';
												|ru = 'Выбор типа данных';
												|en = 'Select data type'; fa = 'Select data type';
												|it = 'Scelta del tipo dati';
												|pl = 'Wybierz typ danych';
												|tr = 'Veri türünü seçin'"));
		
		OpenForm(
			"CommonForm.SelectValue",
			OpeningParameters,
			ThisForm,
			New UUID(),
			,
			,
			CallbackDescriptionOnClose,
			FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	EndIf;
	
	If TypeOf(StorageLocation) = Type("CatalogRef.Warehouses") Then
		StandardProcessing = False;
		OpenWarehouseSelectionForm();
	ElsIf TypeOf(StorageLocation) = Type("CatalogRef.BusinessStructure") Then
		StandardProcessing = False;
		OpenDivisionSelectionForm();
	ElsIf TypeOf(StorageLocation) = Type("CatalogRef.CounterpartyContracts") Then
		StandardProcessing = False;
		OpenContractSelectionForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterSelectingTypeOfStorageLocation(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedStorageLocation = Result;
	
	If TypeOf(SelectedStorageLocation) = Type("CatalogRef.Warehouses") Then
		OpenWarehouseSelectionForm();
	ElsIf TypeOf(SelectedStorageLocation) = Type("CatalogRef.BusinessStructure") Then
		OpenDivisionSelectionForm();
	ElsIf TypeOf(SelectedStorageLocation) = Type("CatalogRef.CounterpartyContracts") Then
		OpenContractSelectionForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenWarehouseSelectionForm()
	
	OpenForm("Catalog.Warehouses.Form.ChoiceForm",
		,
		Items.StorageLocation,
		Items.StorageLocation);
	
EndProcedure

&AtClient
Procedure OpenDivisionSelectionForm()
	
	OpenForm("Catalog.BusinessStructure.Form.ChoiceForm",
		,
		Items.StorageLocation,
		Items.StorageLocation);
	
EndProcedure

&AtClient
Procedure OpenContractSelectionForm()
	
	FilterStructure1 = New Structure();
	StructureOfSelectionParameters = New Structure();
	If PurposeUseKey = "PurchaseDocumentsAll"
		Or PurposeUseKey = "MonthEndTransactions" Then
		FilterStructure1.Insert(
			"BusinessOperation",
			PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale"));
	EndIf;
	
	If PurposeUseKey = "DocumentsOfAcceptanceForProcessing"
		Or PurposeUseKey = "MonthEndTransactions" Then
		FilterStructure1.Insert(
			"BusinessOperation",
			TollingSchemeClientServer.ContractBusinessTransaction());
	EndIf;
	StructureOfSelectionParameters.Insert("Filter", FilterStructure1);
	OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm",
		StructureOfSelectionParameters,
		Items.StorageLocation,
		Items.StorageLocation);
	
EndProcedure

&AtClient
Procedure DecorationThereIsAnErrorTransferringReservesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ShouldNotRunInBackground", True);
	FilterParameters.Insert("StartDate", TransferStartTime);
	FilterParameters.Insert("EventLogEvent", NameOfReserveTransferEvent());
	EventLogClient.OpenEventLog(FilterParameters);

EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	HandlingNavigationLinkSeeAlsoGo(FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure LinkGoToURLProcessing(Item, FormattedStringURL, StandardProcessing)
	HandlingNavigationLinkSeeAlsoGo(FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure TheDecorationOfTheTransferFormURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	TransferFormParameters = New Structure;
	TransferFormParameters.Insert("PurposeUseKey", "DocumentsBetweenCompaniesAll");
	
	ListFormSelections = New Structure;
	ListFormSelections.Insert("Organization", Recipient);
	ListFormSelections.Insert("StorageLocation", StorageLocation);
	
	TransferFormParameters.Insert("ListFormSelections", ListFormSelections);
	
	OpenForm("DataProcessor.LogOfIntercompanyDocuments.Form.RegisterTransfersAndRedemptions",
				TransferFormParameters,
				,
				"DocumentsBetweenCompaniesAll");
	
EndProcedure

&AtClient
Procedure DecorationThereAreExtraReservesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	TransferReserves_();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueADocumentForThePeriod(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
	"DataProcessor.LogOfIntercompanyDocuments.RegisterTransfersAndRedemptions.Command.IssueADocumentForThePeriod");
	
	String = Items.ToRegisterForAPeriod.CurrentData;
	
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(
		String, LogParameters()) Then
		Return;
	EndIf;
	
	If String <> Undefined Then
		
		HeaderFieldStructure = New Structure(HeaderFields);
		
		FillPropertyValues(HeaderFieldStructure, String);
		
		If RegisteredDocuments = "OnlyTransfers" Then
			NameOfOpeningForm = "Document.CustomerInvoiceIntercompany.ObjectForm";
		Else
			NameOfOpeningForm = "Document.RedemptionOfGoodsFromStorage.ObjectForm";
		EndIf;
		
		Basis = New Structure;
		Basis.Insert("HeaderFields", HeaderFieldStructure);
		Basis.Insert("FillInByOrganizationSProductReserves");
		
		ParametersStructure1 = New Structure("Basis", Basis);
		
		OpenForm(NameOfOpeningForm, ParametersStructure1, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	RequirementsForRegistrationForPeriod();
	
EndProcedure

&AtClient
Procedure CollapseReserves(Command)
	
	CollapseReservesServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersToRegisterForAPeriod

&AtClient
Procedure ToRegisterForAPeriodBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region Private

#Region TransferReserves_

&AtClient
Procedure TransferReserves_()		
	
	Items.DecorationThereAreExtraReserves.Visible = False;
	
	BackgroundJob = TransferReserves_Server();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("AfterFillingInForRegistrationForPeriod", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function TransferReserves_Server()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Chuyển dự trữ hàng hóa của doanh nghiệp';
																	|ru = 'Перенос резервов товаров организаций';
																	|en = 'Transfer company goods reserves'; fa = 'Transfer company goods reserves';
																	|it = 'Trasferimento delle scorte di merci delle società';
																	|pl = 'Przenoszenie rezerw towarów firm';
																	|tr = 'İş yerlerinin ürün yedeklerinin aktarılması'");
	BackgroundExecutionParameters.RunInBackground = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.LogOfIntercompanyDocuments.AllocateReservesByPeriod",
		ParametersForFillingInFormForPeriod(), BackgroundExecutionParameters);
		
	TransferStartTime = CurrentSessionDate();
		
	Return BackgroundJob;
	
EndFunction

#EndRegion


#Region RequirementsForRegistrationForPeriod

&AtClient
Procedure RequirementsForRegistrationForPeriod()		
	
	Items.DecorationThereAreExtraReserves.Visible = False;
	Items.DecorationThereIsAnErrorTransferringReserves.Visible = False;
	
	BackgroundJob = RequirementsForRegistrationForPeriodServer();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("AfterFillingInForRegistrationForPeriod", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function RequirementsForRegistrationForPeriodServer()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Chuyển dự trữ hàng hóa của doanh nghiệp';
																	|ru = 'Перенос резервов товаров организаций';
																	|en = 'Transfer company goods reserves'; fa = 'Transfer company goods reserves';
																	|it = 'Trasferimento delle scorte di merci delle società';
																	|pl = 'Przenoszenie rezerw towarów firm';
																	|tr = 'İş yerlerinin ürün yedeklerinin aktarılması'");
	
	TransferStartTime = CurrentSessionDate();
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.LogOfIntercompanyDocuments.RequirementsForRegistrationForPeriod",
		ParametersForFillingInFormForPeriod(), BackgroundExecutionParameters);
		
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterFillingInForRegistrationForPeriod(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
	
		If IsTempStorageURL(BackgroundJob.ResultAddress) Then
			UploadToRegistrationForPeriod(BackgroundJob.ResultAddress);
		EndIf;
		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành nhiệm vụ do: %Cause%';
									|ru = 'Не удалось закончить выполнения задания по причине: %Cause%';
									|en = 'Cannot complete job. Reason: %Cause%'; fa = 'Cannot complete job. Reason: %Cause%';
									|it = 'Non è stato possibile completare il task a causa di: %Cause%';
									|pl = 'Nie udało się ukończyć zadanie z powodu: %Cause%';
									|tr = '%Cause% nedeniyle görev tamamlanamadı'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
		ToRegisterForAPeriod.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure UploadToRegistrationForPeriod(AddressInTempStorage)
	
	Result = GetFromTempStorage(AddressInTempStorage); 
	
	If Result.ToRegisterForAPeriod <> Undefined Then  
		ToRegisterForAPeriod.Load(Result.ToRegisterForAPeriod);
	Else
		ToRegisterForAPeriod.Clear();
	EndIf;
	
	Items.DecorationThereAreExtraReserves.Visible          = Result.ExcessReserves = "ThereAreExtraReserves";	
	Items.DecorationThereIsAnErrorTransferringReserves.Visible = Result.ExcessReserves = "Error";	
	Items.TheDecorationOfTheTransferForm.Visible           = Result.ThereAreGoodsForRegistrationOfTransfersBeforeRedemption;
	
EndProcedure

// The constructor function parameters
// 
// Returns:
// 	Structure - Where:
// * StorageLocation - CatalogRef.CounterpartyContracts, CatalogRef.BusinessStructure, CatalogRef.Warehouses - 
// * Recipient - CatalogRef.Companies
// * Sender - CatalogRef.Companies, CatalogRef.Partners - 
// * Period - StandardPeriod
// * IssueRansoms - Boolean
// * MakeTransfers - Boolean
&AtServer
Function ParametersForFillingInFormForPeriod()
	
	FillParameters = New Structure;
	
	FillParameters.Insert("MakeTransfers", RegisteredDocuments = "OnlyTransfers"); 
	FillParameters.Insert("IssueRansoms",   RegisteredDocuments = "RansomsOnly"); 
	FillParameters.Insert("Period",            Period);
	FillParameters.Insert("Sender",       Sender);
	FillParameters.Insert("Recipient",        Recipient);
	FillParameters.Insert("StorageLocation",     StorageLocation);
	FillParameters.Insert("TypesOfRedemptionStocks", New Array);
	If FillParameters.IssueRansoms Then
		If PurposeUseKey = "PurchaseDocumentsAll"
			Or PurposeUseKey = "MonthEndTransactions" Then
			FillParameters.TypesOfRedemptionStocks.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
		EndIf;
		If PurposeUseKey = "DocumentsOfAcceptanceForProcessing"
			Or PurposeUseKey = "MonthEndTransactions" Then
			FillParameters.TypesOfRedemptionStocks.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
			FillParameters.TypesOfRedemptionStocks.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
			FillParameters.TypesOfRedemptionStocks.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
		EndIf;
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ToRegisterForAPeriod.Period",
		"ToRegisterForAPeriodPeriod");
	
EndProcedure

&AtClient
Procedure HandlingNavigationLinkSeeAlsoGo(FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	ListFormSelections = New Structure;
	ListFormSelections.Insert("StorageLocation", StorageLocation);
	
	LogParameters = New Structure;
	
	If RegisteredDocuments = "OnlyTransfers" Then
		ListFormSelections.Insert("Organization", Sender);
		
		LogParameters.Insert("PurposeUseKey", "CustomerInvoiceIntercompany");
	ElsIf PurposeUseKey = "MonthEndTransactions" Then
		ListFormSelections.Insert("Organization", Recipient);
		LogParameters.Insert("PurposeUseKey", PurposeUseKey);
	Else
		ListFormSelections.Insert("Organization", Recipient);
		LogParameters.Insert("PurposeUseKey", "RedemptionOfGoodsFromStorage");
	EndIf;
	
	LogParameters.Insert("QuickFilterStructure", ListFormSelections);
	
	OpenForm(FormattedStringURL, LogParameters);
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "DocumentsBetweenCompaniesAll";
	
EndFunction

&AtServer
Procedure RestoreSettings(Var_Parameters)
	If Var_Parameters.Property("PurposeUseKey")
		And ValueIsFilled(Var_Parameters.PurposeUseKey) Then
		
		PurposeUseKey = Var_Parameters.PurposeUseKey;
		
	Else
		PurposeUseKey = DefaultFormAssignmentKey();
	EndIf;
	
	RegistrationOfTransfers = PurposeUseKey = DefaultFormAssignmentKey();
	
	If Var_Parameters.Property("RegistrationPeriod") Then
		FormIsOpenedByHyperlink = True;
		
		If RegistrationOfTransfers Then
			Recipient  = Var_Parameters.Organization;
			Sender = Var_Parameters.Organization;
		Else
			Recipient = Var_Parameters.Organization;
		EndIf;
		
		StartDate     = BegOfMonth(Var_Parameters.RegistrationPeriod);
		EndeDate = EndOfMonth(Var_Parameters.RegistrationPeriod);
		
		Period.StartDate    = StartDate;
		Period.EndDate = EndeDate;
		
	ElsIf Var_Parameters.Property("ListFormSelections") Then
		
		FormIsOpenedByHyperlink = True;
		ListFormSelections = Var_Parameters.ListFormSelections;
		
		If RegistrationOfTransfers Then
			Sender = ListFormSelections.Organization;
		Else
			Recipient = ListFormSelections.Organization;
		EndIf;
		
		If ListFormSelections.Property("Warehouse") Then
			StorageLocation = ListFormSelections.Warehouse;
		Else
			StorageLocation = ListFormSelections.StorageLocation;
		EndIf;
		
	ElsIf Var_Parameters.Property("QuickFilterStructure") Then
		
		FormIsOpenedByHyperlink = True;
		ListFormSelections = Var_Parameters.QuickFilterStructure;
		
		If RegistrationOfTransfers Then
			Sender = ListFormSelections.Organization;
		Else
			Recipient = ListFormSelections.Organization;
		EndIf;
		
		If ListFormSelections.Property("Warehouse") Then
			StorageLocation = ListFormSelections.Warehouse;
		Else
			StorageLocation = ListFormSelections.StorageLocation;
		EndIf;
		
	Else
		
		FormIsOpenedByHyperlink = False;
		
		ObjectKey = "DataProcessor.LogOfIntercompanyDocuments.Form.RegisterTransfersAndRedemptions";
		Settings   = Common.CommonSettingsStorageLoad(ObjectKey, PurposeUseKey); // See ParametersForFillingInFormForPeriod
		
		If Settings <> Undefined Then
			Period               = Settings.Period;
			Sender          = Settings.Sender;
			Recipient           = Settings.Recipient;
			RegisteredDocuments = Settings.RegisteredDocuments;
			If Settings.Property("StorageLocation") Then
				StorageLocation    = Settings.StorageLocation;
			ElsIf Settings.Property("Warehouse") Then
				StorageLocation    = Settings.Warehouse;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(RegisteredDocuments) Then
		RegisteredDocuments = ?(RegistrationOfTransfers, "OnlyTransfers", "RansomsOnly");
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeForm(Var_Parameters)
	
	GenerationParameters = New Structure;
	
	ArrayCalculationManagersSeeAlsoInWork = New Array();
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	
	If RegisteredDocuments = "OnlyTransfers" Then
		
		Title = NStr("vi = 'Chuyển hàng lập chứng từ';
					|ru = 'Передачи товаров к оформлению';
					|en = 'Intercompany invoices to register'; fa = 'Intercompany invoices to register';
					|it = 'Consegne di merci per la formalizzazione';
					|pl = 'Przekazanie towarów do rejestracji';
					|tr = 'Düzenlenme için ürünlerin transferi'");
		
		Sender = ?(ValueIsFilled(Sender), Sender, Catalogs.Companies.EmptyRef());
		StorageLocation = ?(ValueIsFilled(StorageLocation), StorageLocation, Catalogs.Warehouses.EmptyRef());
		
		Items.StorageLocation.ChooseType = False;
		                                
		Items.StorageLocation.Visible                         = UseSeveralWarehouses;
		Items.ToRegisterForAPeriodStorageLocation.Visible      = UseSeveralWarehouses;
		Items.ToRegisterForAPeriodCounterparty.Visible = False;
		Items.ToRegisterForAPeriodVATTaxation.Visible = True;
		
		GenerationParameters.Insert("PurposeUseKey", "CustomerInvoiceIntercompany");
		ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.LogOfIntercompanyDocuments");
		
	Else
		
		Title = NStr("vi = 'Mua lại hàng hóa để lập chứng từ';
					|ru = 'Выкупы товаров к оформлению';
					|en = 'Purchases invoices — VMI to register'; fa = 'Purchases invoices — VMI to register';
					|it = 'I riscatti di merci per la formalizzazione';
					|pl = 'Wykup towarów do rejestracji';
					|tr = 'Düzenlenme için ürünlerin itfa edilmesi'");
		
		Sender = ?(ValueIsFilled(Sender), Sender, Catalogs.Partners.EmptyRef());
		
		ChoiceParameter = New ChoiceParameter("Filter.Vendor", True);
		ParametersArray = New Array;
		ParametersArray.Add(ChoiceParameter);
		
		Items.Sender.ChoiceParameters = New FixedArray(ParametersArray);
		
		SenderHeader = NStr("vi = 'Bên gửi hàng';
							|ru = 'Поклажедатель';
							|en = 'Depositor'; fa = 'امانت‌گذار';
							|it = 'Depositante';
							|pl = 'Depozytariusz';
							|tr = 'Kefil'");
		If PurposeUseKey = "DocumentsOfAcceptanceForProcessing" Then
			SenderHeader = NStr("vi = 'Bên đặt gia công';
								|ru = 'Давалец';
								|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
								|it = 'Fornitore';
								|pl = 'Właściciel surowców';
								|tr = 'Malzeme tedarikçisi'");
		EndIf;
		Items.Sender.Title                    = SenderHeader;
		Items.ToRegisterForAPeriodSender.Title = SenderHeader;
		
		HeaderRecipient = NStr("vi = 'Doanh nghiệp';
								|ru = 'Организация';
								|en = 'Company'; fa = 'Company';
								|it = 'Azienda';
								|pl = 'Firma';
								|tr = 'İş yeri'");
		Items.Recipient.Title                    = HeaderRecipient;
		Items.ToRegisterForAPeriodRecipient.Title = HeaderRecipient;
		
		WarehouseTitle = NStr("vi = 'Nơi cất giữ';
								|ru = 'Место хранения';
								|en = 'Warehouse'; fa = 'Warehouse';
								|it = 'Luogo di stoccaggio';
								|pl = 'Miejsce przechowywania';
								|tr = 'Saklama yeri'");
		Items.StorageLocation.Title                    = WarehouseTitle;
		Items.ToRegisterForAPeriodStorageLocation.Title = WarehouseTitle;
		
		Items.ToRegisterForAPeriodCounterparty.Visible         = True;
		Items.ToRegisterForAPeriodVATTaxation.Visible = False;
		
		GenerationParameters.Insert("PurposeUseKey", "RedemptionOfGoodsFromStorage");
		If PurposeUseKey = "DocumentsOfAcceptanceForProcessing" Then
			ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.DocumentsOfReceiptForTollingAll2_5");
		Else
			ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.LogOfPurchaseDocuments");
		EndIf;
	EndIf;
	
	SeeAlsoInProgress = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters);
	Items.SeeAlsoInProgress.Visible = ValueIsFilled(SeeAlsoInProgress);
	
	ArrayCalculationManagersSeeAlsoInWork = New Array;
	ArrayCalculationManagersSeeAlsoInWork.Add("DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption");
	
	LinkGoTo = TMCommonUse.CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters, NStr("vi = 'Chuyển đến:';
																														|ru = 'Перейти:';
																														|en = 'Go to:'; fa = 'Go to:';
																														|it = 'Passare:';
																														|pl = 'Przejdź:';
																														|tr = 'Git:'")); 
	Items.LinkGoTo.Visible = ValueIsFilled(LinkGoTo);
	
	Items.ToTheDesignByMonthsToRollReserves.Visible = TMCommonUse.DebugMode();
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	If FormIsOpenedByHyperlink Then
		Return;
	EndIf;
	
	ObjectKey = "DataProcessor.LogOfIntercompanyDocuments.Form.RegisterTransfersAndRedemptions";
	AttributesToSaveNames = "Period,Sender,Recipient,StorageLocation,RegisteredDocuments";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave(ObjectKey, PurposeUseKey, Settings);
	
EndProcedure

&AtServer
Procedure CollapseReservesServer()
	
	AccumulationRegisters.CompanySafeStock.CollapseRegisterReservesOfGoodsOfOrganizations();
	
EndProcedure

&AtServerNoContext
Function NameOfReserveTransferEvent()
	
	Return AccumulationRegisters.CompanySafeStock.NameOfReserveTransferEvent();
	
EndFunction

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",   Recipient);
	QuickFilterStructure.Insert("StorageLocation", StorageLocation);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",	QuickFilterStructure);
	LogParameters.Insert("WorkplaceName",			"LogOfIntercompanyDocuments");
	LogParameters.Insert("FormAssignmentKey",		PurposeUseKey);
	LogParameters.Insert("JournalSynonym", NStr("vi = 'Chứng từ giữa các doanh nghiệp';
												|ru = 'Документы между организациями';
												|en = 'Documents between companies'; fa = 'Documents between companies';
												|it = 'Documenti tra organizzazioni';
												|pl = 'Dokumenty międzyfirmowe';
												|tr = 'İş yerleri arasındaki belgeler'"));
	
	Return LogParameters;
	
EndFunction

#EndRegion
