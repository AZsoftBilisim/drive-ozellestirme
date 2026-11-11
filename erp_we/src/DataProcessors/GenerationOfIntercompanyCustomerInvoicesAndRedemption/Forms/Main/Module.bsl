
&AtClient
Var TimeConsumingOperationForm;

&AtClient
Var IdleHandlerParameters;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseIntercompanyContracts = GetFunctionalOption("UseIntercompanyContracts");
	
	SetConditionalAppearance();		
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	GeneratedDocumentsSelectionList = Items.GeneratedDocuments_.ChoiceList;
	GeneratedDocumentsSelectionList.Clear();
	
	GeneratedDocumentsSelectionList.Add(
		"OnlyTransfersBetweenOrganizations",
		NStr("vi = 'Chỉ chuyển giao giữa các doanh nghiệp';
			|ru = 'Только передачи между организациями';
			|en = 'Intercompany invoice'; fa = 'فاکتور درون‌گروهی';
			|it = 'Solo trasferimenti tra le organizzazioni';
			|pl = 'Tylko przekazania między firmami';
			|tr = 'Sadece iş yerleri arasındaki transferler'"));
		
	GeneratedDocumentsSelectionList.Add(
		"OnlyRedemptionOfGoodsInStorage",
		NStr("vi = 'Chỉ mua lại hàng hóa trong kho';
			|ru = 'Только выкупы товаров на хранении';
			|en = 'Intercompany VMI transfer'; fa = 'انتقال VMI درون‌گروهی';
			|it = 'Solo i riscatti delle merci in deposito';
			|pl = 'Tylko wykupy przechowywanych towarów';
			|tr = 'Sadece depolamadaki ürünlerin itfası'"));
	
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		GeneratedDocumentsSelectionList.Add(
			"OnlyRedemptionOfGiverSGoods",
			NStr("vi = 'Chỉ mua lại hàng hóa của người đặt gia công';
				|ru = 'Только выкупы товаров давальца';
				|en = 'Only provider goods redemptions'; fa = 'Only provider goods redemptions';
				|it = 'Solo riscatti delle merci del fornitore';
				|pl = 'Tylko wykupy towarów właściciela surowców';
				|tr = 'Yalnızca tedarikçi ürünlerinin iadeleri'"));
	EndIf;
	
	GeneratedDocumentsSelectionList.Add(
		"TransfersBetweenOrganizationsAndRepurchasesOfGoodsInStorage",
		NStr("vi = 'Chuyển hàng giữa các doanh nghiệp và mua lại hàng hóa trong kho';
			|ru = 'Передачи товаров между организациями и выкупы товаров на хранении';
			|en = 'Intercompany invoice and VMI transfer'; fa = 'فاکتور درون‌گروهی و انتقال VMI';
			|it = 'Trasferimenti delle merci tra le organizzazioni e riscatti delle merci in deposito';
			|pl = 'Przekazania towarów między firmami i wykupy przechowywanych towarów';
			|tr = 'İş yerleri arasındaki transferler ve depolamadaki ürünleri itfası'"));
	ValuesByKey = DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.HeaderAndGeneratedDocumentsByUseDestinationKey(
		Parameters.PurposeUseKey);
		
	Title 			 = ValuesByKey.Title;
	GeneratedDocuments_ = ValuesByKey.GeneratedDocuments_;
		
	If Not ValueIsFilled(GeneratedDocuments_) Then
		ExceptionText = NStr("vi = 'Không cần xử lý với các tùy chỉnh như vậy của tùy chỉnh chức năng.';
							|ru = 'Использовать обработку с такими настройками функциональных опций не требуется.';
							|en = 'No need to use data processor with such settings of functional options.'; fa = 'No need to use data processor with such settings of functional options.';
							|it = 'Non è necessario utilizzare elaborazione con queste impostazioni di opzioni funzionali.';
							|pl = 'Używanie procedury przetwarzania z takimi ustawieniami opcji funkcjonalnych nie jest wymagane.';
							|tr = 'Bu fonksiyonel seçenek ayarlarıyla işlemeyi kullanmak gerekli değildir.'");
		Raise ExceptionText;
	EndIf;
	
	VisibilityGeneratedDocuments = GetFunctionalOption("UseCustodyDuringPurchase");
	VisibilityGeneratedDocuments = VisibilityGeneratedDocuments
									Or GetFunctionalOption("UseTollManufacturing2_5");
	Items.GeneratedDocuments_.Visible = GetFunctionalOption("UseCustomerInvoiceIntercompany")
		And VisibilityGeneratedDocuments;
	
	DataCompositionServer.InitializeSettingsComposer(FilterOfProductItem, 
		NameOfSelectionTemplate(),
		"ProblematicOrganizations"); 
	
	Items.SetPrices.Visible = AccessRight("Insert", Metadata.Documents.PriceSetup);
	
	SenderSelectionOption = "ByTransmissionSettings";
	
	InventoryTypeSelectionValues = New Array;
	
	If GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		InventoryTypeSelectionValues.Add(Enums.InventoryTypes.OwnGoods);
	EndIf;
	
	If GetFunctionalOption("UsePurchaseCommission")
		And GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		InventoryTypeSelectionValues.Add(Enums.InventoryTypes.ConsignedGoods);
	EndIf;
	
	If GetFunctionalOption("UseCustodyDuringPurchase") Then
		InventoryTypeSelectionValues.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	EndIf;
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		InventoryTypeSelectionValues.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
		InventoryTypeSelectionValues.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
		InventoryTypeSelectionValues.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	EndIf;
	Items.SelectedSendersInventoryType.ChoiceList.LoadValues(InventoryTypeSelectionValues);
	Items.SelectedSendersInventoryType.Visible = Items.SelectedSendersInventoryType.ChoiceList.Count() > 1;
	
	ParametersArray = New Array;
	
	ContractSelectionParameter = New ChoiceParameter("Filter.ContractType", PredefinedValue("Enum.TypesOfIntercompanyContracts.PurchaseAndSale"));
	ParametersArray.Add(ContractSelectionParameter);
	
	ContractSelectionParameter = New ChoiceParameter("Filter.DeletionMark", False);
	ParametersArray.Add(ContractSelectionParameter);
	
	ContractSelectionParameter = New ChoiceParameter("Filter.Status", PredefinedValue("Enum.CounterpartyContractStatuses.Valid"));
	ParametersArray.Add(ContractSelectionParameter);
	
	Items.SelectedSendersContract.ChoiceParameters = New FixedArray(ParametersArray); 
	
	DocumentGenerationFrequency = "ByMonths";
	
	If ValueIsFilled(Parameters.TheStartDateOfTheAnalysis) Then
		AnalysisPeriod.StartDate = Parameters.TheStartDateOfTheAnalysis;
	Else
		AnalysisPeriod.StartDate = BegOfMonth(InventoriesServer.DateOfFirstReserve(AddMonth(CurrentSessionDate(),-1)));
	EndIf;
	
	If ValueIsFilled(Parameters.TheEndDateOfTheAnalysis) Then
		AnalysisPeriod.EndDate = Parameters.TheEndDateOfTheAnalysis;
	Else
		AnalysisPeriod.EndDate = EndOfMonth(CurrentSessionDate());
	EndIf;	
	
	If AnalysisPeriod.StartDate > AnalysisPeriod.EndDate Then
		AnalysisPeriod.StartDate = BegOfMonth(AnalysisPeriod.EndDate);
	EndIf;
	
	If ValueIsFilled(Parameters.Warehouse) Then
		DataCompositionClientServer.AddFilter(FilterOfProductItem, "Warehouse", Parameters.Warehouse);
	EndIf;
	
	If Parameters.RunMode = "CorrectNegativeBalance" Then
		InitializeResidueCorrectionMode();
	EndIf;
	
	CreatePresentationOfProductSelection();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If RunMode <> "CorrectNegativeBalance" Then
		FillInProblemCompanies();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_RedemptionOfGoodsFromStorage"
		Or EventName = "Write_CustomerInvoiceIntercompany" Then
		UpdateCreatedDocs();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationItemSelectionURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("DecorationItemSelectionURLProcessingCompletion", ThisForm);
		
	EditingFormParameters = New Structure("SettingsAddress,NameAddressOfTheLayout",
			SelectionOfProductsSettings(),
			NameOfSelectionTemplate());
	
	OpenForm("CommonForm.EditDataCompositionSettings",
		EditingFormParameters,
		ThisForm,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtServer
Function SelectionOfProductsSettings()
	Return FilterOfProductItem.GetSettings();	
EndFunction

&AtClient
Procedure AnalysisPeriodOnChange(Item)
	
	ClearMessages();
	
	If Not ValueIsFilled(AnalysisPeriod.StartDate)
		Or Not ValueIsFilled(AnalysisPeriod.EndDate) Then
		
		MessageText = NStr("vi = 'Cần phải điền ngày bắt đầu và kết thúc kỳ.';
							|ru = 'Даты начала и окончания периода анализа должны быть заполнены.';
							|en = 'Start and end dates of the analysis period must be populated.'; fa = 'Start and end dates of the analysis period must be populated.';
							|it = 'Le date di inizio e fine del periodo di analisi devono essere compilate.';
							|pl = 'Daty początku i zakończenia okresu analizy muszą być wypełnione.';
							|tr = 'Analiz döneminin başlangıç ve bitiş tarihleri doldurulmalıdır.'");
		
		CommonClient.MessageToUser(MessageText, , "AnalysisPeriod");
		
		If Not ValueIsFilled(AnalysisPeriod.StartDate) Then
			If ValueIsFilled(AnalysisPeriod.EndDate) Then
				AnalysisPeriod.StartDate = BegOfMonth(AddMonth(AnalysisPeriod.EndDate,-1));
			Else
				AnalysisPeriod.StartDate = BegOfMonth(AddMonth(CommonClient.SessionDate(),-1));
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(AnalysisPeriod.EndDate) Then
			AnalysisPeriod.EndDate = EndOfMonth(AnalysisPeriod.StartDate);
		EndIf;
		
	ElsIf AnalysisPeriod.StartDate > AnalysisPeriod.EndDate
		And ValueIsFilled(AnalysisPeriod.EndDate) Then
		
		MessageText = NStr("vi = 'Ngày bắt đầu của kỳ không thể lớn hơn ngày kết thúc của kỳ.';
							|ru = 'Дата начала периода не может быть больше даты окончания периода.';
							|en = 'The period start date cannot be greater than the period end date'; fa = 'The period start date cannot be greater than the period end date';
							|it = 'La data di inizio periodo non può essere superiore alla data del termine periodo.';
							|pl = 'Data początku okresu nie może być dłuższa niż data zakończenia okresu.';
							|tr = 'Dönemin başlangıç tarihi, dönemin bitiş tarihinden büyük olamaz.'");
		
		CommonClient.MessageToUser(MessageText, , "AnalysisPeriod");
		
		AnalysisPeriod.EndDate = EndOfMonth(AnalysisPeriod.StartDate);
	EndIf;
	
	FillInProblemCompanies();
	
EndProcedure

&AtClient
Procedure ProblemsInformationThereAreNegativeBalancesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	GenerateReportOnNegativeBalances(False)
EndProcedure

&AtClient
Procedure ResultsInformationThereAreNegativeBalancesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	GenerateReportOnNegativeBalances(True)
EndProcedure

&AtClient
Procedure SenderSelectionOptionOnChange(Item)
	
	ConfigureSettingsPage();
	
EndProcedure

&AtClient
Procedure DocumentGenerationFrequencyOnChange(Item)
	
	FillInProblemCompanies();
	
EndProcedure

&AtClient
Procedure GeneratedDocuments_OnChange(Item)
	
	BackgroundJob = GeneratedDocuments_OnChangeServer();
	If BackgroundJob <> Undefined Then
		FillInSenders(,BackgroundJob);
	EndIf;
	
EndProcedure

&AtClient
Procedure SendersByFeeExtendedTooltipURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	SettingsFormParameters = New Structure("CompanyCustomer", Organization);
	
	CallbackDescription = New CallbackDescription("ProcessChangesToTransferSettings", ThisObject);
	
	OpenForm("InformationRegister.CustomizeCustomerInvoiceIntercompany.ListForm",
		SettingsFormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ProcessChangesToTransferSettings(Result, AdditionalParagraphs) Export
	
	FillInConsignors();
	
EndProcedure

&AtClient
Procedure UpdateTroubledCompanies(Command)
	FillInProblemCompanies();	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCreatedDocuments

&AtClient
Procedure CreatedDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	Ref = CreatedDocuments.FindByID(RowSelected).Ref;
	
	ShowValue(,Ref);
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsSelectedSenders

&AtClient
Procedure SelectedSendersOnStartEdit(Item, NewRow, Copy)
	If NewRow
		And Not Copy Then
		Items.SelectedSenders.CurrentData.Sender = PredefinedValue("Catalog.Companies.EmptyRef");
		Items.SelectedSenders.CurrentData.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsSaleToAnotherCompany");
		Items.SelectedSenders.CurrentData.PricesKind  = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
		Items.SelectedSenders.CurrentData.Contract = PredefinedValue("Catalog.IntercompanyContracts.EmptyRef");
		
		If Items.SelectedSendersInventoryType.ChoiceList.Count() = 1 Then
			Items.SelectedSenders.CurrentData.InventoryType = Items.SelectedSendersInventoryType.ChoiceList[0].Value;
		EndIf;                                        
		
	EndIf;
EndProcedure

&AtClient
Procedure SelectedSendersSenderOnChange(Item)
	Items.SelectedSenders.CurrentData.Contract = PredefinedValue("Catalog.IntercompanyContracts.EmptyRef");
EndProcedure

&AtClient
Procedure SelectedSendersBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If Not MakeTransfers(GeneratedDocuments_) Then
		Cancel = True;
		Return;
	EndIf;
	
	If Copy
		And TypeOf(Items.SelectedSenders.CurrentData.Sender) = Type("CatalogRef.Partners") Then
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsCommissionSenders

&AtClient
Procedure SendersByFeeBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Create(Command)
	
	ClearMessages();
	
	If Not CheckSenders() Then
		Return;
	EndIf;
	
	CreateTransferDocuments("Validate", True);
	
EndProcedure

&AtClient
Procedure ContinueGeneratingDocuments(Command)
	
	If DocumentGenerationCanceled Then
		CreateTransferDocuments("DontCheck", False);
	Else
		CallbackDescription = New CallbackDescription("ContinueGeneratingDocumentsCompletion", ThisObject);
		OpenForm("DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption.Form.SelectGenerationContinuationOption",
			,
			ThisObject,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
		
EndProcedure

&AtClient
Procedure ContinueGeneratingDocumentsCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		CreateTransferDocuments(Result, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheTransferSettings(Command)
	
	FillInSenders("SelectedSenders");
	
EndProcedure

&AtClient
Procedure ContinueWithNewSelections(Command)
	
	CreatedDocuments.Clear();
	
	Items.Main.CurrentPage = Items.Issues;
	Items.GoToGenerationSettings.DefaultButton = True;
	
	FillInProblemCompanies();
	
EndProcedure

&AtClient
Procedure SetPrices(Command)
	
	UnstatedPricesAddress = PlacePricesThatAreNotSetInTemporaryStorage();
	
	FillingValues = New Structure;
	FillingValues.Insert("Date", BegOfDay(AnalysisPeriod.StartDate));
	FillingValues.Insert("ProductsTable", UnstatedPricesAddress);
	
	ParametersOfPriceSettingForm = New Structure;
	ParametersOfPriceSettingForm.Insert("FillingValues", FillingValues);
	
	CallbackDescription = New CallbackDescription("SetPricesCompletion", ThisObject);
	
	OpenForm("Document.PriceSetup.ObjectForm",
		ParametersOfPriceSettingForm,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);		
	
EndProcedure

&AtClient
Procedure GoToGenerationSettings(Command)
	
	If ProblematicOrganizations.Count() = 0 Then
		MessageText = NStr("vi = 'Không có doanh nghiệp mà cần tạo chứng từ với các tùy chỉnh phân tích đã chỉ ra.';
							|ru = 'Нет организаций, по которым требуется оформлять документы с указанными настройками анализа.';
							|en = 'There are no companies that require document registration with the specified analysis settings.'; fa = 'There are no companies that require document registration with the specified analysis settings.';
							|it = 'Non ci sono società per le quali è richiesto formalizzare i documenti con le impostazioni di analisi specificate.';
							|pl = 'Brak firm, według których należy sporządzić dokumenty z wskazanymi ustawieniami analizy.';
							|tr = 'Belirtilen analiz ayarlarına sahip belgelerin düzenlenmesi gereken herhangi iş yeri bulunmamaktadır.'");
		ShowMessageBox(, MessageText);
	ElsIf Items.ProblematicOrganizations.CurrentData = Undefined Then
		MessageText = NStr("vi = 'Hãy chọn doanh nghiệp mà theo đó cần tạo chứng từ.';
							|ru = 'Выберите организацию, по которой нужно оформлять документы.';
							|en = 'Select a company to register documents by.'; fa = 'Select a company to register documents by.';
							|it = 'Selezionare la società per la quale si desidera formalizzare i documenti.';
							|pl = 'Wybierz firmę, według której należy sporządzić dokumenty.';
							|tr = 'Düzenlenmesi gereken belgelere göre iş yerini seç.'");
		ShowMessageBox(, MessageText);
	Else
		Organization = Items.ProblematicOrganizations.CurrentData.Organization;
		InventoryType  = Items.ProblematicOrganizations.CurrentData.InventoryType;
		
		BackgroundJob = FillInDataAndConfigureSettingsPage();
		
		If BackgroundJob <> Undefined Then
			If InventoryType = PredefinedValue("Enum.InventoryTypes.OwnGoods") Then
				FillInSenders(,BackgroundJob);
			Else
				FillInConsignors(BackgroundJob);
			EndIf;
			
		EndIf;
		
		Items.Main.CurrentPage  = Items.Settings;
		Items.Create.DefaultButton = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BackToGenerationSettings(Command)
	Items.Main.CurrentPage  = Items.Settings;
	Items.Create.DefaultButton = True;
EndProcedure

&AtClient
Procedure ToRecipientCompanySelection(Command)
	
	SaveSelectedSenders();
	
	Items.Main.CurrentPage = Items.Issues;
	Items.GoToGenerationSettings.DefaultButton = True;
	
EndProcedure

&AtClient
Procedure AddDepositor(Command)
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("Organization", Organization);
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("TableAddress", PlaceDepositorsWithGoodsInTemporaryStorage());
	
	CallbackDescription = New CallbackDescription("AddDepositorCompletion", ThisObject);
	
	OpenForm("DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption.Form.SelectionOfDepositor",
		ChoiceFormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure AddDepositorCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result)
		And TypeOf(Result) = Type("Structure") Then
		
		FillPropertyValues(Object.SelectedSenders.Add(), Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkDocumentsForDeletion(Command)
	QueryText = NStr("vi = 'Khi quay lại tùy chỉnh thì các chứng từ đã tạo sẽ bị đặt dấu xóa. Tiếp tục?';
					|ru = 'При возврате к настройкам созданные документы будут помечены на удаление. Продолжить?';
					|en = 'If you go back to settings, the created documents will be marked for deletion. Continue?'; fa = 'If you go back to settings, the created documents will be marked for deletion. Continue?';
					|it = 'Quando si ritorna alle impostazioni, i documenti creati verranno contrassegnati per la cancellazione. Continuare?';
					|pl = 'Podczas zwrotu do ustawień utworzone dokumenty będą zaznaczone do usunięcia. Kontynuować?';
					|tr = 'Ayarlara geri dönüldüğünde, oluşturulan belgeler silinmek üzere işaretlenecektir. Devam edilsin mi?'");
	CallbackDescription = New CallbackDescription("MarkDocumentsForDeletionCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel,, DialogReturnCode.Cancel);
EndProcedure

&AtClient
Procedure MarkDocumentsForDeletionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		MarkCreatedDocumentsForDeletion();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheCommitteersTeam(Command)		
	FillInConsignors();	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearanceUnavailable = Not GetFunctionalOption("UseCustodyDuringPurchase");
	ConditionalAppearanceUnavailable = ConditionalAppearanceUnavailable
								   And Not GetFunctionalOption("UseTollManufacturing2_5");
	If ConditionalAppearanceUnavailable Then
		Return;
	EndIf;
	
	EconomicOperationsOfRedemption = New ValueList;
	EconomicOperationsOfRedemption.LoadValues(DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.EconomicOperationsOfRedemption());
	
	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedSendersSender.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedSendersPricesKind.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedSendersInventoryType.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedSendersContract.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SelectedSenders.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = EconomicOperationsOfRedemption;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedSendersContract.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SelectedSenders.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = EconomicOperationsOfRedemption;
	
	Item.Appearance.SetParameterValue("ReadOnly", Not UseIntercompanyContracts);
	If Not UseIntercompanyContracts Then
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<để mua lại>';
														|ru = '<для выкупов>';
														|en = '<for redemptions>'; fa = '<for redemptions>';
														|it = '<per riscatti>';
														|pl = '<dla wykupów>';
														|tr = '<itfa için>'"));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	EndIf;	
	
	//
	
	If GetFunctionalOption("UseTollManufacturing2_5") Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.SelectedSendersPricesKind.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField("Object.SelectedSenders.BusinessOperation");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.BusinessTransactions.RedemptionOfProviderGoods;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	EndIf;
EndProcedure

#Region CreateTransferDocuments

&AtClient
Procedure CreateTransferDocuments(ActionWithTransferPrices, SaveSenders)
	
	DocumentGenerationCanceled = False;
	BackgroundJob = CreateTransferDocumentsServer(ActionWithTransferPrices, SaveSenders);
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("AfterCreatingTransferDocuments", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function CreateTransferDocumentsServer(ActionWithTransferPrices, SaveSenders)
	
	CreationParameters = New Structure;
	CreationParameters.Insert("Organization", Organization);
	CreationParameters.Insert("Period", AnalysisPeriod);
	CreationParameters.Insert("InventoryType", InventoryType);
	
	If InventoryType = Enums.InventoryTypes.OwnGoods Then
		
		CreationParameters.Insert("SelectedSenders", Object.SelectedSenders.Unload());
		CreationParameters.Insert("SenderSelectionOption", SenderSelectionOption);
		CreationParameters.Insert("MakeTransfers", MakeTransfers(GeneratedDocuments_));
		CreationParameters.Insert("IssueRansoms", IssueRansoms(GeneratedDocuments_));
		
	Else	
		
		CreationParameters.Insert("SelectedSenders", SendersByFee.Unload());
		CreationParameters.Insert("SenderSelectionOption", "AccordingToSpecifiedPriorities");
		CreationParameters.Insert("MakeTransfers", True);
		CreationParameters.Insert("IssueRansoms", False);
		
	EndIf;
	CreationParameters.Insert("GeneratedDocuments_", GeneratedDocuments_);
	CreationParameters.Insert("CreatedDocuments", CreatedDocuments.Unload().UnloadColumn("Ref"));
	
	CreationParameters.Insert("DocumentGenerationFrequency", DocumentGenerationFrequency);
	
	LayoutSettingsForBackgroundJobs = LayoutSettingsByName("ProductsToBeTransferred", True);
	
	CreationParameters.Insert("CompositionSettings", LayoutSettingsForBackgroundJobs);
	CreationParameters.Insert("TemplateName", NameOfSelectionTemplate());
	CreationParameters.Insert("ActionWithTransferPrices", ActionWithTransferPrices);
	
	If SaveSenders Then
		SaveSelectedSenders();
	EndIf;
	                       
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập chứng từ chuyển giao hàng hóa giữa các doanh nghiệp và mua lại';
																	|ru = 'Формирование документов передачи товаров между организациями и выкупов';
																	|en = 'Generate ""Customer invoices — Intercompany"" and redemption documents'; fa = 'Generate ""Customer invoices — Intercompany"" and redemption documents';
																	|it = 'Generazione di documenti di trasferimento delle merci tra le società e dei riscatti';
																	|pl = 'Utworzenie dokumentów przekazania towarów między firmami i wykupów';
																	|tr = 'İş yerleri arası müşteri faturası ve satın alma faturasını oluşturma'");
	BackgroundExecutionParameters.RunInBackground = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.CreateTransferDocuments",
		CreationParameters, BackgroundExecutionParameters);
	
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterCreatingTransferDocuments(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
		CreatedDocuments.Clear();
		UnsetPrices.Clear();
		UploadResultsOfBackgroundTasks(BackgroundJob.ResultAddress);		
		
		If UnsetPrices.Count() > 0 Then
			Items.Main.CurrentPage = Items.SettingPrices;
			Items.SetPrices.DefaultButton = True;
		ElsIf CreatedDocuments.Count() = 0 Then
			MessageText = NStr("vi = 'Không thể tạo chứng từ với các tùy chỉnh tạo đã chỉ ra.';
								|ru = 'Не удалось создать документы с указанными настройками формирования.';
								|en = 'Cannot create documents with the specified generation settings.'; fa = 'Cannot create documents with the specified generation settings.';
								|it = 'Impossibile creare documenti con delle impostazioni di generazione specificate.';
								|pl = 'Nie udało się utworzyć dokumentów z wskazanymi ustawieniami utworzenia.';
								|tr = 'Belirtilen biçimlendirme ayarlarıyla belge oluşturulamadı.'");
			ShowMessageBox(,MessageText);
			
			Items.Main.CurrentPage = Items.Settings;
			Items.Create.DefaultButton = True;
			
		Else
			Items.Main.CurrentPage = Items.Results;
			Items.ContinueWithNewSelections.DefaultButton = RunMode <> "CorrectNegativeBalance";
			Items.Done.DefaultButton = RunMode = "CorrectNegativeBalance";
			
			DocumentGenerationCanceled = Not AllDocumentsArePosted;
			SetVisibilityOfInformationOnPageOfCreatedDocuments(True);
			
		EndIf;
		
		If MakeTransfers(GeneratedDocuments_) Then
			Notify("Write_CustomerInvoiceIntercompany");
		EndIf;
		
		If IssueRansoms(GeneratedDocuments_) Then
			Notify("Write_RedemptionOfGoodsFromStorage");
		EndIf;
		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành việc tạo chứng từ do: %Cause%';
									|ru = 'Не удалось закончить формирование документов по причине: %Cause%';
									|en = 'Cannot complete document generation. Reason: %Cause%'; fa = 'Cannot complete document generation. Reason: %Cause%';
									|it = 'Non è stato possibile completare la generazione dei documenti a causa di: %Cause%';
									|pl = 'Nie udało się zakończyć utworzenie dokumentów z powodu: %Cause%';
									|tr = 'Şu nedenden dolayı belge oluşturma işlemi tamamlanamadı: %Cause%'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FillInProblemCompanies

&AtClient
Procedure FillInProblemCompanies()
	Items.ProblemsInformationIsGenerated.Visible = True;
	Items.ProblemsInformationThereAreNegativeBalances.Visible = False;
	Items.ProblemsInformationNoNegativeBalances.Visible = False;
	
	ProblematicOrganizations.Clear();
	Items.GoToGenerationSettings.Enabled = False;
	Items.ProblematicOrganizations.Enabled          = False;
		
	BackgroundJob = FillInProblemCompaniesServer();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	Handler = New CallbackDescription("AfterFillingInProblemAreas", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
EndProcedure

&AtServer
Function FillInProblemCompaniesServer()
	
	CreationParameters = New Structure;                    
	CreationParameters.Insert("Period", AnalysisPeriod);
	CreationParameters.Insert("DocumentGenerationFrequency", DocumentGenerationFrequency);
	
	LayoutSettingsForBackgroundJobs = LayoutSettingsByName("ProblematicOrganizations", False);
	
	CreationParameters.Insert("CompositionSettings", LayoutSettingsForBackgroundJobs);
	CreationParameters.Insert("TemplateName", NameOfSelectionTemplate());
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền vào danh sách các doanh nghiệp có vấn đề';
																	|ru = 'Заполнение списка проблемных организаций';
																	|en = 'Fill in troubled company list'; fa = 'Fill in troubled company list';
																	|it = 'Compilazione dell''elenco di società problematiche';
																	|pl = 'Wypełnienie listy problemnych firm';
																	|tr = 'Sorunlu iş yerleri listesinin doldurulması'");
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.FillInListOfProblemOrganizations",
		CreationParameters, BackgroundExecutionParameters);
	
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterFillingInProblemAreas(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
		UploadResultsOfBackgroundTasks(BackgroundJob.ResultAddress);		
		HasIssue = ProblematicOrganizations.Count() > 0;
		
		Items.ProblemsInformationIsGenerated.Visible              = False;
		Items.ProblemsInformationThereAreNegativeBalances.Visible = HasIssue;
		Items.ProblemsInformationNoNegativeBalances.Visible = Not HasIssue;
		
		Items.Main.CurrentPage = Items.Issues;
		Items.GoToGenerationSettings.DefaultButton = True;
		
		Items.GoToGenerationSettings.Enabled = HasIssue;
		Items.ProblematicOrganizations.Enabled        = HasIssue;
	Else
		Items.ProblemsInformationIsGenerated.Visible              = True;
		Items.ProblemsInformationThereAreNegativeBalances.Visible = False;
		Items.ProblemsInformationNoNegativeBalances.Visible = False;
		Items.GoToGenerationSettings.Enabled           = False;
		Items.ProblematicOrganizations.Enabled                    = False;
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành việc điền vào danh sách các doanh nghiệp có số dư âm do: %Cause%';
									|ru = 'Не удалось закончить заполнения списка организаций с отрицательными остатками по причине: %Cause%';
									|en = 'Cannot complete filling in the list of companies with negative balance. Reason: %Cause%'; fa = 'Cannot complete filling in the list of companies with negative balance. Reason: %Cause%';
									|it = 'Impossibile completare la compilazione dell''elenco delle società con saldi negativi a causa di: %Cause%';
									|pl = 'Nie udało się zakończyć wypełnienie listy firm z ujemnymi ostatkami z powodu: %Cause%';
									|tr = 'Negatif bakiyesi olan iş yerlerinin listesi şu nedenden dolayı tamamlanamadı: %Cause%'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region MarkCreatedDocumentsForDeletion

&AtClient
Procedure MarkCreatedDocumentsForDeletion()		
	BackgroundJob = MarkCreatedDocumentsForDeletionServer();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("AfterMarkingToDeleteCreatedDocuments", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
EndProcedure

&AtServer
Function MarkCreatedDocumentsForDeletionServer()
	
	CreationParameters = New Structure;                    
	CreationParameters.Insert("MakeTransfers", MakeTransfers(GeneratedDocuments_));
	CreationParameters.Insert("IssueRansoms", IssueRansoms(GeneratedDocuments_));
	CreationParameters.Insert("CreatedDocuments", CreatedDocuments.Unload().UnloadColumn("Ref"));
	
	CreationParameters.Insert("Period", AnalysisPeriod);
	CreationParameters.Insert("DocumentGenerationFrequency", DocumentGenerationFrequency);
	
	LayoutSettingsForBackgroundJobs = LayoutSettingsByName("ProblematicOrganizations", False);
	
	CreationParameters.Insert("CompositionSettings", LayoutSettingsForBackgroundJobs);
	CreationParameters.Insert("TemplateName", NameOfSelectionTemplate());
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Đánh dấu để xóa các chứng từ đã tạo';
																	|ru = 'Пометка на удаление созданных документов';
																	|en = 'Mark created documents for deletion'; fa = 'Mark created documents for deletion';
																	|it = 'Contrassegno per eliminazione dei documenti creati';
																	|pl = 'Zaznaczenie do usunięcia utworzonych dokumentów';
																	|tr = 'Oluşturulan belgelerin silinmesi için işaretleme'");
	BackgroundExecutionParameters.RunInBackground = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.MarkCreatedDocumentsForDeletion",
		CreationParameters, BackgroundExecutionParameters);
	
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterMarkingToDeleteCreatedDocuments(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
		CreatedDocuments.Clear();
		UploadResultsOfBackgroundTasks(BackgroundJob.ResultAddress);		
		
		If CreatedDocuments.Count() > 0 Then
			ErrorDescription = NStr("vi = 'Các chứng từ hiển thị trong bảng không thể được đánh dấu để xóa.';
									|ru = 'Показанные в таблице документы не удалось пометить на удаление.';
									|en = 'Cannot mark documents shown in the table for deletion.'; fa = 'Cannot mark documents shown in the table for deletion.';
									|it = 'I documenti visualizzati nella tabella non possono essere contrassegnati per la cancellazione.';
									|pl = 'Pokazane w tabeli dokumenty nie udało się zaznaczyć do usunięcia.';
									|tr = 'Tabloda gösterilen belgeler silinmek üzere işaretlenememiştir.'");
			ShowMessageBox(, ErrorDescription);
			Items.ResultsInformationThereAreNegativeBalances.Visible = False;
			Items.ResultsInformationNoNegativeBalances.Visible = False;
		Else
			Items.Main.CurrentPage = Items.Settings;
			Items.Create.DefaultButton = True;
		EndIf;
		
		If MakeTransfers(GeneratedDocuments_) Then
			Notify("Write_CustomerInvoiceIntercompany");
		EndIf;
		
		If IssueRansoms(GeneratedDocuments_) Then
			Notify("Write_RedemptionOfGoodsFromStorage");
		EndIf;
		
	Else
		Items.ResultsInformationThereAreNegativeBalances.Visible = False;
		Items.ResultsInformationNoNegativeBalances.Visible = False;
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành việc điền vào danh sách các doanh nghiệp có số dư âm do: %Cause%';
									|ru = 'Не удалось закончить заполнения списка организаций с отрицательными остатками по причине: %Cause%';
									|en = 'Cannot complete filling in the list of companies with negative balance. Reason: %Cause%'; fa = 'Cannot complete filling in the list of companies with negative balance. Reason: %Cause%';
									|it = 'Impossibile completare la compilazione dell''elenco delle società con saldi negativi a causa di: %Cause%';
									|pl = 'Nie udało się zakończyć wypełnienie listy firm z ujemnymi ostatkami z powodu: %Cause%';
									|tr = 'Negatif bakiyesi olan iş yerlerinin listesi şu nedenden dolayı tamamlanamadı: %Cause%'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region UpdateCreatedDocs

&AtClient
Procedure UpdateCreatedDocs()		
	SetVisibilityOfInformationOnPageOfCreatedDocuments(False);
	
	BackgroundJob = UpdateCreatedDocsServer();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	Handler = New CallbackDescription("AfterUpdatingCreatedDocuments", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
EndProcedure

&AtServer
Function UpdateCreatedDocsServer()
	
	CreationParameters = New Structure;                    
	CreationParameters.Insert("MakeTransfers", MakeTransfers(GeneratedDocuments_));
	CreationParameters.Insert("IssueRansoms", IssueRansoms(GeneratedDocuments_));
	CreationParameters.Insert("CreatedDocuments", CreatedDocuments.Unload().UnloadColumn("Ref"));
	CreationParameters.Insert("Period", AnalysisPeriod);
	CreationParameters.Insert("DocumentGenerationFrequency", DocumentGenerationFrequency);
	
	LayoutSettingsForBackgroundJobs = LayoutSettingsByName("ProblematicOrganizations", False);
	
	CreationParameters.Insert("CompositionSettings", LayoutSettingsForBackgroundJobs);
	CreationParameters.Insert("TemplateName", NameOfSelectionTemplate());
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật danh sách các chứng từ đã tạo';
																	|ru = 'Обновление списка созданных документов';
																	|en = 'Update created document list'; fa = 'Update created document list';
																	|it = 'Aggiornamento dell''elenco dei documenti creati';
																	|pl = 'Aktualizacja listy utworzonych dokumentów';
																	|tr = 'Oluşturulan belgelerin listesini güncelleme'");
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.UpdateCreatedDocs",
		CreationParameters, BackgroundExecutionParameters);
	
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterUpdatingCreatedDocuments(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
		
		UploadResultsOfBackgroundTasks(BackgroundJob.ResultAddress);		
		SetVisibilityOfInformationOnPageOfCreatedDocuments(True);
		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn tất cập nhật danh sách các chứng từ đã tạo do: %Cause%';
									|ru = 'Не удалось закончить обновление списка созданных документов по причине: %Cause%';
									|en = 'Cannot complete updating the list of created documents. Reason: %Cause%'; fa = 'Cannot complete updating the list of created documents. Reason: %Cause%';
									|it = 'Non è stato possibile completare l''aggiornamento dell''elenco dei documenti generati a causa di: %Cause%';
									|pl = 'Nie udało się zakończyć aktualizację listy utworzonych dokumentów z powodu: %Cause%';
									|tr = 'Oluşturulan belgelerin listesinin güncellenmesi şu nedenle tamamlanamadı: %Cause%'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FillInConsignors
	
&AtClient
Procedure FillInConsignors(BackgroundJob = Undefined)		
	If BackgroundJob = Undefined Then
		BackgroundJob = FillInConsignorsServer();
	EndIf;
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	Handler = New CallbackDescription("AfterFillingCommittees", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
EndProcedure

&AtServer
Function FillInConsignorsServer()
	
	CreationParameters = New Structure;                    
	CreationParameters.Insert("MakeTransfers", MakeTransfers(GeneratedDocuments_));
	CreationParameters.Insert("IssueRansoms", IssueRansoms(GeneratedDocuments_));
	CreationParameters.Insert("CreatedDocuments", CreatedDocuments.Unload().UnloadColumn("Ref"));
	CreationParameters.Insert("Period", AnalysisPeriod);
	CreationParameters.Insert("DocumentGenerationFrequency", DocumentGenerationFrequency);
	CreationParameters.Insert("Organization", Organization);
	CreationParameters.Insert("InventoryType", InventoryType);
	
	LayoutSettingsForBackgroundJobs = LayoutSettingsByName("OrganizationsCommittees", True);
	
	CreationParameters.Insert("CompositionSettings", LayoutSettingsForBackgroundJobs);
	CreationParameters.Insert("TemplateName", NameOfSelectionTemplate());
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật danh sách doanh nghiệp';
																	|ru = 'Обновление списка организаций-коминетов';
																	|en = 'Update consignor company list'; fa = 'Update consignor company list';
																	|it = 'Aggiornamento dell''elenco di società-committenti';
																	|pl = 'Aktualizacja listy firm-komitentów';
																	|tr = 'Gönderici iş yeri listesinin güncellenmesi'");
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.FillInConsignors",
		CreationParameters, BackgroundExecutionParameters);
	
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterFillingCommittees(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
		UploadResultsOfBackgroundTasks(BackgroundJob.ResultAddress);		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành điền vào danh sách các doanh nghiệp có thẩm quyền do: %Cause%';
									|ru = 'Не удалось закончить заполнения списка организаций-кометентов по причине: %Cause%';
									|en = 'Cannot complete filling in the list of principal companies. Reason: %Cause%'; fa = 'Cannot complete filling in the list of principal companies. Reason: %Cause%';
									|it = 'Impossibile completare la compilazione dell''elenco delle società-committenti a causa di: %Cause%';
									|pl = 'Nie udało się zakończyć wypełnienia listy firm-komitentów z powodu: %Cause%';
									|tr = 'Bu %Cause% nedenle gönderici iş yeri listesinin doldurulması tamamlanamadı'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FillInSenders

&AtClient
Procedure FillInSenders(TableName = "", BackgroundJob = Undefined)		
	If BackgroundJob = Undefined Then
		BackgroundJob = FillInSendersServer(TableName);
	EndIf;
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	Handler = New CallbackDescription("AfterFillingInSenders", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
EndProcedure

&AtServer
Function FillInSendersServer(TableName)
	
	OnlyDepositors = TableName = "DepositorsWithGoods";
	
	CreationParameters = New Structure;                    
	CreationParameters.Insert("MakeTransfers", MakeTransfers(GeneratedDocuments_) And Not OnlyDepositors);
	CreationParameters.Insert("IssueRansoms", IssueRansoms(GeneratedDocuments_));
	CreationParameters.Insert("Organization", Organization);
	CreationParameters.Insert("TableName", TableName);
	CreationParameters.Insert("InventoryType", InventoryType);
	CreationParameters.Insert("GeneratedDocuments_", GeneratedDocuments_);
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật tên người gửi sản phẩm';
																	|ru = 'Обновление отправителей товаров';
																	|en = 'Update goods senders'; fa = 'Update goods senders';
																	|it = 'Aggiornamento dei mittenti delle merci';
																	|pl = 'Aktualizacja nadawców towarów';
																	|tr = 'Ürünlerin göndericilerinin güncellenmesi'");
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.FillInSenders",
		CreationParameters, BackgroundExecutionParameters);
	
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterFillingInSenders(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
		UploadResultsOfBackgroundTasks(BackgroundJob.ResultAddress);		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành điền vào danh sách người gửi do: %Cause%';
									|ru = 'Не удалось закончить заполнения списка отправителей по причине: %Cause%';
									|en = 'Cannot complete filling in the list of senders. Reason: %Cause%'; fa = 'Cannot complete filling in the list of senders. Reason: %Cause%';
									|it = 'Impossibile completare la compilazione dell''elenco dei mittenti a causa di: %Cause%';
									|pl = 'Nie udało się zakończyć wypełnienie listy nadawców z powodu: %Cause%';
									|tr = 'Gönderen listesini doldurma işlemi şu nedenle tamamlanamadı: %Cause%'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

&AtServer
Procedure SaveSelectedSenders()
	If InventoryType = Enums.InventoryTypes.OwnGoods Then
		ObjectKey = "DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption";
		
		If ValueIsFilled(Organization)
			And Object.SelectedSenders.Count() > 0 Then
			
			SettingsKey = String(Organization.UUID()) + "SelectedSenders";
			
			Common.CommonSettingsStorageSave(ObjectKey,
				SettingsKey,
				Object.SelectedSenders.Unload());
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure UploadSelectedSenders()
	
	If SenderSelectionOption = "AccordingToSpecifiedPriorities" Then
		If ValueIsFilled(Organization) Then
			ObjectKey = "DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption";
			SettingsKey = String(Organization.UUID()) + "SelectedSenders";
			SelectedSendersSettings = Common.CommonSettingsStorageLoad(ObjectKey, SettingsKey);
			If SelectedSendersSettings <> Undefined
				And TypeOf(SelectedSendersSettings) = Type("ValueTable") Then
				Object.SelectedSenders.Load(SelectedSendersSettings);
				
				DeleteLinesOfSelectedSendersForGeneratedDocuments();
			Else
				Object.SelectedSenders.Clear();
			EndIf;
		Else
			Object.SelectedSenders.Clear();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteLinesOfSelectedSendersForGeneratedDocuments()
	
	IndexOf = Object.SelectedSenders.Count();
	
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		
		TableRow = Object.SelectedSenders[IndexOf];
		
		SenderOrganization_ = TypeOf(TableRow.Sender) = Type("CatalogRef.Companies");
		SenderPartner = TypeOf(TableRow.Sender) = Type("CatalogRef.Partners");
		
		If (SenderPartner
			And Not IssueRansoms(GeneratedDocuments_))
			
			Or (SenderOrganization_
			And Not MakeTransfers(GeneratedDocuments_))
			
			Or Not ValueIsFilled(TableRow.Sender)
			
			Or Not ValueIsFilled(TableRow.PricesKind)
			
			Or Not ValueIsFilled(TableRow.BusinessOperation)
			
			Or Not ValueIsFilled(TableRow.InventoryType)
			
			Or Not ValueIsFilled(TableRow.Contract)
				And (UseIntercompanyContracts
			    	And SenderOrganization_
					Or SenderPartner) Then
			
			Object.SelectedSenders.Delete(TableRow);
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Function GeneratedDocuments_OnChangeServer()
	
	BackgroundJob = FillInDataAndConfigureSettingsPage();
	DeleteLinesOfSelectedSendersForGeneratedDocuments();

	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure GenerateReportOnNegativeBalances(WithSelectionByCurRecipient)
	FormParameters = New Structure;
	
	FilterReport_ = New Structure;
	FilterReport_.Insert("DocumentGenerationFrequency", DocumentGenerationFrequency);
	
	FormParameters.Insert("Filter", FilterReport_);													
	FormParameters.Insert("FixedSettings", LayoutSettingsByName("Report", WithSelectionByCurRecipient));
	FormParameters.Insert("PurposeUseKey");
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	FormParameters.Insert("VariantKey", "Report");
	
	OpenForm("Report.CompanyNegativeStockBalance.Form", FormParameters, ThisForm);
EndProcedure

&AtClient
Procedure SetPricesCompletion(Result, CallbackDescription) Export
	
	BackToGenerationSettings(Undefined);	
	
EndProcedure

&AtServer
Function LayoutSettingsByName(SettingName, WithSelectionByCurRecipient)
	
	Return DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.LayoutSettingsByName(
		 FilterOfProductItem.GetSettings(),
		 SettingName,
		 NameOfSelectionTemplate(),
		 AnalysisPeriod,
		 DocumentGenerationFrequency,
		 ?(WithSelectionByCurRecipient, Organization, Undefined),
		 ?(WithSelectionByCurRecipient, InventoryType, Undefined));
	
EndFunction

&AtClientAtServerNoContext
Function NameOfSelectionTemplate()
	
	Return "Report.CompanyNegativeStockBalance.FilterOfProducts_";
	
EndFunction

&AtClient
Procedure DecorationItemSelectionURLProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or Not IsTempStorageURL(Result) Then
		Return;
	EndIf;
	ProcessProductSelectionChanges(Result);
	FillInProblemCompanies();
	
EndProcedure

&AtServer
Procedure ProcessProductSelectionChanges(FilterAddress)
	
	SelectionOfProductsSetting = GetFromTempStorage(FilterAddress);
	DeleteFromTempStorage(FilterAddress);
	
	FilterOfProductItem.LoadSettings(SelectionOfProductsSetting);
	CreatePresentationOfProductSelection();
	
EndProcedure

&AtServer
Procedure CreatePresentationOfProductSelection()
	
	RowsArray = New Array;
	RowsArray.Add(NStr("vi = 'Lọc mặt hàng:';
						|ru = 'Отбор номенклатуры:';
						|en = 'Filter product:'; fa = 'Filter product:';
						|it = 'Selezione articoli:';
						|pl = 'Filtr wierszy pozycji:';
						|tr = 'Ürün gamı filtresi:'") + " ");
	FilterPresentation = String(FilterOfProductItem.Settings.Filter);
	If ValueIsFilled(FilterPresentation) Then
		RowsArray.Add(FilterPresentation+". ");
	Else
		RowsArray.Add(NStr("vi = '<chưa thiết lập>.';
							|ru = '<не установлен>.';
							|en = '<not set>.'; fa = '<not set>.';
							|it = '<non impostato>.';
							|pl = '<nie ustawiono>.';
							|tr = '<ayarlanmadı>.'")+ " ");
	EndIf;
	RowsArray.Add(New FormattedString(NStr("vi = 'Đặt bộ lọc';
											|ru = 'Установить отбор';
											|en = 'Set filter'; fa = 'تعیین فیلتر';
											|it = 'Impostare selezione';
											|pl = 'Ustaw wybór';
											|tr = 'Filtre kur'"),,,,"Filter"));
	Items.DecorationItemSelection.Title = New FormattedString(RowsArray);
	
EndProcedure

&AtServer
Procedure UploadResultsOfBackgroundTasks(StorageAddress)
	
	Result = GetFromTempStorage(StorageAddress);
	FormAttributes = ThisObject.GetAttributes();
	
	For Each RowOfTables In Result Do
		
		FormDetailsFound = False;
		For Each ArrRow In FormAttributes Do
			If ArrRow.Name = RowOfTables.TableName Then 
				ThisObject[RowOfTables.TableName].Load(RowOfTables.Table);
				FormDetailsFound = True;
				Break;
			EndIf;
		EndDo;
		
		If Not FormDetailsFound Then
			If Object.Property(RowOfTables.TableName) Then
				Object[RowOfTables.TableName].Load(RowOfTables.Table);
			Else
				ExceptionText = NStr("vi = 'Tên bảng không xác định %TableName%';
									|ru = 'Неизвестное имя таблицы %TableName%';
									|en = 'Unknown table name %TableName%'; fa = 'Unknown table name %TableName%';
									|it = 'Nome della tabella sconosciuto %TableName%';
									|pl = 'Nieznana nazwa tabeli %TableName%';
									|tr = 'Bilinmeyen tablo adı %TableName%'");
				ExceptionText = StrReplace(ExceptionText, "%TableName%", RowOfTables.TableName);
				Raise ExceptionText;
			EndIf;
		EndIf;
	EndDo;
	
	AllDocumentsArePosted = CreatedDocuments.FindRows(New Structure("Posted", False)).Count() = 0;	
EndProcedure

&AtClientAtServerNoContext
Function MakeTransfers(GeneratedDocuments_)
	
	Return GeneratedDocuments_ = "TransfersBetweenOrganizationsAndRepurchasesOfGoodsInStorage"
			Or GeneratedDocuments_ = "OnlyTransfersBetweenOrganizations";
	
EndFunction
		
&AtClientAtServerNoContext
Function IssueRansoms(GeneratedDocuments_)
	
	Return GeneratedDocuments_ = "TransfersBetweenOrganizationsAndRepurchasesOfGoodsInStorage"
			Or GeneratedDocuments_ = "OnlyRedemptionOfGiverSGoods"
			Or GeneratedDocuments_ = "OnlyRedemptionOfGoods"
			Or GeneratedDocuments_ = "OnlyRedemptionOfGoodsInStorage";
	
EndFunction

&AtServer
Function PlacePricesThatAreNotSetInTemporaryStorage()
	
	Return PutToTempStorage(UnsetPrices.Unload(), UUID);
	
EndFunction

&AtServer
Function ConfigureSettingsPage()
	
	If InventoryType = Enums.InventoryTypes.OwnGoods Then
		
		Items.SettingsInventoryTypes.CurrentPage = Items.SettingsInventoryTypesOwnGoods;
		
		If SenderSelectionOption = "ByTransmissionSettings" Then
			Items.SenderPages.CurrentPage = Items.PageSendersByTransferSettings;
			Items.TransferSettings.Visible = MakeTransfers(GeneratedDocuments_);
			Items.DepositorsWithGoods.Visible = IssueRansoms(GeneratedDocuments_);
		Else
			Items.SenderPages.CurrentPage = Items.PageSendersAccordingToSpecifiedPriorities;
		EndIf;
		
		If SenderSelectionOption = "ByTransmissionSettings" Then
			ExplanationText =
			NStr("vi = 'Theo doanh nghiệp-nhận sẽ tìm thấy số dư âm vào cuối mỗi %PresentationOfPeriodicityOfFormation%từ kỳ đã chỉ ra. Sau đó, sẽ phân tích số dư của chủ sở hữu hàng hóa và %PresentationOfGeneratedDocuments%. Ban đầu, sẽ ghi giảm hàng hóa mà theo đó đã tạo dự phòng hàng hóa của doanh nghiệp.';
				|ru = 'По организации-получателю будут найдены отрицательные остатки на конец каждого %PresentationOfPeriodicityOfFormation% из указанного периода. Затем будут проанализированы остатки владельцев товаров и %PresentationOfGeneratedDocuments%. Сначала будут списываться товары, по которым сформированы резервы товаров организаций.';
				|en = 'Negative balance at the end of each %PresentationOfPeriodicityOfFormation% within the specified period will be found for the receiving company. Then stock balance of owners will be analyzed and %PresentationOfGeneratedDocuments%. First, goods by which there are generated company goods reserves will be written off.'; fa = 'Negative balance at the end of each %PresentationOfPeriodicityOfFormation% within the specified period will be found for the receiving company. Then stock balance of owners will be analyzed and %PresentationOfGeneratedDocuments%. First, goods by which there are generated company goods reserves will be written off.';
				|it = 'Per la società-destinatario verranno trovati i saldi negativi per fine di ciascuno %PresentationOfPeriodicityOfFormation% dei periodi specificati. Quindi verranno analizzate le rimanenze dei proprietari delle merci e %PresentationOfGeneratedDocuments%. Prima verranno stornate le merci per le quali sono generate le scorte merci delle società.';
				|pl = 'Według firmy-odbiorcy będzie znaleziony ujemny stan magazynowy na koniec każdego %PresentationOfPeriodicityOfFormation% ze wskazanego okresu. Potem będą przeanalizowane ostatki właścicieli towarów i %PresentationOfGeneratedDocuments%. Najpierw będą rozchodowane wiersze pozycji, według których są utworzone rezerwy towarów firm.';
				|tr = 'Belirlenen dönemin her %PresentationOfPeriodicityOfFormation% sonunda alıcı iş yeri için negatif bakiyeler bulunacaktır. Daha sonra ürün sahiplerinin bakiyeleri ve %PresentationOfGeneratedDocuments% analiz edilecektir. İş yerlerinin ürün rezervlerinin oluşturulduğu ürünler ilk olarak silinecektir.'");
		Else
			ExplanationText =
			NStr("vi = 'Theo doanh nghiệp-chủ sở hữu sẽ tìm thấy số dư âm vào cuối mỗi %PresentationOfPeriodicityOfFormation% từ kỳ cụ thể. Sau đó, sẽ phân tích số dư của chủ sở hữu hàng hóa theo trình tự ưu tiên chúng và %PresentationOfGeneratedDocuments%.';
				|ru = 'По организации-владельцу будут найдены отрицательные остатки на конец каждого %PresentationOfPeriodicityOfFormation% из указанного периода. Затем будут проанализированы остатки владельцев товаров в порядке их приоритета и %PresentationOfGeneratedDocuments%.';
				|en = 'Negative balance at the end of each %PresentationOfPeriodicityOfFormation% within the specified period will be found for the owner company. Then stock balance of owners will be analyzed according to their priority and %PresentationOfGeneratedDocuments%.'; fa = 'Negative balance at the end of each %PresentationOfPeriodicityOfFormation% within the specified period will be found for the owner company. Then stock balance of owners will be analyzed according to their priority and %PresentationOfGeneratedDocuments%.';
				|it = 'Per la società-proprietario verranno trovati i saldi negativi per la fine di ciascuno %PresentationOfPeriodicityOfFormation% dei periodi specificati. In seguito verranno analizzati le rimanenze dei proprietari delle merci in ordine di priorità e %PresentationOfGeneratedDocuments%.';
				|pl = 'Według firmy- właściciela będzie znaleziony ujemny stan magazynowy na koniec każdego %PresentationOfPeriodicityOfFormation% ze wskazanego okresu. Potem będą przeanalizowane ostatki właścicieli towarów w kolejności ich priorytetu i %PresentationOfGeneratedDocuments%.';
				|tr = 'Belirtilen dönemdeki her %PresentationOfPeriodicityOfFormation% sonunda ürün sahibi iş yeri için negatif bakiyeler bulunacaktır. Daha sonra ürün sahiplerinin bakiyeleri öncelik sırasına ve %PresentationOfGeneratedDocuments% ''ne göre analiz edilecektir.'");
		EndIf;
		
		If DocumentGenerationFrequency = "ByDays" Then
			PresentationOfPeriodicityOfFormation = NStr("vi = 'ngày';
														|ru = 'дня';
														|en = 'day'; fa = 'روز';
														|it = 'del giorno';
														|pl = 'dnia';
														|tr = 'gün'");
		Else
			PresentationOfPeriodicityOfFormation = NStr("vi = 'tháng';
														|ru = 'месяца';
														|en = 'month'; fa = 'ماه';
														|it = 'del mese';
														|pl = 'miesiąca';
														|tr = 'ay'");
		EndIf;
		
		RightsIssues = New Array;
		
		If IssueRansoms(GeneratedDocuments_) 
			And Not AccessRight("Insert", Metadata.Documents.RedemptionOfGoodsFromStorage) Then
			IssueText = NStr("vi = 'Không đủ quyền để lập mua lại hàng hóa trong kho.';
							|ru = 'Недостаточно прав для формирования выкупов товаров на хранении.';
							|en = 'Insufficient rights to generate redemption of goods at storage.'; fa = 'Insufficient rights to generate redemption of goods at storage.';
							|it = 'Diritti insufficienti per generare il riscatto delle merci in deposito.';
							|pl = 'Niewystarczające uprawnienia dla utworzenia wykupów towarów na przechowaniu.';
							|tr = 'Ambardaki ürünlerin itfası için yetersiz erişim yetkileri.'");	
			RightsIssues.Add(IssueText);
		EndIf;
		
		If MakeTransfers(GeneratedDocuments_)
			And Not AccessRight("Insert", Metadata.Documents.CustomerInvoiceIntercompany) Then
			IssueText = NStr("vi = 'Không đủ quyền để lập chuyển hàng hóa giữa các doanh nghiệp.';
							|ru = 'Недостаточно прав для формирования передач товаров между организациями.';
							|en = 'Insufficient rights to generate intercompany goods transfers.'; fa = 'Insufficient rights to generate intercompany goods transfers.';
							|it = 'Diritti insufficienti per generare il trasferimento delle merci tra le società.';
							|pl = 'Niewystarczające uprawnienia dla utworzenia przekazań towarów między firmami.';
							|tr = 'iş yerleri arası müşteri faturası oluşturulması için yetersiz erişim yetkileri.'");	
			RightsIssues.Add(IssueText);
		EndIf;
		
		If IssueRansoms(GeneratedDocuments_)
			And MakeTransfers(GeneratedDocuments_) Then
			
			PresentationOfGeneratedDocuments = NStr("vi = 'lập việc chuyển giao hàng hóa giữa các doanh nghiệp và mua lại hàng hóa trong kho';
													|ru = 'сформированы передачи товаров между организациями и выкупы товаров на хранении';
													|en = 'Intercompany invoice and VMI transfers are generated'; fa = 'Intercompany invoice and VMI transfers are generated';
													|it = 'sono generati i trasferimenti delle merci tra le società e riscatti delle merci in deposito';
													|pl = 'utworzono przekazania towarów między firmami i wykupy towarów na przechowywaniu';
													|tr = 'iş yerleri arası müşteri faturası ve VMI satın alma faturası oluşturuldu'");
			TextOfFillButton = NStr("vi = 'Điền bên gửi hàng và doanh nghiệp';
									|ru = 'Заполнить поклажедателями и организациями';
									|en = 'Fill in with depositors and companies'; fa = 'Fill in with depositors and companies';
									|it = 'Inserire depositanti e società';
									|pl = 'Wypełnij deponentami i firmami';
									|tr = 'Mevduat sahibi ve iş yerleri tarafından doldur'");
			FillButtonHint = NStr("vi = 'Điền bên gửi hàng mà theo đó có số dư hàng hóa chưa được mua và bởi doanh nghiệp theo các tùy chỉnh chuyển';
									|ru = 'Заполнить поклажедателями, по которым есть остатки невыкупленных товаров, и организациями по настройкам передачи';
									|en = 'Fill in with depositors for which there is balance of non-purchased goods and with companies by transfer settings'; fa = 'Fill in with depositors for which there is balance of non-purchased goods and with companies by transfer settings';
									|it = 'Inserire i depositanti, per i quali vi sono le rimanenze delle merci in sofferenza e le società per le impostazioni di trasferimento';
									|pl = 'Wypełnij deponentami, według których są ostatki niewykupionych towarów, i firmami według ustawień przekazania';
									|tr = 'Transfer ayarlarına göre, satın alınmamış ürün bakiyesi olan mevduat sahipleri ve iş yerleriyle doldur'");
			
		ElsIf MakeTransfers(GeneratedDocuments_) Then
			
			PresentationOfGeneratedDocuments = NStr("vi = 'lập việc chuyển giao hàng hóa giữa các doanh nghiệp';
													|ru = 'сформированы передачи товаров между организациями';
													|en = '""Customer invoices — Intercompany"" are generated'; fa = '""Customer invoices — Intercompany"" are generated';
													|it = 'generati i trasferimenti delle merci tra le società';
													|pl = 'utworzono przekazania towarów między firmami';
													|tr = 'iş yerleri arası müşteri faturası oluşturuldu'");
			TextOfFillButton = NStr("vi = 'Điền doanh nghiệp';
									|ru = 'Заполнить организациями';
									|en = 'Fill in with companies'; fa = 'Fill in with companies';
									|it = 'Inserire le società';
									|pl = 'Wypełnij firmami';
									|tr = 'İş yerleri ile doldur'");
			FillButtonHint = NStr("vi = 'Điền doanh nghiệp cài đặt chuyển';
									|ru = 'Заполнить организациями по настройкам передачи';
									|en = 'Fill in with companies by transfer settings'; fa = 'Fill in with companies by transfer settings';
									|it = 'Inserire le società per le impostazioni di trasferimento';
									|pl = 'Wypełnij firmami według ustawień przekazania';
									|tr = 'İş yerlerini transfer ayarlarına göre doldur'");
			
		Else
			
			PresentationOfGeneratedDocuments = NStr("vi = 'lập mua lại hàng hóa trong kho';
													|ru = 'сформированы выкупы товаров на хранении';
													|en = 'redemptions of stocked goods are generated'; fa = 'redemptions of stocked goods are generated';
													|it = 'generati i riscatti delle merci in deposito';
													|pl = 'utworzono wykupy towarów na przechowywaniu';
													|tr = 'saklamadaki ürünlerin itfası oluşturuldu'");
			TextOfFillButton = NStr("vi = 'Điền bên gửi hàng';
									|ru = 'Заполнить поклажедателями';
									|en = 'Fill in with depositors'; fa = 'Fill in with depositors';
									|it = 'Inserire i depositanti';
									|pl = 'Wypełnij deponentami';
									|tr = 'Mevduat sahipleriyle doldur'");
			FillButtonHint = NStr("vi = 'Điền bên gửi hàng có số dư của hàng hóa không được nhận';
									|ru = 'Заполнить поклажедателями, по которым есть остатки невыкупленных товаров';
									|en = 'Fill in with depositors for which there is balance of non-purchased goods'; fa = 'Fill in with depositors for which there is balance of non-purchased goods';
									|it = 'Inserire i depositanti per i quali vi sono le rimanenze delle merci in sofferenza';
									|pl = 'Wypełnij deponentami, według których są ostatki niewykupionych towarów';
									|tr = 'İtfa edilmeyen ürün bakiyesi olan mevduat sahipleriyle doldur'");
			
		EndIf;
		
		If IssueRansoms(GeneratedDocuments_) Then
			Items.SelectedSendersAdd.Title = NStr("vi = 'Thêm doanh nghiệp';
													|ru = 'Добавить организацию';
													|en = 'Add company'; fa = 'افزودن شرکت';
													|it = 'Aggiungere una azienda';
													|pl = 'Dodaj firmę';
													|tr = 'İş yeri ekle'");
		Else
			Items.SelectedSendersAdd.Title = NStr("vi = 'Thêm';
													|ru = 'Добавить';
													|en = 'Add'; fa = 'افزودن';
													|it = 'Aggiungere';
													|pl = 'Add';
													|tr = 'Ekle'");
		EndIf;
		
		If MakeTransfers(GeneratedDocuments_) Then
			Items.SelectedSendersAddDepositor.Title = NStr("vi = 'Thêm bên gửi hàng';
															|ru = 'Добавить поклажедателя';
															|en = 'Add depositor'; fa = 'افزودن امانت‌گذار';
															|it = 'Aggiungere un depositante';
															|pl = 'Dodaj deponenta';
															|tr = 'Mevduat sahibi ekle'");
		Else
			Items.SelectedSendersAddDepositor.Title = NStr("vi = 'Thêm';
															|ru = 'Добавить';
															|en = 'Add'; fa = 'افزودن';
															|it = 'Aggiungere';
															|pl = 'Add';
															|tr = 'Ekle'");
		EndIf;
		
		Items.SelectedSendersAdd.Visible = MakeTransfers(GeneratedDocuments_);
		Items.SelectedSendersAddDepositor.Visible = IssueRansoms(GeneratedDocuments_);
		
		Items.SelectedSendersContract.Visible = UseIntercompanyContracts
														Or IssueRansoms(GeneratedDocuments_);
														
		Items.TransferSettings.Visible = MakeTransfers(GeneratedDocuments_);
		Items.DepositorsWithGoods.Visible = IssueRansoms(GeneratedDocuments_);
		
		ExplanationText = StrReplace(ExplanationText, "%PresentationOfPeriodicityOfFormation%", PresentationOfPeriodicityOfFormation);
		ExplanationText = StrReplace(ExplanationText, "%PresentationOfGeneratedDocuments%", PresentationOfGeneratedDocuments);
		
		Items.SettingsInformationCustomProductAlgorithmExplanation.Title = ExplanationText; 
		
		Commands.FillInTheTransferSettings.Title = TextOfFillButton;
		Commands.FillInTheTransferSettings.ToolTip = FillButtonHint;
		
		ThereIsProblemWithRights = RightsIssues.Count() > 0;
		
		If ThereIsProblemWithRights Then
			IssueText = NStr("vi = 'Liên hệ với quản trị viên của bạn để gán các quyền cần thiết. Không thể tiếp tục tạo chứng từ với cài đặt này.';
							|ru = 'Обратитесь к администратору для назначения необходимых прав. Продолжить формирование документов с такой настройкой невозможно.';
							|en = 'Please contact the administrator to assign the required rights. You cannot continue document generation with this setting.'; fa = 'Please contact the administrator to assign the required rights. You cannot continue document generation with this setting.';
							|it = 'Per assegnare i diritti necessari contattare l''amministratore. È impossibile continuare la generazione dei documenti con questa impostazione.';
							|pl = 'Zwróć się do administratora dla wyznaczenia koniecznych uprawnień. Kontynuowanie utworzenia dokumentów z takim ustawieniem jest niemożliwe.';
							|tr = 'Gerekli erişim hakları atamak için yöneticiye başvur. Bu ayarla belge oluşturmaya devam etmek mümkün değildir.'");	
			RightsIssues.Add(IssueText);
			TextOfRightsIssue = StrConcat(RightsIssues, " ");
			Items.SettingsInformationItsOwnProductsToProblemWithTheRights.Title = TextOfRightsIssue;
		EndIf;
		
		Items.SettingsInformationItsOwnProductsToProblemWithTheRights.Visible = ThereIsProblemWithRights;
		
	Else
		Items.SettingsInventoryTypes.CurrentPage = Items.SettingsInventoryTypesConsignedGoods;
		ThereIsProblemWithRights = Not AccessRight("Insert", Metadata.Documents.CustomerInvoiceIntercompany);
		Items.SettingsInformationCommissionTheGoodsTheProblemWithTheRights.Visible = ThereIsProblemWithRights;
	EndIf;	
	
	Items.Create.Enabled = Not ThereIsProblemWithRights;
EndFunction

&AtClient
Procedure SetVisibilityOfInformationOnPageOfCreatedDocuments(TheCalculationIsPerformed)
	
	If TheCalculationIsPerformed Then
			
		ProblemRemained = ProblematicOrganizations.FindRows(New Structure("Organization,InventoryType", Organization, InventoryType)).Count() > 0;
		
		Items.ResultsInformationThereAreUnverifiedDocuments.Visible = DocumentGenerationCanceled 
																				And Not AllDocumentsArePosted
																				And ProblemRemained;
																				
		Items.ResultsInformationToContinueBuilding.Visible = DocumentGenerationCanceled
																				And AllDocumentsArePosted
																				And ProblemRemained;
																				
		Items.ToContinueTheFormation.Visible = DocumentGenerationCanceled
													And ProblemRemained;
													
		Items.ToContinueTheFormation.Enabled = AllDocumentsArePosted;
		
		Items.ResultsInformationThereAreNegativeBalances.Visible = Not DocumentGenerationCanceled 
																			And ProblemRemained;
																			
		Items.ResultsInformationNoNegativeBalances.Visible = Not ProblemRemained;
		
		Items.Done.Visible = Not ProblemRemained;
		
		Items.ContinueWithNewSelections.Visible = Not (DocumentGenerationCanceled And ProblemRemained)
													   And RunMode <> "CorrectNegativeBalance";
	
	Else
		
		Items.ResultsInformationThereAreUnverifiedDocuments.Visible = False;
		Items.ResultsInformationToContinueBuilding.Visible     = False;
		Items.ResultsInformationThereAreNegativeBalances.Visible   = False;
		Items.ResultsInformationNoNegativeBalances.Visible   = False;
		
	EndIf;
	
	Items.CreatedDocuments.Enabled             = TheCalculationIsPerformed;
	Items.ResultsInformationIsGenerated.Visible  = Not TheCalculationIsPerformed;
	
EndProcedure

&AtServer
Function FillInDataAndConfigureSettingsPage()
	
	ConfigureSettingsPage();
	
	BackgroundJob = Undefined;
	
	If InventoryType = Enums.InventoryTypes.OwnGoods Then 
		
		If MakeTransfers(GeneratedDocuments_) Then
			CommonClientServer.SetDynamicListFilterItem(TransferSettings,
				"CompanyCustomer",
				Organization,
				DataCompositionComparisonType.Equal);
			
			CommonClientServer.SetDynamicListFilterItem(TransferSettings,
				"GoodsTransferMethod",
				Enums.GoodsTransferMethods.Sale,
				DataCompositionComparisonType.Equal);
			
		EndIf;
		
		If IssueRansoms(GeneratedDocuments_) Then																		
			BackgroundJob = FillInSendersServer("DepositorsWithGoods");
		EndIf;
		
		UploadSelectedSenders();
		
	Else
		BackgroundJob = FillInConsignorsServer()
	EndIf;
	
	Return BackgroundJob;
	
EndFunction

&AtServer
Function CheckSenders()
	
	Result = True;
	
	If InventoryType = Enums.InventoryTypes.OwnGoods Then
		
		If SenderSelectionOption = "AccordingToSpecifiedPriorities" Then
			If Object.SelectedSenders.Count() = 0 Then
				MessageText = NStr("vi = 'Chọn người gửi.';
									|ru = 'Выберите отправителей.';
									|en = 'Select senders.'; fa = 'Select senders.';
									|it = 'Selezionare i mittenti.';
									|pl = 'Wybierz nadawców.';
									|tr = 'Göndericileri seç.'");
				CommonClientServer.MessageToUser(MessageText,,"SelectedSenders","Object");
				Return False;
			EndIf;
			
			EconomicOperationsOfRedemption = DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.EconomicOperationsOfRedemption();
			
			Cancel = False;
			DataProcessorObject = FormAttributeToValue("Object");
			
			TMCommonUse.CheckForDuplicatesOfTSStrings(DataProcessorObject,
				"SelectedSenders","Sender,PricesKind,Contract,InventoryType", Cancel);
				
			If Cancel Then
				Return False;
			EndIf;
			
			For Each RowOfTables In Object.SelectedSenders Do
				If Not IssueRansoms(GeneratedDocuments_) 
					Or EconomicOperationsOfRedemption.Find(RowOfTables.BusinessOperation) = Undefined Then
					
					If Not ValueIsFilled(RowOfTables.Sender) Then
						MessageText = NStr("vi = 'Chỉ định người gửi';
											|ru = 'Укажите отправителя';
											|en = 'Specify sender'; fa = 'Specify sender';
											|it = 'Specificare il mittente';
											|pl = 'Wskaż nadawcę';
											|tr = 'Göndericiyi belirt'");
						
						Result = False;
						Field = CommonClientServer.PathToTabularSection("SelectedSenders", RowOfTables.LineNumber, "Sender");
						CommonClientServer.MessageToUser(MessageText,,Field,"Object");
						
					EndIf;
					
					If Not ValueIsFilled(RowOfTables.PricesKind) Then
						MessageText = NStr("vi = 'Chỉ định dạng giá chuyển nhượng';
											|ru = 'Укажите вид цен передачи';
											|en = 'Specify a transfer price type'; fa = 'Specify a transfer price type';
											|it = 'Specificare il tipo di prezzi di trasferimento';
											|pl = 'Wskaż rodzaj ceny przekazania';
											|tr = 'Transfer fiyatlarının türünü belirt'");	
						Result = False;
						Field = CommonClientServer.PathToTabularSection("SelectedSenders", RowOfTables.LineNumber, "PricesKind");
						CommonClientServer.MessageToUser(MessageText,,Field,"Object");
					EndIf;
					
					If UseIntercompanyContracts
						And Not ValueIsFilled(RowOfTables.Contract) Then
						MessageText = NStr("vi = 'Chỉ định hợp đồng';
											|ru = 'Укажите договор';
											|en = 'Specify contract'; fa = 'Specify contract';
											|it = 'Specificare l''accordo';
											|pl = 'Wskaż kontrakt';
											|tr = 'Sözleşmeyi belirt'");	
						Result = False;
						Field = CommonClientServer.PathToTabularSection("SelectedSenders", RowOfTables.LineNumber, "Contract");
						CommonClientServer.MessageToUser(MessageText,,Field,"Object");
					EndIf;
					
					If Not ValueIsFilled(RowOfTables.InventoryType) Then
						MessageText = NStr("vi = 'Cho biết loại hàng tồn kho được chuyển';
											|ru = 'Укажите передаваемый тип запасов';
											|en = 'Specify transferred inventory type'; fa = 'Specify transferred inventory type';
											|it = 'Specificare il tipo delle scorte in trasferimento';
											|pl = 'Wskaż przekazywany typ zapasów';
											|tr = 'Transfer edilecek stok türünü belirt'");	
						Result = False;
						Field = CommonClientServer.PathToTabularSection("SelectedSenders", RowOfTables.LineNumber, "InventoryType");
						CommonClientServer.MessageToUser(MessageText,,Field,"Object");
					EndIf;
					
				EndIf;
			EndDo;
			
		ElsIf MakeTransfers(GeneratedDocuments_) Then
			
			QueryOptions = New Structure();
			QueryOptions.Insert("Organization", Organization);
			QueryOptions.Insert("MakeTransfers", MakeTransfers(GeneratedDocuments_));
			QueryOptions.Insert("IssueRansoms", False);
			QueryOptions.Insert("InventoryType",  InventoryType);
			QueryOptions.Insert("GeneratedDocuments_", GeneratedDocuments_);
			TransferSettingsTable = 
				DataProcessors.GenerationOfIntercompanyCustomerInvoicesAndRedemption.GetTableForTransmissionSettings(QueryOptions);
			
			For Each RowOfTables In TransferSettingsTable Do
				
				If Not ValueIsFilled(RowOfTables.PricesKind) Then
					MessageText = NStr("vi = 'Chỉ định dạng giá trong cài đặt chuyển từ doanh nghiệp %Sender%';
										|ru = 'Укажите вид цен в настройках передачи от организации %Sender%';
										|en = 'Specify price type in settings of transfer from the %Sender% company'; fa = 'Specify price type in settings of transfer from the %Sender% company';
										|it = 'Specificare il tipo di prezzi nelle impostazioni di trasferimento dalla società %Sender%';
										|pl = 'Podaj rodzaj ceny w ustawieniach przekazania od firmy%Sender%';
										|tr = '%Sender% iş yerinden yapılan transfer için ayarlarda fiyat türünü belirt'");	
					MessageText = StrReplace(MessageText, "%Sender%", RowOfTables.Sender);
					Result = False;
					CommonClientServer.MessageToUser(MessageText);
				EndIf;
				
				If UseIntercompanyContracts
					And Not ValueIsFilled(RowOfTables.Contract) Then
					MessageText = NStr("vi = 'Hãy chỉ ra hợp đồng trong các tùy chỉnh chuyển từ doanh nghiệp %Sender%';
										|ru = 'Укажите договор в настройках передачи от организации %Sender%';
										|en = 'Specify contract in the settings of transfer from the %Sender% company'; fa = 'Specify contract in the settings of transfer from the %Sender% company';
										|it = 'Specificare un accordo nelle impostazioni di trasferimento dalla società %Sender%';
										|pl = 'Podaj kontrakt w ustawieniach przekazania od firmy %Sender%';
										|tr = 'İş yeri %Sender%''den transfer ayarlarında sözleşmeyi belirt'");	
					MessageText = StrReplace(MessageText, "%Sender%", RowOfTables.Sender);
					Result = False;
					CommonClientServer.MessageToUser(MessageText);
				EndIf;
			EndDo;
			
		EndIf;
		
	Else	
		
		For Each RowOfTables In SendersByFee Do
			
			If Not ValueIsFilled(RowOfTables.PricesKind) Then
				MessageText = NStr("vi = 'Hãy chỉ ra dạng giá trong các tùy chỉnh chuyển';
									|ru = 'Укажите вид цен в настройках передачи';
									|en = 'Specify a price type in transfer settings'; fa = 'Specify a price type in transfer settings';
									|it = 'Specificare il tipo di prezzi nelle impostazioni di trasferimento';
									|pl = 'Podaj rodzaj ceny w ustawieniach przekazania';
									|tr = 'Transfer ayarlarında fiyat türünü belirt'");	
				Result = False;
				Field = CommonClientServer.PathToTabularSection("SendersByFee",
																	SendersByFee.IndexOf(RowOfTables) + 1,
																	"PricesKind");
				CommonClientServer.MessageToUser(MessageText,,Field);
			EndIf;
			
			If UseIntercompanyContracts
				And Not ValueIsFilled(RowOfTables.Contract) Then
				MessageText = NStr("vi = 'Hãy chỉ ra hợp đồng trong các tùy chỉnh chuyển';
									|ru = 'Укажите договор в настройках передачи';
									|en = 'Specify a contract in transfer settings'; fa = 'Specify a contract in transfer settings';
									|it = 'Specificare l''accordo nelle impostazioni di trasferimento';
									|pl = 'Podaj kontrakt w ustawieniach przekazania';
									|tr = 'Transfer ayarlarında sözleşmeyi belirt'");	
				Result = False;
				Field = CommonClientServer.PathToTabularSection("SendersByFee",
																	SendersByFee.IndexOf(RowOfTables) + 1,
																	"Contract");
				CommonClientServer.MessageToUser(MessageText,,Field);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Function PlaceDepositorsWithGoodsInTemporaryStorage() 
	
	Return PutToTempStorage(DepositorsWithGoods.Unload(), UUID);

EndFunction

&AtServer
Procedure InitializeResidueCorrectionMode()
	
	RunMode = "CorrectNegativeBalance";
	DataCompositionClientServer.AddFilter(
		FilterOfProductItem, 
		"Warehouse", 
		Parameters.FilterWarehouses, 
		DataCompositionComparisonType.InList);
	DataCompositionClientServer.AddFilter(
		FilterOfProductItem, 
		"Products", 
		Parameters.FilterProducts, 
		DataCompositionComparisonType.InList);
	ProblematicOrganizationsLine = ProblematicOrganizations.Add();
	ProblematicOrganizationsLine.Organization = Parameters.Organization;
	ProblematicOrganizationsLine.InventoryType = Parameters.InventoryType;
	Organization = Parameters.Organization;
	InventoryType = Parameters.InventoryType;
	For Each Source In SourceParameters_1() Do
		SenderRow = Object.SelectedSenders.Add();
		SenderRow.Sender = Source.Sender;
		SenderRow.InventoryType = Source.InventoryType;
		SenderRow.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.GoodsSaleToAnotherCompany");
		SenderRow.PricesKind  = PredefinedValue("Catalog.TypesOfPrices.EmptyRef");
		SenderRow.Contract = PredefinedValue("Catalog.IntercompanyContracts.EmptyRef");
	EndDo;
	Items.SettingsHeader.Title = NStr("vi = 'Thiết lập tạo chứng từ theo gói';
										|ru = 'Настройка пакетного формирования документов';
										|en = 'Set up batch document generation'; fa = 'Set up batch document generation';
										|it = 'Configurazione della generazione di documenti a pacchetto';
										|pl = 'Ustawienie utworzenia pakietów dokumentów';
										|tr = 'Belgelerin toplu olarak oluşturulma ayarları'");
	Items.ResultsTitle.Title = NStr("vi = 'Chứng từ đã tạo';
									|ru = 'Созданные документы';
									|en = 'Created documents'; fa = 'اسناد ایجادشده';
									|it = 'Documenti creati';
									|pl = 'Utworzone dokumenty';
									|tr = 'Oluşturulmuş belgeler'");
	Items.ProblemsInformationIsGenerated.Visible = False;
	Items.ProblemsInformationThereAreNegativeBalances.Visible = True;
	Items.ProblemsInformationNoNegativeBalances.Visible = False;
	Items.ToRecipientCompanySelection.Visible = False;
	Items.GoToGenerationSettings.Enabled = True;
	Items.ProblematicOrganizations.Enabled = True;
	Items.Main.CurrentPage = Items.Settings;
	Items.Create.DefaultButton = True;
	SenderSelectionOption = "AccordingToSpecifiedPriorities";
	ConfigureSettingsPage();

EndProcedure

// Returns:
// 	Array of Structure:
// 		* Sender - CatalogRef.Companies
// 		* InventoryType - EnumRef.InventoryTypes
//
&AtServer
Function SourceParameters_1()
	
	Return Parameters.Sources;
	
EndFunction

#EndRegion
