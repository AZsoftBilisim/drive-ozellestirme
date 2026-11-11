#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CheckAccessPermission(Cancel);
	InitializeHelper();
	
EndProcedure

&AtServer
Procedure InitializeHelper()
	
	DataProcessorObject = FormAttributeToValue("Object");
	DetailedBalanceCorrectionOption = "GenerateCorrectionsToExpandedBalance";
	ThisIsTradeManagementBasic = GetFunctionalOption("BaseVersion")
									And GetFunctionalOption("TradeManagement");
	IsExternalDataProcessor = TypeOf(DataProcessorObject) <> Type("DataProcessorObject.WizardOfCorrectingCompanyStockBalance");
	AddressOfAdditionalParametersOfRegistrationControlResult = PutToTempStorage(Undefined,
																								UUID);
	
	If Constants.ControlCompanyStockBalance.Get() Then
		PostInitialValueWithoutControl = SessionParameters.PostWithoutControlOfCompanyStockBalance;
	EndIf;
	ProductionIsUsed = ProductionIsUsed();
	ExcisableGoodsAreUsed = GetFunctionalOption("UseExcisableGoods");
	Items.DecorationDiagnosisOfNegativeBalancesOtherSolutions3.Visible = True;
	If ThisIsTradeManagementBasic Then
		TextAssistantDescription = NStr("vi = '1. Phân tích và hiển thị thông tin chi tiết về lỗi
										|2. Lập các chứng từ còn thiếu theo dữ liệu kế toán kho
										|3. Lập lại dự phòng theo số dư âm
										|4. Chỉnh sửa số dư chi tiết
										|5. Lập chứng từ ghi tăng hàng hóa';
										|ru = '1. Анализ и вывод подробной информации о проблемах
										|2. Оформление недостающих документов по данным складского учета
										|3. Переформирование резервов по отрицательным остаткам
										|4. Исправление развернутого сальдо
										|5. Оформление оприходований товаров';
										|en = '1. Analyze and display detailed information on issues.
										|2. Register missing documents according to warehouse accounting data.
										|3. Rebuild reserves of negative balance.
										|4. Adjust detailed balance.
										|5. Register goods recording as received.'; fa = '1. Analyze and display detailed information on issues.
										|2. Register missing documents according to warehouse accounting data.
										|3. Rebuild reserves of negative balance.
										|4. Adjust detailed balance.
										|5. Register goods recording as received.';
										|it = '1. Analisi e visualizzazione dell''informazione circa i problemi
										|2. Registrazione documenti non indicati in base ai dati della contabilità di magazzino
										|3. Nuova registrazione delle riserve per saldi negativi
										|4.Correzione saldo esplicativo
										|5. Registrazione accettazione articoli';
										|pl = '1. Analiza i wyświetlanie szczegółowych informacji o problemach
										|2. Projekt brakujących dokumentów, wg danych ewidencji magazynowej
										|3. Przekształcanie rezerw wg ujemnych sald
										|4. Poprawka salda rozwartego
										|5. Rejestracja przyjęć zewnętrznych';
										|tr = '1. Sorunlar hakkında detaylı bilgi analizi ve çıktısı
										|2. Ambar muhasebe verilerine göre eksik belgelerin düzenlenmesi
										|3. Negatif bakiyeler için rezervlerin yeniden oluşturulması
										|4. Katlanmamış bakiyenin düzeltilmesi
										|5. Ürünlerin teslim alınmasının kaydı'");
		TextStep6Title = NStr("vi = 'Bước 5. Lập chứng từ ghi tăng hàng hóa';
								|ru = 'Шаг 5. Оформление оприходований товаров';
								|en = 'Step 5. Register goods receipt'; fa = 'Step 5. Register goods receipt';
								|it = 'Fase 5. Registrazione accettazione articoli';
								|pl = 'Krok 5. Rejestracja przyjęć zewnętrznych';
								|tr = 'Aşama 5. Ürünlerin teslim alınmasının kaydı'");
		
		Items.DecorationTitleStep6.Title = TextStep6Title;
		Items.DecorationStep0Description2.Title = TextAssistantDescription;
	EndIf;
	
	If ExcisableGoodsAreUsed Then
		WarningText = NStr("vi = 'Số tiền thuế TTĐB';
							|ru = ', суммы акциза';
							|en = ', excise amount'; fa = ', excise amount';
							|it = ', excise amount';
							|pl = ', excise amount';
							|tr = ', tüketim vergisi tutarları'");
	Else
		WarningText = "";
	EndIf;
	Items.GroupStep4ExplanationOfOption2Subgroup2AdditionalExplanation.Title = StrReplace(
		Items.GroupStep4ExplanationOfOption2Subgroup2AdditionalExplanation.Title,
		"%WarningAboutChangesInAmountOfExciseDuty%",
		WarningText);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	CustomizeFormElements();
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Not Exit Then
		InstallProgramWithoutControlOnServer(PostInitialValueWithoutControl);
	EndIf;
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure TransferSettingsBetweenOrganizationsSelection(Item, RowSelected, Field, StandardProcessing)
	
	FormOpenParameters = New Structure;
	Var_Key = TransferSettingsKey(
		Item.CurrentData.Owner, 
		Item.CurrentData.Seller, 
		Item.CurrentData.InventoryTypeOfOwner);
	If Var_Key = Undefined Then
		FillingValues = New Structure;
		FillingValues.Insert("CompanyOwner", Item.CurrentData.Owner);
		FillingValues.Insert("CompanyCustomer", Item.CurrentData.Seller);
		FillingValues.Insert("InventoryType", Item.CurrentData.InventoryTypeOfOwner);
		FillingValues.Insert("GoodsTransferMethod", PredefinedValue("Enum.GoodsTransferMethods.NotTransferred"));
		FormOpenParameters.Insert("FillingValues", FillingValues);
	Else
		FormOpenParameters.Insert("Key", Var_Key);
	EndIf;
	OpenForm(
		"InformationRegister.CustomizeCustomerInvoiceIntercompany.RecordForm",
		FormOpenParameters,
		ThisForm,,,,
		New CallbackDescription("CreatePresentationOfRecordingTransferSettings", ThisForm));
	
EndProcedure

&AtClient
Procedure NumberOfPositionsNegativeBalanceClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpenNegativeBalancesOnClientReport();
EndProcedure

&AtClient
Procedure ItemQuantitySidedBalanceClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpenExpandedBalanceOnClientReport();
EndProcedure

&AtClient
Procedure DecorationDiagnosisOfNegativeBalancesOtherSolutions2URLProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = False;
	If FormattedStringURL = "RegisterSubcontractorReports" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CurrentPageName", "ReportsPage");
		FormParameters.Insert("RegistrationPeriod",  BegOfMonth(Object.MonthOfCorrection));
		FormParameters.Insert("CheckedPeriod",  BegOfMonth(Object.MonthOfCorrection));
		FormParameters.Insert("Filter",              New Structure("BeginOfPeriod, EndOfPeriod", BegOfMonth(Object.MonthOfCorrection), EndOfMonth(Object.MonthOfCorrection)));
		
		OpenForm("DataProcessor.DocumentsOfTransferToTollingAll2_5.Form.ToRegisterInvoices", FormParameters, ThisObject);
		
	EndIf;
EndProcedure

&AtClient
Procedure DecorationDiagnosisOfNegativeBalancesOtherSolutions3URLProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = False;
	If FormattedStringURL = "RegistrationOfGiversReports" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CurrentPageName", "ReportsPage");
		FormParameters.Insert("RegistrationPeriod",  BegOfMonth(Object.MonthOfCorrection));
		FormParameters.Insert("CheckedPeriod",  BegOfMonth(Object.MonthOfCorrection));
		FormParameters.Insert("Filter",              New Structure("BeginOfPeriod, EndOfPeriod", BegOfMonth(Object.MonthOfCorrection), EndOfMonth(Object.MonthOfCorrection)));
		
		OpenForm("DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices", FormParameters, ThisObject);
		
	EndIf;
EndProcedure

&AtClient
Procedure Step2ReportOnMissingDocumentsDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	StandardProcessing = False;
	
	If TypeOf(Details) = Type("DataCompositionDetailsID") Then
		AvailableAction = New Array;
		AvailableAction.Add(DataCompositionDetailsProcessingAction.OpenValue);
		DetailProcessing = New DataCompositionDetailsProcess(
			RegistrationControlResultExplanationDataAddress, 
			New DataCompositionAvailableSettingsSource(RegistrationControlResultSchemeAddress));
	    DetailProcessing.ShowActionChoice(
		    New CallbackDescription("HandlingSelectionOfDecryptionAction", ThisForm),
		    Details,
			AvailableAction,,
			True,
			Item);
	ElsIf TypeOf(Details) = Type("String") Then
		ReportsTMClientOverridable.ProcessDecryptionControlOfRegistrationOfDocumentsOfCommodityMovement(
			ThisForm, Details, "NotificationsAboutClosureOfWorkplaceForProcessingDocuments",
			CurrentServerDate(), Object.FiltersToGenerateControlReport);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToTheSettingsForTransferringProductsBetweenOrganizationsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	CheckRoleNSISetupIsAvailable(StandardProcessing);
EndProcedure

&AtClient
Procedure ControlOfDesignDetailOnPositionsOnChange(Item)
	MethodParameters_ = New Structure;
	MethodParameters_.Insert("ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement", New Array);
	MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement.Add(
		AddressOfAdditionalParametersOfRegistrationControlResult);
	MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement.Add(
		ControlOfDesignDetailOnPositions);
	ExecuteObjectMethods(
		"UpdateDataOnNegativeBalancesAndBalances, ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement",
		MethodParameters_,
		"CompleteFormationOfRegistrationControlResult");
EndProcedure

&AtClient
Procedure DecorationStep6SeeAlsoURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If FormattedStringURL = "RegisterBackflushProduction" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("RegistrationPeriod", Object.MonthOfCorrection);
		
		OpenForm("DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm", FormParameters, ThisObject);
		
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NavigationBack(Command)
	SwitchPage(-1);
EndProcedure

&AtClient
Procedure NavigateNext(Command)
	SwitchPage(1);
EndProcedure

&AtClient
Procedure NavigationGoToTheBeginning(Command)
	If Object.NumberOfPositionsNegativeBalance
		Or Object.ItemQuantitySidedBalance Then
		StartSwitchingToPage(1);
	Else
		ExecuteObjectMethods(
			"Initialize, FillInMonthOfCorrection, UpdateDataOnNegativeBalancesAndBalances",,
			"CompletePageSwitching", 
			New Structure("PageNumber", 1));
	EndIf;
EndProcedure

&AtClient
Procedure NavigationClose(Command)
	Close();
EndProcedure

&AtClient
Procedure UpdateData1(Command)
	
	PageNumber = Number(StrReplace(Items.GroupPages.CurrentPage.Name, "GroupStep", ""));
	If PageNumber = 2 Then
		MethodParameters_ = New Structure;
		MethodParameters_.Insert("ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement", New Array);
		MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement.Add(
			AddressOfAdditionalParametersOfRegistrationControlResult);
		MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement.Add(
			ControlOfDesignDetailOnPositions);
		ExecuteObjectMethods(
			"UpdateDataOnNegativeBalancesAndBalances, ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement",
			MethodParameters_,
			"CompleteFormationOfRegistrationControlResult");
	ElsIf PageNumber = 3 Then
		ExecuteObjectMethods("UpdateDataOnNegativeBalancesAndBalances, ReFormationOfReservesIsNotRequired");
	ElsIf PageNumber = 4 Then
		ExecuteObjectMethods("UpdateDataOnNegativeBalancesAndBalances, CorrectionOfUnfoldedBalanceIsRequired");
	ElsIf PageNumber = 6 Then
		ExecuteObjectMethods("UpdateDataOnNegativeBalancesAndBalances, FillOutOrdersForRegistrationOfRegistrationForms");
	Else
		ExecuteObjectMethods("UpdateDataOnNegativeBalancesAndBalances");
	EndIf;
	
EndProcedure

&AtClient
Procedure StartReserveRegeneration(Command)
	ExecuteObjectMethods(
		"CreateNewReserves, 
		|UpdateDataOnNegativeBalancesAndBalances, 
		|ReFormationOfReservesIsNotRequired");
EndProcedure

&AtClient
Procedure OpenListOfGeneratedAdjustments(Command)
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Filter", New Structure);
	FormOpenParameters.Filter.Insert("Ref", New Array);
	FilterArray = FormOpenParameters.Filter.Ref; // Array
	For Each Page1 In Object.ReserveAdjustments Do
		FilterArray.Add(Page1.Document);
	EndDo;
	OpenForm("Document.RegisterAdjustment.ListForm", FormOpenParameters, ThisForm);
EndProcedure

&AtClient
Procedure OpenTheReportNegativeProductBalancesOfOrganizations(Command)
	OpenNegativeBalancesOnClientReport();
EndProcedure

&AtClient
Procedure ToOpenTheReportADetailedBalanceOnTheStockTypesAndNumbersOfGTD(Command)
	OpenExpandedBalanceOnClientReport();
EndProcedure

&AtClient
Procedure StartCorrectingTheExpandedBalance(Command)
	ExecuteObjectMethods(
		DetailedBalanceCorrectionOption + ",
		|UpdateDataOnNegativeBalancesAndBalances,
		|CorrectionOfUnfoldedBalanceIsRequired");
EndProcedure

&AtClient
Procedure OpenTheListOfGeneratedCorrectionsForProductBalancesOfOrganizations(Command)
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Filter", New Structure);
	FormOpenParameters.Filter.Insert("Ref", New Array);
	FilterArray = FormOpenParameters.Filter.Ref; // Array
	For Each Page1 In Object.CorrectionsOfStockBalanceOfCompanies Do
		FilterArray.Add(Page1.Document);
	EndDo;
	OpenForm("Document.CorrectionOfSidedBalanceInCompanyGoodsAccounting.ListForm", FormOpenParameters, ThisForm);
EndProcedure

&AtClient
Procedure OpenListOfChangedDocuments(Command)
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("RowChoiceMode", "OpenObjectForm");
	FormOpenParameters.Insert("Filter", New Structure);
	FormOpenParameters.Filter.Insert("Ref", New Array);
	FilterArray = FormOpenParameters.Filter.Ref; // Array
	For Each Page1 In Object.ModifiedDocuments Do
		FilterArray.Add(Page1.Document);
	EndDo;
	OpenForm("InformationRegister.DocumentsRegistry.ListForm", FormOpenParameters, ThisForm);
EndProcedure

&AtClient
Procedure LaunchTheAssistantForGeneratingTransfersAndPurchasesOfGoods(Command)
	
	ParametersForOpeningGenerationAssistant = New Structure;
	ParametersForOpeningGenerationAssistant.Insert("RunMode", "CorrectNegativeBalance");
	ParametersForOpeningGenerationAssistant.Insert("MonthOfCorrection", Object.MonthOfCorrection);
	ParametersForOpeningGenerationAssistant.Insert("Organization", Items.CompaniesForTransferGeneration.CurrentData.Organization);
	ParametersForOpeningGenerationAssistant.Insert("InventoryType", Items.CompaniesForTransferGeneration.CurrentData.InventoryType);
	ParametersForOpeningGenerationAssistant.Insert("Sources", New Array);
	For Each Page1 In Object.NewCustomizationCustomerInvoiceIntercompany Do
		If Page1.Seller = Items.CompaniesForTransferGeneration.CurrentData.Organization Then
			ParametersForOpeningGenerationAssistant.Sources.Add(New Structure("Sender, InventoryType", Page1.Owner, Page1.InventoryTypeOfOwner));
		EndIf;
	EndDo;
	ParametersForOpeningGenerationAssistant.Insert("FilterProducts", New ValueList);
	ParametersForOpeningGenerationAssistant.Insert("FilterWarehouses", New ValueList);
	For Each Page1 In Object.FiltersForTransferGeneration Do
		If Page1.Organization = Items.CompaniesForTransferGeneration.CurrentData.Organization 
			And Page1.InventoryType = Items.CompaniesForTransferGeneration.CurrentData.InventoryType Then
			ParametersForOpeningGenerationAssistant.FilterProducts.Add(Page1.Products);
			ParametersForOpeningGenerationAssistant.FilterWarehouses.Add(Page1.Warehouse);
		EndIf;
	EndDo;
	OpenForm(
		"DataProcessor.GenerationOfIntercompanyCustomerInvoicesAndRedemption.Form",
		ParametersForOpeningGenerationAssistant,
		ThisForm,,,,
		New CallbackDescription("NotificationOfClosureOfTransferGenerationAssistant", ThisForm),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure StartReserveGenerationByNewSettings(Command)
	If Not CheckFilling() Then
		Return;
	EndIf;
	ExecuteObjectMethods(
		"CreateNewReservesForNewSettings,
		|UpdateDataOnNegativeBalancesAndBalances,
		|FillInNewTransferSettings");
EndProcedure

&AtClient
Procedure OpenListOfGeneratedAdjustmentsByNewSettings(Command)
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Filter", New Structure);
	FormOpenParameters.Filter.Insert("Ref", New Array);
	FilterArray = FormOpenParameters.Filter.Ref; // Array
	For Each Page1 In Object.ReserveAdjustmentsByNewSettings Do
		FilterArray.Add(Page1.Document);
	EndDo;
	OpenForm("Document.RegisterAdjustment.ListForm", FormOpenParameters, ThisForm);
EndProcedure

&AtClient
Procedure RegisterRecordingAsReceived(Command)
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Basis", New Structure);
	FormOpenParameters.Basis.Insert("WizardOfCorrectingCompanyStockBalance");
	FormOpenParameters.Basis.Insert("Date", Object.MonthOfCorrection);
	FormOpenParameters.Basis.Insert("Organization", Items.ReferencesForGeneratingOfGoodsReceipt.CurrentData.Organization);
	FormOpenParameters.Basis.Insert("Warehouse", Items.ReferencesForGeneratingOfGoodsReceipt.CurrentData.Warehouse);
	FormOpenParameters.Basis.Insert("Goods", New Array);
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Organization", Items.ReferencesForGeneratingOfGoodsReceipt.CurrentData.Organization);
	TheStructureOfTheSearch.Insert("Warehouse", Items.ReferencesForGeneratingOfGoodsReceipt.CurrentData.Warehouse);
	RowsFillData = Object.DataForFillingReceipts.FindRows(TheStructureOfTheSearch);
	ArrayProducts = FormOpenParameters.Basis.Goods; // Array
	For Each RowFillingData In RowsFillData Do
		RowProducts_ = New Structure("ItemsLocationAttributes, Products, Characteristic, Purpose, CCDNumber, Series, InventoryOwnerAttribute, Count");
		FillPropertyValues(RowProducts_, RowFillingData);
		ArrayProducts.Add(RowProducts_);
	EndDo;
	OpenForm(
		"Document.InventorySurplusRecognition.ObjectForm", 
		FormOpenParameters, 
		ThisForm,,,,
		New CallbackDescription("NotificationAboutClosingRegistrationForm", ThisForm));
EndProcedure

&AtClient
Procedure ArrangeProductionWithoutOrder(Command)
	CurrentData = Items.ReferencesForGeneratingOfGoodsReceipt.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DocumentParameters_ = ProductionClientServer.ParametersForFormationOfProductionDocumentsWithoutOrders();
	DocumentParameters_.RegistrationPeriod = Object.MonthOfCorrection;
	DocumentParameters_.AutoFill = True;
	
	DocumentParameters_.ListOfData.Add("RecyclableWaste");
	DocumentParameters_.ListOfData.Add("MaterialsAndServices");
	DocumentParameters_.ListOfData.Add("LaborCosts");
	
	DocumentForm = GetForm("Document.BackflushProduction.ObjectForm",, ThisForm);
	DocumentParameters_.FormObjects.Insert("BackflushProduction", DocumentForm.Object);
	
	Result = ArrangeProductionWithoutOrderOnServer(CurrentData.GetID(), DocumentParameters_);
	If Not Result = Undefined Then
		CallbackDescription = New CallbackDescription("NotificationOfClosureOfProductionFormWithoutOrders", ThisForm);
		ProductionClient.ProcessGeneratedDocuments(ThisForm, Result, True, CallbackDescription);
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure GenerateReplacementTaxInvoices(Command)
	ExecuteObjectMethods("GenerateReplacementTaxInvoices");
EndProcedure

&AtClient
Procedure OpenTheListOfGeneratedCorrectiveInvoices(Command)
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("RowChoiceMode", "OpenObjectForm");
	FormOpenParameters.Insert("Filter", New Structure);
	FormOpenParameters.Filter.Insert("Ref", New Array);
	FilterArray = FormOpenParameters.Filter.Ref; // Array
	For Each Page1 In Object.ReplacementTaxInvoices Do
		FilterArray.Add(Page1.Document);
	EndDo;
	OpenForm("InformationRegister.DocumentsRegistry.ListForm", FormOpenParameters, ThisForm);
EndProcedure

&AtClient
Procedure NavigationGoToTheEnd(Command)
	StartSwitchingToPage(7);
EndProcedure

&AtClient
Procedure PrintCorrectiveInvoices(Command)
	VATAccountingERPClient.PrintingCorrectiveInvoicesForChangedDocuments(Object.ReplacementTaxInvoices, ThisForm);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ExecuteObjectMethodsOnServer(MethodNames, MethodParameters_ = Undefined)
	
	Methods = StrSplit(MethodNames, ",");
	DataProcessorObject = FormAttributeToValue("Object");
	
	If Not IsExternalDataProcessor Then
		
		NamesOfLongRunningOperations = DataProcessorObject.NamesOfLongRunningOperations();
		For Each Method In Methods Do
			Method = TrimAll(Method);
			If NamesOfLongRunningOperations.Find(Method) <> Undefined Then
				BackgroundExecution = True;
				Break;
			EndIf;
		EndDo;
		
		If BackgroundExecution Then
			AdditionalParameters = New Structure(
				"MethodNames, MethodParameters_, StructureOfProcessingObject", 
				 MethodNames, MethodParameters_, DataProcessorObject.StructureOfData());
			BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
			BackgroundExecutionResult = TimeConsumingOperations.ExecuteInBackground(
				"DataProcessors.WizardOfCorrectingCompanyStockBalance.ExecuteObjectMethods",
				AdditionalParameters,
				BackgroundExecutionParameters);
		EndIf;
		
	EndIf;
	
	If Not BackgroundExecution Then
		AdditionalParameters = New Structure("MethodNames, MethodParameters_", MethodNames, MethodParameters_);
		DataProcessors.WizardOfCorrectingCompanyStockBalance.ExecuteObjectMethods(
			AdditionalParameters,,
			DataProcessorObject);
		ValueToFormAttribute(DataProcessorObject, "Object");
	EndIf;

EndProcedure

&AtServer
Procedure UploadResultOfBackgroundTaskToServer();
	
	StructureOfProcessingObject = GetFromTempStorage(BackgroundExecutionResult.ResultAddress);
	
	If StructureOfProcessingObject = Undefined Then 
		Return;
	EndIf;
	
	For Each StructureField In StructureOfProcessingObject Do
		If TypeOf(StructureField.Value) = Type("ValueTable") Then
			Object[StructureField.Key].Load(StructureField.Value);
		Else
			Object[StructureField.Key] = StructureField.Value;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function TransferSettingsKey(CompanyOwner, CompanyCustomer, InventoryType)
	
	RecordManager = InformationRegisters.CustomizeCustomerInvoiceIntercompany.CreateRecordManager();
	RecordManager.CompanyOwner = CompanyOwner;
	RecordManager.CompanyCustomer = CompanyCustomer;
	RecordManager.InventoryType = InventoryType;
	RecordManager.Read();
	If RecordManager.Selected() Then
		KeyValues = New Structure(
			"CompanyOwner, CompanyCustomer, InventoryType",
			 CompanyOwner, CompanyCustomer, InventoryType);
		Return InformationRegisters.CustomizeCustomerInvoiceIntercompany.CreateRecordKey(KeyValues);
	Else
		Return Undefined
	EndIf;
	
EndFunction

&AtClient
Procedure CustomizeFormElements()
	
	PageNumber = Number(StrReplace(Items.GroupPages.CurrentPage.Name, "GroupStep", ""));
	HasIssue = Object.NumberOfPositionsNegativeBalance
		Or Object.ItemQuantitySidedBalance;
	
	// Default values
	Items.NavigateNext.Visible = HasIssue;
	Items.NavigateNext.DefaultButton = HasIssue;
	Items.NavigationGoToTheEnd.Visible = Not HasIssue;
	Items.NavigationGoToTheEnd.DefaultButton = Not HasIssue;
	Items.NavigationGoToTheBeginning.Visible = False;
	Items.NavigationGoToTheBeginning.Title = ?(HasIssue, NStr("vi = 'Chuyển đến bắt đầu';
																|ru = 'Перейти в начало';
																|en = 'Go to beginning'; fa = 'رفتن به ابتدا';
																|it = 'Vai all''inizio';
																|pl = 'Przejdź na początek';
																|tr = 'Başlangıca git'"), NStr("vi = 'Tháng tiếp theo';
																								|ru = 'Следующий месяц';
																								|en = 'Next month'; fa = 'Next month';
																								|it = 'Mese successivo';
																								|pl = 'Następny miesiąc';
																								|tr = 'Gelecek ay'"));
	Items.NavigationClose.Visible = False;
	Items.NavigationBack.Visible = True;
	Items.DecorationGroupNavigationExplanationText.Visible = True;
	Items.GroupUpdateTitle.Visible = True;
	Items.DecorationGroupNavigationWarningText.Visible = False;
	
	// Step 0
	If PageNumber = 0 Then
		Items.NavigateNext.Visible = False;
		Items.NavigationGoToTheBeginning.Visible = True;
		Items.NavigationGoToTheBeginning.Title = NStr("vi = 'Bắt đầu';
														|ru = 'Начать';
														|en = 'Start'; fa = 'شروع';
														|it = 'Avvia';
														|pl = 'Start';
														|tr = 'Başlat'");
		Items.NavigationGoToTheBeginning.DefaultButton = True;
		Items.NavigationGoToTheEnd.Visible = False;
		Items.GroupUpdateTitle.Visible = False;
		Items.DecorationGroupNavigationExplanationText.Visible = False;
		Items.NavigationBack.Visible = False;
	EndIf;
	
	// Step 1
	If PageNumber = 1 Then
		SubmissionOfTheCorrectionMonth =
			TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(Object.MonthOfCorrection);
		Items.DecorationGroupNavigationExplanationText.Visible = False;
		
		Items.GroupNegativeBalanceDiagnostics.CurrentPage = 
			?(Object.NumberOfPositionsNegativeBalance,
			Items.GroupNegativeBalanceDiagnosticsStatusProblem,
			Items.GroupNegativeBalanceDiagnosticsStatusNoProblem);
		Items.GroupDiagnosticsOfNegativeBalancesOtherSolutions.Visible = Object.NumberOfPositionsNegativeBalanceOther > 0;
		
		Items.GroupDetailedBalanceDiagnostics.Visible = Not (Object.ItemQuantitySidedBalance = 0
																	And Object.NumberOfPositionsNegativeBalance > 0);
		Items.GroupDetailedBalanceDiagnostics.CurrentPage = 
			?(Object.ItemQuantitySidedBalance,
			Items.GroupDetailedBalanceDiagnosticsStatusProblem,
			Items.GroupDetailedBalanceDiagnosticsStatusNoProblem);

		Items.GroupMonthOfCorrection.Visible = HasIssue;
		Items.CorrectionMonthViewHint.Visible = HasIssue;
		Items.NavigationClose.Visible = Not HasIssue;
		Items.NavigationClose.DefaultButton = Not HasIssue;
		Items.NavigationGoToTheEnd.Visible = False;
	EndIf;
	
	// Step 2
	If PageNumber = 2 Then
		ControlResultIsEmpty = Object.RegistrationControlResult.TableHeight = 0 
			And Object.RegistrationControlResult.TableWidth = 0;
		Items.GroupStep2StatusIssue.Visible = Not ControlResultIsEmpty;
		Items.GroupStep2StateNoProblem.Visible = ControlResultIsEmpty;
	EndIf;
	
	// Step 3
	If PageNumber = 3 Then
		AdjustmentsToReservesQuantity = Object.ReserveAdjustments.Count();
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách các điều chỉnh được tạo';
				|ru = 'Открыть список сформированных корректировок';
				|en = 'Open list of generated adjustments'; fa = 'باز کردن فهرست تعدیلات ایجادشده';
				|it = 'Aprire l''elenco delle rettifiche generate';
				|pl = 'Otworzyć listę utworzonych zapisów korygujących';
				|tr = 'Oluşturulan düzeltmelerin listesini aç'"), 
			AdjustmentsToReservesQuantity, 
			Items.OpenListOfGeneratedAdjustments);
		Items.DecorationPerformAdditionalReservationExplanation2.Title = GenerateTitleStep3Explanation2();
		Items.GroupStep3StatusIssue.Visible = Object.RecalculationOfReservesRequired;
		Items.GroupStep3StateNoProblem.Visible = Not Object.RecalculationOfReservesRequired;
	EndIf;
	
	// Step 4
	If PageNumber = 4 Then
		
		ModifiedDocumentsQuantity = Object.ModifiedDocuments.Count();
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách các chứng từ sửa đổi';
				|ru = 'Открыть список измененных документов';
				|en = 'Open list of changed documents'; fa = 'باز کردن فهرست اسناد تغییریافته';
				|it = 'Aprire l''elenco dei documenti modificati';
				|pl = 'Otworzyć listę zmienionych dokumentów';
				|tr = 'Değiştirilen belgelerin listesini aç'"), 
			ModifiedDocumentsQuantity,
			Items.OpenListOfChangedDocuments);
		ThereAreChangesInCCDNumbers = False;
		For Each Page1 In Object.ModifiedDocuments Do
			If Page1.TaxInvoiceIsIssued And Page1.CCDNumbersChanged Then
				ThereAreChangesInCCDNumbers = True;
				Break;
			EndIf;
		EndDo;
		Items.GenerateReplacementTaxInvoices.Enabled = ModifiedDocumentsQuantity And ThereAreChangesInCCDNumbers;
		
		CorrectiveInvoicesQuantity = Object.ReplacementTaxInvoices.Count();
		Items.PrintingOfCorrectiveInvoices.Enabled = CorrectiveInvoicesQuantity;
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách hóa đơn chỉnh sửa được tạo';
				|ru = 'Открыть список сформированных исправительных счетов-фактур';
				|en = 'Open list of generated replacement tax invoices'; fa = 'باز کردن فهرست فاکتورهای مالیاتی جایگزین ایجادشده';
				|it = 'Aprire l''elenco delle fatture di rettifica generate';
				|pl = 'Otworzyć listę utworzonych korygujących faktur VAT';
				|tr = 'Oluşturulan düzeltici vergi faturalarının listesini açın'"), 
			CorrectiveInvoicesQuantity,
			Items.OpenTheListOfGeneratedCorrectiveInvoices);
			
		CorrectionOfBalancesOfGoodsOfOrganizationsQuantity = Object.CorrectionsOfStockBalanceOfCompanies.Count();
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách các bản sửa lỗi được tạo';
				|ru = 'Открыть список сформированных исправлений';
				|en = 'Open list of generated corrections'; fa = 'باز کردن فهرست اصلاحات ایجادشده';
				|it = 'Aprire l''elenco delle rettifiche generate';
				|pl = 'Otworzyć listę utworzonych poprawek';
				|tr = 'Oluşturulan düzeltmelerin listesini aç'"), 
			CorrectionOfBalancesOfGoodsOfOrganizationsQuantity,
			Items.OpenTheListOfGeneratedCorrectionsForProductBalancesOfOrganizations);
			
		Items.GroupStep4StatusIssue.Visible           = Object.SidedBalanceCorrectionIsRequired Or Object.RefillInventoryOwnerAttributes;
		Items.DecorationStep4Explanation1.Visible               = Not Object.SidedBalanceCorrectionIsRequired And Not Object.RefillInventoryOwnerAttributes;
		Items.DecorationStep4Explanation2.Visible               = Object.SidedBalanceCorrectionIsRequired And Not Object.RefillInventoryOwnerAttributes;
		Items.DecorationStep4Explanation3.Visible               = Not Object.SidedBalanceCorrectionIsRequired And Object.RefillInventoryOwnerAttributes;
		Items.DetailedBalanceCorrectionOption1.Visible = Object.SidedBalanceCorrectionIsRequired;
		Items.GroupStep4Option1Explanation.Visible          = Object.SidedBalanceCorrectionIsRequired;
		Items.TheGroupStep4AsThereIsNoProblem.Visible        = Not Object.SidedBalanceCorrectionIsRequired And Not Object.RefillInventoryOwnerAttributes;
		
		If Not Object.SidedBalanceCorrectionIsRequired And Object.RefillInventoryOwnerAttributes Then
			DetailedBalanceCorrectionOption = "RefillInventoryKinds";
		EndIf;
		
	EndIf;
		
	// Step 5
	If PageNumber = 5 Then
		AdjustmentsToReservesForNewSettingsQuantity = Object.ReserveAdjustmentsByNewSettings.Count();
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách các điều chỉnh được tạo theo cài đặt mới';
				|ru = 'Открыть список сформированных корректировок по новым настройкам';
				|en = 'Open list of generated adjustments by new settings'; fa = 'باز کردن فهرست تعدیلات ایجادشده بر اساس تنظیمات جدید';
				|it = 'Aprire l''elenco delle rettifiche generate per nuove impostazioni';
				|pl = 'Otworzyć listę utworzonych zapisów korygujących według nowych ustawień';
				|tr = 'Yeni ayarlara göre oluşturulan düzeltmelerin listesini aç'"), 
			AdjustmentsToReservesForNewSettingsQuantity,
			Items.OpenListOfGeneratedAdjustmentsByNewSettings);
		Items.GroupStep5StatusIssue.Visible = Object.CompaniesForTransferGeneration.Count();
		Items.GroupStep3StatusNoIssue.Visible = Not Object.CompaniesForTransferGeneration.Count();
	EndIf;
	
	// Step 6
	If PageNumber = 6 Then
		
		Items.DecorationGroupNavigationExplanationText.Visible = False;
		Items.NavigateNext.Visible = False;
		Items.NavigationGoToTheEnd.Visible = True;
		Items.NavigationGoToTheEnd.DefaultButton = True;
		Items.GroupStep6StatusProblem.Visible = Object.ReferencesForGeneratingOfGoodsReceipt.Count();
		Items.GroupStep6StateNoProblem.Visible = Not Object.ReferencesForGeneratingOfGoodsReceipt.Count();
		If ProductionIsUsed Then
			Items.DecorationTitleStep6.Title =
				NStr("vi = 'Bước 6. Lập chứng từ ghi tăng/xuất xưởng hàng hóa.';
					|ru = 'Шаг 6. Оформление оприходования/выпуска товаров.';
					|en = 'Step 6. Register receipt/release of goods.'; fa = 'Step 6. Register receipt/release of goods.';
					|it = 'Fase 6. Registrazione accettazione/produzione articoli.';
					|pl = 'Krok 6. Zatwierdzenie przyjęcia/wydania zewnętrznego';
					|tr = 'Aşama 6: Ürünlerin teslim alındığının/üretiminin kaydı.'");
			Items.DecorationStep6Explanation1.Title =
				NStr("vi = 'Đây là bước cuối cùng. Nếu các bước trước không hữu ích thì bạn có thể lập chứng từ ghi tăng/xuất xưởng đối với các mặt hàng còn dư âm.';
					|ru = 'Этот шаг заключительный. Если предыдущие шаги не помогли, то вы можете оформить оприходование/выпуск товаров, по которым остались отрицательные остатки.';
					|en = 'This step is final. If the previous steps did not help, you can register the receipt/release of goods for which there is negative balance.'; fa = 'This step is final. If the previous steps did not help, you can register the receipt/release of goods for which there is negative balance.';
					|it = 'Questa è la fase conclusiva. Se le fasi precedenti non sono state d''aiuto, è possibile registrare la registrazione/produzione degli articoli per i quali restano i saldi negativi.';
					|pl = 'Ten krok jest ostateczny. Jeśli poprzednie kroki nie pomogły, możesz zarejestrować przyjęcie/wydanie zewnętrzne, według których pozostały salda ujemne.';
					|tr = 'Bu aşama nihaidir. Önceki adımlar yardımcı olmadıysa, negatif bakiyesi olan ürünlerin makbuzunu/üretimini kaydedebilirsiniz.'");
			Items.DecorationStep6NoProblemExplanation.Title =
				NStr("vi = 'Không cần lập chứng từ ghi tăng/xuất xưởng hàng hóa.';
					|ru = 'Оформление оприходований/выпуска товаров не требуется.';
					|en = 'Registration of receipt/release of goods is not required.'; fa = 'Registration of receipt/release of goods is not required.';
					|it = 'Registrazione accettazione/produzione articoli non richiesta.';
					|pl = 'Rejestracja wydań/przyjęć zewnętrznych nie jest wymagana.';
					|tr = 'Ürünlerin teslim alınması / üretimi gerekli değildir.'");
		EndIf;
		Items.ReferencesForGeneratingOfGoodsReceiptArrangeProductionWithoutOrder.Visible = ProductionIsUsed;
		Items.DecorationStep6SeeAlso.Visible = ProductionIsUsed;
		
	EndIf;
	
	// Step 7
	If PageNumber = 7 Then
		ReportHeader = NStr("vi = 'Báo cáo tiến độ cho %MonthOfCorrection%';
							|ru = 'Отчет о проделанной работе за %MonthOfCorrection%';
							|en = 'Progress report for %MonthOfCorrection%'; fa = 'Progress report for %MonthOfCorrection%';
							|it = 'Report sul lavoro eseguito a %MonthOfCorrection%';
							|pl = 'Raport z postępów pracy dla %MonthOfCorrection%';
							|tr = '%MonthOfCorrection% için tamamlanan iş raporu'");
		ReportHeader = 
			StrReplace(ReportHeader, "%MonthOfCorrection%" ,Lower(Format(Object.MonthOfCorrection, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																										|ru = 'ДФ=''MMMM yyyy''';
																										|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																										|it = 'ДФ=''ММММ гггг''';
																										|pl = 'DF=''MMMM yyyy''';
																										|tr = 'DF=''MMMM yyyy'''"))));
		Items.DecorationTitleStep7.Title = ReportHeader;
		Items.GroupStep7NegativeBalanceDiagnostics.Visible = Object.NumberOfPositionsNegativeBalance;
		Items.GroupStep7DetailedBalanceDiagnostics.Visible = Object.ItemQuantitySidedBalance;
		Items.NavigationGoToTheBeginning.Visible = True;
		Items.NavigationGoToTheBeginning.DefaultButton = True;
		Items.NavigationGoToTheEnd.Visible = False;
		Items.GroupUpdateTitle.Visible = False;
		Items.DecorationGroupNavigationExplanationText.Visible = False;
		Items.DecorationGroupNavigationWarningText.Visible = Not HasIssue;
		Items.NavigateNext.Visible = False;
		Items.NavigationClose.Visible = True;
		ModifiedDocumentsQuantity = Object.ModifiedDocuments.Count();
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách các chứng từ sửa đổi';
				|ru = 'Открыть список измененных документов';
				|en = 'Open list of changed documents'; fa = 'باز کردن فهرست اسناد تغییریافته';
				|it = 'Aprire l''elenco dei documenti modificati';
				|pl = 'Otworzyć listę zmienionych dokumentów';
				|tr = 'Değiştirilen belgelerin listesini aç'"), 
			ModifiedDocumentsQuantity,
			Items.OpenTheListOfModifiedDocumentsStep7);
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách điều chỉnh dự trữ được tạo.';
				|ru = 'Открыть список сформированных корректировок резервов';
				|en = 'Open list of generated adjustments of reserves'; fa = 'باز کردن فهرست تعدیلات ایجادشده رزروها';
				|it = 'Aprire l''elenco delle rettifiche di scorte generate';
				|pl = 'Otworzyć listę utworzonych zapisów korygujących rezerw';
				|tr = 'Oluşturulan rezerv düzeltmelerinin listesini aç'"), 
			Object.ReserveAdjustments.Count(),
			Items.OpenTheListOfGeneratedAdjustmentsStep7);
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách chỉnh sửa được tạo của số dư hàng hóa mở rộng trong doanh nghiệp';
				|ru = 'Открыть список сформированных исправлений развернутого сальдо товаров организаций';
				|en = 'Open list of generated corrections of the company goods detailed balance'; fa = 'Open list of generated corrections of the company goods detailed balance';
				|it = 'Aprire l''elenco delle rettifiche generate del saldo merci esteso delle società';
				|pl = 'Otworzyć listę utworzonych poprawek rozwiniętego saldo towarów firmy';
				|tr = 'İş yerlerinin brüt ürün bakiyesi için oluşturulan düzeltmelerin listesini aç'"), 
			Object.CorrectionsOfStockBalanceOfCompanies.Count(),
			Items.OpenTheListOfGeneratedAdjustmentsForTheBalanceOfGoodsOfOrganizationsStep7);
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách điều chỉnh dự trữ đã tạo cho cài đặt mới';
				|ru = 'Открыть список сформированных корректировок резервов по новым настройкам';
				|en = 'Open list of generated adjustments of reserves by new settings'; fa = 'باز کردن فهرست تعدیلات ایجادشده رزروها بر اساس تنظیمات جدید';
				|it = 'Aprire l''elenco delle rettifiche delle scorte generate in base alle nuove impostazioni';
				|pl = 'Otworzyć listę utworzonych zapisów korygujących rezerw według nowych ustawień';
				|tr = 'Yeni ayarlara göre oluşturulan rezerv düzeltmelerinin listesini aç'"), 
			Object.ReserveAdjustmentsByNewSettings.Count(),
			Items.OpenTheListOfGeneratedAdjustmentsForTheNewSettingsStep7);
		ConfigureDocumentListHyperlink(
			NStr("vi = 'Mở danh sách hóa đơn chỉnh sửa được tạo';
				|ru = 'Открыть список сформированных исправительных счетов-фактур';
				|en = 'Open list of generated replacement tax invoices'; fa = 'باز کردن فهرست فاکتورهای مالیاتی جایگزین ایجادشده';
				|it = 'Aprire l''elenco delle fatture di rettifica generate';
				|pl = 'Otworzyć listę utworzonych korygujących faktur VAT';
				|tr = 'Oluşturulan düzeltici vergi faturalarının listesini açın'"), 
			Object.ReplacementTaxInvoices.Count(),
			Items.OpenTheListOfGeneratedCorrectiveInvoicesStep7);
	EndIf;
		
EndProcedure

&AtClient
Procedure SwitchPage(Delta)
	
	PageNumber = Number(StrReplace(Items.GroupPages.CurrentPage.Name, "GroupStep", ""));
	PageNumber = PageNumber + Delta;
	
	If PageNumber = 5
		And ThisIsTradeManagementBasic Then
		
		PageNumber = PageNumber + Delta;
		
	EndIf;
	
	StartSwitchingToPage(PageNumber);
	
EndProcedure

&AtClient
Procedure StartSwitchingToPage(PageNumber)
	
	CompletionHandler = "CompletePageSwitching";
	CompletionHandlerParameters = New Structure;
	CompletionHandlerParameters.Insert("PageNumber", PageNumber);
	
	If PageNumber = 2 Then
		If PostInitialValueWithoutControl = False Then
			InstallProgramWithoutControlOnServer(True);
		EndIf;
		MethodParameters_ = New Structure;
		MethodParameters_.Insert("ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement", New Array);
		MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement.Add(
			AddressOfAdditionalParametersOfRegistrationControlResult);
		MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement.Add(
			ControlOfDesignDetailOnPositions);
		ExecuteObjectMethods(
			"ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement",
			MethodParameters_,
			"CompleteFormationOfRegistrationControlResult");
	ElsIf PageNumber = 3 Then
		ExecuteObjectMethods("ReFormationOfReservesIsNotRequired",,CompletionHandler, CompletionHandlerParameters)
	ElsIf PageNumber = 4 Then
		ExecuteObjectMethods("CorrectionOfUnfoldedBalanceIsRequired",, CompletionHandler, CompletionHandlerParameters);
	ElsIf PageNumber = 5 Then
		ExecuteObjectMethods("FillInNewTransferSettings",, CompletionHandler, CompletionHandlerParameters);
	ElsIf PageNumber = 6 Then
		ExecuteObjectMethods("FillOutOrdersForRegistrationOfRegistrationForms",, CompletionHandler, CompletionHandlerParameters);
	Else 
		CompletePageSwitching(PageNumber);
		CustomizeFormElements();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureDocumentListHyperlink(CommandTitle, DocumentsCount, CommandElementOnForm)
	
	If DocumentsCount Then
		CommandTitle = 
			CommandTitle + " (" + Format(DocumentsCount) + ")";
	EndIf;
	CommandElementOnForm.Title = CommandTitle;
	CommandElementOnForm.Enabled = DocumentsCount > 0;

EndProcedure

&AtClient
Procedure ExecuteObjectMethods(
	MethodNames, 
	MethodParameters_ = Undefined, 
	CompletionHandler = Undefined, 
	CompletionHandlerParameters = Undefined)
	
	AdditionalParameters = New Structure(
			"CompletionHandler, CompletionHandlerParameters",
			 CompletionHandler, CompletionHandlerParameters);
	ExecuteObjectMethodsOnServer(MethodNames, MethodParameters_);
	If BackgroundExecution Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = True;
		If StrFind(MethodNames,"RefillInventoryKinds") Then
			IdleParameters.OutputProgressBar = True;
		EndIf;
		CallbackOnCompletion = New CallbackDescription("LoadResultOfBackgroundTask", ThisForm, AdditionalParameters);
		TimeConsumingOperationsClient.WaitCompletion(BackgroundExecutionResult, CallbackOnCompletion, IdleParameters);
	Else
		EndHandlerExecution(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadResultOfBackgroundTask(Result, AdditionalParameters) Export
	BackgroundExecution = False;
	If Result <> Undefined Then
		UploadResultOfBackgroundTaskToServer();
		If Result.Status = "Error" Then
			CustomizeFormElements();
			Raise Result.BriefErrorDescription;
		EndIf;
		EndHandlerExecution(AdditionalParameters);
	EndIf;
EndProcedure

&AtClient
Procedure EndHandlerExecution(AdditionalParameters)
	
	If AdditionalParameters.CompletionHandler = "CompletePageSwitching" Then
		CompletePageSwitching(AdditionalParameters.CompletionHandlerParameters.PageNumber);
		CustomizeFormElements();
	ElsIf AdditionalParameters.CompletionHandler = "CompleteFormationOfRegistrationControlResult" Then
		CompleteFormationOfRegistrationControlResult(
			AddressOfAdditionalParametersOfRegistrationControlResult,
			UUID,
			RegistrationControlResultSchemeAddress,
			RegistrationControlResultExplanationDataAddress);
		CompletePageSwitching(2);
		CustomizeFormElements();
	Else
		CustomizeFormElements();
	EndIf;

EndProcedure

&AtClient
Procedure CompletePageSwitching(PageNumber)
	
	Items.GroupPages.CurrentPage = 
	Items.Find("GroupStep" + Format(PageNumber, "NZ=0; NG="));

EndProcedure

&AtClient
Function GenerateTitleStep3Explanation2()
	
	MonthGenitive = MonthGenitive(Object.MonthOfCorrection);
	Year = Format(Object.MonthOfCorrection, "DF=yyyy");
	TitleText = NStr("vi = 'Khi khởi động tạo lại dự phòng sẽ xóa bản ghi kết chuyển của biểu ghi ""Dự phòng hàng hóa trong doanh nghiệp"" theo các mục mặt hàng có vấn đề, đồng thời bắt đầu từ %MonthGenitive%%Year% và tạo các dự phòng mới theo số dư âm. Sẽ ghi các dự phòng mới vào chứng từ điều chỉnh biểu ghi. Đối với mỗi doanh nghiệp, sẽ tạo ra chứng từ riêng biệt.';
					|ru = 'При запуске переформирования резервов будут очищены движения регистра ""Резервы товаров организаций"" по проблемным позициям, начиная с %MonthGenitive% %Year% года, и сформированы новые резервы по отрицательным остаткам. Новые резервы будут записаны в документы корректировок регистров. Для каждой организации будет создан отдельный документ.';
					|en = 'When rebuilding reserves, the ""Company goods reserves"" register records for problematic positions will be cleared starting from %MonthGenitive% %Year% and new negative balance reserves will be created. New reserves will be recorded in register adjustment documents. A separate document will be created for each company.'; fa = 'When rebuilding reserves, the ""Company goods reserves"" register records for problematic positions will be cleared starting from %MonthGenitive% %Year% and new negative balance reserves will be created. New reserves will be recorded in register adjustment documents. A separate document will be created for each company.';
					|it = 'Durante l''avviamento di riformazione delle riserve, i movimenti del registro ""Scorte delle merci delle società"" verranno cancellati per le posizioni problematiche, a partire da%MonthGenitive% %Year% anno, e verranno generate le nuove scorte per i saldi negativi. Le nuove scorte verranno registrate nei documenti di rettifica del registro. Verrà creato un documento separato per ciascuna società.';
					|pl = 'Podczas uruchomienia ponownego formowania rezerw zostaną oczyszczone ruchy rejestru ""Rezerwy towarów firmy"" według problematycznych pozycji, zaczynając od %MonthGenitive%%Year% roku, i utworzone nowe rezerwy po negatywnych pozostałościach. Nowe rezerwy zostaną zapisane w dokumentach korekty rejestrów. Dla każdej firmy zostanie utworzony osobny dokument.';
					|tr = 'Rezervlerin yenilenmesine başlandığında, ""İş yerlerinin ürün rezervleri"" kaydının hareketleri yılın %MonthGenitive% %Year%''ından başlayarak sorunlu kalemler için temizlenecek ve negatif bakiyeler için yeni rezervler oluşturulacaktır. Yeni rezervler kayıt düzeltme belgelerine kaydedilecektir. Her iş yeri için ayrı bir belge oluşturulacaktır.'");
	TitleText = StrReplace(TitleText, "%MonthGenitive%", Lower(MonthGenitive));
	TitleText = StrReplace(TitleText, "%Year%", Year);
	Return TitleText;
	
EndFunction

&AtClient
Function MonthGenitive(Date)
	
	Months = New Map;
	Months.Insert(1, "january_");
	Months.Insert(2, "february_");
	Months.Insert(3, "martha");
	Months.Insert(4, "april_");
	Months.Insert(5, "ofmay");
	Months.Insert(6, "ofjune");
	Months.Insert(7, "july_");
	Months.Insert(8, "august_");
	Months.Insert(9, "september_");
	Months.Insert(10, "october_");
	Months.Insert(11, "november_");
	Months.Insert(12, "december_");
	
	Return Months.Get(Month(Date));
	
EndFunction

&AtClient
Procedure OpenExpandedBalanceOnClientReport()
	
	ReportFormOpeningParameters = New Structure;
	ReportFormOpeningParameters.Insert("GenerateOnOpen", True);
	ReportFormOpeningParameters.Insert("Filter", New Structure);
	ReportFormOpeningParameters.Filter.Insert("Month", Object.MonthOfCorrection);
	ReportFormOpeningParameters.Filter.Insert("MonthPresentation", SubmissionOfTheCorrectionMonth);
	OpenForm("Report.SidedBalanceByInventoryOwnerAttributesAndCCDNumbers.Form", ReportFormOpeningParameters, ThisForm, True);

EndProcedure

&AtClient
Procedure OpenNegativeBalancesOnClientReport()
	
	ReportFormOpeningParameters = New Structure;
	ReportFormOpeningParameters.Insert("GenerateOnOpen", True);
	ReportFormOpeningParameters.Insert("Filter", New Structure);
	ReportFormOpeningParameters.Filter.Insert("Month", Object.MonthOfCorrection);
	ReportFormOpeningParameters.Filter.Insert("MonthPresentation", SubmissionOfTheCorrectionMonth);
	OpenForm("Report.NegativeBalanceOfStockAndSafeStockOfCompanies.Form", ReportFormOpeningParameters, ThisForm, True);

EndProcedure

&AtClient
Procedure NotificationOfClosureOfTransferGenerationAssistant(Result, AdditionalParameters) Export
	ExecuteObjectMethods("UpdateDataOnNegativeBalancesAndBalances, FillInNewTransferSettings");
EndProcedure

&AtClient
Procedure NotificationAboutClosingRegistrationForm(Result, AdditionalParameters) Export
	ExecuteObjectMethods("UpdateDataOnNegativeBalancesAndBalances, FillOutOrdersForRegistrationOfRegistrationForms");
EndProcedure
&AtClient
Procedure NotificationOfClosureOfProductionFormWithoutOrders(Result, AdditionalParameters) Export
	ExecuteObjectMethods("UpdateDataOnNegativeBalancesAndBalances, FillOutOrdersForRegistrationOfRegistrationForms");
EndProcedure
&AtClient
Procedure CreatePresentationOfRecordingTransferSettings(Result, AdditionalParameters) Export
	
	If Result.GoodsTransferMethod = PredefinedValue("Enum.GoodsTransferMethods.EmptyRef")
		Or Result.GoodsTransferMethod = PredefinedValue("Enum.GoodsTransferMethods.NotTransferred") Then
		Items.TransferSettingsBetweenOrganizations.CurrentData.TransferSetting = "";
	Else
		RecordValues = New Array;
		RecordValues.Add(Result.GoodsTransferMethod);
		If ValueIsFilled(Result.Currency) Then
			RecordValues.Add(Result.Currency);
		EndIf;
		If ValueIsFilled(Result.PriceKind) Then
			RecordValues.Add(Result.PriceKind);
		EndIf;
		Items.TransferSettingsBetweenOrganizations.CurrentData.TransferSetting = StrConcat(RecordValues, ", ");
	EndIf;
	
EndProcedure

&AtClient
Procedure HandlingSelectionOfDecryptionAction(ChosenAction, ChosenActionParameter, AdditionalParameters) Export
	If ChosenAction = DataCompositionDetailsProcessingAction.OpenValue Then
		ShowValue(, ChosenActionParameter);
	EndIf;
EndProcedure

&AtClient
Procedure NotificationsAboutClosureOfWorkplaceForProcessingDocuments(Result, AdditionalParameters) Export
	MethodParameters_ = New Structure;
	MethodParameters_.Insert("ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement", New Array);
	MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement.Add(
		AddressOfAdditionalParametersOfRegistrationControlResult);
	MethodParameters_.ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement.Add(
			ControlOfDesignDetailOnPositions);
	ExecuteObjectMethods(
		"UpdateDataOnNegativeBalancesAndBalances, ToFormResultOfControlOfRegistrationOfDocumentsOfCommodityMovement",
		MethodParameters_,
		"CompleteFormationOfRegistrationControlResult");
EndProcedure

// Parameters:
// 	AddressOfAdditionalParameters - String
// 	UUID - UUID
// 	SchemaURL - String
// 	DetailsDataAddress - String
//
&AtServerNoContext
Procedure CompleteFormationOfRegistrationControlResult(
	Val AddressOfAdditionalParameters, Val UUID, SchemaURL, DetailsDataAddress)
	
	AdditionalParameters = GetFromTempStorage(AddressOfAdditionalParameters); // Structure - Contains: 
																				 // * Schema - DataCompositionSchema
																				 // * DetailsData - Arbitrary
	SchemaURL = PutToTempStorage(AdditionalParameters.Schema, UUID);
	DetailsDataAddress = 
		PutToTempStorage(AdditionalParameters.DetailsData, UUID);
		
EndProcedure

&AtServerNoContext
Procedure CheckRoleNSISetupIsAvailable(StandardProcessing)
	
	If Not Users.RolesAvailable(Metadata.Roles.MasterDataSetup.Name) Then
		StandardProcessing = False;
		MessageText = NStr("vi = 'Để thiết lập chuyển, cần vai trò ""%MasterDataSetup%"". Hãy liên hệ với người quản trị.';
							|ru = 'Для настройки передачи требуется роль ""%MasterDataSetup%"". Обратитесь к администратору.';
							|en = 'You need the ""%MasterDataSetup%"" role to set up transfer. Please contact the administrator.'; fa = 'You need the ""%MasterDataSetup%"" role to set up transfer. Please contact the administrator.';
							|it = 'Per configurare la trasmissione, è richiesto il ruolo ""%MasterDataSetup%"". Contattare l''amministratore.';
							|pl = 'Aby skonfigurować przesyłanie, wymagana jest rola ""%MasterDataSetup%"". Skontaktuj się z administratorem.';
							|tr = 'Transferi ayarlamak için ""%MasterDataSetup%"" rolü gereklidir. Yöneticiyle iletişime geç.'");
		MessageText = StrReplace(MessageText, "%MasterDataSetup%", Metadata.Roles.MasterDataSetup.Synonym);
		Raise MessageText;
	EndIf;

EndProcedure

&AtServerNoContext
Procedure InstallProgramWithoutControlOnServer(Value)
	
	If Constants.ControlCompanyStockBalance.Get() Then
		SessionParameters.PostWithoutControlOfCompanyStockBalance = Value;
	EndIf;

EndProcedure

&AtServerNoContext
Function CurrentServerDate()
	Return CurrentSessionDate();
EndFunction

&AtServer
Procedure CheckAccessPermission(Cancel)
	
	If Constants.ControlCompanyStockBalance.Get()
		And Not UserRightsCached.AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration() Then
		Cancel = True;
		MessageText = 
		NStr("vi = 'Để làm việc với trợ giúp, cần có vai trò ""%AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration%"" hoặc tắt sử dụng tùy chọn chức năng ""%ControlCompanyStockBalance%"". Liên hệ với quản trị viên của bạn.';
			|ru = 'Для работы с помощником требуется роль ""%AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration%"" или отключение функциональной опции ""%ControlCompanyStockBalance%"". Обратитесь к администратору.';
			|en = 'To use the wizard, you need to have the ""%AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration%"" role or disable the ""%ControlCompanyStockBalance%"" functional option. Please contact the administrator.'; fa = 'To use the wizard, you need to have the ""%AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration%"" role or disable the ""%ControlCompanyStockBalance%"" functional option. Please contact the administrator.';
			|it = 'Per utilizzare l''assistente, è necessario avere il ruolo  ""%AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration%"" o disabilitare l''opzione funzionale ""%ControlCompanyStockBalance%"". Contattare l''amministratore.';
			|pl = 'Do pracy z asystentem jest wymagana rola ""%AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration%"" lub wyłączenie opcji funkcjonalnej ""%ControlCompanyStockBalance%"". Zwróć się do administratora.';
			|tr = 'Sihirbazla çalışmak için ""%AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration%"" rolüne sahip olunması veya ""%ControlCompanyStockBalance%"" işlevsel seçeneğinin devre dışı bırakılması gerekir. Yöneticiyle iletişime geç.'");
		MessageText = StrReplace(
		MessageText, "%AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration%",
		Metadata.Roles.AllowDisablingOfControlOfGoodsOfCompaniesForSessionDuration.Synonym);
		MessageText = StrReplace(
		MessageText, "%ControlCompanyStockBalance%", 
		Metadata.Constants.ControlCompanyStockBalance.Synonym);
		Raise MessageText;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT DISTINCT Organization FROM Catalog.InventoryKinds";
	Try 
		QueryResult = Query.Execute();
	Except
		Cancel = True;
		MessageText = 
		NStr("vi = 'Để làm việc với trợ giúp, cần quyền truy cập vào tất cả các doanh nghiệp trong cơ sở dữ liệu thông tin. Liên hệ với quản trị viên của bạn.';
			|ru = 'Для работы с помощником требуется доступ на чтение всех организаций в информационной базе. Обратитесь к администратору.';
			|en = 'For work with the assistant, you need access to read all companies in the infobase. Ask the administrator.'; fa = 'For work with the assistant, you need access to read all companies in the infobase. Ask the administrator.';
			|it = 'Per utilizzare l''assistente, è necessario avere l''accesso per la lettura di tutte le aziende nell''infobase.Contattare l''amministratore.';
			|pl = 'Dla pracy z asystentem wymagany jest dostęp do odczytu wszystkich firm w bazie informacyjnej. Skontaktuj się z administratorem.';
			|tr = 'Sihirbaz, infobase''deki tüm iş yerlerine okuma erişimi gerektirir. Yöneticiyle iletişime geç.'");	
		Raise MessageText;
	EndTry;

EndProcedure

&AtServerNoContext
Function ProductionIsUsed(Warehouse = Undefined)
	
	Department = Undefined;
	If ValueIsFilled(Warehouse) Then
		Department = Common.ObjectAttributeValue(Warehouse, "Department", True);
	EndIf;
	
	If Department = Undefined Then
		Return ProductionServerCached.SubsystemSettingsProduction().ProductionIsUsed;
	Else
		Return ProductionServerCached.ProductionBusinessUnitDescription(Department).ProductionBusinessUnit;
	EndIf;
	
EndFunction

&AtServer
Function ArrangeProductionWithoutOrderOnServer(CurrentID, Val DocumentParameters_)
	
	CurrentData = Object.ReferencesForGeneratingOfGoodsReceipt.FindByID(CurrentID);
	
	If Not ProductionIsUsed(CurrentData.Warehouse) Then
		
		MessageText = NStr("vi = 'Bộ phận kho ""%1"" không phải là đơn vị sản xuất. Cần tạo chứng từ ghi tăng hàng hóa.';
							|ru = 'Подразделение склада ""%1"" не является производственным. Необходимо оформить оприходование товаров.';
							|en = 'The ""%1"" warehouse business unit is not a production business unit. Register the goods receipt.'; fa = 'The ""%1"" warehouse business unit is not a production business unit. Register the goods receipt.';
							|it = 'Подразделение склада ""%1"" не является производственным. Необходимо оформить оприходование товаров.';
							|pl = 'The ""%1"" warehouse business unit is not a production business unit. Register the goods receipt.';
							|tr = 'Ambar departmanı ""%1"" üretim birimi değildir. Stok fazlası tahakkukun oluşturulması gerekmektedir.'");
		MessageText = StrTemplate(MessageText, CurrentData.Warehouse);
		
		Common.MessageToUser(MessageText);
		
		Return Undefined;
		
	EndIf;
	
	Query = DataProcessors.WizardOfCorrectingCompanyStockBalance.RequestDetailedMonthEndBalances(Object.MonthOfCorrection);
	Query.Text = Query.Text + Common.QueryBatchSeparator() +
	"SELECT
	|	0                                                              AS CostGroupNumber,
	|	DetailedBalance.Organization                                   AS Organization,
	|	VALUE(Enum.GroupingsOfCostsInBackflushProduction.ByProducts)    AS GroupCosts,
	|	DetailedBalance.ItemsLocationAttributes.WarehouseArea.Department AS Department,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse) AS DirectionOfProductionIssue,
	|	DetailedBalance.ItemsLocationAttributes.StorageLocation      AS Recipient,
	|	DATETIME(1,1,1)                                               AS ProductionStart,
	|	DetailedBalance.ItemsLocationAttributes.Products       AS Products,
	|	DetailedBalance.ItemsLocationAttributes.Characteristic     AS Characteristic,
	|	DetailedBalance.ItemsLocationAttributes.Series              AS Series,
	|	DetailedBalance.ItemsLocationAttributes.Purpose         AS Purpose,
	|	DetailedBalance.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)        AS BillOfMaterials,
	|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS AllocatedAccordingToRule,
	|	-SUM(DetailedBalance.CountBalance)                     AS Count,
	|	FALSE                                                           AS RecordCostsByADocument,
	|	FALSE                                                           AS ErrorInModelSettings
	|FROM
	|	DetailedBalancesAtEndOfMonth AS DetailedBalance
	|
	|WHERE
	|	DetailedBalance.Organization = &Organization
	|	AND DetailedBalance.ItemsLocationAttributes.StorageLocation = &Warehouse
	|	AND DetailedBalance.InventoryOwnerAttribute.InventoryType IN
	|		(VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
	|	AND DetailedBalance.CountBalance < 0
	|
	|GROUP BY
	|	DetailedBalance.Organization,
	|	DetailedBalance.ItemsLocationAttributes
	|";
	
	Query.SetParameter("Organization", CurrentData.Organization);
	Query.SetParameter("Warehouse",       CurrentData.Warehouse);
	
	For Each CurrentData In Query.Execute().Unload() Do
		StructureProductLine = ProductionClientServer.StructureProductLine();
		FillPropertyValues(StructureProductLine, CurrentData);
		DocumentParameters_.ProductsAccordingToSpecification.Add(StructureProductLine);
	EndDo;
	
	Return DataProcessors.RegisterBackflushProduction.GenerateDocumentsByParameters(DocumentParameters_);
	
EndFunction

#EndRegion
